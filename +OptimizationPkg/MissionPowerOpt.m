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
options = optimoptions('fmincon','MaxIterations', 50 ,'Display','iter','Algorithm','interior-point');

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

% climb beg and end ctrl pt indeces
n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;

PC0 = Aircraft.Mission.History.SI.Power.PC(n1:n2, [1,3]);
b = size(PC0);
lb = zeros(b);
ub = ones(b);

%% Run the Optimizer %%
%%%%%%%%%%%%%%%%%%%%%%%%%
tic
PCbest = fmincon(@(PC0) PCvFburn(PC0, Aircraft), PC0, [], [], [], [], lb, ub, @(PC) SOC_Constraint(PC, Aircraft), options);
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
% Objective Function         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [fburn] = PCvFburn(PC, Aircraft)

    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    Aircraft.Specs.Power.PC(n1:n2, [1,3]) = PC;
    Aircraft.Specs.Power.PC(n1:n2, [2,4]) = PC;
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    
    fburn = Aircraft.Specs.Weight.Fuel;
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% SOC Constraint             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
function [c, ceq] = SOC_Constraint(PC, Aircraft)

    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    Aircraft.Specs.Power.PC(n1:n2, [1,3]) = PC;
    Aircraft.Specs.Power.PC(n1:n2, [2,4]) = PC;
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    
    SOC = Aircraft.Mission.History.SI.Power.SOC(:,2);
    c = 20 - SOC;
    ceq = [];
end

end

