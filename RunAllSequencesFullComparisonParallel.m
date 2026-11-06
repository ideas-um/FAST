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

RunVersion = "all-sequences-v6-literature-calibrated-fixed-climb-kw";
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

SequenceFile = string(getenv("FAST_SEQUENCE_FILE"));
if strlength(SequenceFile) == 0
    SequenceFile = fullfile(RootDir, "Sequence.mat");
elseif ~isfile(SequenceFile)
    Candidate = fullfile(RootDir, SequenceFile);
    if isfile(Candidate), SequenceFile = Candidate; end
end
if ~isfile(SequenceFile)
    error("FAST:SequenceFile:Missing", ...
        "Sequence input file does not exist: %s", SequenceFile);
end
SequenceData = load(char(SequenceFile), "tables");
if ~isfield(SequenceData, "tables") || ~iscell(SequenceData.tables)
    error("FAST:SequenceFile:Invalid", ...
        "Sequence input must contain a cell array named tables: %s", ...
        SequenceFile);
end
Sequences = SequenceData.tables;
nSequence = numel(Sequences);
if nargin < 3 || isempty(SequenceIndices)
    SequenceIndices = 1:nSequence;
end
SequenceIndices = unique(SequenceIndices(:)');
if any(SequenceIndices < 1 | SequenceIndices > nSequence)
    error("Sequence indices must be between 1 and %d.", nSequence);
end

PreparedBaseFile = string(getenv("FAST_BASE_AIRCRAFT_FILE"));
if strlength(PreparedBaseFile) == 0
    [BasePHE, BaseConventional, SizingMetadata] = ...
        SizeERJ175LRBaseAircraft();
    PreparedBaseFile = "sized in this MATLAB run from specification functions";
else
    PreparedData = load(char(PreparedBaseFile), "BasePHE", ...
        "BaseConventional", "SizingMetadata");
    RequiredPreparedFields = ["BasePHE", "BaseConventional", ...
        "SizingMetadata"];
    if ~all(isfield(PreparedData, RequiredPreparedFields))
        error("FAST:PreparedBaseAircraft:InvalidFile", ...
            "Prepared base-aircraft file is incomplete: %s", ...
            PreparedBaseFile);
    end
    BasePHE = PreparedData.BasePHE;
    BaseConventional = PreparedData.BaseConventional;
    SizingMetadata = PreparedData.SizingMetadata;
end
if ~logical(BasePHE.Settings.Converged) || ...
        ~logical(BaseConventional.Settings.Converged) || ...
        string(BasePHE.Specs.Propulsion.PropArch.Type) ~= "PHE" || ...
        string(BaseConventional.Specs.Propulsion.PropArch.Type) ~= "C" || ...
        BasePHE.Specs.Performance.RCMax ~= ...
            BaseConventional.Specs.Performance.RCMax || ...
        BasePHE.Specs.Propulsion.MDotCF ~= ...
            BaseConventional.Specs.Propulsion.MDotCF || ...
        BasePHE.Specs.Weight.WairfCF ~= ...
            BaseConventional.Specs.Weight.WairfCF
    error("FAST:PreparedBaseAircraft:ValidationFailed", ...
        ["Prepared aircraft must be converged C/PHE designs with matching " ...
         "climb-rate, fuel-flow, and airframe-weight requirements."]);
end
BasePHE.Specs.Battery.Charging = 150e3;
BasePHE.Settings.GroundChargeModel = "ThermalEquivalentCircuit";
BasePHE.Settings.BatterySOH_pct = 80;
BasePHE.Settings.BatteryInitialTemperature_C = 35;
BasePHE.Settings.PrintOut = 0;
BasePHE.Settings.Plotting = 0;
BasePHE.Settings.Table = 0;

BaseConventional.Settings.PrintOut = 0;
BaseConventional.Settings.Plotting = 0;
BaseConventional.Settings.Table = 0;

InputMetadata = struct( ...
    "RunVersion", RunVersion, ...
    "SequenceFile", string(SequenceFile), ...
    "BaseAircraftSource", string(PreparedBaseFile), ...
    "SizingMetadata", SizingMetadata, ...
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
    % A Slurm array element runs exactly one sequence.  Preserve the
    % diagnostic marker, then propagate the exception so MATLAB and Slurm
    % report FAILED instead of a misleading process-level COMPLETED state.
    % Multi-sequence desktop runs retain the historical collect-and-continue
    % behavior unless the caller explicitly enables this setting.
    if ReadLogicalEnvironment("FAST_RETHROW_SEQUENCE_FAILURE", false)
        rethrow(ME);
    end
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
    UnoptimizedReplayOutput, FixedClimbMotorPower_kW, ...
    FixedClimbMotorPower_pct] = LoadOrComputeFixedBaseline( ...
    BasePHE, Sequence, iSequence, RunVersion);
if ReadLogicalEnvironment("FAST_FIXED_BASELINE_ONLY", false)
    fprintf("Fixed baseline cache %d complete in %.2f min.\n", ...
        iSequence, toc(SequenceTimer) / 60);
    return;
end

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
JointMaxIterations = ReadPositiveIntegerEnvironment( ...
    "FAST_GL_JOINT_MAX_ITERATIONS", MaxIterations);
JointMaxIterations = min(JointMaxIterations, MaxIterations);
JointInput = ConfigureOptimizer(BasePHE, JointMaxIterations);
JointInput.Settings.Analysis.Type = -2;
JointBaseline = [];
if all(cellfun(@(x) ~isempty(x), UnoptimizedPC))
    JointBaseline = struct;
    JointBaseline.PC = cat(2, UnoptimizedPC{:});
    JointBaseline.Fuel_kg = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Specs.Weight.Fuel, ...
        (1:nFlight)');
    JointBaseline.MTOW_kg = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Specs.Weight.MTOW, ...
        (1:nFlight)');
    JointBaseline.LamDwn = arrayfun(@(k) ...
        UnoptimizedAircraft.(sprintf("Aircraft%d", k)).Mission.History.SI.Power.LamDwn, ...
        (1:nFlight)', "UniformOutput", false);
end
[JointAircraft, JointPC, JointOptimizerTime_min, JointOptSeqTable, ...
    JointExitFlag, JointOptimizerOutput] = ...
    OptimizationPkg.SequencePowerOpt(JointInput, Sequence, JointBaseline);
JointCharge = ReplayCharges(JointAircraft, Sequence);

% Keep the feasible fixed baseline if an individual flight optimizer returns
% a higher-fuel point. Preserve the joint optimizer's own feasible result
% without an incumbent fallback so joint local-optimum failures remain
% visible in the reported comparison and diagnostic audit.
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
    JointExitFlag, IndividualExitFlag, FixedClimbMotorPower_kW, ...
    FixedClimbMotorPower_pct);
[OptimizationTrace, OptimizationComparison] = BuildOptimizationDiagnostics( ...
    iSequence, JointOptimizerOutput, IndividualOptimizerOutput, ...
    JointOptimizerTime_min, IndividualOptimizerTime_min);
if JointExitFlag == 0 || any(IndividualExitFlag == 0)
    OptimizationCompletion = "feasible_at_iteration_limit";
else
    OptimizationCompletion = "strictly_converged";
end

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
    "UnoptimizedReplayOutput", {UnoptimizedReplayOutput}, ...
    "FixedClimbMotorPower_kW", FixedClimbMotorPower_kW, ...
    "FixedClimbMotorPower_pct", FixedClimbMotorPower_pct);
RunMetadata = struct( ...
    "Status", "success", ...
    "RunVersion", RunVersion, ...
    "SequenceIndex", iSequence, ...
    "Flights", nFlight, ...
    "MaxIterations", MaxIterations, ...
    "JointMaxIterations", JointMaxIterations, ...
    "OptimalityTolerance", ...
        JointInput.Settings.PowerOptOptimalityTolerance, ...
    "AcceptFeasibleAtIterationLimit", ...
        JointInput.Settings.PowerOptAcceptFeasibleAtIterationLimit, ...
    "BaselineCase", ...
        "Fixed constant-kW climb HEA (30% motor-rating target)", ...
    "FixedTakeoffLamUps", 1.0, ...
    "FixedClimbMotorPower_kW", FixedClimbMotorPower_kW, ...
    "FixedClimbMotorPower_pct", FixedClimbMotorPower_pct, ...
    "OptimizationCompletion", OptimizationCompletion, ...
    "Runtime_min", toc(SequenceTimer) / 60, ...
    "Completed", string(datetime("now")));
Status = "success";

save(CheckpointFile, "Status", "RunMetadata", "Sequence", ...
    "SequenceSummary", "FlightResults", "ChargeResults", ...
    "MissionResults", "ChargeHistories", "OptimizerResults", ...
    "OptimizationTrace", "OptimizationComparison", "-v7.3");
fprintf("Sequence %d complete in %.2f min.\n", ...
    iSequence, RunMetadata.Runtime_min);
end


function [AircraftSet, ChargeHistories, PC, ReplayOutput, ...
        FixedClimbMotorPower_kW, FixedClimbMotorPower_pct] = ...
        FlyUnoptimizedSequence(BaseAircraft, Sequence)
% Hold the combined electric-motor shaft output constant at every climb
% point. The initial target is 30 percent of the two motors' combined SLS
% rating. If the complete charged sequence cannot sustain that absolute
% power, find the greatest sequence-feasible constant target.
iEM = find(BaseAircraft.Specs.Propulsion.PropArch.TrnType == 0);
if isempty(iEM) || ~isfield(BaseAircraft.Specs.Propulsion, "SLSPower")
    error("RunAllSequences:MissingMotorRating", ...
        "The fixed-power baseline requires sized electric-motor ratings.");
end
RatedMotorPower_W = sum(BaseAircraft.Specs.Propulsion.SLSPower(iEM));
MaximumMotorPower_W = 0.30 * RatedMotorPower_W;

[AircraftSet, ChargeHistories, PC, ReplayOutput, IsFeasible] = ...
    ReplayFixedClimbSequence(BaseAircraft, Sequence, MaximumMotorPower_W);
if IsFeasible
    FixedMotorPower_W = MaximumMotorPower_W;
else
    [BestAircraft, BestCharge, BestPC, BestReplay, ZeroFeasible] = ...
        ReplayFixedClimbSequence(BaseAircraft, Sequence, 0);
    if ~ZeroFeasible
        Violations = cellfun(@(x) x.constrviolation, BestReplay);
        ExitFlags = cellfun(@(x) x.ExitFlag, BestReplay);
        error("RunAllSequences:FixedBaselineInfeasible", ...
            "The sequence cannot complete with full EM takeoff support even " + ...
            "when climb motor power is zero. Constraint violations by " + ...
            "flight: %s; exit flags: %s.", mat2str(Violations, 6), ...
            mat2str(ExitFlags));
    end
    Lower_W = 0;
    Upper_W = MaximumMotorPower_W;
    for iSearch = 1:10
        Candidate_W = 0.5 * (Lower_W + Upper_W);
        [CandidateAircraft, CandidateCharge, CandidatePC, CandidateReplay, ...
            CandidateFeasible] = ReplayFixedClimbSequence( ...
            BaseAircraft, Sequence, Candidate_W);
        if CandidateFeasible
            Lower_W = Candidate_W;
            BestAircraft = CandidateAircraft;
            BestCharge = CandidateCharge;
            BestPC = CandidatePC;
            BestReplay = CandidateReplay;
        else
            Upper_W = Candidate_W;
        end
    end
    % Report and replay to 0.1 kW, rounded down so numerical rounding cannot
    % cross the feasible boundary.
    FixedMotorPower_W = floor(Lower_W / 100) * 100;
    [AircraftSet, ChargeHistories, PC, ReplayOutput, IsFeasible] = ...
        ReplayFixedClimbSequence(BaseAircraft, Sequence, FixedMotorPower_W);
    if ~IsFeasible
        AircraftSet = BestAircraft;
        ChargeHistories = BestCharge;
        PC = BestPC;
        ReplayOutput = BestReplay;
        FixedMotorPower_W = Lower_W;
    end
end
FixedClimbMotorPower_kW = FixedMotorPower_W / 1000;
FixedClimbMotorPower_pct = 100 * FixedMotorPower_W / RatedMotorPower_W;
end


function [AircraftSet, ChargeHistories, PC, ReplayOutput, ...
        FixedClimbMotorPower_kW, FixedClimbMotorPower_pct] = ...
        LoadOrComputeFixedBaseline(BaseAircraft, Sequence, ...
        SequenceIndex, RunVersion)
CacheDirectory = string(getenv("FAST_FIXED_BASELINE_CACHE_DIR"));
BaselineOnly = ReadLogicalEnvironment("FAST_FIXED_BASELINE_ONLY", false);
if BaselineOnly && strlength(CacheDirectory) == 0
    error("FAST:MissingFixedBaselineCacheDirectory", ...
        "FAST_FIXED_BASELINE_CACHE_DIR is required in baseline-only mode.");
end

CacheFile = "";
if strlength(CacheDirectory) > 0
    if ~isfolder(CacheDirectory), mkdir(CacheDirectory); end
    CacheFile = fullfile(CacheDirectory, sprintf( ...
        "Sequence_%04d_fixed_baseline.mat", SequenceIndex));
end
Fingerprint = FixedBaselineAircraftFingerprint(BaseAircraft);
if strlength(CacheFile) > 0 && IsValidFixedBaselineCache( ...
        CacheFile, RunVersion, SequenceIndex, Sequence, Fingerprint)
    D = load(CacheFile, "UnoptimizedMissionResults", ...
        "UnoptimizedCharge", "UnoptimizedPC", ...
        "UnoptimizedReplayOutput", "FixedClimbMotorPower_kW", ...
        "FixedClimbMotorPower_pct");
    AircraftSet = RestoreCompactAircraftSet(D.UnoptimizedMissionResults);
    ChargeHistories = D.UnoptimizedCharge;
    PC = D.UnoptimizedPC;
    ReplayOutput = D.UnoptimizedReplayOutput;
    FixedClimbMotorPower_kW = D.FixedClimbMotorPower_kW;
    FixedClimbMotorPower_pct = D.FixedClimbMotorPower_pct;
    fprintf("Loaded fixed baseline cache for sequence %d: %s\n", ...
        SequenceIndex, CacheFile);
    return;
end

[AircraftSet, ChargeHistories, PC, ReplayOutput, ...
    FixedClimbMotorPower_kW, FixedClimbMotorPower_pct] = ...
    FlyUnoptimizedSequence(BaseAircraft, Sequence);
if strlength(CacheFile) > 0
    UnoptimizedMissionResults = CompactAircraftSet(AircraftSet, Sequence);
    UnoptimizedCharge = ChargeHistories;
    UnoptimizedPC = PC;
    UnoptimizedReplayOutput = ReplayOutput;
    FixedBaselineMetadata = struct( ...
        "Status", "success", ...
        "RunVersion", RunVersion, ...
        "SequenceIndex", SequenceIndex, ...
        "Flights", height(Sequence), ...
        "AircraftFingerprint", Fingerprint, ...
        "Completed", string(datetime("now")));
    save(CacheFile, "FixedBaselineMetadata", "Sequence", ...
        "UnoptimizedMissionResults", "UnoptimizedCharge", ...
        "UnoptimizedPC", "UnoptimizedReplayOutput", ...
        "FixedClimbMotorPower_kW", "FixedClimbMotorPower_pct", "-v7.3");
end
end


function IsValid = IsValidFixedBaselineCache(FileName, RunVersion, ...
        SequenceIndex, Sequence, Fingerprint)
IsValid = false;
if ~isfile(FileName), return; end
try
    D = load(FileName, "FixedBaselineMetadata", "Sequence");
    M = D.FixedBaselineMetadata;
    IsValid = string(M.Status) == "success" && ...
        string(M.RunVersion) == string(RunVersion) && ...
        M.SequenceIndex == SequenceIndex && ...
        isequaln(D.Sequence, Sequence) && ...
        isequaln(M.AircraftFingerprint, Fingerprint);
catch
    IsValid = false;
end
end


function Fingerprint = FixedBaselineAircraftFingerprint(Aircraft)
Fingerprint = struct( ...
    "MTOW_kg", Aircraft.Specs.Weight.MTOW, ...
    "Fuel_kg", Aircraft.Specs.Weight.Fuel, ...
    "MotorSLSPower_W", Aircraft.Specs.Propulsion.SLSPower( ...
        Aircraft.Specs.Propulsion.PropArch.TrnType == 0), ...
    "BatterySpecificEnergy_Jpkg", Aircraft.Specs.Power.SpecEnergy.Batt, ...
    "ClimbLiftToDragCF", Aircraft.Specs.Aero.L_D.ClbCF, ...
    "CruiseLiftToDragCF", Aircraft.Specs.Aero.L_D.CrsCF, ...
    "FuelFlowCF", Aircraft.Specs.Propulsion.MDotCF, ...
    "AirframeWeightCF", Aircraft.Specs.Weight.WairfCF, ...
    "ChargerPower_W", Aircraft.Specs.Battery.Charging, ...
    "BatterySOH_pct", Aircraft.Settings.BatterySOH_pct, ...
    "BatteryInitialTemperature_C", ...
        Aircraft.Settings.BatteryInitialTemperature_C);
end


function AircraftSet = RestoreCompactAircraftSet(Records)
AircraftSet = struct;
for k = 1:numel(Records)
    R = Records{k};
    A = struct;
    A.Mission = struct("Profile", R.MissionProfile, ...
        "History", R.MissionHistory);
    A.Specs = struct;
    A.Specs.Weight = R.Weight;
    A.Specs.Performance = R.Performance;
    A.Specs.Power = R.Power;
    A.Specs.Battery = R.Battery;
    A.Specs.Propulsion = struct("PropArch", R.PropArch);
    A.Settings = struct("Analysis", struct("Type", R.AnalysisType));
    AircraftSet.(sprintf("Aircraft%d", k)) = A;
end
end


function [AircraftSet, ChargeHistories, PC, ReplayOutput, IsFeasible] = ...
        ReplayFixedClimbSequence(BaseAircraft, Sequence, TargetMotorPower_W)
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
    % Keep full takeoff availability and the original 30-percent climb
    % availability ceiling. Within that ceiling, LamDwn is varied point by
    % point to hold one absolute combined motor-power target.
    Seed.Specs.Power.LamUps.SLS = 1.00;
    Seed.Specs.Power.LamUps.Tko = 1.00;
    Seed.Specs.Power.LamUps.Clb = 0.30;
    Seed.Specs.Power.LamUps.Crs = 0.00;
    Seed.Specs.Power.LamUps.Des = 0.00;
    Seed.Specs.Power.LamUps.Lnd = 0.00;
    Seed.Settings.Analysis.Type = -1;
    Seed.Settings.PowerOpt = 0;
    Seed = Main(Seed, @MissionProfilesPkg.ERJ_ClimbThenAccel);

    Seed = ConfigureOptimizer(Seed, 0);
    [Aircraft, PC{k}, ReplayExitFlag, ReplayOutput{k}] = ...
        ReplayConstantClimbMotorPower(Seed, TargetMotorPower_W);
    ReplayOutput{k}.ExitFlag = ReplayExitFlag;
    ReplayOutput{k}.Feasible = ...
        isfinite(ReplayOutput{k}.constrviolation) && ...
        ReplayOutput{k}.constrviolation <= ...
        Seed.Settings.PowerOptConstraintTolerance && ...
        ConstantClimbMotorPowerWasDelivered(Aircraft, TargetMotorPower_W);
    ReplayOutput{k}.FixedClimbMotorPowerTarget_kW = ...
        TargetMotorPower_W / 1000;
    AchievedClimbPower_W = CombinedClimbMotorPower(Aircraft);
    ReplayOutput{k}.FixedClimbMotorPowerMinimum_kW = ...
        min(AchievedClimbPower_W, [], "omitnan") / 1000;
    ReplayOutput{k}.FixedClimbMotorPowerMaximum_kW = ...
        max(AchievedClimbPower_W, [], "omitnan") / 1000;
    if ~ReplayOutput{k}.Feasible
        warning("RunAllSequences:UnoptimizedInfeasible", ...
            "Fixed-power flight %d cannot deliver %.3f kW throughout " + ...
            "climb; achieved range %.3f--%.3f kW " + ...
            "(maximum scaled constraint %.6g).", ...
            k, TargetMotorPower_W / 1000, ...
            ReplayOutput{k}.FixedClimbMotorPowerMinimum_kW, ...
            ReplayOutput{k}.FixedClimbMotorPowerMaximum_kW, ...
            ReplayOutput{k}.constrviolation);
    end
    AircraftSet.(sprintf("Aircraft%d", k)) = Aircraft;
    if k < nFlight
        [ChargeHistories{k}, BegSOC, BegTemperature_C] = ...
            ChargeForNextFlight(Aircraft, Sequence.GROUND_TIME(k + 1));
    end
end
IsFeasible = all(cellfun(@(x) isfield(x, "Feasible") && ...
    logical(x.Feasible), ReplayOutput));
if IsFeasible
    IsFeasible = FixedPowerCommandsWereSet( ...
        AircraftSet, nFlight, TargetMotorPower_W);
end
end


function [Aircraft, PC, ExitFlag, Output] = ...
        ReplayConstantClimbMotorPower(Seed, TargetMotorPower_W)
Profile = Seed.Mission.Profile;
ControlPts = TakeoffThroughClimbPoints(Profile);
ClimbPts = PhasePoints(Profile, "Climb");
[IsClimbControl, ClimbLocations] = ismember(ClimbPts(:), ControlPts);
if ~all(IsClimbControl)
    error("RunAllSequences:ClimbControlMapping", ...
        "Every climb point must be in the fixed-power control horizon.");
end

H = Seed.Mission.History.SI;
nSrc = numel(Seed.Specs.Propulsion.PropArch.SrcType);
iEM = find(Seed.Specs.Propulsion.PropArch.TrnType == 0);
PC = mean(H.Power.LamDwn(ControlPts, iEM), 2);
ReferencePower_W = sum(max(H.Power.Pout(ClimbPts, nSrc + iEM), 0), 2);
if TargetMotorPower_W <= 0
    PC(ClimbLocations) = 0;
else
    Scale = TargetMotorPower_W ./ max(ReferencePower_W, 1);
    PC(ClimbLocations) = PC(ClimbLocations) .* Scale;
end
PC = min(max(PC, 0), 1);

for iCorrect = 1:4
    Trial = ConfigureOptimizer(Seed, 0);
    Trial.Settings.PreserveOptimizationLamUps = true;
    Trial.Settings.PowerOptInitialPC = PC;
    Trial.Settings.PowerOptUseExactInitialPC = true;
    [Aircraft, PC, ~, ExitFlag, Output] = ...
        OptimizationPkg.MissionPowerOpt( ...
        Trial, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    if ConstantClimbMotorPowerWasDelivered(Aircraft, TargetMotorPower_W)
        return;
    end
    Achieved_W = CombinedClimbMotorPower(Aircraft);
    if TargetMotorPower_W <= 0
        PC(ClimbLocations) = 0;
    else
        PC(ClimbLocations) = PC(ClimbLocations) .* ...
            (TargetMotorPower_W ./ max(Achieved_W, 1));
    end
    PC = min(max(PC, 0), 1);
end
end


function IsValid = FixedPowerCommandsWereSet(AircraftSet, nFlight, ...
        TargetMotorPower_W)
CommandTolerance = 5e-3;
IsValid = true;
for k = 1:nFlight
    Aircraft = AircraftSet.(sprintf("Aircraft%d", k));
    Profile = Aircraft.Mission.Profile;
    iEM = find(Aircraft.Specs.Propulsion.PropArch.TrnType == 0);
    if isempty(iEM), IsValid = false; return; end
    Command = Aircraft.Mission.History.SI.Power.LamUps;
    TakeoffPts = PhasePoints(Profile, ["Takeoff","DetailedTakeoff"]);
    ClimbPts = PhasePoints(Profile, "Climb");
    if ~isempty(TakeoffPts)
        TakeoffValue = mean(Command(TakeoffPts, iEM), 2);
        IsValid = IsValid && all(abs(TakeoffValue - 1) <= CommandTolerance);
    end
    IsValid = IsValid && ~isempty(ClimbPts) && ...
        ConstantClimbMotorPowerWasDelivered(Aircraft, TargetMotorPower_W);
    if ~IsValid, return; end
end
end


function IsValid = ConstantClimbMotorPowerWasDelivered( ...
        Aircraft, TargetMotorPower_W)
Power_W = CombinedClimbMotorPower(Aircraft);
% FAST's coupled fuel/trajectory fixed point leaves small sub-percent power
% differences after the control correction. Treat a 1-percent (minimum
% 1 kW) band as constant while retaining the achieved min/max in diagnostics.
Tolerance_W = max(1000, 0.01 * max(TargetMotorPower_W, 1));
IsValid = ~isempty(Power_W) && all(isfinite(Power_W)) && ...
    all(abs(Power_W - TargetMotorPower_W) <= Tolerance_W);
end


function Power_W = CombinedClimbMotorPower(Aircraft)
ClimbPts = PhasePoints(Aircraft.Mission.Profile, "Climb");
nSrc = numel(Aircraft.Specs.Propulsion.PropArch.SrcType);
iEM = find(Aircraft.Specs.Propulsion.PropArch.TrnType == 0);
if isempty(ClimbPts) || isempty(iEM)
    Power_W = [];
    return;
end
Pout = Aircraft.Mission.History.SI.Power.Pout;
Power_W = sum(max(Pout(ClimbPts, nSrc + iEM), 0), 2);
end


function Points = TakeoffThroughClimbPoints(Profile)
TakeoffSegments = find(Profile.ID == 1 & ...
    ismember(string(Profile.Segs), ["Takeoff","DetailedTakeoff"]));
ClimbSegments = find(Profile.ID == 1 & string(Profile.Segs) == "Climb");
if isempty(TakeoffSegments) || isempty(ClimbSegments)
    error("RunAllSequences:MissingTakeoffOrClimb", ...
        "The fixed-power baseline requires takeoff and climb segments.");
end
Points = (Profile.SegBeg(TakeoffSegments(1)): ...
    Profile.SegEnd(ClimbSegments(end)) - 1)';
end


function Points = PhasePoints(Profile, Names)
Names = string(Names);
Segments = find(Profile.ID == 1 & ismember(string(Profile.Segs), Names));
Points = [];
for iSeg = Segments(:)'
    % Adjacent FAST segments share their boundary point. Exclude that final
    % point so the next segment's command is not attributed to this phase.
    Last = max(Profile.SegBeg(iSeg), Profile.SegEnd(iSeg) - 1);
    Points = [Points, Profile.SegBeg(iSeg):Last]; %#ok<AGROW>
end
Points = unique(Points);
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
Aircraft.Settings.PowerOptOptimalityTolerance = ...
    ReadPositiveScalarEnvironment("FAST_GL_OPTIMALITY_TOLERANCE", 5e-4);
Aircraft.Settings.PowerOptFunctionTolerance = 1e-5;
Aircraft.Settings.PowerOptConstraintTolerance = 1e-4;
Aircraft.Settings.PowerOptAcceptFeasibleAtIterationLimit = ...
    ReadLogicalEnvironment("FAST_GL_ACCEPT_FEASIBLE_AT_LIMIT", false);
end


function Value = ReadPositiveIntegerEnvironment(Name, DefaultValue)
Text = string(getenv(Name));
if strlength(Text) == 0
    Value = DefaultValue;
    return;
end
Value = str2double(Text);
if ~isscalar(Value) || ~isfinite(Value) || Value < 1 || Value ~= fix(Value)
    error("FAST:BadEnvironmentInteger", ...
        "%s must be a positive integer.", Name);
end
end


function Value = ReadPositiveScalarEnvironment(Name, DefaultValue)
Text = string(getenv(Name));
if strlength(Text) == 0
    Value = DefaultValue;
    return;
end
Value = str2double(Text);
if ~isscalar(Value) || ~isfinite(Value) || Value <= 0
    error("FAST:BadEnvironmentScalar", ...
        "%s must be a positive finite scalar.", Name);
end
end


function Value = ReadLogicalEnvironment(Name, DefaultValue)
Text = lower(strtrim(string(getenv(Name))));
if strlength(Text) == 0
    Value = DefaultValue;
elseif any(Text == ["1", "true", "yes", "on"])
    Value = true;
elseif any(Text == ["0", "false", "no", "off"])
    Value = false;
else
    error("FAST:BadEnvironmentLogical", ...
        "%s must be 1/0, true/false, yes/no, or on/off.", Name);
end
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
Aircraft = ReusableAircraftForCache(Aircraft);
save(FileName, "Aircraft", "CacheMetadata", "-v7.3");
end


function Compact = ReusableAircraftForCache(Aircraft)
% Retain everything needed for exact result reuse and post-processing while
% omitting repeated sizing/engine databases from every cached flight.
Compact = struct;
Compact.Specs = struct;
Compact.Specs.Weight = Aircraft.Specs.Weight;
Compact.Specs.Performance = Aircraft.Specs.Performance;
Compact.Specs.Power = Aircraft.Specs.Power;
Compact.Specs.Battery = Aircraft.Specs.Battery;
Compact.Specs.Propulsion = struct( ...
    "PropArch", Aircraft.Specs.Propulsion.PropArch);
Compact.Settings = struct("Analysis", Aircraft.Settings.Analysis);
Compact.Mission = struct( ...
    "Profile", Aircraft.Mission.Profile, ...
    "History", Aircraft.Mission.History);
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
    if isfield(C, "SOCBeg")
        SOCBeg_pct(k) = C.SOCBeg;
    elseif isfield(C, "SOC") && ~isempty(C.SOC)
        SOCBeg_pct(k) = C.SOC(1);
    end
    if isfield(C, "SOCEnd")
        SOCEnd_pct(k) = C.SOCEnd;
    elseif isfield(C, "SOC") && ~isempty(C.SOC)
        SOCEnd_pct(k) = C.SOC(end);
    end
    SOCAdded_pct(k) = SOCEnd_pct(k) - SOCBeg_pct(k);
    if isfield(C, "GridEnergy_kWh")
        GridEnergy_kWh(k) = C.GridEnergy_kWh;
    elseif isfield(C, "EnergyFromGrid_J")
        GridEnergy_kWh(k) = C.EnergyFromGrid_J / 3.6e6;
    elseif isfield(C, "EnergyGrid_J")
        GridEnergy_kWh(k) = C.EnergyGrid_J / 3.6e6;
    end
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
        UnoptimizedCharge, JointTime, IndividualTime, JointExit, ...
        IndividualExit, FixedClimbMotorPower_kW, FixedClimbMotorPower_pct)
JointMain = sum(Joint.FuelBurn_kg); IndividualMain = sum(Individual.FuelBurn_kg);
UnoptimizedMain = sum(Unoptimized.FuelBurn_kg); ConventionalMain = sum(Conventional.FuelBurn_kg);
JointMeanLandingSOCExcludingLast = MeanExcludingLast(Joint.EndSOC_pct);
BaselineSavings_kg = ConventionalMain - UnoptimizedMain;
[JointRelativeImprovement_pct, JointRelativeError_pct] = ...
    RelativeSavingsMetrics(UnoptimizedMain - JointMain, BaselineSavings_kg);
[IndividualRelativeImprovement_pct, IndividualRelativeError_pct] = ...
    RelativeSavingsMetrics(UnoptimizedMain - IndividualMain, BaselineSavings_kg);

Summary = table(Index, height(Sequence), sum(Sequence.DISTANCE), ...
    JointMain, IndividualMain, UnoptimizedMain, ConventionalMain, ...
    UnoptimizedMain-JointMain, UnoptimizedMain-IndividualMain, ...
    ConventionalMain-JointMain, ConventionalMain-IndividualMain, ...
    BaselineSavings_kg, JointRelativeImprovement_pct, ...
    JointRelativeError_pct, IndividualRelativeImprovement_pct, ...
    IndividualRelativeError_pct, ...
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
    all(Unoptimized.Feasible), FixedClimbMotorPower_kW, ...
    FixedClimbMotorPower_pct, JointTime, IndividualTime, ...
    JointExit, min(IndividualExit), ...
    'VariableNames', {'Sequence','Flights','Distance_nmi', ...
    'JointFuelBurn_kg','IndividualFuelBurn_kg','UnoptimizedFuelBurn_kg', ...
    'ConventionalFuelBurn_kg', ...
    'JointFuelSavedVsUnoptimized_kg_per_day', ...
    'IndividualFuelSavedVsUnoptimized_kg_per_day', ...
    'JointFuelSavedVsConventional_kg_per_day', ...
    'IndividualFuelSavedVsConventional_kg_per_day', ...
    'UnoptimizedFuelSavedVsConventional_kg_per_day', ...
    'JointAdditionalSavingsRelativeToUnoptimizedBaseline_pct', ...
    'JointRelativeFuelError_pct', ...
    'IndividualAdditionalSavingsRelativeToUnoptimizedBaseline_pct', ...
    'IndividualRelativeFuelError_pct', ...
    'JointBatteryTerminal_kWh','IndividualBatteryTerminal_kWh', ...
    'UnoptimizedBatteryTerminal_kWh', ...
    'JointMeanLandingSOCExcludingLast_pct', ...
    'JointAverageChargeTime_min','JointAverageSOCAdded_pct', ...
    'JointAveragePostChargeSOC_pct','IndividualAverageChargeTime_min', ...
    'IndividualAverageSOCAdded_pct','UnoptimizedAverageChargeTime_min', ...
    'UnoptimizedAverageSOCAdded_pct','JointFeasible', ...
    'IndividualFeasible','UnoptimizedFeasible', ...
    'FixedClimbMotorPower_kW','FixedClimbMotorPower_pct', ...
    'JointOptimizerTime_min', ...
    'IndividualOptimizerTime_min','JointExitFlag', ...
    'MinimumIndividualExitFlag'});
end


function [Improvement_pct, Error_pct] = RelativeSavingsMetrics( ...
        AdditionalSavings_kg, BaselineSavings_kg)
Tolerance = 1e-9 * max(1, abs(BaselineSavings_kg));
if ~isfinite(BaselineSavings_kg) || abs(BaselineSavings_kg) <= Tolerance
    Improvement_pct = NaN;
    Error_pct = NaN;
    return
end
% Positive improvement means optimization saved additional fuel. The error
% convention is its negative, so -5% means 5% more saving than the
% unoptimized HEA achieved relative to conventional.
Improvement_pct = 100 * AdditionalSavings_kg / abs(BaselineSavings_kg);
Error_pct = -Improvement_pct;
end


function [Trace, Comparison] = BuildOptimizationDiagnostics( ...
        SequenceIndex, JointOutput, IndividualOutputs, JointTime_min, ...
        IndividualTime_min)
TraceRows = cell(numel(IndividualOutputs) + 1, 1);
TraceRows{1} = LabelTrace(GetTrace(JointOutput), SequenceIndex, ...
    "Joint", 0);
for k = 1:numel(IndividualOutputs)
    TraceRows{k + 1} = LabelTrace(GetTrace(IndividualOutputs{k}), ...
        SequenceIndex, "Individual", k);
end
HasRows = ~cellfun(@isempty, TraceRows);
if any(HasRows)
    Trace = vertcat(TraceRows{HasRows});
else
    Trace = table;
end

JointTrace = GetTrace(JointOutput);
JointIterations = LastFinite(JointTrace, "Iteration");
JointFunctionEvaluations = LastFinite(JointTrace, "FunctionCount");
IndividualIterations = 0;
IndividualFunctionEvaluations = 0;
for k = 1:numel(IndividualOutputs)
    FlightTrace = GetTrace(IndividualOutputs{k});
    IndividualIterations = IndividualIterations + ...
        ZeroIfNaN(LastFinite(FlightTrace, "Iteration"));
    IndividualFunctionEvaluations = IndividualFunctionEvaluations + ...
        ZeroIfNaN(LastFinite(FlightTrace, "FunctionCount"));
end
IndividualTotalTime_min = sum(IndividualTime_min);
if IndividualTotalTime_min > 0
    JointToIndividualTimeRatio = JointTime_min / IndividualTotalTime_min;
else
    JointToIndividualTimeRatio = NaN;
end
Comparison = table(SequenceIndex, numel(IndividualOutputs), ...
    JointTime_min, IndividualTotalTime_min, mean(IndividualTime_min), ...
    JointToIndividualTimeRatio, JointIterations, IndividualIterations, ...
    JointFunctionEvaluations, IndividualFunctionEvaluations, ...
    'VariableNames', {'Sequence','Flights','JointTime_min', ...
    'IndividualTotalTime_min','IndividualMeanFlightTime_min', ...
    'JointToIndividualTimeRatio','JointIterations', ...
    'IndividualTotalIterations','JointFunctionEvaluations', ...
    'IndividualTotalFunctionEvaluations'});
end


function Trace = GetTrace(Output)
if isstruct(Output) && isfield(Output, "IterationHistory") && ...
        istable(Output.IterationHistory)
    Trace = Output.IterationHistory;
else
    Trace = table;
end
end


function Trace = LabelTrace(Trace, SequenceIndex, Method, Flight)
if isempty(Trace), return; end
Trace.Sequence = repmat(SequenceIndex, height(Trace), 1);
Trace.Method = repmat(string(Method), height(Trace), 1);
Trace.Flight = repmat(Flight, height(Trace), 1);
if ~ismember("StartAttempt", string(Trace.Properties.VariableNames))
    Trace.StartAttempt = ones(height(Trace), 1);
end
Trace = movevars(Trace, ...
    ["Sequence","Method","Flight","StartAttempt"], "Before", 1);
end


function Value = LastFinite(Trace, Variable)
Value = NaN;
if isempty(Trace) || ~ismember(Variable, string(Trace.Properties.VariableNames))
    return
end
Values = Trace.(Variable);
Index = find(isfinite(Values), 1, "last");
if ~isempty(Index), Value = Values(Index); end
end


function Value = ZeroIfNaN(Value)
if ~isfinite(Value), Value = 0; end
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
