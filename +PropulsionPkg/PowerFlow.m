function [P] = PowerFlow(P, Arch, Lambda, Eta, Direct, Tol)
%
% [P] = PowerFlow(P, Arch, Lambda, Eta, Direct, Tol)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 12 dec 2024
%
% given a system architecture, propagate "stuff" through it.
%
% INPUTS:
%     P      - power required/available for downstream/upstream flows,
%              respectively.
%              size/type/units: n-by-1 / double / []
%
%     Arch   - propulsion architecture matrix, showing a connection (1) or
%              not (0) between components.
%              size/type/units: n-by-n / logical / []
%
%     Lambda - up/downstream operational matrix, depending on the direction
%              that the power flow is going.
%              size/type/units: n-by-n / double / [%]
%
%     Eta    - up/downstream efficiency matrix, depending on the direction
%              that the power flow is going.
%              size/type/units: n-by-n / double / [%]
%
%     Direct - indicates whether the power flow is going up/downstream,
%              either:
%                  a) +1:   upstream (-->)
%                  b) -1: downstream (<--)
%              size/type/units: 1-by-1 / integer / []
%
%     Tol    - convergence tolerance (defaults to 1.0e-06).
%              size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     P      - power required/available after being propagated through the
%              propulsion architecture.
%              size/type/units: n-by-1 / double / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the input vector's length
n = length(P);

% remember previous iteration
Pold = zeros(n, 1);

% call the appropriate propagation function
if     (Direct == +1)
    
    % propagate upstream
    PropFun = @(Arch, Lambda, Eta) (Lambda .* Arch .* Eta)';
    
elseif (Direct == -1)
    
    % propagate downstream
    PropFun = @(Arch, Lambda, Eta) (Lambda .* Arch ./ Eta)';
    
else
    
    % throw an error
    error("ERROR - SysFlow: 'Direct' must be +1 (propagate upstream) or -1 (propagate downstream).");
    
end

% check for a convergence tolerance
if (nargin < 6)
    
    % define a default tolerance
    EPS = 1.0e-06;
    
else
    
    % use the input tolerance
    EPS = Tol;
    
end


%% ITERATE %%
%%%%%%%%%%%%%

% find the matrix to represent propagation through the system architecture
M = PropFun(Arch, Lambda, Eta);

% iteration counter
iter = 0;

% multiply while 2-norm is greater than a tolerance 
while ((norm(Pold - P) > EPS) && (iter < n))
    
    % multiply (propagate through the system architecture)
    Pstar = M * P;
    
    % remember the previous iterate
    Pold = P;
    
    % remember which indices to update
    UpdateIndx = abs(Pstar) > EPS;
    
    % update
    P(UpdateIndx) = Pstar(UpdateIndx);
    
    % increment the iteration
    iter = iter + 1;

end


end