function [Aircraft] = DiversionMission(Aircraft, dV)
%
% [Aircraft] = DiversionMission(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jan 2026
%
% after an engine failure, climb to 3,000 ft at takeoff speed. then,
% accelerate to 250 kts and climb to 10,000 ft. cruise at 250 kts before
% descending and landing.
%
%      _____________
%     /             \
%    /               \
% __/                 \__
%           1
%
% INPUTS:
%     Aircraft - aircraft structure (without a mission profile).
%                size/type/units: 1-by-1 / struct / []
%
%     dV       - difference between takeoff and climb speeds.
%                size/type/units: 1-by-1 / double / [kts]
%
% OUTPUTS:
%     Aircraft - aircraft structure (with    a mission profile).
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% check for a second argument, otherwise default to no speed difference
if (nargin < 2)
    dV = 0;
end

% get the takeoff speed
Vtko = Aircraft.Specs.Performance.Vels.Tko;

% transition speed (add 0/10/20 kts)
Vtrn = Vtko + UnitConversionPkg.ConvVel(dV, "kts", "m/s");

% cruise speed estimate
Vcrs = UnitConversionPkg.ConvVel(250, "kts", "m/s");

% compute the diversion distance
DivDist = UnitConversionPkg.ConvLength(200, "naut mi", "m");

% intermeditate climb altitude
IntAlt = UnitConversionPkg.ConvLength(3000, "ft", "m");

% diversion altitude
DivAlt = UnitConversionPkg.ConvLength(10000, "ft", "m");


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = DivDist;

% define the target types ("Dist" or "Time")
Mission.Target.Type = "Dist";


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID = [1; 1; 1; 1; 1; 1];

% define the starting/ending altitudes (in m)
Mission.AltBeg = [0; 0     ; IntAlt; DivAlt; DivAlt; 0];
Mission.AltEnd = [0; IntAlt; DivAlt; DivAlt; 0     ; 0];

% define the climb rate (in m/s)
Mission.ClbRate = [NaN; NaN; NaN; NaN; NaN; NaN];

% define the starting/ending speeds
Mission.VelBeg = [0   ; Vtko; Vtrn; Vcrs;       Vcrs; 1.1 * Vtko];
Mission.VelEnd = [Vtko; Vtrn; Vcrs; Vcrs; 1.1 * Vtko; 0         ];

% define the speed types
Mission.TypeBeg = ["TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"];
Mission.TypeEnd = ["TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end