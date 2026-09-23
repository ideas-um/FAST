function [Aircraft] = NotionalMission01(Aircraft)
%
% [Aircraft] = NotionalMission01(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define a typical mission with a design and distance-based reserve mission
% (see below). Note that this mission is not very detailed and could impact
% the energy source weights required to fly.
%
% mission 1: fly at design range             | mission 2: 100 nmi diversion
%                                            | at 20% of cruise altitude
%                                            |
%                                            |
%        _____________________________       |
%       /                             \      |
%      /                               \     |  __________
%     /                                 \    | /          \
%    /                                   \___|/            \
% __/                                        |              \__
%
%
% INPUTS:
%     Aircraft - aircraft structure (without a mission profile).
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure (with    a mission profile).
%                size/type/units: 1-by-1 / struct / []
%


%% IMPORT THE PERFORMANCE PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% mission range
Range = Aircraft.Specs.Performance.Range;

% takeoff and cruise altitudes
AltTko = Aircraft.Specs.Performance.Alts.Tko;
AltCrs = Aircraft.Specs.Performance.Alts.Crs;

% takeoff (m/s) and cruise (mach) speeds
VelTko = Aircraft.Specs.Performance.Vels.Tko;
VelCrs = Aircraft.Specs.Performance.Vels.Crs;


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [Range; 100];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;        1;        1;        2;        2;         2;         2];

% define the starting/ending altitudes (in m)
Mission.AltBeg = [AltTko; AltTko; AltCrs;       AltCrs; 0.1 * AltCrs; 0.2 * AltCrs; 0.2 * AltCrs; AltTko];
Mission.AltEnd = [AltTko; AltCrs; AltCrs; 0.1 * AltCrs; 0.2 * AltCrs; 0.2 * AltCrs;       AltTko; AltTko];

% define the climb rate (in m/s)
Mission.ClbRate = [   NaN;    NaN;    NaN;          NaN;          NaN;          NaN;          NaN;    NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [     0; VelTko; VelCrs;       VelCrs; 1.2 * VelTko; 1.5 * VelTko; 1.5 * VelTko; 1.2 * VelTko];
Mission.VelEnd  = [VelTko; VelCrs; VelCrs; 1.2 * VelTko; 1.5 * VelTko; 1.5 * VelTko; 1.2 * VelTko;            0];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS";  "TAS"; "Mach"; "Mach"; "TAS"; "TAS"; "TAS"; "TAS"];
Mission.TypeEnd = ["TAS"; "Mach"; "Mach";  "TAS"; "TAS"; "TAS"; "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end