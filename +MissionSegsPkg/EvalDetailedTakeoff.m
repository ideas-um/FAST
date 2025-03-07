function [Aircraft] = EvalDetailedTakeoff(Aircraft)
%
% [Aircraft] = EvalDetailedTakeoff(Aircraft)
% written by Nawa Khailany, nawakhai@umich.edu
% modified by Paul Mokotoff, prmoko@umich.edu
% last modified: 05 mar 2025
%
% Evaluate the takeoff segment. Assume maximum thrust/power from all
% components in the propulsion system. In the detailed takeoff segment, the
% time to complete the takeoff roll is computed from the physics (unlike
% the less detailed takeoff segment, EvalTakeoff, which assumes a
% one-minute takeoff).
%
% INPUTS:
%     Aircraft - aircraft being flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft flown after takeoff with the mission history
%                updated in "Aircraft.Mission.History.SI".
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% info about the aircraft    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% weight: get the maximum takeoff weight
MTOW = Aircraft.Specs.Weight.MTOW; 

% wing loading: get the wing loading
W_S = Aircraft.Specs.Aero.W_S.SLS;

% area: get the wing area
S = MTOW / W_S;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% information from the       %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% set number of points in the segment
npoint = Aircraft.Mission.Profile.SegPts(SegsID);

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% ending altitude (beginning altitude assumed to be 0)
AltEnd = Aircraft.Mission.Profile.AltEnd(SegsID);

% ending airspeed (beginning airspeed assumed to be 0)
V_tko = Aircraft.Mission.Profile.VelEnd(SegsID);

% ending velocity type (beginning one is not needed)
vtype = Aircraft.Mission.Profile.TypeEnd(SegsID);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% invariants                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravitational acceleration
g = 9.81;

% assume no temperature variation
dISA = 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% allocate memory for the    %
% mission history outputs    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rate of climb
dh_dt = zeros(npoint,1);

% flight path angle
FPA = zeros(npoint, 1);

% altitude
Alt = repmat(Aircraft.Specs.Performance.Alts.Tko, npoint, 1);

% total mass in each time
Mass = repmat(MTOW, npoint, 1);

% remember the power splits
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = repmat(Aircraft.Specs.Power.LamDwn.Tko, SegEnd - SegBeg + 1, 1);
Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :) = repmat(Aircraft.Specs.Power.LamUps.Tko, SegEnd - SegBeg + 1, 1);


%% FLY TAKEOFF %%
%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the airspeed profile %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the takeoff velocity to TAS, and find the density at takeoff
[~, V_tko, ~, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon( ...
                              AltEnd, dISA, vtype, V_tko);

% prescribe linearly spaced airspeeds during takeoff roll
V = linspace(0, V_tko, npoint)';

% remember the flight conditions during takeoff
Aircraft.Mission.History.SI.Performance.TAS(SegBeg:SegEnd) = V  ;
Aircraft.Mission.History.SI.Performance.Rho(SegBeg:SegEnd) = Rho;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% consider the geometry and  %
% its impact on aerodynamics %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the maximum lift coefficient
CL_max = 2 * MTOW * g / (Rho * ((V_tko / 1.1) ^ 2) * S);

% compute the CDO
CD0 = 0.0017; % hardcoded for now

% hardcode flaps
flaps = 1;

% Compute the delta CD0 based on flaps and landing gear (hardcoded now)
if (flaps == 1)
    k_uc = 3.16e-5;
else
    k_uc = 5.81e-5;
end

% compute the change in parasite drag coefficient
dCD0 = W_S * k_uc * MTOW ^ -0.215;

% k1 and k3 estimations (hardcoded for now, incorporate geometry later)
k1 = 0.02;
k3 = 1 / (pi * 0.9 * 10);

% G estimation (hardcoded for now, incorporate geometry later)
G = 0.6;

% compute the CD
CD = CD0 + dCD0 + (k1 + G * k3) * CL_max ^ 2;

% Compute L/D ratio
L_D = repmat(CL_max / CD, npoint, 1);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft performance       %
% analysis                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for state variables
D     = zeros(npoint, 1);
dV_dt = zeros(npoint, 1);
ddist = zeros(npoint, 1);
dtime = zeros(npoint, 1);

% fly with maximum power, so assume infinite power required
Preq = Inf(npoint, 1);

% compute the power available
Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

% get the power available
Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);

%
% FLIGHT PHYSICS:
% First, compute the aircraft's acceleration based on the thrust/power
% available and drag at each control point. Then, based on the thrust and
% drag, compute the acceleration at the control points (assume it is
% constant between control points). Use the airspeed difference and
% acceleration to determine the time to travel between the respective
% control points as well as the distance between the control points.
%
% T0                          T1                 T2
% D0                          D1                 D2
% V0                          V1                 V2
% |                           |                  |
% o---------------------------o------------------o
% |        dV_dt1             |     dV_dt2       |
% |           dt1             |        dt2       |
%
        
% get the thrust at each point
T = Pav ./ V;

% the first point will have a divide by 0 error, leave it as NaN
T(1) = NaN;

% compute the lift (assume takeoff is flown at CLmax)
L = 0.5 .* Rho .* V(2:end) .^ 2 .* CL_max .* S;

% compute the friction force (assume coefficient of friction)
F = 0.02 .* (MTOW * g - L);

% as liftoff occurs, L > W, so the frictional force is < 0 --- set it to 0
F(F < 0) = 0;

% compute the drag
D(2:end) = 0.5 .* Rho .* V(2:end) .^ 2 .* CD .* S;
    
% compute the acceleration (assume constant mass for now)
dV_dt(2:end) = (T(2:end) - D(2:end) - F) ./ MTOW;
    
% compute the time between control points
dtime(2:end) = diff(V) ./ dV_dt(2:end);

% compute the distance travelled
ddist(2:end) = diff(V .^ 2) ./ (2 .* dV_dt(2:end));

% compute power to overcome drag
DV = D .* V;

% compute the specific excess power (assume constant mass)
Ps = (Pav - DV) ./ (Mass .* g);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft performance post- %
% processing                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the time to takeoff and distance travelled
Time = cumsum(dtime);
Dist = cumsum(ddist);

% get the flight conditions for the entire takeoff roll
[EAS, TAS, Mach] = MissionSegsPkg.ComputeFltCon(Alt, dISA, "TAS", V);

% remember the flight conditions
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;

% ------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        %
% energy analysis        %
%                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% potential energy
PE = Mass .* g .* Alt;

% kinetic energy
KE = 0.5 .* Mass .* TAS .^ 2;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propulsion analysis, get   %
% the fuel burn, energy      %
% consumed, etc.             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember information in the mission history
Aircraft.Mission.History.SI.Power.Req(       SegBeg:SegEnd) = Preq;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;

% perform the propulsion analysis
Aircraft = PropulsionPkg.PropAnalysis(Aircraft);


%% FILL THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ; % m
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ; % m/s
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt; % m/s
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt; % m / s^2
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ; % deg
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ; % m/s
Aircraft.Mission.History.SI.Performance.LD(  SegBeg:SegEnd) = L_D  ;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(SegBeg:SegEnd) = PE; % J
Aircraft.Mission.History.SI.Energy.KE(SegBeg:SegEnd) = KE; % J

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Takeoff";

% ----------------------------------------------------------

end