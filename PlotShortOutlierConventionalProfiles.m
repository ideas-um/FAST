function Summary = PlotShortOutlierConventionalProfiles( ...
        SequenceFile, SequenceIndices, OutputFile)
%PLOTSHORTOUTLIERCONVENTIONALPROFILES Audit short outlier mission shapes.

Root = fileparts(mfilename("fullpath"));
if nargin < 1 || strlength(string(SequenceFile)) == 0
    SequenceFile = fullfile(Root, "Sequence.mat");
end
if nargin < 2 || isempty(SequenceIndices)
    SequenceIndices = [18 190 252 273 286 323 338 344];
end
if nargin < 3 || strlength(string(OutputFile)) == 0
    OutputFile = fullfile(Root, "Short_Outlier_Conventional_Profiles.pdf");
end

D = load(char(SequenceFile), "tables");
SequenceIndices = unique(SequenceIndices(:)', "stable");
if any(SequenceIndices < 1 | SequenceIndices > numel(D.tables))
    error("FAST:ShortMissionAudit:InvalidSequence", ...
        "A requested sequence index is outside the input file.");
end
Base = AircraftSpecsPkg.ERJ175LR();
Base.Settings.PrintOut = 0;
Base = Main(Base, @MissionProfilesPkg.ERJ_ClimbThenAccel);
if ~logical(Base.Settings.Converged)
    error("FAST:ShortMissionAudit:Sizing", ...
        "The calibrated conventional aircraft did not converge.");
end

n = numel(SequenceIndices);
Rows = cell(n, 1);
PlotData = cell(n, 1);
for i = 1:n
    Index = SequenceIndices(i);
    Sequence = D.tables{Index};
    PlotData{i} = cell(height(Sequence), 1);
    TotalTime_min = 0;
    MaximumAltitude_ft = 0;
    for k = 1:height(Sequence)
        Aircraft = ConfigureConventionalFlight(Base, Sequence(k, :));
        Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        H = Aircraft.Mission.History.SI;
        MainSegments = find(Aircraft.Mission.Profile.ID == 1);
        Last = Aircraft.Mission.Profile.SegEnd(MainSegments(end));
        Distance_nmi = H.Performance.Dist(1:Last) / 1852;
        Time_min = (H.Performance.Time(1:Last) - ...
            H.Performance.Time(1)) / 60;
        Altitude_ft = H.Performance.Alt(1:Last) / 0.3048;
        PlotData{i}{k} = struct("Distance_nmi", Distance_nmi, ...
            "Time_min", Time_min, "Altitude_ft", Altitude_ft);
        TotalTime_min = TotalTime_min + Time_min(end);
        MaximumAltitude_ft = max(MaximumAltitude_ft, max(Altitude_ft));
    end
    Rows{i} = table(Index, height(Sequence), sum(Sequence.DISTANCE), ...
        min(Sequence.DISTANCE), max(Sequence.DISTANCE), ...
        TotalTime_min, MaximumAltitude_ft, ...
        'VariableNames', {'OriginalSequenceIndex','Flights', ...
        'TotalSequenceDistance_nmi','ShortestLeg_nmi','LongestLeg_nmi', ...
        'TotalAirborneTime_min','MaximumAltitude_ft'});
end

% Main may close analysis figures internally, so create the audit figure only
% after all conventional missions have finished.
Fig = figure("Visible", "off", "Color", "w", ...
    "Position", [20 20 1500 max(700, 300*n)]);
Layout = tiledlayout(Fig, n, 2, "TileSpacing", "compact", ...
    "Padding", "compact");
Colors = lines(12);
for i = 1:n
    AxDistance = nexttile(Layout); hold(AxDistance, "on");
    AxTime = nexttile(Layout); hold(AxTime, "on");
    for k = 1:numel(PlotData{i})
        P = PlotData{i}{k};
        Color = Colors(1 + mod(k - 1, size(Colors, 1)), :);
        plot(AxDistance, P.Distance_nmi, P.Altitude_ft, ...
            "LineWidth", 1.5, "Color", Color, ...
            "DisplayName", "Flight " + k);
        plot(AxTime, P.Time_min, P.Altitude_ft, ...
            "LineWidth", 1.5, "Color", Color, ...
            "DisplayName", "Flight " + k);
    end
    Index = SequenceIndices(i);
    title(AxDistance, sprintf("Sequence %d: altitude vs distance", Index), ...
        "Color", "k");
    xlabel(AxDistance, "Flight distance (nmi)");
    ylabel(AxDistance, "Altitude (ft)");
    title(AxTime, sprintf("Sequence %d: altitude vs time", Index), ...
        "Color", "k");
    xlabel(AxTime, "Flight time (min)");
    ylabel(AxTime, "Altitude (ft)");
    StyleAxes(AxDistance); StyleAxes(AxTime);
    if i == 1, legend(AxTime, "Location", "best"); end
end
title(Layout, ...
    "Calibrated conventional ERJ175LR short-sequence trajectory audit", ...
    "Color", "k");
exportgraphics(Fig, OutputFile, "ContentType", "vector", ...
    "BackgroundColor", "white");
close(Fig);
Summary = vertcat(Rows{:});
[Folder, BaseName] = fileparts(char(OutputFile));
writetable(Summary, fullfile(Folder, BaseName + "_Summary.csv"));
end


function Aircraft = ConfigureConventionalFlight(Aircraft, Flight)
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
    Flight.DISTANCE, "naut mi", "m");
[~, ~, Aircraft.Specs.Performance.Vels.Crs] = ...
    MissionSegsPkg.ComputeFltCon(Flight.ALTITUDE_m, 0, "TAS", ...
    convvel(Flight.SPEED_mph, "mph", "m/s"));
Aircraft.Specs.Performance.Alts.Crs = Flight.ALTITUDE_m;
Aircraft.Specs.Weight.Payload = convmass(Flight.PAYLOAD_lb, "lbm", "kg");
Aircraft.Settings.Analysis.Type = -1;
Aircraft.Settings.PowerOpt = 0;
Aircraft.Settings.PrintOut = 0;
Aircraft.Settings.Plotting = 0;
Aircraft.Settings.Table = 0;
end


function StyleAxes(Ax)
grid(Ax, "on"); box(Ax, "on");
set(Ax, "Color", "w", "XColor", "k", "YColor", "k", ...
    "GridColor", [0.8 0.8 0.8]);
end
