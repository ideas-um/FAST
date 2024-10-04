function [] = DrawFaultTree(Arch, Components)
%
% [] = DrawFaultTree(Arch, Components)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 oct 2024
%
% Draw a fault tree from the adjacency matrix of a directed graph with
% the names of the given components.
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
%                      e) a column vector of the logic gates corresponding
%                         to each node/failure
%                      f) a column vector of indices to be appended to the
%                         logic gates (because matlab requires unique node
%                         labels)
%                  size/type/units: 1-by-1 / struct / []
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
NodeLabels = Components.Name;

% create the graph
G0 = digraph(Arch, NodeLabels);


%% ADD THE LOGIC GATES %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% get all possible paths
BPath = bfsearch(G0, isrc, "allevents");

% make a larger matrix to include the logical gates
B = [Arch, zeros(nnode, nnode); zeros(nnode, 2*nnode)];

% loop through the paths searched
for istep = 1:height(BPath)
    
    % get the event
    CurEvent = BPath.Event(istep);
    
    if ((CurEvent == "edgetonew"       ) || ...
        (CurEvent == "edgetodiscovered"))
        
        % get the beginning and ending nodes
        BegNode = BPath.Edge(istep, 1);
        EndNode = BPath.Edge(istep, 2);
        
        % offset index by number of components in the system
        icol = BegNode + nnode;
        
        % remove the existing path
        B(BegNode, EndNode) = 0;
        
        % add in a stop at the logic gate
        B(BegNode, icol   ) = 1;
        B(icol   , EndNode) = 1;
                
    end        
end

% remember for the gates' names
GateLabels = strcat(Components.GateType, num2str(Components.GateIdx));

% create new node labels
NodeLabels = [NodeLabels; GateLabels];

% find vertices that are islands
Island = find((sum(B, 1)' == 0) & (sum(B, 2) == 0));

% remove the islands' rows/columns from the adjacency matrix
B(Island, :) = [];
B(:, Island) = [];

% remove the islands' node labels
NodeLabels(Island) = [];


%% RE-MAKE THE FAULT TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a new digraph
G1 = digraph(B, NodeLabels);

% create a figure
figure;

% plot the new graph
T1 = plot(G1);

% format the plot
T1.ArrowSize = 0;
T1.NodeFontSize = 12;
T1.MarkerSize = 6;
T1.LineWidth = 2;

% ----------------------------------------------------------

end