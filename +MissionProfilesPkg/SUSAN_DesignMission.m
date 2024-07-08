function [Aircraft] = SUSAN_DesignMission(Aircraft)
%
% [Aircraft] = NotionalMission00(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% updated for SUSAN by Miranda Stockhausen, mstockha@umich.edu
% last updated: 8 Jul 2024
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
%    /     Design Range: 2500 nmi        \
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


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = Aircraft.Specs.Performance.Range;

% define the target types ("Dist" or "Time")
Mission.Target.Type = "Dist";


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = ones(length(Mission.Segs), 1);

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([0 ; 1500; 10000; 37000; 37000; 1500], 'ft', 'm');
Mission.AltEnd = UnitConversionPkg.ConvLength([1500 ; 10000; 37000; 37000; 1500; 0], 'ft', 'm');

% define the climb rate (in m/s)
Mission.ClbRate = [NaN; NaN; NaN; NaN; NaN; NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg  = [0; UnitConversionPkg.ConvVel([250; 250], 'kts', 'm/s'); 0.785; 0.785; UnitConversionPkg.ConvVel(250, 'kts', 'm/s')];
Mission.VelEnd  = [UnitConversionPkg.ConvVel([250; 250], 'kts', 'm/s'); 0.785; 0.785; UnitConversionPkg.ConvVel(250, 'kts', 'm/s'); 0];

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS"; "TAS"; "TAS"; "Mach"; "Mach"; "TAS"];
Mission.TypeEnd = ["TAS"; "TAS"; "Mach"; "Mach"; "TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end