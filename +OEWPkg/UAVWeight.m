function [Aircraft] = UAVWeight(Aircraft)
%
% [Aircraft] = UAVWeight(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% patterned after code written by Maxfield Arnson
% last updated: 20 apr 2026
%
% predict the weight of a UAV.
%
% INPUTS:
%     Aircraft - information about the aircraft being analyzed.
%                size/type/units: 1-by-1 / struct / []
%
%
% OUTPUTS:
%     Aircraft - updated aircraft information with weight buildup.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the aircraft class
aclass = Aircraft.Specs.TLAR.Class;

% confirm that it is a UAV
if (~strcmpi(aclass, "UAV"))
    error("ERROR - UAVWeight: weight buildup for UAVs only.");
end

% check for a calibration factor on OEW/airframe weight
if (isfield(Aircraft.Specs.Weight, "WairfCF"))
    
    % update the airframe weight
    OEWCF = Aircraft.Specs.Weight.WairfCF;
    
else
    
    % assume no calibration factor
    OEWCF = 1;
        
end

% get the propulsion architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% iteration settings
Tol     = Aircraft.Settings.OEW.Tol    ;
MaxIter = Aircraft.Settings.OEW.MaxIter;


%% WEIGHT BUILDUP %%
%%%%%%%%%%%%%%%%%%%%

% get the power-weight ratio
P_W = Aircraft.Specs.Power.P_W.SLS;

% get the MTOW
MTOW  = Aircraft.Specs.Weight.MTOW;

% get the other weights, if available
OEW   = CheckEmpty(Aircraft.Specs.Weight.OEW);
Wpay  = CheckEmpty(Aircraft.Specs.Weight.Payload);
Wfuel = CheckEmpty(Aircraft.Specs.Weight.Fuel);
Wbatt = CheckEmpty(Aircraft.Specs.Weight.Batt);
Weng  = CheckEmpty(Aircraft.Specs.Weight.Engines);
Wem   = CheckEmpty(Aircraft.Specs.Weight.EM);

% initialize the iteration
Iter = 0;
Err  = 1;

% iterate until converged
while ((Err > Tol) && (Iter < MaxIter))
    
    % compute the system-level rated power
    Prated = P_W * MTOW;
    
    % compute the gas turbine engine weight
    if (strcmpi(Arch, "C"))
        

        % compute the engine weight
        Weng = OEWPkg.PistonEngineWeight(Prated);

    end
    
    % compute the electric motor weight
    if (strcmpi(Arch, "E"))
                
        % compute the electric motor weight
        Wem = OEWPkg.ElectricMachineWeight(Prated);
        
    end
    
    % check for a negative OEW and correct via a heuristic, if necessary
    if (OEW < 0)
        OEW = 0.5 * MTOW;
    end

    % compute the new OEW here, and multiply by the airframe weight
    % calibration factor
    OEW = 0.4822*MTOW+2.7192;
    OEW = OEW .* OEWCF;
    
    % compute the new MTOW
    %NewMTOW = OEW + Wpay + Wfuel + Wbatt + Weng + Wem;
    NewMTOW = OEW + Wpay + Wfuel + Wbatt;
    
    % compute the relative error to check convergence
    Err = abs(NewMTOW - MTOW) / MTOW;
    
    % iterate
    Iter = Iter + 1;
    
    % remember the MTOW
    MTOW = NewMTOW;
            
end

% throw a warning if iteration limit was reached
if (Iter >= MaxIter)
    warning("WARNING - UAVWeight: weight buildup not converged.");
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% remember the weights that changed
Aircraft.Specs.Weight.MTOW    = MTOW;
Aircraft.Specs.Weight.OEW     = OEW;
Aircraft.Specs.Weight.Engines = Weng;
Aircraft.Specs.Weight.EM      = Wem;


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Val] = CheckEmpty(Field)
%
% [Val] = CheckEmpty(Field)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 apr 2026
%
% check if a field is empty or contains a value.
%
% INPUTS:
%     Field - a variable that is either empty or not.
%             size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Val   - the value of the variable after it is checked.
%             size/type/units: 1-by-1 / double / []
%

% check the field
if (isempty(Field))
    
    % if empty, return 0
    Val = 0;
    
else
    
    % if not empty, return the value
    Val = Field;
    
end


end