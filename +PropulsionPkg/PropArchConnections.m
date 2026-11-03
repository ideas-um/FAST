function [Aircraft] = PropArchConnections(Aircraft)
%
% [Aircraft] = PropArchConnections(Aircraft)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 jan 2025
%
% Given a propulsion architecture, identify any parallel electric motor /
% engine connections. These connections are used to reduce the power
% supplied by an engine to turn the fan/propeller.
%
% INPUTS:
%     Aircraft - structure containing information about the aircraft and
%                its propulsion architecture from
%                "Aircraft.Specs.Propulsion.PropArch".
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - structure identifying the companion engines / electric
%                motors that are arranged in parallel.
%                size/type/units: 1-by-1 / struct / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the architecture
Arch = Aircraft.Specs.Propulsion.PropArch.Arch;

% get the number of sources and transmitters
nsrc = length(Aircraft.Specs.Propulsion.PropArch.SrcType);
ntrn = length(Aircraft.Specs.Propulsion.PropArch.TrnType);

% Retain one record per shared downstream target. Indexing only by the
% driving engine loses the target identity and cannot represent an engine
% that participates in more than one parallel group.
EmptyGroup = struct("Driving", [], "Helping", [], "Target", []);
Aircraft.Specs.Propulsion.PropArch.ParConns = repmat(EmptyGroup, 0, 1);


%% FIND THE POWER SOURCES IN PARALLEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the transmitter indices
itrn = nsrc + (1 : ntrn);

% check for components in parallel (offset by number of sources)
AnyParallel = find(sum(Arch(itrn, itrn), 1) > 1) + nsrc;

if (~any(AnyParallel))
    
    % exit the function
    return;
    
end


%% FLAG PARALLEL ENGINE-EM CONNECTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the records showing each engine / electric-motor parallel group
ParConns = Aircraft.Specs.Propulsion.PropArch.ParConns;

% get the transmitter types
TrnType = Aircraft.Specs.Propulsion.PropArch.TrnType;

% loop through each connection
for iconn = 1:length(AnyParallel)
    
    % get the TS that is in parallel with the PS
    icomp = AnyParallel(iconn);
    
    % find the gas-turbine engine being supplemented
    Driving = find((Arch(itrn, icomp) > 0)' & (TrnType == 1));
        
    % find the electric motors that are supplementing (offset by nsrc)
    Helping = find((Arch(itrn, icomp) > 0)' & (TrnType == 0)) + nsrc;
    
    % update both driving and helping components are not empty
    if (~isempty(Driving) && ~isempty(Helping))

        % Store a separate record for each engine at this target. Component
        % indices are absolute so consumers do not need mixed offset rules.
        for idrive = Driving
            Group = EmptyGroup;
            Group.Driving = idrive + nsrc;
            Group.Helping = Helping;
            Group.Target = icomp;
            ParConns(end + 1, 1) = Group; %#ok<AGROW>
        end
    
    end
end

% return the updated set of parallel connections
Aircraft.Specs.Propulsion.PropArch.ParConns = ParConns;


end
