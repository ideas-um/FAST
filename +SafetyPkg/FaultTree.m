function [] = FaultTree(Arch, Components)
%
% [] = FaultTree(Arch, Components))
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 30 sep 2024
%
% Create a fault tree from the adjacency matrix of a directed graph with
% the names of the given components.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%


%% PROCESS THE MATRIX %%
%%%%%%%%%%%%%%%%%%%%%%%%

% since we move from power sink to energy source, switch the direction
Arch = Arch';

% get the number of nodes
[nnode, ~] = size(Arch);

% get the sources
isrc = find(sum(Arch, 1) == 0);


%% PLOT THE FAULT TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% generate node labels (sink shows thrust generated, so label separately)
NodeLabels = strcat("Loss of ", Components.Name);

% create the graph
G0 = digraph(Arch, NodeLabels);


%% ADD THE LOGIC GATES %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% get all possible paths
BPath = bfsearch(G0, isrc, "allevents");

% get the number of edges
nedge = height(G0.Edges);

% make a larger matrix to include the logical gates
B = [Arch, zeros(nnode, nedge); zeros(nedge, nnode), zeros(nedge)];

% allocate memory to remember the nodes corresponding to each edge
ColIdx = zeros(nnode, 1);

% remember the column index for new logic gates
idx = nnode;

% loop through the paths searched
for istep = 1:height(BPath)
    
    % get the event
    CurEvent = BPath.Event(istep);
    
    if      (CurEvent == "discovernode"    )
        
        % increment the index
        idx = idx + 1;
        
        % remember the index
        ColIdx(BPath.Node(istep)) = idx;
        
    elseif ((CurEvent == "edgetonew"       ) || ...
            (CurEvent == "edgetodiscovered"))
        
        % get the beginning and ending nodes
        BegNode = BPath.Edge(istep, 1);
        EndNode = BPath.Edge(istep, 2);
        
        % get the index of the beginning node
        icol = ColIdx(BegNode);
        
        % remove the existing path
        B(BegNode, EndNode) = 0;
        
        % add in a stop at the logic gate
        B(BegNode, icol   ) = 1;
        B(icol   , EndNode) = 1;
                
    end        
end

% offset the gate column indexes to access the nodes
ColIdx = ColIdx - nnode;

% remember for the gates' names
GateLabels = strcat(Components.GateType(ColIdx), num2str(Components.GateIdx(ColIdx)));

% create new node labels
NodeLabels = [NodeLabels; GateLabels];

% find vertices that are islands
Island = find((sum(B, 1)' == 0) & (sum(B, 2) == 0));

% remove the islands' rows/columns from the adjacency matrix
B(Island, :) = [];
B(:, Island) = [];

% remove the islands' node labels
NodeLabels(Island) = [];


%% RE-ARRANGE THE DATA TO LOOK LIKE A TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a new digraph
G1 = digraph(B, NodeLabels);

% plot the new graph
figure;
T1 = plot(G1);

% turn off the edges
T1.ArrowSize = 0;

% get the number of nodes in the new graph
[nnode, ~] = size(B);

% get the sources
isrc = find(sum(B, 1) == 0);

% find the maximum level that the fault can occur
MaxLevel = zeros(nnode, 1);

% get all possible paths
DPath = dfsearch(G1, isrc, "allevents");

% get the first level
ylevel = 1;

% loop through the path elements
for istep = 1:height(DPath)
    
    % get the event
    CurEvent = DPath.Event(istep);
    
    % take the appropriate course of action during the search
    if     (CurEvent == "discovernode")
        
        % if a vertex was discovered, add a layer
        ylevel = ylevel + 1;
        
    elseif (CurEvent == "finishnode"  )
        
        % if a vertex has no edges, retreat a layer
        ylevel = ylevel - 1;
                
    else
        
        % no action needed
        continue;
        
    end
    
    % get the node
    inode = DPath.Node(istep);
    
    % check which layer it should be placed on
    MaxLevel(inode) = max(MaxLevel(inode), ylevel);
    
end

% find the total number of levels
nlevel = max(MaxLevel);

% re-arrange the elements in the tree
for ilevel = 1:nlevel
    
    % remember the nodes on this level
    lnode = MaxLevel == ilevel;
    
    % spread out x-variables
    T1.XData(lnode) = 1:sum(lnode);
    
    % set the y-variable
    T1.YData(lnode) = nlevel - ilevel;
    
end

% ----------------------------------------------------------

end