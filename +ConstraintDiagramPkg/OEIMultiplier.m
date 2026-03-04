function [k] = OEIMultiplier(Aircraft)
%
% [k] = OEIMultiplier(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 mar 2026
%
% return the appropriate multiplier for engine inoperative conditons,
% either based on a discrete number of engines installed or a percent
% specific excess power loss.
%
% INPUTS:
%     Aircraft - data structure with information about the aircraft.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     k        - the multiplier for the engine inoperative condition.
%                size/type/units: 1-by-1 / double / []
%

% get the constraint type
Type = Aircraft.Settings.ConstraintType;

% check the multiplier type
if (Type == 0)
    
    % get the number of engines
    Neng = Aircraft.Specs.Propulsion.NumEngines;
    
    % compute the multiplier
    k = Neng / (Neng - 1);
    
elseif (Type == 1)
    
    % compute the percent specific excess power loss during nEI conditions
    PsLoss = Aircraft.Specs.Performance.PsLoss;
    
    % compute the multiplier (derived quadratic function)
    k = 1.045 .* PsLoss .^ 2 + 1;
    
else
    
    % throw an error
    error("ERROR - OEIMultiplier: invalid Type selected, must be 0 or 1.");
    
end

% ----------------------------------------------------------

end