function [Aircraft] = PropAnalysisNew(Aircraft)
%
% [Aircraft] = PropAnalysisNew(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 oct 2024
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

% energy and power source types
ESType = Aircraft.Specs.Propulsion.PropArch.ESType;
PSType = Aircraft.Specs.Propulsion.PropArch.PSType;

% get the propulsion architecture
PSPS = Aircraft.Specs.Propulsion.PropArch.PSPS;
TSPS = Aircraft.Specs.Propulsion.PropArch.TSPS;

% operation matrices
OperTS   = Aircraft.Specs.Propulsion.Oper.TS  ;
OperTSPS = Aircraft.Specs.Propulsion.Oper.TSPS;
OperPSPS = Aircraft.Specs.Propulsion.Oper.PSPS;
OperPSES = Aircraft.Specs.Propulsion.Oper.PSES;

% efficiencies
EtaTSPS = Aircraft.Specs.Propulsion.Eta.TSPS;
EtaPSPS = Aircraft.Specs.Propulsion.Eta.PSPS;
EtaPSES = Aircraft.Specs.Propulsion.Eta.PSES;

% get the number of energy sources
nes = length(Aircraft.Specs.Propulsion.PropArch.ESType);

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

% propulsion architecture
arch = Aircraft.Specs.Propulsion.Arch.Type;

% mission ID
MissID = Aircraft.Mission.Profile.MissID;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the power required
Preq = Aircraft.Mission.History.SI.Power.Req(SegBeg:SegEnd);

% power available for the thrust/power sources
Pav_TS = Aircraft.Mission.History.SI.Power.Pav_TS(SegBeg:SegEnd, :);
Pav_PS = Aircraft.Mission.History.SI.Power.Pav_PS(SegBeg:SegEnd, :);

% get the necessary splits
LamTS   = Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd);
LamTSPS = Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd);
LamPSPS = Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd);
LamPSES = Aircraft.Mission.History.SI.Power.LamPSES(SegBeg:SegEnd);

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
E_ES  = zeros(npnt, nes);
Fburn = zeros(npnt, 1);
SOC   = repmat(100, npnt, nes);

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

% get the types of power sources
Eng = PSType == +1;

% get the types of energy sources
Fuel = ESType == 1;
Batt = ESType == 0;

% get the number of thrust and power sources
[nts, nps] = size(Aircraft.Specs.Propulsion.PropArch.TSPS);

% get the number of energy sources
nes = length(ESType);

% allocate memory for the power required
PreqTS = zeros(npnt, nts);
PreqPS = zeros(npnt, nps);
PreqES = zeros(npnt, nes);
PreqDr = zeros(npnt, nps);
Psupp  = zeros(npnt, nps);


%% PROPULSION SYSTEM ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% propagate the power        %
% required along the         %
% powertrain                 %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through points to get power outputs by thrust/power sources
for ipnt = 1:npnt
    
    % if the power required is infinitely large, return infinity
    if (isinf(Preq(ipnt)))
        
        % the power/thrust sources must provide infinite power
        PreqTS(ipnt, :) = Inf;
        PreqDr(ipnt, :) = Inf;
        PreqPS(ipnt, :) = Inf;
        
        % no need to multiply matrices, so continue on
        continue;
        
    end
    
    % evaluate the function handles for the current splits
    SplitTS   = PropulsionPkg.EvalSplit(OperTS  , LamTS(  ipnt, :));
    SplitTSPS = PropulsionPkg.EvalSplit(OperTSPS, LamTSPS(ipnt, :));
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
    
    % get the power output by the thrust sources
    PreqTS(ipnt, :) = Preq(ipnt) * SplitTS;
    
    % get the power output by the driven  power sources
    PreqDr(ipnt, :) = PreqTS(ipnt, :) * (SplitTSPS ./ EtaTSPS);
    
    % get the power output by the driving power sources
    PreqPS(ipnt, :) = PreqDr(ipnt, :) * (SplitPSPS ./ EtaPSPS);
        
end

% for the power and thrust sources, convert to thrust as well
TreqPS = PreqPS ./ TAS;
TreqTS = PreqTS ./ TAS;

% remember the power/thrust required by the thrust/power sources
Aircraft.Mission.History.SI.Power.Preq_TS(SegBeg:SegEnd, :) = PreqTS;
Aircraft.Mission.History.SI.Power.Preq_PS(SegBeg:SegEnd, :) = PreqPS;
Aircraft.Mission.History.SI.Power.Treq_TS(SegBeg:SegEnd, :) = TreqTS;
Aircraft.Mission.History.SI.Power.Treq_PS(SegBeg:SegEnd, :) = TreqPS;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the required    %
% thrust/power does not      %
% exceed what is available   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume the required power can be achieved
PoutTS = PreqTS;
PoutPS = PreqPS;
PoutDr = PreqDr;

% check the thrust sources
exceeds = find(PreqTS > Pav_TS);

% if any exceed the power available, return only the power available
if (any(exceeds))
    PoutTS(exceeds) = Pav_TS(exceeds);
end

% remember the output thrust/power from the thrust sources
Aircraft.Mission.History.SI.Power.Pout_TS(SegBeg:SegEnd, :) = PoutTS;
Aircraft.Mission.History.SI.Power.Tout_TS(SegBeg:SegEnd, :) = PoutTS ./ TAS;

% check the driven power sources
exceeds = find(PreqDr > Pav_PS);

% if any exceed the power available, return only the power available
if (any(exceeds))
    PoutDr(exceeds) = Pav_PS(exceeds);
end

% check the driving power sources
exceeds = find(PreqPS > Pav_PS);

% if any exceed the power available, return only the power available
if (any(exceeds))
    PoutPS(exceeds) = Pav_PS(exceeds);
end

% remember the output thrust/power from the power  sources
Aircraft.Mission.History.SI.Power.Pout_PS(SegBeg:SegEnd, :) = PoutPS;
Aircraft.Mission.History.SI.Power.Tout_PS(SegBeg:SegEnd, :) = PoutPS ./ TAS;

% allocate power to/from the gas-turbine engines for components in series/parallel
for ipnt = 1:npnt
    
    % evaluate the function handles for the current splits
    SplitPSPS = PropulsionPkg.EvalSplit(OperPSPS, LamPSPS(ipnt, :));
    
    % check for the power supplement
    Psupp(ipnt, :) = PropulsionPkg.PowerSupplementCheck(PoutDr(ipnt, :), TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, EtaFan);
        
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute the power to be    %
% supplied by the energy     %
% sources                    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through points to get power outputs by the energy sources
for ipnt = 1:npnt
    
    % evaluate the function handle
    SplitPSES = PropulsionPkg.EvalSplit(OperPSES, LamPSES(ipnt, :));
    
    % get the power output by the energy sources
    PreqES(ipnt, :) = PoutPS(ipnt, :) * (SplitPSES ./ EtaPSES);
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% compute the fuel burn and  %
% battery energy consumed    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the engine and battery outputs
SFC      = zeros(npnt, nps);
MDotFuel = zeros(npnt, nps);
V        = zeros(npnt, nes);
I        = zeros(npnt, nes);
Q        = zeros(npnt, nes);
C_rate   = zeros(npnt, nes);
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
            [V(ibeg:iend, icol), I(ibeg:iend, icol), PreqES(ibeg:iend, icol),  Q(ibeg+1:iend+1, icol), SOC(ibeg+1:iend+1, icol) ...
                ] = BatteryPkg.Model(PreqES(ibeg:iend, icol), dt, SOC(1    , icol), ParCells, SerCells); 
            
            % check if the SOC falls below 20%
            BattDeplete = find(SOC(:, icol) < 20, 1);
            
            % update the battery/EM power and SOC
            if ((~isempty(BattDeplete)) && (strcmpi(arch, "E") == 0) && (Aircraft.Settings.Analysis.Type < 0))
                
                % no more power is provided from the electric motor or battery
                PreqES(BattDeplete:end, icol) = 0;
                
                % zero the splits
                LamTS(  BattDeplete:end, :) = 0;
                LamTSPS(BattDeplete:end, :) = 0;
                LamPSPS(BattDeplete:end, :) = 0;
                LamPSES(BattDeplete:end, :) = 0;
                
                % change the SOC (prior index is last charge > 20%)
                SOC(BattDeplete:end, icol) = SOC(BattDeplete - 1, icol);
                
                % flag this result
                Aircraft.Mission.History.Flags.SOCOff(MissID) = 1;
                
            end
        end

        % get the energy from the battery
        E_ES(2:end, icol) = E_ES(1, icol) + cumsum(PreqES(ibeg:iend, icol) .* dt);
        
        % get the battery energy remaining
        Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(PreqES(ibeg:iend, icol) .* dt);
            
        % check if the battery remaining goes negative
        StopBatt = find(Eleft_ES(:, icol) < 0, 1);
        
        % transfer power to the engines if the battery is empty (if not sizing)
        if (any(StopBatt) && (Aircraft.Settings.Analysis.Type < 0))
            
            % stop the battery before it crosses 0 (maximum to avoid 0 index)
            StopBatt = max(1, StopBatt - 1);
            
            % get the number of gas-turbine engines
            neng = sum(Eng);
            
            % assume the gas-turbine engines can handle the EM load
            PoutPS(StopBatt:iend, Eng) = PoutPS(StopBatt:iend, Eng) + repmat(PreqES(StopBatt:iend, icol) ./ neng, 1, neng);
            
            % set the battery power to 0 and remaining battery to 0
            PreqES(StopBatt:end, icol) = 0;
            
            % recompute the battery energy consumed
            E_ES(2:end, icol) = E_ES(1, icol) + cumsum(PreqES(ibeg:iend, icol) .* dt);
            
            % recompute the battery energy remaining
            Eleft_ES(2:end, icol) = Eleft_ES(1, icol) - cumsum(PreqES(ibeg:iend, icol) .* dt);
            
        end
    end
end

% check for fuel
if (any(Fuel))
    
    % check the aircraft class
    if      (strcmpi(aclass, "Turbofan" ) == 1)

        % call the appropriate engine sizing function
        EngSizeFun = @(Aircraft, OffParams, ElecPower, ieng, ipnt) EngineModelPkg.SimpleOffDesign(Aircraft, OffParams, ElecPower, ieng, ipnt);

        % get the TSFC from the engine performance
        GetSFC = @(OffDesignEng) OffDesignEng.TSFC;
        
        % get the fuel flow rate
        MDot = @(OffDesignEng) OffDesignEng.Fuel;

    elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
            (strcmpi(aclass, "Piston"   ) == 1) )

        % call the appropriate engine sizing function
        EngSizeFun = @(EngSpec, EMPower) EngineModelPkg.TurbopropNonlinearSizing(EngSpec, EMPower);

        % get the BSFC from the engine sizing
        GetSFC = @(SizedEngine) SizedEngine.BSFC_Imp;
        
        % get the fuel flow rate
        MDot = @(OffDesignEng) OffDesignEng.Fuel.MDot;

    end
    
    % get the indices of the engines
    HasEng = find(Eng);
    
    % loop through the engines
    for ieng = 1:length(HasEng)
        
        % get the column index
        icol = HasEng(ieng);
        
        % compute the thrust output from the engine (account for fan)
        TEng = PoutTS(ibeg:iend, icol) ./ TAS(ibeg:iend);
        
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
            PTemp = PoutPS(ibeg:iend, icol);
            
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
                OffDesignEngine = EngSizeFun(Aircraft, OffParams, Psupp(ipnt, icol), icol, ipnt);
                
            elseif ((strcmpi(aclass, "Turboprop") == 1) || ...
                    (strcmpi(aclass, "Piston"   ) == 1) )
                
                % get the required power
                Aircraft.Specs.Propulsion.Engine.ReqPower     = PTemp(ipnt);
                
                % run the engine model
                OffDesignEngine = EngSizeFun(Aircraft.Specs.Propulsion.Engine, Psupp(ipnt, icol));
                
            end
            
            % get out the SFC (could be TSFC or BSFC)
            SFC(ipnt, icol) = GetSFC(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
            
            % get the fuel flow
            MDotFuel(ipnt, icol) = MDot(OffDesignEngine) * Aircraft.Specs.Propulsion.MDotCF;
            
        end                
    end
        
    % compute the mass flow into all power sources
    dmdt = MDotFuel * SplitPSES;
    
    % compute the power from the energy source
    dEdt = dmdt(:, Fuel) .* efuel;
    
    % compute the fuel burn at each point
    dFburn = dmdt(1:end-1, Fuel) .* dt;
    
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

% remember the power provided by the energy sources
Aircraft.Mission.History.SI.Power.P_ES(SegBeg:SegEnd, :) = PreqES;


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
% Aircraft.Mission.History.SI.Power.C_rate(  SegBeg:SegEnd, :) = C_rate(:,2);
Aircraft.Mission.History.SI.Power.V_cell(  SegBeg:SegEnd, :) = V ./ SerCells;   % Find Voltage per cell
Aircraft.Mission.History.SI.Power.Cur_cell(SegBeg:SegEnd, :) = I ./ ParCells;   % Find Current per cell
Aircraft.Mission.History.SI.Power.Cap_cell(SegBeg:SegEnd, :) = Q ./ ParCells;   % Find Capacity per cell

% splits
Aircraft.Mission.History.SI.Power.LamTS(  SegBeg:SegEnd, :) = LamTS  ;
Aircraft.Mission.History.SI.Power.LamTSPS(SegBeg:SegEnd, :) = LamTSPS;
Aircraft.Mission.History.SI.Power.LamPSPS(SegBeg:SegEnd, :) = LamPSPS;
Aircraft.Mission.History.SI.Power.LamPSES(SegBeg:SegEnd, :) = LamPSES;

% energy quantities
Aircraft.Mission.History.SI.Energy.E_ES(    SegBeg:SegEnd, :) = E_ES    ;
Aircraft.Mission.History.SI.Energy.Eleft_ES(SegBeg:SegEnd, :) = Eleft_ES;

% ----------------------------------------------------------

end