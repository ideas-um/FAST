function [g, h, dgdx, dhdx] = TestLineSearchCon(x, NeedGrad)
%
% [g, h, dgdx, dhdx] = TestLineSearchCon(x, NeedGrad)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Constraint for testing the line search. For the definitions below, nx is
% the number of design variables, ng is the number of inequality
% constraints, and nh is the number of equality constraints.
%
% INPUTS:
%     x        - current design point.
%                size/type/units: nx-by-1 / double / []
%
%     NeedGrad - whether the gradient is needed (1) or not (0).
%                size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     g        - inequality constraints.
%                size/type/units: ng-by-1 / double / []
%
%     h        -   equality constraints.
%                size/type/units: nh-by-1 / double / []
%
%     dgdx     - inequality constraints' derivatives.
%                size/type/units: ng-by-nx or 0-by-0 / double / []
%
%     dhdx     -   equality constriants' derivatives.
%                size/type/units: nh-by-nx or 0-by-0 / double / []
%

% ----------------------------------------------------------

% just use an inequality constraint
g = x - 2;

% no equality constraints
h = [];

% check if derivatives are needed
if (NeedGrad == 1)
    
    % compute the derivatives
    dgdx = 1 ;
    dhdx = [];
    
end

% ----------------------------------------------------------

end