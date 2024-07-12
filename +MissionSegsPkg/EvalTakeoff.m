function [Aircraft] = EvalTakeoff(Aircraft)
%
% [Aircraft] = EvalTakeoff(Aircraft)
% originally written by Huseyin Acar
% modified by Nawa Khailany, prmoko@umich.edu
% last modified: 10 Jul 2024
%
% Evaluate the takeoff segment. Assume a 1-minute takeoff at constant
% acceleration and maximum thrust/power from all power sources.
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

% gravitational acceleration------[scalar]
g = 9.81;

% weight: get the maximum takeoff weight
MTOW = Aircraft.Specs.Weight.MTOW; 

% wing loading: get the wing loading
W_S = Aircraft.Specs.Aero.W_S.SLS;

% area: get the wing area
S = (1/W_S)*MTOW;

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

% beginning and ending altitudes
AltBeg = Aircraft.Mission.Profile.AltBeg(SegsID);
AltEnd = Aircraft.Mission.Profile.AltEnd(SegsID);

% beginning and ending velocities
VelBeg = Aircraft.Mission.Profile.VelBeg(SegsID);
V_to = Aircraft.Mission.Profile.VelEnd(SegsID);

% beginning and ending velocity types
TypeBeg = Aircraft.Mission.Profile.TypeBeg(SegsID);
vtype = Aircraft.Mission.Profile.TypeEnd(SegsID);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% invariants                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% gravitational acceleration------[scalar]
g = 9.81;

% initial velocity is zero------[scalar]
V_i = 0;

% assume no temperature variation-------[scalar]
dISA = 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% allocate memory for the    %
% mission history outputs    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% rate of climb------[npoint x 1]
dh_dt = zeros(npoint,1);

% flight path angle------[npoint x 1]
FPA = zeros(npoint, 1);

% altitude------[npoint x 1]
Alt = repmat(Aircraft.Specs.Performance.Alts.Tko, npoint, 1);

% total mass in each time------[npoint x 1]
Mass = repmat(MTOW, npoint, 1);

% memory for the fuel and battery energy remaining
Eleft_ES = zeros(npoint, 1);

% memory for Lift over Drag Ratio
L_D = zeros(npoint,1);

% get the energy source types
Fuel = Aircraft.Specs.Propulsion.PropArch.ESType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

% check for any fuel
if (any(Fuel))
    
    % compute the fuel energy remaining
    Eleft_ES(:, Fuel) = Aircraft.Specs.Power.SpecEnergy.Fuel * Aircraft.Specs.Weight.Fuel;
    
end

% check for any battery
if (any(Batt))
    
    % compute the battery energy remaining
    Eleft_ES(:, Batt) = Aircraft.Specs.Power.SpecEnergy.Batt * Aircraft.Specs.Weight.Batt;
    
end

% assume thrust split comes from the aircraft specifications
LamTS = repmat(Aircraft.Specs.Power.LamTS.Tko, npoint, 1);

% assume energy/power/thrust splits come from the aircraft specifications
LamTSPS = repmat(Aircraft.Specs.Power.LamTSPS.Tko, npoint, 1);
LamPSPS = repmat(Aircraft.Specs.Power.LamPSPS.Tko, npoint, 1);
LamPSES = repmat(Aircraft.Specs.Power.LamPSES.Tko, npoint, 1);

% check if the power optimization structure is available
if (isfield(Aircraft, "PowerOpt"))
    
    % check if the splits are available
    if (isfield(Aircraft.PowerOpt, "Splits"))
        
        % get the thrust/power/energy splits
        [LamTS, LamTSPS, LamPSPS, LamPSES] = OptimizationPkg.GetSplits( ...
        Aircraft, SegBeg, SegEnd, LamTS, LamTSPS, LamPSPS, LamPSES);
        
    end
end

% remember the splits
Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd, :) = LamTS  ;
Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd, :) = LamTSPS;
Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd, :) = LamPSPS;
Aircraft.Mission.History.SI.Power.LamPSES(SegBeg:SegEnd, :) = LamPSES;


%% FLY TAKEOFF %%
%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft performance       %
% analysis                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the takeoff velocity to TAS, and find Rho
[~, V_to, ~, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon( ...
                           AltEnd, dISA, vtype, V_to);

% compute the CLmax
CL_max = (2*MTOW*g)/(Rho(1)*((V_to/1.1)^2)*S);

% compute the CDO
CD0 = 0.0017; % hardcoded for now

% Compute the delta CD0 based on flaps and landing gear
 % hardcode flaps
flaps = 1;
if (flaps == 1)
    k_uc = 3.16e-5;
else
    k_uc = 5.81e-5;
end
dCD0 = W_S*k_uc*(MTOW^-0.215);

% k1 and k3 estimations (hardcoded for now, incorporate geometry later)
k1 = 0.02;
k3 = 1/(pi*0.9*10);

% G estimation (hardcoded for now, incorporate geometry later)
G = 0.6;

% compute the CD
CD = CD0 + dCD0 + (k1 + G*k3)*(CL_max^2);

% Pre-allocate Velocity Array
VelArray = zeros(npoint,1);

% Fill out Velocity Array
for i = 1:npoint

    VelSpacing = V_to/(npoint - 1);

    VelArray(i) = (i - 1)*VelSpacing;

end

% Pre-allocate Acceleration Array
AccArray = zeros(npoint,1);

% Pre-allocate Thrust Array
ThrArray = zeros(npoint,1);

% Pre-allocate Drag Array
DragArray = zeros(npoint,1);

% Pre-allocate Distance Array
DisArray = zeros(npoint,1);

% Pre-allocate Time Array
TimeArray = zeros(npoint,1);

% Compute above Array values based on the time step (the first node is at 0
% velocity). The acceleration at each node is computing the acceleration of
% the segment between the previous node and the current node.
for i = 1:npoint

    if i == 1

        % Thrust to NaN
        ThrArray(i) = NaN;

        % Compute Drag
        DragArray(i) = 0.5.*Rho(1).*((VelArray(i)).^2).*CD.*S;
    
        % Compute Acceleration
        AccArray(i) = 0;
    
        % Compute Distance
        DisArray(i) = 0;

        % Compute Time
        TimeArray(i) = 0;


    else

        % Find Thrust based on aircraft class
        switch Aircraft.Specs.TLAR.Class
            case "Turbofan"
                ThrArray(i) = Aircraft.Specs.Propulsion.Thrust.SLS;
            case "Turboprop"
                T_W = (Aircraft.Specs.Power.P_W.SLS/VelArray(i));
                % thrust: Get the thrust
                ThrArray(i) = T_W*(MTOW); 
        end

        % Compute Drag
        DragArray(i) = 0.5.*Rho(1).*((VelArray(i)).^2).*CD.*S;
    
        % Compute Acceleration
        AccArray(i) = (ThrArray(i) - DragArray(i))./MTOW;
    
        % Compute Distance
        DisArray(i) = (VelArray(i).^2 - VelArray(i - 1).^2)./(2.*AccArray(i));
    
        % Compute Time between nodes
        TimeArray(i) = (VelArray(i) - VelArray(i - 1))./AccArray(i);

    end


end

% acceleration
dv_dt = AccArray;

% Allocate memory for Time
Time = zeros(npoint,1)';

% Find the global elapsed time at each node and store it at the Time array
for i = 1:npoint
    if i == 1
        
        Time(i) = 0;
        TotalTime = 0;

    else

        TotalTime = TotalTime + TimeArray(i);
        Time(i) = TotalTime;

    end
end

% Compute Drag
D = DragArray;

% Compute L/D ratio
L_D = repmat(CL_max/CD,npoint,1);

% Allocate memory for Distance
Dist = zeros(npoint,1);

% Find the global elapsed distance at each node and store it in the Dist
% array
for i = 1:npoint
    if i == 1
        
        Dist(i) = 0;
        TotalDist = 0;

    else

        TotalDist = TotalDist + DisArray(i);
        Dist(i) = TotalDist;

    end
end

% get the flight conditions------[npoint x 1]      
[EAS, TAS, Mach, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon(...
                                 Alt, dISA, "TAS", VelArray);

% remember the flight conditions
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd) = Alt ;
                             
% compute the power available
Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

% get the power available
Pav = Aircraft.Mission.History.SI.Power.TV(SegBeg:SegEnd);

% compute power to overcome drag --- new (ncases)
DV = D .* TAS;

% compute the specific excess power (ncases)
Ps = (Pav - DV) ./ (Mass .* g);

% ------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%
%                        %
% energy analysis        %
%                        %
%%%%%%%%%%%%%%%%%%%%%%%%%%

% potential energy (ncases)
PE = Mass .* g .* Alt;

% kinetic energy (ncases)
KE = 0.5 .* Mass .* TAS .^ 2;

% power overcame (ncases)
dPE_dt = Mass .* g   .* dh_dt;
dKE_dt = Mass .* TAS .* AccArray;

% power required (ncases)
Preq = dPE_dt + dKE_dt + DV;

% thrust required
Treq = Preq ./ TAS;

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

% remember the fuel and battery energy remaining
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% perform the propulsion analysis
Aircraft = PropulsionPkg.PropAnalysisNew(Aircraft);


%% FILL THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% performance metrics
Aircraft.Mission.History.SI.Performance.Dist(SegBeg:SegEnd) = Dist ; % m
Aircraft.Mission.History.SI.Performance.EAS( SegBeg:SegEnd) = EAS  ; % m/s
Aircraft.Mission.History.SI.Performance.RC(  SegBeg:SegEnd) = dh_dt; % m/s
Aircraft.Mission.History.SI.Performance.Acc( SegBeg:SegEnd) = dv_dt; % m / s^2
Aircraft.Mission.History.SI.Performance.FPA( SegBeg:SegEnd) = FPA  ; % deg
Aircraft.Mission.History.SI.Performance.Ps(  SegBeg:SegEnd) = Ps   ; % m/s
Aircraft.Mission.History.SI.Performance.LD(  SegBeg:SegEnd) = L_D  ;

% propulsion system quantities
Aircraft.Mission.History.SI.Propulsion.Treq(SegBeg:SegEnd) = Treq;

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(SegBeg:SegEnd) = PE; % J
Aircraft.Mission.History.SI.Energy.KE(SegBeg:SegEnd) = KE; % J

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Takeoff";

end