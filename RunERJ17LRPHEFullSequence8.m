% Jointly optimize all five flights in Sequence 8 using one fixed-size PHE.

clearvars;
clc;
RunTimer = tic;

if isfile(fullfile("output", "ERJ17LR_PHE_sized.mat"))
    Input = load(fullfile("output", "ERJ17LR_PHE_sized.mat"), "SizedPHE");
    Aircraft = Input.SizedPHE;
    InputFile = fullfile("output", "ERJ17LR_PHE_sized.mat");
else
    Input = load(fullfile("output", "ERJ17LR_PHE_sized_cycle_fixed.mat"), "A");
    Aircraft = Input.A;
    InputFile = fullfile("output", "ERJ17LR_PHE_sized_cycle_fixed.mat");
end

SequenceData = load("Sequence.mat", "tables");
Sequence = SequenceData.tables{8};
Aircraft.Settings.Analysis.Type = -1;
Aircraft.Settings.PowerOptMaxIter = 500;
Aircraft.Settings.PowerOptMaxStarts = 1;
Aircraft.Specs.Battery.Charging = 150e3;

[OptimizedAircraft, PCbest, OptimizerTime_min, OptSeqTable, ...
    ExitFlag, OptimizerOutput] = ...
    OptimizationPkg.SequencePowerOpt(Aircraft, Sequence);

nflight = height(Sequence);
Fuel_kg = zeros(nflight, 1);
BatteryEnergy_kWh = zeros(nflight, 1);
InitialSOC_pct = zeros(nflight, 1);
FinalSOC_pct = zeros(nflight, 1);
PostChargeSOC_pct = zeros(nflight, 1);
ChargeTime_min = zeros(nflight, 1);

for iflight = 1:nflight
    A = OptimizedAircraft.(sprintf("Aircraft%d", iflight));
    MainSegs = find(A.Mission.Profile.ID == 1);
    MainEnd = A.Mission.Profile.SegEnd(MainSegs(end));
    Batt = find(A.Specs.Propulsion.PropArch.SrcType == 0, 1);
    Fuel_kg(iflight) = A.Mission.History.SI.Weight.Fburn(MainEnd);
    BatteryEnergy_kWh(iflight) = ...
        A.Mission.History.SI.Energy.E_ES(MainEnd, Batt) / 3.6e6;
    InitialSOC_pct(iflight) = A.Mission.History.SI.Power.SOC(1, Batt);
    FinalSOC_pct(iflight) = A.Mission.History.SI.Power.SOC(MainEnd, Batt);
    if iflight < nflight
        ChargeTime_min(iflight) = max(Sequence.GROUND_TIME(iflight + 1) - 7, 0);
        Charged = A.Mission.History.SI.Power.ChargedAC;
        if isfield(Charged, "SOC")
            PostChargeSOC_pct(iflight) = Charged.SOC(end);
        else
            PostChargeSOC_pct(iflight) = Charged.SOCEnd;
        end
    else
        PostChargeSOC_pct(iflight) = FinalSOC_pct(iflight);
    end
end

TotalFuel_kg = sum(Fuel_kg);
TotalBatteryEnergy_kWh = sum(BatteryEnergy_kWh);
FlightResults = table((1:nflight)', Sequence.DISTANCE, Sequence.GROUND_TIME, ...
    ChargeTime_min, Fuel_kg, BatteryEnergy_kWh, InitialSOC_pct, ...
    FinalSOC_pct, PostChargeSOC_pct, ...
    'VariableNames', {'Flight', 'Distance_nmi', 'GroundTime_min', ...
    'ChargeTime_min', 'Fuel_kg', 'BatteryEnergy_kWh', 'InitialSOC_pct', ...
    'FinalSOC_pct', 'PostChargeSOC_pct'});

TotalRunTime_min = toc(RunTimer) / 60;
RunMetadata = struct("SequenceIndex", 8, "InputFile", InputFile, ...
    "AnalysisType", -1, "AircraftSizeFixed", true, ...
    "MaxIterations", 500, "MaxStarts", 1, ...
    "ChargerPower_kW", 150, ...
    "ChargingRule", "GROUND_TIME(next flight) - 7 minutes", ...
    "ObjectiveBoundary", "End of main mission (Mission.Profile.ID == 1)");

save(fullfile("output", "ERJ17LR_PHE_Sequence8_SequenceOpt_150kW_500iter_FullPowerConstraint.mat"), ...
    "OptimizedAircraft", "PCbest", "OptimizerTime_min", "OptSeqTable", ...
    "ExitFlag", "OptimizerOutput", "Sequence", "FlightResults", ...
    "TotalFuel_kg", "TotalBatteryEnergy_kWh", "RunMetadata", ...
    "TotalRunTime_min", "-v7.3");

disp(FlightResults);
fprintf("Sequence total main-mission fuel: %.9f kg\n", TotalFuel_kg);
fprintf("Sequence exit flag %d after %d iterations; runtime %.3f min.\n", ...
    ExitFlag, OptimizerOutput.iterations, TotalRunTime_min);
