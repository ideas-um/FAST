function Aggregate = RunGreatLakesPrepare()
%RUNGREATLAKESPREPARE Build the shared exact conventional-flight cache.

ResultsRoot = RequireEnvironmentPath("FAST_GL_RESULTS_DIR");
PrepareOutput = fullfile(ResultsRoot, "prepare");
SharedCache = fullfile(ResultsRoot, "conventional_flight_cache");
if ~isfolder(PrepareOutput), mkdir(PrepareOutput); end
if ~isfolder(SharedCache), mkdir(SharedCache); end

setenv("FAST_SEQUENCE_OUTPUT_DIR", PrepareOutput);
setenv("FAST_CONVENTIONAL_CACHE_DIR", SharedCache);
setenv("FAST_PREPARE_CACHE_ONLY", "1");
Cleanup = onCleanup(@() setenv("FAST_PREPARE_CACHE_ONLY", ""));

Aggregate = RunAllSequencesFullComparisonParallel(1, 500, 1);
end


function Value = RequireEnvironmentPath(Name)
Value = string(getenv(Name));
if strlength(Value) == 0
    error("GreatLakes:MissingEnvironment", ...
        "Required environment variable %s is not set.", Name);
end
Value = char(Value);
end
