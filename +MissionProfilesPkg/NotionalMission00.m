function [Aircraft] = NotionalMission00(Aircraft)
%
% [Aircraft] = NotionalMission00(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 mar 2024
%
% Define a typical mission with a design mission only (no reserves, see
% below). Note that this mission is not very detailed and could impact
% the energy source weights required to fly.
%
% mission 1: fly at the design range
%
% mission range, velocities, and altitudes are parameterized by the input
% aircraft specification file
%
%        _____________________________       
%       /                             \      
%      /                               \     
%     /                                 \    
%    /                                   \
% __/                                     \__
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
Mission.Target.Valu = Range;

% define the target types ("Dist" or "Time")
Mission.Target.Type = "Dist";


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;        1;         1;         1];

% define the starting/ending altitudes (in m)
Mission.AltBeg = [AltTko; AltTko; AltCrs; AltCrs; AltTko];
Mission.AltEnd = [AltTko; AltCrs; AltCrs; AltTko; AltTko];

% define the climb rate (in m/s)
Mission.ClbRate = [   NaN;    NaN;    NaN;    NaN;    NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [     0; VelTko; VelCrs;       VelCrs; 1.2 * VelTko];
Mission.VelEnd  = [VelTko; VelCrs; VelCrs; 1.2 * VelTko;            0];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS";  "TAS"; "Mach"; "Mach"; "TAS"];
Mission.TypeEnd = ["TAS"; "Mach"; "Mach";  "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end