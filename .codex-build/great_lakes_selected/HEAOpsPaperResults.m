function Results = HEAOpsPaperResults(ResultsRoot, varargin)
%HEAOPSPAPERRESULTS Produce all HEA operations paper tables and figures.
%
% Results = HEAOpsPaperResults()
% Results = HEAOpsPaperResults(ResultsRoot)
% Results = HEAOpsPaperResults(..., "ExpectedSequences", 500)
% Results = HEAOpsPaperResults(..., "RepresentativeSequence", 177)
%
% The processor reads completed production checkpoints only; it never runs
% an optimization. It is safe to call while HPC tasks are still finishing.
% A rerun replaces the derived paper outputs with results from every valid
% checkpoint that is present at that moment.
%
% ResultsRoot may be either the Great Lakes run root (containing tasks), a
% local production run directory (containing checkpoints), or a checkpoint
% directory itself. If omitted, FAST_GL_RESULTS_DIR is used when set;
% otherwise output/all_sequences_full_comparison_fixed_evaluator is used.

if nargin < 1 || isempty(ResultsRoot)
    ResultsRoot = string(getenv("FAST_GL_RESULTS_DIR"));
    if strlength(ResultsRoot) == 0
        ResultsRoot = fullfile(fileparts(mfilename("fullpath")), ...
            "output", "all_sequences_full_comparison_fixed_evaluator");
    end
end

P = inputParser;
P.addParameter("ExpectedSequences", 500, ...
    @(x) isnumeric(x) && isscalar(x) && x >= 1);
P.addParameter("ExpectedIndices", [], ...
    @(x) isempty(x) || (isnumeric(x) && isvector(x) && ...
    all(isfinite(x)) && all(x >= 1) && all(x == fix(x))));
P.addParameter("MaxIterations", 500, ...
    @(x) isnumeric(x) && isscalar(x) && x >= 1);
P.addParameter("RunVersion", ...
    "all-sequences-v4-source-sized-base-aircraft", ...
    @(x) ischar(x) || isstring(x));
P.addParameter("OutputDirectory", "", ...
    @(x) ischar(x) || isstring(x));
P.addParameter("RepresentativeSequence", [], ...
    @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
P.addParameter("FigureVisible", false, ...
    @(x) islogical(x) || isnumeric(x));
P.parse(varargin{:});
Opt = P.Results;

ResultsRoot = char(string(ResultsRoot));
if ~isfolder(ResultsRoot)
    error("HEAOpsPaperResults:MissingResultsRoot", ...
        "Results root does not exist: %s", ResultsRoot);
end
if strlength(string(Opt.OutputDirectory)) == 0
    OutputDirectory = fullfile(ResultsRoot, "PaperResults");
else
    OutputDirectory = char(string(Opt.OutputDirectory));
end
if ~isfolder(OutputDirectory), mkdir(OutputDirectory); end

if isempty(Opt.ExpectedIndices)
    Expected = (1:Opt.ExpectedSequences)';
else
    Expected = unique(Opt.ExpectedIndices(:), "stable");
end
[Files, Discovery] = DiscoverCheckpoints(ResultsRoot, Expected, ...
    string(Opt.RunVersion), Opt.MaxIterations);
if isempty(Files)
    error("HEAOpsPaperResults:NoCompletedCheckpoints", ...
        "No valid completed checkpoints were found below %s. " + ...
        "Partial HPC output is supported, but at least one sequence " + ...
        "must have Status='success'.", ResultsRoot);
end

fprintf("HEA paper processing: reading %d completed checkpoint(s).\n", ...
    height(Files));
[SequenceSummary, FlightResults, ChargeResults, OptimizerDiagnostics] = ...
    LoadCheckpointTables(Files);
Completed = sort(unique(SequenceSummary.Sequence));
Missing = setdiff(Expected, Completed);

OperationalMetrics = BuildOperationalMetrics(SequenceSummary, FlightResults);
[FuelSummary, FuelPerSequence] = BuildFuelTables(SequenceSummary);
SOCComparison = BuildSOCComparison(SequenceSummary, FlightResults, ...
    ChargeResults);
AdditionalMetrics = BuildAdditionalMetrics(SequenceSummary, ...
    FlightResults, ChargeResults);
[FinalSOCParity, FinalSOCParitySummary] = BuildFinalSOCParity( ...
    SequenceSummary, FlightResults);
OptimizerSummary = BuildOptimizerSummary(OptimizerDiagnostics);
[SensitivityData, SensitivitySummary] = BuildFuelSavingsSensitivity( ...
    SequenceSummary, FlightResults, ChargeResults);

Status = table(numel(Expected), numel(Completed), numel(Missing), ...
    sum(SequenceSummary.Flights), string(datetime("now")), ...
    string(ResultsRoot), string(Opt.RunVersion), Opt.MaxIterations, ...
    'VariableNames', {'ExpectedSequences','CompletedSequences', ...
    'MissingSequences','CompletedFlights','Generated','ResultsRoot', ...
    'RunVersion','MaxIterations'});

WriteTable(Status, OutputDirectory, "Run_Status.csv");
WriteTable(BuildSequenceStatus(Expected, Files), OutputDirectory, ...
    "Sequence_Status.csv");
WriteTable(OperationalMetrics, OutputDirectory, "Operations_Summary.csv");
WriteTable(FuelSummary, OutputDirectory, "Fuel_Burn_Summary.csv");
WriteTable(FuelPerSequence, OutputDirectory, ...
    "Fuel_Burn_By_Sequence.csv");
WriteTable(SOCComparison, OutputDirectory, "SOC_and_Charging_Summary.csv");
WriteTable(FinalSOCParity, OutputDirectory, ...
    "Final_SOC_Parity_By_Sequence.csv");
WriteTable(FinalSOCParitySummary, OutputDirectory, ...
    "Final_SOC_Parity_Summary.csv");
WriteTable(OptimizerDiagnostics, OutputDirectory, ...
    "Optimizer_Diagnostics_By_Sequence.csv");
WriteTable(OptimizerSummary, OutputDirectory, ...
    "Optimizer_Diagnostics_Summary.csv");
WriteTable(SensitivityData, OutputDirectory, ...
    "Fuel_Savings_Sensitivity_Data.csv");
WriteTable(SensitivitySummary, OutputDirectory, ...
    "Fuel_Savings_Sensitivity_Summary.csv");
WriteTable(AdditionalMetrics, OutputDirectory, ...
    "Additional_Paper_Metrics.csv");
WriteTable(Discovery, OutputDirectory, "Checkpoint_Discovery.csv");

MakeFuelDistributionPlot(FuelPerSequence, OutputDirectory, ...
    logical(Opt.FigureVisible));
MakeSensitivityPlot(SensitivityData, OutputDirectory, ...
    logical(Opt.FigureVisible));

[Representative, Ranking] = SelectRepresentativeSequence( ...
    SequenceSummary, FlightResults, Files, Opt.RepresentativeSequence);
WriteTable(Ranking, OutputDirectory, ...
    "Representative_Sequence_Ranking.csv");

RepresentativeFile = Files.File(Files.Sequence == Representative);
RepresentativeFile = RepresentativeFile(1);
D = load(char(RepresentativeFile), "Sequence", "MissionResults", ...
    "ChargeHistories", "FlightResults", "ChargeResults", ...
    "SequenceSummary");
MakeRepresentativeEightPanel(D, Representative, OutputDirectory, ...
    logical(Opt.FigureVisible));
WriteTable(D.Sequence, OutputDirectory, sprintf( ...
    "Representative_Sequence_%04d_Flight_Schedule.csv", Representative));
WriteTable(D.FlightResults, OutputDirectory, sprintf( ...
    "Representative_Sequence_%04d_FlightResults.csv", Representative));
WriteTable(D.ChargeResults, OutputDirectory, sprintf( ...
    "Representative_Sequence_%04d_ChargeResults.csv", Representative));

WriteTable(BuildDefinitionsTable(Representative), OutputDirectory, ...
    "Results_Definitions.csv");

Results = struct( ...
    "Status", Status, ...
    "OperationalMetrics", OperationalMetrics, ...
    "FuelSummary", FuelSummary, ...
    "FuelPerSequence", FuelPerSequence, ...
    "SOCComparison", SOCComparison, ...
    "FinalSOCParity", FinalSOCParity, ...
    "OptimizerDiagnostics", OptimizerDiagnostics, ...
    "SensitivitySummary", SensitivitySummary, ...
    "AdditionalMetrics", AdditionalMetrics, ...
    "RepresentativeSequence", Representative, ...
    "CompletedSequenceIndices", Completed, ...
    "MissingSequenceIndices", Missing, ...
    "OutputDirectory", string(OutputDirectory));

fprintf("HEA paper results complete: %d/%d sequences, representative " + ...
    "sequence %d.\nOutput: %s\n", numel(Completed), ...
    numel(Expected), Representative, OutputDirectory);
disp(OperationalMetrics(:, ["Metric","N","Mean","StdDev"]));
disp(FuelSummary(:, ["CaseName","N","MeanFuelBurn_kg", ...
    "StdDevFuelBurn_kg","MeanReductionVsConventional_pct"]));
end


function [Files, Discovery] = DiscoverCheckpoints(Root, Expected, ...
        RunVersion, MaxIterations)
Flat = dir(fullfile(Root, "Sequence_*.mat"));
Recursive = dir(fullfile(Root, "**", "Sequence_*.mat"));
Candidates = [Flat; Recursive];
if isempty(Candidates)
    Files = table;
    Discovery = table;
    return;
end
Paths = string(fullfile({Candidates.folder}, {Candidates.name}))';
[Paths, ia] = unique(Paths, "stable");
Candidates = Candidates(ia);

Sequence = nan(numel(Paths), 1);
Valid = false(numel(Paths), 1);
Reason = strings(numel(Paths), 1);
Modified = NaT(numel(Paths), 1);
for k = 1:numel(Paths)
    Token = regexp(Candidates(k).name, ...
        '^Sequence_(\d+)\.mat$', 'tokens', 'once');
    Modified(k) = datetime(Candidates(k).datenum, ...
        "ConvertFrom", "datenum");
    if isempty(Token)
        Reason(k) = "not a checkpoint filename";
        continue;
    end
    Sequence(k) = str2double(Token{1});
    if ~ismember(Sequence(k), Expected)
        Reason(k) = "outside requested sequence range";
        continue;
    end
    try
        M = load(char(Paths(k)), "Status", "RunMetadata");
        if ~isfield(M, "Status") || string(M.Status) ~= "success"
            Reason(k) = "status is not success";
        elseif ~isfield(M, "RunMetadata")
            Reason(k) = "missing RunMetadata";
        elseif string(M.RunMetadata.RunVersion) ~= RunVersion
            Reason(k) = "different run version";
        elseif M.RunMetadata.MaxIterations ~= MaxIterations
            Reason(k) = "different optimizer iteration count";
        else
            Valid(k) = true;
            Reason(k) = "valid";
        end
    catch ME
        Reason(k) = "unreadable/in progress: " + string(ME.identifier);
    end
end

Discovery = table(Sequence, Paths, Modified, Valid, Reason, ...
    'VariableNames', {'Sequence','File','Modified','Valid','Reason'});
ValidRows = find(Valid);
if isempty(ValidRows)
    Files = table;
    return;
end

% If both a flat and task-sharded copy exist, keep the newest valid copy.
V = Discovery(ValidRows, :);
V = sortrows(V, {'Sequence','Modified'}, {'ascend','descend'});
[~, Keep] = unique(V.Sequence, "stable");
Files = sortrows(V(Keep, {'Sequence','File','Modified'}), "Sequence");
end


function [Summary, Flights, Charges, OptimizerDiagnostics] = ...
        LoadCheckpointTables(Files)
n = height(Files);
SummaryCell = cell(n, 1);
FlightCell = cell(n, 1);
ChargeCell = cell(n, 1);
OptimizerCell = cell(n, 1);
for k = 1:n
    D = load(char(Files.File(k)), "SequenceSummary", ...
        "FlightResults", "ChargeResults", "OptimizerResults");
    Index = Files.Sequence(k);
    S = D.SequenceSummary;
    if ~ismember("Sequence", string(S.Properties.VariableNames))
        S.Sequence = repmat(Index, height(S), 1);
        S = movevars(S, "Sequence", "Before", 1);
    end
    F = D.FlightResults;
    if ismember("Sequence", string(F.Properties.VariableNames))
        F.Sequence(:) = Index;
    else
        F.Sequence = repmat(Index, height(F), 1);
        F = movevars(F, "Sequence", "Before", 1);
    end
    C = D.ChargeResults;
    if ismember("Sequence", string(C.Properties.VariableNames))
        C.Sequence(:) = Index;
    else
        C.Sequence = repmat(Index, height(C), 1);
        C = movevars(C, "Sequence", "Before", 1);
    end
    SummaryCell{k} = S;
    FlightCell{k} = F;
    ChargeCell{k} = C;
    if isfield(D, "OptimizerResults")
        OptimizerCell{k} = BuildOptimizerDiagnosticRows( ...
            Index, S, D.OptimizerResults);
    else
        OptimizerCell{k} = EmptyOptimizerDiagnosticRows;
    end
    if mod(k, 25) == 0 || k == n
        fprintf("  loaded %d/%d checkpoints\n", k, n);
    end
end
Summary = vertcat(SummaryCell{:});
Flights = vertcat(FlightCell{:});
Charges = vertcat(ChargeCell{:});
OptimizerDiagnostics = vertcat(OptimizerCell{:});
Summary = sortrows(Summary, "Sequence");
Flights = sortrows(Flights, {'Sequence','CaseName','Flight'});
Charges = sortrows(Charges, {'Sequence','CaseName','AfterFlight'});
OptimizerDiagnostics = sortrows(OptimizerDiagnostics, ...
    {'Sequence','Strategy'});
end


function T = BuildOptimizerDiagnosticRows(Index, Summary, O)
Rows = cell(2, 1);
JointExit = double(O.JointExitFlag(:));
JointOutput = O.JointOutput;
Rows{1} = OptimizerDiagnosticRow(Index, "Joint optimization", ...
    logical(Summary.JointFeasible(1)), JointExit, {JointOutput}, ...
    Summary.JointOptimizerTime_min(1));

IndividualExit = double(O.IndividualExitFlag(:));
IndividualOutput = O.IndividualOutput;
if ~iscell(IndividualOutput), IndividualOutput = {IndividualOutput}; end
Rows{2} = OptimizerDiagnosticRow(Index, "Individual optimization", ...
    logical(Summary.IndividualFeasible(1)), IndividualExit, ...
    IndividualOutput, Summary.IndividualOptimizerTime_min(1));
T = vertcat(Rows{:});
end


function T = OptimizerDiagnosticRow(Index, Strategy, Feasible, ...
        ExitFlags, Outputs, OptimizerTime_min)
ExitFlags = double(ExitFlags(:));
ConvergedFraction = mean(ExitFlags > 0, "omitnan");
Iterations = nan(numel(Outputs), 1);
MaxConstraints = nan(numel(Outputs), 1);
UsedBestFeasible = false(numel(Outputs), 1);
UsedFeasibleInitialPoint = false(numel(Outputs), 1);
FallbackToUnoptimized = false(numel(Outputs), 1);
for k = 1:numel(Outputs)
    Value = Outputs{k};
    if ~isstruct(Value), continue; end
    Iterations(k) = NumericStructField(Value, "iterations");
    MaxConstraints(k) = NumericStructField(Value, "MaxConstraint");
    if ~isfinite(MaxConstraints(k))
        MaxConstraints(k) = NumericStructField(Value, "ReplayMaxConstraint");
    end
    UsedBestFeasible(k) = LogicalStructField(Value, "UsedBestFeasible");
    UsedFeasibleInitialPoint(k) = ...
        LogicalStructField(Value, "UsedFeasibleInitialPoint");
    FallbackToUnoptimized(k) = ...
        LogicalStructField(Value, "FallbackToUnoptimized");
end
T = table(Index, string(Strategy), logical(Feasible), ...
    all(ExitFlags > 0), ConvergedFraction, min(ExitFlags, [], "omitnan"), ...
    mean(ExitFlags, "omitnan"), sum(Iterations, "omitnan"), ...
    mean(Iterations, "omitnan"), max(MaxConstraints, [], "omitnan"), ...
    sum(UsedBestFeasible), sum(UsedFeasibleInitialPoint), ...
    sum(FallbackToUnoptimized), OptimizerTime_min, ...
    'VariableNames', {'Sequence','Strategy','Feasible', ...
    'AllOptimizersConverged','ConvergedFlightFraction', ...
    'MinimumExitFlag','MeanExitFlag','TotalIterations','MeanIterations', ...
    'MaximumConstraintViolation','UsedBestFeasibleCount', ...
    'UsedFeasibleInitialPointCount','FallbackToUnoptimizedCount', ...
    'OptimizerTime_min'});
end


function Value = NumericStructField(S, Name)
Value = NaN;
if isfield(S, Name) && isnumeric(S.(Name)) && ~isempty(S.(Name))
    FieldValue = S.(Name);
    Value = double(FieldValue(1));
end
end


function Value = LogicalStructField(S, Name)
Value = false;
if isfield(S, Name) && ~isempty(S.(Name))
    FieldValue = S.(Name);
    Value = logical(FieldValue(1));
end
end


function T = EmptyOptimizerDiagnosticRows
T = table('Size', [0 14], 'VariableTypes', ...
    {'double','string','logical','logical','double','double','double', ...
    'double','double','double','double','double','double','double'}, ...
    'VariableNames', {'Sequence','Strategy','Feasible', ...
    'AllOptimizersConverged','ConvergedFlightFraction', ...
    'MinimumExitFlag','MeanExitFlag','TotalIterations','MeanIterations', ...
    'MaximumConstraintViolation','UsedBestFeasibleCount', ...
    'UsedFeasibleInitialPointCount','FallbackToUnoptimizedCount', ...
    'OptimizerTime_min'});
end


function T = BuildOperationalMetrics(Summary, Flights)
% Use one case only so the common schedule is not counted four times.
Schedule = Flights(string(Flights.CaseName) == "Conventional", :);
if isempty(Schedule)
    Schedule = Flights(string(Flights.CaseName) == "Joint", :);
end
GroundStops = Schedule.GroundTime_min(Schedule.Flight > 1);
T = [ ...
    SummarizeVector("Flight mission distance", "nmi", ...
        Schedule.Distance_nmi); ...
    SummarizeVector("Daily sequence distance", "nmi/sequence", ...
        Summary.Distance_nmi); ...
    SummarizeVector("Between-flight ground time", "min", GroundStops); ...
    SummarizeVector("Flights per sequence", "flights/sequence", ...
        Summary.Flights)];
end


function [SummaryTable, PerSequence] = BuildFuelTables(S)
Cases = ["Conventional","Unoptimized","Individual","Joint"];
FuelVars = ["ConventionalFuelBurn_kg","UnoptimizedFuelBurn_kg", ...
    "IndividualFuelBurn_kg","JointFuelBurn_kg"];
Conv = S.ConventionalFuelBurn_kg;
Unoptimized = S.UnoptimizedFuelBurn_kg;
PerSequence = table(S.Sequence, ...
    S.ConventionalFuelBurn_kg, S.UnoptimizedFuelBurn_kg, ...
    S.IndividualFuelBurn_kg, S.JointFuelBurn_kg, ...
    'VariableNames', {'Sequence','ConventionalFuelBurn_kg', ...
    'UnoptimizedFuelBurn_kg','IndividualFuelBurn_kg','JointFuelBurn_kg'});

Rows = cell(numel(Cases), 1);
for k = 1:numel(Cases)
    Fuel = S.(FuelVars(k));
    Normalized = Fuel ./ Conv;
    Reduction = Conv - Fuel;
    ReductionPct = 100 * Reduction ./ Conv;
    OptimizationReduction = Unoptimized - Fuel;
    OptimizationReductionPct = 100 * OptimizationReduction ./ Unoptimized;
    FS = ScalarStats(Fuel);
    NS = ScalarStats(Normalized);
    RS = ScalarStats(Reduction);
    RPS = ScalarStats(ReductionPct);
    OS = ScalarStats(OptimizationReduction);
    OPS = ScalarStats(OptimizationReductionPct);
    Rows{k} = table(Cases(k), FS.N, FS.Mean, FS.StdDev, FS.Variance, ...
        FS.StandardError, FS.CI95Low, FS.CI95High, ...
        NS.Mean, NS.StdDev, NS.Variance, ...
        RS.Mean, RS.StdDev, RS.Variance, ...
        RPS.Mean, RPS.StdDev, RPS.Variance, ...
        OS.Mean, OS.StdDev, OS.Variance, ...
        OPS.Mean, OPS.StdDev, OPS.Variance, ...
        'VariableNames', {'CaseName','N','MeanFuelBurn_kg', ...
        'StdDevFuelBurn_kg','VarianceFuelBurn_kg2', ...
        'StandardErrorFuelBurn_kg','CI95LowFuelBurn_kg', ...
        'CI95HighFuelBurn_kg','MeanNormalizedFuelBurn', ...
        'StdDevNormalizedFuelBurn','VarianceNormalizedFuelBurn', ...
        'MeanReductionVsConventional_kg', ...
        'StdDevReductionVsConventional_kg', ...
        'VarianceReductionVsConventional_kg2', ...
        'MeanReductionVsConventional_pct', ...
        'StdDevReductionVsConventional_pct', ...
        'VarianceReductionVsConventional_pct2', ...
        'MeanReductionVsUnoptimizedHEA_kg', ...
        'StdDevReductionVsUnoptimizedHEA_kg', ...
        'VarianceReductionVsUnoptimizedHEA_kg2', ...
        'MeanReductionVsUnoptimizedHEA_pct', ...
        'StdDevReductionVsUnoptimizedHEA_pct', ...
        'VarianceReductionVsUnoptimizedHEA_pct2'});
    PerSequence.(Cases(k) + "Normalized") = Normalized;
    PerSequence.(Cases(k) + "ReductionVsConventional_kg") = Reduction;
    PerSequence.(Cases(k) + "ReductionVsConventional_pct") = ReductionPct;
    PerSequence.(Cases(k) + "ReductionVsUnoptimizedHEA_kg") = ...
        OptimizationReduction;
    PerSequence.(Cases(k) + "ReductionVsUnoptimizedHEA_pct") = ...
        OptimizationReductionPct;
end
SummaryTable = vertcat(Rows{:});
end


function T = BuildSOCComparison(Summary, Flights, Charges)
Cases = ["Unoptimized","Individual","Joint"];
Rows = cell(0, 1);
for iCase = 1:numel(Cases)
    CaseName = Cases(iCase);
    F = Flights(string(Flights.CaseName) == CaseName, :);
    [Found, Loc] = ismember(F.Sequence, Summary.Sequence);
    TotalFlights = nan(height(F), 1);
    TotalFlights(Found) = Summary.Flights(Loc(Found));
    IsNonLast = F.Flight < TotalFlights;
    for Position = 1:3
        Values = F.EndSOC_pct(IsNonLast & F.Flight == Position);
        Rows{end + 1, 1} = SOCRow(CaseName, ...
            "Ending SOC after flight " + Position + " (non-last only)", ...
            Position, Values); %#ok<AGROW>
    end
    Rows{end + 1, 1} = SOCRow(CaseName, ...
        "Ending SOC after all non-last flights", NaN, ...
        F.EndSOC_pct(IsNonLast)); %#ok<AGROW>
    C = Charges(string(Charges.CaseName) == CaseName, :);
    Rows{end + 1, 1} = SOCRow(CaseName, ...
        "SOC added during ground charging", NaN, ...
        C.SOCAdded_pct); %#ok<AGROW>
end
T = vertcat(Rows{:});
end


function T = SOCRow(CaseName, Metric, FlightPosition, Values)
S = ScalarStats(Values);
T = table(string(CaseName), string(Metric), FlightPosition, ...
    S.N, S.Mean, S.StdDev, S.Variance, S.StandardError, ...
    S.CI95Low, S.CI95High, ...
    'VariableNames', {'CaseName','Measurement','FlightPosition', ...
    'N','Mean_pct','StdDev_pct','Variance_pct2','StandardError_pct', ...
    'CI95Low_pct','CI95High_pct'});
end


function T = BuildAdditionalMetrics(Summary, Flights, Charges)
Cases = ["Unoptimized","Individual","Joint"];
Rows = cell(0, 1);
for iCase = 1:numel(Cases)
    CaseName = Cases(iCase);
    F = Flights(string(Flights.CaseName) == CaseName, :);
    C = Charges(string(Charges.CaseName) == CaseName, :);
    Final = false(height(F), 1);
    for k = 1:height(F)
        Final(k) = F.Flight(k) == max(F.Flight(F.Sequence == F.Sequence(k)));
    end
    Rows{end + 1} = AdditionalRow(CaseName, ...
        "Final-flight ending SOC", "%", F.EndSOC_pct(Final)); %#ok<AGROW>
    Rows{end + 1} = AdditionalRow(CaseName, ...
        "Battery terminal energy per flight", "kWh", ...
        F.BatteryTerminal_kWh); %#ok<AGROW>
    Rows{end + 1} = AdditionalRow(CaseName, ...
        "Ground charge duration", "min", C.ActualTime_min); %#ok<AGROW>
    Rows{end + 1} = AdditionalRow(CaseName, ...
        "Post-charge SOC", "%", C.SOCEnd_pct); %#ok<AGROW>
    if ismember("GridEnergy_kWh", string(C.Properties.VariableNames))
        Rows{end + 1} = AdditionalRow(CaseName, ...
            "Grid energy per charging event", "kWh", ...
            C.GridEnergy_kWh); %#ok<AGROW>
    end
    if ismember("TemperatureEnd_C", string(C.Properties.VariableNames))
        Rows{end + 1} = AdditionalRow(CaseName, ...
            "Battery temperature after charging", "degC", ...
            C.TemperatureEnd_C); %#ok<AGROW>
    end
    Rows{end + 1} = AdditionalRow(CaseName, ...
        "Feasible flight indicator", "fraction", double(F.Feasible)); %#ok<AGROW>
end
Rows{end + 1} = AdditionalRow("Joint", ...
    "Optimizer worker time per sequence", "min", ...
    Summary.JointOptimizerTime_min);
Rows{end + 1} = AdditionalRow("Individual", ...
    "Optimizer worker time per sequence", "min", ...
    Summary.IndividualOptimizerTime_min);
T = vertcat(Rows{:});
end


function [BySequence, SummaryTable] = BuildFinalSOCParity(Summary, Flights)
Sequences = Summary.Sequence;
n = numel(Sequences);
UnoptimizedFinalSOC_pct = nan(n, 1);
IndividualFinalSOC_pct = nan(n, 1);
JointFinalSOC_pct = nan(n, 1);
for k = 1:n
    Index = Sequences(k);
    UnoptimizedFinalSOC_pct(k) = FinalSOCForCase( ...
        Flights, Index, "Unoptimized");
    IndividualFinalSOC_pct(k) = FinalSOCForCase( ...
        Flights, Index, "Individual");
    JointFinalSOC_pct(k) = FinalSOCForCase(Flights, Index, "Joint");
end
JointMinusIndividual_pct = JointFinalSOC_pct - IndividualFinalSOC_pct;
JointMinusUnoptimized_pct = JointFinalSOC_pct - UnoptimizedFinalSOC_pct;
MaximumHEASpread_pct = max([UnoptimizedFinalSOC_pct, ...
    IndividualFinalSOC_pct, JointFinalSOC_pct], [], 2) - ...
    min([UnoptimizedFinalSOC_pct, IndividualFinalSOC_pct, ...
    JointFinalSOC_pct], [], 2);
BySequence = table(Sequences, UnoptimizedFinalSOC_pct, ...
    IndividualFinalSOC_pct, JointFinalSOC_pct, ...
    JointMinusIndividual_pct, JointMinusUnoptimized_pct, ...
    MaximumHEASpread_pct, ...
    'VariableNames', {'Sequence','UnoptimizedFinalSOC_pct', ...
    'IndividualFinalSOC_pct','JointFinalSOC_pct', ...
    'JointMinusIndividualFinalSOC_pct', ...
    'JointMinusUnoptimizedFinalSOC_pct','MaximumHEAFinalSOCSpread_pct'});
SummaryTable = [ ...
    SummarizeVector("Unoptimized final SOC", "%", ...
        UnoptimizedFinalSOC_pct); ...
    SummarizeVector("Individual-optimized final SOC", "%", ...
        IndividualFinalSOC_pct); ...
    SummarizeVector("Joint-optimized final SOC", "%", ...
        JointFinalSOC_pct); ...
    SummarizeVector("Joint minus individual final SOC", ...
        "percentage points", JointMinusIndividual_pct); ...
    SummarizeVector("Joint minus unoptimized final SOC", ...
        "percentage points", JointMinusUnoptimized_pct); ...
    SummarizeVector("Maximum final-SOC spread among HEA cases", ...
        "percentage points", MaximumHEASpread_pct)];
end


function Value = FinalSOCForCase(Flights, Index, CaseName)
F = Flights(Flights.Sequence == Index & ...
    string(Flights.CaseName) == CaseName, :);
if isempty(F)
    Value = NaN;
else
    [~, Last] = max(F.Flight);
    Value = F.EndSOC_pct(Last);
end
end


function T = BuildOptimizerSummary(D)
Strategies = unique(D.Strategy, "stable");
Rows = cell(numel(Strategies), 1);
for k = 1:numel(Strategies)
    Strategy = Strategies(k);
    S = D(D.Strategy == Strategy, :);
    Rows{k} = table(Strategy, height(S), sum(S.Feasible), ...
        100 * mean(S.Feasible), sum(S.AllOptimizersConverged), ...
        100 * mean(S.AllOptimizersConverged), ...
        100 * mean(S.ConvergedFlightFraction, "omitnan"), ...
        mean(S.MinimumExitFlag, "omitnan"), ...
        mean(S.TotalIterations, "omitnan"), ...
        mean(S.MaximumConstraintViolation, "omitnan"), ...
        sum(S.UsedBestFeasibleCount), ...
        sum(S.UsedFeasibleInitialPointCount), ...
        sum(S.FallbackToUnoptimizedCount), ...
        mean(S.OptimizerTime_min, "omitnan"), ...
        'VariableNames', {'Strategy','Sequences','FeasibleSequences', ...
        'FeasibilityRate_pct','FullyConvergedSequences', ...
        'FullConvergenceRate_pct','MeanConvergedFlightRate_pct', ...
        'MeanMinimumExitFlag','MeanTotalIterations', ...
        'MeanMaximumConstraintViolation','UsedBestFeasibleCount', ...
        'UsedFeasibleInitialPointCount','FallbackToUnoptimizedCount', ...
        'MeanOptimizerTime_min'});
end
T = vertcat(Rows{:});
end


function [Data, SummaryTable] = BuildFuelSavingsSensitivity(S, Flights, Charges)
Schedule = Flights(string(Flights.CaseName) == "Conventional", :);
Sequences = S.Sequence;
n = height(S);
TotalGroundTime_min = zeros(n, 1);
MeanGroundTime_min = zeros(n, 1);
Cases = ["Unoptimized","Individual","Joint"];
MeanAvailableChargeTime_min = nan(n, numel(Cases));
MeanActualChargeTime_min = nan(n, numel(Cases));
MeanSOCAdded_pct = nan(n, numel(Cases));
MeanPostChargeSOC_pct = nan(n, numel(Cases));
FullRechargeFraction = nan(n, numel(Cases));
for k = 1:n
    G = Schedule.GroundTime_min(Schedule.Sequence == Sequences(k) & ...
        Schedule.Flight > 1);
    TotalGroundTime_min(k) = sum(G, "omitnan");
    MeanGroundTime_min(k) = mean(G, "omitnan");
    for iCase = 1:numel(Cases)
        C = Charges(Charges.Sequence == Sequences(k) & ...
            string(Charges.CaseName) == Cases(iCase), :);
        MeanAvailableChargeTime_min(k, iCase) = ...
            mean(C.AvailableTime_min, "omitnan");
        MeanActualChargeTime_min(k, iCase) = ...
            mean(C.ActualTime_min, "omitnan");
        MeanSOCAdded_pct(k, iCase) = mean(C.SOCAdded_pct, "omitnan");
        MeanPostChargeSOC_pct(k, iCase) = mean(C.SOCEnd_pct, "omitnan");
        FullRechargeFraction(k, iCase) = mean(C.SOCEnd_pct >= 99.5, "omitnan");
    end
end
Conv = S.ConventionalFuelBurn_kg;
Unoptimized = S.UnoptimizedFuelBurn_kg;
UnoptimizedFuelSaving_pct = 100 * ...
    (Conv - Unoptimized) ./ Conv;
IndividualFuelSaving_pct = 100 * ...
    (Conv - S.IndividualFuelBurn_kg) ./ Conv;
JointFuelSaving_pct = 100 * (Conv - S.JointFuelBurn_kg) ./ Conv;
IndividualOptimizationBenefit_pct = 100 * ...
    (Unoptimized - S.IndividualFuelBurn_kg) ./ Unoptimized;
JointOptimizationBenefit_pct = 100 * ...
    (Unoptimized - S.JointFuelBurn_kg) ./ Unoptimized;
JointAdditionalBenefitVsIndividual_pct = 100 * ...
    (S.IndividualFuelBurn_kg - S.JointFuelBurn_kg) ./ ...
    S.IndividualFuelBurn_kg;
BaselineFuelSaving_kg = Conv - Unoptimized;
RelativeDenominator = abs(BaselineFuelSaving_kg);
RelativeTolerance = 1e-9 .* max(1, abs(Conv));
RelativeDenominator(RelativeDenominator <= RelativeTolerance) = NaN;
IndividualAdditionalSavingsRelativeToBaseline_pct = 100 * ...
    (Unoptimized - S.IndividualFuelBurn_kg) ./ RelativeDenominator;
JointAdditionalSavingsRelativeToBaseline_pct = 100 * ...
    (Unoptimized - S.JointFuelBurn_kg) ./ RelativeDenominator;
% Negative error means the optimized case saved more fuel. Thus -5% means
% 5% additional saving relative to the unoptimized HEA's original saving
% versus conventional.
IndividualRelativeFuelError_pct = ...
    -IndividualAdditionalSavingsRelativeToBaseline_pct;
JointRelativeFuelError_pct = -JointAdditionalSavingsRelativeToBaseline_pct;
Data = table(Sequences, S.Distance_nmi, S.Flights, ...
    TotalGroundTime_min, MeanGroundTime_min, ...
    UnoptimizedFuelSaving_pct, IndividualFuelSaving_pct, ...
    JointFuelSaving_pct, IndividualOptimizationBenefit_pct, ...
    JointOptimizationBenefit_pct, JointAdditionalBenefitVsIndividual_pct, ...
    BaselineFuelSaving_kg, ...
    IndividualAdditionalSavingsRelativeToBaseline_pct, ...
    JointAdditionalSavingsRelativeToBaseline_pct, ...
    IndividualRelativeFuelError_pct, JointRelativeFuelError_pct, ...
    'VariableNames', {'Sequence','SequenceDistance_nmi','FlightsPerSequence', ...
    'TotalGroundTime_min','MeanGroundTime_min', ...
    'UnoptimizedFuelSaving_pct','IndividualFuelSaving_pct', ...
    'JointFuelSaving_pct','IndividualOptimizationBenefit_pct', ...
    'JointOptimizationBenefit_pct','JointAdditionalBenefitVsIndividual_pct', ...
    'UnoptimizedBaselineFuelSavingVsConventional_kg', ...
    'IndividualAdditionalSavingsRelativeToBaseline_pct', ...
    'JointAdditionalSavingsRelativeToBaseline_pct', ...
    'IndividualRelativeFuelError_pct','JointRelativeFuelError_pct'});
for iCase = 1:numel(Cases)
    Prefix = Cases(iCase);
    Data.(Prefix + "MeanAvailableChargeTime_min") = ...
        MeanAvailableChargeTime_min(:, iCase);
    Data.(Prefix + "MeanActualChargeTime_min") = ...
        MeanActualChargeTime_min(:, iCase);
    Data.(Prefix + "MeanSOCAdded_pct") = MeanSOCAdded_pct(:, iCase);
    Data.(Prefix + "MeanPostChargeSOC_pct") = ...
        MeanPostChargeSOC_pct(:, iCase);
    Data.(Prefix + "FullRechargeFraction") = FullRechargeFraction(:, iCase);
end

OutcomeLabels = ["Unoptimized HEA saving vs conventional", ...
    "Individual optimization saving vs conventional", ...
    "Joint optimization saving vs conventional", ...
    "Individual additional saving vs unoptimized savings baseline", ...
    "Joint additional saving vs unoptimized savings baseline", ...
    "Joint added benefit vs individual optimization"];
Outcomes = ["UnoptimizedFuelSaving_pct","IndividualFuelSaving_pct", ...
    "JointFuelSaving_pct", ...
    "IndividualAdditionalSavingsRelativeToBaseline_pct", ...
    "JointAdditionalSavingsRelativeToBaseline_pct", ...
    "JointAdditionalBenefitVsIndividual_pct"];
ChargePrefixes = ["Unoptimized","Individual","Joint", ...
    "Individual","Joint","Joint"];
CommonPredictors = ["SequenceDistance_nmi","FlightsPerSequence", ...
    "MeanGroundTime_min"];
CommonLabels = ["Sequence distance","Flights per sequence", ...
    "Mean between-flight ground time"];
CommonUnits = ["nmi","flights","min"];
ChargeSuffixes = ["MeanAvailableChargeTime_min", ...
    "MeanActualChargeTime_min","MeanSOCAdded_pct", ...
    "MeanPostChargeSOC_pct","FullRechargeFraction"];
ChargeLabels = ["Mean available charging time", ...
    "Mean actual charging time","Mean SOC added while charging", ...
    "Mean post-charge SOC","Fraction of charges reaching 99.5% SOC"];
ChargeUnits = ["min","min","%","%","fraction"];
Rows = cell(numel(Outcomes) * ...
    (numel(CommonPredictors) + numel(ChargeSuffixes)), 1);
iRow = 0;
for iOutcome = 1:numel(Outcomes)
    Y = Data.(Outcomes(iOutcome));
    Predictors = [CommonPredictors, ...
        ChargePrefixes(iOutcome) + ChargeSuffixes];
    PredictorLabels = [CommonLabels, ChargeLabels];
    PredictorUnits = [CommonUnits, ChargeUnits];
    for iPredictor = 1:numel(Predictors)
        iRow = iRow + 1;
        X = Data.(Predictors(iPredictor));
        Fit = SimpleLinearSensitivity(X, Y);
        Rows{iRow} = table(OutcomeLabels(iOutcome), ...
            PredictorLabels(iPredictor), ...
            PredictorUnits(iPredictor), Fit.N, Fit.Slope, Fit.Intercept, ...
            Fit.PearsonR, Fit.RSquared, ...
            'VariableNames', {'FuelSavingOutcome','Predictor','PredictorUnit', ...
            'N','FuelSavingSlope_pctPointsPerPredictorUnit', ...
            'FuelSavingIntercept_pct','PearsonCorrelation', ...
            'RSquared'});
    end
end
SummaryTable = vertcat(Rows{:});
end


function Fit = SimpleLinearSensitivity(X, Y)
Valid = isfinite(X) & isfinite(Y);
X = double(X(Valid)); Y = double(Y(Valid));
Fit.N = numel(X);
XTolerance = 1e-12 * max(1, max(abs(X), [], "omitnan"));
YTolerance = 1e-12 * max(1, max(abs(Y), [], "omitnan"));
if Fit.N < 2 || max(X) - min(X) <= XTolerance
    [Fit.Slope, Fit.Intercept, Fit.PearsonR, Fit.RSquared] = deal(NaN);
    return;
end
if max(Y) - min(Y) <= YTolerance
    Fit.Slope = 0;
    Fit.Intercept = mean(Y);
    Fit.PearsonR = NaN;
    Fit.RSquared = NaN;
    return;
end
Coefficients = polyfit(X, Y, 1);
Predicted = polyval(Coefficients, X);
Fit.Slope = Coefficients(1);
Fit.Intercept = Coefficients(2);
Correlation = corrcoef(X, Y);
Fit.PearsonR = Correlation(1, 2);
SSTotal = sum((Y - mean(Y)).^2);
if SSTotal == 0
    Fit.RSquared = NaN;
else
    Fit.RSquared = min(max(1 - sum((Y - Predicted).^2) / SSTotal, 0), 1);
end
end


function T = AdditionalRow(CaseName, Metric, Unit, Values)
S = ScalarStats(Values);
T = table(string(CaseName), string(Metric), string(Unit), ...
    S.N, S.Mean, S.StdDev, S.Variance, S.StandardError, ...
    S.CI95Low, S.CI95High, S.Median, S.Minimum, S.Maximum, ...
    'VariableNames', {'CaseName','Metric','Unit','N','Mean','StdDev', ...
    'Variance','StandardError','CI95Low','CI95High','Median','Minimum', ...
    'Maximum'});
end


function T = SummarizeVector(Metric, Unit, Values)
S = ScalarStats(Values);
T = table(string(Metric), string(Unit), S.N, S.Mean, S.StdDev, ...
    S.Variance, S.StandardError, S.CI95Low, S.CI95High, S.Median, ...
    S.Minimum, S.Maximum, S.CoefficientOfVariation_pct, ...
    'VariableNames', {'Metric','Unit','N','Mean','StdDev','Variance', ...
    'StandardError','CI95Low','CI95High','Median','Minimum','Maximum', ...
    'CoefficientOfVariation_pct'});
end


function S = ScalarStats(Values)
Values = double(Values(:));
Values = Values(isfinite(Values));
S.N = numel(Values);
if isempty(Values)
    [S.Mean, S.StdDev, S.Variance, S.StandardError, S.CI95Low, ...
        S.CI95High, S.Median, S.Minimum, S.Maximum, ...
        S.CoefficientOfVariation_pct] = deal(NaN);
    return;
end
S.Mean = mean(Values);
S.StdDev = std(Values, 0);
S.Variance = var(Values, 0);
S.StandardError = S.StdDev / sqrt(S.N);
S.CI95Low = S.Mean - 1.96 * S.StandardError;
S.CI95High = S.Mean + 1.96 * S.StandardError;
S.Median = median(Values);
S.Minimum = min(Values);
S.Maximum = max(Values);
if S.Mean == 0
    S.CoefficientOfVariation_pct = NaN;
else
    S.CoefficientOfVariation_pct = 100 * S.StdDev / abs(S.Mean);
end
end


function MakeFuelDistributionPlot(T, OutDir, IsVisible)
Cases = ["Conventional","Unoptimized","Individual","Joint"];
Labels = ["Conventional","Unoptimized HEA", ...
    "Individual optimized","Joint optimized"];
Colors = [0.25 0.25 0.25; 0.4660 0.6740 0.1880; ...
    0.8500 0.3250 0.0980; 0.0000 0.4470 0.7410];
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [50 50 1550 650]);
L = tiledlayout(Fig, 1, 2, "TileSpacing", "compact", ...
    "Padding", "compact");

Ax = nexttile(L); hold(Ax, "on");
for k = 1:numel(Cases)
    Y = T.(Cases(k) + "ReductionVsConventional_pct");
    Jitter = 0.17 * sin(double(T.Sequence) * 12.9898 + k * 7.233);
    scatter(Ax, k + Jitter, Y, 18, Colors(k, :), "filled", ...
        "MarkerFaceAlpha", 0.42, "MarkerEdgeAlpha", 0.25, ...
        "DisplayName", Labels(k));
    M = mean(Y, "omitnan"); SD = std(Y, 0, "omitnan");
    errorbar(Ax, k, M, SD, "k", "LineStyle", "none", ...
        "LineWidth", 1.5, "CapSize", 10, "HandleVisibility", "off");
    plot(Ax, [k-0.15 k+0.15], [M M], "k-", "LineWidth", 2, ...
        "HandleVisibility", "off");
end
yline(Ax, 0, ":", "Conventional = 0%", "LineWidth", 1.2);
set(Ax, "XTick", 1:4, "XTickLabel", Labels);
xlim(Ax, [0.5 4.5]);
ylabel(Ax, "Fuel saving relative to conventional (%)");
title(Ax, "All completed sequences (mean \pm SD)");
StylePaperAxes(Ax);

Ax = nexttile(L); hold(Ax, "on");
for k = 1:numel(Cases)
    Y = sort(T.(Cases(k) + "ReductionVsConventional_pct"));
    Y = Y(isfinite(Y));
    F = (1:numel(Y))' / numel(Y);
    stairs(Ax, Y, F, "LineWidth", 1.8, "Color", Colors(k, :), ...
        "DisplayName", Labels(k));
end
xline(Ax, 0, ":", "Conventional = 0%", "LineWidth", 1.2, ...
    "HandleVisibility", "off");
xlabel(Ax, "Fuel saving relative to conventional (%)");
ylabel(Ax, "Empirical cumulative probability");
title(Ax, "Empirical distributions");
Leg = legend(Ax, "Location", "best");
set(Leg, "Color", "w", "TextColor", "k");
StylePaperAxes(Ax);
title(L, "Sequence-level fuel burn normalized to paired conventional operation");
L.Title.Color = "k";

exportgraphics(Fig, fullfile(OutDir, ...
    "Fuel_Savings_Vs_Conventional_Distribution.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function MakeSensitivityPlot(T, OutDir, IsVisible)
Cases = ["Individual","Joint"];
Labels = ["Individual additional fuel saving", ...
    "Joint additional fuel saving"];
Outcomes = ["IndividualAdditionalSavingsRelativeToBaseline_pct", ...
    "JointAdditionalSavingsRelativeToBaseline_pct"];
CommonPredictors = ["SequenceDistance_nmi","FlightsPerSequence", ...
    "MeanGroundTime_min"];
CommonXLabels = ["Sequence distance (nmi)","Flights per sequence", ...
    "Mean between-flight ground time (min)"];
Colors = [0.8500 0.3250 0.0980; 0.0000 0.4470 0.7410];
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [30 30 1700 900]);
L = tiledlayout(Fig, 2, 4, "TileSpacing", "compact", ...
    "Padding", "compact");
for iCase = 1:numel(Cases)
    Y = T.(Outcomes(iCase));
    Predictors = [CommonPredictors, ...
        Cases(iCase) + "MeanAvailableChargeTime_min"];
    XLabels = [CommonXLabels, "Mean available charging time (min)"];
    for iPredictor = 1:numel(Predictors)
        Ax = nexttile(L); hold(Ax, "on");
        X = T.(Predictors(iPredictor));
        Valid = isfinite(X) & isfinite(Y);
        scatter(Ax, X(Valid), Y(Valid), 16, Colors(iCase, :), ...
            "filled", "MarkerFaceAlpha", 0.45, ...
            "MarkerEdgeAlpha", 0.25);
        Fit = SimpleLinearSensitivity(X, Y);
        if isfinite(Fit.Slope)
            XLine = linspace(min(X(Valid)), max(X(Valid)), 100)';
            plot(Ax, XLine, Fit.Intercept + Fit.Slope * XLine, ...
                "Color", Colors(iCase, :), "LineWidth", 1.7);
            if isfinite(Fit.PearsonR)
                Text = sprintf("r = %.3f, R^2 = %.3f", ...
                    Fit.PearsonR, Fit.RSquared);
            else
                Text = "No outcome variation";
                Center = mean(Y(Valid), "omitnan");
                Padding = max(0.5, 0.05 * abs(Center));
                ylim(Ax, Center + [-Padding Padding]);
            end
            text(Ax, 0.03, 0.95, Text, "Units", "normalized", ...
                "VerticalAlignment", "top", "Color", "k", ...
                "BackgroundColor", "w");
        end
        xlabel(Ax, XLabels(iPredictor));
        ylabel(Ax, "Additional saving vs unoptimized savings baseline (%)");
        title(Ax, Labels(iCase));
        StylePaperAxes(Ax);
    end
end
title(L, "Additional fuel saving from power-management optimization: " + ...
    "schedule and charging sensitivity");
L.Title.Color = "k";
exportgraphics(Fig, fullfile(OutDir, "Fuel_Savings_Sensitivity.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function [Selected, Ranking] = SelectRepresentativeSequence( ...
        Summary, Flights, Files, Requested)
Indices = intersect(Summary.Sequence, Files.Sequence, "stable");
MeanSOCAdvantage_pct = nan(numel(Indices), 1);
MinimumSOCAdvantage_pct = nan(numel(Indices), 1);
FractionNonLastFlightsJointHigherSOC = nan(numel(Indices), 1);
JointFuelSavingVsIndividual_pct = nan(numel(Indices), 1);
Score = nan(numel(Indices), 1);
for k = 1:numel(Indices)
    Index = Indices(k);
    F = Flights(Flights.Sequence == Index, :);
    J = sortrows(F(string(F.CaseName) == "Joint", :), "Flight");
    I = sortrows(F(string(F.CaseName) == "Individual", :), "Flight");
    n = min(height(J), height(I));
    if n < 2, continue; end
    Delta = J.EndSOC_pct(1:n-1) - I.EndSOC_pct(1:n-1);
    MeanSOCAdvantage_pct(k) = mean(Delta, "omitnan");
    MinimumSOCAdvantage_pct(k) = min(Delta, [], "omitnan");
    FractionNonLastFlightsJointHigherSOC(k) = mean(Delta > 0);
    S = Summary(Summary.Sequence == Index, :);
    JointFuelSavingVsIndividual_pct(k) = 100 * ...
        (S.IndividualFuelBurn_kg(1) - S.JointFuelBurn_kg(1)) / ...
        S.IndividualFuelBurn_kg(1);
    Score(k) = MeanSOCAdvantage_pct(k) + ...
        2 * FractionNonLastFlightsJointHigherSOC(k) + ...
        max(JointFuelSavingVsIndividual_pct(k), 0);
end
Ranking = table(Indices, MeanSOCAdvantage_pct, ...
    MinimumSOCAdvantage_pct, FractionNonLastFlightsJointHigherSOC, ...
    JointFuelSavingVsIndividual_pct, Score, ...
    'VariableNames', {'Sequence','MeanJointMinusIndividualEndingSOC_pct', ...
    'MinimumJointMinusIndividualEndingSOC_pct', ...
    'FractionNonLastFlightsJointHigherSOC', ...
    'JointFuelSavingVsIndividual_pct','SelectionScore'});
Ranking = sortrows(Ranking, "SelectionScore", "descend");

if ~isempty(Requested)
    if ~ismember(Requested, Indices)
        error("HEAOpsPaperResults:RepresentativeNotComplete", ...
            "Requested representative sequence %d is not complete.", Requested);
    end
    Selected = Requested;
else
    Eligible = Ranking.MeanJointMinusIndividualEndingSOC_pct > 0 & ...
        Ranking.JointFuelSavingVsIndividual_pct >= 0;
    if any(Eligible)
        Selected = Ranking.Sequence(find(Eligible, 1));
    else
        Selected = Ranking.Sequence(1);
    end
end
end


function MakeRepresentativeEightPanel(D, Index, OutDir, IsVisible)
Cases = ["Conventional","Unoptimized","Individual","Joint"];
PHECases = ["Unoptimized","Individual","Joint"];
Labels = ["Conventional","Unoptimized HEA", ...
    "Individual optimized","Joint optimized"];
Colors = [0.25 0.25 0.25; 0.4660 0.6740 0.1880; ...
    0.8500 0.3250 0.0980; 0.0000 0.4470 0.7410];
Styles = [":" "--" "-." "-"];
for k = 1:numel(Cases)
    Timeline.(Cases(k)) = BuildTimeline(D.MissionResults, ...
        D.Sequence, Cases(k));
end
for k = 1:numel(PHECases)
    SOCTimeline.(PHECases(k)) = BuildSOCTimeline(D.MissionResults, ...
        D.ChargeHistories, D.Sequence, PHECases(k));
end
Reference = Timeline.Joint;
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [30 30 1800 1400]);
L = tiledlayout(Fig, 4, 2, "TileSpacing", "compact", ...
    "Padding", "compact");

PlotTimelinePanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Altitude_ft", 1/1000, "Altitude (kft)", ...
    "Mission altitude", Reference);
PlotTimelinePanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Speed_kts", 1, "True airspeed (kt)", ...
    "Mission speed", Reference);

Ax = nexttile(L); hold(Ax, "on");
for k = 1:numel(PHECases)
    C = SOCTimeline.(PHECases(k));
    CaseIndex = find(Cases == PHECases(k));
    PlotThinned(Ax, C.Time_h, C.SOC_pct, Styles(CaseIndex), ...
        "LineWidth", 1.5, "Color", Colors(CaseIndex, :), ...
        "DisplayName", Labels(CaseIndex));
end
DecorateSequenceAxes(Ax, Reference, "Battery SOC (%)", ...
    "SOC with ground charging"); ylim(Ax, [0 105]); legend(Ax, "Location", "best");

PlotTimelinePanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "FuelTime_h", "CumulativeFuel_kg", 1, ...
    "Cumulative fuel burn (kg)", "Main-mission fuel burn", Reference);
PlotTimelinePanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "Preq_MW", 1, "Required power (MW)", ...
    "Required propulsion power", Reference);

Ax = nexttile(L); hold(Ax, "on");
for k = 2:numel(Cases)
    C = Timeline.(Cases(k));
    PlotThinned(Ax, C.Time_h, C.MotorUtilization, Styles(k), ...
        "LineWidth", 1.4, "Color", Colors(k, :), ...
        "DisplayName", Labels(k));
end
DecorateSequenceAxes(Ax, Reference, ...
    "EM output / uncapped rating", "Electric-machine utilization");
ylim(Ax, [-0.03 1.05]); legend(Ax, "Location", "best");

PlotTimelinePanel(nexttile(L), Timeline, Cases, Labels, Colors, Styles, ...
    "Time_h", "MDotFuel_kgs", 1, "Fuel flow (kg/s)", ...
    "Total fuel mass flow", Reference);

Ax = nexttile(L); hold(Ax, "on");
Conv = Timeline.Conventional;
for k = 2:numel(Cases)
    C = Timeline.(Cases(k));
    [ConvTime, ConvFuelValues] = UniqueFiniteSeries( ...
        Conv.FuelTime_h, Conv.CumulativeFuel_kg);
    [CaseTime, CaseFuelValues] = UniqueFiniteSeries( ...
        C.FuelTime_h, C.CumulativeFuel_kg);
    CommonTime = unique([ConvTime; CaseTime]);
    ConvFuel = interp1(ConvTime, ConvFuelValues, ...
        CommonTime, "linear", "extrap");
    CaseFuel = interp1(CaseTime, CaseFuelValues, ...
        CommonTime, "linear", "extrap");
    PlotThinned(Ax, CommonTime, ConvFuel - CaseFuel, Styles(k), ...
        "LineWidth", 1.6, "Color", Colors(k, :), ...
        "DisplayName", Labels(k));
end
DecorateSequenceAxes(Ax, Reference, ...
    "Fuel saved vs conventional (kg)", "Cumulative fuel saving");
yline(Ax, 0, ":", "HandleVisibility", "off");
legend(Ax, "Location", "best");

for Ax = findall(Fig, "Type", "axes")'
    xlabel(Ax, "Elapsed sequence time including ground time (h)");
    StylePaperAxes(Ax);
end
title(L, sprintf("Representative sequence %d: joint optimization " + ...
    "preserves inter-flight SOC and reduces fuel", Index));
L.Title.Color = "k";
BaseName = sprintf("Representative_Sequence_%04d_Mission_Comparison", Index);
exportgraphics(Fig, fullfile(OutDir, BaseName + ".pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function [X, Y] = UniqueFiniteSeries(X, Y)
Valid = isfinite(X) & isfinite(Y);
X = X(Valid);
Y = Y(Valid);
[X, Keep] = unique(X, "last");
Y = Y(Keep);
end


function PlotTimelinePanel(Ax, T, Cases, Labels, Colors, Styles, ...
        XField, YField, Scale, YLabelText, TitleText, Reference)
hold(Ax, "on");
for k = 1:numel(Cases)
    C = T.(Cases(k));
    PlotThinned(Ax, C.(XField), Scale * C.(YField), Styles(k), ...
        "LineWidth", 1.35, "Color", Colors(k, :), ...
        "DisplayName", Labels(k));
end
DecorateSequenceAxes(Ax, Reference, YLabelText, TitleText);
legend(Ax, "Location", "best");
end


function DecorateSequenceAxes(Ax, Reference, YLabelText, TitleText)
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
for k = 2:numel(Reference.FlightStart_h)
    xline(Ax, Reference.FlightStart_h(k), ":", sprintf("F%d", k), ...
        "HandleVisibility", "off", "LabelVerticalAlignment", "bottom");
end
grid(Ax, "on"); box(Ax, "on");
ylabel(Ax, YLabelText); title(Ax, TitleText);
StylePaperAxes(Ax);
end


function StylePaperAxes(Ax)
set(Ax, "Color", "w", "XColor", "k", "YColor", "k", ...
    "GridColor", [0.72 0.72 0.72], ...
    "MinorGridColor", [0.85 0.85 0.85]);
Ax.Title.Color = "k";
Ax.XLabel.Color = "k";
Ax.YLabel.Color = "k";
Leg = Ax.Legend;
if ~isempty(Leg)
    set(Leg, "Color", "w", "TextColor", "k");
end
grid(Ax, "on"); box(Ax, "on");
end


function T = BuildTimeline(MissionResults, Sequence, CaseName)
nFlight = height(Sequence);
T = EmptyTimeline;
TimeOffset_s = 0;
DistanceOffset_nmi = 0;
FuelOffset_kg = 0;
T.FlightStart_h = zeros(nFlight, 1);
T.GroundStart_h = [];
T.GroundEnd_h = [];
for k = 1:nFlight
    R = MissionResults(k).(CaseName);
    H = R.MissionHistory.SI;
    Last = R.MainMissionEndIndex;
    LocalTime_s = H.Performance.Time(1:Last);
    LocalTime_s = LocalTime_s - LocalTime_s(1);
    Time_h = (TimeOffset_s + LocalTime_s) / 3600;
    T.FlightStart_h(k) = Time_h(1);
    LocalDistance_nmi = H.Performance.Dist(1:Last) / 1852;
    Fuel = FuelOffset_kg + H.Weight.Fburn(1:Last);
    PReq = H.Power.Preq(1:Last, end) / 1e6;
    MDotFuel = sum(H.Propulsion.MDotFuel(1:Last, :), 2);
    nSrc = numel(R.PropArch.SrcType);
    iEM = find(R.PropArch.TrnType == 0);
    TrueLamUps = GetTrueLamUps(R, H, Last, nSrc);
    if isempty(iEM)
        MotorUtilization = nan(Last, 1);
    else
        MotorUtilization = mean(TrueLamUps(:, iEM), 2, "omitnan");
    end
    T.Time_h = [T.Time_h; Time_h(:); NaN];
    T.Altitude_ft = [T.Altitude_ft; ...
        H.Performance.Alt(1:Last) / 0.3048; NaN];
    T.Speed_kts = [T.Speed_kts; ...
        H.Performance.TAS(1:Last) * 1.943844; NaN];
    T.Distance_nmi = [T.Distance_nmi; ...
        DistanceOffset_nmi + LocalDistance_nmi(:); NaN];
    T.Preq_MW = [T.Preq_MW; PReq(:); NaN];
    T.MDotFuel_kgs = [T.MDotFuel_kgs; MDotFuel(:); NaN];
    T.MotorUtilization = [T.MotorUtilization; ...
        MotorUtilization(:); NaN];
    if k == 1
        T.FuelTime_h = Time_h(:);
        T.CumulativeFuel_kg = Fuel(:);
    else
        T.FuelTime_h = [T.FuelTime_h; Time_h(:)];
        T.CumulativeFuel_kg = [T.CumulativeFuel_kg; Fuel(:)];
    end
    FuelOffset_kg = Fuel(end);
    DistanceOffset_nmi = DistanceOffset_nmi + LocalDistance_nmi(end);
    TimeOffset_s = TimeOffset_s + LocalTime_s(end);
    if k < nFlight
        Ground_s = Sequence.GROUND_TIME(k + 1) * 60;
        T.GroundStart_h(end + 1, 1) = TimeOffset_s / 3600;
        T.GroundEnd_h(end + 1, 1) = ...
            (TimeOffset_s + Ground_s) / 3600;
        T.FuelTime_h = [T.FuelTime_h; TimeOffset_s/3600; ...
            (TimeOffset_s + Ground_s)/3600];
        T.CumulativeFuel_kg = [T.CumulativeFuel_kg; ...
            FuelOffset_kg; FuelOffset_kg];
        TimeOffset_s = TimeOffset_s + Ground_s;
    end
end
end


function T = EmptyTimeline
Fields = ["Time_h","Altitude_ft","Speed_kts","Distance_nmi", ...
    "Preq_MW","MDotFuel_kgs","MotorUtilization", ...
    "FuelTime_h","CumulativeFuel_kg"];
for Field = Fields, T.(Field) = []; end
T.FlightStart_h = [];
T.GroundStart_h = [];
T.GroundEnd_h = [];
end


function TrueLamUps = GetTrueLamUps(R, H, Last, nSrc)
if isfield(R, "TrueLamUps")
    AllValues = R.TrueLamUps;
elseif isfield(R, "LamUpsFullRatedUtilization")
    AllValues = R.LamUpsFullRatedUtilization;
else
    Pout = H.Power.Pout(1:Last, :);
    Pav = H.Power.Pav(1:Last, :);
    AllValues = zeros(size(Pout));
    Valid = isfinite(Pout) & isfinite(Pav) & abs(Pav) > 1e-9;
    AllValues(Valid) = Pout(Valid) ./ Pav(Valid);
    nTrn = numel(R.PropArch.TrnType);
    Columns = nSrc + (1:nTrn);
    AllValues(:, Columns) = AllValues(:, Columns) .* ...
        R.LamUpsCommand(1:Last, :);
    AllValues = min(max(AllValues, 0), 1);
end
TrueLamUps = AllValues(1:Last, ...
    nSrc + (1:numel(R.PropArch.TrnType)));
end


function T = BuildSOCTimeline(MissionResults, ChargeHistories, ...
        Sequence, CaseName)
nFlight = height(Sequence);
T.Time_h = [];
T.SOC_pct = [];
Offset_s = 0;
for k = 1:nFlight
    R = MissionResults(k).(CaseName);
    H = R.MissionHistory.SI;
    Last = R.MainMissionEndIndex;
    Batt = find(R.PropArch.SrcType == 0, 1);
    FlightTime_s = H.Performance.Time(1:Last);
    FlightTime_s = FlightTime_s - FlightTime_s(1);
    T.Time_h = [T.Time_h; (Offset_s + FlightTime_s(:))/3600];
    T.SOC_pct = [T.SOC_pct; H.Power.SOC(1:Last, Batt)];
    Offset_s = Offset_s + FlightTime_s(end);
    if k < nFlight
        C = GetChargeHistory(ChargeHistories, CaseName, k);
        if isfield(C, "Time_s") && isfield(C, "SOC") && ...
                ~isempty(C.Time_s)
            T.Time_h = [T.Time_h; ...
                (Offset_s + C.Time_s(:))/3600];
            T.SOC_pct = [T.SOC_pct; C.SOC(:)];
        end
        Ground_s = Sequence.GROUND_TIME(k + 1) * 60;
        Offset_s = Offset_s + Ground_s;
        if isfield(C, "SOCEnd")
            T.Time_h = [T.Time_h; Offset_s/3600];
            T.SOC_pct = [T.SOC_pct; C.SOCEnd];
        end
    end
end
end


function C = GetChargeHistory(ChargeHistories, CaseName, k)
if isscalar(ChargeHistories) && iscell(ChargeHistories.(CaseName))
    C = ChargeHistories.(CaseName){k};
else
    C = ChargeHistories(k).(CaseName);
end
end


function H = PlotThinned(Ax, X, Y, varargin)
MaxPoints = 2500;
n = numel(X);
if n > MaxPoints
    Keep = unique([1; n; round(linspace(1, n, MaxPoints))'; ...
        find(~isfinite(X) | ~isfinite(Y))]);
    X = X(Keep);
    Y = Y(Keep);
end
H = plot(Ax, X, Y, varargin{:});
end


function AddGroundRegions(Ax, Starts, Ends)
for k = 1:numel(Starts)
    xregion(Ax, Starts(k), Ends(k), ...
        "FaceColor", [0.82 0.82 0.82], "FaceAlpha", 0.18, ...
        "EdgeColor", [0.55 0.55 0.55], "HandleVisibility", "off");
end
end


function WriteTable(T, Directory, Name)
writetable(T, fullfile(Directory, Name));
end


function T = BuildSequenceStatus(Expected, Files)
Completed = ismember(Expected, Files.Sequence);
Status = repmat("missing", numel(Expected), 1);
Status(Completed) = "complete";
CheckpointFile = strings(numel(Expected), 1);
for k = find(Completed)'
    CheckpointFile(k) = Files.File(Files.Sequence == Expected(k));
end
T = table(Expected, Status, CheckpointFile, ...
    'VariableNames', {'Sequence','Status','CheckpointFile'});
end


function T = BuildDefinitionsTable(Representative)
Item = [ ...
    "Mission length"; "Ground time"; "Variation"; ...
    "Normalized fuel burn"; "Fuel saving vs conventional"; ...
    "Power-management optimization benefit"; "Final-SOC parity"; ...
    "Charging dependence"; "Optimizer convergence"; ...
    "Battery 80% SOH setting"; "Representative sequence"];
Definition = [ ...
    "Flight distance in nautical miles; total daily sequence distance is also reported."; ...
    "Only between-flight stops are included; the first-flight placeholder is excluded."; ...
    "Sample standard deviation and sample variance, with N, standard error, and a 95% confidence interval."; ...
    "Each sequence and strategy is divided by the conventional fuel burn for the same sequence, so conventional equals 1."; ...
    "Paired conventional fuel minus HEA fuel, reported in kilograms and percent."; ...
    "Additional saving is unoptimized-HEA fuel minus optimized fuel, divided by the absolute unoptimized HEA saving versus conventional. Relative fuel error is its negative, so -5% means 5% additional saving relative to that baseline."; ...
    "Final HEA SOC values and paired differences are reported to show whether fuel comparisons end at comparable battery states."; ...
    "Correlation and linear R-squared quantify whether optimization benefit varies with ground time, available/actual charge time, SOC added, post-charge SOC, or full recharge frequency."; ...
    "Exit flag greater than zero is counted as converged. Feasibility is reported separately because an iteration-limit result can remain feasible."; ...
    "The run represents an aged battery at 80% state of health: effective cell capacity is 80% of nominal, and the charging model applies a 0.60 C age limit and 1.30 resistance multiplier before temperature/power limits. It is not an 80% SOC limit and no degradation is accumulated."; ...
    "Sequence " + string(Representative) + " was selected for clear joint SOC preservation and joint fuel saving relative to individual optimization."];
T = table(Item, Definition);
end
