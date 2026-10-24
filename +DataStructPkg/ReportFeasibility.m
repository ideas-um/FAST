function ReportFeasibility(Aircraft)
%
% ReportFeasibility(Aircraft)
%
% Print end-of-run checks that distinguish numerical sizing convergence
% from physical mission feasibility. This function reports only; it does
% not alter the aircraft, mission history, or solver result.
%
% INPUTS:
%     Aircraft - completed FAST aircraft structure containing specifications,
%                settings, and mission history.
%


%% SETUP %%
%%%%%%%%%%%

Tol = 1.0e-06;
Names = strings(0, 1);
Passed = false(0, 1);
Details = strings(0, 1);


%% NUMERICAL CONVERGENCE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

Converged = isfield(Aircraft, "Settings") && ...
            isfield(Aircraft.Settings, "Converged") && ...
            isequal(Aircraft.Settings.Converged, 1);
[Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
    "Sizing convergence", Converged, ...
    ConditionalText(Converged, ...
        "fuel, battery, and MTOW sizing iterations converged", ...
        "fuel, battery, or MTOW sizing iterations did not converge"));


%% PHYSICAL SIZING OUTPUTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[PhysicalPassed, PhysicalDetail] = CheckPhysicalOutputs(Aircraft);
[Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
    "Physical sizing outputs", PhysicalPassed, PhysicalDetail);


%% POWER AVAILABILITY %%
%%%%%%%%%%%%%%%%%%%%%%%%

[PowerPassed, PowerDetail] = CheckPowerAvailability(Aircraft, Tol);
[Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
    "Power availability", PowerPassed, PowerDetail);


%% MISSION LIMITS %%
%%%%%%%%%%%%%%%%%%%%

[Applicable, SOCPassed, SOCDetail] = CheckSOC(Aircraft, Tol);
if (Applicable)
    [Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
        "Battery SOC limits", SOCPassed, SOCDetail);
end

[Applicable, ClimbPassed, ClimbDetail] = CheckClimbRate(Aircraft, Tol);
if (Applicable)
    [Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
        "Climb-rate limit", ClimbPassed, ClimbDetail);
end

[Applicable, TakeoffPassed, TakeoffDetail] = CheckTakeoffWeight(Aircraft, Tol);
if (Applicable)
    [Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
        "Takeoff-weight limit", TakeoffPassed, TakeoffDetail);
end

[Applicable, MotorPassed, MotorDetail] = CheckMotorSizing(Aircraft, Tol);
if (Applicable)
    [Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
        "Electric-motor sizing", MotorPassed, MotorDetail);
end

[Applicable, SplitPassed, SplitDetail] = CheckPHESplits(Aircraft, Tol);
if (Applicable)
    [Names, Passed, Details] = AddCheck(Names, Passed, Details, ...
        "PHE power-split realization", SplitPassed, SplitDetail);
end


%% PRINT REPORT %%
%%%%%%%%%%%%%%%%%%

fprintf(1, "FAST Feasibility Summary:\n");
for icheck = 1:length(Names)
    Status = "PASS";
    if (~Passed(icheck))
        Status = "FAIL";
    end
    fprintf(1, "    %-4s  %s: %s\n", Status, Names(icheck), Details(icheck));
end
fprintf(1, "\n");

Failed = find(~Passed);
if (isempty(Failed))
    fprintf(1, "FAST result passed all applicable feasibility checks.\n\n");
    return
end

FailureList = join("    - " + Names(Failed) + ": " + Details(Failed), newline);
if (Converged)
    Message = sprintf("FAST converged numerically, but %d feasibility check(s) failed. Do not treat this result as feasible.\n%s", ...
        length(Failed), FailureList);
else
    Message = sprintf("FAST did not converge and %d feasibility check(s) failed. Do not use this result as a feasible design.\n%s", ...
        length(Failed), FailureList);
end
warning("FAST:InfeasibleResult", "%s", Message);

% ----------------------------------------------------------
end


function [Names, Passed, Details] = AddCheck(Names, Passed, Details, Name, Pass, Detail)
%
% Append one result while keeping report assembly uniform.
%

Names(end + 1, 1) = Name;
Passed(end + 1, 1) = Pass;
Details(end + 1, 1) = Detail;

end


function Text = ConditionalText(Condition, TrueText, FalseText)
%
% Select a diagnostic string without duplicating report construction.
%

if (Condition)
    Text = TrueText;
else
    Text = FalseText;
end

end


function [Passed, Detail] = CheckPhysicalOutputs(Aircraft)
%
% Require finite nonnegative energy-source masses and positive MTOW.
%

Passed = false;
Detail = "required weight outputs are missing";
if (~isfield(Aircraft, "Specs") || ~isfield(Aircraft.Specs, "Weight"))
    return
end

Weight = Aircraft.Specs.Weight;
Fields = ["Fuel", "Batt", "MTOW"];
if (~all(isfield(Weight, Fields)))
    return
end

Fuel = Weight.Fuel;
Batt = Weight.Batt;
MTOW = Weight.MTOW;
Passed = all(isfinite(Fuel), "all") && all(Fuel >= 0, "all") && ...
         all(isfinite(Batt), "all") && all(Batt >= 0, "all") && ...
         isscalar(MTOW) && isfinite(MTOW) && MTOW > 0;
Detail = sprintf("fuel=%g kg, battery=%g kg, MTOW=%g kg", ...
                 sum(Fuel, "all"), sum(Batt, "all"), MTOW);

end


function [Passed, Detail] = CheckPowerAvailability(Aircraft, Tol)
%
% Require realized transmitter loads and sink delivery to respect available power.
%

Passed = false;
Detail = "power-availability evidence is missing";
if (~isfield(Aircraft.Specs, "Propulsion") || ...
    ~isfield(Aircraft.Specs.Propulsion, "PropArch") || ...
    ~isfield(Aircraft.Mission.History.SI, "Power"))
    return
end

PropArch = Aircraft.Specs.Propulsion.PropArch;
Power = Aircraft.Mission.History.SI.Power;
if (~all(isfield(PropArch, ["SrcType", "TrnType"])) || ...
    ~all(isfield(Power, ["Pav", "Pout", "Req"])))
    return
end

Pav = Power.Pav;
Pout = Power.Pout;
Req = Power.Req;
nSrc = length(PropArch.SrcType);
nTrn = length(PropArch.TrnType);
TrnIndex = nSrc + (1:nTrn);
SinkIndex = nSrc + nTrn + 1;
if (~isequal(size(Pav), size(Pout)) || isempty(TrnIndex) || ...
    size(Pout, 2) < SinkIndex || size(Pout, 1) ~= numel(Req))
    return
end

TransmitterOutput = Pout(:, TrnIndex);
TransmitterAvailable = Pav(:, TrnIndex);
PositiveOutput = isfinite(TransmitterOutput) & TransmitterOutput > 0;
Available = (isfinite(TransmitterAvailable) & TransmitterAvailable > 0) | ...
            (isinf(TransmitterAvailable) & TransmitterAvailable > 0);
Shortfall = PositiveOutput & ~Available;

FiniteAvailable = PositiveOutput & isfinite(TransmitterAvailable) & ...
                  TransmitterAvailable > 0;
Ratios = TransmitterOutput(FiniteAvailable) ./ ...
         TransmitterAvailable(FiniteAvailable);
Shortfall(FiniteAvailable) = Ratios > 1 + Tol;

Req = Req(:);
SinkOutput = Pout(:, SinkIndex);
FiniteDemand = isfinite(Req) & Req > 0;
SinkValid = isfinite(SinkOutput) & SinkOutput > 0;
SinkShortfall = FiniteDemand & ~SinkValid;
SinkRatios = Req(FiniteDemand & SinkValid) ./ ...
             SinkOutput(FiniteDemand & SinkValid);
SinkShortfall(FiniteDemand & SinkValid) = SinkRatios > 1 + Tol;

AllRatios = [Ratios(:); SinkRatios(:)];
MaxRatio = NaN;
if (~isempty(AllRatios))
    MaxRatio = max(AllRatios);
end

MaxDeficit = NaN;
DeficitFailure = false;
Mode = "RecomputeLambda";
if (isfield(Aircraft.Settings, "PowerManagement") && ...
    isfield(Aircraft.Settings.PowerManagement, "Mode"))
    Mode = string(Aircraft.Settings.PowerManagement.Mode);
end
if (strcmpi(Mode, "SupplyLambda"))
    if (~isfield(Aircraft.Mission.History.SI, "Constraints") || ...
        ~isfield(Aircraft.Mission.History.SI.Constraints, "PowerDeficit"))
        DeficitFailure = true;
    else
        Deficits = Aircraft.Mission.History.SI.Constraints.PowerDeficit;
        if (isempty(Deficits) || any(~isfinite(Deficits), "all"))
            DeficitFailure = true;
        else
            MaxDeficit = max(Deficits, [], "all");
            DeficitFailure = MaxDeficit > Tol;
        end
    end
end

Checked = nnz(PositiveOutput) + nnz(FiniteDemand);
Passed = Checked > 0 && ~any(Shortfall, "all") && ...
         ~any(SinkShortfall, "all") && ~DeficitFailure;
Detail = sprintf("max required/available ratio=%g, shortfalls=%d", ...
                 MaxRatio, nnz(Shortfall) + nnz(SinkShortfall));
if (strcmpi(Mode, "SupplyLambda"))
    Detail = sprintf("%s, max PowerDeficit=%g W", Detail, MaxDeficit);
end

end


function [Applicable, Passed, Detail] = CheckSOC(Aircraft, Tol)
%
% Check battery-source SOC against the declared minimum and 100 percent.
%

Applicable = false;
Passed = false;
Detail = "battery SOC evidence is missing";
PropArch = Aircraft.Specs.Propulsion.PropArch;
if (~isfield(PropArch, "SrcType"))
    return
end
BatteryIndex = find(PropArch.SrcType == 0);
Applicable = ~isempty(BatteryIndex);
if (~Applicable)
    return
end
if (~isfield(Aircraft.Specs, "Battery") || ...
    ~isfield(Aircraft.Specs.Battery, "MinSOC") || ...
    ~isfield(Aircraft.Mission.History.SI.Power, "SOC"))
    return
end

SOC = Aircraft.Mission.History.SI.Power.SOC(:, BatteryIndex);
SOC = SOC(isfinite(SOC));
MinSOCLimit = Aircraft.Specs.Battery.MinSOC;
if (isempty(SOC) || ~isscalar(MinSOCLimit) || ~isfinite(MinSOCLimit))
    return
end

MinSOC = min(SOC);
MaxSOC = max(SOC);
Passed = MinSOC + max(Tol, 1.0) >= MinSOCLimit && MaxSOC <= 100 + Tol;
Detail = sprintf("range=[%g, %g]%%, allowed=[%g, 100]%%", ...
                 MinSOC, MaxSOC, MinSOCLimit);

end


function [Applicable, Passed, Detail] = CheckClimbRate(Aircraft, Tol)
%
% Check realized climb control points against the declared maximum rate.
%

Applicable = isfield(Aircraft.Specs.Performance, "RCMax") && ...
             isscalar(Aircraft.Specs.Performance.RCMax) && ...
             isfinite(Aircraft.Specs.Performance.RCMax);
Passed = false;
Detail = "climb-rate evidence is missing";
if (~Applicable || ~isfield(Aircraft.Mission.History.SI.Performance, "RC"))
    return
end

Segments = string(Aircraft.Mission.History.Segment);
RC = Aircraft.Mission.History.SI.Performance.RC;
Climb = strcmpi(Segments, "Climb");
Values = RC(Climb & isfinite(RC));
if (isempty(Values))
    return
end

Maximum = max(Values);
Limit = Aircraft.Specs.Performance.RCMax;
LimitTol = max(Tol, abs(Limit) * 1.0e-09);
Passed = Maximum <= Limit + LimitTol;
Detail = sprintf("maximum=%g m/s, limit=%g m/s", Maximum, Limit);

end


function [Applicable, Passed, Detail] = CheckTakeoffWeight(Aircraft, Tol)
%
% Check the first takeoff control-point weight against MTOW.
%

Applicable = isfield(Aircraft.Specs.Weight, "MTOW") && ...
             isscalar(Aircraft.Specs.Weight.MTOW) && ...
             isfinite(Aircraft.Specs.Weight.MTOW);
Passed = false;
Detail = "takeoff-weight evidence is missing";
if (~Applicable || ~isfield(Aircraft.Mission.History.SI.Weight, "CurWeight"))
    return
end

Segments = string(Aircraft.Mission.History.Segment);
Takeoff = strcmpi(Segments, "Takeoff") | strcmpi(Segments, "DetailedTakeoff");
Index = find(Takeoff, 1);
if (isempty(Index))
    return
end

GrossWeight = Aircraft.Mission.History.SI.Weight.CurWeight(Index);
Limit = Aircraft.Specs.Weight.MTOW;
LimitTol = max(Tol, abs(Limit) * 1.0e-09);
Passed = isfinite(GrossWeight) && GrossWeight <= Limit + LimitTol;
Detail = sprintf("gross weight=%g kg, MTOW=%g kg", GrossWeight, Limit);

end


function [Applicable, Passed, Detail] = CheckMotorSizing(Aircraft, Tol)
%
% Require installed motor mass to support peak simultaneous motor output.
%

PropArch = Aircraft.Specs.Propulsion.PropArch;
Applicable = isfield(PropArch, "TrnType") && any(PropArch.TrnType == 0);
Passed = false;
Detail = "electric-motor sizing evidence is missing";
if (~Applicable || ~isfield(Aircraft.Specs.Power, "P_W") || ...
    ~isfield(Aircraft.Specs.Power.P_W, "EM") || ...
    ~isfield(Aircraft.Specs.Weight, "EM"))
    return
end

nSrc = length(PropArch.SrcType);
MotorIndex = nSrc + find(PropArch.TrnType == 0);
Pout = Aircraft.Mission.History.SI.Power.Pout;
SpecificPower = Aircraft.Specs.Power.P_W.EM;
InstalledMass = Aircraft.Specs.Weight.EM;
if (isempty(Pout) || size(Pout, 2) < max(MotorIndex) || ...
    ~isscalar(SpecificPower) || ~isfinite(SpecificPower) || SpecificPower <= 0 || ...
    ~isscalar(InstalledMass) || ~isfinite(InstalledMass) || InstalledMass < 0)
    return
end

MotorPower = Pout(:, MotorIndex);
MotorPower(~isfinite(MotorPower) | MotorPower < 0) = 0;
PeakPower = max(sum(MotorPower, 2));
RequiredMass = PeakPower / SpecificPower;
Passed = InstalledMass + Tol >= RequiredMass;
Detail = sprintf("installed=%g kg, required=%g kg at peak %g W", ...
                 InstalledMass, RequiredMass, PeakPower);

end


function [Applicable, Passed, Detail] = CheckPHESplits(Aircraft, Tol)
%
% Verify bounded PHE splits and exact supplied-history realization when present.
%

PropArch = Aircraft.Specs.Propulsion.PropArch;
Applicable = isfield(PropArch, "Type") && strcmpi(PropArch.Type, "PHE");
Passed = false;
Detail = "PHE downstream split evidence is missing";
if (~Applicable || ~isfield(Aircraft.Mission.History.SI.Power, "LamDwn"))
    return
end

Realized = Aircraft.Mission.History.SI.Power.LamDwn;
if (isempty(Realized) || any(~isfinite(Realized), "all") || ...
    any(Realized < -Tol, "all") || any(Realized > 1 + Tol, "all"))
    Detail = "realized LamDwn values must be finite and within [0, 1]";
    return
end

Mode = string(Aircraft.Settings.PowerManagement.Mode);
if (strcmpi(Mode, "SupplyLambda") && ...
    isfield(Aircraft.Mission.Profile, "LamDwnBySegment"))
    Histories = Aircraft.Mission.Profile.LamDwnBySegment;
    if (~iscell(Histories) || isempty(Histories))
        return
    end
    Expected = Histories{1};
    for iseg = 2:numel(Histories)
        SegmentValues = Histories{iseg};
        Expected(end, :) = SegmentValues(1, :);
        Expected = [Expected; SegmentValues(2:end, :)]; %#ok<AGROW>
    end
    Passed = isequal(size(Expected), size(Realized)) && ...
             all(abs(Expected - Realized) <= Tol, "all");
    Detail = sprintf("%d supplied LamDwn point(s) checked", size(Realized, 1));
else
    Passed = true;
    Detail = sprintf("%d realized LamDwn point(s) are finite and bounded", ...
                     size(Realized, 1));
end

end
