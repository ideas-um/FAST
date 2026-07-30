function [Aircraft] = EvalDetailedTakeoff(Aircraft)
%
% [Aircraft] = EvalDetailedTakeoff(Aircraft)
% written by Emma Cassidy, emmasmit@umich.edu
% last modified: 29 sep 2025
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

% wing loading: get the wing loading
W_S = Aircraft.Specs.Aero.W_S.SLS;

% area: get the wing area
S = Aircraft.Specs.Weight.MTOW / W_S;

AR = Aircraft.Specs.Aero.AR;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% information from the       %
% mission profile            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;
%SegsID = 1;

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

TkoRoll = Aircraft.Mission.Profile.TkoRoll;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% allocate memory for the    %
% mission history outputs    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% altitude
Alt = repmat(Aircraft.Specs.Performance.Alts.Tko, npoint, 1);

% TAS
TAS = zeros(npoint,1);

% time 
Time = zeros(npoint,1);

% drag
DV     = zeros(npoint, 1);

% time change
dt = zeros(npoint,1);

% acceleration
dV_dt = zeros(npoint, 1);

Ps = zeros(npoint,1);

% if not first segment, get accumulated quantities
if (SegBeg > 1)
    
    % initialize aircraft mass
    Mass = repmat(Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg), npoint, 1);
    
    % get distance flown and time aloft
    distStart = Aircraft.Mission.History.SI.Performance.Dist(SegBeg);
    timeStart = Aircraft.Mission.History.SI.Performance.Time(SegBeg);
   
    
else
    
    % initialize aircraft mass: assume maximum takeoff weight
    Mass = repmat(Aircraft.Specs.Weight.MTOW, npoint, 1);
    
   distStart = 0;
    timeStart = 0;
    
end

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
% setup the airspeed profile %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the takeoff velocity to TAS, and find the density at takeoff
[~, V_tko, ~, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon( ...
                              AltEnd, dISA, vtype, V_tko);

Aircraft.Mission.History.SI.Performance.Rho(SegBeg:SegEnd) = Rho;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% consider the geometry and  %
% its impact on aerodynamics %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retireve clean drag coefficient
CD0 = Aircraft.Specs.Aero.CD0; 

% chnage in parasite drag in takeoff configuration
dCD0 = Aircraft.Specs.Aero.dCD1;

CL = .3;

%{
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
%}
% k1 and k3 estimations (hardcoded for now, incorporate geometry later)
k1 = 1/(pi*Aircraft.Specs.Aero.e * AR);
k3 = -.15*k1;

% G estimation (hardcoded for now, incorporate geometry later)
G = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% iteration setup            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define tolerance for testing convergence
EPS06 = 1.0e-6;

% maximum number of iterations
MaxIter = 10;

dTkoRoll = 1;

% ----------------------------------------------------------
%% FLY TAKEOFF %%
%%%%%%%%%%%%%%%%%


% get the power available
Pav = 0;

i = 0; 

% converge on take off roll length
while dTkoRoll > EPS06 && i < MaxIter

    Dist = linspace(0, TkoRoll, npoint)';

    for ipt = 1:npoint
    
        if ipt == 1
            F = 0.02 .* (Mass(ipt) * g);
            T = Aircraft.Specs.Propulsion.SLSThrust(1);
            dV_dt(ipt) = (T-F)/Mass(ipt);
        else
            % compute the lift coefficient
            %CL = 2 * MTOW * g / (Rho * (TAS(ipt)^ 2) * S);
            
            % compute the CD
            CD = CD0 + dCD0 + (k1 + G * k3) * CL ^ 2;
        
    
            % compute the lift (assume takeoff is flown at CLmax)
            L = 0.5 .* Rho .* TAS(ipt) .^ 2 .* CL .* S;
            
            % compute the friction force (assume coefficient of friction)
            F = 0.02 .* (Mass(ipt) * g - L);
            
            % as liftoff occurs, L > W, so the frictional force is < 0 --- set it to 0
            if F < 0 
                F = 0;
            end
            
            % compute the drag
            D = 0.5 .* Rho .* TAS(ipt) .^ 2 .* CD .* S;
        
            DV(ipt) = (D+F).*TAS(ipt);
        
            Ps(ipt) = (Pav(ipt) - DV(ipt)) ./ (Mass(ipt) .* g);
        
            dV_dt(ipt) = Ps(ipt).*g./TAS(ipt);
        end
        
        if ipt ~= npoint
            % Solve for dt using ds = v*dt + 0.5*a*dt^2 over the current
            % distance interval. The takeoff roll iteration changes the
            % distance grid until the last point reaches the target speed.
            a = 0.5 .* dV_dt(ipt);
            b = TAS(ipt);
            c = -(Dist(ipt+1)-Dist(ipt));

            if abs(a) < EPS06
                dt(ipt) = -c ./ b;
            else
                dt(ipt) = (-b + sqrt(b.^2 - 4.*a.*c))./(2.*a);
            end
        
            if dt(ipt) < 0
                error("ERROR - EvalDetailedTakeoff: negative time step while iterating takeoff distance.");
            end
        
            % update next velcoity
            TAS(ipt+1) = dV_dt(ipt) * dt(ipt) + TAS(ipt);
        
            % update time
            Time(ipt+1) = dt(ipt) + Time(ipt);
            
            % update power avaliable based on TAS
            Aircraft.Mission.History.SI.Performance.TAS(SegBeg:SegEnd) = TAS;
            
            % compute the power available
            Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

            % get the updated power available
            Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);
        end
       
    end

    oldTkoRoll = TkoRoll;

    % check if takeoff velodity achieved
    id_vel = find(TAS > V_tko, 1, 'First');

    % if empty, takeoff speed not reached, lengthen runway
    if isempty(id_vel)
        TkoRoll = 1.1 * TkoRoll;
    else
        TkoRoll = Dist(id_vel);
    end

    dTkoRoll = abs(TkoRoll-oldTkoRoll);
     i = i +1;
end

    
%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        %
% energy analysis        %
%                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%

dKE_dt = Mass .* TAS .* dV_dt;

% power required (ncases)
Preq = dKE_dt + DV;

Preq(1) = Pav(1);

% ------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        %
% propulsion analysis    %
%                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%

Time = Time + timeStart;
Dist = Dist + distStart;
        
% store variables in the mission history
Aircraft.Mission.History.SI.Power.Req(       SegBeg:SegEnd) = Preq;
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass;
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;

% perform the propulsion analysis
Aircraft = PropulsionPkg.PropAnalysis(Aircraft);



%% FILL THE STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ;
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = TAS  ; % at takeoff this is the same
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = 0;
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dV_dt;
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ;

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "DetailedTakeoff";

% ----------------------------------------------------------

end
