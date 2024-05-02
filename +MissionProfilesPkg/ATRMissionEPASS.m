function [Aircraft] = ATRMissionEPASS(Aircraft)
%
% [Aircraft] = ATRMissionEPASS(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define a mission for the ATR42 as defined in E-PASS.
%
% mission 1: 801 nmi range           | mission 2: 45-  | mission 3: 87 nmi
%                                    | minute loiter   | diversion (cruise
%                                    | at 10,000 ft    | at 10,000 ft)
%                                    |                 |
%        _____________________       |                 |
%       /                     \      |                 |
%      /                       \     |  _______________|____
%     /                         \    | /               |    \
%    /                           \___|/                |     \
% __/                                |                 |      \__
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
Mission.Target.Valu = [UnitConversionPkg.ConvLength(801, "naut mi", "m"); 45; UnitConversionPkg.ConvLength(87, "naut mi", "m")];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Time"; "Dist"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Cruise"; "Descent"; "Descent"; "Descent"; "Climb";  "Climb"; "Cruise"; "Cruise"; "Descent"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;       1;        1;         1;         1;         1;       2;        2;        2;        3;         3;         3;         3];

% define the starting/ending altitudes (in m)
Mission.AltBeg =  UnitConversionPkg.ConvLength([     0;       0;   24000;    25000;     25000;     24000;      3000;    1500;     9000;    10000;    10000;     10000;      3000;         0], "ft", "m");
Mission.AltEnd =  UnitConversionPkg.ConvLength([     0;   24000;   25000;    25000;     24000;      3000;      1500;    9000;    10000;    10000;    10000;      3000;         0;         0], "ft", "m");

% define the rate of climb/descent (in m/s)
Mission.ClbRate =            [   NaN;     NaN;     NaN;      NaN;       NaN;       NaN;       NaN;     NaN;      NaN;      NaN;      NaN;       NaN;       NaN;       NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg =  UnitConversionPkg.ConvVel(   [     0;     160;     160;      300;       300;       200;       200;      160;     160;      200;      200;       200;       200;        160], "kts", "m/s");
Mission.VelEnd =  UnitConversionPkg.ConvVel(   [   160;     160;     300;      300;       200;       200;       160;      160;     200;      200;      200;       200;       160;          0], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg =            [ "TAS";   "EAS";   "EAS";    "TAS";     "TAS";     "EAS";     "EAS";    "EAS";   "EAS";    "EAS";    "EAS";     "EAS";     "EAS";      "EAS"];
Mission.TypeEnd =            [ "EAS";   "EAS";   "TAS";    "TAS";     "EAS";     "EAS";     "EAS";    "EAS";   "EAS";    "EAS";    "EAS";     "EAS";     "EAS";      "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end