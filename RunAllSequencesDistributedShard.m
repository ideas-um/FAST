function Aggregate = RunAllSequencesDistributedShard( ...
        ShardNumbers, ShardCount, CompletedIndicesFile, ...
        NumWorkers, MaxIterations)
%RUNALLSEQUENCESDISTRIBUTEDSHARD Run a non-overlapping host share.
%
% Example two-host 2:1 split (faster machine gets two shares):
%   RunAllSequencesDistributedShard([1 2],3,completionFile,12,500)
%   RunAllSequencesDistributedShard(3,3,completionFile,6,500)
%
% Sharding is applied only after removing checkpoints already completed on
% the remote host.  The production runner still performs exact FAST/EAP
% analyses and retains its own local checkpoint/resume behavior.

if nargin < 1 || isempty(ShardNumbers), ShardNumbers = 1; end
if nargin < 2 || isempty(ShardCount), ShardCount = 1; end
if nargin < 3 || isempty(CompletedIndicesFile)
    CompletedIndicesFile = fullfile(fileparts(mfilename("fullpath")), ...
        "RemoteCompletedSequenceIndices.txt");
end
if nargin < 4 || isempty(NumWorkers), NumWorkers = 6; end
if nargin < 5 || isempty(MaxIterations), MaxIterations = 500; end

ShardNumbers = unique(ShardNumbers(:)');
if any(ShardNumbers < 1 | ShardNumbers > ShardCount | ...
        ShardNumbers ~= fix(ShardNumbers))
    error("Shard numbers must be integers from 1 through ShardCount.");
end

RootDir = fileparts(mfilename("fullpath"));
SequenceData = load(fullfile(RootDir, "Sequence.mat"), "tables");
nSequence = numel(SequenceData.tables);
Completed = zeros(0, 1);
if isfile(CompletedIndicesFile)
    Completed = readmatrix(CompletedIndicesFile);
    Completed = unique(Completed(isfinite(Completed)));
end

Remaining = setdiff((1:nSequence)', Completed, "stable");
Assignment = mod((0:numel(Remaining)-1)', ShardCount) + 1;
Selected = Remaining(ismember(Assignment, ShardNumbers));

fprintf(["Distributed shard(s) %s/%d selected %d of %d remaining " ...
    "sequences (%d already complete).\n"], ...
    mat2str(ShardNumbers), ShardCount, numel(Selected), ...
    numel(Remaining), numel(Completed));
Aggregate = RunAllSequencesFullComparisonParallel( ...
    NumWorkers, MaxIterations, Selected);
end
