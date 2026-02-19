function [Aircraft] = PropulsionSizing(Aircraft)
%
% [Aircraft] = PropulsionSizing(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 18 feb 2026
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

% get the takeoff speed
TkoVel = Aircraft.Specs.Performance.Vels.Tko;

% get the transmitter type
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% find the appropriate transmitters
EM   = TrnType == 0;
Eng  = TrnType == 1;
Prop = TrnType == 2;
EG   = TrnType == 3;
Cab  = TrnType == 4;

% get the electric motor power-weight ratio
P_Wem = Aircraft.Specs.Power.P_W.EM;
P_Weg = Aircraft.Specs.Power.P_W.EG;

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the design splits
LamDwn = Aircraft.Specs.Power.LamDwn.SLS;

% get propulsion system efficiencies
EtaDwn = Aircraft.Specs.Propulsion.PropArch.EtaDwn;

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
OperDwn = Aircraft.Specs.Propulsion.PropArch.OperDwn;

% get the power splits
Splits = PropulsionPkg.EvalSplit(OperDwn, LamDwn);

% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
ntrn = length(Aircraft.Specs.Propulsion.PropArch.TrnType);

% number of components
ncomp = length(Arch);

% get only the transmitter and sink indices
idx = (nsrc + 1) : ncomp;

% split the power amongst the power sources
Pdwn = PropulsionPkg.PowerFlow([zeros(1, ntrn), P0]', Arch(idx, idx)', Splits(idx, idx), EtaDwn(idx, idx), -1);

% get only the transmitter indicies
idx = nsrc + (1 : ntrn);

% get the supplemental power
Psupp = PropulsionPkg.PowerSupplementCheck(Pdwn(1:end-1)', Arch(idx, idx), Splits(idx, idx), EtaDwn(idx, idx), TrnType, EtaFan);

% convert power to thrust
Tdwn  = Pdwn  ./ TkoVel;
Tsupp = Psupp ./ TkoVel;

% remember the power  available/supplemented for each transmitter
Aircraft.Specs.Propulsion.SLSPower   = Pdwn(1:end-1)';
Aircraft.Specs.Propulsion.PowerSupp  = Psupp         ;

% remember the thrust available/supplemented for each transmitter
Aircraft.Specs.Propulsion.SLSThrust  = Tdwn(1:end-1)';
Aircraft.Specs.Propulsion.ThrustSupp = Tsupp         ;

% check that the inlet area matches the number of propulsors in the config.
if (length(Aircraft.Specs.Propulsion.InletArea) ~= ntrn)
    
    % create a properly sized array
    Aircraft.Specs.Propulsion.InletArea = NaN(1, ntrn);
    
end

% check for a fully-electric architecture (so engines don't get sized)
if (any(TrnType > 0 & TrnType ~= 2))

    % lapse thrust/power for turbofan/turboprops, respectively
    if      (strcmpi(aclass, "Turbofan" ) == 1)

        % predict engine weight using the design thrust
        TurbofanEngines = Aircraft.HistData.Eng;
        IO = {["Thrust_Max"],["DryWeight"]};

        % row vector can have multiple targets for a single input
        target = Tdwn(Eng);

        % run the regression - input must be a column vector
        Weng = RegressionPkg.NLGPR(TurbofanEngines,IO,target);

        % if the target was 0 thrust, no engine is needed (return 0 weight)
        Weng(target < 1.0e-06) = 0;
        
        % get all engine indices (no longer assume all are the same)
        ieng = find(Eng);
        
        % add flight conditions
        Aircraft.Specs.Propulsion.Engine.Alt = 0;
        Aircraft.Specs.Propulsion.Engine.Mach = 0.05;
        
        % array for the sized engines
        SizedEngines = [];
        
        % size each engine
        for jeng = 1:length(ieng)
            
            % check if the thrust supplement is positive
            if (Tsupp(ieng(jeng)) > 0)
                
                % increase the engine size to generate all the thrust
                Aircraft.Specs.Propulsion.Engine.DesignThrust = Tdwn(ieng(jeng)) + Tsupp(ieng(jeng));
                
            else
                
                % leave the engine size as is, power is siphoned off
                Aircraft.Specs.Propulsion.Engine.DesignThrust = Tdwn(ieng(jeng));
                
            end
            
            % turn on flag for sizing the engine
            Aircraft.Specs.Propulsion.Engine.Sizing = 1;
            
            % if the thrust requirement is small, don't size it
            if (Aircraft.Specs.Propulsion.Engine.DesignThrust > 1.0e-06)
            
                % size the engine
                Engine = EngineModelPkg.TurbofanNonlinearSizing(Aircraft.Specs.Propulsion.Engine, Psupp(ieng(1)));
                
                % turn off engine sizing
                Engine.Specs.Sizing = 0;                
                
                % remember the sized engine
                SizedEngines = [SizedEngines; Engine];
                                
                % get the new inlet area
                InletArea = pi * Engine.FanDiam ^ 2 / 4;
                
                % find the fan connected to the engine
                ifan = find((Arch(jeng+nsrc, idx) == 1) & Prop);
                
                % remember the inlet area
                Aircraft.Specs.Propulsion.InletArea(ifan) = InletArea;
            
            end
        end
        
        % remember the sized engines
        Aircraft.Specs.Propulsion.SizedEngine = SizedEngines;
        
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
        Weng = polyval(W_f_of_pow, Pdwn(Eng) / 1000);

    else

        % throw error
        error("ERROR - PropulsionSizing: invalid aircraft class.");

    end

else

    % no engines need to be sized
    Weng = 0;

end

% check if cable weight information is available
if (isfield(Aircraft.Specs.Propulsion.PropArch, "CableConns"  ) && ...
    isfield(Aircraft.Specs.Propulsion.PropArch, "CableLengths") )
    
    % get the cable lengths and connections
    CabCon = Aircraft.Specs.Propulsion.PropArch.CableConns  ;
    CabLen = Aircraft.Specs.Propulsion.PropArch.CableLengths;
    
    % check if cables are explicitly provided
    if (any(Cab))

        % get the number of connections from the cables
        [ndwn, ~] = size(CabCon);
        
        % get the required power for the cables
        Pcab = repmat(Pdwn(Cab)', ndwn, 1);
        
    else
    
        % get the electric motor power
        Pem = Pdwn(EM);
        
        % get the electric motor efficiencies
        EtaEM = Aircraft.Specs.Propulsion.PropArch.EtaEM;
        
        % get the transmitter architecture and operational matrices
        TrnArch = Arch(idx, idx);
        
        % capture the electric generator-motor connections
        ArchEG2EM = TrnArch(EG, EM);

        % compute the cable power
        Pcab = Pem' .* ArchEG2EM ./ EtaEM';
        
    end
   
    % get the cable weight-power ratio
    W_Pcab = Aircraft.Specs.Power.P_W.Cables;
    
    % compute the individual cable weights
    Wcab = W_Pcab .* (Pcab ./ 1.0e+06) .* CabCon .* CabLen;
    
    % compute the weight of the cables
    Aircraft.Specs.Weight.Cables = sum(Wcab, "all");

    
else
    
    % no cables are included
    Aircraft.Specs.Weight.Cables = 0;
        
end

% remember the weight of the engines
Aircraft.Specs.Weight.Engines = sum(Weng);

% compute the electric motor and generator weight
Aircraft.Specs.Weight.EM = sum(OEWPkg.ElectricMachineWeight(Pdwn(EM)));%sum(Pdwn(EM)) / P_Wem;
Aircraft.Specs.Weight.EG = sum(OEWPkg.ElectricMachineWeight(Pdwn(EG)));%sum(Pdwn(EG)) / P_Weg;

% ----------------------------------------------------------

end