function AggregateMetrics = RunAllSequencePowerOptParallel(NumWorkers, MaxIterations, SequenceIndices)
%RUNALLSEQUENCEPOWEROPTPARALLEL Optimize every sequence with checkpoints.
%
% Each successful sequence is saved independently under
% output/sequence_poweropt_checkpoints. Re-running this function skips
% successful checkpoints and retries only missing/failed sequences.

if nargin < 1 || isempty(NumWorkers)
    NumWorkers = min(8, feature("numcores"));
end
if nargin < 2 || isempty(MaxIterations)
    MaxIterations = 5;
end

RootDir = fileparts(mfilename("fullpath"));
CheckpointDir = fullfile(RootDir, "output", "sequence_poweropt_checkpoints");
if ~isfolder(CheckpointDir)
    mkdir(CheckpointDir);
end

HybridData = load(fullfile(RootDir, ...
    "ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat"), "SizedAircraft");
HybridAircraft = HybridData.SizedAircraft;
HybridAircraft.Settings.Analysis.Type = -1;
HybridAircraft.Settings.PowerOptMaxIter = MaxIterations;
HybridAircraft.Specs.Battery.Charging = 150e3;

ConventionalFile = fullfile(RootDir, "ERJ175LR_conventional_current.mat");
if isfile(ConventionalFile)
    ConventionalData = load(ConventionalFile, "ConventionalAircraft");
    ConventionalAircraft = ConventionalData.ConventionalAircraft;
else
    ConventionalAircraft = AircraftSpecsPkg.ERJ175LR;
    ConventionalAircraft.Settings.PrintOut = 0;
    ConventionalAircraft = Main(ConventionalAircraft, ...
        @MissionProfilesPkg.ERJ_ClimbThenAccel);
    save(ConventionalFile, "ConventionalAircraft", "-v7.3");
end
ConventionalAircraft.Settings.Analysis.Type = -1;
ConventionalAircraft.Settings.PrintOut = 0;
ConventionalAircraft.Settings.Table = 0;

SequenceData = load(fullfile(RootDir, "Sequence.mat"), "tables");
Sequences = SequenceData.tables;
SequenceCount = numel(Sequences);
if nargin < 3 || isempty(SequenceIndices)
    SequenceIndices = 1:SequenceCount;
end
SequenceIndices = unique(SequenceIndices(:)');
if any(SequenceIndices < 1 | SequenceIndices > SequenceCount)
    error("Sequence indices must be between 1 and %d.", SequenceCount);
end

Pool = gcp("nocreate");
if isempty(Pool) || Pool.NumWorkers ~= NumWorkers
    if ~isempty(Pool)
        delete(Pool);
    end
    parpool("Processes", NumWorkers);
end

fprintf("Optimizing %d of %d sequences with %d workers and %d iterations.\n", ...
    numel(SequenceIndices), SequenceCount, NumWorkers, MaxIterations);

parfor WorkIndex = 1:numel(SequenceIndices)
    SequenceIndex = SequenceIndices(WorkIndex);
    CheckpointFile = fullfile(CheckpointDir, ...
        sprintf("Sequence_%04d.mat", SequenceIndex));
    if IsSuccessfulCheckpoint(CheckpointFile, MaxIterations)
        continue
    end

    Sequence = Sequences{SequenceIndex};
    try
        [OptimizedAircraft, PCbest, OptimizerTime_min, OptSeqTable] = ...
            OptimizationPkg.SequencePowerOpt(HybridAircraft, Sequence);
        FlightResults = SummarizeHybrid(OptimizedAircraft, Sequence);
        ConventionalResults = FlyConventionalSequence( ...
            ConventionalAircraft, Sequence);

        SequenceSummary = BuildSequenceSummary( ...
            SequenceIndex, FlightResults, ConventionalResults, ...
            OptimizerTime_min);
        Status = "success";
        RunMetadata = struct( ...
            "SequenceIndex", SequenceIndex, ...
            "MaxIterations", MaxIterations, ...
            "ChargerPower_kW", 150, ...
            "ChargingRule", "GROUND_TIME(next flight) - 7 minutes", ...
            "Objective", "Total main-mission fuel burn", ...
            "AircraftSizeFixed", true, ...
            "Completed", string(datetime("now")));

        SaveSuccessCheckpoint(CheckpointFile, Status, Sequence, PCbest, ...
            OptimizerTime_min, OptSeqTable, FlightResults, ...
            ConventionalResults, SequenceSummary, RunMetadata);
    catch ME
        SaveFailureCheckpoint(CheckpointDir, SequenceIndex, MaxIterations, ME);
    end
end

AggregateMetrics = AggregateCheckpoints(CheckpointDir, SequenceCount, ...
    MaxIterations);
save(fullfile(RootDir, ...
    "ERJ175LR_AllSequences_FuelOpt_150kW_Aggregate.mat"), ...
    "AggregateMetrics", "-v7.3");
writetable(AggregateMetrics.SequenceMetrics, fullfile(RootDir, ...
    "ERJ175LR_AllSequences_FuelOpt_150kW_Metrics.csv"));

disp(AggregateMetrics.GeneralMetrics);
end


function IsSuccess = IsSuccessfulCheckpoint(FileName, MaxIterations)
IsSuccess = false;
if ~isfile(FileName)
    return
end
try
    Data = load(FileName, "Status", "RunMetadata");
    IsSuccess = Data.Status == "success" && ...
        Data.RunMetadata.MaxIterations == MaxIterations;
catch
    IsSuccess = false;
end
end


function FlightResults = SummarizeHybrid(OptimizedAircraft, Sequence)
nflight = height(Sequence);
MainFuel_kg = zeros(nflight, 1);
FullFuel_kg = zeros(nflight, 1);
BatteryEnergy_kWh = zeros(nflight, 1);
FullBatteryEnergy_kWh = zeros(nflight, 1);
InitialSOC_pct = zeros(nflight, 1);
FinalSOC_pct = zeros(nflight, 1);

for k = 1:nflight
    Aircraft = OptimizedAircraft.(sprintf("Aircraft%d", k));
    MainSegs = find(Aircraft.Mission.Profile.ID == 1);
    MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
    Batt = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);
    MainFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
    FullFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn(end);
    BatteryEnergy_kWh(k) = ...
        Aircraft.Mission.History.SI.Energy.E_ES(MainEnd, Batt) / 3.6e6;
    FullBatteryEnergy_kWh(k) = ...
        Aircraft.Mission.History.SI.Energy.E_ES(end, Batt) / 3.6e6;
    InitialSOC_pct(k) = Aircraft.Mission.History.SI.Power.SOC(1, Batt);
    FinalSOC_pct(k) = Aircraft.Mission.History.SI.Power.SOC(MainEnd, Batt);
end

FlightResults = table((1:nflight)', Sequence.DISTANCE, ...
    Sequence.GROUND_TIME, MainFuel_kg, FullFuel_kg, ...
    BatteryEnergy_kWh, FullBatteryEnergy_kWh, ...
    InitialSOC_pct, FinalSOC_pct, ...
    'VariableNames', {'Flight', 'Distance_nmi', 'GroundTime_min', ...
    'MainFuel_kg', 'FullFuel_kg', 'BatteryEnergy_kWh', ...
    'FullBatteryEnergy_kWh', 'InitialSOC_pct', 'FinalSOC_pct'});
end


function Results = FlyConventionalSequence(BaseAircraft, Sequence)
nflight = height(Sequence);
MainFuel_kg = zeros(nflight, 1);
FullFuel_kg = zeros(nflight, 1);

for k = 1:nflight
    Aircraft = BaseAircraft;
    Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
        Sequence.DISTANCE(k), "naut mi", "m");
    [~, ~, Mach] = MissionSegsPkg.ComputeFltCon( ...
        Sequence.ALTITUDE_m(k), 0, "TAS", ...
        convvel(Sequence.SPEED_mph(k), "mph", "m/s"));
    Aircraft.Specs.Performance.Vels.Crs = Mach;
    Aircraft.Specs.Performance.Alts.Crs = Sequence.ALTITUDE_m(k);
    Aircraft.Specs.Weight.Payload = convmass( ...
        Sequence.PAYLOAD_lb(k), "lbm", "kg");

    Aircraft = MissionProfilesPkg.ERJ_ClimbThenAccel(Aircraft);
    Aircraft = MissionSegsPkg.ProcessProfile(Aircraft);
    Aircraft = DataStructPkg.InitMissionHistory(Aircraft);
    Aircraft = DataStructPkg.ClearMission(Aircraft);
    Aircraft = PropulsionPkg.LamFill(Aircraft);
    Aircraft = MissionSegsPkg.FlyMission(Aircraft);

    MainSegs = find(Aircraft.Mission.Profile.ID == 1);
    MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
    MainFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
    FullFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn(end);
end

Results = table((1:nflight)', MainFuel_kg, FullFuel_kg, ...
    'VariableNames', {'Flight', 'MainFuel_kg', 'FullFuel_kg'});
end


function Summary = BuildSequenceSummary(Index, Hybrid, Conventional, OptTime)
HybridMain = sum(Hybrid.MainFuel_kg);
HybridFull = sum(Hybrid.FullFuel_kg);
ConvMain = sum(Conventional.MainFuel_kg);
ConvFull = sum(Conventional.FullFuel_kg);

if height(Hybrid) > 1
    MeanInitialSOCExcludingFirst = mean(Hybrid.InitialSOC_pct(2:end));
    MeanFinalSOCExcludingLast = mean(Hybrid.FinalSOC_pct(1:end-1));
else
    MeanInitialSOCExcludingFirst = NaN;
    MeanFinalSOCExcludingLast = NaN;
end

Summary = table(Index, height(Hybrid), sum(Hybrid.Distance_nmi), ...
    HybridMain, ConvMain, ConvMain - HybridMain, ...
    100 * (ConvMain - HybridMain) / ConvMain, ...
    HybridFull, ConvFull, ConvFull - HybridFull, ...
    100 * (ConvFull - HybridFull) / ConvFull, ...
    sum(Hybrid.BatteryEnergy_kWh), ...
    MeanInitialSOCExcludingFirst, MeanFinalSOCExcludingLast, OptTime, ...
    'VariableNames', {'Sequence', 'Flights', 'Distance_nmi', ...
    'HybridMainFuel_kg', 'ConventionalMainFuel_kg', ...
    'MainFuelSaved_kg', 'MainFuelSaved_pct', ...
    'HybridFullFuel_kg', 'ConventionalFullFuel_kg', ...
    'FullFuelSaved_kg', 'FullFuelSaved_pct', ...
    'BatteryEnergy_kWh', 'MeanInitialSOCExcludingFirst_pct', ...
    'MeanFinalSOCExcludingLast_pct', 'OptimizerTime_min'});
end


function SaveSuccessCheckpoint(FileName, Status, Sequence, PCbest, ...
    OptimizerTime_min, OptSeqTable, FlightResults, ...
    ConventionalResults, SequenceSummary, RunMetadata)
save(FileName, "Status", "Sequence", "PCbest", "OptimizerTime_min", ...
    "OptSeqTable", "FlightResults", "ConventionalResults", ...
    "SequenceSummary", "RunMetadata", "-v7.3");
end


function SaveFailureCheckpoint(Directory, Index, MaxIterations, ME)
FailureFile = fullfile(Directory, sprintf("Failed_%04d.mat", Index));
Status = "failed";
SequenceIndex = Index;
ErrorIdentifier = string(ME.identifier);
ErrorMessage = string(ME.message);
ErrorReport = string(getReport(ME, "extended", "hyperlinks", "off"));
Failed = string(datetime("now"));
save(FailureFile, "Status", "SequenceIndex", "MaxIterations", ...
    "ErrorIdentifier", "ErrorMessage", "ErrorReport", "Failed");
end


function Aggregate = AggregateCheckpoints(Directory, Count, MaxIterations)
Rows = cell(Count, 1);
Success = false(Count, 1);
for k = 1:Count
    FileName = fullfile(Directory, sprintf("Sequence_%04d.mat", k));
    if IsSuccessfulCheckpoint(FileName, MaxIterations)
        Data = load(FileName, "SequenceSummary");
        Rows{k} = Data.SequenceSummary;
        Success(k) = true;
    end
end

if any(Success)
    SequenceMetrics = vertcat(Rows{Success});
else
    SequenceMetrics = table;
end

if isempty(SequenceMetrics)
    GeneralMetrics = table(Count, 0, Count, ...
        'VariableNames', {'TotalSequences', 'CompletedSequences', ...
        'RemainingSequences'});
else
    GeneralMetrics = table(Count, height(SequenceMetrics), ...
        Count - height(SequenceMetrics), sum(SequenceMetrics.Flights), ...
        mean(SequenceMetrics.MainFuelSaved_kg), ...
        mean(SequenceMetrics.MainFuelSaved_pct), ...
        100 * sum(SequenceMetrics.MainFuelSaved_kg) / ...
        sum(SequenceMetrics.ConventionalMainFuel_kg), ...
        mean(SequenceMetrics.FullFuelSaved_kg), ...
        mean(SequenceMetrics.FullFuelSaved_pct), ...
        100 * sum(SequenceMetrics.FullFuelSaved_kg) / ...
        sum(SequenceMetrics.ConventionalFullFuel_kg), ...
        mean(SequenceMetrics.MeanInitialSOCExcludingFirst_pct, ...
        "omitnan"), ...
        mean(SequenceMetrics.MeanFinalSOCExcludingLast_pct, "omitnan"), ...
        sum(SequenceMetrics.OptimizerTime_min), ...
        'VariableNames', {'TotalSequences', 'CompletedSequences', ...
        'RemainingSequences', 'CompletedFlights', ...
        'AverageMainFuelSaved_kgPerSequence', ...
        'AverageMainFuelSaved_pctPerSequence', ...
        'FleetWeightedMainFuelSaved_pct', ...
        'AverageFullFuelSaved_kgPerSequence', ...
        'AverageFullFuelSaved_pctPerSequence', ...
        'FleetWeightedFullFuelSaved_pct', ...
        'AverageInitialSOCExcludingFirst_pct', ...
        'AverageFinalSOCExcludingLast_pct', ...
        'TotalOptimizerWorkerTime_min'});
end

Aggregate = struct( ...
    "SequenceMetrics", SequenceMetrics, ...
    "GeneralMetrics", GeneralMetrics, ...
    "CompletedSequenceIndices", find(Success), ...
    "MissingSequenceIndices", find(~Success), ...
    "Generated", string(datetime("now")));
end
