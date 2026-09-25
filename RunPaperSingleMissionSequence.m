% Reproduce the paper's single-mission optimizer over its five-flight sequence.
% Each flight is optimized separately, while SOC is carried through the
% sequence and charging is limited by the scheduled ground time.

clearvars;
clc;

Input = load("ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat", "SizedAircraft");
SequenceData = load("Sequence.mat", "tables");
Sequence = SequenceData.tables{8};
Aircraft = Input.SizedAircraft;
Aircraft.Settings.PowerOptMaxIter = 5;

nflight = height(Sequence);
FlightAircraft = struct();
PCbest = cell(nflight, 1);
OptimizerTime_min = zeros(nflight, 1);
Fuel_kg = zeros(nflight, 1);
BatteryEnergy_kWh = zeros(nflight, 1);
InitialSOC_pct = zeros(nflight, 1);
FinalSOC_pct = zeros(nflight, 1);
ChargeTime_min = zeros(nflight, 1);
PostChargeSOC_pct = zeros(nflight, 1);

for iflight = 1:nflight
    speed = convvel(Sequence.SPEED_mph(iflight), "mph", "m/s");
    Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
        Sequence.DISTANCE(iflight), "naut mi", "m");
    [~, ~, Aircraft.Specs.Performance.Vels.Crs] = ...
        MissionSegsPkg.ComputeFltCon(Sequence.ALTITUDE_m(iflight), 0, "TAS", speed);
    Aircraft.Specs.Performance.Alts.Crs = Sequence.ALTITUDE_m(iflight);
    Aircraft.Specs.Weight.Payload = convmass(Sequence.PAYLOAD_lb(iflight), "lbm", "kg");
    Aircraft.Settings.Analysis.Type = -1;

    [Aircraft, PCbest{iflight}, OptimizerTime_min(iflight)] = ...
        OptimizationPkg.MissionPowerOpt(Aircraft, ...
                                        @MissionProfilesPkg.ERJ_ClimbThenAccel);

    MainSegs = find(Aircraft.Mission.Profile.ID == 1);
    MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
    Batt = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);

    Fuel_kg(iflight) = Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
    BatteryEnergy_kWh(iflight) = ...
        Aircraft.Mission.History.SI.Energy.E_ES(MainEnd, Batt) / 3.6e6;
    InitialSOC_pct(iflight) = Aircraft.Mission.History.SI.Power.SOC(1, Batt);
    FinalSOC_pct(iflight) = Aircraft.Mission.History.SI.Power.SOC(MainEnd, Batt);

    FlightAircraft.(sprintf("Aircraft%d", iflight)) = Aircraft;

    if iflight < nflight
        ChargeTime_min(iflight) = max(Sequence.GROUND_TIME(iflight + 1) - 5, 0);
        Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime_min(iflight) * 60);
        if isfield(Aircraft.Mission.History.SI.Power, "ChargedAC")
            Charged = Aircraft.Mission.History.SI.Power.ChargedAC;
            if isfield(Charged, "SOC")
                PostChargeSOC_pct(iflight) = Charged.SOC(end);
            else
                PostChargeSOC_pct(iflight) = Charged.SOCEnd;
            end
            Aircraft.Specs.Battery.BegSOC = PostChargeSOC_pct(iflight);
        end
    else
        PostChargeSOC_pct(iflight) = FinalSOC_pct(iflight);
    end
end

TotalFuel_kg = sum(Fuel_kg);
TotalBatteryEnergy_kWh = sum(BatteryEnergy_kWh);
PaperFuel_kg = 14696.539532;
PaperBatteryEnergy_kWh = 635.330592;

FlightResults = table((1:nflight)', Sequence.DISTANCE, Sequence.GROUND_TIME, ...
    ChargeTime_min, Fuel_kg, BatteryEnergy_kWh, InitialSOC_pct, FinalSOC_pct, ...
    PostChargeSOC_pct, OptimizerTime_min, ...
    'VariableNames', {'Flight', 'Distance_nmi', 'GroundTime_min', ...
    'ChargeTime_min', 'Fuel_kg', 'BatteryEnergy_kWh', 'InitialSOC_pct', ...
    'FinalSOC_pct', 'PostChargeSOC_pct', 'OptimizerTime_min'});

PaperComparison = table( ...
    ["TotalFuel_kg"; "TotalBatteryEnergy_kWh"], ...
    [PaperFuel_kg; PaperBatteryEnergy_kWh], ...
    [TotalFuel_kg; TotalBatteryEnergy_kWh], ...
    100 .* ([TotalFuel_kg; TotalBatteryEnergy_kWh] - ...
    [PaperFuel_kg; PaperBatteryEnergy_kWh]) ./ ...
    [PaperFuel_kg; PaperBatteryEnergy_kWh], ...
    'VariableNames', {'Metric', 'Paper', 'CurrentBranch', 'DifferencePercent'});

ElectricMotorWeight_kg = sum(Aircraft.Specs.Weight.EM, "all");
RunMetadata = struct("SequenceIndex", 8, ...
    "MaxSQPIterationsPerFlight", 5, ...
    "ChargingRule", "GROUND_TIME(next flight) - 5 minutes", ...
    "AnalysisType", -1, ...
    "OptimizedSchedule", "LamDwn");
save("ERJ175LR_SingleMissionSequence_LamDwn.mat", "FlightAircraft", ...
    "PCbest", "Sequence", "FlightResults", "PaperComparison", ...
    "TotalFuel_kg", "TotalBatteryEnergy_kWh", "ElectricMotorWeight_kg", ...
    "RunMetadata", "-v7.3");

disp(FlightResults);
disp(PaperComparison);
fprintf("Electric motor weight: %.3f kg\n", ElectricMotorWeight_kg);
