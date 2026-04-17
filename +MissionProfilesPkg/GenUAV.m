function [Aircraft] = GenUAV(Aircraft)
%
% [Aircraft] = GenUAV(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 apr 2026
%
% fly a UAV mission using a breguet range/endurance equation based on the
% design mission range/endurance provided in the aircraft data.
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
if (isfield(Aircraft.Specs.Performance, "Range"))
    
    % get the range (in m)
    Mission.Target.Valu = Aircraft.Specs.Performance.Range;
    
    % set a distance-based target
    Mission.Target.Type = "Dist";
    
end

if (isfield(Aircraft.Specs.Performance, "Endurance"))
    
    % get the endurance (in min)
    Mission.Target.Valu = Aircraft.Specs.Performance.Endurance;

    % set a time-based target
    Mission.Target.Type = "Time";

end


%% DEFINE THE MISSION SEGMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the segments
Mission.Segs = "CruiseUAV";

% define the mission id (segments in same mission must be consecutive)
Mission.ID   = 1;

% define the starting/ending altitudes (in m)
Mission.AltBeg = Aircraft.Specs.Performance.Alts.Crs;
Mission.AltEnd = Aircraft.Specs.Performance.Alts.Crs;

% define the climb rate (in m/s)
Mission.ClbRate =  NaN;

% define the starting/ending speeds (in m/s or mach)
Mission.VelBeg = Aircraft.Specs.Performance.Vels.Crs;
Mission.VelEnd = Aircraft.Specs.Performance.Vels.Crs;

% define the speed types (either "TAS", "EAS", or "Mach")
Mission.TypeBeg = "Mach";
Mission.TypeEnd = "Mach";


%% REMEMBER THE MISSION PROFILE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% save the information
Aircraft.Mission.Profile = Mission;


end