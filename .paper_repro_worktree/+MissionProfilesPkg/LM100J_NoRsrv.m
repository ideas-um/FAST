function [Aircraft] = LM100J_NoRsrv(Aircraft)
%
% [Aircraft] = LM100J_NoRsrv(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define the design mission for a LM100J with no reserve mission. Obtained
% from collaborators at NASA.
%
% mission 1: 2,390 nmi range
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


%% DEFINE THE MISSION TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the targets (in m or min)
Mission.Target.Valu = Aircraft.Specs.Performance.Range;

% define the target types ("Dist" or "Time")
Mission.Target.Type = "Dist";


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["Takeoff"; "Climb"; "Climb"; "Climb"; "Cruise"; "Descent"; "Landing"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [        1;       1;       1;       1;        1;         1;         1];

% define the starting/ending altitudes (in m)
Mission.AltBeg =  UnitConversionPkg.ConvLength([     0;       0;   10000;   17000;    25000;     25000;       0], "ft", "m");
Mission.AltEnd =  UnitConversionPkg.ConvLength([     0;   10000;   17000;   25000;    25000;         0;       0], "ft", "m");

% define a rate of climb/descent (m/s) or NaN for auto-selected rate
Mission.ClbRate =  UnitConversionPkg.ConvVel([     NaN;     NaN;    2000;    1500;      NaN;     -1500;     NaN], "ft/min", "m/s");

% define the starting/ending speeds (m/s or mach)
Mission.VelBeg =  UnitConversionPkg.ConvVel([        0;     200;     210;     300;     0.59;       280;     160], "kts", "m/s");
Mission.VelEnd =  UnitConversionPkg.ConvVel([      200;     200;     300;     300;     0.59;       160;       0], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = [            "TAS";   "TAS";   "TAS";   "TAS";   "Mach";     "TAS";   "TAS"];
Mission.TypeEnd = [            "TAS";   "TAS";   "TAS";   "TAS";   "Mach";     "TAS";   "TAS"];

% update the cruise segment with mach numbers
Mission.VelBeg(5) = 0.59;
Mission.VelEnd(5) = 0.59;

% operational splits to optimize (only needed if running an optimization)
Mission.PowerOpt = [    1;      0;        0;       0;        0;         0;       0];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end