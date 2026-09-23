function [Aircraft] = BRECruise02(Aircraft)
%
% [Aircraft] = BRECruise02(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Fly all missions using only the Breguet Range-based cruise segment (see
% below) with a time-based reserve mission.
%
% mission 1: 1,650 nmi range                 | mission 2: 45 minute loiter
%                                            | (modeled as cruise segment)
%                                            |
% ___________________________________________|_________________
%                                            |
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
Mission.Target.Valu = [UnitConversionPkg.ConvLength(1650, "naut mi", "m"); 45];

% define the target types ("Dist" or "Time")
Mission.Target.Type = ["Dist"; "Time"];


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = ["CruiseBRE"; "CruiseBRE"];

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = [          1;           2];

% define the starting/ending altitudes (in m)
Mission.AltBeg = UnitConversionPkg.ConvLength([35000; 35000], "ft", "m");
Mission.AltEnd = UnitConversionPkg.ConvLength([35000; 35000], "ft", "m");

% define the climb rate (in m/s)
Mission.ClbRate = [  NaN;   NaN];

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg = UnitConversionPkg.ConvVel([460; 460], "kts", "m/s");
Mission.VelEnd = UnitConversionPkg.ConvVel([460; 460], "kts", "m/s");

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = ["TAS"; "TAS"];
Mission.TypeEnd = ["TAS"; "TAS"];


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;

% ----------------------------------------------------------

end