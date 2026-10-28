function Aggregate = RunGreatLakesSequenceTask()
%RUNGREATLAKESSEQUENCETASK Run one isolated Slurm-array sequence task.

SequenceIndex = str2double(getenv("FAST_SEQUENCE_INDEX"));
if ~isscalar(SequenceIndex) || ~isfinite(SequenceIndex) || ...
        SequenceIndex ~= fix(SequenceIndex) || ...
        SequenceIndex < 1 || SequenceIndex > 500
    error("GreatLakes:BadSequenceIndex", ...
        "FAST_SEQUENCE_INDEX must be an integer from 1 through 500.");
end
if ismember(SequenceIndex, [24 50 52])
    error("GreatLakes:ExcludedSequence", ...
        "Sequence %d already has results and must not be rerun.", ...
        SequenceIndex);
end

ResultsRoot = RequireEnvironmentPath("FAST_GL_RESULTS_DIR");
TaskOutput = fullfile(ResultsRoot, "tasks", ...
    sprintf("Sequence_%04d", SequenceIndex));
SharedCache = fullfile(ResultsRoot, "conventional_flight_cache");
if ~isfolder(TaskOutput), mkdir(TaskOutput); end
if ~isfolder(SharedCache)
    error("GreatLakes:MissingConventionalCache", ...
        "Shared cache is missing. The preparation job must finish first.");
end

setenv("FAST_SEQUENCE_OUTPUT_DIR", TaskOutput);
setenv("FAST_CONVENTIONAL_CACHE_DIR", SharedCache);
setenv("FAST_PREPARE_CACHE_ONLY", "");
Aggregate = RunAllSequencesFullComparisonParallel(1, 500, SequenceIndex);
end


function Value = RequireEnvironmentPath(Name)
Value = string(getenv(Name));
if strlength(Value) == 0
    error("GreatLakes:MissingEnvironment", ...
        "Required environment variable %s is not set.", Name);
end
Value = char(Value);
end
