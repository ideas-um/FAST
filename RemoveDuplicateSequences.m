function [tables, DuplicateMap, OriginalSequenceIndices] = ...
        RemoveDuplicateSequences(InputFile, OutputFile)
%REMOVEDUPLICATESEQUENCES Remove exact duplicate operational schedules.
%
% Schedule equality uses every input consumed by the FAST sequence model:
% distance, cruise altitude, cruise speed, payload, and between-flight
% ground time. Raw date, tail number, and realized delay fields are ignored.
% The first occurrence is retained and every removed original index is
% mapped to that retained occurrence.

Root = fileparts(mfilename("fullpath"));
if nargin < 1 || strlength(string(InputFile)) == 0
    InputFile = fullfile(Root, "Sequence.mat");
end
if nargin < 2 || strlength(string(OutputFile)) == 0
    OutputFile = fullfile(Root, "Sequences_nocopy.mat");
end

D = load(char(InputFile), "tables");
if ~isfield(D, "tables") || ~iscell(D.tables)
    error("FAST:Sequences:InvalidInput", ...
        "Input MAT file must contain the cell array tables.");
end
AllTables = D.tables(:);
n = numel(AllTables);
Keep = true(n, 1);
KeptOriginalIndex = nan(n, 1);
for i = 1:n
    if ~Keep(i), continue; end
    KeptOriginalIndex(i) = i;
    for j = i + 1:n
        if Keep(j) && SameFASTSchedule(AllTables{i}, AllTables{j})
            Keep(j) = false;
            KeptOriginalIndex(j) = i;
        end
    end
end

OriginalSequenceIndices = find(Keep);
tables = AllTables(Keep);
RemovedOriginalIndex = find(~Keep);
DuplicateMap = table(RemovedOriginalIndex, ...
    KeptOriginalIndex(RemovedOriginalIndex), ...
    'VariableNames', {'RemovedOriginalSequenceIndex', ...
    'KeptOriginalSequenceIndex'});
Metadata = struct("EqualityDefinition", ...
    "exact FAST inputs: DISTANCE, ALTITUDE_m, SPEED_mph, PAYLOAD_lb, GROUND_TIME", ...
    "InputSequenceCount", n, "UniqueSequenceCount", numel(tables), ...
    "RemovedDuplicateCount", height(DuplicateMap), ...
    "Generated", string(datetime("now")));

OutputFile = char(OutputFile);
save(OutputFile, "tables", "OriginalSequenceIndices", ...
    "DuplicateMap", "Metadata", "-v7.3");
[Folder, Base] = fileparts(OutputFile);
writetable(DuplicateMap, fullfile(Folder, Base + "_DuplicateMap.csv"));
fprintf("Saved %d unique schedules to %s; removed %d duplicates.\n", ...
    numel(tables), OutputFile, height(DuplicateMap));
end


function Same = SameFASTSchedule(A, B)
Variables = {'DISTANCE','ALTITUDE_m','SPEED_mph','PAYLOAD_lb','GROUND_TIME'};
if ~all(ismember(Variables, A.Properties.VariableNames)) || ...
        ~all(ismember(Variables, B.Properties.VariableNames))
    error("FAST:Sequences:MissingOperationalInput", ...
        "Every schedule must contain %s.", strjoin(Variables, ", "));
end
Same = isequaln(A(:, Variables), B(:, Variables));
end
