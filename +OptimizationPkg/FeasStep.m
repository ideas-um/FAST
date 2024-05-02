function [amax] = FeasStep(ng, s, ps)
%
% [amax] = FeasStep(ng, s, ps)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Find the maximum step size that is feasible. For the inputs/outputs
% below, ns and nx are the number of slack variables and design variables,
% respectively.
%
% INPUTS:
%     ng   - number of inequality constraints.
%            size/type/units: 1-by-1 / int / []
%
%     s    - slack variables.
%            size/type/units: ns-by-1 / double / []
%
%     ps   - search directions.
%            size/type/units: nx-by-1 / double / []
%
% OUTPUTS:
%     amax - maximum step size.
%            size/type/units: 1-by-1 / double / []
%

% ----------------------------------------------------------

% define a fractional tolerance
tau = 0.005;

% assume a maximum step size
amax = 1.0;

% compute the maximum step sizes allowed by the constraints
MaxStep = (tau - 1) .* s ./ ps;

% if any step sizes are positive, find the maximum step that can be taken
for ig = 1:ng
    
    % check for a positive step size
    if (MaxStep(ig) > 0)
        
        % compute the maximum feasible step
        amax = min(amax, MaxStep(ig));
        
    end
end

% ----------------------------------------------------------

end