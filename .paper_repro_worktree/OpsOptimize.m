function [Aircraft] = OpsOptimize(Aircraft, ProfileFxn)
%
% [Aircraft] = OpsOptimize(Aircraft, ProfileFxn)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Operational power split optimization package driver.
%
% INPUTS:
%     Aircraft   - structure containing aircraft specifications, mission
%                  history, and information about which objective function
%                  should be optimized.
%                  size/type/units: 1-by-1 / struct / []
%
%     ProfileFxn - function handle for the mission profile to be flown.
%                  These typically reside in the "MissionProfilesPkg"
%                  folder.
%                  size/type/units: 1-by-1 / function handle / []
%
% OUTPUTS:
%     Aircraft   - structure with the optimized power splits.
%                  size/type/units: 1-by-1 / struct / []
%


%% OPTIMIZATION SETUP %%
%%%%%%%%%%%%%%%%%%%%%%%%

% zero the operations power splits
Aircraft.Specs.Power.Phi.Tko = 0;
Aircraft.Specs.Power.Phi.Clb = 0;
Aircraft.Specs.Power.Phi.Crs = 0;
Aircraft.Specs.Power.Phi.Des = 0;
Aircraft.Specs.Power.Phi.Lnd = 0;

% maximum number of iterations
MaxIter = Aircraft.PowerOpt.MaxIter;

% convergence tolerance
Tol = Aircraft.PowerOpt.Tol;

% count the iterations
iter = 0;

% flag for using prescribed power splits (or power split history)
Aircraft.PowerOpt.PhiCount = 0;


%% OPTIMIZE THE POWER SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% time the process
tic;

% iterate
while (iter < MaxIter)
    
    % fly the mission
    Aircraft = MissionSegsPkg.FlyMission(Aircraft, ProfileFxn);
    
    % reset the power split counter (for the next mission)
    Aircraft.PowerOpt.PhiCount = 1;
    
    % post-processing after first iteration
    if (iter < 1)
        
        % get the mission history
        History = Aircraft.Mission.History;
        
        % get the optimization settings
        PowerOpt = Aircraft.PowerOpt;
        
        % number of control points in the mission
        npnt = length(History.SI.Performance.Alt);
        
        % allocate memory for finding the power splits
        iphi = zeros(npnt, 1);
        
        % number of segments to hybridize
        nseg = length(PowerOpt.Segments);
        
        % get the power splits to modify
        for iseg = 1:nseg
            
            % check through each segment to find their indices
            iphi = iphi + strcmp(History.Segment, PowerOpt.Segments(iseg));
            
        end
        
        % convert the resultant array from searching to a logical
        iphi = logical(iphi);
        
        % get the number of power splits to solve for
        nphi = sum(iphi);
        
        % check if all power splits in mission must be optimized
        if (nphi == npnt)
            
            % get points to hybridize (final point doesn't matter)
            ielem = find(iphi);
            
        else
            
            % get points to hybridize, add an extra point for math needs
            ielem = [find(iphi); 0];
            
            % locate the extra control point
            ielem(end) = ielem(end - 1) + 1;
        
        end
    end
    
    % setup the simplex method
    Tableau = OptimizationPkg.SimplexSetup(Aircraft, ielem);
    
    % solve the tableau
    PhiOpt = OptimizationPkg.SimplexSolve(Tableau);
    
    % post-process the result
    Aircraft = OptimizationPkg.SimplexPost(Aircraft, ielem, PhiOpt);

    % get the objective function
    ObjFun = Aircraft.PowerOpt.ObjFun;
    
    % find the appropriate objective
    if     (strcmpi(ObjFun, "DOC") == 1)
        
        % compute the DOC
        Obj = 0;
        
    elseif (strcmpi(ObjFun, "FuelBurn") == 1)
        
        % get the fuel burn
        Obj = Aircraft.Mission.History.SI.Weight.Fburn(end);
        
    elseif (strcmpi(ObjFun, "Energy") == 1)
        
        % get the total energy consumed
        Obj = Aircraft.Mission.History.SI.Energy.Fuel(end) + ...
              Aircraft.Mission.History.SI.Energy.Batt(end) ;
        
    else
        
        % throw error
        error("ERROR - OpsOptimize: invalid objective function type. must be 'DOC', 'FuelBurn', or 'Energy'.");
        
    end
    
    % print the result
    fprintf(1, "Objective Function Value: %.8e\n", Obj);
    
    % get the power splits from the optimization
    CurPhi = Aircraft.Mission.History.SI.Power.Phi(ielem(1:nphi));
    
    % check convergence after the first update
    if (iter > 0)
                
        % compute the relative error between iterates
        RelErr = abs(CurPhi - OldPhi) ./ OldPhi;
        
        % check convergence
        if (~any(RelErr > Tol))
            
            % the power split history no longer needs to be saved
            Aircraft.PowerOpt = rmfield(Aircraft.PowerOpt, "PhiHist");
            
            % break out of the loop
            break;
            
        end
    end
    
    % iterate
    iter = iter + 1;
    
    % remember the last iterate
    OldPhi = CurPhi;
    
    % remember the entire power split history (gets cleared in next iter.)
    Aircraft.PowerOpt.PhiHist = Aircraft.Mission.History.SI.Power.Phi;
        
end

% stop the process
Aircraft.PowerOpt.WallTime = toc;

% return the number of iterations run
Aircraft.PowerOpt.Iter = iter;

% ----------------------------------------------------------

end