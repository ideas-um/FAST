function [f, Grad] = TestLineSearchObj(x, NeedGrad)
%
% [f, Grad] = TestLineSearchObj(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Test function for the line search.
%
% INPUTS:
%     x        - vector of design variables.
%                size/type/units: n-by-1 / double / []
%
%     NeedGrad - flag to compute gradients (1 for gradients, otherwise 0).
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     f        - objective function value.
%                size/type/units: 1-by-1 / double / []
%
%     Grad     - gradients (if requested).
%                size/type/units: n-by-1 or 0-by-0 / double / []
%

% ----------------------------------------------------------

% compute the objective value
f = 0.1 * x(1) ^ 6 - 1.5 * x(1) ^ 4 + 5 * x(1) ^ 2 + 0.1 * x(2) ^ 4 + 3 * x(2) ^ 2 - 9 * x(2) + 0.5 * x(1) * x(2);

% check if gradient is needed
if (NeedGrad == 1)
    
    % compute the partial derivatives
    dfdx1 = 0.6 * x(1) ^ 5 - 6 * x(1) ^ 3 + 10 * x(1) + 0.5 * x(2);
    dfdx2 = 0.4 * x(2) ^ 3 - 9                        + 0.5 * x(1);
    
    % assemble the gradient
    Grad = [dfdx1; dfdx2];
    
else
    
    % return an empty gradient
    Grad = [];
    
end

% ----------------------------------------------------------

end