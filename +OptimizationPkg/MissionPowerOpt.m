function OptAircraft = MissionPowerOpt(Aircraft)

%
% OptAicraft = MissionPowerOpt(Aircraft)
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

% get starting point
PC0 = Aircraft.Mission.History.SI.Power.PC(n1:n2, [1,3]);
b = size(PC0);
lb = zeros(b);
ub = ones(b);

% save storage values
PClast = [];
fburn = [];
SOC    = [];
Ps = [];
g = 9.81;
%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
PCbest = fmincon(@(PC0) ObjFunc(PC0, Aircraft), PC0, [], [], [], [], lb, ub, @(PC) Cons(PC, Aircraft), options);
t = toc 

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%
fburnOG = PCvFburn(PC0, Aircraft);
fburnOpt = PCvFburn(PCbest, Aircraft);
fdiff = (fburnOpt - fburnOG)/fburnOG;
pout = sprintf("Fuel Burn Reduction: %f", fdiff);
disp(pout)

n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;
Aircraft.Specs.Power.PC(n1:n2, [1,3]) = PCbest;
Aircraft.Specs.Power.PC(n1:n2, [2,4]) = PCbest;
Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
OptAircraft = Aircraft;
    
%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
%  Function Evaluation        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fburn, SOC, Ps] = FlyAircraft(PC, Aircraft)
    % get climb beg and end indeces
    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    % input updated PC
    Aircraft.Specs.Power.PC(n1:n2, [1,3]) = PC;
    Aircraft.Specs.Power.PC(n1:n2, [2,4]) = PC;
    % fly off design mission
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    
    % fuel required for mission
    fburn = Aircraft.Specs.Weight.Fuel;

    % SOC for mission
    SOC = Aircraft.Mission.History.SI.Power.SOC(n1:n2,2);

    % check if enough power for desired climb profile
    % extract climb TAS
    V = Aircraft.Mission.History.SI.Performance.TAS(n1:n2);
    % mass during climb
    m = Aircraft.Mission.History.SI.Weight.CurWeight(n1:n2);
    % lift
    L = g .* m;
    % drag
    D = L ./ Aircraft.Specs.Aero.L_D;
    % rate of climb
    RC = Aircraft.Mission.History.SI.Performance.RC(n1:n2);
    % acceleration during climb
    a = Aircraft.Mission.History.SI.Performance.Acc(n1:n2);
    % power avaliable 
    TV = Aircraft.Mission.History.SI.Power.TV(n1:n2);
    % excess power 
    Ps = D.* V + m.*g.*RC + m.*V.*a - TV;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [val] = ObjFunc(PC, Aircraft)
    % check if PC values changes
    if ~isequal(PC, PClast)
        [fburn, SOC, Ps] = FlyAircraft(PC, Aircraft);
        PClast = PC;
    end
    % return objective function value
    val = fburn;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% SOC Constraint             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function [c, ceq] = Cons(PC, Aircraft)
    % check if PC values changes
    if ~isequal(PC, PClast)
        [fburn, SOC, Ps] = FlyAircraft(PC, Aircraft);
        PClast = PC;
    end
    % compute SOC constraint
    cSOC = 20 - SOC;

    % out put constraints
    c = [cSOC; Ps;];
    ceq = [];

end

end

