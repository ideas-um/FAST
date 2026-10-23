function TestPHELambdaReplay()
%
% Stress-test exact PHE mission replay across several discretizations.
%

Aircraft = AircraftSpecsPkg.ERJ175LR_Elec();
Aircraft.Specs.Aero.L_D.Method = @(Aircraft) AerodynamicsPkg.ConstantLD(Aircraft);
Aircraft = DataStructPkg.PreSpecProcessing(Aircraft);
Aircraft = DataStructPkg.SpecProcessing(Aircraft);
Aircraft.Settings.DetailedBatt = 0;
Aircraft.Specs.Aero.S = Aircraft.Specs.Weight.MTOW / ...
                        Aircraft.Specs.Aero.W_S.SLS;
Aircraft = PropulsionPkg.CreatePropArch(Aircraft);
Aircraft = PropulsionPkg.PropArchConnections(Aircraft);
Aircraft = MissionProfilesPkg.ERJ(Aircraft);
Aircraft = MissionSegsPkg.ProcessProfile(Aircraft);
Aircraft = DataStructPkg.InitMissionHistory(Aircraft);
Aircraft = PropulsionPkg.PropulsionSizing(Aircraft);

PointCases = [4, 5, 4, 4; ...
              10, 10, 10, 10; ...
              16, 12, 14, 11];

for icase = 1:size(PointCases, 1)
    Prepared = Aircraft;
    Prepared.Settings.TkoPoints = PointCases(icase, 1);
    Prepared.Settings.ClbPoints = PointCases(icase, 2);
    Prepared.Settings.CrsPoints = PointCases(icase, 3);
    Prepared.Settings.DesPoints = PointCases(icase, 4);
    Prepared.Settings.PowerManagement.Mode = "RecomputeLambda";
    Prepared = MissionProfilesPkg.ERJ(Prepared);
    Prepared = MissionSegsPkg.ProcessProfile(Prepared);

    Recomputed = DataStructPkg.InitMissionHistory(Prepared);
    Recomputed = MissionSegsPkg.FlyMission(Recomputed);

    Supplied = MissionSegsPkg.CaptureSegmentSplits(Recomputed);
    Supplied.Settings.PowerManagement.Mode = "SupplyLambda";
    Supplied = DataStructPkg.InitMissionHistory(Supplied);
    Supplied = MissionSegsPkg.FlyMission(Supplied);

    AssertMatchingHistory(Recomputed, Supplied);
    assert(all(isfinite(Supplied.Mission.History.SI.Constraints.ComponentPower), "all"));
    assert(all(isfinite(Supplied.Mission.History.SI.Constraints.PowerDeficit), "all"));
    AssertCorrectTakeoffSplitFeasible(Supplied);

    AssertBadTakeoffSplitDetected(Recomputed);
end

fprintf("PHE lambda replay stress tests passed.\n");

end

function AssertCorrectTakeoffSplitFeasible(Supplied)
%
% Ensure a recomputed maximum-power split replays without an overload.
%

Takeoff = Supplied.Mission.Profile.SegBeg(1): ...
          Supplied.Mission.Profile.SegEnd(1) - 1;
PowerDeficit = Supplied.Mission.History.SI.Constraints.PowerDeficit(Takeoff);
assert(max(PowerDeficit) < 1.0e-06);

end

function AssertBadTakeoffSplitDetected(Recomputed)
%
% Ensure maximum-power takeoff exposes an infeasible supplied PHE split.
%

Supplied = MissionSegsPkg.CaptureSegmentSplits(Recomputed);
Supplied.Settings.PowerManagement.Mode = "SupplyLambda";
Supplied.Mission.Profile.LamDwnBySegment{1}(:) = 0.90;
Supplied = DataStructPkg.InitMissionHistory(Supplied);
Supplied = MissionSegsPkg.FlyMission(Supplied);

Takeoff = Supplied.Mission.Profile.SegBeg(1): ...
          Supplied.Mission.Profile.SegEnd(1) - 1;
PowerDeficit = Supplied.Mission.History.SI.Constraints.PowerDeficit(Takeoff);
assert(any(PowerDeficit > 1.0e-06));
assert(all(isfinite(PowerDeficit)));

end

function AssertMatchingHistory(Recomputed, Supplied)
%
% Require bit-for-bit equality for all physical mission histories.
%

Reference = Recomputed.Mission.History;
Replay = Supplied.Mission.History;

assert(isequaln(Reference.SI.Performance, Replay.SI.Performance));
assert(isequaln(Reference.SI.Aero, Replay.SI.Aero));
assert(isequaln(Reference.SI.Propulsion, Replay.SI.Propulsion));
assert(isequaln(Reference.SI.Weight, Replay.SI.Weight));
assert(isequaln(Reference.SI.Power, Replay.SI.Power));
assert(isequaln(Reference.SI.Energy, Replay.SI.Energy));
assert(isequaln(Reference.Segment, Replay.Segment));
assert(isequaln(Reference.Flags, Replay.Flags));

end
