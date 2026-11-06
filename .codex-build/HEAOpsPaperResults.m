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
    "all-sequences-v6-literature-calibrated-fixed-climb-kw", ...
    @(x) ischar(x) || isstring(x));
P.addParameter("OutputDirectory", "", ...
    @(x) ischar(x) || isstring(x));
P.addParameter("RepresentativeSequence", [], ...
    @(x) isempty(x) || (isnumeric(x) && isscalar(x) && x >= 1));
P.addParameter("RandomSequenceCount", 4, ...
    @(x) isnumeric(x) && isscalar(x) && x >= 0 && x == fix(x));
P.addParameter("RandomSeed", 20261105, ...
    @(x) isnumeric(x) && isscalar(x) && isfinite(x));
P.addParameter("ConvergenceSequenceCount", 4, ...
    @(x) isnumeric(x) && isscalar(x) && x >= 0 && x == fix(x));
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
[SequenceSummary, FlightResults, ChargeResults, OptimizerDiagnostics, ...
    OptimizerTrace] = ...
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
OptimizationBenefit = BuildOptimizationBenefitAnalyses(Files);
[OutlierDiagnostics, JointAudit] = BuildOutlierDiagnostics( ...
    SensitivityData, OptimizerDiagnostics);

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
WriteTable(OutlierDiagnostics, OutputDirectory, ...
    "Outlier_Sequence_Diagnostics.csv");
WriteTable(JointAudit, OutputDirectory, ...
    "Joint_Worse_Than_Individual_Audit.csv");
WriteTable(AdditionalMetrics, OutputDirectory, ...
    "Additional_Paper_Metrics.csv");
WriteTable(Discovery, OutputDirectory, "Checkpoint_Discovery.csv");
WriteTable(OptimizationBenefit.PhaseFuelByFlight, OutputDirectory, ...
    "Phase_Fuel_Decomposition_By_Flight.csv");
WriteTable(OptimizationBenefit.PhaseFuelSummary, OutputDirectory, ...
    "Phase_Fuel_Decomposition_Summary.csv");
WriteTable(OptimizationBenefit.ClimbContributionBySequence, ...
    OutputDirectory, "Climb_Optimization_Contribution_By_Sequence.csv");
WriteTable(OptimizationBenefit.ClimbContributionSummary, ...
    OutputDirectory, "Climb_Optimization_Contribution_Summary.csv");
WriteTable(OptimizationBenefit.ElectricAssistBySequence, ...
    OutputDirectory, "Electric_Assist_Effectiveness_By_Sequence.csv");
WriteTable(OptimizationBenefit.ElectricAssistPhaseSummary, ...
    OutputDirectory, "Electric_Assist_Phase_Allocation.csv");
WriteTable(OptimizationBenefit.SOCNeutralBySequence, OutputDirectory, ...
    "SOC_Neutral_Optimization_Benefit_By_Sequence.csv");
WriteTable(OptimizationBenefit.SOCNeutralSummary, OutputDirectory, ...
    "SOC_Neutral_Optimization_Benefit_Summary.csv");
WriteTable(OptimizationBenefit.AuthorityBySequencePhase, ...
    OutputDirectory, "Optimization_Authority_By_Sequence_And_Phase.csv");
WriteTable(OptimizationBenefit.AuthoritySummary, OutputDirectory, ...
    "Optimization_Authority_Summary.csv");

MakeFuelDistributionPlot(FuelPerSequence, SensitivityData, OutputDirectory, ...
    logical(Opt.FigureVisible));
MakeSensitivityPlot(SensitivityData, OutputDirectory, ...
    logical(Opt.FigureVisible));
MakeJointIndividualComparisonPlot(FuelPerSequence, OutputDirectory, ...
    logical(Opt.FigureVisible));
MakeOptimizationBenefitPlots(OptimizationBenefit, OutputDirectory, ...
    logical(Opt.FigureVisible));
[ConvergenceSequences, ConvergenceSelection] = ...
    MakeOptimizerConvergencePlot(OptimizerTrace, OutputDirectory, ...
    logical(Opt.FigureVisible), Opt.ConvergenceSequenceCount, ...
    Opt.RandomSeed + 1);
WriteTable(ConvergenceSelection, OutputDirectory, ...
    "Optimizer_Convergence_Sequence_Selection.csv");

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

[RandomSequences, RandomSelection] = SelectRandomSequences( ...
    Files.Sequence, Opt.RandomSequenceCount, Opt.RandomSeed);
WriteTable(RandomSelection, OutputDirectory, ...
    "Random_Sequence_Selection.csv");
for iRandom = 1:numel(RandomSequences)
    RandomIndex = RandomSequences(iRandom);
    RandomFile = Files.File(Files.Sequence == RandomIndex);
    R = load(char(RandomFile(1)), "Sequence", "MissionResults", ...
        "ChargeHistories", "FlightResults", "ChargeResults", ...
        "SequenceSummary");
    MakeRepresentativeEightPanel(R, RandomIndex, OutputDirectory, ...
        logical(Opt.FigureVisible), "Random");
    WriteTable(R.Sequence, OutputDirectory, sprintf( ...
        "Random_Sequence_%04d_Flight_Schedule.csv", RandomIndex));
    WriteTable(R.FlightResults, OutputDirectory, sprintf( ...
        "Random_Sequence_%04d_FlightResults.csv", RandomIndex));
    WriteTable(R.ChargeResults, OutputDirectory, sprintf( ...
        "Random_Sequence_%04d_ChargeResults.csv", RandomIndex));
end

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
    "OptimizerTrace", OptimizerTrace, ...
    "SensitivitySummary", SensitivitySummary, ...
    "AdditionalMetrics", AdditionalMetrics, ...
    "OptimizationBenefit", OptimizationBenefit, ...
    "RepresentativeSequence", Representative, ...
    "RandomSequences", RandomSequences, ...
    "ConvergenceSequences", ConvergenceSequences, ...
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


function [Summary, Flights, Charges, OptimizerDiagnostics, OptimizerTrace] = ...
        LoadCheckpointTables(Files)
n = height(Files);
SummaryCell = cell(n, 1);
FlightCell = cell(n, 1);
ChargeCell = cell(n, 1);
OptimizerCell = cell(n, 1);
TraceCell = cell(n, 1);
for k = 1:n
    D = load(char(Files.File(k)), "SequenceSummary", ...
        "FlightResults", "ChargeResults", "OptimizerResults", ...
        "RunMetadata");
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
        TraceCell{k} = BuildOptimizerTraceRows( ...
            Index, D.OptimizerResults, D.RunMetadata);
    else
        OptimizerCell{k} = EmptyOptimizerDiagnosticRows;
        TraceCell{k} = EmptyOptimizerTraceRows;
    end
    if mod(k, 25) == 0 || k == n
        fprintf("  loaded %d/%d checkpoints\n", k, n);
    end
end
Summary = vertcat(SummaryCell{:});
Flights = vertcat(FlightCell{:});
Charges = vertcat(ChargeCell{:});
OptimizerDiagnostics = vertcat(OptimizerCell{:});
OptimizerTrace = vertcat(TraceCell{:});
Summary = sortrows(Summary, "Sequence");
Flights = sortrows(Flights, {'Sequence','CaseName','Flight'});
Charges = sortrows(Charges, {'Sequence','CaseName','AfterFlight'});
OptimizerDiagnostics = sortrows(OptimizerDiagnostics, ...
    {'Sequence','Strategy'});
if ~isempty(OptimizerTrace)
    OptimizerTrace = sortrows(OptimizerTrace, ...
        {'Sequence','Strategy','Flight','Iteration'});
end
end


function T = BuildOptimizerDiagnosticRows(Index, Summary, O)
Rows = cell(2, 1);
JointExit = double(O.JointExitFlag(:));
JointOutput = O.JointOutput;
Rows{1} = OptimizerDiagnosticRow(Index, "Joint optimization", ...
    SummaryLogicalValue(Summary, "JointFeasible", JointExit > 0), ...
    JointExit, {JointOutput}, ...
    Summary.JointOptimizerTime_min(1));

IndividualExit = double(O.IndividualExitFlag(:));
IndividualOutput = O.IndividualOutput;
if ~iscell(IndividualOutput), IndividualOutput = {IndividualOutput}; end
Rows{2} = OptimizerDiagnosticRow(Index, "Individual optimization", ...
    SummaryLogicalValue(Summary, "IndividualFeasible", ...
    all(IndividualExit > 0)), IndividualExit, ...
    IndividualOutput, Summary.IndividualOptimizerTime_min(1));
T = vertcat(Rows{:});
end


function Value = SummaryLogicalValue(Summary, Name, DefaultValue)
if ismember(Name, string(Summary.Properties.VariableNames))
    Values = Summary.(Name);
    Value = logical(Values(1));
else
    Value = logical(DefaultValue);
end
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


function T = BuildOptimizerTraceRows(Index, O, RunMetadata)
Tolerance = 5e-4;
if isstruct(RunMetadata) && isfield(RunMetadata, "OptimalityTolerance") && ...
        isfinite(RunMetadata.OptimalityTolerance)
    Tolerance = double(RunMetadata.OptimalityTolerance);
end
Rows = cell(0, 1);
if isfield(O, "JointOutput")
    Rows{end + 1, 1} = LabelOptimizerTrace( ...
        ExtractOptimizerTrace(O.JointOutput), Index, "Joint", 0, ...
        Tolerance); %#ok<AGROW>
end
if isfield(O, "IndividualOutput")
    Individual = O.IndividualOutput;
    if ~iscell(Individual), Individual = {Individual}; end
    for k = 1:numel(Individual)
        Rows{end + 1, 1} = LabelOptimizerTrace( ...
            ExtractOptimizerTrace(Individual{k}), Index, "Individual", ...
            k, Tolerance); %#ok<AGROW>
    end
end
if isempty(Rows)
    T = EmptyOptimizerTraceRows;
else
    HasRows = ~cellfun(@isempty, Rows);
    if any(HasRows)
        T = vertcat(Rows{HasRows});
    else
        T = EmptyOptimizerTraceRows;
    end
end
end


function T = ExtractOptimizerTrace(Output)
T = table;
if ~isstruct(Output) || ~isfield(Output, "IterationHistory") || ...
        ~istable(Output.IterationHistory)
    return;
end
Source = Output.IterationHistory;
Required = ["Iteration","FunctionCount","ObjectiveReduction_pct", ...
    "ConstraintViolation","FirstOrderOptimality","StepSize","Elapsed_s"];
for Name = Required
    if ~ismember(Name, string(Source.Properties.VariableNames))
        Source.(Name) = nan(height(Source), 1);
    end
end
T = Source(:, cellstr(Required));
T = T(isfinite(T.Iteration) & T.Iteration >= 0, :);
end


function T = LabelOptimizerTrace(T, Sequence, Strategy, Flight, Tolerance)
if isempty(T), return; end
T.Sequence = repmat(Sequence, height(T), 1);
T.Strategy = repmat(string(Strategy), height(T), 1);
T.Flight = repmat(Flight, height(T), 1);
T.OptimalityTolerance = repmat(Tolerance, height(T), 1);
T = movevars(T, ["Sequence","Strategy","Flight", ...
    "OptimalityTolerance"], "Before", 1);
end


function T = EmptyOptimizerTraceRows
T = table('Size', [0 11], 'VariableTypes', ...
    {'double','string','double','double','double','double','double', ...
    'double','double','double','double'}, ...
    'VariableNames', {'Sequence','Strategy','Flight', ...
    'OptimalityTolerance','Iteration','FunctionCount', ...
    'ObjectiveReduction_pct','ConstraintViolation', ...
    'FirstOrderOptimality','StepSize','Elapsed_s'});
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
DisplayCases = ["Conventional", ...
    "Fixed constant-kW climb HEA (30% motor-rating target)", ...
    "Individual optimized","Joint optimized"];
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
    Rows{k} = table(DisplayCases(k), FS.N, FS.Mean, FS.StdDev, FS.Variance, ...
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
    if ismember("Feasible", string(F.Properties.VariableNames))
        Rows{end + 1} = AdditionalRow(CaseName, ...
            "Feasible flight indicator", "fraction", ...
            double(F.Feasible)); %#ok<AGROW>
    end
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
    SummarizeVector("Fixed climb assist final SOC", "%", ...
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
JointFuelSavingMinusIndividual_kg = ...
    S.IndividualFuelBurn_kg - S.JointFuelBurn_kg;
JointMinusIndividualSaving_pctPoints = ...
    JointFuelSaving_pct - IndividualFuelSaving_pct;
IndividualOptimizationBenefit_pct = 100 * ...
    (Unoptimized - S.IndividualFuelBurn_kg) ./ Unoptimized;
JointOptimizationBenefit_pct = 100 * ...
    (Unoptimized - S.JointFuelBurn_kg) ./ Unoptimized;
IndividualAdditionalSaving_pctPointsOfConventional = 100 * ...
    (Unoptimized - S.IndividualFuelBurn_kg) ./ Conv;
JointAdditionalSaving_pctPointsOfConventional = 100 * ...
    (Unoptimized - S.JointFuelBurn_kg) ./ Conv;
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
    JointFuelSaving_pct, JointFuelSavingMinusIndividual_kg, ...
    JointMinusIndividualSaving_pctPoints, ...
    IndividualOptimizationBenefit_pct, ...
    JointOptimizationBenefit_pct, JointAdditionalBenefitVsIndividual_pct, ...
    IndividualAdditionalSaving_pctPointsOfConventional, ...
    JointAdditionalSaving_pctPointsOfConventional, ...
    BaselineFuelSaving_kg, ...
    IndividualAdditionalSavingsRelativeToBaseline_pct, ...
    JointAdditionalSavingsRelativeToBaseline_pct, ...
    IndividualRelativeFuelError_pct, JointRelativeFuelError_pct, ...
    'VariableNames', {'Sequence','SequenceDistance_nmi','FlightsPerSequence', ...
    'TotalGroundTime_min','MeanGroundTime_min', ...
    'UnoptimizedFuelSaving_pct','IndividualFuelSaving_pct', ...
    'JointFuelSaving_pct','JointFuelSavingMinusIndividual_kg', ...
    'JointMinusIndividualSaving_pctPoints', ...
    'IndividualOptimizationBenefit_pct', ...
    'JointOptimizationBenefit_pct','JointAdditionalBenefitVsIndividual_pct', ...
    'IndividualAdditionalSaving_pctPointsOfConventional', ...
    'JointAdditionalSaving_pctPointsOfConventional', ...
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

OutcomeLabels = ["Individual optimization saving vs conventional", ...
    "Joint optimization saving vs conventional", ...
    "Joint minus individual saving"];
Outcomes = ["IndividualFuelSaving_pct", "JointFuelSaving_pct", ...
    "JointMinusIndividualSaving_pctPoints"];
ChargePrefixes = ["Individual","Joint","Joint"];
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


function [Outliers, JointAudit] = BuildOutlierDiagnostics(T, D)
MetricNames = ["FixedClimbAssistFuelSaving_pct", ...
    "IndividualFuelSaving_pct", "JointFuelSaving_pct", ...
    "IndividualAdditionalSaving_pctPointsOfConventional", ...
    "JointAdditionalSaving_pctPointsOfConventional", ...
    "JointMinusIndividualSaving_pctPoints"];
Variables = ["UnoptimizedFuelSaving_pct", ...
    "IndividualFuelSaving_pct", "JointFuelSaving_pct", ...
    "IndividualAdditionalSaving_pctPointsOfConventional", ...
    "JointAdditionalSaving_pctPointsOfConventional", ...
    "JointMinusIndividualSaving_pctPoints"];
Rows = cell(0, 1);
for k = 1:numel(Variables)
    Values = T.(Variables(k));
    Finite = Values(isfinite(Values));
    Q = prctile(Finite, [25 75]);
    Lower = Q(1) - 1.5 * (Q(2) - Q(1));
    Upper = Q(2) + 1.5 * (Q(2) - Q(1));
    Flag = isfinite(Values) & (Values < Lower | Values > Upper);
    Indices = find(Flag);
    for i = Indices(:)'
        Direction = "low";
        if Values(i) > Upper, Direction = "high"; end
        Rows{end + 1, 1} = table(T.Sequence(i), MetricNames(k), ...
            Values(i), Lower, Upper, Direction, ...
            T.SequenceDistance_nmi(i), T.FlightsPerSequence(i), ...
            T.MeanGroundTime_min(i), ...
            'VariableNames', {'Sequence','Metric','Value','LowerTukeyFence', ...
            'UpperTukeyFence','Direction','SequenceDistance_nmi', ...
            'FlightsPerSequence','MeanGroundTime_min'}); %#ok<AGROW>
    end
end
if isempty(Rows)
    Outliers = table;
else
    Outliers = vertcat(Rows{:});
    Outliers = sortrows(Outliers, ["Sequence","Metric"]);
end

% A joint optimizer should normally match or improve the independently
% optimized sequence. Preserve and flag every reversal larger than a 1-gram
% numerical tolerance; no individual or fixed-baseline fallback is applied.
Mask = T.JointFuelSavingMinusIndividual_kg < -1.0e-3;
JointAudit = T(Mask, {'Sequence','SequenceDistance_nmi', ...
    'FlightsPerSequence','MeanGroundTime_min', ...
    'IndividualFuelSaving_pct','JointFuelSaving_pct', ...
    'JointFuelSavingMinusIndividual_kg', ...
    'JointMinusIndividualSaving_pctPoints'});
n = height(JointAudit);
JointAudit.IndividualIterations = nan(n, 1);
JointAudit.JointIterations = nan(n, 1);
JointAudit.IndividualExitFlag = nan(n, 1);
JointAudit.JointExitFlag = nan(n, 1);
JointAudit.IndividualFeasible = false(n, 1);
JointAudit.JointFeasible = false(n, 1);
for i = 1:n
    Seq = JointAudit.Sequence(i);
    Individual = D(D.Sequence == Seq & contains(string(D.Strategy), ...
        "Individual", "IgnoreCase", true), :);
    Joint = D(D.Sequence == Seq & contains(string(D.Strategy), ...
        "Joint", "IgnoreCase", true), :);
    if ~isempty(Individual)
        JointAudit.IndividualIterations(i) = Individual.TotalIterations(1);
        JointAudit.IndividualExitFlag(i) = Individual.MinimumExitFlag(1);
        JointAudit.IndividualFeasible(i) = logical(Individual.Feasible(1));
    end
    if ~isempty(Joint)
        JointAudit.JointIterations(i) = Joint.TotalIterations(1);
        JointAudit.JointExitFlag(i) = Joint.MinimumExitFlag(1);
        JointAudit.JointFeasible(i) = logical(Joint.Feasible(1));
    end
end
JointAudit.AuditReason = repmat( ...
    "Joint fuel burn exceeded individual by more than 0.001 kg; raw joint result retained", ...
    n, 1);
end


function MakeFuelDistributionPlot(T, Sensitivity, OutDir, IsVisible)
Cases = ["Unoptimized","Individual","Joint"];
Labels = ["Fixed constant-kW climb HEA (30% motor-rating target)", ...
    "Individual optimized","Joint optimized"];
Colors = [0.4660 0.6740 0.1880; ...
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
    scatter(Ax, repmat(k, size(Y)), Y, 18, Colors(k, :), "filled", ...
        "MarkerFaceAlpha", 0.42, "MarkerEdgeAlpha", 0.25, ...
        "DisplayName", Labels(k));
    M = mean(Y, "omitnan"); SD = std(Y, 0, "omitnan");
    errorbar(Ax, k, M, SD, "k", "LineStyle", "none", ...
        "LineWidth", 1.5, "CapSize", 10, "HandleVisibility", "off");
    plot(Ax, [k-0.15 k+0.15], [M M], "k-", "LineWidth", 2, ...
        "HandleVisibility", "off");
end
set(Ax, "XTick", 1:3, "XTickLabel", Labels);
xlim(Ax, [0.5 3.5]);
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
xlabel(Ax, "Fuel saving relative to conventional (%)");
ylabel(Ax, "Empirical cumulative probability");
title(Ax, "Cumulative distribution (fraction at or below x)");
Leg = legend(Ax, "Location", "best");
set(Leg, "Color", "w", "TextColor", "k");
StylePaperAxes(Ax);
title(L, "Sequence-level percent fuel saving relative to paired conventional operation");
L.Title.Color = "k";

exportgraphics(Fig, fullfile(OutDir, ...
    "Fuel_Savings_Vs_Conventional_Distribution.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);

% Alternative view: horizontal position within each case explicitly encodes
% sequence distance instead of arbitrary display jitter.
[Found, Location] = ismember(T.Sequence, Sensitivity.Sequence);
Distance = nan(height(T), 1);
Distance(Found) = Sensitivity.SequenceDistance_nmi(Location(Found));
FiniteDistance = Distance(isfinite(Distance));
if isempty(FiniteDistance), return; end
Distance01 = (Distance - min(FiniteDistance)) ./ ...
    max(max(FiniteDistance) - min(FiniteDistance), eps);
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [50 50 1200 720]);
Ax = axes(Fig); hold(Ax, "on");
for k = 1:numel(Cases)
    Y = T.(Cases(k) + "ReductionVsConventional_pct");
    X = k + 0.28 * (2 * Distance01 - 1);
    scatter(Ax, X, Y, 24, Distance, "filled", ...
        "MarkerFaceAlpha", 0.55, "MarkerEdgeAlpha", 0.25);
end
set(Ax, "XTick", 1:3, "XTickLabel", Labels);
xlim(Ax, [0.55 3.45]);
ylabel(Ax, "Fuel saving relative to conventional (%)");
title(Ax, ["Distribution with distance-encoded width"; ...
    "left within each case = shortest sequence; right = longest sequence"]);
C = colorbar(Ax); C.Label.String = "Total sequence distance (nmi)";
StylePaperAxes(Ax);
exportgraphics(Fig, fullfile(OutDir, ...
    "Fuel_Savings_Distribution_Distance_Width.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function MakeSensitivityPlot(T, OutDir, IsVisible)
Cases = ["Unoptimized","Individual","Joint"];
Labels = ["Fixed constant-kW climb HEA (30% motor-rating target)","Individual optimized", ...
    "Joint optimized"];
Outcomes = ["UnoptimizedFuelSaving_pct", ...
    "IndividualFuelSaving_pct", "JointFuelSaving_pct"];
CommonPredictors = ["SequenceDistance_nmi","FlightsPerSequence", ...
    "MeanGroundTime_min"];
CommonXLabels = ["Sequence distance (nmi)","Flights per sequence", ...
    "Mean between-flight ground time (min)"];
Colors = [0.4660 0.6740 0.1880; 0.8500 0.3250 0.0980; ...
    0.0000 0.4470 0.7410];
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [20 20 1800 1450]);
L = tiledlayout(Fig, 4, 4, "TileSpacing", "compact", ...
    "Padding", "compact");
XLabels = [CommonXLabels, "Mean available charging time (min)"];
for iCase = 1:3
    Predictors = [CommonPredictors, Cases(iCase) + ...
        "MeanAvailableChargeTime_min"];
    for iPredictor = 1:numel(Predictors)
        Ax = nexttile(L, (iCase - 1) * 4 + iPredictor); hold(Ax, "on");
        Y = T.(Outcomes(iCase));
        X = T.(Predictors(iPredictor));
        Valid = isfinite(X) & isfinite(Y);
        scatter(Ax, X(Valid), Y(Valid), 16, Colors(iCase, :), ...
            "filled", "MarkerFaceAlpha", 0.45, ...
            "MarkerEdgeAlpha", 0.25, "DisplayName", Labels(iCase));
        Fit = SimpleLinearSensitivity(X, Y);
        if isfinite(Fit.Slope)
            XLine = linspace(min(X(Valid)), max(X(Valid)), 100)';
            plot(Ax, XLine, Fit.Intercept + Fit.Slope * XLine, ...
                "Color", Colors(iCase, :), "LineWidth", 1.7, ...
                "HandleVisibility", "off");
            text(Ax, 0.03, 0.96, sprintf("r=%.2f, R^2=%.2f", ...
                Fit.PearsonR, Fit.RSquared), ...
                "Units", "normalized", "VerticalAlignment", "top", ...
                "Color", Colors(iCase, :), "BackgroundColor", "w");
        end
        xlabel(Ax, XLabels(iPredictor));
        ylabel(Ax, "Saving vs conventional (%)");
        title(Ax, Labels(iCase));
        StylePaperAxes(Ax);
    end
end

% Bottom row overlays all three cases on the same axes and scale.
for iPredictor = 1:4
    Ax = nexttile(L, 12 + iPredictor); hold(Ax, "on");
    for iCase = 1:3
        if iPredictor <= 3
            X = T.(CommonPredictors(iPredictor));
        else
            X = T.(Cases(iCase) + "MeanAvailableChargeTime_min");
        end
        Y = T.(Outcomes(iCase));
        Valid = isfinite(X) & isfinite(Y);
        scatter(Ax, X(Valid), Y(Valid), 15, Colors(iCase, :), ...
            "filled", "MarkerFaceAlpha", 0.30, ...
            "MarkerEdgeAlpha", 0.15, "DisplayName", Labels(iCase));
        Fit = SimpleLinearSensitivity(X, Y);
        if isfinite(Fit.Slope)
            XLine = linspace(min(X(Valid)), max(X(Valid)), 100)';
            plot(Ax, XLine, Fit.Intercept + Fit.Slope * XLine, ...
                "Color", Colors(iCase, :), "LineWidth", 1.5, ...
                "HandleVisibility", "off");
        end
    end
    xlabel(Ax, XLabels(iPredictor));
    ylabel(Ax, "Saving vs conventional (%)");
    title(Ax, "All HEA cases");
    if iPredictor == 1, legend(Ax, "Location", "best"); end
    StylePaperAxes(Ax);
end
title(L, "Total HEA fuel saving relative to conventional operation " + ...
    "(descriptive associations, not causal effects)");
L.Title.Color = "k";
exportgraphics(Fig, fullfile(OutDir, ...
    "Fuel_Savings_Sensitivity_Total_Vs_Conventional.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
MakeAdditionalContributionSensitivityPlot(T, OutDir, IsVisible);
end


function MakeAdditionalContributionSensitivityPlot(T, OutDir, IsVisible)
Cases = ["Individual","Joint"];
Labels = ["Individual additional saving", "Joint additional saving"];
Outcomes = ["IndividualAdditionalSaving_pctPointsOfConventional", ...
    "JointAdditionalSaving_pctPointsOfConventional"];
Predictors = ["SequenceDistance_nmi","FlightsPerSequence", ...
    "MeanGroundTime_min", "MeanAvailableChargeTime_min"];
XLabels = ["Sequence distance (nmi)","Flights per sequence", ...
    "Mean between-flight ground time (min)", ...
    "Mean available charging time (min)"];
Colors = [0.8500 0.3250 0.0980; 0.0000 0.4470 0.7410];
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [30 30 1700 900]);
L = tiledlayout(Fig, 2, 4, "TileSpacing", "compact", ...
    "Padding", "compact");
for iCase = 1:2
    Y = T.(Outcomes(iCase));
    for iPredictor = 1:4
        Ax = nexttile(L); hold(Ax, "on");
        Predictor = Predictors(iPredictor);
        if Predictor == "MeanAvailableChargeTime_min"
            Predictor = Cases(iCase) + Predictor;
        end
        X = T.(Predictor);
        Valid = isfinite(X) & isfinite(Y);
        scatter(Ax, X(Valid), Y(Valid), 16, Colors(iCase, :), ...
            "filled", "MarkerFaceAlpha", 0.5, "MarkerEdgeAlpha", 0.25);
        Fit = SimpleLinearSensitivity(X, Y);
        if isfinite(Fit.Slope)
            XLine = linspace(min(X(Valid)), max(X(Valid)), 100)';
            plot(Ax, XLine, Fit.Intercept + Fit.Slope * XLine, ...
                "Color", Colors(iCase, :), "LineWidth", 1.8);
            text(Ax, 0.03, 0.95, sprintf("r=%.2f, R^2=%.2f", ...
                Fit.PearsonR, Fit.RSquared), "Units", "normalized", ...
                "VerticalAlignment", "top", "Color", [0.15 0.15 0.15], ...
                "BackgroundColor", "w");
        end
        yline(Ax, 0, "k:", "HandleVisibility", "off");
        xlabel(Ax, XLabels(iPredictor));
        ylabel(Ax, "Added saving beyond fixed HEA (% of conventional fuel)");
        title(Ax, Labels(iCase));
        StylePaperAxes(Ax);
    end
end
title(L, "Additional optimization saving beyond the fixed climb-assist HEA " + ...
    "baseline (percentage points of conventional fuel)");
L.Title.Color = "k";
exportgraphics(Fig, fullfile(OutDir, ...
    "Fuel_Savings_Sensitivity_Additional_Optimization.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function MakeJointIndividualComparisonPlot(T, OutDir, IsVisible)
Individual = T.IndividualReductionVsConventional_pct;
Joint = T.JointReductionVsConventional_pct;
Valid = isfinite(Individual) & isfinite(Joint);
Individual = Individual(Valid);
Joint = Joint(Valid);
Difference = Joint - Individual;
Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [60 60 1450 620]);
L = tiledlayout(Fig, 1, 2, "TileSpacing", "compact", ...
    "Padding", "compact");

Ax = nexttile(L); hold(Ax, "on");
scatter(Ax, Individual, Joint, 22, [0.0000 0.4470 0.7410], ...
    "filled", "MarkerFaceAlpha", 0.45, "MarkerEdgeAlpha", 0.25);
Limits = [min([Individual; Joint]), max([Individual; Joint])];
Padding = max(0.1, 0.04 * max(1, diff(Limits)));
Limits = Limits + [-Padding Padding];
plot(Ax, Limits, Limits, "k--", "LineWidth", 1.3);
xlim(Ax, Limits); ylim(Ax, Limits); axis(Ax, "square");
xlabel(Ax, "Individual saving vs conventional (%)");
ylabel(Ax, "Joint saving vs conventional (%)");
title(Ax, "Paired sequence comparison (dashed = equal)");
StylePaperAxes(Ax);

Ax = nexttile(L); hold(Ax, "on");
histogram(Ax, Difference, "BinMethod", "fd", ...
    "FaceColor", [0.0000 0.4470 0.7410], "FaceAlpha", 0.65, ...
    "EdgeColor", "w");
xline(Ax, 0, "k--", "Equal", "LineWidth", 1.2);
xline(Ax, median(Difference, "omitnan"), "-", ...
    sprintf("Median %.3g pp", median(Difference, "omitnan")), ...
    "Color", [0.8500 0.3250 0.0980], "LineWidth", 1.6);
xlabel(Ax, "Joint minus individual saving (percentage points)");
ylabel(Ax, "Number of sequences");
title(Ax, "Distribution of joint advantage");
StylePaperAxes(Ax);

title(L, "Joint versus individual power-management fuel saving");
L.Title.Color = "k";
exportgraphics(Fig, fullfile(OutDir, ...
    "Joint_Vs_Individual_Fuel_Savings.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function [Selected, Selection] = MakeOptimizerConvergencePlot( ...
        Trace, OutDir, IsVisible, Count, Seed)
Selected = zeros(0, 1);
Selection = table('Size', [0 3], ...
    'VariableTypes', {'double','double','double'}, ...
    'VariableNames', {'SelectionOrder','Sequence','RandomSeed'});
if isempty(Trace) || Count == 0
    return;
end
Candidates = unique(Trace.Sequence, "stable");
HasBoth = false(size(Candidates));
for k = 1:numel(Candidates)
    Strategies = unique(Trace.Strategy(Trace.Sequence == Candidates(k)));
    HasBoth(k) = all(ismember(["Joint","Individual"], Strategies));
end
Candidates = Candidates(HasBoth);
[Selected, Selection] = SelectRandomSequences(Candidates, Count, Seed);
if isempty(Selected), return; end

Visibility = "off";
if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", ...
    "Position", [30 30 1650 340 * numel(Selected)]);
L = tiledlayout(Fig, numel(Selected), 2, "TileSpacing", "compact", ...
    "Padding", "compact");
for k = 1:numel(Selected)
    S = Trace(Trace.Sequence == Selected(k), :);
    Ax = nexttile(L); hold(Ax, "on");
    PlotConvergenceMetric(Ax, S, "ObjectiveReduction_pct", false);
    yline(Ax, 0, ":", "HandleVisibility", "off");
    xlabel(Ax, "Optimizer iteration");
    ylabel(Ax, "Objective reduction from start (%)");
    title(Ax, sprintf("Sequence %d: objective history", Selected(k)));
    if k == 1, legend(Ax, "Location", "best"); end
    StylePaperAxes(Ax);

    Ax = nexttile(L); hold(Ax, "on");
    PlotConvergenceMetric(Ax, S, "FirstOrderOptimality", true);
    Tolerance = median(S.OptimalityTolerance, "omitnan");
    if isfinite(Tolerance) && Tolerance > 0
        yline(Ax, Tolerance, "k:", sprintf("Tolerance %.1e", Tolerance), ...
            "LineWidth", 1.2, "HandleVisibility", "off");
    end
    xlabel(Ax, "Optimizer iteration");
    ylabel(Ax, "First-order optimality residual");
    title(Ax, sprintf("Sequence %d: convergence residual", Selected(k)));
    StylePaperAxes(Ax);
end
title(L, "Joint and individual optimizer convergence histories");
L.Title.Color = "k";
exportgraphics(Fig, fullfile(OutDir, ...
    "Optimizer_Convergence_Selected_Sequences.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function PlotConvergenceMetric(Ax, Trace, Metric, UseLogScale)
JointColor = [0.0000 0.4470 0.7410];
IndividualColor = [0.9290 0.6940 0.1250];
LightIndividual = 0.65 * IndividualColor + 0.35;
Joint = Trace(Trace.Strategy == "Joint", :);
Joint = sortrows(Joint, "Iteration");
JointMetric = Joint.(Metric);
Valid = isfinite(Joint.Iteration) & isfinite(JointMetric);
if UseLogScale, Valid = Valid & JointMetric > 0; end
plot(Ax, Joint.Iteration(Valid), JointMetric(Valid), "-", ...
    "Color", JointColor, "LineWidth", 2.0, "DisplayName", "Joint");

Individual = Trace(Trace.Strategy == "Individual", :);
Flights = unique(Individual.Flight, "stable");
for k = 1:numel(Flights)
    F = sortrows(Individual(Individual.Flight == Flights(k), :), ...
        "Iteration");
    FlightMetric = F.(Metric);
    Valid = isfinite(F.Iteration) & isfinite(FlightMetric);
    if UseLogScale, Valid = Valid & FlightMetric > 0; end
    Display = "";
    if k == 1, Display = "Individual flights"; end
    HandleVisibility = "off";
    if strlength(Display) > 0, HandleVisibility = "on"; end
    plot(Ax, F.Iteration(Valid), FlightMetric(Valid), "-", ...
        "Color", LightIndividual, "LineWidth", 0.8, ...
        "HandleVisibility", HandleVisibility, "DisplayName", Display);
end
if ~isempty(Individual)
    [Iterations, MedianValue] = MedianTraceByIteration(Individual, Metric, ...
        UseLogScale);
    plot(Ax, Iterations, MedianValue, "--", "Color", IndividualColor, ...
        "LineWidth", 2.0, "DisplayName", "Individual median");
end
if UseLogScale, set(Ax, "YScale", "log"); end
end


function [Iterations, Values] = MedianTraceByIteration(Trace, Metric, Positive)
Iterations = unique(Trace.Iteration(isfinite(Trace.Iteration)));
Values = nan(size(Iterations));
for k = 1:numel(Iterations)
    AllValues = Trace.(Metric);
    V = AllValues(Trace.Iteration == Iterations(k));
    V = V(isfinite(V));
    if Positive, V = V(V > 0); end
    if ~isempty(V), Values(k) = median(V); end
end
Valid = isfinite(Values);
Iterations = Iterations(Valid);
Values = Values(Valid);
end


function [Selected, Selection] = SelectRandomSequences(Candidates, Count, Seed)
Candidates = unique(double(Candidates(:)), "stable");
Count = min(Count, numel(Candidates));
if Count == 0
    Selected = zeros(0, 1);
else
    Previous = rng;
    Cleanup = onCleanup(@() rng(Previous)); %#ok<NASGU>
    rng(double(Seed), "twister");
    Selected = Candidates(randperm(numel(Candidates), Count));
end
Selection = table((1:numel(Selected))', Selected, ...
    repmat(double(Seed), numel(Selected), 1), ...
    'VariableNames', {'SelectionOrder','Sequence','RandomSeed'});
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


function MakeRepresentativeEightPanel(D, Index, OutDir, IsVisible, PlotRole)
if nargin < 5, PlotRole = "Representative"; end
Cases = ["Conventional","Unoptimized","Individual","Joint"];
PHECases = ["Unoptimized","Individual","Joint"];
Labels = ["Conventional","Fixed constant-kW climb HEA (30% motor-rating target)", ...
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
title(L, sprintf("%s sequence %d: joint optimization " + ...
    "preserves inter-flight SOC and reduces fuel", PlotRole, Index));
L.Title.Color = "k";
BaseName = sprintf("%s_Sequence_%04d_Mission_Comparison", PlotRole, Index);
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


function Analysis = BuildOptimizationBenefitAnalyses(Files)
% Extract phase-resolved results from completed checkpoints without rerunning
% any optimizer. Checkpoints are loaded one at a time to bound memory use.
Rows = cell(height(Files), 1);
for k = 1:height(Files)
    try
        D = load(char(Files.File(k)), "Sequence", "MissionResults");
        Rows{k} = ExtractCheckpointPhaseMetrics( ...
            Files.Sequence(k), D.Sequence, D.MissionResults);
    catch ME
        warning("HEAOpsPaperResults:PhaseAnalysisSkipped", ...
            "Skipped phase analysis for sequence %d: %s", ...
            Files.Sequence(k), ME.message);
        Rows{k} = table;
    end
    if mod(k, 25) == 0 || k == height(Files)
        fprintf("  phase analysis %d/%d checkpoints\n", k, height(Files));
    end
end
HasRows = ~cellfun(@isempty, Rows);
if any(HasRows)
    Phase = vertcat(Rows{HasRows});
else
    Phase = table;
end

PhaseFuel = BuildPhaseFuelComparison(Phase);
PhaseSummary = SummarizePhaseFuel(PhaseFuel);
[Climb, ClimbSummary] = BuildClimbContribution(PhaseFuel);
[Assist, AssistPhase] = BuildElectricAssistAnalysis(Phase, PhaseFuel);
[SOCNeutral, SOCNeutralSummary] = BuildSOCNeutralAnalysis(Phase, PhaseFuel);
[Authority, AuthoritySummary] = BuildAuthorityAnalysis(Phase);

Analysis = struct( ...
    "PhaseFuelByFlight", PhaseFuel, ...
    "PhaseFuelSummary", PhaseSummary, ...
    "ClimbContributionBySequence", Climb, ...
    "ClimbContributionSummary", ClimbSummary, ...
    "ElectricAssistBySequence", Assist, ...
    "ElectricAssistPhaseSummary", AssistPhase, ...
    "SOCNeutralBySequence", SOCNeutral, ...
    "SOCNeutralSummary", SOCNeutralSummary, ...
    "AuthorityBySequencePhase", Authority, ...
    "AuthoritySummary", AuthoritySummary);
end


function T = ExtractCheckpointPhaseMetrics(Index, Sequence, MissionResults)
Cases = ["Conventional","Unoptimized","Individual","Joint"];
Rows = cell(numel(MissionResults) * numel(Cases), 1);
n = 0;
for iFlight = 1:numel(MissionResults)
    for iCase = 1:numel(Cases)
        CaseName = Cases(iCase);
        if ~isfield(MissionResults(iFlight), CaseName), continue; end
        R = MissionResults(iFlight).(CaseName);
        n = n + 1;
        Rows{n} = ExtractFlightPhaseMetrics(Index, iFlight, ...
            CaseName, R);
    end
end
Rows = Rows(1:n);
HasRows = ~cellfun(@isempty, Rows);
if any(HasRows), T = vertcat(Rows{HasRows}); else, T = table; end
end


function T = ExtractFlightPhaseMetrics(Index, Flight, CaseName, R)
H = R.MissionHistory.SI;
Profile = R.MissionProfile;
Last = min(R.MainMissionEndIndex, numel(H.Weight.Fburn));
if Last < 2
    T = table;
    return
end

Time_s = double(H.Performance.Time(1:Last));
Time_s = Time_s - Time_s(1);
Dt_s = [0; max(diff(Time_s(:)), 0)];
Fuel = double(H.Weight.Fburn(1:Last));
FuelIncrement_kg = [Fuel(1); diff(Fuel(:))];
PhaseAtPoint = repmat("Other", Last, 1);
PhaseOrderAtPoint = repmat(90, Last, 1);
SegmentNames = string(Profile.Segs);
if isfield(Profile, "ID")
    MainSegments = find(Profile.ID == 1);
else
    MainSegments = (1:numel(SegmentNames))';
end
for iSeg = MainSegments(:)'
    Beg = max(1, round(Profile.SegBeg(iSeg)));
    Fin = min(Last, round(Profile.SegEnd(iSeg)));
    if Fin < Beg, continue; end
    ThisPhase = CanonicalMissionPhase(SegmentNames(iSeg));
    PhaseAtPoint(Beg:Fin) = ThisPhase;
    PhaseOrderAtPoint(Beg:Fin) = MissionPhaseOrder(ThisPhase);
end

nSrc = numel(R.PropArch.SrcType);
iEM = find(R.PropArch.TrnType == 0);
iBatt = find(R.PropArch.SrcType == 0, 1);
Pout = double(H.Power.Pout(1:Last, :));
Pav = double(H.Power.Pav(1:Last, :));
Preq = double(H.Power.Preq(1:Last, end));

ElectricPower_W = zeros(Last, 1);
MotorUtilization = nan(Last, 1);
if ~isempty(iEM)
    EMColumns = nSrc + iEM;
    ElectricPower_W = sum(max(Pout(:, EMColumns), 0), 2, "omitnan");
    TrueLamUps = GetTrueLamUps(R, H, Last, nSrc);
    MotorUtilization = mean(TrueLamUps(:, iEM), 2, "omitnan");
end
ElectricAssistFraction = ElectricPower_W ./ max(abs(Preq), 1);
ElectricAssistFraction = min(max(ElectricAssistFraction, 0), 1);

BatteryPower_W = nan(Last, 1);
BatteryUtilization = nan(Last, 1);
SOC_pct = nan(Last, 1);
MinimumAllowedSOC_pct = NaN;
NominalBatteryCapacity_kWh = NaN;
if ~isempty(iBatt)
    BatteryPower_W = max(Pout(:, iBatt), 0);
    Valid = isfinite(Pout(:, iBatt)) & isfinite(Pav(:, iBatt)) & ...
        abs(Pav(:, iBatt)) > 1;
    BatteryUtilization(Valid) = max(Pout(Valid, iBatt), 0) ./ ...
        abs(Pav(Valid, iBatt));
    SOC_pct = double(H.Power.SOC(1:Last, iBatt));
    if isfield(R.Battery, "MinSOC")
        MinimumAllowedSOC_pct = double(R.Battery.MinSOC);
    end
    NominalBatteryCapacity_kWh = BatteryCapacity_kWh(R);
end
FiniteFlightSOC = find(isfinite(SOC_pct), 1, "last");
if isempty(FiniteFlightSOC)
    FlightTerminalSOC_pct = NaN;
else
    FlightTerminalSOC_pct = SOC_pct(FiniteFlightSOC);
end

Phases = unique(PhaseAtPoint, "stable");
Rows = cell(numel(Phases), 1);
for k = 1:numel(Phases)
    PhaseName = Phases(k);
    Mask = PhaseAtPoint == PhaseName;
    Duration_s = sum(Dt_s(Mask), "omitnan");
    BatteryEnergy_kWh = sum(BatteryPower_W(Mask) .* Dt_s(Mask), ...
        "omitnan") / 3.6e6;
    ElectricEnergy_kWh = sum(ElectricPower_W(Mask) .* Dt_s(Mask), ...
        "omitnan") / 3.6e6;
    PhaseFuel_kg = sum(FuelIncrement_kg(Mask), "omitnan");
    MeanAssist = WeightedMean(ElectricAssistFraction(Mask), Dt_s(Mask));
    MeanMotor = WeightedMean(MotorUtilization(Mask), Dt_s(Mask));
    MeanBattery = WeightedMean(BatteryUtilization(Mask), Dt_s(Mask));
    MotorLimitFraction = WeightedFraction( ...
        MotorUtilization(Mask) >= 0.99, Dt_s(Mask));
    BatteryLimitFraction = WeightedFraction( ...
        BatteryUtilization(Mask) >= 0.99, Dt_s(Mask));
    PhaseSOC = SOC_pct(Mask);
    FiniteSOC = find(isfinite(PhaseSOC));
    if isempty(FiniteSOC)
        BeginSOC = NaN; EndSOC = NaN; MinimumSOC = NaN;
    else
        BeginSOC = PhaseSOC(FiniteSOC(1));
        EndSOC = PhaseSOC(FiniteSOC(end));
        MinimumSOC = min(PhaseSOC(FiniteSOC));
    end
    MinSOCMargin = MinimumSOC - MinimumAllowedSOC_pct;
    Rows{k} = table(Index, Flight, string(CaseName), PhaseName, ...
        min(PhaseOrderAtPoint(Mask)), Duration_s/60, PhaseFuel_kg, ...
        BatteryEnergy_kWh, ElectricEnergy_kWh, MeanAssist, ...
        max(ElectricAssistFraction(Mask), [], "omitnan"), MeanMotor, ...
        max(MotorUtilization(Mask), [], "omitnan"), MotorLimitFraction, ...
        MeanBattery, max(BatteryUtilization(Mask), [], "omitnan"), ...
        BatteryLimitFraction, BeginSOC, EndSOC, MinimumSOC, ...
        FlightTerminalSOC_pct, MinimumAllowedSOC_pct, MinSOCMargin, ...
        NominalBatteryCapacity_kWh, ...
        'VariableNames', {'Sequence','Flight','CaseName','Phase', ...
        'PhaseOrder','Duration_min','FuelBurn_kg','BatteryEnergy_kWh', ...
        'ElectricAssistEnergy_kWh','MeanElectricAssistFraction', ...
        'PeakElectricAssistFraction','MeanMotorUtilization', ...
        'PeakMotorUtilization','MotorLimitFraction', ...
        'MeanBatteryUtilization','PeakBatteryUtilization', ...
        'BatteryLimitFraction','BeginSOC_pct','EndSOC_pct', ...
        'MinimumSOC_pct','FlightTerminalSOC_pct', ...
        'MinimumAllowedSOC_pct','MinimumSOCMargin_pct', ...
        'NominalBatteryCapacity_kWh'});
end
T = vertcat(Rows{:});
end


function Phase = CanonicalMissionPhase(Name)
Name = lower(strtrim(string(Name)));
if contains(Name, "taxi")
    Phase = "Taxi";
elseif contains(Name, "takeoff") || contains(Name, "take-off")
    Phase = "Takeoff";
elseif contains(Name, "climb") || contains(Name, "accel")
    Phase = "Climb";
elseif contains(Name, "cruise")
    Phase = "Cruise";
elseif contains(Name, "descent") || contains(Name, "approach")
    Phase = "Descent";
elseif contains(Name, "landing") || contains(Name, "land")
    Phase = "Landing";
else
    Phase = "Other";
end
end


function Order = MissionPhaseOrder(Phase)
Names = ["Taxi","Takeoff","Climb","Cruise","Descent","Landing","Other"];
Order = find(Names == string(Phase), 1);
if isempty(Order), Order = 90; end
end


function Capacity = BatteryCapacity_kWh(R)
Capacity = NaN;
RequiredPower = ["ParCells","SerCells"];
RequiredBattery = ["CapCell","NomVolCell"];
if ~all(isfield(R.Power.Battery, cellstr(RequiredPower))) || ...
        ~all(isfield(R.Battery, cellstr(RequiredBattery)))
    return
end
Capacity = double(R.Power.Battery.ParCells) * ...
    double(R.Power.Battery.SerCells) * double(R.Battery.CapCell) * ...
    double(R.Battery.NomVolCell) / 1000;
end


function Value = WeightedMean(X, W)
Valid = isfinite(X) & isfinite(W) & W > 0;
if any(Valid)
    Value = sum(X(Valid) .* W(Valid)) / sum(W(Valid));
else
    Value = mean(X, "omitnan");
end
end


function Value = WeightedFraction(Condition, W)
Valid = isfinite(W) & W > 0;
if any(Valid)
    Value = sum(double(Condition(Valid)) .* W(Valid)) / sum(W(Valid));
else
    Value = NaN;
end
end


function T = BuildPhaseFuelComparison(Phase)
if isempty(Phase), T = table; return; end
Keys = unique(Phase(:, {'Sequence','Flight','Phase','PhaseOrder'}), ...
    "rows", "stable");
Strategies = ["Individual","Joint"];
Rows = cell(height(Keys) * numel(Strategies), 1);
n = 0;
for k = 1:height(Keys)
    Base = Phase.Sequence == Keys.Sequence(k) & ...
        Phase.Flight == Keys.Flight(k) & Phase.Phase == Keys.Phase(k);
    Conventional = Phase(Base & Phase.CaseName == "Conventional", :);
    Unoptimized = Phase(Base & Phase.CaseName == "Unoptimized", :);
    if isempty(Conventional) || isempty(Unoptimized), continue; end
    for iStrategy = 1:numel(Strategies)
        Strategy = Strategies(iStrategy);
        Optimized = Phase(Base & Phase.CaseName == Strategy, :);
        if isempty(Optimized), continue; end
        ConvFuel = Conventional.FuelBurn_kg(1);
        UnoptFuel = Unoptimized.FuelBurn_kg(1);
        OptFuel = Optimized.FuelBurn_kg(1);
        ArchitectureSaving = ConvFuel - UnoptFuel;
        OptimizationSaving = UnoptFuel - OptFuel;
        TotalSaving = ConvFuel - OptFuel;
        n = n + 1;
        Rows{n} = table(Keys.Sequence(k), Keys.Flight(k), ...
            Keys.Phase(k), Keys.PhaseOrder(k), Strategy, ConvFuel, ...
            UnoptFuel, OptFuel, ArchitectureSaving, OptimizationSaving, ...
            TotalSaving, SafePercent(ArchitectureSaving, ConvFuel), ...
            SafePercent(OptimizationSaving, UnoptFuel), ...
            SafePercent(TotalSaving, ConvFuel), ...
            SafePercent(OptimizationSaving, TotalSaving), ...
            'VariableNames', {'Sequence','Flight','Phase','PhaseOrder', ...
            'OptimizationStrategy','ConventionalFuel_kg', ...
            'UnoptimizedHEAFuel_kg','OptimizedHEAFuel_kg', ...
            'ArchitectureFuelSaving_kg','OptimizationFuelSaving_kg', ...
            'TotalOptimizedFuelSavingVsConventional_kg', ...
            'ArchitectureFuelSaving_pctOfConventional', ...
            'OptimizationFuelSaving_pctOfUnoptimizedHEA', ...
            'TotalOptimizedFuelSaving_pctOfConventional', ...
            'OptimizationShareOfTotalSaving_pct'});
    end
end
Rows = Rows(1:n);
if isempty(Rows), T = table; else, T = vertcat(Rows{:}); end
end


function T = SummarizePhaseFuel(Data)
if isempty(Data), T = table; return; end
Strategies = unique(Data.OptimizationStrategy, "stable");
Phases = sortrows(unique(Data(:, {'Phase','PhaseOrder'}), "rows"), ...
    "PhaseOrder");
Rows = cell(numel(Strategies) * height(Phases), 1);
n = 0;
for i = 1:numel(Strategies)
    for j = 1:height(Phases)
        Mask = Data.OptimizationStrategy == Strategies(i) & ...
            Data.Phase == Phases.Phase(j);
        if ~any(Mask), continue; end
        A = ScalarStats(Data.ArchitectureFuelSaving_kg(Mask));
        O = ScalarStats(Data.OptimizationFuelSaving_kg(Mask));
        P = ScalarStats(Data.OptimizationFuelSaving_pctOfUnoptimizedHEA(Mask));
        S = ScalarStats(Data.OptimizationShareOfTotalSaving_pct(Mask));
        n = n + 1;
        Rows{n} = table(Strategies(i), Phases.Phase(j), ...
            Phases.PhaseOrder(j), O.N, A.Mean, A.CI95Low, A.CI95High, ...
            O.Mean, O.CI95Low, O.CI95High, P.Mean, P.CI95Low, ...
            P.CI95High, S.Mean, ...
            'VariableNames', {'OptimizationStrategy','Phase','PhaseOrder', ...
            'NFlights','MeanArchitectureFuelSaving_kg', ...
            'ArchitectureSavingCI95Low_kg','ArchitectureSavingCI95High_kg', ...
            'MeanOptimizationFuelSaving_kg','OptimizationSavingCI95Low_kg', ...
            'OptimizationSavingCI95High_kg', ...
            'MeanOptimizationFuelSaving_pctOfUnoptimizedHEA', ...
            'OptimizationSavingCI95Low_pct', ...
            'OptimizationSavingCI95High_pct', ...
            'MeanOptimizationShareOfTotalSaving_pct'});
    end
end
T = vertcat(Rows{1:n});
end


function [T, Summary] = BuildClimbContribution(Data)
if isempty(Data), T = table; Summary = table; return; end
Keys = unique(Data(:, {'Sequence','OptimizationStrategy'}), "rows");
Rows = cell(height(Keys), 1);
for k = 1:height(Keys)
    Mask = Data.Sequence == Keys.Sequence(k) & ...
        Data.OptimizationStrategy == Keys.OptimizationStrategy(k);
    D = Data(Mask, :);
    IsClimb = D.Phase == "Climb";
    IsHighPower = ismember(D.Phase, ["Takeoff","Climb"]);
    TotalSaving = sum(D.OptimizationFuelSaving_kg, "omitnan");
    ClimbSaving = sum(D.OptimizationFuelSaving_kg(IsClimb), "omitnan");
    HighPowerSaving = sum(D.OptimizationFuelSaving_kg(IsHighPower), "omitnan");
    ClimbUnoptimized = sum(D.UnoptimizedHEAFuel_kg(IsClimb), "omitnan");
    HighPowerUnoptimized = sum(D.UnoptimizedHEAFuel_kg(IsHighPower), "omitnan");
    Rows{k} = table(Keys.Sequence(k), Keys.OptimizationStrategy(k), ...
        ClimbSaving, HighPowerSaving, TotalSaving, ...
        SafePercent(ClimbSaving, ClimbUnoptimized), ...
        SafePercent(HighPowerSaving, HighPowerUnoptimized), ...
        SafePercent(ClimbSaving, TotalSaving), ...
        SafePercent(HighPowerSaving, TotalSaving), ...
        'VariableNames', {'Sequence','OptimizationStrategy', ...
        'ClimbOptimizationFuelSaving_kg', ...
        'TakeoffAndClimbOptimizationFuelSaving_kg', ...
        'TotalOptimizationFuelSaving_kg', ...
        'ClimbOptimizationFuelSaving_pctOfUnoptimizedHEAClimb', ...
        'TakeoffAndClimbOptimizationFuelSaving_pctOfUnoptimizedHEA', ...
        'ClimbShareOfTotalOptimizationSaving_pct', ...
        'TakeoffAndClimbShareOfTotalOptimizationSaving_pct'});
end
T = vertcat(Rows{:});
Summary = SummarizeStrategyMetrics(T, ...
    ["ClimbOptimizationFuelSaving_kg", ...
    "TakeoffAndClimbOptimizationFuelSaving_kg", ...
    "TotalOptimizationFuelSaving_kg", ...
    "ClimbOptimizationFuelSaving_pctOfUnoptimizedHEAClimb", ...
    "ClimbShareOfTotalOptimizationSaving_pct", ...
    "TakeoffAndClimbShareOfTotalOptimizationSaving_pct"]);
end


function [T, PhaseSummary] = BuildElectricAssistAnalysis(Phase, Fuel)
if isempty(Phase), T = table; PhaseSummary = table; return; end
PHE = Phase(Phase.CaseName ~= "Conventional", :);
Groups = unique(PHE(:, {'CaseName','Phase','PhaseOrder'}), "rows");
Groups = sortrows(Groups, {'CaseName','PhaseOrder'});
Rows = cell(height(Groups), 1);
for k = 1:height(Groups)
    Mask = PHE.CaseName == Groups.CaseName(k) & ...
        PHE.Phase == Groups.Phase(k);
    E = ScalarStats(PHE.BatteryEnergy_kWh(Mask));
    A = ScalarStats(100 * PHE.MeanElectricAssistFraction(Mask));
    M = ScalarStats(100 * PHE.MeanMotorUtilization(Mask));
    Rows{k} = table(Groups.CaseName(k), Groups.Phase(k), ...
        Groups.PhaseOrder(k), E.N, E.Mean, E.CI95Low, E.CI95High, ...
        A.Mean, A.CI95Low, A.CI95High, M.Mean, ...
        'VariableNames', {'CaseName','Phase','PhaseOrder','NFlights', ...
        'MeanBatteryEnergy_kWh','BatteryEnergyCI95Low_kWh', ...
        'BatteryEnergyCI95High_kWh','MeanElectricAssist_pct', ...
        'ElectricAssistCI95Low_pct','ElectricAssistCI95High_pct', ...
        'MeanMotorUtilization_pct'});
end
PhaseSummary = vertcat(Rows{:});

Keys = unique(Fuel(:, {'Sequence','OptimizationStrategy'}), "rows");
Rows = cell(height(Keys), 1);
for k = 1:height(Keys)
    Strategy = Keys.OptimizationStrategy(k);
    FMask = Fuel.Sequence == Keys.Sequence(k) & ...
        Fuel.OptimizationStrategy == Strategy;
    UMask = PHE.Sequence == Keys.Sequence(k) & PHE.CaseName == "Unoptimized";
    OMask = PHE.Sequence == Keys.Sequence(k) & PHE.CaseName == Strategy;
    UF = PHE(UMask, :); OF = PHE(OMask, :); FF = Fuel(FMask, :);
    FuelSaved = sum(FF.OptimizationFuelSaving_kg, "omitnan");
    ClimbFuelSaved = sum(FF.OptimizationFuelSaving_kg( ...
        FF.Phase == "Climb"), "omitnan");
    UnoptEnergy = sum(UF.BatteryEnergy_kWh, "omitnan");
    OptEnergy = sum(OF.BatteryEnergy_kWh, "omitnan");
    ClimbEnergy = sum(OF.BatteryEnergy_kWh(OF.Phase == "Climb"), "omitnan");
    AdditionalEnergy = OptEnergy - UnoptEnergy;
    Rows{k} = table(Keys.Sequence(k), Strategy, FuelSaved, ...
        ClimbFuelSaved, UnoptEnergy, OptEnergy, AdditionalEnergy, ...
        SafeRatio(FuelSaved, OptEnergy), ...
        SafeRatio(FuelSaved, AdditionalEnergy), ...
        SafePercent(ClimbEnergy, OptEnergy), ...
        'VariableNames', {'Sequence','OptimizationStrategy', ...
        'OptimizationFuelSaving_kg','ClimbOptimizationFuelSaving_kg', ...
        'UnoptimizedBatteryEnergy_kWh','OptimizedBatteryEnergy_kWh', ...
        'AdditionalBatteryEnergyUsedByOptimization_kWh', ...
        'OptimizationFuelSavedPerOptimizedBatteryEnergy_kg_per_kWh', ...
        'MarginalFuelSavedPerAdditionalBatteryEnergy_kg_per_kWh', ...
        'OptimizedBatteryEnergyAllocatedToClimb_pct'});
end
T = vertcat(Rows{:});
end


function [T, Summary] = BuildSOCNeutralAnalysis(Phase, Fuel)
if isempty(Phase), T = table; Summary = table; return; end
Keys = unique(Fuel(:, {'Sequence','OptimizationStrategy'}), "rows");
Rows = cell(height(Keys), 1);
for k = 1:height(Keys)
    Strategy = Keys.OptimizationStrategy(k);
    P = Phase(Phase.Sequence == Keys.Sequence(k) & ...
        ismember(Phase.CaseName, ["Unoptimized", Strategy]), :);
    LastFlight = max(P.Flight);
    U = P(P.CaseName == "Unoptimized" & P.Flight == LastFlight, :);
    O = P(P.CaseName == Strategy & P.Flight == LastFlight, :);
    if isempty(U) || isempty(O)
        UnoptSOC = NaN; OptSOC = NaN; Capacity = NaN;
    else
        UnoptSOC = U.FlightTerminalSOC_pct(1);
        OptSOC = O.FlightTerminalSOC_pct(1);
        Capacity = O.NominalBatteryCapacity_kWh(1);
    end
    DeltaSOC = OptSOC - UnoptSOC;
    DeltaEnergy = Capacity * DeltaSOC / 100;
    F = Fuel(Fuel.Sequence == Keys.Sequence(k) & ...
        Fuel.OptimizationStrategy == Strategy, :);
    FuelSaved = sum(F.OptimizationFuelSaving_kg, "omitnan");
    WithinHalf = abs(DeltaSOC) <= 0.5;
    WithinOne = abs(DeltaSOC) <= 1.0;
    ParitySaving = NaN;
    if WithinHalf, ParitySaving = FuelSaved; end
    Rows{k} = table(Keys.Sequence(k), Strategy, FuelSaved, UnoptSOC, ...
        OptSOC, DeltaSOC, Capacity, DeltaEnergy, WithinHalf, WithinOne, ...
        ParitySaving, 'VariableNames', {'Sequence','OptimizationStrategy', ...
        'OptimizationFuelSaving_kg','UnoptimizedTerminalSOC_pct', ...
        'OptimizedTerminalSOC_pct','OptimizedMinusUnoptimizedTerminalSOC_pct', ...
        'NominalBatteryCapacity_kWh', ...
        'OptimizedMinusUnoptimizedTerminalEnergy_kWh', ...
        'SOCParityWithin0_5pct','SOCParityWithin1_0pct', ...
        'FuelSavingForSOCParityWithin0_5pct_kg'});
end
T = vertcat(Rows{:});
Strategies = unique(T.OptimizationStrategy, "stable");
Rows = cell(numel(Strategies), 1);
for k = 1:numel(Strategies)
    S = T(T.OptimizationStrategy == Strategies(k), :);
    AllSaving = ScalarStats(S.OptimizationFuelSaving_kg);
    ParitySaving = ScalarStats(S.FuelSavingForSOCParityWithin0_5pct_kg);
    Delta = ScalarStats(S.OptimizedMinusUnoptimizedTerminalSOC_pct);
    Rows{k} = table(Strategies(k), height(S), sum(S.SOCParityWithin0_5pct), ...
        100 * mean(S.SOCParityWithin0_5pct), sum(S.SOCParityWithin1_0pct), ...
        100 * mean(S.SOCParityWithin1_0pct), AllSaving.Mean, ...
        ParitySaving.Mean, ParitySaving.CI95Low, ParitySaving.CI95High, ...
        Delta.Mean, 'VariableNames', {'OptimizationStrategy','NSequences', ...
        'SequencesWithin0_5pctSOC','SequencesWithin0_5pctSOC_pct', ...
        'SequencesWithin1_0pctSOC','SequencesWithin1_0pctSOC_pct', ...
        'MeanFuelSavingAllSequences_kg', ...
        'MeanFuelSavingAt0_5pctSOCParity_kg', ...
        'SOCParityFuelSavingCI95Low_kg','SOCParityFuelSavingCI95High_kg', ...
        'MeanTerminalSOCDifference_pct'});
end
Summary = vertcat(Rows{:});
end


function [T, Summary] = BuildAuthorityAnalysis(Phase)
if isempty(Phase), T = table; Summary = table; return; end
P = Phase(Phase.CaseName ~= "Conventional", :);
Keys = unique(P(:, {'Sequence','CaseName','Phase','PhaseOrder'}), "rows");
Rows = cell(height(Keys), 1);
for k = 1:height(Keys)
    Mask = P.Sequence == Keys.Sequence(k) & ...
        P.CaseName == Keys.CaseName(k) & P.Phase == Keys.Phase(k);
    D = P(Mask, :);
    Duration = sum(D.Duration_min, "omitnan");
    W = D.Duration_min;
    Rows{k} = table(Keys.Sequence(k), Keys.CaseName(k), Keys.Phase(k), ...
        Keys.PhaseOrder(k), Duration, ...
        WeightedMean(D.MeanMotorUtilization, W), ...
        max(D.PeakMotorUtilization, [], "omitnan"), ...
        WeightedMean(D.MotorLimitFraction, W), ...
        WeightedMean(D.MeanBatteryUtilization, W), ...
        max(D.PeakBatteryUtilization, [], "omitnan"), ...
        WeightedMean(D.BatteryLimitFraction, W), ...
        min(D.MinimumSOCMargin_pct, [], "omitnan"), ...
        'VariableNames', {'Sequence','CaseName','Phase','PhaseOrder', ...
        'Duration_min','MeanMotorUtilization','PeakMotorUtilization', ...
        'MotorLimitFraction','MeanBatteryUtilization', ...
        'PeakBatteryUtilization','BatteryLimitFraction', ...
        'MinimumSOCMargin_pct'});
end
T = vertcat(Rows{:});
Groups = unique(T(:, {'CaseName','Phase','PhaseOrder'}), "rows");
Rows = cell(height(Groups), 1);
for k = 1:height(Groups)
    Mask = T.CaseName == Groups.CaseName(k) & T.Phase == Groups.Phase(k);
    M = ScalarStats(100 * T.MeanMotorUtilization(Mask));
    ML = ScalarStats(100 * T.MotorLimitFraction(Mask));
    B = ScalarStats(100 * T.MeanBatteryUtilization(Mask));
    BL = ScalarStats(100 * T.BatteryLimitFraction(Mask));
    SOC = ScalarStats(T.MinimumSOCMargin_pct(Mask));
    Rows{k} = table(Groups.CaseName(k), Groups.Phase(k), ...
        Groups.PhaseOrder(k), M.N, M.Mean, ML.Mean, B.Mean, BL.Mean, ...
        SOC.Mean, 'VariableNames', {'CaseName','Phase','PhaseOrder', ...
        'NSequences','MeanMotorUtilization_pct', ...
        'MeanTimeAtMotorLimit_pct','MeanBatteryUtilization_pct', ...
        'MeanTimeAtBatteryLimit_pct','MeanMinimumSOCMargin_pct'});
end
Summary = sortrows(vertcat(Rows{:}), {'CaseName','PhaseOrder'});
end


function T = SummarizeStrategyMetrics(Data, Metrics)
Strategies = unique(Data.OptimizationStrategy, "stable");
Rows = cell(numel(Strategies) * numel(Metrics), 1);
n = 0;
for i = 1:numel(Strategies)
    S = Data(Data.OptimizationStrategy == Strategies(i), :);
    for j = 1:numel(Metrics)
        Stats = ScalarStats(S.(Metrics(j)));
        n = n + 1;
        Rows{n} = table(Strategies(i), Metrics(j), Stats.N, Stats.Mean, ...
            Stats.StdDev, Stats.CI95Low, Stats.CI95High, ...
            'VariableNames', {'OptimizationStrategy','Metric','N', ...
            'Mean','StdDev','CI95Low','CI95High'});
    end
end
T = vertcat(Rows{1:n});
end


function Value = SafePercent(Numerator, Denominator)
Value = 100 * SafeRatio(Numerator, Denominator);
end


function Value = SafeRatio(Numerator, Denominator)
Tolerance = 1e-9 * max(1, abs(Denominator));
if ~isfinite(Numerator) || ~isfinite(Denominator) || ...
        abs(Denominator) <= Tolerance
    Value = NaN;
else
    Value = Numerator / Denominator;
end
end


function MakeOptimizationBenefitPlots(A, OutDir, IsVisible)
if isempty(A.PhaseFuelSummary), return; end
MakePhaseFuelDecompositionPlot(A.PhaseFuelSummary, OutDir, IsVisible);
MakeClimbContributionPlot(A.ClimbContributionBySequence, OutDir, IsVisible);
MakeElectricAssistPlot(A.ElectricAssistPhaseSummary, ...
    A.ElectricAssistBySequence, OutDir, IsVisible);
MakeSOCNeutralPlot(A.SOCNeutralBySequence, OutDir, IsVisible);
MakeAuthorityPlot(A.AuthoritySummary, OutDir, IsVisible);
end


function MakePhaseFuelDecompositionPlot(T, OutDir, IsVisible)
Fig = NewAnalysisFigure(IsVisible, [100 100 1500 650]);
Strategies = ["Individual","Joint"];
for k = 1:2
    Ax = subplot(1, 2, k, "Parent", Fig);
    D = sortrows(T(T.OptimizationStrategy == Strategies(k), :), "PhaseOrder");
    Values = [D.MeanArchitectureFuelSaving_kg, ...
        D.MeanOptimizationFuelSaving_kg];
    bar(Ax, categorical(D.Phase, D.Phase), Values, "stacked");
    ylabel(Ax, "Mean fuel saving per flight (kg)");
    title(Ax, Strategies(k) + " optimization: source of fuel saving");
    legend(Ax, ["HEA architecture","Operational optimization"], ...
        "Location", "best");
    StylePaperAxes(Ax);
end
SetAnalysisTitle(Fig, ...
    "Phase fuel decomposition: architecture versus optimization");
exportgraphics(Fig, fullfile(OutDir, "Phase_Fuel_Decomposition.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function MakeClimbContributionPlot(T, OutDir, IsVisible)
if isempty(T), return; end
Fig = NewAnalysisFigure(IsVisible, [100 100 1450 650]);
Strategies = ["Individual","Joint"];
Metrics = ["ClimbOptimizationFuelSaving_pctOfUnoptimizedHEAClimb", ...
    "ClimbShareOfTotalOptimizationSaving_pct"];
Titles = ["Climb fuel reduction relative to fixed-assist HEA climb", ...
    "Fraction of total optimization saving produced in climb"];
YLabels = ["Climb fuel reduction (%)","Share of optimization saving (%)"];
for p = 1:2
    Ax = subplot(1, 2, p, "Parent", Fig); hold(Ax, "on");
    for k = 1:2
        Values = T.(Metrics(p))(T.OptimizationStrategy == Strategies(k));
        X = k + 0.12 * sin((1:numel(Values))');
        scatter(Ax, X, Values, 15, "filled", "MarkerFaceAlpha", 0.25);
        plot(Ax, k, median(Values, "omitnan"), "kd", ...
            "MarkerFaceColor", "y", "MarkerSize", 8);
    end
    xlim(Ax, [0.5 2.5]); xticks(Ax, 1:2); xticklabels(Ax, Strategies);
    ylabel(Ax, YLabels(p)); title(Ax, Titles(p)); yline(Ax, 0, ":");
    StylePaperAxes(Ax);
end
SetAnalysisTitle(Fig, ...
    "Climb optimization contribution (points with median diamonds)");
exportgraphics(Fig, fullfile(OutDir, ...
    "Climb_Optimization_Contribution.pdf"), "ContentType", "vector", ...
    "BackgroundColor", "white");
close(Fig);
end


function MakeElectricAssistPlot(Phase, Sequence, OutDir, IsVisible)
if isempty(Phase), return; end
Fig = NewAnalysisFigure(IsVisible, [100 100 1500 650]);
Cases = ["Unoptimized","Individual","Joint"];
CaseLabels = ["Fixed climb assist","Individual","Joint"];
Phases = sortrows(unique(Phase(:, {'Phase','PhaseOrder'}), "rows"), ...
    "PhaseOrder");
Energy = nan(height(Phases), numel(Cases));
Assist = nan(height(Phases), numel(Cases));
for i = 1:height(Phases)
    for j = 1:numel(Cases)
        Mask = Phase.Phase == Phases.Phase(i) & Phase.CaseName == Cases(j);
        if any(Mask)
            Energy(i,j) = Phase.MeanBatteryEnergy_kWh(find(Mask,1));
            Assist(i,j) = Phase.MeanElectricAssist_pct(find(Mask,1));
        end
    end
end
Ax = subplot(1,2,1,"Parent",Fig);
bar(Ax, categorical(Phases.Phase, Phases.Phase), Energy);
ylabel(Ax,"Mean battery energy per flight (kWh)");
title(Ax,"Battery-energy allocation by phase"); legend(Ax,CaseLabels,"Location","best");
StylePaperAxes(Ax);
Ax = subplot(1,2,2,"Parent",Fig);
bar(Ax, categorical(Phases.Phase, Phases.Phase), Assist);
ylabel(Ax,"Mean electric assist (% of required power)");
title(Ax,"Electric-assist allocation by phase"); legend(Ax,CaseLabels,"Location","best");
StylePaperAxes(Ax);
SetAnalysisTitle(Fig, "Electric-assist effectiveness and allocation");
exportgraphics(Fig, fullfile(OutDir, "Electric_Assist_Effectiveness.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function MakeSOCNeutralPlot(T, OutDir, IsVisible)
if isempty(T), return; end
Fig = NewAnalysisFigure(IsVisible, [100 100 900 700]); Ax = axes(Fig); hold(Ax,"on");
Strategies = ["Individual","Joint"];
Colors = [0.8500 0.3250 0.0980; 0.0000 0.4470 0.7410];
for k = 1:2
    S = T(T.OptimizationStrategy == Strategies(k), :);
    scatter(Ax, S.OptimizedMinusUnoptimizedTerminalSOC_pct, ...
        S.OptimizationFuelSaving_kg, 24, Colors(k,:), "filled", ...
        "MarkerFaceAlpha", 0.45, "DisplayName", Strategies(k));
end
xregion(Ax, -0.5, 0.5, "FaceColor", [0.6 0.8 0.6], ...
    "FaceAlpha", 0.15, "HandleVisibility", "off");
xline(Ax,0,":","HandleVisibility","off");
yline(Ax,0,":","HandleVisibility","off");
xlabel(Ax,"Optimized minus fixed-baseline terminal SOC (percentage points)");
ylabel(Ax,"Optimization fuel saving (kg per sequence)");
title(Ax,"SOC-neutral optimization benefit (green band = ±0.5 SOC point)");
legend(Ax,"Location","best"); StylePaperAxes(Ax);
exportgraphics(Fig, fullfile(OutDir, ...
    "SOC_Neutral_Optimization_Benefit.pdf"), "ContentType", "vector", ...
    "BackgroundColor", "white");
close(Fig);
end


function MakeAuthorityPlot(T, OutDir, IsVisible)
if isempty(T), return; end
Fig = NewAnalysisFigure(IsVisible, [100 100 1500 750]);
Cases = ["Unoptimized","Individual","Joint"];
CaseLabels = ["Fixed climb assist","Individual","Joint"];
Phases = sortrows(unique(T(:, {'Phase','PhaseOrder'}), "rows"), "PhaseOrder");
Motor = nan(height(Phases),3); AtLimit = Motor;
for i = 1:height(Phases)
    for j = 1:3
        Mask = T.Phase == Phases.Phase(i) & T.CaseName == Cases(j);
        if any(Mask)
            Motor(i,j) = T.MeanMotorUtilization_pct(find(Mask,1));
            AtLimit(i,j) = T.MeanTimeAtMotorLimit_pct(find(Mask,1));
        end
    end
end
Ax=subplot(1,2,1,"Parent",Fig); bar(Ax,categorical(Phases.Phase,Phases.Phase),Motor);
ylabel(Ax,"Mean motor utilization (% of rating)"); title(Ax,"Available electric-power utilization");
legend(Ax,CaseLabels,"Location","northeast"); StylePaperAxes(Ax);
Ax=subplot(1,2,2,"Parent",Fig); bar(Ax,categorical(Phases.Phase,Phases.Phase),AtLimit);
ylabel(Ax,"Time at motor limit (%)"); title(Ax,"How often electric power constrains the schedule");
legend(Ax,CaseLabels,"Location","northeast"); StylePaperAxes(Ax);
SetAnalysisTitle(Fig,"Optimization authority and active constraints");
exportgraphics(Fig, fullfile(OutDir, "Optimization_Authority.pdf"), ...
    "ContentType", "vector", "BackgroundColor", "white");
close(Fig);
end


function Fig = NewAnalysisFigure(IsVisible, Position)
Visibility = "off"; if IsVisible, Visibility = "on"; end
Fig = figure("Visible", Visibility, "Color", "w", "Position", Position);
end


function SetAnalysisTitle(Fig, Text)
TitleHandle = sgtitle(Fig, Text);
TitleHandle.Color = "k";
TitleHandle.FontWeight = "bold";
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
    "Battery 80% SOH setting"; "Representative sequence"; ...
    "Random sequence case studies"];
Definition = [ ...
    "Flight distance in nautical miles; total daily sequence distance is also reported."; ...
    "Only between-flight stops are included; the first-flight placeholder is excluded."; ...
    "Sample standard deviation and sample variance, with N, standard error, and a 95% confidence interval."; ...
    "Each sequence and strategy is divided by conventional fuel for the same sequence, so conventional equals 1. This remains in the CSV tables; the headline distribution figure uses the more intuitive percent saving versus conventional."; ...
    "Paired conventional fuel minus HEA fuel, reported in kilograms and percent."; ...
    "The internal Unoptimized fields store the fixed constant-kW climb HEA baseline for backward-compatible checkpoint loading. Its target is 30% of combined installed motor rating and is automatically reduced only when the complete charged sequence cannot sustain it; the exact kW and percent are stored in SequenceSummary. Additional saving is fixed-baseline fuel minus optimized fuel."; ...
    "Final HEA SOC values and paired differences are reported to show whether fuel comparisons end at comparable battery states."; ...
    "Separate sensitivity figures show total saving versus conventional and additional optimization saving beyond the fixed HEA baseline, expressed as percentage points of conventional fuel. These are descriptive associations, not causal effects."; ...
    "Exit flag greater than zero is counted as converged. Feasibility is reported separately because an iteration-limit result can remain feasible. Selected convergence plots compare joint and individual objective reduction and first-order optimality residual histories when traces are stored."; ...
    "The run represents an aged battery at 80% state of health: effective cell capacity is 80% of nominal, and the charging model applies a 0.60 C age limit and 1.30 resistance multiplier before temperature/power limits. It is not an 80% SOC limit and no degradation is accumulated."; ...
    "Sequence " + string(Representative) + " was selected for clear joint SOC preservation and joint fuel saving relative to individual optimization."; ...
    "Four completed sequences are drawn with a fixed recorded random seed, written to Random_Sequence_Selection.csv, and receive the same eight-panel mission comparison as the representative case."];
T = table(Item, Definition);
end
