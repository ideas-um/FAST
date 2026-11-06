function SmokeRoot = ValidateRepresentative100Workflow(RunSmoke)
%VALIDATEREPRESENTATIVE100WORKFLOW Preflight the 250 Wh/kg selected workflow.

if nargin < 1, RunSmoke = false; end
Root = fileparts(mfilename("fullpath"));
Workflow = fullfile(fileparts(Root), "great_lakes");
addpath(Root, Workflow);

Files = { ...
    fullfile(Root,"RunAllSequencesFullComparisonParallel.m"), ...
    fullfile(Root,"RunGreatLakesSequenceTask.m"), ...
    fullfile(Root,"+OptimizationPkg","SequencePowerOpt.m"), ...
    fullfile(Root,"+OptimizationPkg","OptimizationTraceRecorder.m"), ...
    fullfile(Workflow,"PrepareSelectedSequenceRun.m"), ...
    fullfile(Workflow,"RunSelectedSequenceTask.m"), ...
    fullfile(Workflow,"CollectSelectedSequenceResults.m"), ...
    fullfile(Workflow,"ProcessSelectedSequenceResults.m"), ...
    fullfile(Workflow,"HEAOpsPaperResults.m")};
for k = 1:numel(Files)
    Messages = checkcode(Files{k}, "-id");
    IDs = string({Messages.id});
    Serious = ~ismember(IDs, ["NASGU","AGROW","NOPTS","INUSD"]);
    if ~isempty(Messages)
        Text = string({Messages.message});
        Serious = Serious & ~contains(Text, ...
            "A Code Analyzer message was once suppressed here");
    end
    if any(Serious)
        error("FAST:Representative100:CodeCheck", ...
            "Static MATLAB check failed for %s: %s", Files{k}, ...
            strjoin(string({Messages(Serious).message}), " | "));
    end
end

Trace = OptimizationPkg.OptimizationTraceRecorder.EmptyTable();
assert(height(Trace) == 0 && width(Trace) == 12, ...
    "Optimization trace table construction failed.");
SequenceFile = fullfile(Root,"Seq100Represent.mat");
SequenceData = load(SequenceFile,"tables","OriginalSequenceIndices");
assert(numel(SequenceData.tables) == 100 && ...
    numel(SequenceData.OriginalSequenceIndices) == 100, ...
    "Representative sequence file must contain 100 tables and mappings.");
BaselineFile = fullfile(Root, ...
    "ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat");
Baseline = load(BaselineFile,"SizedAircraft");
assert(abs(Baseline.SizedAircraft.Specs.Power.SpecEnergy.Batt / 3.6e3 ...
    - 250) < 1e-10, "Selected HEA baseline is not 250 Wh/kg.");

SmokeRoot = "";
if ~RunSmoke
    fprintf("Representative-100 static preflight passed.\n");
    return
end

SmokeRoot = string(tempname(fullfile(Root,"tmp")));
mkdir(SmokeRoot);
Names = ["FAST_GL_RESULTS_DIR","FAST_HEA_BASELINE_FILE", ...
    "FAST_SEQUENCE_FILE","FAST_GL_MAX_ITERATIONS", ...
    "FAST_GL_JOINT_MAX_ITERATIONS","FAST_GL_OPTIMALITY_TOLERANCE", ...
    "FAST_GL_ACCEPT_FEASIBLE_AT_LIMIT", ...
    "FAST_EXPECTED_BATTERY_SPECIFIC_ENERGY_WHKG", ...
    "FAST_GL_SEQUENCE_SPEC","FAST_SEQUENCE_INDEX", ...
    "FAST_RETHROW_SEQUENCE_FAILURE"];
for k = 1:numel(Names), Old.(Names(k)) = string(getenv(Names(k))); end
Cleanup = onCleanup(@() RestoreEnvironment(Old));
setenv("FAST_GL_RESULTS_DIR",SmokeRoot);
setenv("FAST_HEA_BASELINE_FILE",BaselineFile);
setenv("FAST_SEQUENCE_FILE",SequenceFile);
setenv("FAST_GL_MAX_ITERATIONS","1");
setenv("FAST_GL_JOINT_MAX_ITERATIONS","1");
setenv("FAST_GL_OPTIMALITY_TOLERANCE","1e-3");
setenv("FAST_GL_ACCEPT_FEASIBLE_AT_LIMIT","1");
setenv("FAST_EXPECTED_BATTERY_SPECIFIC_ENERGY_WHKG","250");
setenv("FAST_GL_SEQUENCE_SPEC","1");
setenv("FAST_SEQUENCE_INDEX","1");

PrepareSelectedSequenceRun();
RunSelectedSequenceTask();
Results = ProcessSelectedSequenceResults();
assert(numel(Results.Combined.CompletedSequenceIndices) == 1 && ...
    Results.Combined.CompletedSequenceIndices == 1, ...
    "End-to-end smoke test did not produce the selected checkpoint.");
fprintf("Representative-100 runtime smoke test passed: %s\n",SmokeRoot);
clear Cleanup
end


function RestoreEnvironment(Old)
Names = string(fieldnames(Old));
for k = 1:numel(Names), setenv(Names(k),Old.(Names(k))); end
end
