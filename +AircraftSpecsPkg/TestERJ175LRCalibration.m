function Tests = TestERJ175LRCalibration()
Tests = functiontests(localfunctions);
end

function testPublishedBaselineMatchesCurrentFAST(~)
% Verify the conventional ERJ175LR sizing against the published baseline.
% The 0.5 percent tolerance matches the accuracy claim in Cassidy et al.
% (2025), doi:10.3390/aerospace12070598.

lastwarn("");
Aircraft = Main(AircraftSpecsPkg.ERJ175LR(), ...
    @MissionProfilesPkg.ERJ_ClimbThenAccel);
[~, WarningID] = lastwarn;
assert(WarningID ~= "FAST:InfeasibleResult", ...
    "The calibrated baseline did not pass FAST feasibility checks.");

Names = ["MTOW"; "OEW"; "block fuel"];
Actual = [Aircraft.Specs.Weight.MTOW; ...
          Aircraft.Specs.Weight.OEW; ...
          Aircraft.Specs.Weight.Fuel];
Reference = [38637; 21545; 9398];
RelativeError = abs(Actual - Reference) ./ Reference;

for Index = 1:numel(Names)
    assert(RelativeError(Index) <= 0.005, ...
        "%s differs from the literature baseline by %.3f percent.", ...
        Names(Index), 100 * RelativeError(Index));
end

fprintf("ERJ175LR calibration passed: MTOW %.1f kg, OEW %.1f kg, fuel %.1f kg.\n", ...
    Actual(1), Actual(2), Actual(3));
end
