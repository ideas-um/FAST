function [Aircraft] = A320(Aircraft)
%
% [Aircraft] = A320(Aircraft)
% written by Max Arnson, marnson@umich.edu
% last updated: 28 feb 2023
%
% define an A320(Neo) design mission
% (see below).
%
% mission 1: 3400/3 nmi climb and cruise  
% mission 2: 3400/3 nmi climb and cruise
% mission 3: 3400/3 nmi climb and cruise and descent
% mission 4: climb and divert, descend
% mission 5: hold for 30 minutes
%             |          |                   |              |
%             |          | _________         |              |
%             | _________|/         \        |              |
%        _____|/         |           \       |              |
%       /     |          |            \      |              |
%      /      |          |             \     |  __________  |
%     /       |          |              \    | /          \ |  
%    /        |          |               \___|/            \|______
% __/         |          |                   |              |      \__
%      1            2                3               4            5
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
Ranges = UnitConversionPkg.ConvLength([3400/3; 3400/3; 3400/3; 200],'naut mi', 'm');
Mission.Target.Valu = [Ranges; 30];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Dist"; "Dist"; "Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Cruise";
    "Climb"; "Cruise"; 
    "Climb"; "Cruise"; "Descent"; 
    "Climb"; "Cruise"; "Descent"; 
    "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [ 1; 1; 1; 1;
    2; 2;
    3; 3; 3;
    4; 4; 4;
    5; 5; 5];

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([ 0; 0; 10000; 35000;
    35000; 37000;
    37000; 39000; 39000;
    1500; 15000; 15000;
    1500; 1500; 0],'ft','m');

Mission.AltEnd = UnitConversionPkg.ConvLength([ 0; 10000; 35000; 35000;
    37000; 37000;
    39000; 39000; 1500;
    15000; 15000; 1500;
    1500; 0; 0],'ft','m');

% define the climb rate (in m/s)
Mission.ClbRate = [ NaN; NaN; NaN; NaN;
    NaN; NaN;
    NaN; NaN; NaN;
    NaN; NaN; NaN;
    NaN; NaN; NaN];

% define the starting/ending speeds
Mission.VelBeg  = [ 0; 0.3; UnitConversionPkg.ConvVel(250,'kts','m/s'); 0.78;
    0.78; 0.78;
    0.78; 0.78; 0.78;
    0.3; 0.3; 0.3;
    0.3; 0.3; 0.3];

Mission.VelEnd  = [ 0.3; UnitConversionPkg.ConvVel(250,'kts','m/s'); 0.78; 0.78;
    0.78; 0.78;
    0.78; 0.78; 0.3;
    0.3; 0.3; 0.3;
    0.3; 0.3; 0];

% define the speed types
Mission.TypeBeg = [ "Mach"; "Mach"; "TAS"; "Mach";
    "Mach"; "Mach";
    "Mach"; "Mach"; "Mach";
    "Mach"; "Mach"; "Mach";
    "Mach"; "Mach"; "Mach"];

Mission.TypeEnd = [ "Mach"; "TAS"; "Mach"; "Mach";
    "Mach"; "Mach";
    "Mach"; "Mach"; "Mach";
    "Mach"; "Mach"; "Mach";
    "Mach"; "Mach"; "Mach"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end