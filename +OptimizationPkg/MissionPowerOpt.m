function [OptAircraft, PCbest, t] = MissionPowerOpt(Aircraft, ProfileFxn)
%
% OptAircraft = MissionPowerOpt(Aircraft, ProfileFxn)
% written by Emma Cassidy, emmasmit@umich.edu
% updated for mission-indexed PowerOpt scheduling
%
% Optimize the PHE electric downstream power split over the first mission
% from takeoff through the end of cruise. The optimizer works on the
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

% Keep optimizer evaluations serial because the nested objective caches the
% last mission evaluation and mutates a local Aircraft copy.
options = optimoptions("fmincon", ...
                       "MaxIterations", MaxOptIter, ...
                       "Display", "iter", ...
                       "Algorithm", "sqp", ...
                       "UseParallel", false);

% objective function convergence tolerance
options.OptimalityTolerance = 1.0e-8;

% step size convergence
options.StepTolerance = 1.0e-8;


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
Aircraft.Settings.PowerOpt = 1;

% no mission history table
Aircraft.Settings.Table = 0;

% Build the same mission and propulsion metadata Main will use. This lets
% the optimizer derive the takeoff-through-cruise point range from the
% actual mission profile instead of stale hard-coded indices.
Aircraft0 = PrepareMissionAircraft(Aircraft, ProfileFxn);

% optimize the first mission from takeoff through the end of its final
% cruise segment.
pts = FirstMissionTakeoffToCruise(Aircraft0);

% get architecture indices used to apply a symmetric PHE split.
TrnType = Aircraft0.Specs.Propulsion.PropArch.TrnType;
iEM  = find(TrnType == 0);
iGT  = find(TrnType == 1);
iFan = find(TrnType == 2);

if (isempty(iEM) || isempty(iGT) || isempty(iFan))
    error("ERROR - MissionPowerOpt: PowerOpt currently expects a PHE architecture with engines, electric motors, and fans.");
end

% get starting electric downstream split from the mission-filled schedule.
PC0 = mean(Aircraft0.Specs.Power.LamDwn.Miss(pts, iEM), 2);
PC0(isnan(PC0)) = 0;
PC0 = min(max(PC0, 0), 0.9);

% keep electric assist bounded below full electric contribution so the gas
% turbine path remains available for the main mission.
lb = zeros(size(PC0));
ub = 0.9 .* ones(size(PC0));

% save storage values for objective/constraint caching.
PClast = [];
fburn = [];
SOC = [];
dh_dt = [];


%% RUN THE OPTIMIZER %%
%%%%%%%%%%%%%%%%%%%%%%

tic
if (MaxOptIter < 1)
    % Smoke-test path: evaluate the current mission split without launching
    % fmincon's finite-difference loop.
    PCbest = PC0;
    ObjFunc(PCbest);
    Cons(PCbest);
else
    PCbest = fmincon(@(PC) ObjFunc(PC), PC0, [], [], [], [], lb, ub, @(PC) Cons(PC), options);
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

function [fburnOut, SOCOut, RCOut] = FlyAircraft(PC)
    % input updated mission split schedule
    TestAircraft = ApplyPowerSplit(Aircraft0, PC);

    try
        % Fly the already-sized aircraft directly. Calling Main here enters
        % EAPAnalysis, whose first pass calls PropulsionSizing even for the
        % retrofit (-2) mode and therefore changes motor and aircraft size.
        TestAircraft = FlyFixedAircraft(TestAircraft);

        % fuel required for mission
        fburnOut = TestAircraft.Mission.History.SI.Weight.Fburn(end);
        if (fburnOut < 0)
            fburnOut = 1.0e10;
        end

        % constrain SOC over the whole flown mission, not only the optimized
        % window, so cruise optimization cannot deplete the reserve mission.
        Batt = TestAircraft.Specs.Propulsion.PropArch.SrcType == 0;
        if (any(Batt))
            SOCOut = TestAircraft.Mission.History.SI.Power.SOC(:, Batt);
        else
            SOCOut = 100;
        end

        % climb-rate constraint is applied only over the optimized window.
        RCOut = TestAircraft.Mission.History.SI.Performance.RC(pts);

    catch
        % Penalize failed mission evaluations and return constraint values
        % that fmincon will reject.
        fburnOut = 1.0e10;
        SOCOut = -1;
        RCOut = Aircraft0.Specs.Performance.RCMax + ones(size(pts));
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
    % check if PC values changed
    if ~isequal(PC, PClast)
        [fburn, SOC, dh_dt] = FlyAircraft(PC);
        PClast = PC;
    end

    % return objective function value
    val = fburn;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Constraints                %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c, ceq] = Cons(PC)
    % check if PC values changed
    if ~isequal(PC, PClast)
        [fburn, SOC, dh_dt] = FlyAircraft(PC);
        PClast = PC;
    end

    % enforce minimum battery SOC and maximum rate of climb.
    cSOC = Aircraft0.Specs.Battery.MinSOC - SOC(:);
    cRC = dh_dt(:) - Aircraft0.Specs.Performance.RCMax;

    % output constraints
    c = [cSOC; cRC];
    ceq = [];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Split Application          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [OutAircraft] = ApplyPowerSplit(InAircraft, PC)
    OutAircraft = InAircraft;

    % Enforce symmetric electric assist on all electric motors and balance
    % the complementary downstream split on all gas turbines.
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iEM) = repmat(PC, 1, length(iEM));
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iGT) = repmat(1 - PC, 1, length(iGT));

    % Keep fan demand evenly distributed for the PHE twin-fan architecture.
    OutAircraft.Specs.Power.LamDwn.Miss(pts, iFan) = repmat(1 / length(iFan), length(pts), length(iFan));

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


function [pts] = FirstMissionTakeoffToCruise(Aircraft)
% Return mission-history indices from first takeoff point through the end of
% the final cruise segment in mission ID 1.

Mission = Aircraft.Mission.Profile;
MissionID = 1;

InMission = Mission.ID == MissionID;
TakeoffSegs = find(InMission & (strcmpi(Mission.Segs, "Takeoff") | strcmpi(Mission.Segs, "DetailedTakeoff")));
CruiseSegs = find(InMission & strcmpi(Mission.Segs, "Cruise"));

if (isempty(TakeoffSegs) || isempty(CruiseSegs))
    error("ERROR - MissionPowerOpt: first mission must include takeoff and cruise segments.");
end

SegBeg = Mission.SegBeg(TakeoffSegs(1));
SegEnd = Mission.SegEnd(CruiseSegs(end));
pts = (SegBeg:SegEnd)';
end
