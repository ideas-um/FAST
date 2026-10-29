function Report = CheckMissionPowerSplits(Input, Options)
%CHECKMISSIONPOWERSPLITS Validate lambda values against mission power history.
%
%   CheckMissionPowerSplits(CheckpointFile)
%   CheckMissionPowerSplits(MissionResults)
%   Report = CheckMissionPowerSplits(..., Name=Value)
%
% A successful check prints one PASSED line. If a check fails, the
% offending mission points are displayed and returned as Report.Violations.
%
% LamUps is an availability command, while Pav already contains that
% command for the electric machines. Therefore actual full-rated
% utilization is
%
%       TrueLamUps = LamUpsCommand .* Pout ./ Pav.
%
% LamDwn is checked against the achieved parallel-branch power fractions.
% Analysis type -1 uses Pav, matching RecomputeSplits; fixed-command type
% -2 uses Pout, which confirms that the requested routing was achieved.

arguments
    Input
    Options.SequenceIndex (1,1) double = NaN
    Options.LambdaTolerance (1,1) double {mustBeNonnegative} = 1e-5
    Options.RelativePowerTolerance (1,1) double {mustBeNonnegative} = 1e-3
    Options.AbsolutePowerTolerance_W (1,1) double {mustBeNonnegative} = 10
    Options.MaxDisplayedViolations (1,1) double {mustBeInteger,mustBePositive} = 50
end

[MissionResults, SequenceIndex, Source] = LoadInput(Input, Options.SequenceIndex);
Cases = intersect(["Joint", "Individual", "Unoptimized", "Conventional"], ...
    string(fieldnames(MissionResults)), "stable");

Rows = cell(0, 17);
nChecked = 0;
for iCase = 1:numel(Cases)
    CaseName = Cases(iCase);
    for iFlight = 1:numel(MissionResults)
        R = MissionResults(iFlight).(CaseName);
        if isempty(R) || ~isfield(R, "MissionHistory") || ...
                ~isfield(R.MissionHistory, "SI")
            continue
        end
        [NewRows, Count] = CheckFlight(R, SequenceIndex, CaseName, iFlight, Options);
        Rows = [Rows; NewRows]; %#ok<AGROW>
        nChecked = nChecked + Count;
    end
end

Names = ["Sequence", "CaseName", "Flight", "MissionID", ...
    "SegmentIndex", "SegmentName", "Point", "Time_s", ...
    "Component", "Check", "LambdaRecorded", "LambdaExpected", ...
    "Pav_W", "Pout_W", "ExpectedPout_W", "LambdaError", "PowerError_W"];
if isempty(Rows)
    Violations = cell2table(cell(0, numel(Names)), "VariableNames", Names);
else
    Violations = cell2table(Rows, "VariableNames", Names);
end

Report = struct("Passed", isempty(Rows), "SequenceIndex", SequenceIndex, ...
    "Source", Source, "CheckedValues", nChecked, ...
    "ViolationCount", height(Violations), "Violations", Violations, ...
    "LambdaTolerance", Options.LambdaTolerance, ...
    "RelativePowerTolerance", Options.RelativePowerTolerance, ...
    "AbsolutePowerTolerance_W", Options.AbsolutePowerTolerance_W);

if Report.Passed
    fprintf("PASSED: mission LamDwn/LamUps power consistency (%d values checked).\n", ...
        nChecked);
else
    fprintf("FAILED: %d mission LamDwn/LamUps power-consistency violations.\n", ...
        Report.ViolationCount);
    disp(Violations(1:min(height(Violations), Options.MaxDisplayedViolations), :));
    if height(Violations) > Options.MaxDisplayedViolations
        fprintf("Displayed the first %d of %d violations.\n", ...
            Options.MaxDisplayedViolations, height(Violations));
    end
end
end


function [MissionResults, SequenceIndex, Source] = LoadInput(Input, SequenceIndex)
if ischar(Input) || (isstring(Input) && isscalar(Input))
    Source = string(Input);
    D = load(Input, "MissionResults", "RunMetadata");
    if ~isfield(D, "MissionResults")
        error("CheckMissionPowerSplits:MissingMissionResults", ...
            "Checkpoint does not contain MissionResults: %s", Input);
    end
    MissionResults = D.MissionResults;
    if isnan(SequenceIndex) && isfield(D, "RunMetadata") && ...
            isfield(D.RunMetadata, "SequenceIndex")
        SequenceIndex = D.RunMetadata.SequenceIndex;
    end
elseif isstruct(Input)
    Source = "in-memory MissionResults";
    MissionResults = Input;
else
    error("CheckMissionPowerSplits:InvalidInput", ...
        "Input must be a checkpoint filename or MissionResults struct.");
end
end


function [Rows, nChecked] = CheckFlight(R, SequenceIndex, CaseName, Flight, Options)
Rows = cell(0, 17);
nChecked = 0;
H = R.MissionHistory.SI;
if ~isfield(H, "Power") || ~all(isfield(H.Power, ...
        ["Pav", "Pout", "LamUps", "LamDwn"]))
    return
end

Pav = H.Power.Pav;
Pout = H.Power.Pout;
LamUps = H.Power.LamUps;
LamDwn = H.Power.LamDwn;
Arch = R.PropArch;
nSrc = numel(Arch.SrcType);
nTrn = numel(Arch.TrnType);
TrnCols = nSrc + (1:nTrn);
nPoint = min([size(Pav, 1), size(Pout, 1), size(LamUps, 1), size(LamDwn, 1)]);
Pav = Pav(1:nPoint, :);
Pout = Pout(1:nPoint, :);
LamUps = LamUps(1:nPoint, 1:nTrn);
LamDwn = LamDwn(1:nPoint, 1:nTrn);

% 1) Every transmitter output must remain within the stored available power.
for iTrn = 1:nTrn
    Col = TrnCols(iTrn);
    Tol = PowerTolerance(Pav(:, Col), Pout(:, Col), Options);
    Error = Pout(:, Col) - Pav(:, Col);
    Bad = find(isfinite(Error) & Error > Tol);
    nChecked = nChecked + nnz(isfinite(Error));
    for Point = Bad(:)'
        Rows(end + 1, :) = MakeRow(R, SequenceIndex, CaseName, Flight, ...
            Point, iTrn, "Pout exceeds Pav", LamUps(Point, iTrn), NaN, ...
            Pav(Point, Col), Pout(Point, Col), Pav(Point, Col), NaN, ...
            Error(Point)); %#ok<AGROW>
    end
end

% 2) Validate the saved/plotted true LamUps against command * Pout/Pav.
PoutTrn = Pout(:, TrnCols);
PavTrn = Pav(:, TrnCols);
Valid = isfinite(PoutTrn) & isfinite(PavTrn) & ...
    abs(PavTrn) > Options.AbsolutePowerTolerance_W;
Ratio = zeros(nPoint, nTrn);
Ratio(Valid) = PoutTrn(Valid) ./ PavTrn(Valid);
ExpectedTrue = LamUps .* Ratio;

if isfield(R, "TrueLamUps")
    Saved = R.TrueLamUps(1:nPoint, TrnCols);
elseif isfield(R, "LamUpsFullRatedUtilization")
    Saved = R.LamUpsFullRatedUtilization(1:nPoint, TrnCols);
else
    Saved = ExpectedTrue;
end
for iTrn = 1:nTrn
    Error = Saved(:, iTrn) - ExpectedTrue(:, iTrn);
    Bad = find(isfinite(Error) & abs(Error) > Options.LambdaTolerance);
    nChecked = nChecked + nnz(isfinite(Error));
    for Point = Bad(:)'
        Col = TrnCols(iTrn);
        Rows(end + 1, :) = MakeRow(R, SequenceIndex, CaseName, Flight, ...
            Point, iTrn, "LamUps vs Pout/Pav", Saved(Point, iTrn), ...
            ExpectedTrue(Point, iTrn), Pav(Point, Col), Pout(Point, Col), ...
            NaN, Error(Point), NaN); %#ok<AGROW>
    end
end

% 3) Re-run FAST's exact downstream topology equation from the recorded
% sink output. This includes the architecture and downstream efficiencies,
% avoiding the incorrect assumption that LamDwn is a raw Pout fraction.
ExpectedPout = ReconstructTransmitterPout(Arch, LamDwn, Pav, Pout, nSrc, ...
    Options.AbsolutePowerTolerance_W);
for iTrn = 1:nTrn
    Col = TrnCols(iTrn);
    Error = Pout(:, Col) - ExpectedPout(:, iTrn);
    Tol = PowerTolerance(Pout(:, Col), ExpectedPout(:, iTrn), Options);
    Comparable = isfinite(Error);
    Bad = find(Comparable & abs(Error) > Tol);
    nChecked = nChecked + nnz(Comparable);
    for Point = Bad(:)'
        Rows(end + 1, :) = MakeRow(R, SequenceIndex, CaseName, Flight, ...
            Point, iTrn, "LamDwn power routing", LamDwn(Point, iTrn), ...
            NaN, Pav(Point, Col), Pout(Point, Col), ...
            ExpectedPout(Point, iTrn), NaN, Error(Point)); %#ok<AGROW>
    end
end
end


function Expected = ReconstructTransmitterPout(Arch, LamDwn, Pav, Pout, nSrc, MinSinkPower)
nPoint = size(LamDwn, 1);
nTrn = size(LamDwn, 2);
Expected = nan(nPoint, nTrn);
if ~all(isfield(Arch, ["Arch", "OperDwn", "EtaDwn"]))
    return
end
nComp = size(Arch.Arch, 1);
TrnSnkCols = (nSrc + 1):nComp;
SrcTrnCols = 1:(nSrc + nTrn);
TrnCols = nSrc + (1:nTrn);
nSink = nComp - nSrc - nTrn;
if nSink < 1, return; end
for Point = 1:nPoint
    SplitDwn = PropulsionPkg.EvalSplit(Arch.OperDwn, LamDwn(Point, :));
    Seed = zeros(numel(TrnSnkCols), 1);
    Seed(end - nSink + 1:end) = Pout(Point, end - nSink + 1:end)';
    % At a zero-speed static point the sink power can be zero even though
    % the fan/transmitter shaft power is finite. The downstream routing is
    % underdetermined from Pout there, so do not manufacture a violation.
    if all(abs(Seed(end - nSink + 1:end)) <= MinSinkPower)
        continue
    end
    Routed = PropulsionPkg.PowerFlow(Seed, ...
        Arch.Arch(TrnSnkCols, TrnSnkCols)', ...
        SplitDwn(TrnSnkCols, TrnSnkCols), ...
        Arch.EtaDwn(TrnSnkCols, TrnSnkCols), -1)';
    Inactive = abs(LamDwn(Point, :)) <= 1e-12;
    Routed(find(Inactive)) = 0; %#ok<FNDSB>
    FullExpected = zeros(1, nComp);
    FullExpected(TrnSnkCols) = min(Routed, Pav(Point, TrnSnkCols));
    FullExpected(SrcTrnCols) = PropulsionPkg.PowerFlow( ...
        FullExpected(SrcTrnCols)', ...
        Arch.Arch(SrcTrnCols, SrcTrnCols)', ...
        SplitDwn(SrcTrnCols, SrcTrnCols), ...
        Arch.EtaDwn(SrcTrnCols, SrcTrnCols), -1)';
    FullExpected(TrnCols) = min(FullExpected(TrnCols), Pav(Point, TrnCols));
    Expected(Point, :) = FullExpected(TrnCols);
end
end


function Row = MakeRow(R, SequenceIndex, CaseName, Flight, Point, iTrn, ...
        Check, Recorded, Expected, Pav, Pout, ExpectedPout, LambdaError, PowerError)
[MissionID, SegmentIndex, SegmentName] = LocateSegment(R.MissionProfile, Point);
Time = NaN;
if isfield(R.MissionHistory.SI, "Performance") && ...
        isfield(R.MissionHistory.SI.Performance, "Time") && ...
        numel(R.MissionHistory.SI.Performance.Time) >= Point
    Time = R.MissionHistory.SI.Performance.Time(Point);
end
Component = TransmitterName(R.PropArch.TrnType(iTrn), iTrn);
Row = {SequenceIndex, CaseName, Flight, MissionID, SegmentIndex, ...
    SegmentName, Point, Time, Component, Check, Recorded, Expected, ...
    Pav, Pout, ExpectedPout, LambdaError, PowerError};
end


function [MissionID, SegmentIndex, SegmentName] = LocateSegment(Profile, Point)
SegmentIndex = find(Profile.SegBeg <= Point & Profile.SegEnd >= Point, 1, "first");
if isempty(SegmentIndex)
    MissionID = NaN;
    SegmentIndex = NaN;
    SegmentName = "Unknown";
    return
end
MissionID = Profile.ID(SegmentIndex);
SegmentName = string(Profile.Segs(SegmentIndex));
end


function Name = TransmitterName(Type, Index)
Names = ["Electric motor", "Gas turbine", "Propulsor", ...
    "Gearbox", "Cable", "Quasi-sink"];
if isfinite(Type) && Type >= 0 && Type <= 5
    Name = sprintf("%s %d", Names(Type + 1), Index);
else
    Name = sprintf("Transmitter %d", Index);
end
end


function Tol = PowerTolerance(A, B, Options)
Tol = Options.AbsolutePowerTolerance_W + ...
    Options.RelativePowerTolerance .* max(abs(A), abs(B));
end
