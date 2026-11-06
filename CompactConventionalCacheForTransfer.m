function Summary = CompactConventionalCacheForTransfer( ...
        SourceDirectory, DestinationDirectory)
%COMPACTCONVENTIONALCACHEFORTRANSFER Strip repeated heavy aircraft databases.
%
% The exact conventional mission has already been evaluated in every source
% cache entry.  This function preserves the mission profile/history and all
% fields used by RunAllSequencesFullComparisonParallel post-processing while
% omitting engine maps and other sizing databases that are identical in every
% file.  Source files are never modified.

if nargin < 1 || strlength(string(SourceDirectory)) == 0
    SourceDirectory = fullfile(pwd, "output", ...
        "local_rep100_sequence8_v6", "conventional_flight_cache");
end
if nargin < 2 || strlength(string(DestinationDirectory)) == 0
    DestinationDirectory = fullfile(pwd, "output", ...
        "local_rep100_precomputed_v6", "conventional_flight_cache");
end
SourceDirectory = char(SourceDirectory);
DestinationDirectory = char(DestinationDirectory);

if ~isfolder(SourceDirectory)
    error("FAST:MissingConventionalCache", ...
        "Conventional cache directory does not exist: %s", SourceDirectory);
end
if ~isfolder(DestinationDirectory), mkdir(DestinationDirectory); end

Files = dir(fullfile(SourceDirectory, "ConventionalFlight_*.mat"));
if isempty(Files)
    error("FAST:EmptyConventionalCache", ...
        "No conventional cache MAT files were found in %s.", SourceDirectory);
end

FileName = strings(numel(Files), 1);
SourceBytes = zeros(numel(Files), 1);
CompactBytes = zeros(numel(Files), 1);
for k = 1:numel(Files)
    SourceFile = fullfile(Files(k).folder, Files(k).name);
    Data = load(SourceFile, "Aircraft", "CacheMetadata");
    if ~isfield(Data, "Aircraft") || ~isfield(Data, "CacheMetadata")
        error("FAST:InvalidConventionalCache", ...
            "Cache file is incomplete: %s", SourceFile);
    end
    Aircraft = ReusableAircraft(Data.Aircraft);
    CacheMetadata = Data.CacheMetadata;
    DestinationFile = fullfile(DestinationDirectory, Files(k).name);
    save(DestinationFile, "Aircraft", "CacheMetadata", "-v7.3");

    CompactInfo = dir(DestinationFile);
    FileName(k) = string(Files(k).name);
    SourceBytes(k) = Files(k).bytes;
    CompactBytes(k) = CompactInfo.bytes;
    fprintf("Compacted conventional cache %d/%d: %s\n", ...
        k, numel(Files), Files(k).name);
end

Reduction_pct = 100 * (1 - CompactBytes ./ SourceBytes);
Summary = table(FileName, SourceBytes, CompactBytes, Reduction_pct);
writetable(Summary, fullfile(DestinationDirectory, ...
    "Conventional_Cache_Transfer_Manifest.csv"));
save(fullfile(DestinationDirectory, ...
    "Conventional_Cache_Transfer_Manifest.mat"), "Summary");

fprintf("Conventional cache compacted: %.1f MiB -> %.1f MiB.\n", ...
    sum(SourceBytes) / 2^20, sum(CompactBytes) / 2^20);
end


function Compact = ReusableAircraft(Aircraft)
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
