function [Aircraft] = AEAProfile(Aircraft)
%
% NotionalMission02.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 23 apr 2024
%
% Define a typical mission with a design and time-based reserve mission
% (see below). Note that this mission is not very detailed and could impact
% the energy source weights required to fly.
%
% mission 1: 1,650 nmi range                 | mission 2: 45 minute loiter
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
Range = UnitConversionPkg.ConvLength(500,'naut mi','m');

% takeoff and cruise altitudes
AltTko = Aircraft.Specs.Performance.Alts.Tko;
AltCrs = 7829;

% takeoff (m/s) and cruise (mach) speeds
VelTko = Aircraft.Specs.Performance.Vels.Tko;
VelCrs = 0.747;


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [Range];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;        1;        1];

% define the starting/ending altitudes (in m)
Mission.AltBeg = [AltTko; AltTko; AltCrs;       AltCrs];
Mission.AltEnd = [AltTko; AltCrs; AltCrs;       AltTko];

% define the climb rate (in m/s)
Mission.ClbRate = [   NaN;    NaN;    NaN;          NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [     0; VelTko; VelCrs;       VelCrs];
Mission.VelEnd  = [VelTko; VelCrs; VelCrs; 1.2 * VelTko];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS"; "TAS" ; "Mach"; "Mach"];
Mission.TypeEnd = ["TAS"; "Mach"; "Mach";  "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end