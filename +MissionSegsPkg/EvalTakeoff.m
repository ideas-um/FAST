function [Aircraft] = EvalTakeoff(Aircraft)
%
% [Aircraft] = EvalTakeoff(Aircraft)
% originally written by Huseyin Acar
% modified by Paul Mokotoff, prmoko@umich.edu
% last modified: 04 apr 2024
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

% weight: get the maximum takeoff weight
MTOW = Aircraft.Specs.Weight.MTOW; 

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

% ground rolling second------[scalar-second]
TOffTime = 60; 

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

% time point------[npoint x 1]
Time = linspace(0, TOffTime, npoint)';

% rate of climb------[npoint x 1]
dh_dt = zeros(npoint,1);

% flight path angle------[npoint x 1]
FPA = zeros(npoint, 1);

% altitude------[npoint x 1]
Alt = Aircraft.Mission.History.SI.Performance.Alt(SegBeg:SegEnd); % m

% total mass in each time------[npoint x 1]
Mass = repmat(MTOW, npoint, 1);

% memory for the fuel and battery energy remaining
Eleft_ES = zeros(npoint, 1);

% get the energy source types
Fuel = Aircraft.Specs.Propulsion.PropArch.ESType == 1;
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

LamSLS = Aircraft.Specs.Power.LamTSPS.SLS;
Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd) = repmat(LamSLS, npoint, 1);

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


%% FLY TAKEOFF %%
%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft performance       %
% analysis                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% convert the takeoff velocity to TAS
[~, V_to, ~, ~, ~, ~, ~] = MissionSegsPkg.ComputeFltCon( ...
                           AltEnd, dISA, vtype, V_to);

% assume acceleration is constant during ground rolling-------[scalar]
dv_dt = (V_to - V_i) / TOffTime;

% the distance traveled in each time point------[npoint x 1]
Dist = 0.5 .* dv_dt .* Time .^ 2;

% instantenous velocity for each time------[npoint x 1]
V_ins = dv_dt .* Time;

% get the flight conditions------[npoint x 1]      
[EAS, TAS, Mach, ~, ~, Rho, ~] = MissionSegsPkg.ComputeFltCon(...
                                 Alt, dISA, "TAS", V_ins);

% remember the flight conditions
Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd) = TAS ;
Aircraft.Mission.History.SI.Performance.Rho( SegBeg:SegEnd) = Rho ;
Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd) = Time;
Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd) = Mach;
                             
% compute the power available
Aircraft = PropulsionPkg.PowerAvailable(Aircraft);

% for full throttle, recompute the operational power splits
%Aircraft = PropulsionPkg.RecomputeSplits(Aircraft, SegBeg, SegEnd, PC);

% assume all available power is for flying
Preq = Inf(npoint, 1);

% compute the specific excess power (will be 0 - did this b/c we don't know drag at takeoff)
Ps = zeros(npoint, 1);

% kinetic Energy------[npoint x 1]
KE = 0.5 .* Mass .* TAS .^ 2;

% potential energy------[npoint x 1]
PE = Mass .* g .* Alt;

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

% energy quantities
Aircraft.Mission.History.SI.Energy.PE(SegBeg:SegEnd) = PE; % J
Aircraft.Mission.History.SI.Energy.KE(SegBeg:SegEnd) = KE; % J

% current segment
Aircraft.Mission.History.Segment(SegBeg:SegEnd) = "Takeoff";

end