function [Psupp] = PowerSupplementCheck()
%
% [Psupp] = PowerSupplementCheck()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 26 sep 2024
%
% check new approach to accounting for power supplements.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Psupp - the supplemental power provided/required into each power
%             source.
%             size/type/units: 1-by-nps / double / [W]
%


%% ESTABLISH ARBITRARY PARAMETERS FOR NOW %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% series/parallel
% PSPS = [1, 0; 1, 1];
% PreqDr = [80, 20];
% ipnt = 1;
% SplitPSPS = [1, 0; 0.9, 1];
% EtaPSPS = [1, 1; 1, 1];%0.96, 1];
% TSPS = [1, 1];
% PSType = [1, 0];
% FanEfficiency = 1;%0.99;

% series only
% PSPS = [1, 0; 1, 1];
% PreqDr = [10, 90];
% ipnt = 1;
% SplitPSPS = [1, 0; 1, 1];
% EtaPSPS = [1, 1; 1, 1];
% TSPS = [1, 0; 0, 1];
% PSType = [1, 0];
% FanEfficiency = 1;

% parallel only
PSPS = [1, 0; 0, 1];
PreqDr = [80, 20];
ipnt = 1;
SplitPSPS = [1, 0; 0, 1];
EtaPSPS = [1, 1; 1, 1];
TSPS = [1, 1];
PSType = [1, 0];
FanEfficiency = 1;


%% PERFORM THE ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of power sources
[nps, ~] = size(PSPS);

% allocate memory for the supplemental power
Psupp = zeros(1, nps);

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
        Psupp(icomp) = Psupp(icomp) - PreqDr(ipnt, MyConns) * ...
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
        Psupp(icomp) = Psupp(icomp) + PreqDr(ipnt, Helping) ./ FanEfficiency; %#ok<FNDSB>, ignore warning about "find" ... easier to read this way
        
    end % for
end % if

% ----------------------------------------------------------

end