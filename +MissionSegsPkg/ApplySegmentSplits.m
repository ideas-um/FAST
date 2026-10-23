function Aircraft = ApplySegmentSplits(Aircraft, SegBeg, SegEnd, DefaultDwn, DefaultUps)
%
% Aircraft = ApplySegmentSplits(Aircraft, SegBeg, SegEnd, DefaultDwn, DefaultUps)
%
% Store the operational split histories for the current mission segment.
% Pointwise histories supplied by the mission profile take precedence over
% the aircraft's constant segment values. Adjacent segments share a control
% point; when the later segment is evaluated, its first row owns that shared
% point in the final mission history.
%
% INPUTS:
%     Aircraft  - aircraft structure containing the processed mission.
%     SegBeg    - first global control-point index for the segment.
%     SegEnd    - final global control-point index for the segment.
%     DefaultDwn - constant downstream split row used as a fallback.
%     DefaultUps - constant upstream split row used as a fallback.
%
% OUTPUTS:
%     Aircraft - aircraft with LamDwn and LamUps stored for this segment.
%

Mission = Aircraft.Mission.Profile;
SegsID = Mission.SegsID;
npoint = SegEnd - SegBeg + 1;
nDwn = size(Aircraft.Mission.History.SI.Power.LamDwn, 2);
nUps = size(Aircraft.Mission.History.SI.Power.LamUps, 2);

LamDwn = ResolveHistory(Mission, "LamDwnBySegment", SegsID, ...
                        DefaultDwn, npoint, nDwn);
LamUps = ResolveHistory(Mission, "LamUpsBySegment", SegsID, ...
                        DefaultUps, npoint, nUps);

Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;
Aircraft.Mission.History.SI.Power.LamUps(SegBeg:SegEnd, :) = LamUps;

end

function Split = ResolveHistory(Mission, FieldName, SegsID, Default, npoint, nsplit)
%
% Select a validated pointwise history or expand the constant fallback.
%

if (~isfield(Mission, FieldName))
    if (nsplit == 0)
        Split = zeros(npoint, 0);
    else
        Split = repmat(Default, npoint, 1);
    end
    return
end

Histories = Mission.(FieldName);
if (~iscell(Histories) || SegsID > numel(Histories))
    error("FAST:InvalidSegmentLambdaHistory", ...
          "%s must contain one cell per mission segment.", FieldName);
end

Split = Histories{SegsID};
if (~isnumeric(Split) || ~isequal(size(Split), [npoint, nsplit]) || ...
    any(~isfinite(Split), "all"))
    error("FAST:InvalidSegmentLambdaHistory", ...
          "%s{%d} must be a finite numeric %d-by-%d matrix.", ...
          FieldName, SegsID, npoint, nsplit);
end

end
