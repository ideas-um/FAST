function Aggregate = RunSelectedSequenceTask()
%RUNSELECTEDSEQUENCETASK Run one selected Slurm-array sequence task.

SequenceIndex = ReadPositiveInteger("FAST_SEQUENCE_INDEX", NaN);
MaxIterations = ReadPositiveInteger("FAST_GL_MAX_ITERATIONS", 500);
ResultsRoot = RequireEnvironmentPath("FAST_GL_RESULTS_DIR");
TaskOutput = fullfile(ResultsRoot, "tasks", ...
    sprintf("Sequence_%04d", SequenceIndex));
SharedCache = fullfile(ResultsRoot, "conventional_flight_cache");
PreparedBaseFile = fullfile(ResultsRoot, "prepared", ...
    "SelectedHEA_BaseAircraft.mat");

if ~isfolder(TaskOutput), mkdir(TaskOutput); end
if ~isfolder(SharedCache)
    error("GreatLakes:MissingConventionalCache", ...
        "Preparation did not create the conventional-flight cache.");
end
if ~isfile(PreparedBaseFile)
    error("GreatLakes:MissingPreparedAircraft", ...
        "Preparation did not create SelectedHEA_BaseAircraft.mat.");
end

setenv("FAST_SEQUENCE_OUTPUT_DIR", TaskOutput);
setenv("FAST_CONVENTIONAL_CACHE_DIR", SharedCache);
setenv("FAST_BASE_AIRCRAFT_FILE", PreparedBaseFile);
setenv("FAST_PREPARE_CACHE_ONLY", "");
Aggregate = RunAllSequencesFullComparisonParallel( ...
    1, MaxIterations, SequenceIndex);
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
