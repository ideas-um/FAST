function [f, dfdx, info] = NewTestObj(x, NeedGrad)
%
% [f, dfdx, info] = NewTestObj(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Example objective function for testing the interior point optimizer.
% Adapted from Engineering Design Optimization, Example 5.16.
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
%                size/types/units: n-by-1 or 0-by-0 / double / []
%

% ----------------------------------------------------------

% assume a gradient is wanted
if (nargin < 2)
    NeedGrad = 1;
end

% define constants for unconstrained problem
L1 = 12;
L2 =  8;
k1 =  1;
k2 = 10;
mg =  7;

% compute the objective function
f = 0.5 * k1 * (sqrt((L1 + x(1)) ^ 2 + x(2) ^ 2) - L1) ^ 2 + ...
    0.5 * k2 * (sqrt((L2 - x(1)) ^ 2 + x(2) ^ 2) - L2) ^ 2 - ...
    mg  *                              x(2)               ;

% check if a gradient is needed
if (NeedGrad == 1)
    
    % compute the partial derivatives
    dfdx1 =  k2 * (L2 - sqrt(x(2) ^ 2 + (L2 - x(1)) ^ 2)) * (L2 - x(1)) / sqrt(x(2) ^ 2 + (L2 - x(1)) ^ 2) - ...
             k1 * (L1 - sqrt((L1 + x(1)) ^ 2 + x(2) ^ 2)) * (L1 + x(1)) / sqrt((L1 + x(1)) ^ 2 + x(2) ^ 2) ;
    dfdx2 = -k2 * (L2 - sqrt(x(2) ^ 2 + (L2 - x(1)) ^ 2)) *       x(2)  / sqrt(x(2) ^ 2 + (L2 - x(1)) ^ 2) - ...
             k1 * (L1 - sqrt((L1 + x(1)) ^ 2 + x(2) ^ 2)) *       x(2)  / sqrt((L1 + x(1)) ^ 2 + x(2) ^ 2) - ...
             mg ;
    
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