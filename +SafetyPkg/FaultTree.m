function [] = FaultTree()
%
%[] = FaultTree()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 02 aug 2024
%
% Create a fault tree from the adjacency matrix of a directed graph.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

% cleanup before running
close all

%% TEST CASE %%
%%%%%%%%%%%%%%%

% example:
%
%     |-----|     |-----|     |-----|     |-----|
%     | c_1 | --> | c_2 | --> | c_3 | --> | out |
%     |-----|     |-----|     |-----|     |-----|
%

% create the "adjacency" matrix
% A = [0, 1, 0, 0; ...
%      0, 0, 1, 0; ...
%      0, 0, 0, 1; ...
%      0, 0, 0, 0] ;

% more complex case, parallel architecture
A = [0, 1, 0, 0, 0, 0, 0, 0; ...
     0, 0, 1, 0, 0, 0, 0, 0; ...
     0, 0, 0, 1, 1, 0, 0, 0; ...
     0, 0, 0, 0, 0, 1, 0, 0; ...
     0, 0, 0, 0, 0, 0, 1, 0; ...
     0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 1; ...
     0, 0, 0, 0, 0, 0, 0, 0] ;
 
% slightly more complex case, multiple energy sources
% A = [0, 0, 1, 0, 0; ...
%      0, 0, 1, 0, 0; ...
%      0, 0, 0, 1, 0; ...
%      0, 0, 0, 0, 1; ...
%      0, 0, 0, 0, 0] ;


%% PROCESS THE MATRIX %%
%%%%%%%%%%%%%%%%%%%%%%%%

% since we move from TS to ES, switch the direction
A = A';

% get the number of nodes
[nnode, ~] = size(A);

% get the sources
isrc = find(sum(A, 1) == 0);


%% PLOT THE FAULT TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% generate node labels (sink shows thrust generated, so label separately)
NodeLabels = [strcat("Element " + num2str((1:nnode-1)') + " Fail"); ...
              "Loss of Thrust"];

% create the graph
G0 = digraph(A, NodeLabels);

% % plot the tree
% figure;
% T0 = plot(G0);
% 
% % turn off edges
% T0.ArrowSize = 0;


%% ADD THE LOGIC GATES %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% get all possible paths
BPath = bfsearch(G0, isrc, "allevents");

% get the number of edges
nedge = height(G0.Edges);

% make a larger matrix to include the logical gates
B = [A, zeros(nnode, nedge); zeros(nedge, nnode), zeros(nedge)];

% remember the column index for new logic gates
idx = nnode + 1;

% loop through the paths searched
for istep = 1:height(BPath)
    
    % get the event
    CurEvent = BPath.Event(istep);
    
    if      (CurEvent == "finishnode"      )
        
        % increment the index
        idx = idx + 1;
        
    elseif ((CurEvent == "edgetonew"       ) || ...
            (CurEvent == "edgetodiscovered"))
        
        % remove the existing path
        B(BPath.Edge(istep, 1), BPath.Edge(istep, 2)) = 0;
        
        % add in a stop at the logic gate
        B(BPath.Edge(istep, 1), idx                ) = 1;
        B(idx                , BPath.Edge(istep, 2)) = 1;
        
    end        
end

% memory for the gates' names
GateLabels = repmat("", nedge, 1);

% check how many connections leave the nodes
OutOrder = sum(B(nnode+1:end, :), 2);

% get the number of OR and AND gates
nor  = OutOrder == 1;
nand = OutOrder >  1;

% update the gate labels
GateLabels(nor ) = strcat("OR" , num2str((1:sum(nor ))'));
GateLabels(nand) = strcat("AND", num2str((1:sum(nand))'));

% create new node labels
NodeLabels = [NodeLabels; GateLabels];

% find vertices that are islands
Island = find((sum(B, 1)' == 0) & (sum(B, 2) == 0));

% remove the islands' rows/columns from the adjacency matrix
B(Island, :) = [];
B(:, Island) = [];

% remove the islands' node labels
NodeLabels(Island) = [];

% create a new digraph
G1 = digraph(B, NodeLabels);

% plot the new graph
figure;
T1 = plot(G1);

% turn off the edges
T1.ArrowSize = 0;


%% RE-ARRANGE THE DATA TO LOOK LIKE A TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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