% Regression test for regular (-1) to fixed-command (-2) baseline replay.
% The reported unoptimized case must retain the prescribed PHE upstream
% availability: 100% in takeoff and no more than 30% in climb.

clearvars;
clc;

D = load(fullfile("output", "ERJ175LR_PHE_Sized.mat"), "SizedAircraft");
S = load("Sequence.mat", "tables");
Flight = S.tables{24}(1, :);
Aircraft = D.SizedAircraft;

Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
    Flight.DISTANCE, "naut mi", "m");
[~, ~, Aircraft.Specs.Performance.Vels.Crs] = ...
    MissionSegsPkg.ComputeFltCon(Flight.ALTITUDE_m, 0, "TAS", ...
    convvel(Flight.SPEED_mph, "mph", "m/s"));
Aircraft.Specs.Performance.Alts.Crs = Flight.ALTITUDE_m;
Aircraft.Specs.Weight.Payload = convmass(Flight.PAYLOAD_lb, "lbm", "kg");
Aircraft.Specs.Power.Battery.BegSOC = 100;
Aircraft.Specs.Battery.BegSOC = 100;
Aircraft.Specs.Power.LamUps.SLS = 1.00;
Aircraft.Specs.Power.LamUps.Tko = 1.00;
Aircraft.Specs.Power.LamUps.Clb = 0.30;
Aircraft.Specs.Power.LamUps.Crs = 0.00;
Aircraft.Specs.Power.LamUps.Des = 0.00;
Aircraft.Specs.Power.LamUps.Lnd = 0.00;
Aircraft.Settings.Analysis.Type = -1;
Aircraft.Settings.PowerOpt = 0;
Aircraft.Settings.PrintOut = 0;
Aircraft.Settings.Plotting = 0;
Aircraft.Settings.Table = 0;
if isfield(Aircraft.Specs.Power.LamUps, "Miss")
    Aircraft.Specs.Power.LamUps = rmfield(Aircraft.Specs.Power.LamUps, "Miss");
end
if isfield(Aircraft.Specs.Power.LamDwn, "Miss")
    Aircraft.Specs.Power.LamDwn = rmfield(Aircraft.Specs.Power.LamDwn, "Miss");
end

Regular = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
Regular.Settings.PowerOptMaxIter = 0;
Regular.Settings.PowerOptMaxStarts = 1;
Regular.Settings.PowerOptUseParallel = false;
Regular.Settings.PowerOptOptimalityTolerance = 5e-4;
Regular.Settings.PowerOptFunctionTolerance = 1e-5;
Regular.Settings.PowerOptConstraintTolerance = 1e-4;
Regular.Settings.PreserveOptimizationLamUps = true;

[Replay, ~, ~, ExitFlag, Output] = OptimizationPkg.MissionPowerOpt( ...
    Regular, @MissionProfilesPkg.ERJ_ClimbThenAccel);

Profile = Replay.Mission.Profile;
MainSegs = find(Profile.ID == 1);
TakeoffSegs = MainSegs(strcmpi(Profile.Segs(MainSegs), "Takeoff") | ...
    strcmpi(Profile.Segs(MainSegs), "DetailedTakeoff"));
ClimbSegs = MainSegs(strcmpi(Profile.Segs(MainSegs), "Climb"));
TakeoffPts = SegmentPoints(Profile, TakeoffSegs);
ClimbPts = SegmentPoints(Profile, ClimbSegs);
iEM = find(Replay.Specs.Propulsion.PropArch.TrnType == 0);
LamUps = Replay.Mission.History.SI.Power.LamUps;

TakeoffMax = max(LamUps(TakeoffPts, iEM), [], "all");
TakeoffMin = min(LamUps(TakeoffPts, iEM), [], "all");
ClimbMax = max(LamUps(ClimbPts, iEM), [], "all");
ClimbMin = min(LamUps(ClimbPts, iEM), [], "all");
Feasible = ExitFlag > 0 && ...
    Output.constrviolation <= Regular.Settings.PowerOptConstraintTolerance;

fprintf("PRESCRIBED Clb=%.6f; replay takeoff=[%.6f %.6f], climb=[%.6f %.6f]\n", ...
    Regular.Specs.Power.LamUps.Clb, TakeoffMin, TakeoffMax, ...
    ClimbMin, ClimbMax);

assert(abs(TakeoffMin - 1) <= 1e-12 && abs(TakeoffMax - 1) <= 1e-12, ...
    "Unoptimized takeoff LamUps was not preserved at 1.0.");
assert(ClimbMin >= -1e-12 && ClimbMax <= 0.30 + 1e-12, ...
    "Unoptimized climb LamUps exceeded its 0.30 cap.");

fprintf("UNOPT_REPLAY feasible=%d exit=%d constraint=%.6g " + ...
    "takeoff=[%.3f %.3f] climb=[%.3f %.3f]\n", ...
    Feasible, ExitFlag, Output.constrviolation, ...
    TakeoffMin, TakeoffMax, ClimbMin, ClimbMax);


function Points = SegmentPoints(Profile, Segments)
Points = [];
for iSeg = Segments(:).'
    Points = [Points, Profile.SegBeg(iSeg): ...
        max(Profile.SegBeg(iSeg), Profile.SegEnd(iSeg) - 1)]; %#ok<AGROW>
end
Points = unique(Points);
end
