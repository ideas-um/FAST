function [OptimizedAircraft, PCbest, t, OptSeqTable] = SequencePowerOpt(Aircraft, Sequence)
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
Aircraft.Settings.Analysis.Type = -2;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% no mission history table
Aircraft.Settings.Table = 0;

Aircraft.Settings.PowerOpt = 1;
Aircraft.Settings.PowerStrat = -1;

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
ub = 0.9 .* ones(size(PC0));

% save storage values
PClast = [];
Objective = [];
SOC    = [];
dh_dt = [];
%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
if (MaxOptIter < 1)
    PCbest = PC0;
else
    PCbest = fmincon(@(PC) ObjFunc(PC, Aircraft, Sequence), PC0, [], [], [], [], lb, ub, @(PC) Cons(PC, Aircraft, Sequence), options);
end
t = toc / 60;

% Ensure the returned aircraft sequence corresponds exactly to PCbest,
% rather than whichever finite-difference point fmincon evaluated last.
FlySequence(PCbest, Aircraft, Sequence);

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%

for kflight = 1:nflight
        nameAC = sprintf("Aircraft%d", kflight);
        Aircraft = OptimizedAircraft.(nameAC);
        results = AnaylzeMiss(Aircraft);
        
        OptSeqTable{kflight, :}= [kflight, Sequence.DISTANCE(kflight),...
                                Sequence.GROUND_TIME(kflight), results] ;
end


save("SeqOptAC_futDOC.mat", "OptimizedAircraft");
save("opttable_futDOC.mat", "OptSeqTable");
    
%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%

    function [DOC,SOC, dh_dt]  = FlySequence(PC, Aircraft, Sequence)
    % Direct operating cost is the sequence objective.
    DOC = 0;
    SOC = zeros(length(pts), nflight);
    dh_dt = zeros(length(pts), nflight);

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
            ChargeTimeMin = Sequence.GROUND_TIME(jflight+1) - 5;
        else
            ChargeTimeMin = 1e3;
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

        %--------------------------------------------------------------
        % input design variables
        Aircraft = ApplyPowerSplit(Aircraft, PC(:, jflight));

        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Optimized HEA power for    %
        %           mission          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        

        % fly mission
        try
            Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
            %Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);
            
            % determine cost of flight
            Aircraft = CostPkg.EnergyCost_perAirport(Aircraft, Sequence.ORIGIN(jflight), priceTable);

            %objective function: DOC
            DOC = DOC + Aircraft.Specs.Cost.FOC;

            % rate of climb
            dh_dt(:, jflight) = Aircraft.Mission.History.SI.Performance.RC(pts);
        
            %SOC
            SOC(:, jflight) = Aircraft.Mission.History.SI.Power.SOC(pts,2);
        catch
            DOC = 10^15;
            dh_dt(:, jflight) = Aircraft.Specs.Performance.RCMax + ones(length(pts), 1);
            SOC(:, jflight) = -ones(length(pts), 1);
        end

       

     
        
        try
            % charge battery
            Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);
    
            % assign charges SOC to begSOC for next flight
            Aircraft.Specs.Battery.BegSOC = Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd;
        catch
            Aircraft.Specs.Battery.BegSOC = 20;
        end
        
        % save optimized aircraft struct
        nameAC = sprintf("Aircraft%d", jflight);
        OptimizedAircraft.(nameAC) = Aircraft;
    end

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
        [Objective, SOC, dh_dt] = FlySequence(PC, Aircraft, Sequence);
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
        [Objective, SOC, dh_dt] = FlySequence(PC, Aircraft, Sequence);
        PClast = PC;
    end
    % compute SOC constraint
    cSOC = Aircraft.Specs.Battery.MinSOC - SOC;

    % compute RC constraint
    cRC = dh_dt - Aircraft.Specs.Performance.RCMax;

    % out put constraints
    c = [cSOC(:); cRC(:)];
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

    % LamUps controls availability, not the optimized demand split.
    OutAircraft.Specs.Power.LamUps.Miss(pts, iEM) = 1;
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

end

