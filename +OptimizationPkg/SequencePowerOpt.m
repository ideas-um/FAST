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

% Evaluations mutate the cached sequence result, so keep them serial.
options = optimoptions("fmincon", ...
                       "MaxIterations", MaxOptIter, ...
                       "Display", "iter", ...
                       "Algorithm", "interior-point", ...
                       "UseParallel", false);

% objective function convergence tolerance
options.OptimalityTolerance = 10^-6;

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
Aircraft.Settings.Analysis.Type = -1;

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
pts = FirstMissionTakeoffThroughClimb(Aircraft);

TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;
iEM  = find(TrnType == 0);
iGT  = find(TrnType == 1);
iFan = find(TrnType == 2);

if (isempty(iEM) || isempty(iGT) || isempty(iFan))
    error("ERROR - SequencePowerOpt: expected a PHE architecture with engines, electric motors, and fans.");
end

% Use one electric-assist control per mission point and flight. Both
% electric motors receive the same split; gas turbines receive 1 - split.
PC = mean(Aircraft.Specs.Power.LamDwn.Miss(pts, iEM), 2);
PC(isnan(PC)) = 0;
PC = min(max(PC, 0), 0.9);
PC0 = repmat(PC, 1, nflight);
lb = zeros(size(PC0));
ub = ones(size(PC0));

% save storage values
PClast = [];
Objective = [];
SOC    = [];
dh_dt = [];
PowerExcess = [];
MTOWExcess = [];
LastEvaluationFailure = "";
%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
if (MaxOptIter < 1)
    error("ERROR - SequencePowerOpt: MaxIterations must be positive for a converged result.");
end

StartPoints = BuildStartPoints(PC0, MaxStarts);
Attempts = repmat(struct("Start", 0, "ExitFlag", NaN, "Iterations", NaN, ...
    "Objective_kg", NaN, "MaxConstraint", Inf, "ValidReplay", false), ...
    numel(StartPoints), 1);
Converged = false;

for iStart = 1:numel(StartPoints)
    PClast = [];
    [CandidatePC, ~, CandidateExitFlag, CandidateOutput] = ...
        fmincon(@(PC) ObjFunc(PC, Aircraft, Sequence), StartPoints{iStart}, ...
        [], [], [], [], lb, ub, @(PC) Cons(PC, Aircraft, Sequence), options);

    PClast = [];
[ReplayObjective, ReplaySOC, ReplayRC, ReplayPowerExcess, ...
        ReplayMTOWExcess, ValidReplay] = ...
        FlySequence(CandidatePC, Aircraft, Sequence);
    ReplayConstraints = [ ...
        reshape(Aircraft.Specs.Battery.MinSOC - ReplaySOC, [], 1); ...
        reshape(ReplaySOC - 100, [], 1); ...
        reshape(ReplayRC - Aircraft.Specs.Performance.RCMax, [], 1); ...
        ReplayPowerExcess(:); ReplayMTOWExcess(:)];
    MaxConstraint = max(ReplayConstraints, [], "all");

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

if ~Converged
    FailureSuffix = "";
    if strlength(LastEvaluationFailure) > 0
        FailureSuffix = " Last evaluation failure: " + LastEvaluationFailure;
    end
    error("OptimizationPkg:SequencePowerOpt:NoConvergedSolution", ...
        "No converged, feasible sequence solution was found after %d starts and %d iterations per start.%s", ...
        numel(StartPoints), MaxOptIter, FailureSuffix);
end
t = toc / 60;

% Ensure the returned aircraft sequence corresponds exactly to PCbest,
% rather than whichever finite-difference point fmincon evaluated last.
[~, ~, ~, ~, ~, FinalReplayValid] = FlySequence(PCbest, Aircraft, Sequence);
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
            FlySequence(PC, Aircraft, Sequence)
    % Total main-mission fuel burn is the sequence objective.
    TotalFuel = 0;
    SOC = zeros(length(pts), nflight);
    dh_dt = zeros(length(pts), nflight);
    % Check power availability at the same fixed takeoff/climb control
    % points used by the SOC and rate-of-climb constraints.  Restricting
    % the mission histories to pts preserves every optimized control point
    % while keeping the nonlinear-constraint vector length invariant.
    PowerExcess = zeros(length(pts), nflight);
    MTOWExcess = zeros(nflight, 1);
    Valid = false;
    CandidateAircraft = struct;

    % iterate through missions
    for jflight = 1:nflight
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

        % Rebuild this flight's range-dependent mission profile without
        % entering aircraft or propulsion sizing, then apply its controls.
        Aircraft = PrepareFlightMission(Aircraft);
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
            
            % Determine cost for post-processing, then add this flight's
            % main-mission fuel burn to the sequence objective.
            Aircraft = CostPkg.EnergyCost_perAirport(Aircraft, Sequence.ORIGIN(jflight), priceTable);
            MainSegs = find(Aircraft.Mission.Profile.ID == 1);
            MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
            TotalFuel = TotalFuel + Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);

            % rate of climb
            dh_dt(:, jflight) = Aircraft.Mission.History.SI.Performance.RC(pts);
        
            %SOC
            SOC(:, jflight) = Aircraft.Mission.History.SI.Power.SOC(pts,2);

            % fmincon constraint: power demand may not exceed component
            % power availability anywhere in the complete mission.
            ThisPowerExcess = Aircraft.Mission.History.SI.Power.Preq - ...
                Aircraft.Mission.History.SI.Power.Pav;
            % Unused terminal/component entries are stored as NaN and do
            % not represent a physical demand point.
            ThisPowerExcess(~isfinite(ThisPowerExcess)) = 0;
            PowerExcess(:, jflight) = ThisPowerExcess(pts);

            % fmincon constraint: the flight takeoff weight may not exceed
            % the MTOW of the original sized HEA design.
            MTOWExcess(jflight) = ...
                Aircraft.Mission.History.SI.Weight.CurWeight(1) - ...
                Aircraft.Specs.Weight.MTOW;
        catch ME
            LastEvaluationFailure = "Flight " + jflight + ": " + ...
                string(ME.message) + " (" + string(ME.identifier) + ")";
            TotalFuel = 10^15;
            dh_dt(:, :) = Aircraft.Specs.Performance.RCMax + 1;
            SOC(:, :) = -1;
            PowerExcess(:, :) = 1e15;
            MTOWExcess(:) = 1e15;
            OptimizedAircraft = struct;
            return
        end

       

     
        
        try
            % Charge the battery and propagate its actual post-charge SOC
            % to the next flight. A charging failure invalidates the entire
            % sequence evaluation; it must never be replaced by a fake SOC.
            if jflight < nflight
                Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);
                Aircraft.Specs.Power.Battery.BegSOC = ...
                    Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd;
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
            return
        end
        
        % save optimized aircraft struct
        nameAC = sprintf("Aircraft%d", jflight);
        CandidateAircraft.(nameAC) = Aircraft;
    end

    OptimizedAircraft = CandidateAircraft;
    Valid = true;

end

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC, Aircraft, Sequence)
    % check if PC values changes
    if ~isequal(PC, PClast)
        % Cache every quantity consumed by Cons. fmincon commonly calls the
        % objective before the nonlinear constraints at the same PC; if
        % only the first three outputs are assigned here, Cons sees a cache
        % hit while PowerExcess and MTOWExcess are still empty, changing the
        % constraint-vector length on its next evaluation.
        [Objective, SOC, dh_dt, PowerExcess, MTOWExcess] = ...
            FlySequence(PC, Aircraft, Sequence);
        PClast = PC;
        %disp(PC)
    end
    % return objective function value
    val = Objective;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% SOC Constraint             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function [c, ceq] = Cons(PC, Aircraft, Sequence)
    % check if PC values changes
    if ~isequal(PC, PClast)
        [Objective, SOC, dh_dt, PowerExcess, MTOWExcess] = ...
            FlySequence(PC, Aircraft, Sequence);
        PClast = PC;
    end
    % Battery SOC must remain within its physical range at every optimized
    % takeoff/climb control point for every flight in the sequence.
    cSOCMin = Aircraft.Specs.Battery.MinSOC - SOC;
    cSOCMax = SOC - 100;

    % compute RC constraint
    cRC = dh_dt - Aircraft.Specs.Performance.RCMax;

    % out put constraints
    % Component-wise power constraint across every flight and mission point.
    cPower = PowerExcess;

    % Per-flight structural weight constraint against the fixed HEA design.
    cMTOW = MTOWExcess;

    c = [cSOCMin(:); cSOCMax(:); cRC(:); cPower(:); cMTOW(:)];
    ceq = [];

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Split Application          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function OutAircraft = ApplyPowerSplit(InAircraft, PC)
    OutAircraft = InAircraft;

    OutAircraft.Specs.Power.LamDwn.Miss(pts, iEM) = repmat(PC, 1, length(iEM));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iGT) = repmat(1 - PC, 1, length(iGT));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iFan) = ...
        repmat(1 / length(iFan), length(pts), length(iFan));

    % The climb derate is used only while sizing the installed motors.
    % During sequence optimization the full installed motor rating is
    % available throughout takeoff and climb.
    OutAircraft.Specs.Power.LamUps.Miss(pts, iEM) = 1;
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
end

function OutAircraft = FlyFixedAircraft(InAircraft)
    OutAircraft = DataStructPkg.ClearMission(InAircraft);
    OutAircraft = PropulsionPkg.LamFill(OutAircraft);
    OutAircraft = MissionSegsPkg.FlyMission(OutAircraft);
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
end


function pts = FirstMissionTakeoffThroughClimb(Aircraft)
Mission = Aircraft.Mission.Profile;
InMission = Mission.ID == 1;
TakeoffSegs = find(InMission & (strcmpi(Mission.Segs, "Takeoff") | strcmpi(Mission.Segs, "DetailedTakeoff")));
ClimbSegs = find(InMission & strcmpi(Mission.Segs, "Climb"));

if (isempty(TakeoffSegs) || isempty(ClimbSegs))
    error("ERROR - SequencePowerOpt: first mission must include takeoff and climb segments.");
end

pts = (Mission.SegBeg(TakeoffSegs(1)):Mission.SegEnd(ClimbSegs(end)))';
end


function Starts = BuildStartPoints(PC0, MaxStarts)
MaxStarts = max(1, floor(MaxStarts));
Starts = cell(min(MaxStarts, 3), 1);
Starts{1} = PC0;

if numel(Starts) >= 2
    % A conservative schedule preserves more battery for later flights.
    FlightScale = linspace(0.35, 1, size(PC0, 2));
    Starts{2} = PC0 .* FlightScale;
end

if numel(Starts) >= 3
    % A uniform low-assist schedule provides a distinct feasible basin.
    Starts{3} = min(PC0, 0.10 .* ones(size(PC0)));
end
end

end

