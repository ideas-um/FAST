function [Aircraft] = SUSAN_NominalMissions(Aircraft)
%
% [Aircraft] = NotionalMission00(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% updated for SUSAN by Miranda Stockhausen, mstockha@umich.edu
% last updated: 14 Aug 2024
%
% Define the design mission (including reserves) for the SUSAN electrofan
% aircraft concept. The mission includes a 2500 nmi design range, a 100 nmi
% diversion, and a 45 minute hold as required by FAA regulation: 
% https://www.ecfr.gov/current/title-14.
% 
%
% mission 1: climb and accelerated cruise
% mission 2: climb to design cruise, then begin descent
% mission 3: 100 nmi diversion (reserve mission i)
% mission 4: 45 minute hold and land (reserve mission ii)
%
%
%                      |  __________________  |          |
%                      | /                  \ |          |
%        ______________|/                    \|________  |
%       /              |                      |        \ |
%      /               |                      |         \|___
%     /                |                      |          |   \
% ___/  mission 1      |           2          |  3       | 4  \___
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
Mission.Target.Valu = [UnitConversionPkg.ConvLength(2500, "naut mi", "m"); UnitConversionPkg.ConvLength(100, "naut mi", "m"); 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Cruise"; "Descent";
    "Cruise"; "Descent"; 
    "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID  = [ 1; 1; 1; 1; 
    2; 2;
    3; 3; 3;]

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([0; 0; 35000; 35000; ...
    10000; 10000;
    1500; 1500; 0], 'ft', 'm');
Mission.AltEnd = UnitConversionPkg.ConvLength([0; 35000; 35000; 10000; ...
    10000; 1500;
    1500; 0; 0], 'ft', 'm');

% define the climb rate (in m/s)
Mission.ClbRate = [0; NaN; 0; NaN; ...
    0; NaN;
    0; NaN; 0];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [0; UnitConversionPkg.ConvVel(150,'kts', 'm/s'); 0.785; 0.785; 
    UnitConversionPkg.ConvVel([250; 250; ...
    165; 165; 150], 'kts', 'm/s')];
Mission.VelEnd  = [UnitConversionPkg.ConvVel(150, 'kts', 'm/s'); 0.785; 0.785; UnitConversionPkg.ConvVel(250, 'kts', 'm/s'); ...
    UnitConversionPkg.ConvVel([250; 165; ...
    165; 150], 'kts', 'm/s'); 0];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["Mach"; "EAS"; "Mach"; "Mach"; ...
    "EAS"; "EAS";
    "EAS"; "EAS"; "EAS"];
Mission.TypeEnd = ["EAS"; "Mach"; "Mach"; "EAS";
    "EAS"; "EAS";
    "EAS"; "EAS"; "Mach"];

%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end