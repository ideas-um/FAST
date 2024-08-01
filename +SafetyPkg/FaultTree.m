function [] = FaultTree()
%
%[] = FaultTree()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 01 aug 2024
%
% Create a fault tree from the adjacency matrix of a directed graph.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

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
 
% slightly more complex case 
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
G = digraph(A, NodeLabels);

% plot the tree
Tree = plot(G);

% turn off edges
Tree.ArrowSize = 0;


%% RE-ARRANGE THE DATA TO LOOK LIKE A TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find the maximum level that the fault can occur
MaxLevel = zeros(nnode, 1);

% loop through all possible paths
for ipath = 1:length(isrc)
    
    % get the path
    Path = dfsearch(G, isrc(ipath), "allevents");
    
    % get the first level
    ylevel = 0;
    
    % loop through the path elements
    for istep = 1:height(Path)
        
        % get the event
        CurEvent = Path.Event(istep);
        
        % if a node was discovered, add a layer
        if (CurEvent == "discovernode")
            ylevel = ylevel + 1;
            
        elseif (CurEvent == "finishnode")
            ylevel = ylevel - 1;
            
        else
            continue;
            
        end
        
        % get the node
        inode = Path.Node(istep);
        
        % check which layer it should be placed on
        MaxLevel(inode) = max(MaxLevel(inode), ylevel);
        
    end
end

% find the total number of levels
nlevel = max(MaxLevel) + 1;

% re-arrange the elements in the tree
for ilevel = 1:nlevel
    
    % remember the nodes on this level
    lnode = MaxLevel == ilevel;
    
    % spread out x-variables
    Tree.XData(lnode) = 1:sum(lnode);
    
    % set the y-variable
    Tree.YData(lnode) = nlevel - ilevel;
    
end

% ----------------------------------------------------------

end