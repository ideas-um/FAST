function Config = GetThermalChargeSettings(Aircraft, PowerStrategy)
% Return configurable conservative NMC ground-charging assumptions.
%
% These values are engineering assumptions for sensitivity analysis, not a
% calibrated representation of a particular production cell. Override any
% field through Aircraft.Settings.BatteryThermalCharge.

if nargin < 2 || isempty(PowerStrategy)
    PowerStrategy = Aircraft.Specs.Battery.Charging;
end

Config = struct;
Config.StateOfHealth_pct = 80;
Config.InitialTemperature_C = 35;
Config.AmbientTemperature_C = 30;
Config.CoolantTemperature_C = 25;
Config.MinimumChargeTemperature_C = 0;
Config.MaximumChargeTemperature_C = 45;
Config.CoolingOnTemperature_C = 32;
Config.CoolingTargetTemperature_C = 30;
Config.PassiveConductance_W_K = 30;
Config.ActiveConductance_W_K = 500;
Config.MaximumCooling_W = 20e3;
Config.CoolingCoefficientOfPerformance = 3;
Config.CellSpecificHeat_J_kgK = 900;
Config.ChargerEfficiency = 0.95;
Config.CoulombicEfficiency = 0.995;
Config.MaximumACPower_W = abs(PowerStrategy);
Config.EndOfChargeCRate = 0.02;
Config.TemperatureBreakpoints_C = [0, 5, 10, 15, 25, 35, 40, 45];
Config.MaximumChargeCRate = [0, 0.10, 0.30, 0.50, 0.80, 0.80, 0.40, 0];
Config.ResistanceTemperatureMultiplier = ...
    [2.40, 1.80, 1.35, 1.12, 1.00, 0.92, 0.95, 1.05];
Config.EndOfLifeMaximumCRate = 0.60;
Config.EndOfLifeResistanceMultiplier = 1.30;
Config.EndOfLifeSOH_pct = 80;
Config.MinimumIntegrationStep_s = 5;

if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "BatterySOH_pct")
    Config.StateOfHealth_pct = Aircraft.Settings.BatterySOH_pct;
elseif isfield(Aircraft.Specs.Battery, "SOH") && ...
        ~isempty(Aircraft.Specs.Battery.SOH)
    Config.StateOfHealth_pct = Aircraft.Specs.Battery.SOH(end);
end
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "BatteryInitialTemperature_C")
    Config.InitialTemperature_C = ...
        Aircraft.Settings.BatteryInitialTemperature_C;
end
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "BatteryThermalCharge")
    UserConfig = Aircraft.Settings.BatteryThermalCharge;
    Names = fieldnames(UserConfig);
    for iName = 1:numel(Names)
        Config.(Names{iName}) = UserConfig.(Names{iName});
    end
end

validateattributes(Config.StateOfHealth_pct, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<=', 100});
validateattributes(Config.InitialTemperature_C, {'numeric'}, ...
    {'scalar', 'real', 'finite'});
validateattributes(Config.MaximumACPower_W, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(Config.ChargerEfficiency, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<=', 1});
validateattributes(Config.CoulombicEfficiency, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>', 0, '<=', 1});
validateattributes(Config.CoolingCoefficientOfPerformance, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
if Config.MaximumChargeTemperature_C <= ...
        Config.MinimumChargeTemperature_C
    error("BatteryPkg:GetThermalChargeSettings:TemperatureLimits", ...
        "Maximum charge temperature must exceed the minimum.");
end
if numel(Config.TemperatureBreakpoints_C) ~= ...
        numel(Config.MaximumChargeCRate) || ...
        numel(Config.TemperatureBreakpoints_C) ~= ...
        numel(Config.ResistanceTemperatureMultiplier)
    error("BatteryPkg:GetThermalChargeSettings:TableSize", ...
        "Temperature-dependent charging tables must have equal lengths.");
end

SOHRange = max(100 - Config.EndOfLifeSOH_pct, eps);
AgeFraction = min(max((100 - Config.StateOfHealth_pct) / SOHRange, 0), 1);
Config.AgeResistanceMultiplier = 1 + AgeFraction * ...
    (Config.EndOfLifeResistanceMultiplier - 1);
Config.AgeMaximumCRate = max(Config.EndOfLifeMaximumCRate, ...
    max(Config.MaximumChargeCRate) - AgeFraction * ...
    (max(Config.MaximumChargeCRate) - Config.EndOfLifeMaximumCRate));
end
