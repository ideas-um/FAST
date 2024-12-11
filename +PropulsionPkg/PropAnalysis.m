function [Aircraft] = PropAnalysis(Aircraft)
%
% [Aircraft] = PropAnalysis(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 11 dec 2024
%
% Analyze the propulsion system for a given set of flight conditions.
% Remember how the propulsion system performs in the mission history.
%
% INPUTS:
%     Aircraft - structure with information about the aircraft and mission
%                segments flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - structure with updated information about the power source
%                output and energy source expenditures.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% aircraft specifications    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% specific energy of fuel
efuel = Aircraft.Specs.Power.SpecEnergy.Fuel;

% propulsion architecture
ArchType = Aircraft.Specs.Propulsion.PropArch.Type;

% energy and power source types
SrcType = Aircraft.Specs.Propulsion.PropArch.SrcType;
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the downstream operational matrix
OperDwn = Aircraft.Specs.Propulsion.PropArch.OperDwn;

% get the downstream efficiency matrix
EtaDwn = Aircraft.Specs.Propulsion.PropArch.EtaDwn;

% get the number of sources and transmitters
nsrc = length(SrcType);
ntrn = length(TrnType);

% get the number of components
ncomp = length(Arch);

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
    error("ERROR - PropAnalysisNew: invalid aircraft class provided.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% segment being flown and    %
% which splits have inputs   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the segment id
SegsID = Aircraft.Mission.Profile.SegsID;

% get the beginning and ending control point indices
SegBeg = Aircraft.Mission.Profile.SegBeg(SegsID);
SegEnd = Aircraft.Mission.Profile.SegEnd(SegsID);

% mission ID
MissID = Aircraft.Mission.Profile.MissID;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the power required
PreqSnk = Aircraft.Mission.History.SI.Power.Req(SegBeg:SegEnd);

% power available for all components
Pav = Aircraft.Mission.History.SI.Power.Pav(SegBeg:SegEnd, :);

% get the necessary splits
LamDwn = Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :);

% aircraft weight
Mass = Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd);

% performance history
Time = Aircraft.Mission.History.SI.Performance.Time(SegBeg:SegEnd);
TAS  = Aircraft.Mission.History.SI.Performance.TAS( SegBeg:SegEnd);
Mach = Aircraft.Mission.History.SI.Performance.Mach(SegBeg:SegEnd);
Alt  = Aircraft.Mission.History.SI.Performance.Alt( SegBeg:SegEnd);

% compute the time to travel between control points
dt = diff(Time);

% get the number of control points in the segment
npnt = length(Time);
    
% note the beginning/ending elements
ibeg =        1;
iend = npnt - 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup cumulative fuel and  %
% energy quantities          %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fuel burn
E_ES  = zeros(npnt, nsrc);
Fburn = zeros(npnt, 1);
SOC   = repmat(100, npnt, nsrc);

% battery: get battery cell arrangement
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

% assume basic battery model (constant voltage discharge) will be used
DetailedBatt = 0;

% check if the detailed (time-dependent) battery model should be used
if (~isnan(SerCells) && ~isnan(ParCells))

    % use the detailed battery model instead
    DetailedBatt = 1;

end

% get the energy in the energy sources remaining
Eleft_ES = Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :);

% fill first element if there is a mission history
if (SegBeg > 1)
    
    % get the fuel burn
    Fburn = repmat(Aircraft.Mission.History.SI.Weight.Fburn(SegBeg), npnt, 1);
    
    % get the energy expended by all energy sources
    E_ES = repmat(Aircraft.Mission.History.SI.Energy.E_ES(SegBeg, :), npnt, 1);
    
    % check for a detailed battery model
    if (DetailedBatt == 1)
    
        % get SOC from the mission history
        SOC = repmat(Aircraft.Mission.History.SI.Power.SOC(SegBeg, :), npnt, 1);
        
    end
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get information about the  %
% propulsion architecture    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the transmitter types
Eng = TrnType == 1;

% get the source types
Fuel = SrcType == 1;
Batt = SrcType == 0;

% allocate memory for the power required and supplemental power
Preq  = zeros(npnt, ncomp);
Psupp = zeros(npnt, ncomp);


%% PROPULSION SYSTEM ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propagate the power        %
% required along the         %
% powertrain                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the power at the sink
Preq(:, end) = PreqSnk;

% loop through points to get power outputs by thrust/power sources
for ipnt = 1:npnt
    
    % if the power required is infinitely large, return infinity
    if (isinf(Preq(ipnt, end)))
        
        % all components must provide infinite power
        Preq(ipnt, :) = Inf;
        
        % no need to multiply matrices, so continue on
        continue;
        
    end
    
    % evaluate the function handles for the current splits
    Splits = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
    
    % propagate the power downstream
    Preq(ipnt, :) = PropulsionPkg.PowerFlow(Preq(ipnt, :)', Arch', Splits, EtaDwn, -1)';
    
end

% temporary power required array for iterating
TempReq = Preq;

% iterate until converged
while (1)
    
    % assume the required power can be provided
    Pout = TempReq;
    
    % look at the transmitters and sinks only
    PoutTest = Pout(:, (nsrc + 1):end);
    PavTest  = Pav( :, (nsrc + 1):end);
    
    % check if any power requirements exceed the power available
    exceeds = find(PoutTest > PavTest);
    
    % if any exceed the power available, return only the power available
    if (any(exceeds))
        PoutTest(exceeds) = PavTest(exceeds);
    else
        break;
    end
    
    % set the required power as the output power
    TempReq(:, (nsrc + 1):end) = PoutTest;    
    
    % loop through points to get power outputs by thrust/power sources
    for ipnt = 1:npnt
        
        % if the power required is infinitely large, return infinity
        if (isinf(Preq(ipnt, end)))
            
            % all components must provide infinite power
            TempReq(ipnt, :) = Inf;
            
            % no need to multiply matrices, so continue on
            continue;
            
        end
        
        % evaluate the function handles for the current splits
        Splits = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
        
        % propagate the power downstream
        TempReq(ipnt, :) = PropulsionPkg.PowerFlow(TempReq(ipnt, :)', Arch', Splits, EtaDwn, -1)';
        
    end
end

% compute the thrust required/output
Tout = Pout ./ TAS;
Treq = Preq ./ TAS;

% remember the power/thrust required
Aircraft.Mission.History.SI.Power.Preq(SegBeg:SegEnd, :) = Preq;
Aircraft.Mission.History.SI.Power.Treq(SegBeg:SegEnd, :) = Treq;

Aircraft.Mission.History.SI.Power.Pout(SegBeg:SegEnd, :) = Pout;
Aircraft.Mission.History.SI.Power.Tout(SegBeg:SegEnd, :) = Tout;

% get the indices for the transmitters
itrn = nsrc + (1 : ntrn);

% compute the supplemental power required/provided by/to the gas-turbine
% engine
for ipnt = 1:npnt
    
    % get the current downstream power split
    Splits = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
    
    % check for the power supplement
    Psupp(ipnt, itrn) = PropulsionPkg.PowerSupplementCheck( ...
                        Pout(ipnt, itrn), Arch(itrn, itrn), Splits(itrn, itrn), ...
                        EtaDwn(itrn, itrn), TrnType, EtaFan);
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute the fuel burn and  %
% battery energy consumed    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the engine and battery outputs
SFC      = zeros(npnt, ntrn);
MDotFuel = zeros(npnt, ntrn);
V        = zeros(npnt, nsrc);
I        = zeros(npnt, nsrc);
Q        = zeros(npnt, nsrc);
dmdt     = zeros(npnt, nsrc);

% check for a battery
if (any(Batt))   
    
    % get the indices of the engines
    HasBatt = find(Batt);
    
    % loop through the engines
    for ibatt = 1:length(HasBatt)
        
        % get the column index
        icol = HasBatt(ibatt);
                
        % check if detailed battery model is used
        if (DetailedBatt == 1)
            
            % power available from the battery
            [V(ibeg:iend, icol), I(ibeg:iend, icol), Preq(ibeg:iend, icol),  Q(ibeg+1:iend+1, icol), SOC(ibeg+1:iend+1, icol)] = BatteryPkg.Model(...
             Preq(ibeg:iend, icol), dt, SOC(1, icol), ParCells, SerCells);
            
            % check if the SOC falls below 20%
            BattDeplete = find(SOC(:, icol) < 20, 1);
            
            % update the battery/EM power and SOC
            if ((~isempty(BattDeplete)) && (strcmpi(ArchType, "E") == 0) && (Aircraft.Settings.Analysis.Type < 0))
                
                % no more power is provided from the electric motor or battery
                Preq(BattDeplete:end, icol) = 0;
                
                % zero the splits
                LamDwn(BattDeplete:end, :) = 0;
                
                % change the SOC (prior index is last charge > 20%)
                SOC(BattDeplete:end, icol) = SOC(BattDeplete - 1, icol);
                
                % flag this result
                Aircraft.Mission.History.Flags.SOCOff(MissID) = 1;
                
            end
        end

        % get the energy from the battery
        E_ES(2:end, icol) = E_ES(1, icol) + cumsum(Preq(ibeg:iend, icol) .* dt);
        
        % get the battery energy remaining
        Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(Preq(ibeg:iend, icol) .* dt);
        
        % check if the battery remaining goes negative
        StopBatt = find(Eleft_ES(:, icol) < 0, 1);
        
        % transfer power to the engines if the battery is empty (if not sizing)
        if (any(StopBatt) && (Aircraft.Settings.Analysis.Type < 0))
            
            % stop the battery before it crosses 0 (maximum to avoid 0 index)
            StopBatt = max(1, StopBatt - 1);
            
            % get the number of gas-turbine engines
            neng = sum(Eng);
            
            % get the engine indices
            ieng = find(Eng) + nsrc;
            
            % assume the gas-turbine engines can handle the EM load
            Pout(StopBatt:iend, ieng) = Pout(StopBatt:iend, ieng) + repmat(Preq(StopBatt:iend, icol) ./ neng, 1, neng);
            
            % set the battery power to 0 and remaining battery to 0
            Preq(StopBatt:end, icol) = 0;
            
            % recompute the battery energy consumed
            E_ES(2:end, icol) = E_ES(1, icol) + cumsum(Preq(ibeg:iend, icol) .* dt);
            
            % recompute the battery energy remaining
            Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(Preq(ibeg:iend, icol) .* dt);
            
        end
    end
end

% check for fuel
if (any(Fuel))
    
    % remember the indices
    ifuel = find(Fuel);
    
    % get the number of fuel components
    nfuel = sum(Fuel);
    
    % check the aircraft class
    if      (strcmpi(aclass, "Turbofan" ) == 1)

        % call the appropriate engine sizing function
        EngFun = @(Aircraft, OffParams, ElecPower, ieng, ipnt) EngineModelPkg.SimpleOffDesign(Aircraft, OffParams, ElecPower, ieng, ipnt);

        % get the TSFC from the engine performance
        GetSFC = @(OutEng) OutEng.TSFC;
        
        % get the fuel flow rate
        MDot = @(OutEng) OutEng.Fuel;

    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )

        % call the appropriate engine sizing function
        EngFun = @(EngSpec, EMPower) EngineModelPkg.TurbopropNonlinearSizing(EngSpec, EMPower);

        % get the BSFC from the engine sizing
        GetSFC = @(SizedEngine) SizedEngine.BSFC_Imp;
        
        % get the fuel flow rate
        MDot = @(OffDesignEng) OffDesignEng.Fuel.MDot;

    end
    
    % get the indices of the engines
    HasEng = find(Eng);
    
    % loop through the engines
    for ieng = 1:length(HasEng)
        
        % get the column index (offset by number of sources)
        icol = HasEng(ieng) + nsrc;
        
        % compute the thrust output from the engine
        TEng = Tout(ibeg:iend, icol);
        
        % check for any NaN or Inf (especially at takeoff)
        TEng(isnan(TEng)) = 0;
        TEng(isinf(TEng)) = 0;
    
        % compute thrust/power available (depends on aircraft class)
        if      (strcmpi(aclass, "Turbofan" ) == 1)
            
            % temporary thrust required
            TTemp = TEng;
            
            % any required thrust < 1 must be rounded up to 5% SLS thrust
            TTemp(TEng < 1) = 0.05 * Aircraft.Specs.Propulsion.Thrust.SLS;
                        
        elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                (strcmpi(aclass, "Piston"   ) == 1) )
            
            % temporary power required
            PTemp = Pout(ibeg:iend, icol);
            
            % any required power  < 1 must be rounded up to 5% SLS power
            PTemp(PTemp < 1) = 0.05 * Aircraft.Specs.Power.SLS;
            
        end
        
        % get altitudes and mach number
        Alt  = Alt( ibeg:iend);
        Mach = Mach(ibeg:iend);
                        
        % compute the SFC as a function of thrust required
        for ipnt = 1:(npnt-1)
            
            % update the engine performance requirements
            OffParams.FlightCon.Mach = Mach(ipnt);
            OffParams.FlightCon.Alt  = Alt( ipnt);
            
            % get the required thrust/power
            if      (strcmpi(aclass, "Turbofan" ) == 1)
                
                % get the off-design thrust
                OffParams.Thrust = TTemp(ipnt);
                
                % run the engine model
                OffDesignEngine = EngFun(Aircraft, OffParams, Psupp(ipnt, icol), icol, ipnt);
                
            elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                    (strcmpi(aclass, "Piston"   ) == 1) )
                
                % get the required power
                Aircraft.Specs.Propulsion.Engine.ReqPower     = PTemp(ipnt);
                
                % run the engine model
                OffDesignEngine = EngFun(Aircraft.Specs.Propulsion.Engine, Psupp(ipnt, icol));
                
            end
            
            % get out the SFC (could be TSFC or BSFC)
            SFC(ipnt, icol) = GetSFC(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
            
            % get the fuel flow
            MDotFuel(ipnt, icol) = MDot(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
            
            % get the appropriate elements
            ielem = [ifuel, icol];
            
            % evaluate the function handles for the current splits
            Splits = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
            
            % temporary mass flow rate
            Tempdmdt = PropulsionPkg.PowerFlow([zeros(1, nfuel), MDotFuel(ipnt, icol)]', ...
                       Arch(ielem, ielem)', Splits(ielem, ielem), EtaDwn(ielem, ielem), -1)';
            
            % update the mass flow rates
            dmdt(ipnt, ifuel) = dmdt(ipnt, ifuel) + Tempdmdt(1:end-1)';
                        
        end                
    end
    
    % compute the power from the energy source
    dEdt = dmdt(:, ifuel) .* efuel;
    
    % compute the fuel burn at each point
    dFburn = dmdt(1:end-1, ifuel) .* dt;
    
    % compute the energy expended at each control point
    dEfuel = dEdt(1:end-1) .* dt;
    
    % track the cumulative fuel burn
    CumFburn = cumsum(dFburn);
    
    % compute the cumulative fuel burn
    Fburn(2:end) = Fburn(1) + CumFburn;
    
    % update the aircraft's mass
    Mass( 2:end) = Mass( 1) - CumFburn;
        
    % compute the fuel energy consumed
    E_ES(    2:end, Fuel) = E_ES(2:end, Fuel) + cumsum(dEfuel);
    
    % compute the fuel energy remaining
    Eleft_ES(2:end, Fuel) = Eleft_ES(1, Fuel) - cumsum(dEfuel);

end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% store information in the   %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% weights
Aircraft.Mission.History.SI.Weight.CurWeight(SegBeg:SegEnd) = Mass ;
Aircraft.Mission.History.SI.Weight.Fburn(    SegBeg:SegEnd) = Fburn;

% propulsion system quantities
Aircraft.Mission.History.SI.Propulsion.TSFC(    SegBeg:SegEnd, :) = SFC     ;
Aircraft.Mission.History.SI.Propulsion.MDotFuel(SegBeg:SegEnd, :) = MDotFuel;

% power quantities
Aircraft.Mission.History.SI.Power.SOC(     SegBeg:SegEnd, :) = SOC;
Aircraft.Mission.History.SI.Power.Voltage( SegBeg:SegEnd, :) = V  ;
Aircraft.Mission.History.SI.Power.Current( SegBeg:SegEnd, :) = I  ;
Aircraft.Mission.History.SI.Power.Capacity(SegBeg:SegEnd, :) = Q  ;

% power splits
Aircraft.Mission.History.SI.Power.LamDwn(SegBeg:SegEnd, :) = LamDwn;

% energy quantities
Aircraft.Mission.History.SI.Energy.E_ES(    SegBeg:SegEnd, :) = E_ES    ;
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

end