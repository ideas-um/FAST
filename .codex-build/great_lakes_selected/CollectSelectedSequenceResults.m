function Aggregate = CollectSelectedSequenceResults()
%COLLECTSELECTEDSEQUENCERESULTS Aggregate selected sequence checkpoints.

RunVersion = "all-sequences-v4-source-sized-base-aircraft";
MaxIterations = ReadPositiveInteger("FAST_GL_MAX_ITERATIONS", 500);
Selected = ParseSequenceSpec(string(getenv("FAST_GL_SEQUENCE_SPEC")), 864);
ResultsRoot = RequireEnvironmentPath("FAST_GL_RESULTS_DIR");
CombinedDir = fullfile(ResultsRoot, "combined");
if ~isfolder(CombinedDir), mkdir(CombinedDir); end

nSelected = numel(Selected);
SummaryRows = cell(nSelected, 1);
FlightRows = cell(nSelected, 1);
ChargeRows = cell(nSelected, 1);
TraceRows = cell(nSelected, 1);
ComparisonRows = cell(nSelected, 1);
Complete = false(nSelected, 1);
TaskState = strings(nSelected, 1);
FailureIdentifier = strings(nSelected, 1);
FailureMessage = strings(nSelected, 1);

for k = 1:nSelected
    Index = Selected(k);
    TaskDir = fullfile(ResultsRoot, "tasks", ...
        sprintf("Sequence_%04d", Index));
    CheckpointFile = fullfile(TaskDir, "checkpoints", ...
        sprintf("Sequence_%04d.mat", Index));
    FailureFile = fullfile(TaskDir, "failures", ...
        sprintf("Sequence_%04d_failed.mat", Index));
    if IsValidCheckpoint(CheckpointFile, RunVersion, MaxIterations)
        D = load(CheckpointFile, "SequenceSummary", ...
            "FlightResults", "ChargeResults");
        SummaryRows{k} = D.SequenceSummary;
        D.FlightResults.Sequence = repmat(Index, height(D.FlightResults), 1);
        D.FlightResults = movevars(D.FlightResults, "Sequence", "Before", 1);
        FlightRows{k} = D.FlightResults;
        D.ChargeResults.Sequence = repmat(Index, height(D.ChargeResults), 1);
        D.ChargeResults = movevars(D.ChargeResults, "Sequence", "Before", 1);
        ChargeRows{k} = D.ChargeResults;
        FileVariables = whos("-file", CheckpointFile);
        Available = string({FileVariables.name});
        if ismember("OptimizationTrace", Available)
            Diagnostics = load(CheckpointFile, "OptimizationTrace");
            TraceRows{k} = Diagnostics.OptimizationTrace;
        end
        if ismember("OptimizationComparison", Available)
            Diagnostics = load(CheckpointFile, "OptimizationComparison");
            ComparisonRows{k} = Diagnostics.OptimizationComparison;
        end
        Complete(k) = true;
        TaskState(k) = "success";
    elseif isfile(FailureFile)
        F = load(FailureFile, "ErrorIdentifier", "ErrorMessage");
        TaskState(k) = "failed";
        if isfield(F, "ErrorIdentifier")
            FailureIdentifier(k) = string(F.ErrorIdentifier);
        end
        if isfield(F, "ErrorMessage")
            FailureMessage(k) = string(F.ErrorMessage);
        end
    else
        TaskState(k) = "missing";
    end
end

if any(Complete)
    SequenceSummary = vertcat(SummaryRows{Complete});
    FlightResults = vertcat(FlightRows{Complete});
    ChargeResults = vertcat(ChargeRows{Complete});
    HasTrace = Complete & ~cellfun(@isempty, TraceRows);
    HasComparison = Complete & ~cellfun(@isempty, ComparisonRows);
    if any(HasTrace)
        OptimizationTrace = vertcat(TraceRows{HasTrace});
    else
        OptimizationTrace = table;
    end
    if any(HasComparison)
        OptimizationComparison = vertcat(ComparisonRows{HasComparison});
    else
        OptimizationComparison = table;
    end
else
    SequenceSummary = table;
    FlightResults = table;
    ChargeResults = table;
    OptimizationTrace = table;
    OptimizationComparison = table;
end

TaskStatus = table(Selected, TaskState, FailureIdentifier, FailureMessage, ...
    'VariableNames', {'Sequence','Status','ErrorIdentifier','ErrorMessage'});
FleetMetrics = BuildFleetMetrics(SequenceSummary, nSelected);
RelativeFuelSavings = BuildRelativeFuelSavings(SequenceSummary);
ProcessingMetadata = struct( ...
    "SequenceSpec", string(getenv("FAST_GL_SEQUENCE_SPEC")), ...
    "MaxIterations", MaxIterations, ...
    "Completed", nnz(Complete), ...
    "Selected", nSelected, ...
    "Generated", string(datetime("now")));

Aggregate = struct("SequenceSummary", SequenceSummary, ...
    "FlightResults", FlightResults, "ChargeResults", ChargeResults, ...
    "FleetMetrics", FleetMetrics, "TaskStatus", TaskStatus, ...
    "OptimizationTrace", OptimizationTrace, ...
    "OptimizationComparison", OptimizationComparison, ...
    "RelativeFuelSavings", RelativeFuelSavings, ...
    "ProcessingMetadata", ProcessingMetadata, ...
    "SelectedSequenceIndices", Selected, ...
    "CompletedSequenceIndices", Selected(Complete), ...
    "MissingSequenceIndices", Selected(~Complete));
save(fullfile(CombinedDir, "SelectedSequences_Aggregate.mat"), ...
    "Aggregate", "-v7.3");
WriteTableIfPresent(SequenceSummary, fullfile(CombinedDir, ...
    "SelectedSequences_SequenceSummary.csv"));
WriteTableIfPresent(FlightResults, fullfile(CombinedDir, ...
    "SelectedSequences_FlightResults.csv"));
WriteTableIfPresent(ChargeResults, fullfile(CombinedDir, ...
    "SelectedSequences_ChargeResults.csv"));
WriteTableIfPresent(OptimizationTrace, fullfile(CombinedDir, ...
    "SelectedSequences_OptimizationTrace.csv"));
WriteTableIfPresent(OptimizationComparison, fullfile(CombinedDir, ...
    "SelectedSequences_OptimizationComparison.csv"));
WriteTableIfPresent(RelativeFuelSavings, fullfile(CombinedDir, ...
    "SelectedSequences_RelativeFuelSavings.csv"));
writetable(FleetMetrics, fullfile(CombinedDir, ...
    "SelectedSequences_FleetMetrics.csv"));
writetable(TaskStatus, fullfile(CombinedDir, ...
    "SelectedSequences_TaskStatus.csv"));
writematrix(Selected(Complete), fullfile(CombinedDir, ...
    "CompletedSequenceIndices.txt"));
writematrix(Selected(~Complete), fullfile(CombinedDir, ...
    "MissingSequenceIndices.txt"));
disp(FleetMetrics);
end


function Selected = ParseSequenceSpec(Spec, Maximum)
if strlength(Spec) == 0
    Spec = "1-500";
end
Parts = split(Spec, ",");
Selected = zeros(0, 1);
for k = 1:numel(Parts)
    Token = strip(Parts(k));
    RangeParts = split(Token, "-");
    Values = str2double(RangeParts);
    if any(~isfinite(Values)) || any(Values ~= fix(Values)) || ...
            ~ismember(numel(Values), [1, 2])
        error("GreatLakes:BadSequenceSpec", ...
            "Invalid FAST_GL_SEQUENCE_SPEC token: %s", Token);
    end
    if isscalar(Values)
        NewValues = Values;
    elseif Values(1) <= Values(2)
        NewValues = (Values(1):Values(2))';
    else
        error("GreatLakes:BadSequenceSpec", ...
            "Sequence range must be increasing: %s", Token);
    end
    Selected = [Selected; NewValues(:)]; %#ok<AGROW>
end
Selected = unique(Selected, "stable");
if isempty(Selected) || any(Selected < 1 | Selected > Maximum)
    error("GreatLakes:BadSequenceSpec", ...
        "Selected sequence indices must be between 1 and %d.", Maximum);
end
end


function IsValid = IsValidCheckpoint(FileName, RunVersion, MaxIterations)
IsValid = false;
if ~isfile(FileName), return; end
try
    D = load(FileName, "Status", "RunMetadata");
    IsValid = string(D.Status) == "success" && ...
        string(D.RunMetadata.RunVersion) == RunVersion && ...
        D.RunMetadata.MaxIterations == MaxIterations;
catch
    IsValid = false;
end
end


function FleetMetrics = BuildFleetMetrics(SequenceSummary, TotalSelected)
if isempty(SequenceSummary)
    FleetMetrics = table(TotalSelected, 0, TotalSelected, ...
        'VariableNames', {'TotalSequences','CompletedSequences', ...
        'RemainingSequences'});
    return;
end
FleetMetrics = table(TotalSelected, height(SequenceSummary), ...
    TotalSelected-height(SequenceSummary), sum(SequenceSummary.Flights), ...
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


function T = BuildRelativeFuelSavings(S)
if isempty(S)
    T = table;
    return
end
BaselineFuelSaving_kg = S.ConventionalFuelBurn_kg - ...
    S.UnoptimizedFuelBurn_kg;
JointAdditionalFuelSaving_kg = S.UnoptimizedFuelBurn_kg - ...
    S.JointFuelBurn_kg;
IndividualAdditionalFuelSaving_kg = S.UnoptimizedFuelBurn_kg - ...
    S.IndividualFuelBurn_kg;
Denominator = abs(BaselineFuelSaving_kg);
Tolerance = 1e-9 .* max(1, abs(S.ConventionalFuelBurn_kg));
Denominator(Denominator <= Tolerance) = NaN;
JointAdditionalSavingsRelativeToBaseline_pct = 100 .* ...
    JointAdditionalFuelSaving_kg ./ Denominator;
IndividualAdditionalSavingsRelativeToBaseline_pct = 100 .* ...
    IndividualAdditionalFuelSaving_kg ./ Denominator;
JointRelativeFuelError_pct = ...
    -JointAdditionalSavingsRelativeToBaseline_pct;
IndividualRelativeFuelError_pct = ...
    -IndividualAdditionalSavingsRelativeToBaseline_pct;
T = table(S.Sequence, S.ConventionalFuelBurn_kg, ...
    S.UnoptimizedFuelBurn_kg, S.IndividualFuelBurn_kg, ...
    S.JointFuelBurn_kg, BaselineFuelSaving_kg, ...
    JointAdditionalFuelSaving_kg, IndividualAdditionalFuelSaving_kg, ...
    JointAdditionalSavingsRelativeToBaseline_pct, ...
    IndividualAdditionalSavingsRelativeToBaseline_pct, ...
    JointRelativeFuelError_pct, IndividualRelativeFuelError_pct, ...
    'VariableNames', {'Sequence','ConventionalFuelBurn_kg', ...
    'UnoptimizedFuelBurn_kg','IndividualFuelBurn_kg','JointFuelBurn_kg', ...
    'UnoptimizedBaselineFuelSavingVsConventional_kg', ...
    'JointAdditionalFuelSavingVsUnoptimized_kg', ...
    'IndividualAdditionalFuelSavingVsUnoptimized_kg', ...
    'JointAdditionalSavingsRelativeToBaseline_pct', ...
    'IndividualAdditionalSavingsRelativeToBaseline_pct', ...
    'JointRelativeFuelError_pct','IndividualRelativeFuelError_pct'});
end


function WriteTableIfPresent(Value, FileName)
if ~isempty(Value), writetable(Value, FileName); end
end


function Value = RequireEnvironmentPath(Name)
Value = string(getenv(Name));
if strlength(Value) == 0
    error("GreatLakes:MissingEnvironment", ...
        "Required environment variable %s is not set.", Name);
end
Value = char(Value);
end


function Value = ReadPositiveInteger(Name, DefaultValue)
Text = string(getenv(Name));
if strlength(Text) == 0
    Value = DefaultValue;
else
    Value = str2double(Text);
end
if ~isscalar(Value) || ~isfinite(Value) || Value ~= fix(Value) || Value < 1
    error("GreatLakes:BadInteger", "%s must be a positive integer.", Name);
end
end
