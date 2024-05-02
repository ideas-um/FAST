function [SOCEnd] = GroundCharge(Aircraft, GroundTime, ChrgRate)
%
% [SOCEnd] = GroundCharge(Aircraft, GroundTime, ChrgRate)
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
%
% Simulate aircraft charging at an airport gate.
%
% INPUTS:
%     Aircraft   - structure with information about the aircraft's mission
%                  history and battery SOC after flying.
%                  size/type/units: 1-by-1 / struct / []
%
%     GroundTime - available charging time on the ground.
%                  size/type/units: 1-by-1 / double / [s]
%
%     ChrgRate   - airport charging rate.
%                  size/type/units: 1-by-1 / double / [kW/h]
%
% OUTPUTS:
%     SOCEnd     - state of charge after the ground turn.
%                  size/type/uints: 1-by-1 / double / [%]
%


%% INFO FROM AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SOC upon arrival
SOCBeg = Aircraft.Mission.History.SI.Power.SOC(end);

% number of cells in series and parallel
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;


%% SIMULATE CHARGING %%
%%%%%%%%%%%%%%%%%%%%%%%

% minimum SOC is 0% (fully depleted) and can't be negative
if (SOCBeg < 0)
    SOCBeg = 0;
end

% charge the battery
[~, ~, ~, SOCEnd] = BatteryPkg.Model(ChrgRate, GroundTime, SOCBeg, ...
                                     ParCells,SerCells);

% maximum SOC is 100% (fully charged) and can't be "overcharged"
if (SOCEnd > 100)
    SOCEnd = 100;
end

% ----------------------------------------------------------

end