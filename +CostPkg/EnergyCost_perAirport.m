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

if nargin < 2
    Origin = "Avg";
    % load fuel/energy pricing table
    PackageDir = fileparts(mfilename("fullpath"));
    priceTable = readtable(fullfile(PackageDir, "Energy_CostbyAirport.xlsx"));
elseif nargin < 3
    PackageDir = fileparts(mfilename("fullpath"));
    priceTable = readtable(fullfile(PackageDir, "Energy_CostbyAirport.xlsx"));
end

% check number of energy sources
Fuel = 1;
Batt = 2;

fuelE = 0;
battE = 0;

if ~isempty(Fuel)
    fuelE = Aircraft.Mission.History.SI.Energy.E_ES(end,Fuel);
end

if ~isempty(Batt)
    battE = Aircraft.Mission.History.SI.Energy.E_ES(end,Batt);
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

Aircraft.Specs.Cost.FOC = DOC;
end
