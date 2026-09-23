function [Aircraft] = ATR42_600(Aircraft)
%
% [Aircraft] = ATRMissionEPASS(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% modified by Max Arnson, marnson@umich.edu
% last updated: 2 apr 2024
%
% Define a mission for the ATR42 as defined in Cinar's "Advanced 2030 ..." 
% https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=9813858&tag=1
%
% mission 1: 703 nmi range          | mission 2: 150  | mission 3: 45 min
%                                   | nmi diversion   | diversion (cruise
%                                   | at 15,000 ft    | at 15,000 ft)
%                                   |                 |
%        _____________________      |                 |
%       /                     \     |                 |
%      /                       \_   |  _______________|____
%     /                          \  | /               |    \
%    /                            \_|/                |     \_
% __/                               |                 |       \__
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
Mission.Target.Valu = [UnitConversionPkg.ConvLength(703, "naut mi", "m"); UnitConversionPkg.ConvLength(150, "naut mi", "m"); 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = [           "Takeoff"; "Climb"; "Cruise"; "Descent"; "Descent"; "Climb"; "Cruise"; "Cruise"; "Descent"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [                   1;       1;        1;         1;         1;       2;        2;        3;         3;         3;         3];

% define the starting/ending altitudes (in m)
Mission.AltBeg =  UnitConversionPkg.ConvLength([     0;       0;   25000;    25000;      3000;      1500;    15000;    15000;    15000;     3000;        1500], "ft", "m");
Mission.AltEnd =  UnitConversionPkg.ConvLength([     0;   25000;   25000;     3000;      1500;     15000;    15000;    15000;     3000;     1500;           0], "ft", "m");

% define the rate of climb/descent (in m/s)
Mission.ClbRate =            [   NaN;     NaN;     NaN;   -6.096;       NaN;       NaN;      NaN;      NaN;   -6.096;      NaN;         NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg =  UnitConversionPkg.ConvVel(   [     0;     160;     200;      200;       200;       160;       200;      200;     200;      200;         160], "kts", "m/s");
Mission.VelEnd =  UnitConversionPkg.ConvVel(   [   160;     200;     200;      200;       160;       200;       200;      200;     200;      160;           0], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg =            [ "TAS";   "EAS";   "EAS";    "EAS";     "EAS";     "EAS";     "EAS";    "EAS";   "EAS";    "EAS";       "EAS"];
Mission.TypeEnd =            [ "EAS";   "EAS";   "EAS";    "EAS";     "EAS";     "EAS";     "EAS";    "EAS";   "EAS";    "EAS";       "EAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end