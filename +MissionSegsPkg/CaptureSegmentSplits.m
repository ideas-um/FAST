function Aircraft = CaptureSegmentSplits(Aircraft)
%
% Aircraft = CaptureSegmentSplits(Aircraft)
%
% Copy realized mission power splits into pointwise segment inputs. This
% converts a completed RecomputeLambda mission into a profile that can be
% replayed with SupplyLambda. Both endpoints of every segment are retained;
% the later segment still owns a shared point in the assembled history.
%
% INPUTS:
%     Aircraft - aircraft with a processed profile and completed mission
%                history.
%
% OUTPUTS:
%     Aircraft - aircraft whose mission profile contains LamDwnBySegment
%                and LamUpsBySegment cell arrays.
%

Mission = Aircraft.Mission.Profile;
RequiredFields = ["Segs"; "SegBeg"; "SegEnd"];
if (~all(isfield(Mission, RequiredFields)))
    error("FAST:UnprocessedMissionProfile", ...
          "CaptureSegmentSplits requires a processed mission profile.");
end

nsegs = numel(Mission.Segs);
if (numel(Mission.SegBeg) ~= nsegs || numel(Mission.SegEnd) ~= nsegs)
    error("FAST:InvalidMissionSegments", ...
          "Mission segment bounds must contain one entry per segment.");
end

LamDwn = Aircraft.Mission.History.SI.Power.LamDwn;
LamUps = Aircraft.Mission.History.SI.Power.LamUps;
if (size(LamDwn, 1) < Mission.SegEnd(end) || ...
    size(LamUps, 1) < Mission.SegEnd(end))
    error("FAST:IncompleteLambdaHistory", ...
          "Mission split histories do not cover every segment.");
end

Mission.LamDwnBySegment = cell(nsegs, 1);
Mission.LamUpsBySegment = cell(nsegs, 1);
for iseg = 1:nsegs
    Index = Mission.SegBeg(iseg):Mission.SegEnd(iseg);
    Mission.LamDwnBySegment{iseg} = LamDwn(Index, :);
    Mission.LamUpsBySegment{iseg} = LamUps(Index, :);
end

Aircraft.Mission.Profile = Mission;

end
