function [tables, SelectionMetrics] = BuildRepresentativeSequenceSet( ...
        InputFile, OutputFile, Count)
%BUILDREPRESENTATIVESEQUENCESET Select schedules spanning distance/ground time.
%
% BuildRepresentativeSequenceSet()
% BuildRepresentativeSequenceSet("Sequence.mat", "Seq100Represent.mat", 100)
%
% A deterministic 10-by-10 space-filling design is applied to empirical
% percentile ranks of total sequence distance and mean between-flight ground
% time. The output keeps FAST's expected `tables` variable and records every
% selected schedule's original index for traceability.

Root = fileparts(mfilename("fullpath"));
if nargin < 1 || strlength(string(InputFile)) == 0
    InputFile = fullfile(Root, "Sequence.mat");
end
if nargin < 2 || strlength(string(OutputFile)) == 0
    OutputFile = fullfile(Root, "Seq100Represent.mat");
end
if nargin < 3 || isempty(Count), Count = 100; end
validateattributes(Count, {'numeric'}, {'scalar','integer','positive'});

D = load(char(InputFile));
if ~isfield(D, "tables") || ~iscell(D.tables) || Count > numel(D.tables)
    error("FAST:RepresentativeSequences:InvalidInput", ...
        "Input must contain at least %d schedules in cell array tables.", Count);
end
AllTables = D.tables(:);
n = numel(AllTables);
if isfield(D, "OriginalSequenceIndices") && ...
        numel(D.OriginalSequenceIndices) == n
    OriginalSequenceIndex = D.OriginalSequenceIndices(:);
else
    OriginalSequenceIndex = (1:n)';
end
Flights = zeros(n,1);
TotalDistance_nmi = nan(n,1);
MeanLegDistance_nmi = nan(n,1);
MeanGroundTime_min = nan(n,1);
TotalGroundTime_min = nan(n,1);
for k = 1:n
    T = AllTables{k};
    RequireVariables(T, ["DISTANCE","GROUND_TIME"], k);
    Flights(k) = height(T);
    TotalDistance_nmi(k) = sum(double(T.DISTANCE), "omitnan");
    MeanLegDistance_nmi(k) = mean(double(T.DISTANCE), "omitnan");
    Ground = double(T.GROUND_TIME);
    if numel(Ground) > 1, Ground = Ground(2:end); else, Ground = []; end
    MeanGroundTime_min(k) = mean(Ground, "omitnan");
    TotalGroundTime_min(k) = sum(Ground, "omitnan");
end
if any(~isfinite(TotalDistance_nmi)) || any(~isfinite(MeanGroundTime_min))
    error("FAST:RepresentativeSequences:NonfiniteMetric", ...
        "All schedules must have finite distance and between-flight ground time.");
end

DistancePercentile = EmpiricalPercentile(TotalDistance_nmi);
GroundTimePercentile = EmpiricalPercentile(MeanGroundTime_min);
Selected = SpaceFillingSelection(DistancePercentile, ...
    GroundTimePercentile, Count);
AssertNoDuplicateSchedules(AllTables(Selected));
OriginalSequenceIndices = OriginalSequenceIndex(Selected);
tables = AllTables(Selected);
SelectionOrder = (1:Count)';
SelectionMetrics = table(SelectionOrder, OriginalSequenceIndices, ...
    Flights(Selected), TotalDistance_nmi(Selected), ...
    MeanLegDistance_nmi(Selected), MeanGroundTime_min(Selected), ...
    TotalGroundTime_min(Selected), DistancePercentile(Selected), ...
    GroundTimePercentile(Selected), ...
    'VariableNames', {'RepresentativeSequenceIndex', ...
    'OriginalSequenceIndex','Flights','TotalDistance_nmi', ...
    'MeanLegDistance_nmi','MeanGroundTime_min','TotalGroundTime_min', ...
    'DistanceEmpiricalPercentile','GroundTimeEmpiricalPercentile'});
SelectionMetadata = struct( ...
    "Method", "10-by-10 percentile-space-filling nearest medoids", ...
    "InputFile", string(InputFile), "InputSequenceCount", n, ...
    "SelectedSequenceCount", Count, ...
    "DistanceMetric", "sum of DISTANCE across flights", ...
    "GroundTimeMetric", ...
        "mean GROUND_TIME across between-flight stops (first row excluded)", ...
    "Deterministic", true, "Generated", string(datetime("now")));

OutputFile = char(OutputFile);
OutputDir = fileparts(OutputFile);
if ~isempty(OutputDir) && ~isfolder(OutputDir), mkdir(OutputDir); end
save(OutputFile, "tables", "OriginalSequenceIndices", ...
    "SelectionMetrics", "SelectionMetadata", "-v7.3");
writetable(SelectionMetrics, ReplaceExtension(OutputFile, ...
    "_Selection.csv"));
MakeSelectionPlot(TotalDistance_nmi, MeanGroundTime_min, ...
    Selected, ReplaceExtension(OutputFile, "_Selection.pdf"));

fprintf("Representative sequence set saved: %s\n", OutputFile);
fprintf("Selected %d of %d schedules; distance %.1f-%.1f nmi; " + ...
    "mean ground time %.1f-%.1f min.\n", Count, n, ...
    min(TotalDistance_nmi(Selected)), max(TotalDistance_nmi(Selected)), ...
    min(MeanGroundTime_min(Selected)), max(MeanGroundTime_min(Selected)));
end


function AssertNoDuplicateSchedules(SelectedTables)
for i = 1:numel(SelectedTables)
    for j = i + 1:numel(SelectedTables)
        if SameFASTSchedule(SelectedTables{i}, SelectedTables{j})
            error("FAST:RepresentativeSequences:DuplicateSchedule", ...
                "Representative entries %d and %d are duplicate schedules.", ...
                i, j);
        end
    end
end
end


function Same = SameFASTSchedule(A, B)
Variables = {'DISTANCE','ALTITUDE_m','SPEED_mph','PAYLOAD_lb','GROUND_TIME'};
Same = isequaln(A(:, Variables), B(:, Variables));
end


function RequireVariables(T, Required, Index)
Missing = setdiff(Required, string(T.Properties.VariableNames));
if ~isempty(Missing)
    error("FAST:RepresentativeSequences:MissingVariables", ...
        "Sequence %d is missing: %s", Index, strjoin(Missing, ", "));
end
end


function P = EmpiricalPercentile(X)
[~, Order] = sort(X, "ascend");
Ranks = zeros(size(X));
Ranks(Order) = (1:numel(X))';
P = (Ranks - 0.5) / numel(X);
end


function Selected = SpaceFillingSelection(X, Y, Count)
Side = ceil(sqrt(Count));
Centers = ((1:Side) - 0.5) / Side;
[CX, CY] = ndgrid(Centers, Centers);
Targets = [CX(:), CY(:)];
% Serpentine ordering avoids favoring one edge when Count is not square.
for i = 2:2:Side
    Rows = (i-1)*Side + (1:Side);
    Targets(Rows,:) = flipud(Targets(Rows,:));
end
Targets = Targets(1:Count, :);
Selected = zeros(Count, 1);
Available = true(numel(X), 1);
for k = 1:Count
    Distance2 = (X - Targets(k,1)).^2 + (Y - Targets(k,2)).^2;
    Distance2(~Available) = Inf;
    Minimum = min(Distance2);
    Candidates = find(Distance2 == Minimum);
    % Stable tie break: lowest original sequence index.
    Selected(k) = Candidates(1);
    Available(Selected(k)) = false;
end
end


function Name = ReplaceExtension(FileName, Suffix)
[Folder, Base] = fileparts(FileName);
Name = fullfile(Folder, Base + string(Suffix));
end


function MakeSelectionPlot(AllDistance, AllGround, Selected, FileName)
Fig = figure("Visible","off","Color","w","Position",[100 100 1000 760]);
Ax = axes(Fig); hold(Ax,"on");
scatter(Ax, AllDistance, AllGround, 12, [0.72 0.72 0.72], ...
    "filled", "DisplayName", "All 864 sequences");
scatter(Ax, AllDistance(Selected), AllGround(Selected), 38, ...
    [0.0000 0.4470 0.7410], "filled", "MarkerEdgeColor", "k", ...
    "DisplayName", "Selected representative 100");
xlabel(Ax,"Total sequence distance (nmi)");
ylabel(Ax,"Mean between-flight ground time (min)");
title(Ax,"Representative sequence coverage in distance-ground-time space", ...
    "Color","k");
grid(Ax,"on"); box(Ax,"on"); legend(Ax,"Location","best");
set(Ax,"Color","w","XColor","k","YColor","k", ...
    "GridColor",[0.75 0.75 0.75]);
exportgraphics(Fig, FileName, "ContentType","vector", ...
    "BackgroundColor","white");
close(Fig);
end
