function [amin, fval] = GoldenSection(f, x, p, amax, g, delta, tol)
%
% [amin, fval] = GoldenSection(f, x, p, amax, g, delta, tol)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Perform a Golden Section Search to find the minimum of a unimodal
% function. Only perform phase I of the search (bounding the minimum)
% rather than including phase II (reducing the bounds of uncertainty) for
% improved computational efficiency.
%
% INPUTS:
%     f     - the function handle to the function of interest.
%             size/type/units: 1-by-1 / function handle / []
%
%     x     - vector of current design variables.
%             size/type/units: n-by-1 / double / []
%
%     p     - current search direction.
%             size/type/units: n-by-1 / double / []
%
%     amax  - maximum step size to search.
%             size/type/units: 1-by-1 / double / []
%
%     delta - the interval size for phase I of the search.
%             size/type/units: 1-by-1 / double / []
%
%     tol   - the convergence parameter.
%             size/type/units: 1-by-1 / double / []
%
%     g     - function handle for constraints, if any (can exclude).
%             size/type/units: 1-by-1 / function handle / []
%
% OUTPUTS:
%     amin  - the optimum step size.
%             size/type/units: 1-by-1 / double / []
%
%     fval  - function value at the optimum step size.
%             size/type/units: 1-by-1 / double / []
%


%% CHECK FOR OPTIONAL ARGUMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if an upper bound on the step size is needed
if (nargin < 4)
    amax = 1.0e+06;
end

% check if a constraint function is supplied (if not, assume unconstrained)
if (nargin < 5)
    NeedCons = 0;
else
    NeedCons = 1;
end

% check if a step size is provided
if (nargin < 6)
    delta = 0.1;
end

% check if a tolerance is provided
if (nargin < 7)
    tol = 1.0e-03;
end


%% PHASE 0: COMPUTE INITIAL STEP SIZES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% find an initial set of     %
% step sizes that satsify    %
% the constraints            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% allocate memory for the function values
fvalue = zeros(1, 3);

% iterate until an appropriate set of step sizes is found
while (1)

    % assume the bounds won't need to be re-computed
    NewBounds = 0;
    
    % provide the initial step sizes
    abound = cumsum(delta * 1.618 .^ (0:2)');
    
    % check that the step sizes don't exceed the maximum
    aexceed = abound > amax;
    
    % if any step sizes were exceeded
    if (any(aexceed))
        
        % reduce the step size
        delta  = delta / 1.618;
        
        % continue to the next iteration of the loop
        continue
        
    end
    
    % evaluate the function at those points
    for i = 1:3
        
        % compute the candidate point's coordinates
        xcand = x + abound(i) .* p;
        
        % evaluate the function
        fvalue(i) = f(xcand);
        
        % check if there are constraints
        if (NeedCons == 1)
            
            % compute the constraint values
            [gvals, hvals] = g(xcand);
            
            % memory for the constraint values
            if (i == 1)
                
                % get the number of constraints
                ncon = length(gvals) + length(hvals);
                
                % memory for the constraints
                ConVals = zeros(ncon, 3);
                
            end
            
            % remember the constraints
            ConVals(:, i) = [gvals; abs(hvals)];
            
            % if any constraints are violated, don't search further
            if (any(ConVals(:, i) > 0))
                
                % reduce the maximum bound
                amax = abound(i);
                
                % use a smaller step size
                delta = delta / 1.618;
                
                % require a new step size computation
                NewBounds = 1;
                
                % exit the "for" loop
                break;
                
            end
        end
        
        % compare the first and second evaluations
        if (i == 2)
            
            % check if the second function value is greater than the first
            if (fvalue(2) - fvalue(1) > tol)
                
                % if so, throw a warning that the line search will fail
                %warning('ERROR - GoldenSection: function increases from f(a = 0) to f(a = delta).');
                
                % return the initial point as the minimum
                amin = abound(1);
                fval = fvalue(1);
                
                % break out of the function
                return
                
            end
        end
    end
    
    % if no bounds need to be re-computed, break out
    if (NewBounds == 0)
        break;
    end
    
end

% % plot initial results
% scatter(abound, fvalue, 40, '*', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black');
% hold on
% pause

% ---------------------------------------------------------

% phase I: bound the minimum (don't do phase II, which reduces the bounds)
while ((fvalue(2) - fvalue(3)) > 1.0e-06)
    
    % shift existing data
    abound(1) = abound(2);
    abound(2) = abound(3);
    
    fvalue(1) = fvalue(2);
    fvalue(2) = fvalue(3);
    
    % calculate the next step size
    abound(3) = abound(2) + delta * 1.618 ^ i;
    
    % check the step size
    if (abound(3) > amax)
        
        % stop at the maximum step size
        abound(3) = amax;
        
    end
        
    % calculate the objective value
    fvalue(3) = f(x + abound(3) .* p);
    
    % check if there are constraints
    if (NeedCons == 1)
        
        % compute the constraints
        [gvals, hvals] = g(x + abound(3) .* p);
        
        % remember the constraints
        ConVals(:, 3) = [gvals; abs(hvals)];
        
        % check if any constraints are violated
        if (any(ConVals(:, 3) > 0))
            
            % assume that the previous step was the largest to be taken
            abound(3) = abound(2);
            fvalue(3) = fvalue(2);
            
            % stop the search
            break
            
        end
    end
               
%     % plot new result
%     scatter(abound(3), fvalue(3), 40, '*', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black');
        
    % increment i
    i = i + 1;
    
end

% resulting interval of uncertainty
I = abound(3) - abound(1);

% set the bounds for phase II
al = abound(1);
au = abound(3);

% function values for lower and upper limits
fl = fvalue(1);
fu = fvalue(3);

% % plot bounds
% hold off
% scatter([al, au], [fl, fu], 40, '*', 'MarkerEdgeColor', 'black', 'MarkerFaceColor', 'black');
% hold on

% ---------------------------------------------------------

% return the global minumum
amin = (al + au) / 2;

% don't evaluate the objective function for now to save time
fval = []; % fval = f(x + amin .* p);

end