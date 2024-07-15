function [Aircraft] = SUSAN_DesignMission(Aircraft)
%
% [Aircraft] = NotionalMission00(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% updated for SUSAN by Miranda Stockhausen, mstockha@umich.edu
% last updated: 15 Jul 2024
%
% % Define the design mission (without reserves) for the SUSAN electrofan
% aircraft concept. The mission is similar to that for a Boeing 737-8Max
% with a 2500 nmi range.
%
% mission 1: takeoff and fly to accelerated cruise at 10000 ft
% mission 2: climb to cruise altitude and complete cruise flight
%
%            |   _____________________________       
%            |  /                             \      
%            | /                               \     
%     _______|/                                 \    
%    /       |                                   \
% __/   1    |           mission 2                \__
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
Mission.Target.Valu = [9; UnitConversionPkg.ConvLength(2470, "naut mi", "m")];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Time"; "Dist"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Cruise"; 
    "Climb"; "Cruise"; "Descent"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [1; 1; 1; 1;
    2; 2; 2; 2; 2];

% define the climb rate (in m/s)
Mission.ClbRate = UnitConversionPkg.ConvVel([0; 3000; 2000; 0; ...
    1828.7; 0; -2200; -1500; 0], 'ft/min', 'm/s');

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([0 ; 0; 1500; 10000; ...
    10000; 37000; 37000; 10000; 0], 'ft', 'm');
Mission.AltEnd = UnitConversionPkg.ConvLength([0; 1500; 10000; 10000; ...
    37000; 37000; 10000; 0; 0], 'ft', 'm');

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [0; UnitConversionPkg.ConvVel([150; 250; 250; ...
    300], 'kts', 'm/s'); 0.785; 0.785; UnitConversionPkg.ConvVel([250; 150], 'kts', 'm/s')];
Mission.VelEnd  = [UnitConversionPkg.ConvVel([150; 250; 250; 300], 'kts', 'm/s'); 
    0.785; 0.785; UnitConversionPkg.ConvVel([250; 150], 'kts', 'm/s'); 0];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["Mach"; "EAS"; "EAS"; "EAS";
    "EAS"; "Mach"; "Mach"; "EAS"; "EAS"];
Mission.TypeEnd = ["EAS"; "EAS"; "EAS"; "EAS"; ...
    "Mach"; "Mach"; "EAS"; "EAS"; "Mach"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end