function [Aircraft] = LM100J(Aircraft)
%
% [Aircraft] = LM100J(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define the design mission for a LM100J with reserves. Obtained from
% collaborators at NASA.
%
% mission 1: 2,400 nmi range              | mission 2: 45 minute loiter at
%                                         | 10,000 ft (assumed, not in the
%                                         | provided mission profile)
%                                         |
%        _____________________________    |
%       /                             \   |
%      /                               \  |  __________
%     /                                 \ | /          \
%    /                                   \|/            \
% __/                                     |              \__
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


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [Aircraft.Specs.Performance.Range; 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Climb"; "Cruise"; "Descent"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;       1;       1;        1;         1;       2;        2;         2;         2];

% define the starting/ending altitudes (in m)
Mission.AltBeg =  UnitConversionPkg.ConvLength([     0;       0;   10000;   17000;    25000;     25000;    5000;    10000;     10000;         0], "ft", "m");
Mission.AltEnd =  UnitConversionPkg.ConvLength([     0;   10000;   17000;   25000;    25000;      5000;   10000;    10000;         0;         0], "ft", "m");

% define a rate of climb/descent (m/s) or NaN for auto-selected rate
Mission.ClbRate =  UnitConversionPkg.ConvVel([  NaN;     NaN;    2000;    1500;      NaN;     -1500;    2000;      NaN;     -1500;       NaN], "ft/min", "m/s");

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg =  UnitConversionPkg.ConvVel([     0;     200;     210;     300;     0.59;       280;     210;      300;       300;       140], "kts", "m/s");
Mission.VelEnd =  UnitConversionPkg.ConvVel([   200;     200;     300;     300;     0.59;       210;     300;      300;       140;         0], "kts", "m/s");

% update the cruise segment with mach numbers
Mission.VelBeg(5) = 0.59;
Mission.VelEnd(5) = 0.59;

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = [ "TAS";   "TAS";   "TAS";   "TAS";   "Mach";     "TAS";   "TAS";    "TAS";     "TAS";     "TAS"];
Mission.TypeEnd = [ "TAS";   "TAS";   "TAS";   "TAS";   "Mach";     "TAS";   "TAS";    "TAS";     "TAS";     "TAS"];

% operational splits to optimize (only needed when running an optimization)
Mission.PowerOpt = [    1;      1;        1;       1;        1;         0;       1;        1;         0;         1];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end