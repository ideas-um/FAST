function [Psupp] = PowerSupplementCheck(iprob)
%
% [Psupp] = PowerSupplementCheck(iprob)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 sep 2024
%
% In the propulsion architecture, check if any components are either
% suppling/siphoning power from the gas-turbine engines. If a component is
% placed in series after a gas-turbine engine, it siphons power (negative
% output). If a component is placed in parallel with a gas-turbine engine,
% it provides power (positive output, unless the flow is reversed).
%
% INPUTS:
%     iprob - the problem to be solved.
%             size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     Psupp - the supplemental power provided/required into each power
%             source.
%             size/type/units: 1-by-nps / double / [W]
%


%% ESTABLISH ARBITRARY PARAMETERS FOR NOW %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if     (iprob == 1)
    
    % series/parallel
    PSPS = [1, 0; 1, 1];
    PreqDr = [80, 20; 70, 30];
    SplitPSPS = [1, 0; 0.9, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [1, 1];
    PSType = [1, 0];
    FanEfficiency = 1;
    
elseif (iprob == 2)

    % series/parallel, but swap order
    PSPS = [1, 1; 0, 1];
    PreqDr = [20, 80; 30, 70];
    SplitPSPS = [1, 0.9; 0, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [1, 1];
    PSType = [0, 1];
    FanEfficiency = 1;
    
elseif (iprob == 3)

    % series only
    PSPS = [1, 0; 1, 1];
    PreqDr = [10, 90; 15, 85];
    SplitPSPS = [1, 0; 1, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [1, 0; 0, 1];
    PSType = [1, 0];
    FanEfficiency = 1;

elseif (iprob == 4)
    
    % series only, but swap order
    PSPS = [1, 1; 0, 1];
    PreqDr = [90, 10; 85, 15];
    SplitPSPS = [1, 1; 0, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [0, 1; 1, 0];
    PSType = [0, 1];
    FanEfficiency = 1;

elseif (iprob == 5)
    
    % parallel only
    PSPS = [1, 0; 0, 1];
    PreqDr = [80, 20; 90, 10];
    SplitPSPS = [1, 0; 0, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [1, 1];
    PSType = [1, 0];
    FanEfficiency = 1;

elseif (iprob == 6)
    
    % parallel only, but swap order
    PSPS = [1, 0; 0, 1];
    PreqDr = [20, 80; 10, 90];
    SplitPSPS = [1, 0; 0, 1];
    EtaPSPS = [1, 1; 1, 1];
    TSPS = [1, 1];
    PSType = [0, 1];
    FanEfficiency = 1;
    
else
    
    % don't solve
    Psupp = 0;
    
    return
    
end    


%% PERFORM THE ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of points
[npnt, nps] = size(PreqDr);

% allocate memory for the supplemental power
Psupp = zeros(npnt, nps);

% check for components in series
AnySeries = find(sum(PSPS - eye(nps), 1) > 0);

% run the check
if (any(AnySeries))
    
    % memory for removing each driving PS
    RemoveDriving = zeros(nps, 1);
    
    % loop through each connection
    for iconn = 1:length(AnySeries)
        
        % get the component
        icomp = AnySeries(iconn);
        
        % remove the driving source
        RemoveDriving(icomp) = 1;
        
        % get the components in series
        MyConns = find(PSPS(:, icomp) - RemoveDriving > 0);
        
        % account for the power siphon
        Psupp(:, icomp) = Psupp(:, icomp) - PreqDr(:, MyConns) * ...
                       (SplitPSPS(MyConns, icomp) ./ EtaPSPS(MyConns, icomp));
                   
        % reset the driving source
        RemoveDriving(icomp) = 0;
                   
    end % for
end % if

% check for components in parallel
AnyParallel = find(sum(TSPS, 2) > 1);

% run the check
if (any(AnyParallel))
    
    % loop through each connection
    for iconn = 1:length(AnyParallel)
        
        % get the TS that is in parallel with the PS
        icomp = AnyParallel(iconn);

        % find the gas-turbine engine being supplemented
        Driving = find((TSPS(icomp, :) > 0) & (PSType > 0));
        
        % check if there are multiple "driving" gas-turbine engines
        if (length(Driving) > 1)
            
            % don't know how much each motor is powering each gas-turbine
            continue;
            
        end
        
        % find the electric motors that are supplementing
        Helping = find((TSPS(icomp, :) > 0) & (PSType == 0));
                
        % add the power supplement
        Psupp(:, Driving) = Psupp(:, Driving) + PreqDr(:, Helping) ./ FanEfficiency; %#ok<FNDSB>, ignore warning about "find" ... easier to read this way
        
    end % for
end % if

% ----------------------------------------------------------

end