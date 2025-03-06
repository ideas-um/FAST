function [OptSeqTable, fSOC_Opt, OptmizedAircraft, t] = SequencePowerOpt(Aircraft, Sequence)

%% PRE-PROCESSING AND SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of missions to fly
nflight = height(Sequence);

% setup a table large enough for all flights
% note that 24 = number of data metrics returned (setup in varTypes/Names)
sz = [nflight, 14];

% list the variable types to be returned in the table (24 total)
varTypes = ["double", "string", "double", "double", "double",...
            "double", "double", "double", "double", ...
            "double", "double", "double", "double", ...
             "double"                                  ] ;

% list the variable names to be returned in the table (24 total)
varNames = ["Segment"               , ...
            "Type"                  , ...
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

% get starting point
fSOC = 20.*ones(nflight,1);
b = size(fSOC);
lb = ones(b)*19.5;
ub = ones(b)*100;

% save storage values
fSOC_last = [];
fburn = [];
iSOC   = [];
OptmizedAircraft = [];
g = 9.81;

%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
fSOC_Opt = fmincon(@(PC0) ObjFunc(fSOC, Aircraft, Sequence), fSOC, [], [], [], [], lb, ub, @(fSOC) Cons(fSOC, Aircraft), options);
t = toc/60

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%


%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%


function [fburn, iSOC] = FlySequence(fSOC, Aircraft, Sequence)
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
        ChargeTimeMin = Sequence.GROUND_TIME(iflight) - 5;
        
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

        % SOC depletion limit
        Aircraft.Specs.Power.Battery.EndSOC = fSOC(iflight);

        % ----------------------------------------------------------
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Optimized HEA power for    %
        %           mission          %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % run optimizer
        [OptAC, t(iflight)] = OptimizationPkg.MissionPowerOpt(Aircraft);

        % save optimized aircraft struct
        nameAC = sprintf("OptAircraft%d", iflight);
        OptmizedAircraft.(nameAC) = OptAC;
    
        % save fuel burn
        fburn = fburn + OptAC.Specs.Weight.Fburn;

        % charge battery
        iSOC = BatteryPkg.GroundCharge(OptAC, ChargeTime, )

    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
%  Objective Function        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    function [val] = ObjFunc(fSOC, Aircraft, Sequence)
    % check if PC values changes
    if ~isequal(fSOC, fSOC_last)
        [fburn, SOC] = FlySequence(fSOC, Aircraft, Sequence);
        fSOC_last = fSOC;
        %disp(PC)
    end
    % return objective function value
    val = fburn;
end

function d = PerDiff(a, b)
    d = (a-b)./a .* 100;
end