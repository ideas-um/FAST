function [g, h, dgdx, dhdx] = TestCon(x, NeedGrad)
%
% [g, h, dgdx, dhdx] = TestCon(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Example constraint for testing the interior point optimizer. Adapted from
% Engineering Design Optimization, Example 5.4. For the inputs/outputs
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
%                size/type/units: ng-by-nx / double / []
%
%     dhdx     - gradient of   equality constraints.
%                size/type/units: nh-by-nx / double / []
%

% ----------------------------------------------------------

% assume a gradient is wanted
if (nargin < 2)
    NeedGrad = 1;
end

% compute the inequality constraints
g1 = 0.25 * x(1) ^ 2 + x(2) ^ 2 - 1;
g2 =                 - x(2)        ;
g3 =      - x(1)                   ;

% assemble the constraints
g = [g1; g2; g3];

% there are no equality constraints
h = [];

% check if a gradient is needed
if (NeedGrad == 1)
        
    % compute the partial derivatives for the inequality constraints
    dg1dx1 = 0.5 * x(1);
    dg1dx2 = 2   * x(2);
    
    dg2dx1 =  0;
    dg2dx2 = -1;
    
    dg3dx1 = -1;
    dg3dx2 =  0;
    
    % assemble into a gradient
    dgdx = [dg1dx1, dg1dx2; dg2dx1, dg2dx2; dg3dx1, dg3dx2];
    
    % no   equality constraints
    dhdx = [];
   
else
    
    % return empty arrays
    dhdx = [];
    dgdx = [];
    
end

% ----------------------------------------------------------

end