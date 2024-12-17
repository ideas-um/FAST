function [Psupp] = PowerSupplementCheck(Preq, Arch, Lambda, Eta, TrnType, EtaFan)
%
% [Psupp] = PowerSupplementCheck(Preq, Arch, Lambda, Eta, TrnType, EtaFan, itrn)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 dec 2024
%
% In the propulsion architecture, check if any components are either
% suppling/siphoning power from the gas-turbine engines. If a component is
% placed in series after a gas-turbine engine, it siphons power (negative
% output). If a component is placed in parallel with a gas-turbine engine,
% it provides power (positive output, unless the flow is reversed).
%
% INPUTS:
%     Preq    - the power required by each component.
%               size/type/units: npnt-by-ntrn / double / [W]
%
%     Arch    - the architecture matrix for the transmitters only.
%               size/type/units: ntrn-by-ntrn / integer / []
%
%     Lambda  - the operational matrix for the transmitters only.
%               size/type/units: ntrn-by-ntrn / double / [%]
%
%     Eta     - the efficiency matrix for the transmitters only.
%               size/type/units: ntrn-by-ntrn / double / [%]
%
%     TrnType - the types of transmitters (gas-turbine engine, electric
%               motor, etc.) in the propulsion architecture.
%               size/type/units: 1-by-ntrn / int / []
%
%     EtaFan  - the fan efficiency for the gas-turbine engines.
%               size/type/units: 1-by-1 / double / [%]
%
% OUTPUTS:
%     Psupp   - the supplemental power provided/required by each
%               transmitter.
%               size/type/units: npnt-by-ntrn / double / [W]
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the number of control points and transmitters
[npnt, ntrn] = size(Preq);

% allocate memory for the supplemental power
Psupp = zeros(npnt, ntrn);


%% CHECK FOR SERIES CONNECTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% look for the gas-turbine engines
GTEs = find(TrnType == 1);

% if any gas-turbine engines exist, check for components in series (except
% propellers/fans)
if any(GTEs)
    
    % get the number of gas-turbine engines
    ngte = length(GTEs);
    
    % loop through each gas-turbine engine connection
    for igte = 1:ngte
        
        % get the row of interest
        CurRow = Arch(GTEs(igte), :);
        
        % get the connections that are not propellers/fans
        Conns = (CurRow == 1) & (TrnType ~= 2);
        
        % if there's no connections, move on
        if (~any(Conns))
            continue;
        end
        
        % compute the power siphon
        Psupp(:, GTEs(igte)) = Psupp(:, GTEs(igte)) - Preq(:, Conns) * ...
                               (Lambda(Conns, GTEs(igte)) ./ Eta(Conns, GTEs(igte)));
                           
    end
end


%% CHECK FOR PARALLEL CONNECTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check for components in parallel
AnyParallel = find(sum(Arch, 1) > 1);

% run the check
if (any(AnyParallel))
    
    % loop through each connection
    for iconn = 1:length(AnyParallel)
        
        % get the TS that is in parallel with the PS
        icomp = AnyParallel(iconn);

        % find the gas-turbine engine being supplemented
        Driving = find((Arch(:, icomp) > 0)' & (TrnType == 1));
        
        % check if there are multiple "driving" gas-turbine engines
        if (length(Driving) > 1)
            
            % don't know how much each motor is powering each gas-turbine
            continue;
            
        end
        
        % find the electric motors that are supplementing
        Helping = find((Arch(:, icomp) > 0)' & (TrnType == 0));
                
        % add the power supplement, accounting for the fan efficiency
        Psupp(:, Driving) = Psupp(:, Driving) + Preq(:, Helping) .* EtaFan; %#ok<FNDSB>, ignore warning about "find" ... easier to read this way
        
    end
end

% ----------------------------------------------------------

end