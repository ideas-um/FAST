function [TemperatureEnd_C, TemperatureHistory_C] = ...
    EstimateLandingBatteryTemperature(Aircraft, Config)
% Estimate pack temperature through a flown mission using a lumped model.

if nargin < 2 || isempty(Config)
    Config = BatteryPkg.GetThermalChargeSettings(Aircraft);
end
TemperatureEnd_C = Config.InitialTemperature_C;
TemperatureHistory_C = TemperatureEnd_C;
if ~isfield(Aircraft, "Mission") || ...
        ~isfield(Aircraft.Mission, "History") || ...
        ~isfield(Aircraft.Mission.History, "SI")
    return
end
History = Aircraft.Mission.History.SI;
if ~isfield(History, "Performance") || ...
        ~isfield(History.Performance, "Time") || ...
        ~isfield(History, "Power") || ~isfield(History.Power, "Current")
    return
end
Batt = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);
if isempty(Batt) || size(History.Power.Current, 2) < Batt
    return
end

Time_s = History.Performance.Time(:);
Current_A = History.Power.Current(:, Batt);
nPoint = min(numel(Time_s), numel(Current_A));
if isfield(Aircraft.Settings, "GroundChargeMissionEndIndex") && ...
        isfinite(Aircraft.Settings.GroundChargeMissionEndIndex)
    nPoint = min(nPoint, max(round( ...
        Aircraft.Settings.GroundChargeMissionEndIndex), 1));
end
if nPoint < 2
    return
end
Time_s = Time_s(1:nPoint);
Current_A = Current_A(1:nPoint);
Valid = isfinite(Time_s) & isfinite(Current_A);
Time_s = Time_s(Valid);
Current_A = Current_A(Valid);
if numel(Time_s) < 2
    return
end

Series = Aircraft.Specs.Power.Battery.SerCells;
Parallel = Aircraft.Specs.Power.Battery.ParCells;
PackMass_kg = GetPackMass(Aircraft);
ThermalMass_J_K = max(PackMass_kg * Config.CellSpecificHeat_J_kgK, 1);
BasePackResistance_Ohm = Aircraft.Specs.Battery.IntResist * Series / Parallel;
TemperatureHistory_C = zeros(numel(Time_s), 1);
TemperatureHistory_C(1) = TemperatureEnd_C;
for iPoint = 2:numel(Time_s)
    dt = max(Time_s(iPoint) - Time_s(iPoint - 1), 0);
    if dt == 0
        TemperatureHistory_C(iPoint) = TemperatureEnd_C;
        continue
    end
    ResistanceFactor = interp1(Config.TemperatureBreakpoints_C, ...
        Config.ResistanceTemperatureMultiplier, TemperatureEnd_C, ...
        "linear", "extrap");
    Resistance_Ohm = BasePackResistance_Ohm * ...
        max(ResistanceFactor, 0.1) * Config.AgeResistanceMultiplier;
    HeatGeneration_W = Current_A(iPoint - 1)^2 * Resistance_Ohm;
    PassiveHeat_W = Config.PassiveConductance_W_K * ...
        (TemperatureEnd_C - Config.AmbientTemperature_C);
    ActiveCooling_W = 0;
    if TemperatureEnd_C > Config.CoolingTargetTemperature_C
        ActiveCooling_W = min(Config.MaximumCooling_W, ...
            Config.ActiveConductance_W_K * max( ...
            TemperatureEnd_C - Config.CoolantTemperature_C, 0));
    end
    TemperatureEnd_C = TemperatureEnd_C + dt * ...
        (HeatGeneration_W - PassiveHeat_W - ActiveCooling_W) / ...
        ThermalMass_J_K;
    TemperatureHistory_C(iPoint) = TemperatureEnd_C;
end
end

function PackMass_kg = GetPackMass(Aircraft)
PackMass_kg = NaN;
if isfield(Aircraft.Specs, "Weight") && ...
        isfield(Aircraft.Specs.Weight, "Batt")
    PackMass_kg = sum(Aircraft.Specs.Weight.Batt, "all");
end
if ~isfinite(PackMass_kg) || PackMass_kg <= 0
    Series = Aircraft.Specs.Power.Battery.SerCells;
    Parallel = Aircraft.Specs.Power.Battery.ParCells;
    Energy_J = Aircraft.Specs.Battery.CapCell * ...
        Aircraft.Specs.Battery.NomVolCell * Series * Parallel * 3600;
    SpecificEnergy_J_kg = Aircraft.Specs.Power.SpecEnergy.Batt * 3.6e6;
    PackMass_kg = Energy_J / SpecificEnergy_J_kg;
end
end
