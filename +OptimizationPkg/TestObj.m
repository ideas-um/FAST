function [f, dfdx, info] = TestObj(x, NeedGrad)
%
% [f, dfdx, info] = TestObj(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Example objective function for testing the interior point optimizer.
% adapted from Engineering Design Optimization, Example 5.4.
%
% INPUTS:
%     x        - design variable vector.
%                size/type/units: n-by-1 / double / []
%
%     NeedGrad - flag to compute gradients (1) or not (0).
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     f        - objective function value.
%                size/type/units: 1-by-1 / double / []
%
%     dfdx     - gradients, if requested (otherwise empty).
%                size/type/units: n-by-1 or 0-by-0 / double / []

%     info     - structure with any information for the constraint
%                evaluation (so the objective doesn't need to be computed
%                again).
%                size/type/units: 1-by-1 / struct / []
%

% ----------------------------------------------------------

% assume a gradient is wanted
if (nargin < 2)
    NeedGrad = 1;
end

% compute the objective function
f = x(1) + 2 * x(2);

% check if a gradient is needed
if (NeedGrad == 1)
    
    % compute the partial derivatives
    dfdx1 = 1;
    dfdx2 = 2;
    
    % assemble into a gradient
    dfdx = [dfdx1; dfdx2];
   
else
    
    % return an empty array
    dfdx = [];
    
end

% don't return any information
info = [];

% ----------------------------------------------------------

end