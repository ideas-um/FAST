function [Aircraft] = RegionalJetMission02(Aircraft)
%
% [Aircraft] = RegionalJetMission02(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define a typical mission with a design and time-based reserve mission
% (see below). This profile contains altitudes and speeds for a regional
% jet. Note that this mission is not very detailed and could impact the
% energy source weights required to fly.
%
% mission 1: 1,650 nmi range                 | mission 2: 45 minute loiter
%                                            | at 5,000 ft (modeled as a
%                                            | cruise segment)
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


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = [UnitConversionPkg.ConvLength(2150, "naut mi", "m"); 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;        1;        1;        2;        2;         2;         2];

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([0;     0; 35000; 35000; 3000; 5000; 5000; 0], "ft", "m");
Mission.AltEnd = UnitConversionPkg.ConvLength([0; 35000; 35000;  3000; 5000; 5000;    0; 0], "ft", "m");

% define the climb rate (in m/s)
Mission.ClbRate = [ NaN;    NaN;   NaN;   NaN;   NaN;   NaN;   NaN;   NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg = UnitConversionPkg.ConvVel([  0; 140; 460; 460; 160; 240; 240; 160], "kts", "m/s");
Mission.VelEnd = UnitConversionPkg.ConvVel([140; 460; 460; 160; 240; 240; 160;   0], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"];
Mission.TypeEnd = ["TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end