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
% on parallel workers.
options = optimoptions("fmincon", ...
                       "MaxIterations", MaxOptIter, ...
                       "Display", "iter", ...
                       "Algorithm", "interior-point", ...
                       "UseParallel", true);

% objective function convergence tolerance
options.OptimalityTolerance = 1.0e-6;

% step size convergence
options.StepTolerance = 1.0e-9;

% Match SequencePowerOpt's evaluation allowance.
options.MaxFunctionEvaluations = 1.0e9;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Aircraft Settings          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run off-design mission so the optimizer changes mission power splits
% without resizing the aircraft inside each objective evaluation.
Aircraft.Settings.Analysis.Type = -1;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% The optimizer supplies and constrains the mission-indexed power split.
Aircraft.Settings.PowerOpt = 1;

% no mission history table
Aircraft.Settings.Table = 0;

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
nMissionPts = Aircraft0.Mission.Profile.SegEnd(end);
nComponents = length(Aircraft0.Specs.Propulsion.PropArch.Arch);

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
PC0 = mean(Aircraft0.Specs.Power.LamDwn.Miss(pts, iEM), 2);
PC0(isnan(PC0)) = 0;
PC0 = min(max(PC0, 0), 0.9);
% Start from the conventional (zero-assist) schedule, which avoids asking
% the fixed-size motors for more than their installed power on iteration 0.
PC0 = zeros(size(PC0));

% Match SequencePowerOpt: PC is the total electric fraction and may reach 1.
lb = zeros(size(PC0));
ub = ones(size(PC0));

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
    if exitflag <= 0 || MaxConstraint > options.ConstraintTolerance
        error("OptimizationPkg:MissionPowerOpt:NoFeasibleSolution", ...
            ["Mission optimizer did not produce a feasible result " ...
             "(exit flag %d, maximum scaled constraint %.6g)."], ...
            exitflag, MaxConstraint);
    end
end
t = toc / 60;


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

OptAircraft = ApplyPowerSplit(Aircraft0, PCbest);
OptAircraft = FlyFixedAircraft(OptAircraft);

fburnOG  = ObjFunc(PC0);
fburnOpt = ObjFunc(PCbest);
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
    % input updated mission split schedule
    TestAircraft = ApplyPowerSplit(Aircraft0, PC);

    try
        % Fly the already-sized aircraft directly. Calling Main here enters
        % EAPAnalysis, whose first pass calls PropulsionSizing even for the
        % retrofit (-2) mode and therefore changes motor and aircraft size.
        TestAircraft = FlyFixedAircraft(TestAircraft);

        % fuel required for mission
        fburnOut = TestAircraft.Mission.History.SI.Weight.Fburn(MainEnd);
        if (fburnOut < 0)
            fburnOut = 1.0e10;
        end

        % Match SequencePowerOpt by constraining SOC at every optimized
        % takeoff/climb control point.
        Batt = TestAircraft.Specs.Propulsion.PropArch.SrcType == 0;
        if (any(Batt))
            SOCOut = TestAircraft.Mission.History.SI.Power.SOC(pts, Batt);
        else
            SOCOut = 100;
        end

        % climb-rate constraint is applied only over the optimized window.
        RCOut = TestAircraft.Mission.History.SI.Performance.RC(pts);

        % A prescribed trajectory is feasible only when every propulsion
        % component can supply its required power at every mission point.
        PowerExcessOut = TestAircraft.Mission.History.SI.Power.Preq - ...
            TestAircraft.Mission.History.SI.Power.Pav;
        PowerExcessOut(~isfinite(PowerExcessOut)) = 0;
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
        SOCOut = -1;
        RCOut = Aircraft0.Specs.Performance.RCMax + ones(size(pts));
        PowerExcessOut = 1e15 * ones(nMissionPts, nComponents);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Fixed-Aircraft Mission     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function OutAircraft = FlyFixedAircraft(InAircraft)
    OutAircraft = DataStructPkg.ClearMission(InAircraft);
    OutAircraft = PropulsionPkg.LamFill(OutAircraft);
    OutAircraft = MissionSegsPkg.FlyMission(OutAircraft);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC)
    [val, ~, ~, ~] = FlyAircraft(PC);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Constraints                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c, ceq] = Cons(PC)
    [~, SOC, dh_dt, PowerExcess] = FlyAircraft(PC);

    % enforce minimum battery SOC and maximum rate of climb.
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

    % The climb derate is used only while sizing the installed motors.
    % During mission optimization the full installed motor rating is
    % available throughout the optimized takeoff-to-cruise window.
    OutAircraft.Specs.Power.LamUps.Miss(pts, iEM) = 1;
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
SegEnd = Mission.SegEnd(ClimbSegs(end));
pts = (SegBeg:SegEnd)';
end
