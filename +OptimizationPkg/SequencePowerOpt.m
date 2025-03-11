function [OptimizedAircraft, PCbest, t, OptSeqTable] = SequencePowerOpt(Aircraft, Sequence)
%
% OptAicraft = SequencePowerOpt(Aircraft)
% written by Emma Cassidy, emmasmit@umich.edu
% last updated: Feb 2024
%
% Optimize electric motor power code on an off-design mission for a
% parallel-hybrid propulsion architecture.
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

% number of missions to fly
nflight = height(Sequence);

% setup a table large enough for all flights
% note that 24 = number of data metrics returned (setup in varTypes/Names)
sz = [nflight, 13];

% list the variable types to be returned in the table (24 total)
varTypes = ["double", "double", "double", "double",...
            "double", "double", "double", "double", ...
            "double", "double", "double", "double", ...
             "double"                                  ] ;

% list the variable names to be returned in the table (24 total)
varNames = ["Segment"               , ...
            "Distance (nmi)"        , ...
            "Ground Time (min)"     , ...
            "TOGW (kg)"             , ...
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

% set up optimization algorithm and command window output
% Default - interior point w/ max 50 iterations
options = optimoptions('fmincon','MaxIterations', 100 ,'Display','iter','Algorithm','interior-point');

% objective function convergence tolerance
options.OptimalityTolerance = 10^-3;

% step size convergence
options.StepTolerance = 10^-6;

% max function evaluations
options.MaxFunctionEvaluations = 5000;

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

% climb beg and end ctrl pt indeces
n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;

% get intial power code
PC = Aircraft.Specs.Power.PC(n1:n2, [1,3]);
% expand across for each flight
PC0 = repmat(PC, 1, nflight);
b = size(PC0);
lb = zeros(b);
ub = ones(b);

% save storage values
PClast = [];
fburn = [];
SOC    = [];
OptimizedAircraft = [];
dh_dt = [];
g = 9.81;
%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
PCbest = fmincon(@(PC0) ObjFunc(PC0, Aircraft, Sequence), PC0, [], [], [], [], lb, ub, @(PC0) Cons(PC0, Aircraft, Sequence), options);
t = toc/60

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%
for iflight =1:nflight
        nameAC = sprintf("OptAircraft%d", iflight);
        Aircraft = OptimizedAircraft.(nameAC);
        results = AnaylzeMiss(Aircraft);
        
        OptSeqTable{iflight, :}= [iflight, Sequence.DISTANCE(iflight),...
                                Sequence.GROUND_TIME(iflight), results] ;
end
disp(PCbest)

save("Opt_10ctrlpts_test.mat", "OptimizedAircraft");
save("opttable.mat", "OptSeqTable");
    
%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%

function [fburn, SOC, dh_dt] = FlySequence(PC, Aircraft, Sequence)
    fburn = 0;
    % iterate through missions
    for iflight = 1:nflight
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %                            %
        % extract flight performance %
        % parameters from the table  %
        %                            %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
        % cruise speed
        speed = Sequence.SPEED_mph(iflight);
        
        % mission range
        Range = Sequence.DISTANCE(iflight); 
    
        % cruise altitude
        Alt = Sequence.ALTITUDE_m(iflight);
        
        % ground time (mimutes)
        if iflight < nflight
            ChargeTimeMin = Sequence.GROUND_TIME(iflight+1) - 5;
        else
            ChargeTimeMin = 1e3;
        end
        
        % payload
        Wpayload = Sequence.PAYLOAD_lb(iflight);
    
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
        PC_MISS = PC(:, iflight*2-1 : iflight*2);
        Aircraft.Specs.Power.PC(n1:n2, [1,3]) = PC_MISS;
        Aircraft.Specs.Power.PC(n1:n2, [2,4]) = PC_MISS;

        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Optimized HEA power for    %
        %           mission          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        

        % run optimizer
        Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

        % save fuel burn
        fburn = fburn + Aircraft.Mission.History.SI.Weight.Fburn(73);

        % SOC for mission
        SOC(iflight, :) = Aircraft.Mission.History.SI.Power.SOC(n1:n2+1,2);

        % rate of climb
        dh_dt(iflight, :) = Aircraft.Mission.History.SI.Performance.RC(n1:n2+1);

        % charge battery
        Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);

        % assign charges SOC to begSOC for next flight
        Aircraft.Specs.Battery.BegSOC = Aircraft.Mission.History.SI.Power.ChargedAC.SOC(end);
        
        % save optimized aircraft struct
        nameAC = sprintf("OptAircraft%d", iflight);
        OptimizedAircraft.(nameAC) = Aircraft;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC, Aircraft, Sequence)
    % check if PC values changes
    if ~isequal(PC, PClast)
        [fburn, SOC, dh_dt] = FlySequence(PC, Aircraft, Sequence);
        PClast = PC;
        %disp(PC)
    end
    % return objective function value
    val = fburn;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% SOC Constraint             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function [c, ceq] = Cons(PC, Aircraft, Sequence)
    % check if PC values changes
    if ~isequal(PC, PClast)
        [fburn, SOC, dh_dt] = FlySequence(PC, Aircraft, Sequence);
        PClast = PC;
    end
    % compute SOC constraint
    cSOC = Aircraft.Specs.Battery.MinSOC - SOC;

    % compute RC constraint
    cRC = dh_dt - Aircraft.Specs.Performance.RCMax;

    % out put constraints
    c = [cSOC; cRC];
    ceq = [];

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
Results = [TOGW, Fburn, EBatt, SOCbeg, SOCtko, SOCclb, SOCf, TSFC_tko, TSFC_clb, TSFC_crs];

end

end

