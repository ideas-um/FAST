function TestReportFeasibility()
%
% TestReportFeasibility()
%
% Stress the end-of-run feasibility report across passing, individually
% failing, combined-failure, missing-evidence, and non-converged cases.
%


%% BUILD CONVERGED BASELINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

evalc("PHE = Main(AircraftSpecsPkg.ERJ175LR_Elec(), @MissionProfilesPkg.ERJ_ClimbThenAccel);");
evalc("Conventional = Main(AircraftSpecsPkg.ERJ175LR(), @MissionProfilesPkg.ERJ_ClimbThenAccel);");

AssertCase(PHE, strings(0, 1), ...
    ["FAST result passed all applicable feasibility checks."; ...
     "PHE power-split realization"]);
AssertCase(Conventional, strings(0, 1), ...
    ["FAST result passed all applicable feasibility checks."; ...
     "Power availability"]);


%% INDIVIDUAL FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%

Case = PHE;
Case.Settings.Converged = 0;
AssertCase(Case, "Sizing convergence", ...
    "FAST did not converge and 1 feasibility check(s) failed.");

Case = PHE;
Case.Specs.Weight.Fuel = -1;
AssertCase(Case, "Physical sizing outputs", "fuel=-1 kg");

Case = PHE;
Case.Mission.History.SI.Constraints.PowerDeficit(1) = 100;
AssertCase(Case, "Power availability", "max PowerDeficit=100 W");

Case = PHE;
BatteryIndex = find(Case.Specs.Propulsion.PropArch.SrcType == 0, 1);
Case.Mission.History.SI.Power.SOC(:, BatteryIndex) = ...
    Case.Specs.Battery.MinSOC - 2;
AssertCase(Case, "Battery SOC limits", ...
    sprintf("allowed=[%g, 100]%%", Case.Specs.Battery.MinSOC));

Case = PHE;
Climb = strcmpi(string(Case.Mission.History.Segment), "Climb");
Case.Mission.History.SI.Performance.RC(Climb) = ...
    Case.Specs.Performance.RCMax + 1;
AssertCase(Case, "Climb-rate limit", ...
    sprintf("maximum=%g m/s", Case.Specs.Performance.RCMax + 1));

Case = PHE;
Takeoff = strcmpi(string(Case.Mission.History.Segment), "Takeoff") | ...
          strcmpi(string(Case.Mission.History.Segment), "DetailedTakeoff");
TakeoffIndex = find(Takeoff, 1);
Case.Mission.History.SI.Weight.CurWeight(TakeoffIndex) = ...
    Case.Specs.Weight.MTOW + 100;
AssertCase(Case, "Takeoff-weight limit", ...
    sprintf("gross weight=%g kg", Case.Specs.Weight.MTOW + 100));

Case = PHE;
Case.Specs.Weight.EM = 0;
AssertCase(Case, "Electric-motor sizing", "installed=0 kg");

Case = PHE;
Case.Mission.History.SI.Power.LamDwn(1, 1) = 1.5;
AssertCase(Case, "PHE power-split realization", ...
    "realized LamDwn values must be finite and within [0, 1]");


%% MISSING EVIDENCE %%
%%%%%%%%%%%%%%%%%%%%%%

Case = PHE;
Case.Mission.History.SI.Power = rmfield(Case.Mission.History.SI.Power, "Pav");
AssertCase(Case, "Power availability", "power-availability evidence is missing");

Case = PHE;
Case.Mission.History.SI.Power.SOC(:) = NaN;
AssertCase(Case, "Battery SOC limits", "battery SOC evidence is missing");


%% COMBINED FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%

Case = PHE;
Case.Specs.Weight.Fuel = -1;
Case.Mission.History.SI.Constraints.PowerDeficit(1) = 100;
Case.Mission.History.SI.Power.SOC(:, BatteryIndex) = ...
    Case.Specs.Battery.MinSOC - 2;
Case.Mission.History.SI.Performance.RC(Climb) = ...
    Case.Specs.Performance.RCMax + 1;
Case.Mission.History.SI.Weight.CurWeight(TakeoffIndex) = ...
    Case.Specs.Weight.MTOW + 100;
Case.Specs.Weight.EM = 0;
Case.Mission.History.SI.Power.LamDwn(1, 1) = 1.5;
AssertCase(Case, ...
    ["Physical sizing outputs"; ...
     "Power availability"; ...
     "Battery SOC limits"; ...
     "Climb-rate limit"; ...
     "Takeoff-weight limit"; ...
     "Electric-motor sizing"; ...
     "PHE power-split realization"], ...
    "FAST converged numerically, but 7 feasibility check(s) failed.");

Case.Settings.Converged = 0;
AssertCase(Case, ...
    ["Sizing convergence"; ...
     "Physical sizing outputs"; ...
     "Power availability"; ...
     "Battery SOC limits"; ...
     "Climb-rate limit"; ...
     "Takeoff-weight limit"; ...
     "Electric-motor sizing"; ...
     "PHE power-split realization"], ...
    "FAST did not converge and 8 feasibility check(s) failed.");

fprintf("Feasibility reporting stress tests passed.\n");

end


function AssertCase(Aircraft, ExpectedFailures, ExpectedText)
%
% Require report text, warning identity, and failure count to agree.
%

ExpectedFailures = string(ExpectedFailures(:));
ExpectedText = string(ExpectedText(:));
lastwarn("");
Report = @() DataStructPkg.ReportFeasibility(Aircraft); %#ok<NASGU>
Log = evalc("Report();");
[WarningMessage, WarningIdentifier] = lastwarn;

FailureCount = count(Log, "    FAIL");
assert(FailureCount == length(ExpectedFailures), ...
       "Expected %d failed checks, found %d.\n%s", ...
       length(ExpectedFailures), FailureCount, Log);

for ifailure = 1:length(ExpectedFailures)
    assert(contains(Log, "FAIL  " + ExpectedFailures(ifailure)), ...
           "Missing failed check '%s'.\n%s", ExpectedFailures(ifailure), Log);
end
for itext = 1:length(ExpectedText)
    assert(contains(Log, ExpectedText(itext)) || ...
           contains(string(WarningMessage), ExpectedText(itext)), ...
           "Missing expected report text '%s'.\n%s", ExpectedText(itext), Log);
end

if (isempty(ExpectedFailures))
    assert(isempty(WarningIdentifier), ...
           "Passing result unexpectedly emitted warning %s: %s", ...
           WarningIdentifier, WarningMessage);
    assert(~contains(Log, "FAIL"));
else
    assert(strcmp(WarningIdentifier, "FAST:InfeasibleResult"), ...
           "Expected FAST:InfeasibleResult, received %s.", WarningIdentifier);
    assert(count(string(WarningMessage), "    - ") == length(ExpectedFailures));
    for ifailure = 1:length(ExpectedFailures)
        assert(contains(string(WarningMessage), ExpectedFailures(ifailure)), ...
               "Warning omitted failed check '%s'.", ExpectedFailures(ifailure));
    end
end

end
