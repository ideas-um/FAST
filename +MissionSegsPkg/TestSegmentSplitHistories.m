function TestSegmentSplitHistories()
%
% Test pointwise mission-segment split histories and constant fallbacks.
%

Aircraft.Mission.Profile.SegsID = 1;
Aircraft.Mission.Profile.LamDwnBySegment = { ...
    [1.00; 0.50; 0.25]; ...
    [0.20; 0.10; 0.00]};
Aircraft.Mission.Profile.LamUpsBySegment = { ...
    [1.00; 0.90; 0.80]; ...
    [0.70; 0.60; 0.50]};
Aircraft.Mission.History.SI.Power.LamDwn = zeros(5, 1);
Aircraft.Mission.History.SI.Power.LamUps = zeros(5, 1);

Aircraft = MissionSegsPkg.ApplySegmentSplits(Aircraft, 1, 3, 0.3, 0.4);
assert(isequal(Aircraft.Mission.History.SI.Power.LamDwn(1:3), ...
               [1.00; 0.50; 0.25]));
assert(isequal(Aircraft.Mission.History.SI.Power.LamUps(1:3), ...
               [1.00; 0.90; 0.80]));

% The later segment owns the shared third point in the final history.
Aircraft.Mission.Profile.SegsID = 2;
Aircraft = MissionSegsPkg.ApplySegmentSplits(Aircraft, 3, 5, 0.3, 0.4);
assert(isequal(Aircraft.Mission.History.SI.Power.LamDwn, ...
               [1.00; 0.50; 0.20; 0.10; 0.00]));
assert(isequal(Aircraft.Mission.History.SI.Power.LamUps, ...
               [1.00; 0.90; 0.70; 0.60; 0.50]));

% Without pointwise histories, preserve the constant segment behavior.
Fallback = Aircraft;
Fallback.Mission.Profile = rmfield(Fallback.Mission.Profile, ...
                                   ["LamDwnBySegment", "LamUpsBySegment"]);
Fallback.Mission.Profile.SegsID = 1;
Fallback = MissionSegsPkg.ApplySegmentSplits(Fallback, 1, 3, 0.3, 0.4);
assert(isequal(Fallback.Mission.History.SI.Power.LamDwn(1:3), ...
               repmat(0.3, 3, 1)));
assert(isequal(Fallback.Mission.History.SI.Power.LamUps(1:3), ...
               repmat(0.4, 3, 1)));

% Reject a history whose point count does not match the segment.
Invalid = Aircraft;
Invalid.Mission.Profile.LamDwnBySegment{1} = [1.0; 0.5];
Invalid.Mission.Profile.SegsID = 1;
FailedAsExpected = false;
try
    MissionSegsPkg.ApplySegmentSplits(Invalid, 1, 3, 0.3, 0.4);
catch Error
    FailedAsExpected = strcmp(Error.identifier, ...
                              "FAST:InvalidSegmentLambdaHistory");
end
assert(FailedAsExpected);

fprintf("Segment split-history tests passed.\n");

end
