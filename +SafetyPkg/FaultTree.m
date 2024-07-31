function [] = FaultTree()
%
%[] = FaultTree()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 31 jul 2024
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
%     |-----|     |-----|     |-----|
%     | c_1 | --> | c_2 | --> | c_3 |
%     |-----|     |-----|     |-----|
%

% create the "adjacency" matrix
A = [0, 1, 0; ...
     0, 0, 1; ...
     0, 0, 0] ;
 
% A = [0, 1, 0, 0, 0, 0, 0; ...
%      0, 0, 1, 0, 0, 0, 0; ...
%      0, 0, 0, 1, 1, 0, 0; ...
%      0, 0, 0, 0, 0, 1, 0; ...
%      0, 0, 0, 0, 0, 0, 1; ...
%      0, 0, 0, 0, 0, 0, 0; ...
%      0, 0, 0, 0, 0, 0, 0] ;
 

%% PROCESS THE MATRIX %%
%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of nodes
[nnode, ~] = size(A);

% get an index for each node
inode = 1:nnode;

% get the sources/sinks
isrc = find(sum(A, 1) == 0);
isnk = find(sum(A, 2) == 0);

% find the intermediate components
imid = find(~ismember(inode, union(isrc, isnk)));

% ----------------------------------------------------------

end