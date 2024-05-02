function [Aircraft] = ATRMissionBRE(Aircraft)
%
% [Aircraft] = ATRMissionBRE(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Define a mission for the ATR42 as defined in E-PASS using only the
% Breguet Range Equation.
%
% mission 1: 801 nmi range           | mission 2: 45-  | mission 3: 87 nmi
%                                    | minute loiter   | diversion
%  __________________________________|_________________|_______
%                                    |                 |
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
Mission.Segs = ["CruiseBRE"; "CruiseBRE"; "CruiseBRE"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [          1;           2;           3];

% define the starting/ending altitudes (in m)
Mission.AltBeg =  UnitConversionPkg.ConvLength([   25000;       25000;       25000], "ft", "m");
Mission.AltEnd =  UnitConversionPkg.ConvLength([   25000;       25000;       25000], "ft", "m");

% define the rate of climb/descent (in m/s)
Mission.ClbRate =            [     NaN;         NaN;         NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg =  UnitConversionPkg.ConvVel(   [     300;         300;         300], "kts", "m/s");
Mission.VelEnd =  UnitConversionPkg.ConvVel(   [     300;         300;         300], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg =            [   "TAS";       "TAS";       "TAS"];
Mission.TypeEnd =            [   "TAS";       "TAS";       "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end