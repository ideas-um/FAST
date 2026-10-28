function Aggregate = RunAllSequencesFullComparisonParallel( ...
        NumWorkers, MaxIterations, SequenceIndices)
%RUNALLSEQUENCESFULLCOMPARISONPARALLEL Production comparison for Sequence.mat.
%
% Runs, for every selected daily sequence:
%   1) regular unoptimized PHE dispatch, replayed in fixed-command mode (-2),
%   2) sequential individual-flight MissionPowerOpt,
%   3) joint SequencePowerOpt, and
%   4) conventional off-design operation.
%
% Work is parallelized across sequences. Each sequence is independently
% checkpointed and contains complete mission histories, final lightweight
% flight specifications, optimizer controls, charge histories, flight-level
% results, and daily metrics. Full aircraft databases are saved once rather
% than duplicated thousands of times.

if nargin < 1 || isempty(NumWorkers)
    NumWorkers = 6;
end
if nargin < 2 || isempty(MaxIterations)
    MaxIterations = 500;
end

RunVersion = "all-sequences-thermal-fixed-evaluator-v3-true-lamups";
RootDir = fileparts(mfilename("fullpath"));
% Preserve every checkpoint from the earlier mixed-evaluator run. Corrected
% results are written to a separate directory so no completed work is lost.
RequestedOutputDir = string(getenv("FAST_SEQUENCE_OUTPUT_DIR"));
if strlength(RequestedOutputDir) == 0
    OutputDir = fullfile(RootDir, "output", ...
        "all_sequences_full_comparison_fixed_evaluator");
else
    OutputDir = char(RequestedOutputDir);
end
CheckpointDir = fullfile(OutputDir, "checkpoints");
FailureDir = fullfile(OutputDir, "failures");
if ~isfolder(CheckpointDir), mkdir(CheckpointDir); end
if ~isfolder(FailureDir), mkdir(FailureDir); end

SequenceData = load(fullfile(RootDir, "Sequence.mat"), "tables");
Sequences = SequenceData.tables;
nSequence = numel(Sequences);
if nargin < 3 || isempty(SequenceIndices)
    SequenceIndices = 1:nSequence;
end
SequenceIndices = unique(SequenceIndices(:)');
if any(SequenceIndices < 1 | SequenceIndices > nSequence)
    error("Sequence indices must be between 1 and %d.", nSequence);
end

PHEInputFile = ResolveInputFile("FAST_PHE_INPUT_FILE", fullfile( ...
    RootDir, "output", "ERJ175LR_PHE_Sized.mat"));
ConventionalInputFile = ResolveInputFile( ...
    "FAST_CONVENTIONAL_INPUT_FILE", fullfile(RootDir, "output", ...
    "ERJ175LR_Conventional_RegularTakeoff_Calibrated.mat"));
PHEData = load(PHEInputFile, "SizedAircraft");
BasePHE = PHEData.SizedAircraft;
BasePHE.Specs.Battery.Charging = 150e3;
BasePHE.Settings.GroundChargeModel = "ThermalEquivalentCircuit";
BasePHE.Settings.BatterySOH_pct = 80;
BasePHE.Settings.BatteryInitialTemperature_C = 35;
BasePHE.Settings.PrintOut = 0;
BasePHE.Settings.Plotting = 0;
BasePHE.Settings.Table = 0;

ConventionalData = load(ConventionalInputFile, "C");
BaseConventional = ConventionalData.C;
BaseConventional.Settings.PrintOut = 0;
BaseConventional.Settings.Plotting = 0;
BaseConventional.Settings.Table = 0;

InputMetadata = struct( ...
    "RunVersion", RunVersion, ...
    "SequenceFile", "Sequence.mat", ...
    "PHEInputFile", string(PHEInputFile), ...
    "ConventionalInputFile", string(ConventionalInputFile), ...
    "SequenceCount", nSequence, ...
    "MaxIterations", MaxIterations, ...
    "ParallelWorkers", NumWorkers, ...
    "GroundChargeModel", "ThermalEquivalentCircuit", ...
    "ChargerPower_kW", 150, ...
    "BatterySOH_pct", 80, ...
    "InitialBatteryTemperature_C", 35, ...
    "ReserveDispatch", "Turbine only", ...
    "ChargingRule", "GROUND_TIME(next flight) - 7 minutes", ...
    "Generated", string(datetime("now")));
save(fullfile(OutputDir, "BaseAircraftAndRunInputs.mat"), ...
    "BasePHE", "BaseConventional", "InputMetadata", "-v7.3");

Pool = gcp("nocreate");
if NumWorkers > 1
    if isempty(Pool) || Pool.NumWorkers ~= NumWorkers
        if ~isempty(Pool), delete(Pool); end
        parpool("Processes", NumWorkers);
    end
elseif ~isempty(Pool)
    delete(Pool);
end

% Conventional off-design missions depend only on the four flight inputs
% used by ConfigureFlight, not on sequence SOC/temperature history.  The
% 3,408 rows in Sequence.mat collapse to only 80 unique flight conditions,
% so cache those exact FAST results once and reuse them without introducing
% a surrogate or changing the mission physics.
RequestedCacheDir = string(getenv("FAST_CONVENTIONAL_CACHE_DIR"));
if strlength(RequestedCacheDir) == 0
    ConventionalCacheDir = fullfile(OutputDir, ...
        "conventional_flight_cache");
else
    ConventionalCacheDir = char(RequestedCacheDir);
end
[ConventionalCatalog, ConventionalCacheDir] = BuildConventionalCache( ...
    BaseConventional, Sequences, ConventionalCacheDir, RunVersion, ...
    NumWorkers > 1);

if string(getenv("FAST_PREPARE_CACHE_ONLY")) == "1"
    Aggregate = struct("PreparedConventionalCache", ...
        string(ConventionalCacheDir), "Generated", string(datetime("now")));
    save(fullfile(OutputDir, "GreatLakes_PrepareComplete.mat"), ...
        "Aggregate", "InputMetadata");
    fprintf("Conventional cache preparation complete: %s\n", ...
        ConventionalCacheDir);
    return;
end

fprintf(['Starting %d selected sequences of %d with %d process workers ' ...
    'and %d optimizer iterations.\n'], numel(SequenceIndices), ...
    nSequence, NumWorkers, MaxIterations);

SelectedSequences = Sequences(SequenceIndices);
if NumWorkers == 1
    for iWork = 1:numel(SequenceIndices)
        RunSequenceWorkItem(iWork, SequenceIndices, SelectedSequences, ...
            BasePHE, ConventionalCatalog, ConventionalCacheDir, ...
            MaxIterations, RunVersion, CheckpointDir, FailureDir);
    end
else
    parfor iWork = 1:numel(SequenceIndices)
        RunSequenceWorkItem(iWork, SequenceIndices, SelectedSequences, ...
            BasePHE, ConventionalCatalog, ConventionalCacheDir, ...
            MaxIterations, RunVersion, CheckpointDir, FailureDir);
    end
end

Aggregate = AggregateCheckpoints(CheckpointDir, nSequence, ...
    RunVersion, MaxIterations);
save(fullfile(OutputDir, "AllSequences_Aggregate.mat"), ...
    "Aggregate", "InputMetadata", "-v7.3");
writetable(Aggregate.SequenceSummary, fullfile(OutputDir, ...
    "AllSequences_SequenceSummary.csv"));
writetable(Aggregate.FlightResults, fullfile(OutputDir, ...
    "AllSequences_FlightResults.csv"));
writetable(Aggregate.ChargeResults, fullfile(OutputDir, ...
    "AllSequences_ChargeResults.csv"));
writetable(Aggregate.FleetMetrics, fullfile(OutputDir, ...
    "AllSequences_FleetMetrics.csv"));

disp(Aggregate.FleetMetrics);
end


function RunSequenceWorkItem(iWork, SequenceIndices, SelectedSequences, ...
        BasePHE, ConventionalCatalog, ConventionalCacheDir, ...
        MaxIterations, RunVersion, CheckpointDir, FailureDir)
iSequence = SequenceIndices(iWork);
CheckpointFile = fullfile(CheckpointDir, ...
    sprintf("Sequence_%04d.mat", iSequence));
if IsCompleteCheckpoint(CheckpointFile, RunVersion, MaxIterations)
    return;
end
try
    RunOneSequence(iSequence, SelectedSequences{iWork}, BasePHE, ...
        ConventionalCatalog, ConventionalCacheDir, MaxIterations, ...
        RunVersion, CheckpointFile);
catch ME
    SaveFailure(FailureDir, iSequence, RunVersion, MaxIterations, ME);
end
end


function FileName = ResolveInputFile(EnvironmentVariable, DefaultFile)
Requested = string(getenv(EnvironmentVariable));
if strlength(Requested) == 0
    FileName = DefaultFile;
else
    FileName = char(Requested);
end
if ~isfile(FileName)
    error("RunAllSequences:MissingInputFile", ...
        "%s does not exist. Set %s to the staged input file.", ...
        FileName, EnvironmentVariable);
end
end


function RunOneSequence(iSequence, Sequence, BasePHE, ...
        ConventionalCatalog, ConventionalCacheDir, MaxIterations, ...
        RunVersion, CheckpointFile)
SequenceTimer = tic;
nFlight = height(Sequence);

% Find the regular -1 operational dispatch, then project/replay it through
% the exact same fixed-command -2 evaluator used by MissionPowerOpt. This
% makes baseline and optimized fuel directly comparable.
[UnoptimizedAircraft, UnoptimizedCharge, UnoptimizedPC, ...
    UnoptimizedReplayOutput] = FlyUnoptimizedSequence( ...
    BasePHE, Sequence);

% Independent optimizer, with landing SOC -> thermal ground charge -> next
% flight beginning SOC and temperature.
[IndividualAircraft, IndividualPC, IndividualExitFlag, ...
    IndividualOptimizerOutput, IndividualOptimizerTime_min, ...
    IndividualCharge] = FlyIndividualSequence( ...
    BasePHE, Sequence, MaxIterations, UnoptimizedPC);

% Seed joint optimization with the exact feasible unoptimized -2 replay
% and its matching fuel/MTOW state. The unoptimized sequence is the required
% incumbent: joint optimization may improve it, but may never start from a
% different (for example, individually optimized) operating trajectory.
JointInput = ConfigureOptimizer(BasePHE, MaxIterations);
JointInput.Settings.Analysis.Type = -2;
if all(cellfun(@(x) ~isempty(x), UnoptimizedPC))
    JointInput.Settings.PowerOptInitialPC = cat(2, UnoptimizedPC{:});
    JointInput.Settings.PowerOptInitialFuel_kg = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Specs.Weight.Fuel, ...
        (1:nFlight)');
    JointInput.Settings.PowerOptInitialMTOW_kg = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Specs.Weight.MTOW, ...
        (1:nFlight)');
    JointInput.Settings.PowerOptInitialLamDwn = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Mission.History.SI.Power.LamDwn, ...
        (1:nFlight)', "UniformOutput", false);
end
[JointAircraft, JointPC, JointOptimizerTime_min, JointOptSeqTable, ...
    JointExitFlag, JointOptimizerOutput] = ...
    OptimizationPkg.SequencePowerOpt(JointInput, Sequence);
JointCharge = ReplayCharges(JointAircraft, Sequence);

% Numerical termination, differing availability conventions, or a failed
% local search must never make an "optimized" saved case worse than the
% feasible unoptimized -2 incumbent. Retain the incumbent trajectory when
% either optimizer fails to improve the complete sequence total.
UnoptimizedFeasible = all(cellfun(@(x) ...
    isfield(x, "Feasible") && logical(x.Feasible), ...
    UnoptimizedReplayOutput));
UnoptimizedFuel_kg = SequenceMainMissionFuel(UnoptimizedAircraft, nFlight);
IndividualFuelBeforeFallback_kg = ...
    SequenceMainMissionFuel(IndividualAircraft, nFlight);
if UnoptimizedFeasible && ...
        IndividualFuelBeforeFallback_kg > UnoptimizedFuel_kg + 1.0e-6
    IndividualAircraft = UnoptimizedAircraft;
    IndividualPC = UnoptimizedPC;
    IndividualCharge = UnoptimizedCharge;
    for k = 1:nFlight
        IndividualOptimizerOutput{k}.FallbackToUnoptimized = true;
        IndividualOptimizerOutput{k}.SequenceFuelBeforeFallback_kg = ...
            IndividualFuelBeforeFallback_kg;
        IndividualOptimizerOutput{k}.UnoptimizedSequenceFuel_kg = ...
            UnoptimizedFuel_kg;
    end
end

JointFuelBeforeFallback_kg = SequenceMainMissionFuel(JointAircraft, nFlight);
if UnoptimizedFeasible && ...
        JointFuelBeforeFallback_kg > UnoptimizedFuel_kg + 1.0e-6
    JointAircraft = UnoptimizedAircraft;
    JointPC = cat(2, UnoptimizedPC{:});
    JointCharge = UnoptimizedCharge;
    JointOptimizerOutput.FallbackToUnoptimized = true;
    JointOptimizerOutput.SequenceFuelBeforeFallback_kg = ...
        JointFuelBeforeFallback_kg;
    JointOptimizerOutput.UnoptimizedSequenceFuel_kg = UnoptimizedFuel_kg;
end

[ConventionalAircraft] = FlyConventionalSequence( ...
    Sequence, ConventionalCatalog, ConventionalCacheDir);

[UnoptimizedFlight, UnoptimizedChargeTable] = SummarizePHE( ...
    UnoptimizedAircraft, UnoptimizedCharge, Sequence, "Unoptimized");
UnoptimizedFlight.Feasible = cellfun(@(x) ...
    isfield(x, "Feasible") && logical(x.Feasible), ...
    UnoptimizedReplayOutput);
[IndividualFlight, IndividualChargeTable] = SummarizePHE( ...
    IndividualAircraft, IndividualCharge, Sequence, "Individual");
[JointFlight, JointChargeTable] = SummarizePHE( ...
    JointAircraft, JointCharge, Sequence, "Joint");
ConventionalFlight = SummarizeConventional( ...
    ConventionalAircraft, Sequence);

FlightResults = [JointFlight; IndividualFlight; UnoptimizedFlight; ...
    ConventionalFlight];
ChargeResults = [JointChargeTable; IndividualChargeTable; ...
    UnoptimizedChargeTable];
SequenceSummary = BuildSequenceSummary(iSequence, Sequence, JointFlight, ...
    IndividualFlight, UnoptimizedFlight, ConventionalFlight, ...
    JointChargeTable, IndividualChargeTable, UnoptimizedChargeTable, ...
    JointOptimizerTime_min, sum(IndividualOptimizerTime_min), ...
    JointExitFlag, IndividualExitFlag);

% Save mission histories and compact flight specs. These retain everything
% required to reprocess power, fuel, SOC, trajectory, and split results
% without repeating an optimization, but omit repeated heavyweight aircraft
% databases.
MissionResults = struct( ...
    "Joint", CompactAircraftSet(JointAircraft, Sequence), ...
    "Individual", CompactAircraftSet(IndividualAircraft, Sequence), ...
    "Unoptimized", CompactAircraftSet(UnoptimizedAircraft, Sequence), ...
    "Conventional", CompactAircraftSet(ConventionalAircraft, Sequence));
ChargeHistories = struct( ...
    "Joint", {JointCharge}, ...
    "Individual", {IndividualCharge}, ...
    "Unoptimized", {UnoptimizedCharge});
OptimizerResults = struct( ...
    "JointPC", JointPC, ...
    "JointExitFlag", JointExitFlag, ...
    "JointOutput", JointOptimizerOutput, ...
    "JointTime_min", JointOptimizerTime_min, ...
    "JointSequenceTable", JointOptSeqTable, ...
    "IndividualPC", {IndividualPC}, ...
    "IndividualExitFlag", IndividualExitFlag, ...
    "IndividualOutput", {IndividualOptimizerOutput}, ...
    "IndividualTime_min", IndividualOptimizerTime_min, ...
    "UnoptimizedPC", {UnoptimizedPC}, ...
    "UnoptimizedReplayOutput", {UnoptimizedReplayOutput});
RunMetadata = struct( ...
    "Status", "success", ...
    "RunVersion", RunVersion, ...
    "SequenceIndex", iSequence, ...
    "Flights", nFlight, ...
    "MaxIterations", MaxIterations, ...
    "Runtime_min", toc(SequenceTimer) / 60, ...
    "Completed", string(datetime("now")));
Status = "success";

save(CheckpointFile, "Status", "RunMetadata", "Sequence", ...
    "SequenceSummary", "FlightResults", "ChargeResults", ...
    "MissionResults", "ChargeHistories", "OptimizerResults", "-v7.3");
fprintf("Sequence %d complete in %.2f min.\n", ...
    iSequence, RunMetadata.Runtime_min);
end


function [AircraftSet, ChargeHistories, PC, ReplayOutput] = ...
        FlyUnoptimizedSequence( ...
        BaseAircraft, Sequence)
nFlight = height(Sequence);
AircraftSet = struct;
ChargeHistories = cell(max(nFlight - 1, 0), 1);
PC = cell(nFlight, 1);
ReplayOutput = cell(nFlight, 1);
BegSOC = 100;
BegTemperature_C = BaseAircraft.Settings.BatteryInitialTemperature_C;
for k = 1:nFlight
    Seed = ConfigureFlight(BaseAircraft, Sequence(k, :), ...
        BegSOC, BegTemperature_C);
    % Saved aircraft produced by an earlier -2 run can carry scalar LamUps
    % fields promoted to one. Reassert the regular PHE phase limits before
    % every -1 flight so the baseline is independent of file provenance.
    Seed.Specs.Power.LamUps.SLS = 1.00;
    Seed.Specs.Power.LamUps.Tko = 1.00;
    Seed.Specs.Power.LamUps.Clb = 0.30;
    Seed.Specs.Power.LamUps.Crs = 0.00;
    Seed.Specs.Power.LamUps.Des = 0.00;
    Seed.Specs.Power.LamUps.Lnd = 0.00;
    Seed.Settings.Analysis.Type = -1;
    Seed.Settings.PowerOpt = 0;
    Seed = Main(Seed, @MissionProfilesPkg.ERJ_ClimbThenAccel);

    % MaxIterations=0 performs only the fixed-command feasibility
    % projection and -2 replay. No optimization is performed.
    Seed = ConfigureOptimizer(Seed, 0);
    Seed.Settings.PreserveOptimizationLamUps = true;
    [Aircraft, PC{k}, ~, ReplayExitFlag, ReplayOutput{k}] = ...
        OptimizationPkg.MissionPowerOpt( ...
        Seed, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    ReplayOutput{k}.ExitFlag = ReplayExitFlag;
    ReplayOutput{k}.Feasible = ReplayExitFlag > 0 && ...
        ReplayOutput{k}.constrviolation <= ...
        Seed.Settings.PowerOptConstraintTolerance;
    if ~ReplayOutput{k}.Feasible
        warning("RunAllSequences:UnoptimizedInfeasible", ...
            ["Unoptimized flight %d is infeasible with its prescribed " ...
            "LamUps cap (maximum scaled constraint %.6g)."], ...
            k, ReplayOutput{k}.constrviolation);
    end
    AircraftSet.(sprintf("Aircraft%d", k)) = Aircraft;
    if k < nFlight
        [ChargeHistories{k}, BegSOC, BegTemperature_C] = ...
            ChargeForNextFlight(Aircraft, Sequence.GROUND_TIME(k + 1));
    end
end
end


function [AircraftSet, PC, ExitFlag, OptimizerOutput, OptimizerTime_min, ...
        ChargeHistories] = FlyIndividualSequence( ...
        BaseAircraft, Sequence, MaxIterations, UnoptimizedPC)
nFlight = height(Sequence);
AircraftSet = struct;
PC = cell(nFlight, 1);
ExitFlag = zeros(nFlight, 1);
OptimizerOutput = cell(nFlight, 1);
OptimizerTime_min = zeros(nFlight, 1);
ChargeHistories = cell(max(nFlight - 1, 0), 1);
BegSOC = 100;
BegTemperature_C = BaseAircraft.Settings.BatteryInitialTemperature_C;
for k = 1:nFlight
    Seed = ConfigureFlight(BaseAircraft, Sequence(k, :), ...
        BegSOC, BegTemperature_C);
    % Construct the optimizer seed from the same prescribed regular
    % dispatch used by FlyUnoptimizedSequence. This prevents saved-aircraft
    % LamUps provenance from changing the individual optimizer's incumbent.
    Seed.Specs.Power.LamUps.SLS = 1.00;
    Seed.Specs.Power.LamUps.Tko = 1.00;
    Seed.Specs.Power.LamUps.Clb = 0.30;
    Seed.Specs.Power.LamUps.Crs = 0.00;
    Seed.Specs.Power.LamUps.Des = 0.00;
    Seed.Specs.Power.LamUps.Lnd = 0.00;
    Seed.Settings.Analysis.Type = -1;
    Seed.Settings.PowerOpt = 0;
    Seed = Main(Seed, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    Seed = ConfigureOptimizer(Seed, MaxIterations);
    % Use the exact unoptimized -2 control vector as the incumbent for this
    % flight. Later-flight SOC/temperature may differ after earlier optimized
    % flights and charging, but the control starting point is identical.
    Seed.Settings.PowerOptInitialPC = UnoptimizedPC{k};
    [Aircraft, PC{k}, OptimizerTime_min(k), ExitFlag(k), ...
        OptimizerOutput{k}] = OptimizationPkg.MissionPowerOpt( ...
        Seed, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    AircraftSet.(sprintf("Aircraft%d", k)) = Aircraft;
    if k < nFlight
        [ChargeHistories{k}, BegSOC, BegTemperature_C] = ...
            ChargeForNextFlight(Aircraft, Sequence.GROUND_TIME(k + 1));
    end
end
end


function Fuel_kg = SequenceMainMissionFuel(AircraftSet, nFlight)
Fuel_kg = 0;
for k = 1:nFlight
    Aircraft = AircraftSet.(sprintf("Aircraft%d", k));
    MainSegs = find(Aircraft.Mission.Profile.ID == 1);
    if isempty(MainSegs)
        error("RunAllSequences:MissingMainMission", ...
            "Flight %d has no main mission ID 1.", k);
    end
    MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
    Fuel_kg = Fuel_kg + Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
end
end


function Aircraft = ConfigureOptimizer(Aircraft, MaxIterations)
Aircraft.Settings.PowerOptMaxIter = MaxIterations;
Aircraft.Settings.PowerOptMaxStarts = 1;
Aircraft.Settings.PowerOptUseParallel = false;
Aircraft.Settings.PowerOptOptimalityTolerance = 5e-4;
Aircraft.Settings.PowerOptFunctionTolerance = 1e-5;
Aircraft.Settings.PowerOptConstraintTolerance = 1e-4;
end


function AircraftSet = FlyConventionalSequence( ...
        Sequence, Catalog, CacheDirectory)
nFlight = height(Sequence);
AircraftSet = struct;
for k = 1:nFlight
    CacheIndex = FindConventionalCacheIndex(Sequence(k, :), Catalog);
    Cached = load(fullfile(CacheDirectory, ...
        sprintf("ConventionalFlight_%04d.mat", CacheIndex)), "Aircraft");
    AircraftSet.(sprintf("Aircraft%d", k)) = Cached.Aircraft;
end
end


function [Catalog, CacheDirectory] = BuildConventionalCache( ...
        BaseAircraft, Sequences, CacheDirectory, RunVersion, UseParallel)
Variables = {'DISTANCE','ALTITUDE_m','SPEED_mph','PAYLOAD_lb'};
AllFlights = vertcat(Sequences{:});
Catalog = unique(AllFlights(:, Variables), "rows", "stable");
if ~isfolder(CacheDirectory), mkdir(CacheDirectory); end

fprintf("Preparing %d exact conventional FAST flight cache entries.\n", ...
    height(Catalog));
if UseParallel
    parfor k = 1:height(Catalog)
        BuildOneConventionalCacheEntry(k, Catalog, CacheDirectory, ...
            BaseAircraft, RunVersion);
    end
else
    for k = 1:height(Catalog)
        BuildOneConventionalCacheEntry(k, Catalog, CacheDirectory, ...
            BaseAircraft, RunVersion);
    end
end
end


function BuildOneConventionalCacheEntry(k, Catalog, CacheDirectory, ...
        BaseAircraft, RunVersion)
CacheFile = fullfile(CacheDirectory, ...
    sprintf("ConventionalFlight_%04d.mat", k));
if IsValidConventionalCache(CacheFile, RunVersion, Catalog(k, :))
    return;
end
Aircraft = ConfigureFlight(BaseAircraft, Catalog(k, :), NaN, NaN);
Aircraft.Settings.Analysis.Type = -1;
Aircraft.Settings.PowerOpt = 0;
Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
CacheMetadata = struct("RunVersion", RunVersion, ...
    "CacheIndex", k, "FlightInput", Catalog(k, :), ...
    "Completed", string(datetime("now")));
SaveConventionalCache(CacheFile, Aircraft, CacheMetadata);
end


function SaveConventionalCache(FileName, Aircraft, CacheMetadata)
save(FileName, "Aircraft", "CacheMetadata", "-v7.3");
end


function Index = FindConventionalCacheIndex(Flight, Catalog)
Match = Catalog.DISTANCE == Flight.DISTANCE & ...
    Catalog.ALTITUDE_m == Flight.ALTITUDE_m & ...
    Catalog.SPEED_mph == Flight.SPEED_mph & ...
    Catalog.PAYLOAD_lb == Flight.PAYLOAD_lb;
Index = find(Match, 1);
if isempty(Index)
    error("RunAllSequences:MissingConventionalCache", ...
        "No conventional cache entry matches the requested flight.");
end
end


function IsValid = IsValidConventionalCache( ...
        FileName, RunVersion, FlightInput)
IsValid = false;
if ~isfile(FileName), return; end
try
    D = load(FileName, "CacheMetadata");
    C = D.CacheMetadata;
    IsValid = C.RunVersion == RunVersion && ...
        isequaln(C.FlightInput, FlightInput);
catch
    IsValid = false;
end
end


function Aircraft = ConfigureFlight(Aircraft, Flight, BegSOC, BegTemp_C)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
    Flight.DISTANCE, "naut mi", "m");
[~, ~, Aircraft.Specs.Performance.Vels.Crs] = ...
    MissionSegsPkg.ComputeFltCon(Flight.ALTITUDE_m, 0, "TAS", ...
    convvel(Flight.SPEED_mph, "mph", "m/s"));
Aircraft.Specs.Performance.Alts.Crs = Flight.ALTITUDE_m;
Aircraft.Specs.Weight.Payload = convmass(Flight.PAYLOAD_lb, "lbm", "kg");
if isfinite(BegSOC) && any(Aircraft.Specs.Propulsion.PropArch.SrcType == 0)
    Aircraft.Specs.Power.Battery.BegSOC = BegSOC;
    Aircraft.Specs.Battery.BegSOC = BegSOC;
end
if isfinite(BegTemp_C)
    Aircraft.Settings.BatteryInitialTemperature_C = BegTemp_C;
end
Aircraft.Settings.PrintOut = 0;
Aircraft.Settings.Plotting = 0;
Aircraft.Settings.Table = 0;
if isfield(Aircraft.Specs.Power.LamUps, "Miss")
    Aircraft.Specs.Power.LamUps = rmfield(Aircraft.Specs.Power.LamUps, "Miss");
end
if isfield(Aircraft.Specs.Power.LamDwn, "Miss")
    Aircraft.Specs.Power.LamDwn = rmfield(Aircraft.Specs.Power.LamDwn, "Miss");
end
end


function [Charge, BegSOC, BegTemperature_C] = ChargeForNextFlight( ...
        Aircraft, GroundTime_min)
Aircraft.Settings.GroundChargeMissionEndIndex = GetMainEnd(Aircraft);
ChargeTime_s = max(GroundTime_min - 7, 0) * 60;
Charged = BatteryPkg.GroundCharge(Aircraft, ChargeTime_s);
Charge = Charged.Mission.History.SI.Power.ChargedAC;
BegSOC = Charge.SOCEnd;
BegTemperature_C = Charge.TemperatureEnd_C;
end


function Charges = ReplayCharges(AircraftSet, Sequence)
nFlight = height(Sequence);
Charges = cell(max(nFlight - 1, 0), 1);
for k = 1:nFlight - 1
    Aircraft = AircraftSet.(sprintf("Aircraft%d", k));
    [Charges{k}, ~, ~] = ChargeForNextFlight( ...
        Aircraft, Sequence.GROUND_TIME(k + 1));
end
end


function [FlightTable, ChargeTable] = SummarizePHE( ...
        AircraftSet, ChargeHistories, Sequence, CaseName)
nFlight = height(Sequence);
Flight = (1:nFlight)';
CaseColumn = repmat(string(CaseName), nFlight, 1);
MainFuel_kg = zeros(nFlight, 1);
BegSOC_pct = zeros(nFlight, 1);
EndSOC_pct = zeros(nFlight, 1);
BatteryTerminal_kWh = zeros(nFlight, 1);
for k = 1:nFlight
    Aircraft = AircraftSet.(sprintf("Aircraft%d", k));
    MainEnd = GetMainEnd(Aircraft);
    Batt = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);
    MainFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
    BegSOC_pct(k) = Aircraft.Mission.History.SI.Power.SOC(1, Batt);
    EndSOC_pct(k) = Aircraft.Mission.History.SI.Power.SOC(MainEnd, Batt);
    t = Aircraft.Mission.History.SI.Performance.Time(1:MainEnd);
    p = Aircraft.Mission.History.SI.Power.Pout(1:MainEnd, Batt);
    BatteryTerminal_kWh(k) = trapz(t, p) / 3.6e6;
end
FlightTable = table(CaseColumn, Flight, Sequence.DISTANCE, ...
    Sequence.GROUND_TIME, MainFuel_kg, BegSOC_pct, ...
    EndSOC_pct, BatteryTerminal_kWh, true(nFlight, 1), ...
    'VariableNames', {'CaseName','Flight','Distance_nmi', ...
    'GroundTime_min','FuelBurn_kg','BegSOC_pct', ...
    'EndSOC_pct','BatteryTerminal_kWh','Feasible'});
ChargeTable = SummarizeCharges(ChargeHistories, CaseName, Sequence);
end


function FlightTable = SummarizeConventional(AircraftSet, Sequence)
nFlight = height(Sequence);
MainFuel_kg = zeros(nFlight, 1);
for k = 1:nFlight
    Aircraft = AircraftSet.(sprintf("Aircraft%d", k));
    MainFuel_kg(k) = Aircraft.Mission.History.SI.Weight.Fburn( ...
        GetMainEnd(Aircraft));
end
FlightTable = table(repmat("Conventional", nFlight, 1), (1:nFlight)', ...
    Sequence.DISTANCE, Sequence.GROUND_TIME, MainFuel_kg, ...
    nan(nFlight,1), nan(nFlight,1), nan(nFlight,1), true(nFlight,1), ...
    'VariableNames', {'CaseName','Flight','Distance_nmi', ...
    'GroundTime_min','FuelBurn_kg','BegSOC_pct', ...
    'EndSOC_pct','BatteryTerminal_kWh','Feasible'});
end


function T = SummarizeCharges(Charges, CaseName, Sequence)
nCharge = numel(Charges);
if nCharge == 0
    T = table('Size', [0, 9], 'VariableTypes', ...
        {'string','double','double','double','double','double','double', ...
        'double','double'}, 'VariableNames', {'CaseName','AfterFlight', ...
        'AvailableTime_min','ActualTime_min','SOCBeg_pct','SOCEnd_pct', ...
        'SOCAdded_pct','GridEnergy_kWh','TemperatureEnd_C'});
    return;
end
CaseColumn = repmat(string(CaseName), nCharge, 1);
AfterFlight = (1:nCharge)';
AvailableTime_min = zeros(nCharge, 1);
ActualTime_min = zeros(nCharge, 1);
SOCBeg_pct = zeros(nCharge, 1);
SOCEnd_pct = zeros(nCharge, 1);
SOCAdded_pct = zeros(nCharge, 1);
GridEnergy_kWh = nan(nCharge, 1);
TemperatureEnd_C = nan(nCharge, 1);
for k = 1:nCharge
    C = Charges{k};
    AvailableTime_min(k) = max(Sequence.GROUND_TIME(k + 1) - 7, 0);
    if isfield(C, "Time_s") && ~isempty(C.Time_s)
        ActualTime_min(k) = C.Time_s(end) / 60;
    end
    if isfield(C, "SOCBeg"), SOCBeg_pct(k) = C.SOCBeg; ...
    elseif isfield(C, "SOC") && ~isempty(C.SOC), SOCBeg_pct(k) = C.SOC(1); end
    if isfield(C, "SOCEnd"), SOCEnd_pct(k) = C.SOCEnd; ...
    elseif isfield(C, "SOC") && ~isempty(C.SOC), SOCEnd_pct(k) = C.SOC(end); end
    SOCAdded_pct(k) = SOCEnd_pct(k) - SOCBeg_pct(k);
    if isfield(C, "GridEnergy_kWh"), GridEnergy_kWh(k) = C.GridEnergy_kWh; ...
    elseif isfield(C, "EnergyFromGrid_J"), GridEnergy_kWh(k) = C.EnergyFromGrid_J / 3.6e6; ...
    elseif isfield(C, "EnergyGrid_J"), GridEnergy_kWh(k) = C.EnergyGrid_J / 3.6e6; end
    if isfield(C, "TemperatureEnd_C")
        TemperatureEnd_C(k) = C.TemperatureEnd_C;
    end
end
T = table(CaseColumn, AfterFlight, AvailableTime_min, ActualTime_min, ...
    SOCBeg_pct, SOCEnd_pct, SOCAdded_pct, GridEnergy_kWh, TemperatureEnd_C, ...
    'VariableNames', {'CaseName','AfterFlight','AvailableTime_min', ...
    'ActualTime_min','SOCBeg_pct','SOCEnd_pct','SOCAdded_pct', ...
    'GridEnergy_kWh','TemperatureEnd_C'});
end


function Summary = BuildSequenceSummary(Index, Sequence, Joint, Individual, ...
        Unoptimized, Conventional, JointCharge, IndividualCharge, ...
        UnoptimizedCharge, JointTime, IndividualTime, JointExit, IndividualExit)
JointMain = sum(Joint.FuelBurn_kg); IndividualMain = sum(Individual.FuelBurn_kg);
UnoptimizedMain = sum(Unoptimized.FuelBurn_kg); ConventionalMain = sum(Conventional.FuelBurn_kg);
JointMeanLandingSOCExcludingLast = MeanExcludingLast(Joint.EndSOC_pct);

Summary = table(Index, height(Sequence), sum(Sequence.DISTANCE), ...
    JointMain, IndividualMain, UnoptimizedMain, ConventionalMain, ...
    UnoptimizedMain-JointMain, UnoptimizedMain-IndividualMain, ...
    ConventionalMain-JointMain, ConventionalMain-IndividualMain, ...
    sum(Joint.BatteryTerminal_kWh), sum(Individual.BatteryTerminal_kWh), ...
    sum(Unoptimized.BatteryTerminal_kWh), ...
    JointMeanLandingSOCExcludingLast, ...
    MeanOrNaN(JointCharge.ActualTime_min), ...
    MeanOrNaN(JointCharge.SOCAdded_pct), ...
    MeanOrNaN(JointCharge.SOCEnd_pct), ...
    MeanOrNaN(IndividualCharge.ActualTime_min), ...
    MeanOrNaN(IndividualCharge.SOCAdded_pct), ...
    MeanOrNaN(UnoptimizedCharge.ActualTime_min), ...
    MeanOrNaN(UnoptimizedCharge.SOCAdded_pct), ...
    all(Joint.Feasible), all(Individual.Feasible), ...
    all(Unoptimized.Feasible), JointTime, IndividualTime, ...
    JointExit, min(IndividualExit), ...
    'VariableNames', {'Sequence','Flights','Distance_nmi', ...
    'JointFuelBurn_kg','IndividualFuelBurn_kg','UnoptimizedFuelBurn_kg', ...
    'ConventionalFuelBurn_kg', ...
    'JointFuelSavedVsUnoptimized_kg_per_day', ...
    'IndividualFuelSavedVsUnoptimized_kg_per_day', ...
    'JointFuelSavedVsConventional_kg_per_day', ...
    'IndividualFuelSavedVsConventional_kg_per_day', ...
    'JointBatteryTerminal_kWh','IndividualBatteryTerminal_kWh', ...
    'UnoptimizedBatteryTerminal_kWh', ...
    'JointMeanLandingSOCExcludingLast_pct', ...
    'JointAverageChargeTime_min','JointAverageSOCAdded_pct', ...
    'JointAveragePostChargeSOC_pct','IndividualAverageChargeTime_min', ...
    'IndividualAverageSOCAdded_pct','UnoptimizedAverageChargeTime_min', ...
    'UnoptimizedAverageSOCAdded_pct','JointFeasible', ...
    'IndividualFeasible','UnoptimizedFeasible','JointOptimizerTime_min', ...
    'IndividualOptimizerTime_min','JointExitFlag', ...
    'MinimumIndividualExitFlag'});
end


function Records = CompactAircraftSet(AircraftSet, Sequence)
nFlight = height(Sequence);
Records = cell(nFlight, 1);
for k = 1:nFlight
    A = AircraftSet.(sprintf("Aircraft%d", k));
    R = struct;
    R.FlightInput = Sequence(k, :);
    R.MissionProfile = A.Mission.Profile;
    R.MissionHistory = A.Mission.History;
    R.MainMissionEndIndex = GetMainEnd(A);
    R.Weight = A.Specs.Weight;
    R.Performance = A.Specs.Performance;
    R.Power = A.Specs.Power;
    R.Battery = A.Specs.Battery;
    R.PropArch = A.Specs.Propulsion.PropArch;
    R.AnalysisType = A.Settings.Analysis.Type;
    R.LamUpsCommand = A.Mission.History.SI.Power.LamUps;
    R.LamDwn = A.Mission.History.SI.Power.LamDwn;
    R.TrueLamUps = ComputeTrueLamUps(A);
    % Compatibility alias for checkpoints made before the quantity was
    % named explicitly. Both fields are Pout divided by uncapped rating.
    R.LamUpsFullRatedUtilization = R.TrueLamUps;
    Records{k} = R;
end
end


function Utilization = ComputeTrueLamUps(Aircraft)
Pout = Aircraft.Mission.History.SI.Power.Pout;
Pav = Aircraft.Mission.History.SI.Power.Pav;
Utilization = zeros(size(Pout));
Valid = isfinite(Pout) & isfinite(Pav) & abs(Pav) > 1e-9;
Utilization(Valid) = Pout(Valid) ./ Pav(Valid);
nSrc = numel(Aircraft.Specs.Propulsion.PropArch.SrcType);
nTrn = numel(Aircraft.Specs.Propulsion.PropArch.TrnType);
Cols = nSrc + (1:nTrn);
Utilization(:, Cols) = Utilization(:, Cols) .* ...
    Aircraft.Mission.History.SI.Power.LamUps;
Utilization = min(max(Utilization, 0), 1);
end


function MainEnd = GetMainEnd(Aircraft)
MainSegs = find(Aircraft.Mission.Profile.ID == 1);
MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
end


function Value = MeanExcludingLast(Vector)
if numel(Vector) <= 1, Value = NaN; else, Value = mean(Vector(1:end-1)); end
end


function Value = MeanOrNaN(Vector)
if isempty(Vector), Value = NaN; else, Value = mean(Vector, "omitnan"); end
end


function IsComplete = IsCompleteCheckpoint(FileName, RunVersion, MaxIterations)
IsComplete = false;
if ~isfile(FileName), return; end
try
    D = load(FileName, "Status", "RunMetadata");
    IsComplete = D.Status == "success" && ...
        D.RunMetadata.RunVersion == RunVersion && ...
        D.RunMetadata.MaxIterations == MaxIterations;
catch
    IsComplete = false;
end
end


function SaveFailure(Directory, Index, RunVersion, MaxIterations, ME)
Status = "failed";
RunMetadata = struct("RunVersion", RunVersion, "SequenceIndex", Index, ...
    "MaxIterations", MaxIterations, "Failed", string(datetime("now")));
ErrorIdentifier = string(ME.identifier);
ErrorMessage = string(ME.message);
ErrorReport = string(getReport(ME, "extended", "hyperlinks", "off"));
save(fullfile(Directory, sprintf("Sequence_%04d_failed.mat", Index)), ...
    "Status", "RunMetadata", "ErrorIdentifier", "ErrorMessage", ...
    "ErrorReport");
end


function Aggregate = AggregateCheckpoints(Directory, Count, ...
        RunVersion, MaxIterations)
SummaryRows = cell(Count, 1);
FlightRows = cell(Count, 1);
ChargeRows = cell(Count, 1);
Complete = false(Count, 1);
for k = 1:Count
    FileName = fullfile(Directory, sprintf("Sequence_%04d.mat", k));
    if IsCompleteCheckpoint(FileName, RunVersion, MaxIterations)
        D = load(FileName, "SequenceSummary", "FlightResults", "ChargeResults");
        SummaryRows{k} = D.SequenceSummary;
        D.FlightResults.Sequence = repmat(k, height(D.FlightResults), 1);
        D.FlightResults = movevars(D.FlightResults, "Sequence", "Before", 1);
        FlightRows{k} = D.FlightResults;
        D.ChargeResults.Sequence = repmat(k, height(D.ChargeResults), 1);
        D.ChargeResults = movevars(D.ChargeResults, "Sequence", "Before", 1);
        ChargeRows{k} = D.ChargeResults;
        Complete(k) = true;
    end
end
if any(Complete)
    SequenceSummary = vertcat(SummaryRows{Complete});
    FlightResults = vertcat(FlightRows{Complete});
    ChargeResults = vertcat(ChargeRows{Complete});
else
    SequenceSummary = table; FlightResults = table; ChargeResults = table;
end
if isempty(SequenceSummary)
    FleetMetrics = table(Count, 0, Count, ...
        'VariableNames', {'TotalSequences','CompletedSequences','RemainingSequences'});
else
    FleetMetrics = table(Count, height(SequenceSummary), ...
        Count-height(SequenceSummary), sum(SequenceSummary.Flights), ...
        mean(SequenceSummary.JointFuelSavedVsUnoptimized_kg_per_day), ...
        mean(SequenceSummary.IndividualFuelSavedVsUnoptimized_kg_per_day), ...
        mean(SequenceSummary.JointFuelSavedVsConventional_kg_per_day), ...
        mean(SequenceSummary.IndividualFuelSavedVsConventional_kg_per_day), ...
        mean(SequenceSummary.JointMeanLandingSOCExcludingLast_pct, "omitnan"), ...
        mean(SequenceSummary.JointAverageChargeTime_min, "omitnan"), ...
        mean(SequenceSummary.JointAverageSOCAdded_pct, "omitnan"), ...
        sum(SequenceSummary.JointOptimizerTime_min), ...
        sum(SequenceSummary.IndividualOptimizerTime_min), ...
        'VariableNames', {'TotalSequences','CompletedSequences', ...
        'RemainingSequences','CompletedFlights', ...
        'AverageJointFuelSavedVsUnoptimized_kg_per_day', ...
        'AverageIndividualFuelSavedVsUnoptimized_kg_per_day', ...
        'AverageJointFuelSavedVsConventional_kg_per_day', ...
        'AverageIndividualFuelSavedVsConventional_kg_per_day', ...
        'AverageJointLandingSOCExcludingLast_pct', ...
        'AverageJointChargeTime_min','AverageJointSOCAdded_pct', ...
        'TotalJointOptimizerWorkerTime_min', ...
        'TotalIndividualOptimizerWorkerTime_min'});
end
Aggregate = struct("SequenceSummary", SequenceSummary, ...
    "FlightResults", FlightResults, "ChargeResults", ChargeResults, ...
    "FleetMetrics", FleetMetrics, ...
    "CompletedSequenceIndices", find(Complete), ...
    "MissingSequenceIndices", find(~Complete), ...
    "Generated", string(datetime("now")));
end
