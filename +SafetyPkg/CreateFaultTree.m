function [] = CreateFaultTree(Arch, Components, RemoveSrc)
%
% CreateFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 30 sep 2024
%
% Given an adjacency-like matrix, assemble a fault tree that accounts for
% internal failures and redundant primary events.
%
% INPUTS:
%     Arch       - the architecture matrix representing the system
%                  architecture to be analyzed.
%                  size/type/units: n-by-n / int / []
%
%     Components - a structure array containing each component in the
%                  system architecture and the following information about
%                  it:
%                      a) the component name, a string
%                      b) the component type, a string
%                      c) a column vector of failure rates
%                      d) a column vector of failure modes corresponding to
%                         the failure rates
%                  size/type/units: 1-by-1 / struct / []
%
%     RemoveSrc  - a flag to indicate whether the sources should be removed
%                  from the system architecture (1) or not (0).
%                  size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     none
%


%% CHECK FOR VALID INPUTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the architecture     %
% matrix                     %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that an architecture matrix was provided
if (nargin < 1)
    
    % throw an error
    error("ERROR - CreateFaultTree: the architecture matrix was not provided.");
    
end

% get the size of the architecture matrix
[nrow, ncol] = size(Arch);

% check the that number of rows and columns match
if (nrow ~= ncol)
    
    % throw an error
    error("ERROR - CreateFaultTree: architecture matrix must be square.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the component list   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check that the component list was provided
if (nargin < 2)
    
    % throw an error
    error("ERROR - CreateFaultTree: component list was not provided.");
    
end

% get the number of components
ncomp = length(Components.Name);

% check that there are the same number of components as entries in matrix
if (ncomp ~= nrow)
    
    % throw an error
    error("ERROR - CreateFaultTree: number of compononents must match dimension of architecture matrix.");
    
end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% check the flag             %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if the "remove source" flag was included
if (nargin < 3)
    
    % if it isn't included, assume it should be 0
    RemoveSrc = 0;
    
end


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% count the number of input/output connections
ninput  = sum(Arch, 1)';
noutput = sum(Arch, 2) ;

% find the sources, sinks, and transmitters
isrc = find( ninput == 0                  );
isnk = find(                 noutput == 0 );
itrn = find((ninput ~= 0) & (noutput ~= 0));

% get the number of sources, sinks, and transmitters
nsrc = length(isrc);
nsnk = length(isnk);
ntrn = length(itrn);

% for a fault tree, there can only be one sink
if (nsnk > 1)
    
    % throw an error
    error("ERROR - CreateFaultTree: there are multiple sinks in the architecture matrix.");
    
end

% check if sources must be removed
if (RemoveSrc == 1)
        
    % remove their connections, but keep them in the matrix
    Arch(isrc, :) = 0;
    
    % re-count the number of input/output connections
    ninput  = sum(Arch, 1)';
    noutput = sum(Arch, 2) ;
    
    % re-find the sources, sinks, and transmitters
    isrc = find( ninput == 0                  );
    isnk = find(                 noutput == 0 );
    itrn = find((ninput ~= 0) & (noutput ~= 0));
    
    % re-compute the number of sources, sinks, and transmitters
    nsrc = length(isrc);
    nsnk = length(isnk);
    ntrn = length(itrn);
    
end

% find the connections in the existing architecture
[irow, icol] = find(Arch);


%% COUNT THE INTERNAL/DOWNSTREAM FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the downstream failures
idwn = [itrn; isnk];

% count the downstream failures available
ndwn = ntrn + nsnk;

% check which internal failures are available
iinf = ~strcmpi(Components.FailMode, "") & ninput ~= 0;

% count the number of internal failures available
ninf = sum(iinf);

% count the number of rows/columns to add
nadd = ndwn + ninf;

% add as many entries to the matrix as needed
Arch = [Arch, zeros(nrow, nadd); zeros(nadd, ncol), zeros(nadd)];

% new array dimensions
NewSize = nrow + nadd;

% add entries to the component structure
Components.Name     = [Components.Name    ; repmat("", nadd, 1)];
Components.Type     = [Components.Type    ; repmat("", nadd, 1)];
Components.FailRate = [Components.FailRate; zeros(     nadd, 1)];
Components.FailMode = [Components.FailMode; repmat("", nadd, 1)];


%% ADD THE DOWNSTREAM/INTERNAL FAILURES INTO THE TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% establish internal failure indices (offset by number of components)
IntrFailIdx = nrow + cumsum(iinf);

% establish downstream failure indices (offset by maximum index thus far)
DownFailIdx = max(IntrFailIdx) + cumsum(ninput ~= 0);

% loop through the components
for irow = 1:nrow
    
    % find the components upstream of the current one
    FlowsTo = find(Arch(irow, :));
    
    % update the flows
    Arch(irow, FlowsTo) = 0;
    Arch(irow, DownFailIdx(FlowsTo)) = 1;
    
    % check for a downstream failure
    if (ninput(irow) > 0)
        
        % add the downstream failure
        Arch(DownFailIdx(irow), irow) = 1;
        
        % update the component structure
        Components.Name(    DownFailIdx(irow)) = strcat(Components.Name(irow), " Downstream Failure");
        Components.Type(    DownFailIdx(irow)) =        Components.Type(irow);
        Components.FailMode(DownFailIdx(irow)) =                                "Downstream"         ;
    
        % check for an internal failure
        if (iinf(irow) == 1)
        
            % update the architecture matrix
            Arch(IntrFailIdx(irow), irow) = 1;
            
            % move the component failure to the internal failure
            Components.Name(    IntrFailIdx(irow)) = strcat(Components.Name(    irow), " Internal Failure");
            Components.Type(    IntrFailIdx(irow)) = Components.Type(    irow);
            Components.FailRate(IntrFailIdx(irow)) = Components.FailRate(irow);
            Components.FailMode(IntrFailIdx(irow)) = Components.FailMode(irow);
            
            % modify the component failure
            Components.Name(    irow) = strcat(Components.Name(irow), " Failure");
            Components.FailRate(irow) = 0;
            Components.FailMode(irow) = "Failure";
        
        end
    end
end


%% CREATE THE FAULT TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% count the number of input connections
ninput = sum(Arch, 1)';

% count the number of AND/OR gates
nand =    0;
nor  = nrow;
nnan =    0;

% allocate memory for the gate type and index
Components.GateType = repmat("", NewSize, 1);
Components.GateIdx  = zeros(     NewSize, 1);

% all component gates are now OR gates
Components.GateType(1:nrow) = "OR";
Components.GateIdx( 1:nrow) = 1:nrow;

% loop through the components to get each gate type
for icomp = (nrow+1):NewSize
    
    % check the number of inputs
    if     (ninput(icomp) >  1)
        
        % use an AND gate
        Components.GateType(icomp) = "AND";
        
        % increment the gate count
        nand = nand + 1;
        
        % add a gate index
        Components.GateIdx(icomp) = nand;
        
    elseif (ninput(icomp) == 1)
        
        % use an OR  gate
        Components.GateType(icomp) = "OR";
        
        % increment the gate count
        nor = nor + 1;
        
        % add a gate index
        Components.GateIdx(icomp) = nor;
        
    else
        
        % there are no inputs, so it is a primary event
        Components.GateType(icomp) = "Null";
        
        % increment the gate count
        nnan = nnan + 1;
        
        % add a gate index
        Components.GateIdx(icomp) = nnan;
        
    end
end

% draw the fault tree
SafetyPkg.FaultTree(Arch, Components);

% ----------------------------------------------------------

end