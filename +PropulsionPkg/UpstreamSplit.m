function [UpSplit] = UpstreamSplit(Pups, Pdwn, Arch, Oper, Eta, PSPSFlag)
%
% [UpSplit] = UpstreamSplit(Pups, Pdwn, Arch, Oper, Eta, PSPSFlag)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 20 may 2024
%
% Given a energy-power source, power-power source, or power-thrust source
% pair, compute the upstream power splits, defined as:
%
%     UpSplit(i, j) = Power Supplied by j to i / Power Output by j
%
% For the inputs/outputs below, nups and ndwn represent the number of
% upstream sources and the number of downstream sources, respectively.
%
% INPUTS:
%     Pups     - power required at the upstream sources.
%                size/type/units: 1-by-nups / double / [W]
%
%     Pdwn     - power required at the downstream sources.
%                size/type/units: 1-by-ndwn / double / [W]
%
%     Arch     - architecture matrix between the sources.
%                size/type/units: nups-by-ndwn / int / []
%
%     Oper     - (downstream) operational matrix between the sources.
%                size/type/units: nups-by-ndwn / double / [%]
%
%     Eff      - efficiency matrix between the sources.
%                size/type/units: nups-by-ndwn / double / [%]
%
%     PSPSFlag - flag to indicate that power-power sources are being
%                analyzed (1).
%                size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     UpSplit  - the upstream power splits.
%                size/type/units: nups-by-ndwn / double / [%]
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check that the input array %
% sizes are valid            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the size of the forward/aft sources
nups = length(Pups);
ndwn = length(Pdwn);

% get the size of the architecture matrix
[nrow, ncol] = size(Arch);

% check that the size of the architecture matrix is consistent
if ((nrow ~= nups) || (ncol ~= ndwn))
    
    % throw an error
    error("ERROR - UpstreamSplit: architecture matrix size is inconsistent with the source array sizes.");
    
end

% get the size of the operational matrix
[nrow, ncol] = size(Oper);

% check that the size of the operational matrix is consistent
if ((nrow ~= nups) || (ncol ~= ndwn))
    
    % throw an error
    error("ERROR - UpstreamSplit: operational matrix size is inconsistent with the source array sizes.");
    
end

% get the size of the efficiency matrix
[nrow, ncol] = size(Eta);

% check that the size of the efficiency matrix is consistent
if ((nrow ~= nups) || (ncol ~= ndwn))
    
    % throw an error
    error("ERROR - UpstreamSplit: efficiency matrix size is inconsistent with the source array sizes.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup output matrix        %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize a matrix of zeros
UpSplit = zeros(nups, ndwn);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% find the driven and driven %
% components in the given    %
% architecture               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if a flag was input (otherwise, assume no PS-PS analysis
if (nargin < 6)
    PSPSFlag = 0;
end

% identify the driving components
if (PSPSFlag)
    
    % ignore the diagonal when finding driving/driven components
    [~, Driving] = find(Arch - eye(nups));
    
else
    
    % check all matrix elements
    [~, Driving] = find(Arch);
    
end

% eliminate copies of returned indices
Driving = unique(Driving);


%% COMPUTE THE UPSTREAM SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of driving sources
ndriving = length(Driving);

% loop through the driving sources
for idriving = 1:ndriving
    
    % get the current source's index
    ips = Driving(idriving);
    
    % check which sources it drives
    Driven = find(Arch(:, ips));
    
    % get the number of driven sources
    ndriven = length(Driven);
    
    % loop through each driven source
    for idriven = 1:ndriven
                
        % check if it's driving itself
        if (ips == Driven(idriven))
            
            % if it powers itself, its upstream power split is 1
            UpSplit(ips, ips) = 1;
            
            % continue to the next iteration
            continue;
            
        end
        
        % compute the "supplied power"
        Psupp = Pups(Driven(idriven)) * Oper(Driven(idriven), ips) / Eta(Driven(idriven), ips);
        
        % compute the upstream split
        UpSplit(Driven(idriven), ips) = Psupp / Pdwn(ips);
        
    end
end

% ----------------------------------------------------------

end