function [] = CreateFaultTree(Arch, Components, RemoveSrc)
%
% CreateFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 10 oct 2024
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
    ninput  = sum(Arch, 1)';
            
end

% keep a copy of the original architecture
ArchCopy = Arch      ;
CompCopy = Components;


%% COUNT THE INTERNAL/DOWNSTREAM FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check which internal failures are available
iinf = ~strcmpi(Components.FailMode, "") & ninput ~= 0;

% count the number of internal failures available
ninf = sum(iinf);

% count the downstream failures available
ndwn = sum(ninput > 1);

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
DownFailIdx = max(IntrFailIdx) + cumsum(ninput > 1);

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


%% ACCOUNT FOR DUPLICATE PRIMARY EVENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the component names
CompNames = CompCopy.Name;

% count the number of input/output connections
ninput  = sum(ArchCopy, 1)';
noutput = sum(ArchCopy, 2) ;

% find the duplicate primary events
DuplicEvents = noutput > 1 & ninput == 0;

% loop through the duplicate events
for idup = find(DuplicEvents')
    
    % get the connections from the duplicate
    DupCons = find(ArchCopy(idup, :));
    
    % get the number of connections
    ncon = length(DupCons);
    
    % zero all connections
    ArchCopy(idup, DupCons) = 0;
    
    % memory for the upstream components
    UpComps = zeros(ncon, 1);
    
    % loop through the connections
    for icon = 1:ncon
        
        % get the connection
        jcon = DupCons(icon);
        
        % re-activate the connection one at a time
        ArchCopy(idup, jcon) = 1;
        
        % create a graph
        G = digraph(ArchCopy, CompNames);
        
        % perform a depth-first search to find the upstream component
        DPath = dfsearch(G, idup);
        
        % remember the component
        UpComps(icon) = DPath(end-1);
        
        % deactivate the connection
        ArchCopy(idup, jcon) = 0;
        
    end
    
    % re-activate the connections
    ArchCopy(idup, DupCons) = 1;
        
    % find common component connected to the upstream components discovered
    TopNode = find(sum(ArchCopy(UpComps, :), 1) == ncon);
    
    % remove the connections from the duplicates
    Arch(idup, DupCons) = 0;
    
    % connect to the top-level event
    Arch(idup, TopNode) = 1;
    
end


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