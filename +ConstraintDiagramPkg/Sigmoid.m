function [f] = Sigmoid(Aircraft, a, b, c, d)
%
% [f] = Sigmoid(Aircraft, a, b, c, d)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 25 aug 2025
%
% evaluate the required climb gradient for a given specific excess power
% loss using a sigmoid curve.
%
% INPUTS:
%     Aircraft - data structure with information about the aircraft.
%                size/type/units: 1-by-1 / struct / []
%
%     a        - sigmoid curve amplitude.
%                size/type/units: 1-by-1 / double / []
%
%     b        - sigmoid curve rate of change.
%                size/type/units: 1-by-1 / double / []
%
%     c        - sigmoid curve phase shift.
%                size/type/units: 1-by-1 / double / []
%
%     d        - sigmoid curve vertical translation.
%                size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     f        - sigmoid curve function value.
%                size/type/units: 1-by-1 / double / []
%

% get the specific excess power loss that is being designed for
PsLoss = Aircraft.Specs.Performance.PsLoss;

% compute the function value
f = a ./ (1 + exp(-b .* (PsLoss - c))) + d;

% convert to a percentage
f = f ./ 100;

% ----------------------------------------------------------

end