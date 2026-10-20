function [OptAircraft, PCbest, t, exitflag, OptimizerOutput] = MissionPowerOpt(Aircraft, ProfileFxn)
%
% OptAircraft = MissionPowerOpt(Aircraft, ProfileFxn)
% written by Emma Cassidy, emmasmit@umich.edu
% updated for mission-indexed PowerOpt scheduling
%
% Optimize the PHE electric downstream power split over the first mission
% from takeoff through the end of climb. The optimizer works on the
% mission-filled LamDwn.Miss array so it follows whatever mission profile
% is provided instead of relying on hard-coded control-point indices.
%
% INPUTS:
%   Aircraft  - Aircraft struct with desired mission conditions.
%
%   ProfileFxn - Optional mission profile function handle. Defaults to the
%                ERJ mission used by the HEA design studies.
%
% OUTPUTS:
%   OptAircraft - optimized aircraft struct.
%
%   PCbest      - optimized electric downstream split at each optimized
%                 mission point.
%
%   t           - optimizer wall time in minutes.


%% PRE-PROCESSING AND SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (nargin < 2)
    ProfileFxn = @MissionProfilesPkg.ERJ;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Optimizer Settings         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MaxOptIter = 100;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptMaxIter")
    MaxOptIter = Aircraft.Settings.PowerOptMaxIter;
end

% Each evaluation is stateless, so finite-difference points can run safely
% on parallel workers. Allow callers to disable parallel evaluation when a
% process pool is unavailable or unreliable.
UseParallel = true;
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "PowerOptUseParallel")
    UseParallel = logical(Aircraft.Settings.PowerOptUseParallel);
end
options = optimoptions("fmincon", ...
                       "MaxIterations", MaxOptIter, ...
                       "Display", "iter", ...
                       "Algorithm", "sqp", ...
                       "UseParallel", UseParallel);

% Objective convergence tolerance. FAST's nested mission solves use
% approximately 1e-6 relative state tolerances, so callers may select a
% compatible scaled-objective tolerance rather than forcing SQP to chase
% numerical noise.
OptimalityTolerance = 1.0e-6;
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "PowerOptOptimalityTolerance")
    OptimalityTolerance = Aircraft.Settings.PowerOptOptimalityTolerance;
end
options.OptimalityTolerance = OptimalityTolerance;

FunctionTolerance = 1.0e-6;
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "PowerOptFunctionTolerance")
    FunctionTolerance = Aircraft.Settings.PowerOptFunctionTolerance;
end
options.FunctionTolerance = FunctionTolerance;

ConstraintTolerance = 1.0e-6;
if isfield(Aircraft, "Settings") && ...
        isfield(Aircraft.Settings, "PowerOptConstraintTolerance")
    ConstraintTolerance = Aircraft.Settings.PowerOptConstraintTolerance;
end
options.ConstraintTolerance = ConstraintTolerance;

% step size convergence
options.StepTolerance = 1.0e-9;

% Match SequencePowerOpt's evaluation allowance.
options.MaxFunctionEvaluations = 1.0e9;

% Fuel burn is thousands of kilograms while the design variables are unit
% fractions. Scale the objective so SQP's optimality test is well
% conditioned without changing the physical optimum.
ObjectiveScale = 1.0e4;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Aircraft Settings          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run off-design mission so the optimizer changes mission power splits
% without resizing the aircraft inside each objective evaluation.
Aircraft.Settings.Analysis.Type = -2;
Aircraft.Settings.Analysis.FuelRelaxation = 0.5;
Aircraft.Settings.Analysis.ConvergenceTolerance = 1.0e-5;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% The optimizer supplies and constrains the mission-indexed power split.
Aircraft.Settings.PowerOpt = 1;

% no mission history table
Aircraft.Settings.Table = 0;

% If this aircraft has already completed a regular off-design flight, keep
% its feasible operational dispatch as the optimizer seed. Preparation
% rebuilds mission history, so capture the flown schedule first.
InitialFlownLamDwn = [];
InitialFlownPout = [];
if isfield(Aircraft, "Mission") && isfield(Aircraft.Mission, "History") && ...
        isfield(Aircraft.Mission.History, "SI") && ...
        isfield(Aircraft.Mission.History.SI, "Power") && ...
        isfield(Aircraft.Mission.History.SI.Power, "LamDwn")
    InitialFlownLamDwn = Aircraft.Mission.History.SI.Power.LamDwn;
    if isfield(Aircraft.Mission.History.SI.Power, "Pout")
        InitialFlownPout = Aircraft.Mission.History.SI.Power.Pout;
    end
end

% Build the same mission and propulsion metadata Main will use. This lets
% the optimizer derive the takeoff-through-cruise point range from the
% actual mission profile instead of stale hard-coded indices.
Aircraft0 = PrepareMissionAircraft(Aircraft, ProfileFxn);

% Use the same takeoff-through-climb control horizon as SequencePowerOpt.
pts = FirstMissionTakeoffThroughClimb(Aircraft0);

% Keep the optimization and feasibility horizon on the revenue mission.
% Reserve/diversion segments remain in the flown profile for reporting, but
% they must not be included in the single-mission sequence objective.
MainSegs = find(Aircraft0.Mission.Profile.ID == 1);
if isempty(MainSegs)
    error("ERROR - MissionPowerOpt: mission profile does not contain main mission ID 1.");
end
MainEnd = Aircraft0.Mission.Profile.SegEnd(MainSegs(end));
SOCConstraintPts = unique([pts; MainEnd]);
nMissionPts = Aircraft0.Mission.Profile.SegEnd(end);
nComponents = length(Aircraft0.Specs.Propulsion.PropArch.Arch);
% Only the detailed ground-roll model solves takeoff from available power.
% Regular EvalTakeoff prescribes the trajectory, so it must satisfy the
% same component power constraints as every other mission segment.
TakeoffSegsAll = find(strcmpi(Aircraft0.Mission.Profile.Segs, "DetailedTakeoff"));
TakeoffPtsAll = [];
for iseg = TakeoffSegsAll(:).'
    TakeoffPtsAll = [TakeoffPtsAll, ...
        Aircraft0.Mission.Profile.SegBeg(iseg): ...
        Aircraft0.Mission.Profile.SegEnd(iseg)]; %#ok<AGROW>
end
TakeoffPtsAll = unique(TakeoffPtsAll);

% Only takeoff/climb points are optimization variables. Preserve the
% complete regular -1 dispatch everywhere else so the optimizer contains
% the regular off-design flight as a genuine candidate instead of silently
% reverting uncontrolled rows to the design/default LamDwn schedule.
if ~isempty(InitialFlownLamDwn) && ...
        isequal(size(InitialFlownLamDwn), ...
        size(Aircraft0.Specs.Power.LamDwn.Miss))
    % Preserve regular dispatch only within main mission 1. Reserve and
    % diversion rows remain turbine-only as established during preparation.
    UncontrolledPts = setdiff((1:MainEnd)', pts);
    Aircraft0.Specs.Power.LamDwn.Miss(UncontrolledPts, :) = ...
        InitialFlownLamDwn(UncontrolledPts, :);
    Aircraft0.Mission.History.SI.Power.LamDwn = ...
        Aircraft0.Specs.Power.LamDwn.Miss;
end

% get architecture indices used to apply a symmetric PHE split.
TrnType = Aircraft0.Specs.Propulsion.PropArch.TrnType;
iEM  = find(TrnType == 0);
iGT  = find(TrnType == 1);
iFan = find(TrnType == 2);

if (isempty(iEM) || isempty(iGT) || isempty(iFan))
    error("ERROR - MissionPowerOpt: PowerOpt currently expects a PHE architecture with engines, electric motors, and fans.");
end

% Parallel transmitters each receive the full architecture split value;
% recover the common electric split without summing duplicate columns.
nsrc = length(Aircraft0.Specs.Propulsion.PropArch.SrcType);
if ~isempty(InitialFlownLamDwn) && ...
        size(InitialFlownLamDwn, 1) >= max(pts) && ...
        size(InitialFlownLamDwn, 2) >= max(iEM)
    PC0 = mean(InitialFlownLamDwn(pts, iEM), 2);
elseif ~isempty(InitialFlownPout) && ...
        size(InitialFlownPout, 1) >= max(pts) && ...
        size(InitialFlownPout, 2) >= nsrc + max([iEM, iGT])
    FlownEM = mean(InitialFlownPout(pts, nsrc + iEM), 2);
    FlownGT = mean(InitialFlownPout(pts, nsrc + iGT), 2);
    FlownTotal = FlownEM + FlownGT;
    PC0 = zeros(size(FlownTotal));
    Powered = isfinite(FlownTotal) & FlownTotal > 1.0;
    PC0(Powered) = FlownEM(Powered) ./ FlownTotal(Powered);
else
    PC0 = mean(Aircraft0.Specs.Power.LamDwn.Miss(pts, iEM), 2);
end
PC0(isnan(PC0)) = 0;
PC0 = min(max(PC0, 0), 1);
% Start from the aircraft's design-assist schedule.  A zero-assist seed can
% trap SQP at the conventional corner even when battery energy is available.

% Match SequencePowerOpt: PC is the total electric fraction and may reach 1.
lb = zeros(size(PC0));
ub = ones(size(PC0));

% A schedule that was feasible under adaptive -1 dispatch can overload a
% component when held fixed in -2 mode. Start from the flown dispatch, then
% move only overloaded points into the feasible fixed-split interval.
PC0 = ProjectInitialPointToFixedSplitFeasibility(PC0);
PC0 = ProjectInitialPointToMissionFeasibility(PC0);

% fmincon evaluates the objective and nonlinear constraints at many of the
% same finite-difference points. Cache complete mission evaluations so each
% unique split schedule is flown only once.
EvalCache = containers.Map("KeyType", "char", "ValueType", "any");

%% RUN THE OPTIMIZER %%
%%%%%%%%%%%%%%%%%%%%%%

tic
if (MaxOptIter < 1)
    % Smoke-test path: evaluate the current mission split without launching
    % fmincon's finite-difference loop.
    PCbest = PC0;
    ObjFunc(PCbest);
    [FinalConstraints, ~] = Cons(PCbest);
    exitflag = double(max(FinalConstraints, [], "all") <= options.ConstraintTolerance);
    OptimizerOutput = struct("iterations", 0, "constrviolation", ...
        max(FinalConstraints, [], "all"));
else
    [PCbest, ~, exitflag, OptimizerOutput] = fmincon( ...
        @(PC) ObjFunc(PC), PC0, [], [], [], [], lb, ub, @(PC) Cons(PC), options);
    [FinalConstraints, ~] = Cons(PCbest);
    MaxConstraint = max(FinalConstraints, [], "all");
    % SQP can terminate on an infeasible final trial while returning an
    % earlier feasible accepted point in output.bestfeasible. Replay that
    % point explicitly before declaring failure.
    if MaxConstraint > options.ConstraintTolerance && ...
            isfield(OptimizerOutput, "bestfeasible") && ...
            isstruct(OptimizerOutput.bestfeasible) && ...
            isfield(OptimizerOutput.bestfeasible, "x") && ...
            ~isempty(OptimizerOutput.bestfeasible.x)
        BestFeasiblePC = OptimizerOutput.bestfeasible.x;
        [BestConstraints, ~] = Cons(BestFeasiblePC);
        BestMaxConstraint = max(BestConstraints, [], "all");
        if BestMaxConstraint <= options.ConstraintTolerance
            PCbest = BestFeasiblePC;
            MaxConstraint = BestMaxConstraint;
            OptimizerOutput.UsedBestFeasible = true;
        end
    end
    OptimizerOutput.ReplayMaxConstraint = MaxConstraint;

    % The projected regular off-design seed is a feasible candidate. Never
    % return a higher-fuel feasible local point than that seed.
    [InitialConstraints, ~] = Cons(PC0);
    InitialMaxConstraint = max(InitialConstraints, [], "all");
    InitialObjective = ObjFunc(PC0);
    FinalObjective = ObjFunc(PCbest);
    if InitialMaxConstraint <= options.ConstraintTolerance && ...
            InitialObjective < FinalObjective
        PCbest = PC0;
        MaxConstraint = InitialMaxConstraint;
        OptimizerOutput.UsedFeasibleInitialPoint = true;
        OptimizerOutput.ReplayMaxConstraint = MaxConstraint;
    end
    if MaxConstraint > options.ConstraintTolerance || exitflag < 0
        error("OptimizationPkg:MissionPowerOpt:NoFeasibleSolution", ...
            "Mission optimizer did not produce a feasible result " + ...
            "(exit flag %d, maximum scaled constraint %.6g).", ...
            exitflag, MaxConstraint);
    elseif exitflag == 0
        warning("OptimizationPkg:MissionPowerOpt:IterationLimit", ...
            "Mission optimizer reached its iteration limit; returning " + ...
            "the best feasible point (maximum scaled constraint %.6g).", ...
            MaxConstraint);
    end
end
t = toc / 60;


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

OptAircraft = ApplyPowerSplit(Aircraft0, PCbest);
OptAircraft = FlyFixedAircraft(OptAircraft);
OptAircraft = RecordUpstreamUtilization(OptAircraft);

fburnOG  = ObjFunc(PC0) .* ObjectiveScale;
fburnOpt = ObjFunc(PCbest) .* ObjectiveScale;
fdiff = (fburnOpt - fburnOG) / fburnOG;
fprintf("Fuel Burn Reduction: %f\n", fdiff);


%% NESTED FUNCTIONS %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Function Evaluation        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fburnOut, SOCOut, RCOut, PowerExcessOut] = FlyAircraft(PC)
    CacheKey = sprintf("%.17g,", PC);
    if isKey(EvalCache, CacheKey)
        Cached = EvalCache(CacheKey);
        fburnOut = Cached.fburn;
        SOCOut = Cached.SOC;
        RCOut = Cached.RC;
        PowerExcessOut = Cached.PowerExcess;
        return
    end

    % input updated mission split schedule
    TestAircraft = ApplyPowerSplit(Aircraft0, PC);

    try
        % Run the fixed aircraft through FAST's off-design weight analysis.
        % EAPAnalysis iterates carried fuel and takeoff mass for this mission
        % while retaining the installed battery and propulsion architecture.
        TestAircraft = FlyFixedAircraft(TestAircraft);

        if isfield(TestAircraft.Settings, "Converged") && ...
                TestAircraft.Settings.Converged == 0
            error("OptimizationPkg:MissionPowerOpt:FuelIteration", ...
                "Off-design fuel iteration did not converge.");
        end

        % fuel required for mission
        fburnOut = TestAircraft.Mission.History.SI.Weight.Fburn(MainEnd);
        if (fburnOut < 0)
            fburnOut = 1.0e10;
        end

        % Constrain SOC throughout the optimized takeoff/climb window and at
        % the end of the main mission. Reserve missions are turbine-only.
        Batt = TestAircraft.Specs.Propulsion.PropArch.SrcType == 0;
        if (any(Batt))
            SOCOut = TestAircraft.Mission.History.SI.Power.SOC( ...
                SOCConstraintPts, Batt);
        else
            SOCOut = 100;
        end

        % climb-rate constraint is applied only over the optimized window.
        RCOut = TestAircraft.Mission.History.SI.Performance.RC(pts);

        % A prescribed trajectory is feasible only when every propulsion
        % component can supply its required power at every mission point.
        PreqAll = TestAircraft.Mission.History.SI.Power.Preq;
        PowerExcessOut = max( ...
            PreqAll - TestAircraft.Mission.History.SI.Power.Pav, ...
            PreqAll - TestAircraft.Mission.History.SI.Power.Pout);
        PowerExcessOut(~isfinite(PowerExcessOut)) = 0;
        % This optimizer controls only main mission 1. Reserve/diversion
        % rows use their independent fuel-only dispatch and must not make a
        % main-mission candidate infeasible.
        PowerExcessOut(MainEnd + 1:end, :) = 0;
        % Detailed takeoff uses available power and solves the ground-roll
        % distance. Its back-propagated Preq is not an independent component
        % feasibility constraint.
        PowerExcessOut(TakeoffPtsAll, :) = 0;
        if max(PowerExcessOut, [], "all") > 1
            % The prescribed trajectory may still reach its final time,
            % but this PC schedule is physically invalid for the fixed
            % installed propulsion system. Reject the optimizer evaluation.
            fburnOut = 1.0e10;
        end

    catch
        % Penalize failed mission evaluations and return constraint values
        % that fmincon will reject.
        fburnOut = 1.0e10;
        nBatt = max(1, sum(Aircraft0.Specs.Propulsion.PropArch.SrcType == 0));
        SOCOut = -ones(length(SOCConstraintPts), nBatt);
        RCOut = Aircraft0.Specs.Performance.RCMax + ones(size(pts));
        PowerExcessOut = 1e15 * ones(nMissionPts, nComponents);
    end


    EvalCache(CacheKey) = struct( ...
        "fburn", fburnOut, "SOC", SOCOut, "RC", RCOut, ...
        "PowerExcess", PowerExcessOut);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Fixed-Aircraft Mission     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OutAircraft = FlyFixedAircraft(InAircraft)
    MaxFuelIter = 50;
    if isfield(InAircraft.Settings, "PowerOptFuelMaxIter")
        MaxFuelIter = InAircraft.Settings.PowerOptFuelMaxIter;
    end

    % Re-converge carried fuel and takeoff mass for every candidate power
    % schedule. Type -2 holds the installed aircraft fixed and preserves the
    % optimizer's commanded LamDwn schedule.
    [~, OutAircraft] = evalc( ...
        "EAPAnalysis(InAircraft, -2, MaxFuelIter)");
    if ~isfield(OutAircraft.Settings, "Converged") || ...
            OutAircraft.Settings.Converged == 0
        error("OptimizationPkg:MissionPowerOpt:FuelIteration", ...
            "Off-design fuel/MTOW iteration did not converge.");
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC)
    [val, ~, ~, ~] = FlyAircraft(PC);
    val = val ./ ObjectiveScale;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Constraints                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c, ceq] = Cons(PC)
    [~, SOC, dh_dt, PowerExcess] = FlyAircraft(PC);

    % Enforce the lower SOC bound throughout the controlled window and at
    % the end of the main mission. Fuel minimization is left to determine
    % how much battery energy is economically useful; 20% is not imposed as
    % a terminal equality.
    cSOC = Aircraft0.Specs.Battery.MinSOC - SOC(:);
    cRC = dh_dt(:) - Aircraft0.Specs.Performance.RCMax;

    % output constraints
    % Scale watts to megawatts for a numerically balanced constraint while
    % preserving the physical condition Preq <= Pav.
    c = [cSOC; cRC; PowerExcess(:) / 1e6];
    ceq = [];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Split Application          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [OutAircraft] = ApplyPowerSplit(InAircraft, PC)
    OutAircraft = InAircraft;

    % FAST assigns the complete split to every parallel motor/turbine.
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iEM) = ...
        repmat(PC, 1, length(iEM));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iGT) = ...
        repmat(1 - PC, 1, length(iGT));

    % Keep fan demand evenly distributed for the PHE twin-fan architecture.
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iFan) = repmat(0.5, length(pts), length(iFan));

    % LamUps is installed availability, not achieved loading. Keep it at one
    % throughout takeoff/climb; LamDwn alone controls actual routing.
    OutAircraft.Specs.Power.LamUps.Miss(pts, :) = 1;
end


function PC = ProjectInitialPointToFixedSplitFeasibility(PC)
    for iProject = 1:3
        % A tiny positive command exposes full installed motor availability
        % while the feasible interval is being calculated.
        ProbePC = PC;
        ProbePC(ProbePC == 0) = 1.0e-9;
        ProbeAircraft = ApplyPowerSplit(Aircraft0, ProbePC);
        ProbeAircraft = FlyFixedAircraft(ProbeAircraft);

        Preq = ProbeAircraft.Mission.History.SI.Power.Preq;
        Pav = ProbeAircraft.Mission.History.SI.Power.Pav;
        GTReq = mean(Preq(pts, nsrc + iGT), 2);
        EMReq = mean(Preq(pts, nsrc + iEM), 2);
        GTPav = mean(Pav(pts, nsrc + iGT), 2);
        EMPav = mean(Pav(pts, nsrc + iEM), 2);
        TotalReq = GTReq + EMReq;

        Powered = isfinite(TotalReq) & TotalReq > 1.0;
        Lower = zeros(size(PC));
        Upper = ones(size(PC));
        Lower(Powered) = max(0, 1 - GTPav(Powered) ./ TotalReq(Powered));
        Upper(Powered) = min(1, EMPav(Powered) ./ TotalReq(Powered));

        % If the fixed aircraft has insufficient total installed power,
        % retain the closest possible split and let the normal constraint
        % reporting identify the infeasible point.
        FeasibleBand = Lower <= Upper;
        PC(FeasibleBand) = min(max(PC(FeasibleBand), ...
            Lower(FeasibleBand) + 1.0e-8), Upper(FeasibleBand) - 1.0e-8);
        PC = min(max(PC, 0), 1);
    end
end


function PC = ProjectInitialPointToMissionFeasibility(PC)
    FullPC = PC;
    if IsFeasiblePC(FullPC)
        return
    end

    LowPC = ProjectInitialPointToFixedSplitFeasibility(zeros(size(PC)));
    if ~IsFeasiblePC(LowPC)
        % Retain the closest physical split and let fmincon/normal error
        % reporting diagnose a mission with no feasible fixed-command seed.
        PC = FullPC;
        return
    end

    LowScale = 0;
    HighScale = 1;
    for iBisect = 1:12
        TestScale = 0.5 * (LowScale + HighScale);
        TestPC = LowPC + TestScale .* (FullPC - LowPC);
        TestPC = ProjectInitialPointToFixedSplitFeasibility(TestPC);
        if IsFeasiblePC(TestPC)
            LowScale = TestScale;
            LowPC = TestPC;
        else
            HighScale = TestScale;
        end
    end
    PC = LowPC;

    function Feasible = IsFeasiblePC(TestPC)
        TestAircraft = ApplyPowerSplit(Aircraft0, TestPC);
        try
            TestAircraft = FlyFixedAircraft(TestAircraft);
            BattLocal = TestAircraft.Specs.Propulsion.PropArch.SrcType == 0;
            if any(BattLocal)
                SOCMinLocal = min(TestAircraft.Mission.History.SI.Power.SOC( ...
                    SOCConstraintPts, BattLocal), [], "all");
            else
                SOCMinLocal = 100;
            end
            RCLocal = TestAircraft.Mission.History.SI.Performance.RC(pts);
            PreqLocal = TestAircraft.Mission.History.SI.Power.Preq;
            ExcessLocal = max( ...
                PreqLocal - TestAircraft.Mission.History.SI.Power.Pav, ...
                PreqLocal - TestAircraft.Mission.History.SI.Power.Pout);
            ExcessLocal(~isfinite(ExcessLocal)) = 0;
            ExcessLocal(MainEnd + 1:end, :) = 0;
            ExcessLocal(TakeoffPtsAll, :) = 0;
            Feasible = SOCMinLocal >= ...
                Aircraft0.Specs.Battery.MinSOC - options.ConstraintTolerance && ...
                max(RCLocal - Aircraft0.Specs.Performance.RCMax, [], "all") <= ...
                options.ConstraintTolerance && ...
                max(ExcessLocal, [], "all") <= 1;
        catch
            Feasible = false;
        end
    end
end


function [OutAircraft] = RecordUpstreamUtilization(InAircraft)
    OutAircraft = InAircraft;

    % Postprocess the solved flight into an independent upstream utilization
    % history: actual transmitter output divided by its full available power.
    % This records component loading without changing or re-flying the
    % optimizer-controlled downstream schedule.
    nsrcLocal = length(OutAircraft.Specs.Propulsion.PropArch.SrcType);
    ntransLocal = length(OutAircraft.Specs.Propulsion.PropArch.TrnType);
    cols = nsrcLocal + (1:ntransLocal);
    Pout = OutAircraft.Mission.History.SI.Power.Pout(:, cols);
    Pav = OutAircraft.Mission.History.SI.Power.Pav(:, cols);
    Utilization = zeros(size(Pout));
    Active = isfinite(Pout) & isfinite(Pav) & (abs(Pav) > 1.0e-9);
    Utilization(Active) = Pout(Active) ./ Pav(Active);
    Utilization = min(max(Utilization, 0), 1);

    % Keep LamUps as the availability command used by -2 analysis. Store
    % achieved loading separately so post-processing cannot change the
    % optimizer's full-availability convention.
    OutAircraft.Mission.History.SI.Power.UpstreamUtilization = Utilization;
end

end


%% LOCAL HELPER FUNCTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [Aircraft] = PrepareMissionAircraft(Aircraft, ProfileFxn)
% Prepare propulsion architecture, mission profile, and Lam*.Miss arrays
% without running the full aircraft analysis.

Aircraft = DataStructPkg.PreSpecProcessing(Aircraft);
Aircraft = PropulsionPkg.CreatePropArch(Aircraft);
Aircraft = PropulsionPkg.PropArchConnections(Aircraft);
Aircraft = ProfileFxn(Aircraft);
Aircraft = MissionSegsPkg.ProcessProfile(Aircraft);
Aircraft = DataStructPkg.InitMissionHistory(Aircraft);

% Rebuild any stale mission split arrays so they match this profile length.
if isfield(Aircraft.Specs.Power.LamUps, "Miss")
    Aircraft.Specs.Power.LamUps = rmfield(Aircraft.Specs.Power.LamUps, "Miss");
end
if isfield(Aircraft.Specs.Power.LamDwn, "Miss")
    Aircraft.Specs.Power.LamDwn = rmfield(Aircraft.Specs.Power.LamDwn, "Miss");
end

Aircraft = PropulsionPkg.LamFill(Aircraft);

% Off-design optimization begins with the full installed rating available
% from every transmitter.  LamDwn.Miss independently controls actual routing.
Aircraft.Specs.Power.LamUps.Miss(:) = 1;
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
iEM = find(TrnType == 0);
Aircraft.Mission.History.SI.Power.LamUps(:) = 1;

% Reserve and diversion missions use fuel only. Their downstream schedule
% must not consume battery energy regardless of the aircraft's design splits.
ReserveSegs = find(Aircraft.Mission.Profile.ID ~= 1);
if ~isempty(ReserveSegs)
    ReservePts = [];
    for iseg = ReserveSegs(:).'
        ReservePts = [ReservePts, ...
            Aircraft.Mission.Profile.SegBeg(iseg):Aircraft.Mission.Profile.SegEnd(iseg)]; %#ok<AGROW>
    end
    ReservePts = unique(ReservePts);
    TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
    iEM = find(TrnType == 0);
    iGT = find(TrnType == 1);
    iFan = find(TrnType == 2);
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iEM) = 0;
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iGT) = 1;
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iFan) = 0.5;
    Aircraft.Mission.History.SI.Power.LamDwn = ...
        Aircraft.Specs.Power.LamDwn.Miss;
end
end


function [pts] = FirstMissionTakeoffThroughClimb(Aircraft)
% Return mission-history indices from first takeoff through final climb.

Mission = Aircraft.Mission.Profile;
MissionID = 1;

InMission = Mission.ID == MissionID;
TakeoffSegs = find(InMission & (strcmpi(Mission.Segs, "Takeoff") | strcmpi(Mission.Segs, "DetailedTakeoff")));
ClimbSegs = find(InMission & strcmpi(Mission.Segs, "Climb"));

if (isempty(TakeoffSegs) || isempty(ClimbSegs))
    error("ERROR - MissionPowerOpt: first mission must include takeoff and climb segments.");
end

SegBeg = Mission.SegBeg(TakeoffSegs(1));
% FAST shares the final climb point with the first cruise point. Exclude
% that shared endpoint so the optimizer cannot carry an electric climb
% command across the first (potentially long) cruise integration interval.
SegEnd = Mission.SegEnd(ClimbSegs(end)) - 1;
pts = (SegBeg:SegEnd)';
end
