function [xopt, iter] = SimplexSolve(A)
%
% [xopt, iter] = SimplexSolve(A)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 mar 2024
%
% Use the Simplex Method to solve a linear program. For the inputs/outputs
% below, nx and ng represent the number of design variables and number of
% constraints, respectively.
%
% INPUTS:
%     A    - tableau to be solved.
%            size/type/units: ng+1-by-nx+1 / double / []
%
% OUTPUTS:
%     xopt - optimum point computed by the simplex method.
%            size/type/units: nx-by-1 / double / []
%
%     iter - number of iterations to solve to tableau.
%            size/type/units: 1-by-1 / int / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the tableau size
[nrow, ncol] = size(A);

% extract the number of variables and constraints
nvar = ncol - 1;
ncon = nrow - 1;

% define a tolerance
EPS06 = 1.0e-06;

% find the basic variables
IsBasic = abs(A(end, 1:nvar)) < EPS06;

% identify the location of the basic variables
BasicLoc = cumsum(IsBasic);

% get the number of basic variables (should be equal to nvar - ncon)
nbasic = BasicLoc(end);

% perform sanity check % this doesnt seem right, should it be number of
% rows?
if ((nvar - nbasic) ~= (nvar - ncon))
    error("ERROR - SimplexSolve: check number of basic variables.");
end


%% PERFORM THE SIMPLEX METHOD %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set iteration counter
iter = 0;

% iterate until all cost variables (final row) are positive
while ((any(A(end, 1:nvar) < 0)) && (iter < 10000))
    
    % find the minimum cost coefficient
    [~, icol] = min(A(end, 1:nvar));
    
    % remember the positive entries in the column
    IsPos = A(1:ncon, icol) > 0;
    
    % compute the constraint ratio
    ConRat = A(1:ncon, end) ./ A(1:ncon, icol);
    
    % if the coefficient in the column is negative, reject it
    ConRat(~IsPos) = Inf;
    
    % find the pivot row
    [~, irow] = min(ConRat);
    
    % check for unbounded problem
    if (ConRat(irow) > 1.0e+12)
        error('ERROR - SimplexSolve: solution likely unbounded, ill-posed problem.');
    end
    
    % find the basic variable to become nonbasic
    ibasic = find(BasicLoc == irow, 1);
    
    % convert the basic variable to a nonbasic variable
    BasicLoc(ibasic) = 0;
    
    % convert the nonbasic variable to a basic variable
    BasicLoc(icol) = irow;
    
    % perform the reduction step
    A = OptimizationPkg.GaussElim(A, irow, icol);
    
    % iterate
    iter = iter + 1;

end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the output
xopt = zeros(nvar, 1);

% find the basic variables' values
for ivar = 1:nvar
    
    % check if its a basic variable
    if (BasicLoc(ivar) > 0)
        
        % find the row with the nonzero element
        irow = BasicLoc(ivar);
        
        % return the value
        xopt(ivar) = A(irow, end);
        
    end
end

% ----------------------------------------------------------

end