function [Leaves] = StructTreeSearch(Trunk)
%
% [Leaves] = StructTreeSearch(Trunk)
% Written by Maxfield Arnson
% Updated 10/19/2023
%
% This function takes a structure and returns all lowest level values
% within the structure, since a structure may have fields within it that are also
% structures. It keeps searching until it finds all non-structure fields
% and returns a cell array containing these values. 
%
% It is only called in order to create excel sheets containing the 
% processed IDEAS database. Its purpose is to aid the InitializeDatabase() 
% function in turning matlab datastructures into rows in an excel sheet containing the same
% information.
% 
% INPUTS:
%
% Trunk = Structure of interest. i.e. a structure that a user would like
%           values extracted from
%       size: 1x1 struct
%
%
% OUTPUTS:
%
% Leaves = Cell array containing the {names,values} of all non-structure
%           fields within the Trunk input
%       size: 2xN cell, where N is the number of non-structure fields
%           stored in the Trunk input

% Initialize "branches" (all subfields within the trunk, including the trunk
% itself) to search within
Branches = {'Plane',Trunk};

% Initialize "leaves" (non-struct fields) to an empty cell
Leaves = cell(0,2);

NumBranches = 2;
Iter = 1;

% Keep searching until the number of searches equals the total number of
% structure subfields within the overall structure. (all branches have been
% investigated)
while NumBranches >= Iter

    CurBranch = Branches{Iter,2};
    BranchName = Branches{Iter,1};
    Iter = Iter+1;

    % Investigate the current branch and find any sub-branches (structures)
    % and leaves (non-struct fields) contained within the current branch
    [NewBranches,NewLeaves] = DatabasePkg.TreeBranch(CurBranch,BranchName);

    % add discovered branches to list of branches that need to be
    % investigates
    Branches = [Branches;NewBranches];
    Leaves = [Leaves;NewLeaves];

    % update number of branches investigated
    NumBranches = length(Branches);

end

% by convention create a horizontal array
Leaves = Leaves';
end