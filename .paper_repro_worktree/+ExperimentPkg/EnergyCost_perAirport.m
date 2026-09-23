function [Aircraft] = EnergyCost_perAirport(Aircraft, Origin, priceTable)
%
%
% Inputs:
%    Aircraft - aircraft model
%    Origin - origin airport code as character (where refueling and recharging take
%    place)
%    priceTable (optional) - to save time or use different price table,
%    otherwise default is uploaded
%   
%
%--------------------------------------------------------------------------

if nargin < 3
    % load fuel/energy pricing table
    priceTable = readtable('\+ExperimentPkg\Energy_CostbyAirport.xlsx');
end

% get the number of points in each segment
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);

% check number of energy sources
Fuel = find(Aircraft.Specs.Propulsion.PropArch.ESType == 1);
Batt = find(Aircraft.Specs.Propulsion.PropArch.ESType == 0);

fuelE = 0;
battE = 0;

if ~isempty(Fuel)
    fuelE = Aircraft.Mission.History.SI.Energy.E_ES(npt,Fuel);
end

if ~isempty(Batt)
    battE = Aircraft.Mission.History.SI.Energy.E_ES(npt,Batt);
end

% convert both from joules to kWh
fuelE = fuelE ./ 3.6e6;
battE = battE ./ 3.6e6;

% find matching airport code index
index = find(strcmp(Origin, priceTable.AirportCode));

% compute cost of fuel and electricity 
fuelCost = priceTable.JetFuelPricekWh(index)*fuelE;
battCost = priceTable.ElectricityPricekWh(index)*battE;

% total for full direct operating cost of flight
DOC = fuelCost + battCost;

Aircraft.Mission.History.SI.Performance.Cost = DOC;
end