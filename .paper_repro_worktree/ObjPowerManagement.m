function [f, grad, Aircraft] = ObjPowerManagement(x, NeedGrad, Aircraft)
%
% [f, grad, Aircraft] = ObjPowerManagement(x, NeedGrad, Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Return objective function values for optimizing the operational power
% split as a function of time.
%
% INPUTS:
%     x          - splits being optimized.
%                  size/type/units: n-by-1 / double / []
%
%     NeedGrad   - flag to return gradient of objective with respect to 
%                  x (1) or not (0).
%                  size/type/units: 1-by-1 / int / []
%
%     Aircraft   - structure containing aircraft specifications, mission
%                  history, and information about which objective function
%                  should be optimized.
%                  size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     f          - objective function value, either:
%                      a) FuelBurn - total fuel burn
%                      b) Energy   - total energy consumed
%                      c) DOC      - direct operating cost
%                  size/type/units: 1-by-1 / double / []
%
%     grad       - gradient of the objective with respect to the design
%                  variable(s), if requested.
%                  size/type/units: n-by-1 or 0-by-0 / double / []
%
%     Aircraft   - structure with updated information about the optimized
%                  aircraft configuration.
%                  size/type/units: 1-by-1 / struct / []
%


%% COMPUTE THE OBJECTIVE FUNCTION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the power splits
Aircraft.PowerOpt.Splits = x;

% size the aircraft
DesAircraft = EAPAnalysis(Aircraft, Aircraft.Settings.Analysis.Type, Aircraft.Settings.Analysis.MaxIter);

% save the flown aircraft
Aircraft.PowerOpt.Results.FlownAC = DesAircraft;

% get the objective function
ObjFun = Aircraft.PowerOpt.ObjFun;

% find the appropriate objective
if     (strcmpi(ObjFun, "DOC") == 1)
    
    % compute the DOC
    f = 0;
    
elseif (strcmpi(ObjFun, "FuelBurn") == 1)
    
    % get the fuel burn
    f = DesAircraft.Mission.History.SI.Weight.Fburn(end);
    
    % scale the objective by conventional LM100J fuel burn
    f = f / 17207;
    
elseif (strcmpi(ObjFun, "Energy") == 1)
    
    % get the total energy consumed
    f = DesAircraft.Mission.History.SI.Energy.Fuel(end) + ...
        DesAircraft.Mission.History.SI.Energy.Batt(end) ;
    
    % scale the objective by the conventional LM100J energy expended
    f = f / 7.4335e+11;
      
else
    
    % throw error
    error("ERROR - ObjPowerManagement: invalid objective function type. must be 'DOC', 'FuelBurn', or 'Energy'.");
    
end

% find the points being optimized
SegIndex = DesAircraft.PowerOpt.SegIndex;

% get the electric motor power available and used during the flight
Aircraft.PowerOpt.Constraints.DesPemAv = DesAircraft.Specs.Power.P_W.EM * DesAircraft.Specs.Weight.EM;
Aircraft.PowerOpt.Constraints.DesPem   = DesAircraft.Mission.History.SI.Power.EM(SegIndex);

% find the gas-turbine engines
Eng = Aircraft.Specs.Propulsion.PropArch.PSType == 1;

% get the gas-turbine power available and used during the flight
Aircraft.PowerOpt.Constraints.DesPgtAv = DesAircraft.Mission.History.SI.Power.AvGT(SegIndex);
Aircraft.PowerOpt.Constraints.DesPgt   = DesAircraft.Mission.History.SI.Power.GT(SegIndex);

% get the battery energy available and how much was used during the flight
Aircraft.PowerOpt.Constraints.DesEbattAv = DesAircraft.Specs.Power.SpecEnergy.Batt * DesAircraft.Specs.Weight.Batt;
Aircraft.PowerOpt.Constraints.DesEbatt   = DesAircraft.Mission.History.SI.Energy.Batt(end);

% find the first point in cruise
icrs = find(strcmpi(DesAircraft.Mission.History.Segment, "Cruise"), 1);

% get power available from the engine and power required at cruise
Aircraft.PowerOpt.Constraints.DesPavGT  = DesAircraft.Mission.History.SI.Power.AvGT(icrs);
Aircraft.PowerOpt.Constraints.DesCrsPow = DesAircraft.Mission.History.SI.Power.GT(  icrs);


%% COMPUTE THE GRADIENT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the gradient is required
if (NeedGrad == 1)
    
    % define a perturbation
    EPS = 1.0e-06;
    
    % remember the perturbation
    Aircraft.PowerOpt.Constraints.EPS = EPS;
    
    % number of splits to perturb and number of control points optimized
    nvar = Aircraft.PowerOpt.ndvars;
    
    % number of mission points being optimized
    nmiss = length(Aircraft.PowerOpt.SegIndex);
    
    % allocate memory for the gradient
    grad = zeros(nvar, 1);
    
    % allocate memory for the variables passed into the constraints
    Pem     = zeros(nmiss, nvar);
    PemAv   = zeros(    1, nvar);
    PavGT   = zeros(    1, nvar);
    CrsPow  = zeros(    1, nvar);
    PgtAv   = zeros(nmiss, nvar);
    Pgt     = zeros(nmiss, nvar);
    EbattAv = zeros(    1, nvar);
    Ebatt   = zeros(    1, nvar);
    
    % perturb each split
    for ivar = 1:nvar
        
        % perturb the split
        Aircraft.PowerOpt.Splits(ivar) = Aircraft.PowerOpt.Splits(ivar) + EPS;
    
        % size the aircraft again
        SenAircraft = EAPAnalysis(Aircraft, Aircraft.Settings.Analysis.Type, Aircraft.Settings.Analysis.MaxIter);
    
        % return the objective
        if     (strcmpi(ObjFun, "DOC") == 1)
            
            % compute the DOC
            Delf = 0;
            
        elseif (strcmpi(ObjFun, "FuelBurn") == 1)
            
            % get the fuel burn
            Delf = SenAircraft.Mission.History.SI.Weight.Fburn(end);
            
            % scale the objective by the conventional LM100J fuel burn
            Delf = Delf / 17207;
            
        elseif (strcmpi(ObjFun, "Energy") == 1)
            
            % get the total energy consumed
            Delf = SenAircraft.Mission.History.SI.Energy.Fuel(end) + ...
                   SenAircraft.Mission.History.SI.Energy.Batt(end) ;
            
            % scale objective by the conventional LM100J energy expended
            Delf = Delf / 7.4335e+11;
            
        else
            
            % throw error
            error("ERROR - ObjPowerManagement: invalid objective function type. must be 'DOC', 'FuelBurn', or 'Energy'.");
            
        end
    
        % compute the gradient with a finite difference
        grad(ivar) = (Delf - f) / EPS;
        
        % remember the values for gradient computations
        PemAv(     ivar) = SenAircraft.Specs.Power.P_W.EM * SenAircraft.Specs.Weight.EM;
        Pem(    :, ivar) = SenAircraft.Mission.History.SI.Power.EM(SegIndex)';
        PavGT(     ivar) = SenAircraft.Mission.History.SI.Power.AvGT(icrs);
        CrsPow(    ivar) = SenAircraft.Mission.History.SI.Power.GT(  icrs);
        PgtAv(  :, ivar) = SenAircraft.Mission.History.SI.Power.AvGT(SegIndex)';
        Pgt(    :, ivar) = SenAircraft.Mission.History.SI.Power.GT(  SegIndex)';
        EbattAv(   ivar) = SenAircraft.Specs.Power.SpecEnergy.Batt * SenAircraft.Specs.Weight.Batt;
        Ebatt(     ivar) = SenAircraft.Mission.History.SI.Energy.Batt(end);       
        
        % reset the split perturbation
        Aircraft.PowerOpt.Splits(ivar) = Aircraft.PowerOpt.Splits(ivar) - EPS;
        
    end
    
    % remember all of the power values recorded
    Aircraft.PowerOpt.Constraints.SenPavGT   = PavGT  ;
    Aircraft.PowerOpt.Constraints.SenCrsPow  = CrsPow ;
    Aircraft.PowerOpt.Constraints.SenPemAv   = PemAv  ;
    Aircraft.PowerOpt.Constraints.SenPem     = Pem    ;
    Aircraft.PowerOpt.Constraints.SenPgtAv   = PgtAv  ;
    Aircraft.PowerOpt.Constraints.SenPgt     = Pgt    ;
    Aircraft.PowerOpt.Constraints.SenEbattAv = EbattAv;
    Aircraft.PowerOpt.Constraints.SenEbatt   = Ebatt  ;
    
else
    
    % no gradient is needed
    grad = [];
    
end    

% ----------------------------------------------------------

end