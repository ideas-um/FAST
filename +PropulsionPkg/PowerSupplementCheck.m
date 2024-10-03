function [Psupp] = PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, EtaFan)
%
% [Psupp] = PowerSupplementCheck(iprob)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 03 oct 2024
%
% In the propulsion architecture, check if any components are either
% suppling/siphoning power from the gas-turbine engines. If a component is
% placed in series after a gas-turbine engine, it siphons power (negative
% output). If a component is placed in parallel with a gas-turbine engine,
% it provides power (positive output, unless the flow is reversed).
%
% INPUTS:
%     PreqDr    - the power required to turn the driven power sources.
%                 size/type/units: npnt-by-nps / double / [W]
%
%     TSPS      - the architecture matrix for the thrust-power source
%                 connections.
%                 size/type/units: nts-by-nps / integer / []
%
%     PSPS      - the architecture matrix for the power-power source
%                 connections.
%                 size/type/uints: nps-by-nps / integer / []
%
%     SplitPSPS - the operational power split matrix between all of the
%                 power sources.
%                 size/type/units: nps-by-nps / double / [%]
%
%     EtaPSPS   - the efficiency matrix for the power-power source
%                 connections.
%                 size/type/units: nps-by-nps / double / [%]
%
%     PSType    - the types of power sources (gas-turbine engine, electric
%                 motor, etc.) in the propulsion architecture.
%                 size/type/units: 1-by-nps / int / []
%
%     EtaFan    - the fan efficiency for the gas-turbine engines.
%                 size/type/units: 1-by-1 / double / [%]
%
% OUTPUTS:
%     Psupp     - the supplemental power provided/required into each power
%                 source.
%                 size/type/units: npnt-by-nps / double / [W]
%


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
                
        % add the power supplement, accounting for the fan efficiency
        Psupp(:, Driving) = Psupp(:, Driving) + PreqDr(:, Helping) .* EtaFan; %#ok<FNDSB>, ignore warning about "find" ... easier to read this way
        
    end % for
end % if

% ----------------------------------------------------------

end