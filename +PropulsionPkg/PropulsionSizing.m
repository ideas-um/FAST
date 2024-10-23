function [Aircraft] = PropulsionSizing(Aircraft)
%
% [Aircraft] = PropulsionSizing(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 03 oct 2024
%
% Split the total thrust/power throughout the powertrain and determine the
% total power needed to size each component.
%
% INPUTS:
%     Aircraft - aircraft structure to get information about the aircraft
%                type and the propulsion system.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure updated with the weights of the power
%                sources.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% obtain quantities from the %
% aircraft structure         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% analysis type
atype = Aircraft.Settings.Analysis.Type;

% get the takeoff speed
TkoVel = Aircraft.Specs.Performance.Vels.Tko;

% get the power source type
PSType = Aircraft.Specs.Propulsion.PropArch.PSType;

% find the engines and electric motors
Eng = PSType == 1;
EM  = PSType == 0;

% get the electric motor power-weight ratio
P_Wem = Aircraft.Specs.Power.P_W.EM;

% get the propulsion architecture
TSPS = Aircraft.Specs.Propulsion.PropArch.TSPS;
PSPS = Aircraft.Specs.Propulsion.PropArch.PSPS;

% get the design splits
LamTS   = Aircraft.Specs.Power.LamTS.SLS  ;
LamTSPS = Aircraft.Specs.Power.LamTSPS.SLS;
LamPSPS = Aircraft.Specs.Power.LamPSPS.SLS;

% get propulsion system efficiencies
EtaPSPS = Aircraft.Specs.Propulsion.Eta.PSPS;

% check the aircraft class
if      (strcmpi(aclass, "Turbofan" ) == 1)
    
    % get the fan efficiency
    EtaFan = Aircraft.Specs.Propulsion.Engine.EtaPoly.Fan;
    
elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1)  )
    
    % there is no fan, assume perfect efficiency
    EtaFan = 1;
    
else
    
    % throw error
    error("ERROR - PropulsionSizing: invalid aircraft class provided.");
    
end

% check if the power optimization structure is available
if (isfield(Aircraft, "PowerOpt"))
    
    % check if the splits are available
    if (isfield(Aircraft.PowerOpt, "Splits"))
        
        % get the number of operational splits
        nopers = Aircraft.PowerOpt.nopers;
        
        % count the number of design splits
        tsplit = 1;
        
        % check for design thrust splits
        if (Aircraft.PowerOpt.Settings.DesnTS   == 1)
            
            % get the number of thrust splits
            nsplit = Aircraft.Settings.nargTS  ;
            
            % get the splits
            for isplit = 1:nsplit
                
                % get the current split
                LamTS(  isplit) = Aircraft.PowerOpt.Splits(nopers + tsplit);
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
        end
        
        % check for design thrust-power splits
        if (Aircraft.PowerOpt.Settings.DesnTSPS == 1)
            
            % get the number of thrust-power splits
            nsplit = Aircraft.Settings.nargTSPS;
            
            % get the splits
            for isplit = 1:nsplit
                
                % get the current split
                LamTSPS(isplit) = Aircraft.PowerOpt.Splits(nopers + tsplit);
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
        end
        
        % check for design power-power splits
        if (Aircraft.PowerOpt.Settings.DesnPSPS == 1)
            
            % get the number of power-power splits
            nsplit = Aircraft.Settings.nargPSPS;
            
            % get the splits
            for isplit = 1:nsplit
                
                % get the current split
                LamPSPS(isplit) = Aircraft.PowerOpt.Splits(nopers + tsplit);
                
                % account for the split
                tsplit = tsplit + 1;
                
            end
        end
    end
end


%% SIZE THE PROPULSION SYSTEM %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the SLS power depending on the aircraft class
if      (strcmpi(aclass, "Turbofan" ) == 1)
    
    % get the total thrust (t/w * mtow)
    T0 = Aircraft.Specs.Propulsion.Thrust.SLS;
    
    % get the total power (de-rate to account for not being static)
    P0 = 0.95 * T0 * TkoVel;
    
elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
        (strcmpi(aclass, "Piston"   ) == 1)  )
    
    % get the total power  (p/w * mtow)
    P0 = Aircraft.Specs.Power.SLS;
    
end

% get the power/thrust split function handles
FunSplitTS   = Aircraft.Specs.Propulsion.Oper.TS  ;
FunSplitTSPS = Aircraft.Specs.Propulsion.Oper.TSPS;
FunSplitPSPS = Aircraft.Specs.Propulsion.Oper.PSPS;

% get the splits
LamTS   = Aircraft.Specs.Power.LamTS.SLS;
LamTSPS = Aircraft.Specs.Power.LamTSPS.SLS;
LamPSPS = Aircraft.Specs.Power.LamPSPS.SLS;

% get function to compute the thrust/power splits
SplitTS   = PropulsionPkg.EvalSplit(FunSplitTS  , LamTS  );
SplitTSPS = PropulsionPkg.EvalSplit(FunSplitTSPS, LamTSPS);
SplitPSPS = PropulsionPkg.EvalSplit(FunSplitPSPS, LamPSPS);

% split the power amongst the power sources
[PowerPS, PowerDr] = PropulsionPkg.SplitPower(Aircraft, P0, SplitTS, SplitTSPS, SplitPSPS);

% get the supplemental power
Psupp = PropulsionPkg.PowerSupplementCheck(PowerDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, EtaFan);

% convert power to thrust
ThrustPS = PowerPS ./ TkoVel;
Tsupp    = Psupp   ./ TkoVel;

% remember the power  available/supplemented for each power source
Aircraft.Specs.Propulsion.SLSPower   = PowerPS ;
Aircraft.Specs.Propulsion.PowerSupp  = Psupp   ;

% remember the thrust available/supplemeneted for each power source
Aircraft.Specs.Propulsion.SLSThrust  = ThrustPS;
Aircraft.Specs.Propulsion.ThrustSupp = Tsupp   ;

% check for a fully-electric architecture (so engines don't get sized)
if (any(PSType > 0))

    % lapse thrust/power for turbofan/turboprops, respectively
    if      (strcmpi(aclass, "Turbofan" ) == 1)

        % predict engine weight using the design thrust
        TurbofanEngines = Aircraft.HistData.Eng;
        IO = {["Thrust_Max"],["DryWeight"]};

        % row vector can have multiple targets for a single input
        target = ThrustPS(Eng)';

        % run the regression
        Weng = RegressionPkg.NLGPR(TurbofanEngines,IO,target);
        
        % get the first engine index (assume all engines are the same)
        ieng = find(Eng, 1);
        
        % add flight conditions
        Aircraft.Specs.Propulsion.Engine.Alt = 0;
        Aircraft.Specs.Propulsion.Engine.Mach = 0.05;
        
        % check if the thrust supplement is positive
        if (Tsupp(ieng) > 0)
            
            % increase the engine size to generate all the thrust
            Aircraft.Specs.Propulsion.Engine.DesignThrust = ThrustPS(ieng) + Tsupp(ieng);
            
        else
            
            % leave the engine size as is, power is siphoned off
            Aircraft.Specs.Propulsion.Engine.DesignThrust = ThrustPS(ieng);
            
        end

        % turn on flag for sizing the engine
        Aircraft.Specs.Propulsion.Engine.Sizing = 1;
        
        % size the engine
        Aircraft.Specs.Propulsion.SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(Aircraft.Specs.Propulsion.Engine, Psupp(ieng));
        
        % turn off the sizing flags
        Aircraft.Specs.Propulsion.Engine.Sizing = 0; % unnnecessary
        Aircraft.Specs.Propulsion.SizedEngine.Specs.Sizing = 0;
        
    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )

        % Predict Engine Weight using SLS power
        TurbopropEngines = Aircraft.HistData.Eng;
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
        Weng = polyval(W_f_of_pow, PowerPS(Eng) / 1000);

    else

        % throw error
        error("ERROR - PropulsionSizing: invalid aircraft class.");

    end

else

    % no engines need to be sized
    Weng = 0;

end

% remember the weight of the engines
Aircraft.Specs.Weight.Engines = sum(Weng);

% check if the electric motor weight can be changed and remember it
if (atype > 0)
    Aircraft.Specs.Weight.EM = sum(PowerPS(EM)) / P_Wem;
end

% ----------------------------------------------------------

end