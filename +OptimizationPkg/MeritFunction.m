function [fhat] = MeritFunction(ObjFun, x, ConFun, s, mu)
%
% [fhat] = MeritFunction(ObjFun, x, ConFun, s, mu)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Develop a merit function for line searching. For the inputs/outputs
% below, nx and ns represent the number of design variables and slack
% variables, respectively.
%
% INPUTS:
%     ObjFun - call to objective function.
%              size/type/units: 1-by-1 / function handle / []
%
%     x      - current design point.
%              size/type/units: nx-by-1 / double / []
%
%     ConFun - call to constraint function (if any).
%              size/type/units: 1-by-1 / function handle / []
%
%     s      - current slack variables (if any).
%              size/type/units: ns-by-1 / double / []
%
%     mu     - current penalty parameter (if any).
%              size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     fhat   - merit function value.
%              size/type/units: 1-by-1 / double / []
%

% ----------------------------------------------------------

% evaluate the objective
[f, ~, info] = ObjFun(x, 0);

% check for constraints
if (nargin >= 3)
    
    % check for info to be passed from the objective to constraints
    if (isempty(info) == 1)
        
        % evaluate the constraints (no   extra info)
        [g, h] = ConFun(x, 0);
        
    else
        
        % evaluate the constraints (with extra info)
        [g, h] = ConFun(x, 0, info);
        
    end
    
    % check for inequality constraints
    if (isempty(g))
        
        % no inequality constraints
        g = 0;
        
    end
    
    % check for   equality constraints
    if (isempty(h))
        
        % no   equality constraints
        h = 0;
        
    end
    
else
    
    % the problem is unconstrained, so all constraints are "satisfied"
    g = 0;
    h = 0;
    
end

% check for slack variables
if ((nargin >= 4) && (~isempty(g)))
    
    % compute the slack variable contribution
    SlackPen = mu * sum(log(s));
    
    % define the penalty parameter
    rho = 100 * mu;
    
else
    
    % there are no slack variables or penalty
    s        = 0;
    SlackPen = 0;
    
    % assume a penalty parameter
    rho = 1;
    
end

% penalize the constraints
ConPen = 0.5 * rho * (norm(h) ^ 2 + norm(g + s) ^ 2);

% develop the merit function
fhat = f - SlackPen + ConPen;

% ----------------------------------------------------------

end