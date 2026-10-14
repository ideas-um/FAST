function [OptimizedAircraft, PCbest, t, OptSeqTable, exitflag, OptimizerOutput] = SequencePowerOpt(Aircraft, Sequence)
%
% OptimizedAircraft = SequencePowerOpt(Aircraft, Sequence)
% written by Emma Cassidy, emmasmit@umich.edu
% updated for mission-indexed LamDwn scheduling
%
% Optimize the electric downstream power split across a sequence of
% off-design missions for a parallel-hybrid propulsion architecture.
% The optimzer used is the built in fmincon with the interior point method.
% See setup below to change optimizer paramteters.
%
%
% INPUTS: 
%   Aircraft - Aircraft struct with desired power code starting values and 
%              desired mission conditions. 
% OUTPUTS:
%   OptAircraft - optimized aircraft struct with optimial power code

%% PRE-PROCESSING AND SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% objective function selection
%if cost load cost table
PackageDir = fileparts(mfilename("fullpath"));
priceTable = readtable(fullfile(PackageDir, "..", "+CostPkg", "Energy_CostbyAirport.xlsx"));

% number of missions to fly
nflight = height(Sequence);

if nflight > 1
    IntermediateGateTimes = Sequence.GROUND_TIME(2:end);
    if any(~isfinite(IntermediateGateTimes) | IntermediateGateTimes <= 7)
        BadFlight = find(~isfinite(IntermediateGateTimes) | ...
            IntermediateGateTimes <= 7, 1) + 1;
        error("OptimizationPkg:SequencePowerOpt:InvalidGroundTimeData", ...
            ["Sequence input data are invalid: flight %d has %.3f minutes " ...
            "of preceding gate time; intermediate gate times must exceed " ...
            "the 7-minute fueling/service allowance."], ...
            BadFlight, Sequence.GROUND_TIME(BadFlight));
    end
end

% setup a table large enough for all flights
% note that 24 = number of data metrics returned (setup in varTypes/Names)
sz = [nflight, 14];

% list the variable types to be returned in the table (24 total)
varTypes = ["double", "double", "double", "double",...
            "double", "double", "double", "double", ...
            "double", "double", "double", "double", ...
             "double", "double"                               ] ;

% list the variable names to be returned in the table (24 total)
varNames = ["Segment"               , ...
            "Distance (nmi)"        , ...
            "Ground Time (min)"     , ...
            "TOGW (kg)"             , ...
            "DOC ($)"               , ...
            "Fuel Burn (kg)"        , ...
            "Batt Energy (MJ)"      , ...
            "Intial SOC (%)"        , ...
            "SOC End of Takeoff (%)", ...
            "SOC End of Climb   (%)", ...
            "Final SOC (%)"         , ...
            "Avg Tko TSFC"          , ...
            "Avg Clb TSFC"          , ...
            "Avg Crs TSFC"          ] ;

% setup the table
OptSeqTable = table('Size', sz, 'VariableTypes', varTypes, ...
                            'VariableNames', varNames) ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Optimizer Settings         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MaxOptIter = 200;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptMaxIter")
    MaxOptIter = Aircraft.Settings.PowerOptMaxIter;
end

MaxStarts = 3;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptMaxStarts")
    MaxStarts = Aircraft.Settings.PowerOptMaxStarts;
end

UseParallel = false;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptUseParallel")
    UseParallel = logical(Aircraft.Settings.PowerOptUseParallel);
end

OptimalityTolerance = 5.0e-4;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptOptimalityTolerance")
    OptimalityTolerance = Aircraft.Settings.PowerOptOptimalityTolerance;
end

% Match MissionPowerOpt's objective scaling so fuel in kilograms is well
% conditioned relative to the dimensionless nonlinear constraints.
ObjectiveScale = 1.0e4;

% Objective and constraint evaluations recompute from their explicit
% inputs, so finite-difference points can run safely on parallel workers.
options = optimoptions("fmincon", ...
                       "MaxIterations", MaxOptIter, ...
                       "Display", "iter", ...
                       "Algorithm", "sqp", ...
                       "UseParallel", UseParallel);

% objective function convergence tolerance
options.OptimalityTolerance = OptimalityTolerance;

FunctionTolerance = 1.0e-5;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptFunctionTolerance")
    FunctionTolerance = Aircraft.Settings.PowerOptFunctionTolerance;
end
options.FunctionTolerance = FunctionTolerance;

ConstraintTolerance = 5.0e-5;
if isfield(Aircraft, "Settings") && isfield(Aircraft.Settings, "PowerOptConstraintTolerance")
    ConstraintTolerance = Aircraft.Settings.PowerOptConstraintTolerance;
end
options.ConstraintTolerance = ConstraintTolerance;

% step size convergence
options.StepTolerance = 10^-9;

% max function evaluations
options.MaxFunctionEvaluations = 10^9;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Aircraft  Settings         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run off design mission
Aircraft.Settings.Analysis.Type = -2;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% no mission history table
Aircraft.Settings.Table = 0;

Aircraft.Settings.PowerOpt = 1;

% Every sequence begins with a fully charged battery. Subsequent initial
% SOC values are propagated only from the preceding flight and turnaround.
Aircraft.Specs.Power.Battery.BegSOC = 100;

% Build the mission-indexed lambda schedules used by Main, then identify
% the transmitter columns for the PHE architecture.
Aircraft = PrepareSequenceAircraft(Aircraft);
% Preserve the certified/sized-aircraft takeoff-weight limit. Candidate
% evaluations below iterate the actual carried fuel and takeoff mass, so
% Aircraft.Specs.Weight.MTOW is no longer a suitable structural limit.
DesignMTOWLimit = Aircraft.Specs.Weight.MTOW;
pts = FirstMissionTakeoffThroughClimb(Aircraft);
MainSegs = find(Aircraft.Mission.Profile.ID == 1);
if isempty(MainSegs)
    error("ERROR - SequencePowerOpt: mission profile does not contain main mission ID 1.");
end
MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
SOCConstraintPts = unique([pts; MainEnd]);
nMissionPts = Aircraft.Mission.Profile.SegEnd(end);
nComponents = length(Aircraft.Specs.Propulsion.PropArch.Arch);

% Detailed takeoff solves its ground roll from available power. Its
% back-propagated component Preq is therefore not an independent constraint.
DetailedTakeoffSegs = find(strcmpi(Aircraft.Mission.Profile.Segs, "DetailedTakeoff"));
DetailedTakeoffPts = [];
for iDetailedSeg = DetailedTakeoffSegs(:).'
    DetailedTakeoffPts = [DetailedTakeoffPts, ...
        Aircraft.Mission.Profile.SegBeg(iDetailedSeg): ...
        Aircraft.Mission.Profile.SegEnd(iDetailedSeg)]; %#ok<AGROW>
end
DetailedTakeoffPts = unique(DetailedTakeoffPts);

TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
iEM  = find(TrnType == 0);
iGT  = find(TrnType == 1);
iFan = find(TrnType == 2);

if (isempty(iEM) || isempty(iGT) || isempty(iFan))
    error("ERROR - SequencePowerOpt: expected a PHE architecture with engines, electric motors, and fans.");
end

% Use one electric-assist control per mission point and flight. Parallel
% transmitters each receive the full architecture split value.
PC = mean(Aircraft.Specs.Power.LamDwn.Miss(pts, iEM), 2);
PC(isnan(PC)) = 0;
PC = min(max(PC, 0), 1);
PC0 = repmat(PC, 1, nflight);
FlightFuelSeed = repmat(Aircraft.Specs.Weight.Fuel, nflight, 1);
FlightMTOWSeed = repmat(Aircraft.Specs.Weight.MTOW, nflight, 1);
LastEvaluationFailure = "";
EvalCache = containers.Map("KeyType", "char", "ValueType", "any");
% Generate the sequence starting point from a normal Type -1 off-design
% replay. This mirrors MissionPowerOpt's use of a flown feasible schedule,
% while preserving SOC/ground-charge coupling across all flights.
[FlownPC0, MinimumPC0, FlightFuelSeedCandidate, ...
    FlightMTOWSeedCandidate, FlightLamDwnSeed, ...
    FlownSeedValid, FlownSeedFailure] = ...
    BuildFlownSequenceSeed(Aircraft, Sequence, PC0);
if FlownSeedValid
    FlightFuelSeed = FlightFuelSeedCandidate;
    FlightMTOWSeed = FlightMTOWSeedCandidate;
    [ProjectedPC0, ProjectedSeedValid] = FindFeasibleSequenceSeed( ...
        FlownPC0, MinimumPC0, Aircraft, Sequence);
    if ProjectedSeedValid
        PC0 = ProjectedPC0;
        PCFloor = MinimumPC0;
    else
        PC0 = FlownPC0;
        PCFloor = PC0;
    end
else
    error("OptimizationPkg:SequencePowerOpt:SeedFailure", ...
        "The regular -1 sequence seed failed: %s", FlownSeedFailure);
end

% A caller that supplies a previously converged per-flight control schedule
% must also be able to supply the corresponding fixed-aircraft weight
% states.  Otherwise the controls are replayed at the regular/unoptimized
% sequence weights, so the advertised initial point is not the same point
% that MissionPowerOpt produced (especially after SOC carryover changes).
if isfield(Aircraft.Settings, "PowerOptInitialFuel_kg") || ...
        isfield(Aircraft.Settings, "PowerOptInitialMTOW_kg")
    if ~(isfield(Aircraft.Settings, "PowerOptInitialFuel_kg") && ...
            isfield(Aircraft.Settings, "PowerOptInitialMTOW_kg"))
        error("OptimizationPkg:SequencePowerOpt:InitialWeightState", ...
            ["PowerOptInitialFuel_kg and PowerOptInitialMTOW_kg must be " ...
            "provided together."]);
    end
    RequestedFuelSeed = Aircraft.Settings.PowerOptInitialFuel_kg(:);
    RequestedMTOWSeed = Aircraft.Settings.PowerOptInitialMTOW_kg(:);
    if numel(RequestedFuelSeed) ~= nflight || ...
            numel(RequestedMTOWSeed) ~= nflight || ...
            any(~isfinite(RequestedFuelSeed)) || ...
            any(~isfinite(RequestedMTOWSeed)) || ...
            any(RequestedFuelSeed <= 0) || any(RequestedMTOWSeed <= 0)
        error("OptimizationPkg:SequencePowerOpt:InitialWeightState", ...
            ["Initial fuel and MTOW states must each contain %d finite, " ...
            "positive values."], nflight);
    end
    FlightFuelSeed = RequestedFuelSeed;
    FlightMTOWSeed = RequestedMTOWSeed;
end

% Callers may provide a previously flown/optimized schedule for the whole
% sequence. Clamp it to the turbine-required electric floor and project it
% through the same complete-sequence feasibility check before using it.
if isfield(Aircraft.Settings, "PowerOptInitialPC")
    RequestedPC0 = Aircraft.Settings.PowerOptInitialPC;
    if isequal(size(RequestedPC0), size(PC0)) && all(isfinite(RequestedPC0), "all")
        % Test the requested schedule itself before applying any fallback
        % projection.  Clamping it to the turbine floor derived from the
        % regular/unoptimized seed changes a known-feasible MissionPowerOpt
        % result and means the joint optimizer never starts from that point.
        RequestedPC0 = min(max(RequestedPC0, 0), 1);
        [RequestedPC0, RequestedSeedValid] = FindFeasibleSequenceSeed( ...
            RequestedPC0, MinimumPC0, Aircraft, Sequence);
        if RequestedSeedValid
            PC0 = RequestedPC0;
        end
    else
        error("OptimizationPkg:SequencePowerOpt:InitialPCSize", ...
            "Settings.PowerOptInitialPC must be a finite %d-by-%d array.", ...
            size(PC0, 1), size(PC0, 2));
    end
end
lb = zeros(size(PC0));
ub = ones(size(PC0));
%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
if MaxOptIter < 1
    % A zero-iteration setting is a useful deterministic smoke-test mode:
    % replay the complete sequence at its initialized schedule without
    % claiming an optimized solution.
    PCbest = PC0;
    [ReplayObjective, ReplaySOC, ReplayRC, ReplayPowerExcess, ...
        ReplayMTOWExcess, ValidReplay] = FlySequence(PCbest, Aircraft, Sequence);
    ReplayConstraints = SequenceConstraints(ReplaySOC, ReplayRC, ...
        ReplayPowerExcess, ReplayMTOWExcess, Aircraft);
    MaxConstraint = max(ReplayConstraints, [], "all");
    exitflag = 0;
    OptimizerOutput = struct("iterations", 0, "algorithm", "sequence replay", ...
        "message", "Zero-iteration sequence smoke test.", ...
        "ReplayObjective_kg", ReplayObjective, "MaxConstraint", MaxConstraint, ...
        "Feasible", ValidReplay && MaxConstraint <= options.ConstraintTolerance);
    % This branch is explicitly a replay/debug mode, not a claim of
    % optimizer convergence. Return any physically completed replay so its
    % constraint margins can be inspected by tests and callers.
    Converged = ValidReplay && isfinite(ReplayObjective) && ReplayObjective < 1e14;
else
    StartPoints = BuildStartPoints(PC0, PCFloor, MaxStarts);
    Attempts = repmat(struct("Start", 0, "ExitFlag", NaN, "Iterations", NaN, ...
        "Objective_kg", NaN, "MaxConstraint", Inf, "ValidReplay", false), ...
        numel(StartPoints), 1);
    Converged = false;

    for iStart = 1:numel(StartPoints)
        [CandidatePC, ~, CandidateExitFlag, CandidateOutput] = ...
            fmincon(@(PC) ObjFunc(PC, Aircraft, Sequence), StartPoints{iStart}, ...
            [], [], [], [], lb, ub, @(PC) Cons(PC, Aircraft, Sequence), options);

        [ReplayObjective, ReplaySOC, ReplayRC, ReplayPowerExcess, ...
            ReplayMTOWExcess, ValidReplay] = ...
            FlySequence(CandidatePC, Aircraft, Sequence);
        ReplayConstraints = SequenceConstraints(ReplaySOC, ReplayRC, ...
            ReplayPowerExcess, ReplayMTOWExcess, Aircraft);
        MaxConstraint = max(ReplayConstraints, [], "all");

        if (~ValidReplay || MaxConstraint > options.ConstraintTolerance) && ...
                isfield(CandidateOutput, "bestfeasible") && ...
                isstruct(CandidateOutput.bestfeasible) && ...
                isfield(CandidateOutput.bestfeasible, "x") && ...
                ~isempty(CandidateOutput.bestfeasible.x)
            BestFeasiblePC = CandidateOutput.bestfeasible.x;
            [BestObjective, BestSOC, BestRC, BestPowerExcess, ...
                BestMTOWExcess, BestValid] = ...
                FlySequence(BestFeasiblePC, Aircraft, Sequence);
            BestConstraints = SequenceConstraints(BestSOC, BestRC, ...
                BestPowerExcess, BestMTOWExcess, Aircraft);
            BestMaxConstraint = max(BestConstraints, [], "all");
            if BestValid && BestMaxConstraint <= options.ConstraintTolerance
                CandidatePC = BestFeasiblePC;
                ReplayObjective = BestObjective;
                MaxConstraint = BestMaxConstraint;
                ValidReplay = true;
                CandidateOutput.UsedBestFeasible = true;
            end
        end

        Attempts(iStart).Start = iStart;
        Attempts(iStart).ExitFlag = CandidateExitFlag;
        Attempts(iStart).Iterations = CandidateOutput.iterations;
        Attempts(iStart).Objective_kg = ReplayObjective;
        Attempts(iStart).MaxConstraint = MaxConstraint;
        Attempts(iStart).ValidReplay = ValidReplay;

        if CandidateExitFlag > 0 && ValidReplay && ...
                isfinite(ReplayObjective) && ReplayObjective < 1e14 && ...
                MaxConstraint <= options.ConstraintTolerance
            PCbest = CandidatePC;
            exitflag = CandidateExitFlag;
            OptimizerOutput = CandidateOutput;
            OptimizerOutput.StartAttempt = iStart;
            OptimizerOutput.Attempts = Attempts(1:iStart);
            OptimizerOutput.ReplayObjective_kg = ReplayObjective;
            OptimizerOutput.MaxConstraint = MaxConstraint;
            Converged = true;
            break
        end
    end
end

if ~Converged
    FailureSuffix = "";
    if strlength(LastEvaluationFailure) > 0
        FailureSuffix = " Last evaluation failure: " + LastEvaluationFailure;
    end
    error("OptimizationPkg:SequencePowerOpt:NoConvergedSolution", ...
        "No converged, feasible sequence solution was found after %d starts and %d iterations per start.%s", ...
        max(1, MaxStarts), MaxOptIter, FailureSuffix);
end
t = toc / 60;

% Ensure the returned aircraft sequence corresponds exactly to PCbest,
% rather than whichever finite-difference point fmincon evaluated last.
[~, ~, ~, ~, ~, FinalReplayValid] = FlySequence(PCbest, Aircraft, Sequence, true);
if ~FinalReplayValid
    error("OptimizationPkg:SequencePowerOpt:FinalReplayFailed", ...
        "The converged control schedule failed during its final sequence replay.");
end

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%

for kflight = 1:nflight
        nameAC = sprintf("Aircraft%d", kflight);
        Aircraft = OptimizedAircraft.(nameAC);
        results = AnaylzeMiss(Aircraft);
        
        OptSeqTable{kflight, :}= [kflight, Sequence.DISTANCE(kflight),...
                                Sequence.GROUND_TIME(kflight), results] ;
end


% Result persistence is owned by the calling workflow. Avoid fixed-name
% saves here because they collide when sequences are optimized in parallel.
    
%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%

    function [TotalFuel,SOC, dh_dt, PowerExcess, MTOWExcess, Valid] = ...
            FlySequence(PC, Aircraft, Sequence, ForceReplay)
    if nargin < 4
        ForceReplay = false;
    end
    CacheKey = sprintf("%.17g,", PC(:));
    if ~ForceReplay && ~UseParallel && isKey(EvalCache, CacheKey)
        Cached = EvalCache(CacheKey);
        TotalFuel = Cached.TotalFuel;
        SOC = Cached.SOC;
        dh_dt = Cached.dh_dt;
        PowerExcess = Cached.PowerExcess;
        MTOWExcess = Cached.MTOWExcess;
        Valid = Cached.Valid;
        return
    end

    % Total main-mission fuel burn is the sequence objective.
    TotalFuel = 0;
    SOC = zeros(length(SOCConstraintPts), nflight);
    dh_dt = zeros(length(pts), nflight);
    % Check every component at every mission point for every flight.
    PowerExcess = zeros(nMissionPts, nComponents, nflight);
    MTOWExcess = zeros(nflight, 1);
    Valid = false;
    FixedAircraft = Aircraft;
    CurrentBegSOC = Aircraft.Specs.Power.Battery.BegSOC;
    ThermalConfig = BatteryPkg.GetThermalChargeSettings(Aircraft);
    CurrentBatteryTemperature_C = ThermalConfig.InitialTemperature_C;
    if ForceReplay
        CandidateAircraft = struct;
    end

    % iterate through missions
    for jflight = 1:nflight
        % Every flight uses the same fixed sized aircraft. Only battery SOC
        % propagates across the turnaround; geometry, installed hardware,
        % and other flight-specific analysis state must not drift.
        Aircraft = FixedAircraft;
        Aircraft.Specs.Power.Battery.BegSOC = CurrentBegSOC;
        Aircraft.Settings.BatteryInitialTemperature_C = ...
            CurrentBatteryTemperature_C;
        if isfield(Aircraft.Specs.Battery, "BegSOC")
            Aircraft.Specs.Battery.BegSOC = CurrentBegSOC;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                            %
        % extract flight performance %
        % parameters from the table  %
        %                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        % cruise speed
        speed = Sequence.SPEED_mph(jflight);
        
        % mission range
        Range = Sequence.DISTANCE(jflight);
    
        % cruise altitude
        Alt = Sequence.ALTITUDE_m(jflight);
        
        % ground time (mimutes)
        if jflight < nflight
            ChargeTimeMin = Sequence.GROUND_TIME(jflight+1) - 7;
        else
            ChargeTimeMin = 0;
        end
        
        % payload
        Wpayload = Sequence.PAYLOAD_lb(jflight);
    
        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                            %
        % convert units              %
        %                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % convert ground time from minutes to seconds
        ChargeTime = ChargeTimeMin * 60;
        
        % convert speed from mph to m/s
        speed = convvel(speed, 'mph', 'm/s');
        
        % convert mission range from naut mi to m
        RangeM = UnitConversionPkg.ConvLength(Range, "naut mi", "m"); % convert to m
        
        % convert payload from lbm to kg
        Wpayload = convmass(Wpayload, 'lbm', 'kg');
        
        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                            %
        % update aircraft structure  %
        % with the flight's          %
        % performance parameters     %
        %                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % mission range
        Aircraft.Specs.Performance.Range = RangeM;
    
        % convert speed from TAS to Mach
        [~, ~, Mach] = MissionSegsPkg.ComputeFltCon(Alt, 0, "TAS", speed);
        
        % cruise speed
        Aircraft.Specs.Performance.Vels.Crs = Mach;
        
        % cruise altitude
        Aircraft.Specs.Performance.Alts.Crs = Alt;
        
        % payload
        Aircraft.Specs.Weight.Payload = Wpayload;
        % Use the regular -1 solution as the initial guess. FlyFixedAircraft
        % re-converges carried fuel and takeoff mass for every candidate
        % split, which preserves the sequence coupling between saved SOC,
        % later-flight electric assist, required fuel, and takeoff weight.
        Aircraft.Specs.Weight.Fuel = FlightFuelSeed(jflight);
        Aircraft.Specs.Weight.MTOW = FlightMTOWSeed(jflight);

        % Rebuild this flight's range-dependent mission profile without
        % entering aircraft or propulsion sizing, then apply its controls.
        Aircraft = PrepareFlightMission(Aircraft);
        Aircraft = ApplyUncontrolledOffDesignSchedule( ...
            Aircraft, FlightLamDwnSeed{jflight});
        Aircraft = ApplyPowerSplit(Aircraft, PC(:, jflight));

        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Optimized HEA power for    %
        %           mission          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        

        % fly mission
        try
            Aircraft = FlyFixedAircraft(Aircraft);
            %Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);
            
            % Cost is post-processing only; avoid repeating it for every
            % finite-difference objective/constraint evaluation.
            if ForceReplay
                Aircraft = CostPkg.EnergyCost_perAirport( ...
                    Aircraft, Sequence.ORIGIN(jflight), priceTable);
            end
            TotalFuel = TotalFuel + Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);

            % rate of climb
            dh_dt(:, jflight) = Aircraft.Mission.History.SI.Performance.RC(pts);
        
            %SOC
            iBattSrc = find(Aircraft.Specs.Propulsion.PropArch.SrcType == 0, 1);
            if isempty(iBattSrc)
                SOC(:, jflight) = 100;
            else
                SOC(:, jflight) = Aircraft.Mission.History.SI.Power.SOC( ...
                    SOCConstraintPts, iBattSrc);
            end

            % fmincon constraint: power demand may not exceed component
            % power availability anywhere in the complete mission.
            PreqAll = Aircraft.Mission.History.SI.Power.Preq;
            ThisPowerExcess = max( ...
                PreqAll - Aircraft.Mission.History.SI.Power.Pav, ...
                PreqAll - Aircraft.Mission.History.SI.Power.Pout);
            % Unused terminal/component entries are stored as NaN and do
            % not represent a physical demand point.
            ThisPowerExcess(~isfinite(ThisPowerExcess)) = -1e15;
            % Only main mission 1 is controlled. Reserve/diversion rows use
            % their independent turbine-only dispatch.
            ThisPowerExcess(MainEnd + 1:end, :) = -1e15;
            ThisPowerExcess(DetailedTakeoffPts, :) = -1e15;
            if ~isequal(size(ThisPowerExcess), [nMissionPts, nComponents])
                error("OptimizationPkg:SequencePowerOpt:PowerHistorySize", ...
                    "Unexpected power-history size for flight %d.", jflight);
            end
            PowerExcess(:, :, jflight) = ThisPowerExcess;
            if max(ThisPowerExcess, [], "all") > 1
                % Reaching the prescribed mission time is not sufficient:
                % reject any PC schedule that requests unavailable power.
                TotalFuel = 1e15;
                dh_dt(:, jflight:end) = ...
                    Aircraft.Specs.Performance.RCMax + 1;
                SOC(:, jflight:end) = -1;
                PowerExcess(:, :, jflight+1:end) = 1e15;
                MTOWExcess(jflight:end) = 1e15;
                OptimizedAircraft = struct;
                SaveEvaluation();
                return
            end

            % fmincon constraint: the flight takeoff weight may not exceed
            % the MTOW of the original sized HEA design.
            MTOWExcess(jflight) = ...
                Aircraft.Mission.History.SI.Weight.CurWeight(1) - ...
                DesignMTOWLimit;
        catch ME
            LastEvaluationFailure = "Flight " + jflight + ": " + ...
                string(ME.message) + " (" + string(ME.identifier) + ")";
            TotalFuel = 10^15;
            dh_dt(:, :) = Aircraft.Specs.Performance.RCMax + 1;
            SOC(:, :) = -1;
            PowerExcess(:, :) = 1e15;
            MTOWExcess(:) = 1e15;
            OptimizedAircraft = struct;
            SaveEvaluation();
            return
        end

       

     
        
        try
            % Charge the battery and propagate its actual post-charge SOC
            % to the next flight. A charging failure invalidates the entire
            % sequence evaluation; it must never be replaced by a fake SOC.
            if jflight < nflight
                Aircraft.Settings.GroundChargeMissionEndIndex = MainEnd;
                Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);
                CurrentBegSOC = ...
                    Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd;
                if isfield(Aircraft.Mission.History.SI.Power.ChargedAC, ...
                        "TemperatureEnd_C")
                    CurrentBatteryTemperature_C = Aircraft.Mission.History.SI. ...
                        Power.ChargedAC.TemperatureEnd_C;
                end
            end
        catch ME
            % Keep optimizer evaluations quiet, but retain the true reason
            % so a wholly failed sequence reports a useful diagnostic.
            LastEvaluationFailure = "Ground charge after flight " + ...
                jflight + ": " + string(ME.message) + " (" + ...
                string(ME.identifier) + ")";
            TotalFuel = 10^15;
            dh_dt(:, :) = Aircraft.Specs.Performance.RCMax + 1;
            SOC(:, :) = -1;
            PowerExcess(:, :) = 1e15;
            MTOWExcess(:) = 1e15;
            OptimizedAircraft = struct;
            SaveEvaluation();
            return
        end
        
        % Full aircraft histories are required only for the one final replay.
        % Objective/constraint evaluations retain numeric outputs only.
        if ForceReplay
            Aircraft = RecordUpstreamUtilization(Aircraft);
            nameAC = sprintf("Aircraft%d", jflight);
            CandidateAircraft.(nameAC) = Aircraft;
        end
    end

    if ForceReplay
        OptimizedAircraft = CandidateAircraft;
    end
    Valid = true;
    SaveEvaluation();

    function SaveEvaluation()
        if ~UseParallel
            EvalCache(CacheKey) = struct( ...
                "TotalFuel", TotalFuel, "SOC", SOC, "dh_dt", dh_dt, ...
                "PowerExcess", PowerExcess, "MTOWExcess", MTOWExcess, ...
                "Valid", Valid);
        end
    end

end

function [PCSeed, MinimumPC, FlightFuel, FlightMTOW, FlightLamDwn, ...
        SeedValid, SeedFailure] = ...
        BuildFlownSequenceSeed(SeedAircraft, SeedSequence, FallbackPC)
    PCSeed = FallbackPC;
    MinimumPC = zeros(size(FallbackPC));
    FlightFuel = repmat(SeedAircraft.Specs.Weight.Fuel, nflight, 1);
    FlightMTOW = repmat(SeedAircraft.Specs.Weight.MTOW, nflight, 1);
    FlightLamDwn = cell(nflight, 1);
    SeedValid = false;
    SeedFailure = "";
    SeedAircraft.Settings.Analysis.Type = -1;
    SeedAircraft.Settings.Analysis.FuelRelaxation = 0.5;
    SeedAircraft.Settings.PowerOpt = 0;
    FixedSeedAircraft = SeedAircraft;
    SeedBegSOC = SeedAircraft.Specs.Power.Battery.BegSOC;
    SeedThermalConfig = BatteryPkg.GetThermalChargeSettings(SeedAircraft);
    SeedBatteryTemperature_C = SeedThermalConfig.InitialTemperature_C;
    nsrcLocal = length(SeedAircraft.Specs.Propulsion.PropArch.SrcType);

    try
        for jSeed = 1:nflight
            SeedAircraft = FixedSeedAircraft;
            SeedAircraft.Specs.Power.Battery.BegSOC = SeedBegSOC;
            SeedAircraft.Settings.BatteryInitialTemperature_C = ...
                SeedBatteryTemperature_C;
            if isfield(SeedAircraft.Specs.Battery, "BegSOC")
                SeedAircraft.Specs.Battery.BegSOC = SeedBegSOC;
            end
            Speed = convvel(SeedSequence.SPEED_mph(jSeed), "mph", "m/s");
            SeedAircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
                SeedSequence.DISTANCE(jSeed), "naut mi", "m");
            [~, ~, SeedAircraft.Specs.Performance.Vels.Crs] = ...
                MissionSegsPkg.ComputeFltCon(SeedSequence.ALTITUDE_m(jSeed), ...
                0, "TAS", Speed);
            SeedAircraft.Specs.Performance.Alts.Crs = SeedSequence.ALTITUDE_m(jSeed);
            SeedAircraft.Specs.Weight.Payload = convmass( ...
                SeedSequence.PAYLOAD_lb(jSeed), "lbm", "kg");

            if isfield(SeedAircraft.Specs.Power.LamUps, "Miss")
                SeedAircraft.Specs.Power.LamUps = ...
                    rmfield(SeedAircraft.Specs.Power.LamUps, "Miss");
            end
            if isfield(SeedAircraft.Specs.Power.LamDwn, "Miss")
                SeedAircraft.Specs.Power.LamDwn = ...
                    rmfield(SeedAircraft.Specs.Power.LamDwn, "Miss");
            end

            % Use the same complete -1 off-design path as the comparison
            % baseline. Main rebuilds the profile and converges carried fuel
            % while preserving the fixed installed aircraft.
            SeedAircraft = Main(SeedAircraft, ...
                @MissionProfilesPkg.ERJ_ClimbThenAccel);
            if isfield(SeedAircraft.Settings, "Converged") && ...
                    SeedAircraft.Settings.Converged == 0
                SeedFailure = "Flight " + jSeed + ...
                    " regular off-design fuel iteration did not converge.";
                return
            end
            FlightFuel(jSeed) = SeedAircraft.Specs.Weight.Fuel;
            FlightMTOW(jSeed) = SeedAircraft.Specs.Weight.MTOW;

            Pout = SeedAircraft.Mission.History.SI.Power.Pout;
            Preq = SeedAircraft.Mission.History.SI.Power.Preq;
            Pav = SeedAircraft.Mission.History.SI.Power.Pav;
            FlownLamDwn = SeedAircraft.Mission.History.SI.Power.LamDwn;
            FlightLamDwn{jSeed} = FlownLamDwn;
            if size(FlownLamDwn, 1) >= max(pts) && ...
                    size(FlownLamDwn, 2) >= max(iEM)
                ThisPC = mean(FlownLamDwn(pts, iEM), 2);
            else
                EMOut = mean(Pout(pts, nsrcLocal + iEM), 2);
                GTOut = mean(Pout(pts, nsrcLocal + iGT), 2);
                TotalOut = EMOut + GTOut;
                Powered = isfinite(TotalOut) & TotalOut > 1.0;
                ThisPC = zeros(length(pts), 1);
                ThisPC(Powered) = EMOut(Powered) ./ TotalOut(Powered);
            end

            TotalReq = mean(Preq(pts, nsrcLocal + iEM), 2) + ...
                mean(Preq(pts, nsrcLocal + iGT), 2);
            GTPav = mean(Pav(pts, nsrcLocal + iGT), 2);
            EMPav = mean(Pav(pts, nsrcLocal + iEM), 2);
            Required = isfinite(TotalReq) & TotalReq > 1.0;
            Lower = zeros(length(pts), 1);
            Upper = ones(length(pts), 1);
            Lower(Required) = max(0, 1 - GTPav(Required) ./ TotalReq(Required));
            Upper(Required) = min(1, EMPav(Required) ./ TotalReq(Required));
            FeasibleBand = Lower <= Upper;
            ThisPC(FeasibleBand) = min(max(ThisPC(FeasibleBand), ...
                Lower(FeasibleBand) + 1.0e-8), Upper(FeasibleBand) - 1.0e-8);
            PCSeed(:, jSeed) = min(max(ThisPC, 0), 1);
            MinimumPC(:, jSeed) = min(max(Lower + 1.0e-8, 0), 1);

            if jSeed < nflight
                ChargeTime = max(SeedSequence.GROUND_TIME(jSeed + 1) - 7, 0) * 60;
                SeedAircraft.Settings.BatteryInitialTemperature_C = ...
                    SeedBatteryTemperature_C;
                SeedAircraft.Settings.GroundChargeMissionEndIndex = MainEnd;
                SeedAircraft = BatteryPkg.GroundCharge(SeedAircraft, ChargeTime);
                SeedBegSOC = ...
                    SeedAircraft.Mission.History.SI.Power.ChargedAC.SOCEnd;
                if isfield(SeedAircraft.Mission.History.SI.Power.ChargedAC, ...
                        "TemperatureEnd_C")
                    SeedBatteryTemperature_C = SeedAircraft.Mission.History.SI. ...
                        Power.ChargedAC.TemperatureEnd_C;
                end
            end
        end
        SeedValid = true;
    catch ME
        SeedFailure = string(ME.message) + " (" + string(ME.identifier) + ")";
    end
end

function Aircraft = ApplyUncontrolledOffDesignSchedule(Aircraft, FlownLamDwn)
    if isempty(FlownLamDwn) || ~isequal(size(FlownLamDwn), ...
            size(Aircraft.Specs.Power.LamDwn.Miss))
        return
    end
    % Preserve regular dispatch only inside main mission 1. Do not overwrite
    % the turbine-only reserve/diversion schedule.
    UncontrolledPts = setdiff((1:MainEnd)', pts);
    Aircraft.Specs.Power.LamDwn.Miss(UncontrolledPts, :) = ...
        FlownLamDwn(UncontrolledPts, :);
    Aircraft.Mission.History.SI.Power.LamDwn = ...
        Aircraft.Specs.Power.LamDwn.Miss;
end

function [PCSeed, SeedValid] = FindFeasibleSequenceSeed(FlownPC, MinimumPC, SeedAircraft, SeedSequence)
    % Preserve the point-by-point shape of the Type -1 flown schedule while
    % reducing its electric magnitude only as much as needed to make the
    % complete fixed-split sequence feasible (including SOC carryover).
    [~, SOC, RC, PowerExcess, MTOWExcess, Valid] = ...
        FlySequence(FlownPC, SeedAircraft, SeedSequence);
    c = SequenceConstraints(SOC, RC, PowerExcess, MTOWExcess, SeedAircraft);
    if Valid && max(c, [], "all") <= options.ConstraintTolerance
        PCSeed = FlownPC;
        SeedValid = true;
        return
    end

    [~, SOC, RC, PowerExcess, MTOWExcess, Valid] = ...
        FlySequence(MinimumPC, SeedAircraft, SeedSequence);
    c = SequenceConstraints(SOC, RC, PowerExcess, MTOWExcess, SeedAircraft);
    if ~(Valid && max(c, [], "all") <= options.ConstraintTolerance)
        PCSeed = FlownPC;
        SeedValid = false;
        return
    end

    LowerScale = 0;
    UpperScale = 1;
    for iBisect = 1:12
        TestScale = 0.5 * (LowerScale + UpperScale);
        TestPC = MinimumPC + TestScale .* (FlownPC - MinimumPC);
        [~, SOC, RC, PowerExcess, MTOWExcess, Valid] = ...
            FlySequence(TestPC, SeedAircraft, SeedSequence);
        c = SequenceConstraints(SOC, RC, PowerExcess, MTOWExcess, SeedAircraft);
        if Valid && max(c, [], "all") <= options.ConstraintTolerance
            LowerScale = TestScale;
        else
            UpperScale = TestScale;
        end
    end
    PCSeed = MinimumPC + LowerScale .* (FlownPC - MinimumPC);
    SeedValid = true;
end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC, Aircraft, Sequence)
    [val, ~, ~, ~, ~] = FlySequence(PC, Aircraft, Sequence);
    val = val ./ ObjectiveScale;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% SOC Constraint             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function [c, ceq] = Cons(PC, Aircraft, Sequence)
    [~, SOC, dh_dt, PowerExcess, MTOWExcess] = ...
        FlySequence(PC, Aircraft, Sequence);
    c = SequenceConstraints(SOC, dh_dt, PowerExcess, MTOWExcess, Aircraft);
    ceq = [];

end

function c = SequenceConstraints(SOC, dh_dt, PowerExcess, MTOWExcess, Aircraft)
    cSOCMin = Aircraft.Specs.Battery.MinSOC - SOC;
    cSOCMax = SOC - 100;
    cRC = dh_dt - Aircraft.Specs.Performance.RCMax;
    % One constraint per controlled point/flight is equivalent to requiring
    % every component excess to be nonpositive, while avoiding thousands of
    % identically zero inactive/reserve constraints in SQP's subproblem.
    cPower = max(PowerExcess(pts, :, :), [], 2) / 1e6;
    c = [cSOCMin(:); cSOCMax(:); cRC(:); cPower(:); MTOWExcess(:)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Split Application          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OutAircraft = ApplyPowerSplit(InAircraft, PC)
    OutAircraft = InAircraft;

    % FAST assigns the complete split to every parallel motor/turbine.
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iEM) = ...
        repmat(PC, 1, length(iEM));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iGT) = ...
        repmat(1 - PC, 1, length(iGT));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iFan) = ...
        repmat(0.5, length(pts), length(iFan));

    % LamUps is installed availability, not achieved loading. Keep it at one
    % throughout takeoff/climb; LamDwn alone controls actual routing.
    OutAircraft.Specs.Power.LamUps.Miss(pts, :) = 1;
end

function OutAircraft = PrepareFlightMission(InAircraft)
    OutAircraft = MissionProfilesPkg.ERJ_ClimbThenAccel(InAircraft);
    OutAircraft = MissionSegsPkg.ProcessProfile(OutAircraft);
    OutAircraft = DataStructPkg.InitMissionHistory(OutAircraft);

    if isfield(OutAircraft.Specs.Power.LamUps, "Miss")
        OutAircraft.Specs.Power.LamUps = rmfield(OutAircraft.Specs.Power.LamUps, "Miss");
    end
    if isfield(OutAircraft.Specs.Power.LamDwn, "Miss")
        OutAircraft.Specs.Power.LamDwn = rmfield(OutAircraft.Specs.Power.LamDwn, "Miss");
    end
    OutAircraft = PropulsionPkg.LamFill(OutAircraft);
    OutAircraft = NormalizeOffDesignSchedule(OutAircraft);
end

function OutAircraft = FlyFixedAircraft(InAircraft)
    MaxFuelIter = 50;
    if isfield(InAircraft.Settings, "PowerOptFuelMaxIter")
        MaxFuelIter = InAircraft.Settings.PowerOptFuelMaxIter;
    end

    % EAPAnalysis Type -2 retains the sized wing, battery, and propulsion
    % hardware while iterating carried fuel/MTOW. Suppress its per-iteration
    % console report because this function is called for every optimizer
    % objective and finite-difference evaluation.
    [~, OutAircraft] = evalc( ...
        "EAPAnalysis(InAircraft, -2, MaxFuelIter)");
    if ~isfield(OutAircraft.Settings, "Converged") || ...
            OutAircraft.Settings.Converged == 0
        error("OptimizationPkg:SequencePowerOpt:FuelIteration", ...
            "Off-design fuel/MTOW iteration did not converge.");
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Post Process               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Results = AnaylzeMiss(Aircraft)

%% EXTRACT MISSION SEGMENT INDECES %% 
% get the number of points in each segment
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npnt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);

% get the index of the last takeoff segment
EndTko = Aircraft.Settings.TkoPoints;

% get the index of the last climb segment
EndClb = 2 * Aircraft.Settings.ClbPoints + EndTko - 2;

% get the index of end of cruise
EndCrs = EndClb + Aircraft.Settings.ClbPoints + Aircraft.Settings.CrsPoints + Aircraft.Settings.DesPoints - 3;

% --------------------------------------------------------------------------------------------------------------------------
%% EXTRACT MISSION SEGMENT INDECES %% 

% takeoff gross weight
TOGW = Aircraft.Specs.Weight.MTOW;

% main mission fuelburn
Fburn = Aircraft.Mission.History.SI.Weight.Fburn(npnt);

% direct operting cost
DOC = Aircraft.Specs.Cost.FOC;

% main mission battery energy use
EBatt = Aircraft.Mission.History.SI.Energy.E_ES(npnt, 2);

% SOC after segement values
SOCbeg = Aircraft.Mission.History.SI.Power.SOC(1, 2);
SOCtko = Aircraft.Mission.History.SI.Power.SOC(EndTko, 2);
SOCclb = Aircraft.Mission.History.SI.Power.SOC(EndClb, 2);
SOCf = Aircraft.Mission.History.SI.Power.SOC(npnt, 2);

% mission seg TSFC values
TSFC_tko = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(1     :EndTko))/EndTko            ;
TSFC_clb = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndTko:EndClb))/(EndClb-EndTko +1);
TSFC_crs = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndClb:EndCrs))/(EndCrs-EndClb +1);

% save results in a vector
Results = [TOGW, DOC, Fburn, EBatt, SOCbeg, SOCtko, SOCclb, SOCf, TSFC_tko, TSFC_clb, TSFC_crs];

end


%% LOCAL HELPER FUNCTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Aircraft = PrepareSequenceAircraft(Aircraft)
Aircraft = DataStructPkg.PreSpecProcessing(Aircraft);
Aircraft = PropulsionPkg.CreatePropArch(Aircraft);
Aircraft = PropulsionPkg.PropArchConnections(Aircraft);
Aircraft = MissionProfilesPkg.ERJ_ClimbThenAccel(Aircraft);
Aircraft = MissionSegsPkg.ProcessProfile(Aircraft);
Aircraft = DataStructPkg.InitMissionHistory(Aircraft);

if isfield(Aircraft.Specs.Power.LamUps, "Miss")
    Aircraft.Specs.Power.LamUps = rmfield(Aircraft.Specs.Power.LamUps, "Miss");
end
if isfield(Aircraft.Specs.Power.LamDwn, "Miss")
    Aircraft.Specs.Power.LamDwn = rmfield(Aircraft.Specs.Power.LamDwn, "Miss");
end

Aircraft = PropulsionPkg.LamFill(Aircraft);
Aircraft = NormalizeOffDesignSchedule(Aircraft);
end


function Aircraft = NormalizeOffDesignSchedule(Aircraft)
% Use full installed transmitter availability while keeping LamDwn as the
% independent routing command. Reserve/diversion missions are fuel-only.
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
iEM = find(TrnType == 0);
iGT = find(TrnType == 1);
iFan = find(TrnType == 2);

Aircraft.Specs.Power.LamUps.Miss(:) = 1;
Aircraft.Mission.History.SI.Power.LamUps(:) = 1;

ReserveSegs = find(Aircraft.Mission.Profile.ID ~= 1);
if ~isempty(ReserveSegs)
    ReservePts = [];
    for iReserveSeg = ReserveSegs(:).'
        ReservePts = [ReservePts, ...
            Aircraft.Mission.Profile.SegBeg(iReserveSeg): ...
            Aircraft.Mission.Profile.SegEnd(iReserveSeg)]; %#ok<AGROW>
    end
    ReservePts = unique(ReservePts);
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iEM) = 0;
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iGT) = 1;
    Aircraft.Specs.Power.LamDwn.Miss(ReservePts, iFan) = 0.5;
    Aircraft.Specs.Power.LamUps.Miss(ReservePts, :) = 1;
    Aircraft.Specs.Power.LamUps.Miss(ReservePts, iEM) = 0;
    Aircraft.Mission.History.SI.Power.LamDwn = ...
        Aircraft.Specs.Power.LamDwn.Miss;
    Aircraft.Mission.History.SI.Power.LamUps = ...
        Aircraft.Specs.Power.LamUps.Miss;
end
end


function Aircraft = RecordUpstreamUtilization(Aircraft)
% Preserve LamUps as the availability command and report achieved loading
% separately, matching MissionPowerOpt's post-processing convention.
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
ntrans = length(Aircraft.Specs.Propulsion.PropArch.TrnType);
cols = nsrc + (1:ntrans);
Pout = Aircraft.Mission.History.SI.Power.Pout(:, cols);
Pav = Aircraft.Mission.History.SI.Power.Pav(:, cols);
Utilization = zeros(size(Pout));
Active = isfinite(Pout) & isfinite(Pav) & abs(Pav) > 1.0e-9;
Utilization(Active) = Pout(Active) ./ Pav(Active);
Aircraft.Mission.History.SI.Power.UpstreamUtilization = ...
    min(max(Utilization, 0), 1);
end


function pts = FirstMissionTakeoffThroughClimb(Aircraft)
Mission = Aircraft.Mission.Profile;
InMission = Mission.ID == 1;
TakeoffSegs = find(InMission & (strcmpi(Mission.Segs, "Takeoff") | strcmpi(Mission.Segs, "DetailedTakeoff")));
ClimbSegs = find(InMission & strcmpi(Mission.Segs, "Climb"));

if (isempty(TakeoffSegs) || isempty(ClimbSegs))
    error("ERROR - SequencePowerOpt: first mission must include takeoff and climb segments.");
end

SegBeg = Mission.SegBeg(TakeoffSegs(1));
% The final climb point is shared with the first cruise point. Excluding it
% prevents a climb assist command from spanning the cruise time interval.
SegEnd = Mission.SegEnd(ClimbSegs(end)) - 1;
pts = (SegBeg:SegEnd)';
end


function Starts = BuildStartPoints(PC0, PCFloor, MaxStarts)
MaxStarts = max(1, floor(MaxStarts));
Starts = cell(min(MaxStarts, 3), 1);
% Begin with the aircraft's off-design schedule, which is the closest
% sequence analogue to MissionPowerOpt's feasible flown initialization.
Starts{1} = PC0;

if numel(Starts) >= 2
    Starts{2} = PCFloor;
end

if numel(Starts) >= 3
    % Retain the turbine-feasible per-point floor while conserving more
    % battery than the primary off-design-derived starting schedule.
    Starts{3} = PCFloor + 0.5 .* (PC0 - PCFloor);
end
end

end

