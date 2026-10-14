function [Aircraft] = PropAnalysis(Aircraft)
%
% [Aircraft] = PropAnalysis(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 10 mar 2026
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

% get which propellers are connected to the gas turbine engines
WhichProp = Aircraft.Specs.Propulsion.PropArch.WhichProp;

% get the number of sources and transmitters
nsrc = length(SrcType);
ntrn = length(TrnType);

% get the number of components
ncomp = length(Arch);

% get the number of sinks
nsnk = ncomp - nsrc - ntrn;

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

% check for a windmilling engine
Windmill = Aircraft.Mission.History.SI.Power.Windmill(SegBeg:SegEnd, :);

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

% Start a new mission from its prescribed/carryover battery SOC. The
% default 100% initialization otherwise erases sequence charging state at
% the first segment of every flight.
if (DetailedBatt == 1) && (SegBeg == 1) && any(Batt)
    SOC(:, Batt) = Aircraft.Specs.Power.Battery.BegSOC;
end

% allocate memory for the power required and supplemental power
Preq  = zeros(npnt, ncomp);
Pout  = zeros(npnt, ncomp);
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

% get the transmitter and sink indices
TrnSnkIdx = (nsrc + 1) : ncomp;

% get the source and transmitter indices
SrcTrnIdx = 1 : (nsrc + ntrn);

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
    SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
        
    % check for any windmilling engines
    if (any(Windmill(ipnt, :)))
        
        % split power evenly among the remaining engines
        SplitDwn = RedistForWindmill(SplitDwn, Windmill(ipnt, :), nsrc, ncomp);
        
    end
    
    % propagate the power downstream to the transmitters
    Preq(ipnt, TrnSnkIdx) = PropulsionPkg.PowerFlow(Preq(ipnt, TrnSnkIdx)', Arch(TrnSnkIdx, TrnSnkIdx)', SplitDwn(TrnSnkIdx, TrnSnkIdx), EtaDwn(TrnSnkIdx, TrnSnkIdx), -1)';

    % A transmitter commanded to zero downstream share is off for this
    % mission point. In particular, the zero-speed detailed-takeoff point
    % requests full available sink power; do not assign any of that demand
    % to a disabled motor. The active turbine path carries the full demand.
    InactiveTrn = abs(LamDwn(ipnt, :)) <= 1.0e-12;
    Preq(ipnt, nsrc + find(InactiveTrn)) = 0;

end

% temporary power required array for iterating
TempReq = Preq;

% get the number of sources
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);

% assume the required power can be provided
Pout(:, TrnSnkIdx) = TempReq(:, TrnSnkIdx);

% look at the transmitters and sinks only
PoutTest = Pout(:, TrnSnkIdx);
PavTest  = Pav( :, TrnSnkIdx);

% check if any power requirements exceed the power available
exceeds = find(PoutTest - PavTest > 1.0e-06);

% if any exceed the power available, return only the power available
if (any(exceeds))
    PoutTest(exceeds) = PavTest(exceeds);
end

% set the required power as the output power
Pout(:, TrnSnkIdx) = PoutTest;

% loop through points to propagate power to the sources
for ipnt = 1:npnt
        
    % evaluate the function handles for the current splits
    SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
    
    % check for any windmilling engines
    if (any(Windmill(ipnt, :)))
        
        % split power evenly among the remaining engines
        SplitDwn = RedistForWindmill(SplitDwn, Windmill(ipnt, :), nsrc, ncomp);
        
    end
    
    % propagate the power downstream
    Pout(ipnt, SrcTrnIdx) = PropulsionPkg.PowerFlow(Pout(ipnt, SrcTrnIdx)', Arch(SrcTrnIdx, SrcTrnIdx)', SplitDwn(SrcTrnIdx, SrcTrnIdx), EtaDwn(SrcTrnIdx, SrcTrnIdx), -1)';
    
end

% Source propagation can restore requested transmitter loads above the
% component limits enforced earlier. Reapply the hard limit to every
% transmitter so an off-design engine, motor, or fan never reports more
% output than its available installed power. Any unmet requirement remains
% visible in Preq - Pout as a power shortfall.
TrnCols = nsrc + (1:ntrn);
Pout(:, TrnCols) = min(Pout(:, TrnCols), Pav(:, TrnCols));

% Reconcile each battery source with the electric-motor output that
% actually survived the component availability limit. PowerFlow above can
% otherwise reconstruct battery demand from the requested LamDwn split and
% exceed the LamUps-limited EM capability.
BattSrc = find(SrcType == 0);
for ibatt = BattSrc
    ConnectedEM = find((TrnType == 0) & ...
        (Arch(ibatt, nsrc + (1:ntrn)) > 0));
    if ~isempty(ConnectedEM)
        EMEta = EtaDwn(ibatt, nsrc + ConnectedEM);
        Pout(:, ibatt) = sum(Pout(:, nsrc + ConnectedEM) ./ EMEta, 2);
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
    SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
    
    % check for any windmilling engines
    if (any(Windmill(ipnt, :)))
        
        % split power evenly among the remaining engines
        SplitDwn = RedistForWindmill(SplitDwn, Windmill(ipnt, :), nsrc, ncomp);
        
    end
    
    % check for the power supplement
    Psupp(ipnt, itrn) = PropulsionPkg.PowerSupplementCheck( ...
                        Pout(ipnt, itrn), Arch(itrn, itrn), SplitDwn(itrn, itrn), EtaDwn(itrn, itrn), TrnType, EtaFan);
    
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
            [V(ibeg:iend, icol), I(ibeg:iend, icol), PBatt,  Q(ibeg+1:iend+1, icol), SOC(ibeg:iend+1, icol)] = BatteryPkg.Discharging(Aircraft,...
             Pout(ibeg:iend, icol), dt, SOC(1, icol), ParCells, SerCells);
            
            % check if the SOC falls below 20%
            BattDeplete = find(SOC(:, icol) < 20, 1);
            
            % update the battery/EM power and SOC
            if ((~isempty(BattDeplete)) && (strcmpi(ArchType, "E") == 0) && ...
                    (Aircraft.Settings.Analysis.Type == -1))

                % Stop electric assist at the SOC floor and transfer the
                % downstream demand to the turbine path.  Zeroing every
                % downstream split here used to disconnect both the battery
                % and fuel source while leaving the fan output untouched,
                % creating thrust with no energy input and artificially low
                % fuel burn in regular off-design flights.
                DepletePoint = min(max(BattDeplete, 1), npnt);
                LamDwn(DepletePoint:end, TrnType == 0) = 0;
                LamDwn(DepletePoint:end, TrnType == 1) = 1;

                % Re-propagate the unchanged sink demand through the revised
                % fuel-only topology for the remainder of this segment.
                for ipnt = DepletePoint:npnt
                    SplitDwn = PropulsionPkg.EvalSplit( ...
                        OperDwn, LamDwn(ipnt, :));
                    if any(Windmill(ipnt, :))
                        SplitDwn = RedistForWindmill(SplitDwn, ...
                            Windmill(ipnt, :), nsrc, ncomp);
                    end
                    Pout(ipnt, SrcTrnIdx) = PropulsionPkg.PowerFlow( ...
                        Pout(ipnt, SrcTrnIdx)', ...
                        Arch(SrcTrnIdx, SrcTrnIdx)', ...
                        SplitDwn(SrcTrnIdx, SrcTrnIdx), ...
                        EtaDwn(SrcTrnIdx, SrcTrnIdx), -1)';
                end
                Pout(DepletePoint:end, TrnCols) = min( ...
                    Pout(DepletePoint:end, TrnCols), ...
                    Pav(DepletePoint:end, TrnCols));
                Pout(DepletePoint:end, icol) = 0;

                % Hold SOC at the usable lower bound.  The previous sample is
                % the last physically accepted state unless depletion occurs
                % at the first point of a segment.
                PriorPoint = max(DepletePoint - 1, 1);
                FloorSOC = max(20, SOC(PriorPoint, icol));
                SOC(DepletePoint:end, icol) = FloorSOC;
                
                % flag this result
                Aircraft.Mission.History.Flags.SOCOff(MissID) = 1;
                
            end
        end

        % get the energy from the battery
        E_ES(2:end, icol) = E_ES(1, icol) + cumsum(Pout(ibeg:iend, icol) .* dt);
        
        % get the battery energy remaining
        Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(Pout(ibeg:iend, icol) .* dt);
        
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
            Pout(StopBatt:iend, ieng) = Pout(StopBatt:iend, ieng) + repmat(Pout(StopBatt:iend, icol) ./ neng, 1, neng);
            
            % set the battery power to 0 and remaining battery to 0
            Pout(StopBatt:end, icol) = 0;
            
            % recompute the battery energy consumed
            E_ES(2:end, icol) = E_ES(1, icol) + cumsum(Pout(ibeg:iend, icol) .* dt);
            
            % recompute the battery energy remaining
            Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(Pout(ibeg:iend, icol) .* dt);
            
            % update the thrust output
            Tout = Pout ./ TAS;
            
        end
    end
end

% Battery-floor redistribution changes the active topology after the first
% power-flow pass. Recompute thrust and gas-turbine supplement commands so
% the engine fuel model below sees the revised turbine-only demand.
Tout = Pout ./ TAS;
Psupp(:) = 0;
itrn = nsrc + (1:ntrn);
for ipnt = 1:npnt
    SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
    if any(Windmill(ipnt, :))
        SplitDwn = RedistForWindmill(SplitDwn, ...
            Windmill(ipnt, :), nsrc, ncomp);
    end
    Psupp(ipnt, itrn) = PropulsionPkg.PowerSupplementCheck( ...
        Pout(ipnt, itrn), Arch(itrn, itrn), ...
        SplitDwn(itrn, itrn), EtaDwn(itrn, itrn), ...
        TrnType, EtaFan);
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
        GetSFC = @(SizedEngine) SizedEngine.BSFC;
        
        % get the fuel flow rate
        MDot = @(OffDesignEng) OffDesignEng.Fuel.MDot;

    end
    
    % get the indices of the engines
    HasEng = find(Eng);
    
    % get the trnasmitters that are propellers
    itrn = [false(1, nsrc), TrnType == 2, false(1, nsnk)];
    
    % loop through the engines
    for ieng = 1:length(HasEng)
        
        % get the column index (offset by number of sources)
        icol = HasEng(ieng) + nsrc;
        
        % check if it has a propeller
        iprop = WhichProp(HasEng(ieng));

        % check if the engine is connected to a propeller
        if (iprop ~= 0)
            
            % get the thrust requirement from the propeller
            TEng = Tout(ibeg:iend, iprop);
            
        else
            
            % there is no connection, assume idle thrust and that there is
            % a larger power supplement that dominates the expression
            TEng = zeros(iend-ibeg+1, 1);
            
        end
        
        % check for any NaN or Inf (especially at takeoff)
        TEng(isnan(TEng)) = 0;
        TEng(isinf(TEng)) = 0;
    
        % compute thrust/power available (depends on aircraft class)
        if      (strcmpi(aclass, "Turbofan" ) == 1)
            
            % temporary thrust required
            TTemp = TEng;
            
            % check if there is a power siphon
            % The final control point is shared with the next segment but
            % has no time interval in this segment. Do not let its power
            % split disable idle fuel throughout the preceding descent.
            if (all(abs(Psupp(ibeg:iend, icol)) < 1.0e-06)) || (SegBeg == 1)
            
                % any required thrust < 1 must be rounded up to 5% SLS thrust
                TTemp(TEng < 1) = 0.05 * Aircraft.Specs.Propulsion.Thrust.SLS;
                
            end
                        
        elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                (strcmpi(aclass, "Piston"   ) == 1) )
            
            % temporary power required
            PTemp = Pout(ibeg:iend, icol);
            
            % check if there is a power siphon
            if (all(abs(Psupp(:, icol)) < 1.0e-06)) || (SegBeg == 1)
            
                % any required power  < 1 must be rounded up to 5% SLS power
                PTemp(PTemp < 1) = 0.05 * Aircraft.Specs.Power.SLS;
                
            end            
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
            
            % check for any windmilling engines
            if (any(Windmill(ipnt, :) == HasEng(ieng)))
                
                % assume inoperative engine, no fuel flow
                SFC(     ipnt, HasEng(ieng)) = 0;
                MDotFuel(ipnt, HasEng(ieng)) = 0;
                
            else
                            
                % get out the SFC (could be TSFC or BSFC)
                SFC(ipnt, HasEng(ieng)) = GetSFC(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
                
                % get the fuel flow
                MDotFuel(ipnt, HasEng(ieng)) = MDot(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
            
            end
            
            % get the appropriate elements
            ielem = [ifuel, icol];
            
            % evaluate the function handles for the current splits
            SplitDwn = PropulsionPkg.EvalSplit(OperDwn, LamDwn(ipnt, :));
                        
            % temporary mass flow rate
            Tempdmdt = PropulsionPkg.PowerFlow([zeros(1, nfuel), MDotFuel(ipnt, HasEng(ieng))]', ...
                       Arch(ielem, ielem)', SplitDwn(ielem, ielem), EtaDwn(ielem, ielem), -1)';
            
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

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [LamDwn] = RedistForWindmill(LamDwn, iwind, nsrc, ncomp)
%
% []
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 16 jun 2025
%
% redistribute power from one component when it fails.
%
% INPUTS:
%
% OUTPUTS:
%
%

% get the position of the windmilling components in the matrices
iwind = iwind + nsrc;

% get the sum of the windmilling components' contributions
PowFrac = sum(LamDwn(:, iwind), 2);

% zero the columns with windmilling components
LamDwn(:, iwind) = 0;

% loop through each component
for icomp = 1:ncomp
    
    % check the power fraction
    if (PowFrac(icomp) > 1.0e-12)
        
        % get the remaining components
        ActiveComp = find(LamDwn(icomp, :) > 1.0e-12);
        
        % get the number of remaining components
        nremain = length(ActiveComp);
        
        % check if there are any components remaining
        if (nremain > 0)
            
            % redistribute power equally to the remaining components
            LamDwn(icomp, ActiveComp) = LamDwn(icomp, ActiveComp) + PowFrac(icomp) / nremain;
            
        end        
    end
end
        
% ----------------------------------------------------------

end
