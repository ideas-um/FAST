function Manifest = PrecomputeRepresentative100Baselines(NumWorkers)
%PRECOMPUTEREPRESENTATIVE100BASELINES Cache conventional and fixed HEA cases.
%
% Produces compact, reusable MAT files for all conventional flight conditions
% and for the fixed constant-kW baseline of every representative sequence.
% The optimizer workflow can then load these files and calculate only the
% individual and joint optimized cases on Great Lakes.

if nargin < 1 || isempty(NumWorkers), NumWorkers = 4; end
validateattributes(NumWorkers, {'numeric'}, ...
    {'scalar','integer','positive','<=',12});

Root = fileparts(mfilename("fullpath"));
SourceRun = fullfile(Root, "output", "local_rep100_sequence8_v6");
OutputRoot = fullfile(Root, "output", "local_rep100_precomputed_v6");
SequenceFile = fullfile(Root, "Seq100Represent.mat");
PreparedBaseFile = fullfile(SourceRun, "prepared", ...
    "SelectedHEA_BaseAircraft.mat");
SourceConventionalCache = fullfile(SourceRun, ...
    "conventional_flight_cache");
ConventionalCache = fullfile(OutputRoot, "conventional_flight_cache");
FixedCache = fullfile(OutputRoot, "fixed_baseline_cache");
DriverOutput = fullfile(OutputRoot, "baseline_driver");
PreparedBundle = fullfile(OutputRoot, "prepared");

Required = string({SequenceFile, PreparedBaseFile, SourceConventionalCache});
for k = 1:numel(Required)
    if ~(isfile(Required(k)) || isfolder(Required(k)))
        error("FAST:MissingPrecomputeInput", ...
            "Required precompute input does not exist: %s", Required(k));
    end
end
if ~isfolder(OutputRoot), mkdir(OutputRoot); end
if ~isfolder(FixedCache), mkdir(FixedCache); end
if ~isfolder(DriverOutput), mkdir(DriverOutput); end
if ~isfolder(PreparedBundle), mkdir(PreparedBundle); end

ExistingCompact = dir(fullfile(ConventionalCache, ...
    "ConventionalFlight_*.mat"));
if numel(ExistingCompact) == 63 && isfile(fullfile(ConventionalCache, ...
        "Conventional_Cache_Transfer_Manifest.mat"))
    fprintf("Reusing 63 compact conventional cache files.\n");
else
    CompactConventionalCacheForTransfer( ...
        SourceConventionalCache, ConventionalCache);
end
copyfile(PreparedBaseFile, fullfile(PreparedBundle, ...
    "SelectedHEA_BaseAircraft.mat"), "f");

EnvironmentNames = [ ...
    "FAST_SEQUENCE_FILE", "FAST_SEQUENCE_OUTPUT_DIR", ...
    "FAST_CONVENTIONAL_CACHE_DIR", "FAST_BASE_AIRCRAFT_FILE", ...
    "FAST_FIXED_BASELINE_CACHE_DIR", "FAST_FIXED_BASELINE_ONLY", ...
    "FAST_PREPARE_CACHE_ONLY", "FAST_RETHROW_SEQUENCE_FAILURE"];
PriorValues = arrayfun(@(x) string(getenv(x)), EnvironmentNames);
Cleanup = onCleanup(@() RestoreEnvironment(EnvironmentNames, PriorValues));

setenv("FAST_SEQUENCE_FILE", SequenceFile);
setenv("FAST_SEQUENCE_OUTPUT_DIR", DriverOutput);
setenv("FAST_CONVENTIONAL_CACHE_DIR", ConventionalCache);
setenv("FAST_BASE_AIRCRAFT_FILE", PreparedBaseFile);
setenv("FAST_FIXED_BASELINE_CACHE_DIR", FixedCache);
setenv("FAST_FIXED_BASELINE_ONLY", "1");
setenv("FAST_PREPARE_CACHE_ONLY", "");
setenv("FAST_RETHROW_SEQUENCE_FAILURE", "");

RunAllSequencesFullComparisonParallel(NumWorkers, 500, 1:100);
Manifest = BuildManifest(SequenceFile, FixedCache);
writetable(Manifest, fullfile(OutputRoot, ...
    "Representative100_Precomputed_Baseline_Manifest.csv"));
save(fullfile(OutputRoot, ...
    "Representative100_Precomputed_Baseline_Manifest.mat"), "Manifest");
clear Cleanup

fprintf("Precomputed fixed baselines: %d/%d complete.\n", ...
    nnz(Manifest.Complete), height(Manifest));
fprintf("Reusable result bundle: %s\n", OutputRoot);
end


function Manifest = BuildManifest(SequenceFile, FixedCache)
S = load(SequenceFile, "tables", "OriginalSequenceIndices");
nSequence = numel(S.tables);
RepresentativeSequence = (1:nSequence)';
if isfield(S, "OriginalSequenceIndices")
    OriginalSequence = S.OriginalSequenceIndices(:);
else
    OriginalSequence = RepresentativeSequence;
end
Flights = cellfun(@height, S.tables(:));
Complete = false(nSequence, 1);
FixedClimbMotorPower_kW = nan(nSequence, 1);
FixedClimbMotorPower_pct = nan(nSequence, 1);
FileSize_MiB = nan(nSequence, 1);
Completed = strings(nSequence, 1);
File = strings(nSequence, 1);
for k = 1:nSequence
    File(k) = fullfile(FixedCache, sprintf( ...
        "Sequence_%04d_fixed_baseline.mat", k));
    if ~isfile(File(k)), continue; end
    try
        D = load(File(k), "FixedBaselineMetadata", ...
            "FixedClimbMotorPower_kW", "FixedClimbMotorPower_pct");
        Complete(k) = string(D.FixedBaselineMetadata.Status) == "success";
        FixedClimbMotorPower_kW(k) = D.FixedClimbMotorPower_kW;
        FixedClimbMotorPower_pct(k) = D.FixedClimbMotorPower_pct;
        Completed(k) = string(D.FixedBaselineMetadata.Completed);
        Info = dir(File(k));
        FileSize_MiB(k) = Info.bytes / 2^20;
    catch
        Complete(k) = false;
    end
end
Manifest = table(RepresentativeSequence, OriginalSequence, Flights, ...
    Complete, FixedClimbMotorPower_kW, FixedClimbMotorPower_pct, ...
    FileSize_MiB, Completed, File);
end


function RestoreEnvironment(Names, Values)
for k = 1:numel(Names)
    setenv(Names(k), Values(k));
end
end
