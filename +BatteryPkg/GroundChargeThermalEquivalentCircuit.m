function Aircraft = GroundChargeThermalEquivalentCircuit( ...
    Aircraft, ChrgTime, PowerStrategy, TimeStep)
% Charge a battery with a thermally limited, aged equivalent-circuit model.
%
% The controller enforces a hard AC charger power limit, cell-voltage limit,
% temperature/SOH-dependent C-rate limit, and a 0--45 C charging envelope.
% A lumped pack thermal state includes ohmic heat, passive heat transfer, and
% thermostatically controlled liquid cooling.

if nargin < 3 || isempty(PowerStrategy)
    PowerStrategy = Aircraft.Specs.Battery.Charging;
end
if nargin < 4 || isempty(TimeStep)
    TimeStep = 5;
end
validateattributes(ChrgTime, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonnegative'});
validateattributes(TimeStep, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'positive'});
validateattributes(PowerStrategy, {'numeric'}, ...
    {'scalar', 'real', 'finite', 'nonzero'});

Batt = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);
if isempty(Batt)
    error("BatteryPkg:GroundChargeThermalEquivalentCircuit:NoBattery", ...
        "The propulsion architecture does not contain a battery source.");
end
ChargeStartIndex = size(Aircraft.Mission.History.SI.Power.SOC, 1);
if isfield(Aircraft.Settings, "GroundChargeMissionEndIndex") && ...
        isfinite(Aircraft.Settings.GroundChargeMissionEndIndex)
    ChargeStartIndex = min(max(round( ...
        Aircraft.Settings.GroundChargeMissionEndIndex), 1), ...
        ChargeStartIndex);
end
SOCBeg_pct = Aircraft.Mission.History.SI.Power.SOC( ...
    ChargeStartIndex, Batt);
validateattributes(SOCBeg_pct, {'numeric'}, ...
    {'scalar', 'real', 'finite', '>=', 0, '<=', 100});

Config = BatteryPkg.GetThermalChargeSettings(Aircraft, PowerStrategy);
[LandingTemperature_C, FlightTemperature_C] = ...
    BatteryPkg.EstimateLandingBatteryTemperature(Aircraft, Config);

Series = Aircraft.Specs.Power.Battery.SerCells;
Parallel = Aircraft.Specs.Power.Battery.ParCells;
NominalCellCapacity_Ah = Aircraft.Specs.Battery.CapCell;
EffectiveCellCapacity_Ah = NominalCellCapacity_Ah * ...
    Config.StateOfHealth_pct / 100;
EffectivePackCapacity_Ah = EffectiveCellCapacity_Ah * Parallel;
MaximumPackVoltage_V = Aircraft.Specs.Battery.MaxExtVolCell * Series;
PackMass_kg = GetPackMass(Aircraft);
ThermalMass_J_K = max(PackMass_kg * Config.CellSpecificHeat_J_kgK, 1);

dt = max(TimeStep, Config.MinimumIntegrationStep_s);
Time_s = (0:dt:ChrgTime)';
if isempty(Time_s) || Time_s(end) < ChrgTime
    Time_s(end + 1, 1) = ChrgTime;
end
nPoint = numel(Time_s);
SOC = zeros(nPoint, 1);
Temperature_C = zeros(nPoint, 1);
Voltage_V = zeros(nPoint, 1);
Current_A = zeros(nPoint, 1);
PowerDC_W = zeros(nPoint, 1);
PowerAC_W = zeros(nPoint, 1);
ChargerPowerAC_W = zeros(nPoint, 1);
CoolingElectrical_W = zeros(nPoint, 1);
HeatGeneration_W = zeros(nPoint, 1);
Cooling_W = zeros(nPoint, 1);
CRate = zeros(nPoint, 1);
TemperatureLimited = false(nPoint, 1);
PowerLimited = false(nPoint, 1);
VoltageLimited = false(nPoint, 1);

SOC(1) = SOCBeg_pct / 100;
Temperature_C(1) = LandingTemperature_C;
ChargeComplete = false;
for iPoint = 1:nPoint
    [OpenCircuitVoltage_V, PackResistance_Ohm] = ElectricalState( ...
        SOC(iPoint), Temperature_C(iPoint));
    TemperatureCRate = interp1(Config.TemperatureBreakpoints_C, ...
        Config.MaximumChargeCRate, Temperature_C(iPoint), ...
        "linear", 0);
    MaximumCRate = min(max(TemperatureCRate, 0), Config.AgeMaximumCRate);
    CurrentTemperature_A = MaximumCRate * EffectivePackCapacity_Ah;

    PassiveHeat_W = Config.PassiveConductance_W_K * ...
        (Temperature_C(iPoint) - Config.AmbientTemperature_C);
    if Temperature_C(iPoint) >= Config.CoolingOnTemperature_C
        Cooling_W(iPoint) = min(Config.MaximumCooling_W, ...
            Config.ActiveConductance_W_K * max( ...
            Temperature_C(iPoint) - Config.CoolantTemperature_C, 0));
    end
    CoolingElectrical_W(iPoint) = Cooling_W(iPoint) / ...
        Config.CoolingCoefficientOfPerformance;
    AvailableChargerACPower_W = max(Config.MaximumACPower_W - ...
        CoolingElectrical_W(iPoint), 0);
    MaximumDCPower_W = AvailableChargerACPower_W * ...
        Config.ChargerEfficiency;
    if PackResistance_Ohm > eps
        CurrentPower_A = (-OpenCircuitVoltage_V + sqrt( ...
            OpenCircuitVoltage_V^2 + 4 * PackResistance_Ohm * ...
            MaximumDCPower_W)) / (2 * PackResistance_Ohm);
        CurrentVoltage_A = max((MaximumPackVoltage_V - ...
            OpenCircuitVoltage_V) / PackResistance_Ohm, 0);
    else
        CurrentPower_A = MaximumDCPower_W / max(OpenCircuitVoltage_V, eps);
        CurrentVoltage_A = inf;
    end
    CurrentLimit_A = min([CurrentTemperature_A, CurrentPower_A, ...
        CurrentVoltage_A]);
    EndCurrent_A = Config.EndOfChargeCRate * EffectivePackCapacity_Ah;
    OutsideTemperatureEnvelope = Temperature_C(iPoint) <= ...
        Config.MinimumChargeTemperature_C || Temperature_C(iPoint) >= ...
        Config.MaximumChargeTemperature_C;
    if ChargeComplete || OutsideTemperatureEnvelope || ...
            (SOC(iPoint) >= 0.90 && CurrentLimit_A <= EndCurrent_A)
        CurrentLimit_A = 0;
        ChargeComplete = ChargeComplete || SOC(iPoint) >= 0.90;
    end

    Current_A(iPoint) = max(CurrentLimit_A, 0);
    Voltage_V(iPoint) = OpenCircuitVoltage_V + ...
        Current_A(iPoint) * PackResistance_Ohm;
    Voltage_V(iPoint) = min(Voltage_V(iPoint), MaximumPackVoltage_V);
    PowerDC_W(iPoint) = Voltage_V(iPoint) * Current_A(iPoint);
    ChargerPowerAC_W(iPoint) = PowerDC_W(iPoint) / ...
        Config.ChargerEfficiency;
    PowerAC_W(iPoint) = ChargerPowerAC_W(iPoint) + ...
        CoolingElectrical_W(iPoint);
    HeatGeneration_W(iPoint) = Current_A(iPoint)^2 * PackResistance_Ohm;
    CRate(iPoint) = Current_A(iPoint) / EffectivePackCapacity_Ah;
    Tolerance_A = max(1e-6 * max(CurrentLimit_A, 1), 1e-6);
    TemperatureLimited(iPoint) = CurrentTemperature_A <= ...
        min(CurrentPower_A, CurrentVoltage_A) + Tolerance_A;
    PowerLimited(iPoint) = CurrentPower_A <= ...
        min(CurrentTemperature_A, CurrentVoltage_A) + Tolerance_A;
    VoltageLimited(iPoint) = CurrentVoltage_A <= ...
        min(CurrentTemperature_A, CurrentPower_A) + Tolerance_A;

    if iPoint < nPoint
        Step_s = Time_s(iPoint + 1) - Time_s(iPoint);
        AddedCharge_Ah = Config.CoulombicEfficiency * ...
            Current_A(iPoint) * Step_s / 3600;
        SOC(iPoint + 1) = min(SOC(iPoint) + ...
            AddedCharge_Ah / EffectivePackCapacity_Ah, 1);
        Temperature_C(iPoint + 1) = Temperature_C(iPoint) + Step_s * ...
            (HeatGeneration_W(iPoint) - PassiveHeat_W - ...
            Cooling_W(iPoint)) / ThermalMass_J_K;
    end
end

Charged = struct;
Charged.CtrlPtsTimeStep = dt;
Charged.SOCBeg = SOCBeg_pct;
Charged.MissionEndIndex = ChargeStartIndex;
Charged.Time_s = Time_s;
Charged.SOCEnd = 100 * SOC(end);
Charged.SOC = 100 * SOC;
Charged.Voltage = Voltage_V;
Charged.VolCell = Voltage_V / Series;
Charged.Current = -Current_A;
Charged.P_in = PowerDC_W;
Charged.P_AC = PowerAC_W;
Charged.P_ChargerAC = ChargerPowerAC_W;
Charged.P_CoolingAC = CoolingElectrical_W;
Charged.Capacity = EffectivePackCapacity_Ah * SOC;
Charged.C_rate = -CRate;
Charged.Temperature_C = Temperature_C;
Charged.LandingTemperature_C = LandingTemperature_C;
Charged.FlightTemperature_C = FlightTemperature_C;
Charged.TemperatureEnd_C = Temperature_C(end);
Charged.HeatGeneration_W = HeatGeneration_W;
Charged.Cooling_W = Cooling_W;
Charged.TemperatureLimited = TemperatureLimited;
Charged.PowerLimited = PowerLimited;
Charged.VoltageLimited = VoltageLimited;
Charged.MaximumACPower_W = max(PowerAC_W);
Charged.EnergyFromGrid_J = trapz(Time_s, PowerAC_W);
Charged.EnergyToBattery_J = trapz(Time_s, PowerDC_W);
Charged.StateOfHealth_pct = Config.StateOfHealth_pct;
Charged.Model = "Thermal aged equivalent circuit CC-CV";
Charged.Assumptions = Config;
Aircraft.Mission.History.SI.Power.ChargedAC = Charged;
Aircraft.Settings.BatteryInitialTemperature_C = Temperature_C(end);
Aircraft.Settings.BatterySOH_pct = Config.StateOfHealth_pct;

    function [OCV_V, Resistance_Ohm] = ElectricalState(SOCFraction, Temp_C)
        SOCSafe = min(max(SOCFraction, 0.01), 1);
        DischargedCapacity_Ah = (1 - SOCSafe) * NominalCellCapacity_Ah;
        PolarizationVoltage_V = 0.0011;
        DischargeCurveSlope = 0.29732;
        CellOCV_V = Aircraft.Specs.Battery.MaxExtVolCell + ...
            Aircraft.Specs.Battery.ExpVol * exp( ...
            -Aircraft.Specs.Battery.ExpCap * DischargedCapacity_Ah) - ...
            PolarizationVoltage_V * DischargedCapacity_Ah / SOCSafe - ...
            DischargeCurveSlope * DischargedCapacity_Ah;
        CellResistance_Ohm = Aircraft.Specs.Battery.IntResist + ...
            PolarizationVoltage_V / (1.1 - SOCSafe);
        TemperatureMultiplier = interp1( ...
            Config.TemperatureBreakpoints_C, ...
            Config.ResistanceTemperatureMultiplier, Temp_C, ...
            "linear", "extrap");
        OCV_V = CellOCV_V * Series;
        Resistance_Ohm = CellResistance_Ohm * Series / Parallel * ...
            max(TemperatureMultiplier, 0.1) * ...
            Config.AgeResistanceMultiplier;
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
    PackMass_kg = Energy_J / ...
        (Aircraft.Specs.Power.SpecEnergy.Batt * 3.6e6);
end
end
