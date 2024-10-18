function [] = CreateFaultTree(Arch, Components, RemoveSrc)
%
% CreateFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 18 oct 2024
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
isrc = find(ninput  == 0);
isnk = find(noutput == 0);

% get the number of sinks
nsnk = length(isnk);

% for a fault tree, there can only be one sink
if (nsnk > 1)
    
    % throw an error
    error("ERROR - CreateFaultTree: there are multiple sinks in the architecture matrix.");
    
end

% check if sources must be removed
if (RemoveSrc == 1)
        
    % remove their connections, but keep them in the matrix
    Arch(isrc, :) = 0; %#ok<*FNDSB>
    
    % re-count the number of input/output connections
    ninput = sum(Arch, 1)';
    
end

% get the number of sources
nsrc = length(isrc);

% allocate memory for all of the path lengths
PathLength = zeros(nsrc, 1);

% create a directed graph of the architecture
DG = digraph(Arch);

% loop through all paths to find the longest one
for ipath = 1:nsrc
    [~, PathLength(ipath)] = shortestpath(DG, isrc(ipath), isnk);
end

% get the longest path for the maximum number of redundant primary events
nred = max(PathLength);


%% COUNT THE INTERNAL/DOWNSTREAM/PRIMARY FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check which internal failures are available
iinf = ~strcmpi(Components.FailMode, "") & ninput ~= 0;

% add internal/downstream failures for all components and redundant fails
nadd = 2 * ncomp + nred; %ndwn + ninf + nred;

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

% indices for internal failure modes (offset by number of components)
IntrFailIdx = nrow + (1:ncomp)';%cumsum(iinf);

% indices for downstream failures (offset by maximum index thus far)
DownFailIdx = max(IntrFailIdx) + (1:ncomp)';%cumsum(ninput > 1);

% indices for redundant primary events (offset by maximum index thus far)
RednFailIdx = max(DownFailIdx) + (1:nred)';

% loop through the components
for irow = 1:nrow
    
    % find the components that this one flows to
    FlowsTo = find(Arch(irow, :));
    
    % check if these components have multiple inputs
    MultiIn = find(ninput(FlowsTo) >  1);
    
    % if any of them do ...
    if any(MultiIn)
        
        % connect to a downstream failure instead of the component failure
        Arch(irow,             FlowsTo(MultiIn) ) = 0;
        Arch(irow, DownFailIdx(FlowsTo(MultiIn))) = 1;
        
    end
    
    % check if there are multiple inputs to the current component
    if (ninput(irow) > 1)
        
        % add the downstream failure
        Arch(DownFailIdx(irow), irow) = 1;
        
        % update the component structure
        Components.Name(    DownFailIdx(irow)) = strcat(Components.Name(irow), " Downstream Failure");
        Components.Type(    DownFailIdx(irow)) =        Components.Type(irow);
        Components.FailMode(DownFailIdx(irow)) =                                "Downstream"         ;
                
    end
                                   
    % check for an internal failure
    if (iinf(irow) == 1)
        
        % update the architecture matrix
        Arch(IntrFailIdx(irow), irow) = 1;
        
        % move the component failure to the internal failure
        Components.Name(    IntrFailIdx(irow)) = strcat(Components.Name(    irow), " Internal Failure");
        Components.Type(    IntrFailIdx(irow)) = Components.Type(    irow);
        Components.FailRate(IntrFailIdx(irow)) = Components.FailRate(irow);
        Components.FailMode(IntrFailIdx(irow)) = Components.FailMode(irow);
        
        % delete the failure rate of the this component (moved above)
        Components.FailRate(irow) = 0;
       
    end
    
    % convert the name of the component to represent a failure
    Components.Name(    irow) = strcat(Components.Name(irow), " Failure");
    Components.FailMode(irow) = "Failure";
    
end

% assume all redundant primary event spaces will be used
Components.Name(    RednFailIdx) = strcat("Primary Event Fail", num2str((1:nred)'));
Components.FailRate(RednFailIdx) = 0;
Components.FailMode(RednFailIdx) = strcat("Primary Event Fail", num2str((1:nred)'));


%% ACCOUNT FOR REDUNDANT PRIMARY EVENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% index for the redundant failure mode
ired = 1;

% loop through until there's no more redundant events
while (1)
        
    % count the number of input/output connections
    ninput  = sum(Arch, 1)';
    noutput = sum(Arch, 2) ;
    
    % find the duplicate primary events
    DuplicEvents = noutput > 1 & ninput == 0;

    % check if there are any duplicate events
    if (~any(DuplicEvents))
        
        % if there are none, break out of the loop
        break;
        
    end
    
    % find the duplicate events
    idup = find(DuplicEvents');
    
    % get the output flows
    [OutFlowRow, OutFlowCol] = find(Arch(idup, :));
    
    % remove the connections from the duplicates
    Arch(OutFlowRow, OutFlowCol) = 0;
    
    % connect to the primary redundant failure
    Arch(idup, RednFailIdx(ired)) = 1;
    
    % connect the primary redundant failure to the sink
    Arch(RednFailIdx(ired), isnk) = 1;
    
end


%% CHECK IF DOWNSTREAM FAILURES STILL EXIST %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the column sum of the downstream failures
ColSum = sum(Arch(:, DownFailIdx), 1)';

% check which ones have no flow into it (sum of 0)
RemoveDownFail = find(ColSum == 0);

% remove any downstream failure connections
Arch(DownFailIdx(RemoveDownFail), :) = 0;


%% ELIMINATE EXCESS CONNECTIONS FROM SIMPLIFICATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% count the number of input/output connections
ninput  = sum(Arch, 1)';
noutput = sum(Arch, 2) ;

% find the excess nodes with one input/output
Extras = find(ninput == 1 & noutput == 1)';

% loop through each extra
for iextra = Extras
    
    % get the row where the flow starts
    irow = find(Arch(:, iextra));
    
    % get the column where the flow ends
    icol = find(Arch(iextra, :));
    
    % remove the flows
    Arch(irow, iextra) = 0;
    Arch(iextra, icol) = 0;
    
    % connect the flow directly from beginning to end
    Arch(irow, icol) = 1;
    
end

% find vertices that are islands
Island = find((sum(Arch, 1)' == 0) & (sum(Arch, 2) == 0));

% remove the islands' rows/columns from the adjacency matrix
Arch(Island, :) = [];
Arch(:, Island) = [];

% remove the islands' node labels
Components.Name(    Island) = [];
Components.Type(    Island) = [];
Components.FailRate(Island) = [];
Components.FailMode(Island) = [];

% update the matrix size (removed islands)
NewSize = NewSize - length(Island);


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
SafetyPkg.DrawFaultTree(Arch, Components);

% ----------------------------------------------------------

end