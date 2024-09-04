function [RetrofitAC] = Retrofit(ConvAC,Options)
%
% [RetrofitAC] = Retrofit(ConvAC,Options)
% written by Maxfield Arnson, marnson@umich.edu
% last updated: 29 Jan 2024
%
%
% perform a retrofit of a conventional aircraft with electrified systems.
% as of the last update, only a parallel hybrid electric architecture is
% supported, powered by batteries.
%
% INPUTS:  ConvAC          - "Conventional Aircraft"
%                          this is a sized aircraft structure, which would
%                          have been an output from running an on-design
%                          Main() function call. This aircraft should be
%                          100% conventional, i.e. no electrified
%                          propulsion architecture.
%                          size: 1x1 struct
%
%          Options         - this is a structure containing the parameters
%                          for the retrofit. see
%                          RetrofitPkg.OptionsList.ExampleOptions for more
%                          information
%                          size: 1x1 struct
%
%
% OUTPUTS: RetrofitAC      - a structure containing information about the
%                          aircraft after it has been retrofit with an
%                          electrified system. Information added to the
%                          structure will be a mission history, and a sized
%                          aircraft with the same MTOW as it's conventional
%                          counterpart. The payload is reduced and the fuel
%                          savings/ increased range / payload reduction 9is
%                          reported
%

% ----------------------------------------------------------

% initial cleanup
clc, close all

%% Pre Processing

% Input aircraft must be a conventional aircraft
if ConvAC.Specs.Propulsion.Arch.Type ~= "C"
    error('Retrofitting can only be performed on an aircraft with a conventional (fuel burning only) propulsion system architecture.')
end

% Input aircraft must already be sized
if ~ConvAC.Settings.Converged
    error('Retrofitting must be performed on a sized aircraft. Please size your aircraft using Main() before attempting a retrofit')
end


% check for 0 thrust split or 0 pay or 0 electric motors

if Options.ThrustSplit <=0 || Options.ThrustSplit > 1
    error('Options.ThrustSplit must be set to a positive percentage in the range (0,1].')
end

if Options.NumMotors <1 || mod(Options.NumMotors,1) ~= 0
    error('Options.NumMotors must be set to a positive integer.')
end

if Options.PayDecrease < 0
    error('Options.PayDecrease may not be less than zero. Payload decrease cannot be negative.')
elseif Options.PayDecrease == 0
    warning('Options.PayDecrease should not be zero. Payload decrease of 0% would yields an identical aircraft to the conventional input.')
    RetrofitAC = ConvAC;
    return
elseif Options.PayDecrease > 1
    error('Options.PayDecrease may not be larger than one. 100% payload decrease is the maximum that can be subtracted from the conventional aircraft. Please enter a percentage in the range (0,1].')
end



% other electric inputs required?

% allow for inputs to decide how to spend weight budget


RetrofitAC = ConvAC;
RetrofitAC.Settings.Analysis.Type = -2;
RetrofitAC.Settings.VisualizeAircraft = 0;
RetrofitAC.Settings.Plotting = 0;

%% Set architecture

% parse inputs
Nmot = Options.NumMotors;
Neng = ConvAC.Specs.Propulsion.NumEngines;

MaxPow = max(ConvAC.Mission.History.SI.Power.TV);

% Update Neng
Neng = Neng - Nmot;
if Neng < 0
    error('Too many electric motors. Cannot exceed number of engines on the conventional aircraft.')
end

% Update engine weight
SingleEngineWeight = EngineWeightFxn(MaxPow/Neng,ConvAC.Specs.TLAR.Class);
RetrofitAC.Specs.Weight.Engines = Neng*SingleEngineWeight;
DeltaWeng = ConvAC.Specs.Weight.Engines - RetrofitAC.Specs.Weight.Engines;

% Update Number of Engines
RetrofitAC.Specs.Propulsion.NumEngines = Neng;


% architecture is always nonstandard
RetrofitAC.Specs.Propulsion.Arch.Type = "O";

% thrust-power source matrix
RetrofitAC.Specs.Propulsion.PropArch.TSPS = eye(Nmot+Neng);

% power-power source matrix
RetrofitAC.Specs.Propulsion.PropArch.PSPS = eye(Nmot+Neng);

% power-energy source matrix
RetrofitAC.Specs.Propulsion.PropArch.PSES  = [repmat([1,0],Neng,1); repmat([0,1],Nmot,1)];

% thrust      source operation
RetrofitAC.Specs.Propulsion.Oper.TS   = @(lambda) [(1-lambda)/Neng*ones(1,Neng),(lambda)/Nmot*ones(1,Nmot)];

% thrust-power source operation
RetrofitAC.Specs.Propulsion.Oper.TSPS = @() eye(Neng+Nmot);

% power-power  source operation
RetrofitAC.Specs.Propulsion.Oper.PSPS = @() eye(Neng+Nmot);

% power-energy source operation
RetrofitAC.Specs.Propulsion.Oper.PSES = @() [repmat([1,0],Neng,1); repmat([0,1],Nmot,1)];

% thrust-power source efficiency
EtaTSPS = 0.8*ones(Neng+Nmot,1);

if ConvAC.Specs.TLAR.Class == "Turbofan"
    EtaTSPS(1:Neng) = ones(Neng,1);
end
RetrofitAC.Specs.Propulsion.Eta.TSPS  = ones(Neng+Nmot) + diag(EtaTSPS-1);

% power-power  source efficiency
RetrofitAC.Specs.Propulsion.Eta.PSPS  = ones(Neng+Nmot);

% power-energy source efficiency
RetrofitAC.Specs.Propulsion.Eta.PSES = [repmat([1,1],Neng,1); repmat([1,0.96],Nmot,1)];

% energy source type (1 = fuel, 0 = battery)
RetrofitAC.Specs.Propulsion.PropArch.ESType = [1, 0];

% power source type (1 = engine, 0 = electric motor)
RetrofitAC.Specs.Propulsion.PropArch.PSType = [ones(1,Neng),zeros(1,Nmot)];



% thrust splits (thrust / total thrust)
lam = Options.ThrustSplit;
RetrofitAC.Specs.Power.LamTS.Tko = lam;
RetrofitAC.Specs.Power.LamTS.Clb = lam;
RetrofitAC.Specs.Power.LamTS.Crs = lam;
RetrofitAC.Specs.Power.LamTS.Des = lam;
RetrofitAC.Specs.Power.LamTS.Lnd = lam;
RetrofitAC.Specs.Power.LamTS.SLS = lam;


%% Sizing Setup %%



% assign MTOW from the conventional case
MTOW = ConvAC.Specs.Weight.MTOW;

% reduce payload
RetrofitAC.Specs.Weight.Payload = ConvAC.Specs.Weight.Payload*(1-Options.PayDecrease);
RetrofitAC.Specs.TLAR.MaxPax = RetrofitAC.Specs.Weight.Payload/95;

% set initial budget
Budget = ConvAC.Specs.Weight.Payload*(Options.PayDecrease) + DeltaWeng;

% set EM specific power
RetrofitAC.Specs.Power.P_W.EM = Options.PW_EM*1e3;


% set EG Spec Power
RetrofitAC.Specs.Power.P_W.EG = NaN;

% size electric motors
EMweight = max(ConvAC.Mission.History.SI.Power.TV)/1e3*Options.ThrustSplit/Options.PW_EM;
RetrofitAC.Specs.Weight.EM = EMweight;

% clear mission history
RetrofitAC = DataStructPkg.ClearMission(RetrofitAC);


% remove electric motor weight from weight budget
Budget = Budget - EMweight;


% is the budget negative?
if Budget < 0
    warning('Electric Motors are too heavy to include any batteries.')
    RetrofitAC.FuelSavings = 0;
    RetrofitAC.SuccessfulRetrofit = false;
    return;
end

% spend remaining budget on batteries
RetrofitAC.Specs.Weight.Batt = Budget;

% Update OEW
RetrofitAC.Specs.Weight.OEW = RetrofitAC.Specs.Weight.Airframe + EMweight + RetrofitAC.Specs.Weight.Engines;

% Update MTOW
RetrofitAC.Specs.Weight.MTOW = RetrofitAC.Specs.Weight.OEW + RetrofitAC.Specs.Weight.Payload + RetrofitAC.Specs.Weight.Batt + RetrofitAC.Specs.Weight.Fuel + RetrofitAC.Specs.Weight.Crew;


% set battery spec energy to user input
RetrofitAC.Specs.Power.SpecEnergy.Batt = Options.BattSpecEnergy*3.6e6;

%% Set Battery Model Stuff
RetrofitAC.Specs.Power.Battery.ParCells = NaN;
RetrofitAC.Specs.Power.Battery.SerCells = NaN;
RetrofitAC.Specs.Power.Battery.BegSOC = NaN;

%% Sizing %%


% set iteration parameters
tol = 1e-3;
iter = 1;
maxiter = 50;
err = 1;

%RetrofitAC.Specs.Weight.Payload


% parse input to decide which iteration to run
switch Options.SavingsType

    case "Fuel"
        % iterate on battery weight until TOGW os equal to MTOW
        while err > tol && iter <= maxiter
            RetrofitAC = Main(RetrofitAC,ConvAC.Mission.ProfileFxn);
            TOGW = RetrofitAC.Specs.Weight.MTOW;
            BudgetDelta = MTOW - TOGW;
            RetrofitAC.Specs.Weight.Batt = RetrofitAC.Specs.Weight.Batt + BudgetDelta;
            RetrofitAC.Specs.Weight.MTOW = RetrofitAC.Specs.Weight.MTOW + BudgetDelta;
            err = abs(TOGW - MTOW)/MTOW;
            iter = iter+1;
        end

    case "Payload"
        % iterate on payload weight until TOGW os equal to MTOW
        while err > tol && iter <= maxiter
            RetrofitAC = Main(RetrofitAC,ConvAC.Mission.ProfileFxn);
            TOGW = RetrofitAC.Specs.Weight.MTOW;
            %             BudgetDelta(iter) = MTOW - TOGW
            %             Pay(iter) = RetrofitAC.Specs.Weight.Payload
            %             WBatt(iter) = RetrofitAC.Specs.Weight.Batt
            %             WFuel(iter) = RetrofitAC.Specs.Weight.Fuel
            %             err_vec(iter) = err
            RetrofitAC.Specs.Weight.Payload = RetrofitAC.Specs.Weight.Payload + BudgetDelta(iter);
            RetrofitAC.Specs.Weight.MTOW = RetrofitAC.Specs.Weight.MTOW + BudgetDelta(iter);
            RetrofitAC.Specs.TLAR.MaxPax = RetrofitAC.Specs.Weight.Payload/95;
            err = abs(TOGW - MTOW)/MTOW;
            iter = iter+1;
        end

    case "Range"
        % ensure that the mission range is not hardcoded
        warning('Ensure the mission profile range in the mission profile function is parameterized by the range in the conventional aircraft specification file. i.e. do not use a hardcoded mission range in your conventional mission profile specification file.')
        % iterate on range until TOGW is equal to MTOW
        tol = 1e-4;
        while err > tol && iter <= maxiter
            RetrofitAC = Main(RetrofitAC,ConvAC.Mission.ProfileFxn);
            TOGW = RetrofitAC.Specs.Weight.MTOW;
            multiplier = 1 - (TOGW - MTOW) / MTOW;
            RetrofitAC.Specs.Performance.Range = RetrofitAC.Specs.Performance.Range*multiplier;
            err = abs(TOGW - MTOW)/MTOW;
            iter = iter+1;
        end


    otherwise
        error("Invalid option set for variable: Options.SavingsType, please see documentation for details.")
end




%% Assign OutPuts

RetrofitAC.Specs.TLAR.MaxPax = floor(RetrofitAC.Specs.Weight.Payload/95);


% compared to conventional on design (MTOW)
ConvAC_on = ConvAC;


% compared to conventional off design (same payload)
ConvAC_off = ConvAC;
ConvAC_off.Settings.VisualizeAircraft = 0;
ConvAC_off.Settings.Plotting = 0;
ConvAC_off.Settings.Analysis.Type = -2;
ConvAC_off.Specs.Weight.Payload = ConvAC.Specs.Weight.Payload*(1-Options.PayDecrease);
ConvAC_off.Specs.TLAR.MaxPax = ConvAC_off.Specs.Weight.Payload/95;
ConvAC_off.Specs.Weight.MTOW = ConvAC_off.Specs.Weight.MTOW - ConvAC.Specs.Weight.Payload*Options.PayDecrease;



if Options.SavingsType == "Range"
    ConvAC_off.Specs.Performance.Range = RetrofitAC.Specs.Performance.Range;
end

ConvAC_off = Main(ConvAC_off,ConvAC.Mission.ProfileFxn);




% Fuel savings in percent relative to both the on design and off design
% conventional aircraft
RetrofitAC.FuelSavings.On = (RetrofitAC.Specs.Weight.Fuel - ConvAC_on.Specs.Weight.Fuel)/ConvAC_on.Specs.Weight.Fuel*100;
RetrofitAC.FuelSavings.Off = (ConvAC_off.Specs.Weight.Fuel - ConvAC_on.Specs.Weight.Fuel)/ConvAC_on.Specs.Weight.Fuel*100;

RetrofitAC.RangeSavings.On = (RetrofitAC.Specs.Performance.Range - ConvAC_on.Specs.Performance.Range)/ConvAC_on.Specs.Performance.Range*100;
RetrofitAC.RangeSavings.Off = (ConvAC_off.Specs.Performance.Range - ConvAC_on.Specs.Performance.Range)/ConvAC_on.Specs.Performance.Range*100;

RetrofitAC.PayRebate = Options.PayDecrease - (1 - RetrofitAC.Specs.Weight.Payload/ConvAC.Specs.Weight.Payload);



% Return params used in this retrofit
Options.PayDecrease = 1 - RetrofitAC.Specs.Weight.Payload/ConvAC.Specs.Weight.Payload;
RetrofitAC.RetroParams = Options;





if iter >= maxiter+1
    warning('Retrofitting did not converge on a solution.')
    RetrofitAC.SuccessfulRetrofit = false;
else
    RetrofitAC.SuccessfulRetrofit = true;
end

end



%% Regression function used to predict new engine weights
function [Weng] = EngineWeightFxn(Power,aclass)

if      (strcmpi(aclass, "Turbofan" ) == 1)

    % predict engine weight using the design thrust
    load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
    IO = {["Thrust_Max"],["DryWeight"]};

    % row vector can have multiple targets for a single input
    target = Thrust(Eng)';

    % run the regression
    Weng = RegressionPkg.NLGPR(TurbofanEngines,IO,target);

elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1) )

    % Predict Engine Weight using SLS power
    load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
    [~,WengReg] = RegressionPkg.SearchDB(TurbopropEngines,["DryWeight"]);
    WengReg = cell2mat(WengReg(:,2));
    [~,PowReg] = RegressionPkg.SearchDB(TurbopropEngines,["Power_SLS"]);
    PowReg = cell2mat(PowReg(:,2));
    cind = [];
    for ii = 1:length(PowReg)
        if isnan(PowReg(ii)) || isnan(WengReg(ii))
            cind = [cind,ii];
        end
    end
    WengReg(cind) = [];
    PowReg(cind) = [];
    W_f_of_pow = polyfit(PowReg,WengReg,1);

    % estimate the engine weights
    Weng = polyval(W_f_of_pow, Power / 1000);

else

    % throw error
    error("ERROR - PropulsionSizing: invalid aircraft class.");

end

end

