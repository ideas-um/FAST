function [g, h, dgdx, dhdx] = NewTestCon(x, NeedGrad)
%
% [g, h, dgdx, dhdx] = NewTestCon(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Example constraint for testing the interior point optimizer. Adapted from
% Engineering Design Optimization, Example 5.16. For the inputs/outputs
% below, nx, ng, and nh represent the number of design variables,
% inequality constraints, and equality constraints, respectively.
%
% INPUTS:
%     x        - design variable vector.
%                size/type/units: nx-by-1 / double / []
%
%     NeedGrad - flag to compute gradients (1) or not (0).
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     g        - inequality constraint values.
%                size/type/units: ng-by-1 / double / []
%
%     h        -   equality constraint values.
%                size/type/units: nh-by-1 / double / []
%
%     dgdx     - gradient of inequality constraints.
%                size/type/units: ng-by-nx or 0-by-0 / double / []
%
%     dhdx     - gradient of   equality constraints.
%                size/type/units: nh-by-nx or 0-by-0 / double / []
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

% define constants for   constrained problem
Lc1 = 9;
Lc2 = 6;
yc  = 2;
xc1 = 7;
xc2 = 3;

% compute the inequality constraints
g1 = sqrt((x(1) + xc1) ^ 2 + (x(2) + yc) ^ 2) - Lc1;
g2 = sqrt((x(1) - xc2) ^ 2 + (x(2) + yc) ^ 2) - Lc2;

% assemble the constraints
g = [g1; g2];

% there are no equality constraints
h = [];

% check if a gradient is needed
if (NeedGrad == 1)
        
    % compute the partial derivatives for the inequality constraints
    dg1dx1 = (x(1) + xc1) / (sqrt((x(1) + xc1) ^ 2 + (x(2) + yc) ^ 2));
    dg1dx2 = (x(2) + yc ) / (sqrt((x(1) + xc1) ^ 2 + (x(2) + yc) ^ 2));
    
    dg2dx1 = (x(1) - xc2) / (sqrt((x(1) - xc2) ^ 2 + (x(2) + yc) ^ 2));
    dg2dx2 = (x(2) + yc ) / (sqrt((x(1) - xc2) ^ 2 + (x(2) + yc) ^ 2));
    
    % assemble into a gradient
    dgdx = [dg1dx1, dg1dx2; dg2dx1, dg2dx2];
    
    % no   equality constraints
    dhdx = [];
   
else
    
    % return empty arrays
    dhdx = [];
    dgdx = [];
    
end

% ----------------------------------------------------------

end