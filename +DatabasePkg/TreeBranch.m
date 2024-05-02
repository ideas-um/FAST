function [BranchesArray,Leaves] = TreeBranch(Trunk,TrunkName)
%
% [BranchesArray,Leaves] = TreeBranch(Trunk,TrunkName)
% Written by Maxfield Arnson
% Updated 10/19/2023
%
% This function takes a structure and a structure name and returns 2 cell
% arrays. A list of all substructures and their names, and a second list of
% all non-structure fields and their names
%
% INPUTS:
%
% Trunk = Structure of interest. i.e. a structure that a user would like
%           subfields extracted from
%       size: 1x1 struct
%
% TrunkName = the name of the structure being investigated. For readability
%           of the outputs
%       size: 1x1 string
%
%
% OUTPUTS:
%
% BranchesArray = Cell array containing the {names,values} of all structure
%           fields within the Trunk input
%       size: Dx2 cell, where D is the number of structure fields
%           stored in the Trunk input
%
% Leaves = Cell array containing the {names,values} of all non-structure
%           fields within the Trunk input. To add an extra piece of
%           information, the names also include the branch that this leaf
%           came from to avoid confusion between, for example, Thrust.SLS
%           and Power.SLS
%       size: Nx2 cell, where N is the number of non-structure fields
%           stored in the Trunk input






% Initialize Leaf iterations
BranchandLeafNames = fieldnames(Trunk);
BranchesStruct = Trunk;
Leaves = cell(0,2);
LeafIndex = 1;

% Iterate through subfields and check if they are 
for ii = 1:length(BranchandLeafNames)
    if ~isstruct(Trunk.(BranchandLeafNames{ii}))
        Leaves{LeafIndex,1} = convertCharsToStrings(TrunkName) +"_" +convertCharsToStrings(BranchandLeafNames{ii});
        Leaves{LeafIndex,2} = Trunk.(BranchandLeafNames{ii});
        LeafIndex = LeafIndex+1;
        BranchesStruct = rmfield(BranchesStruct,BranchandLeafNames{ii});
    end
end
BranchNames = fieldnames(BranchesStruct);

% Check if all values were leaves
if isempty(BranchNames)
    BranchesArray = cell(0,2);
else
    BranchesArray = cell(1,2);
    % Iterate from final length backwards to 1 since you cannot add to
    % cells in each iteration
    for jj = length(BranchNames):-1:1
        BranchesArray{jj,1} = BranchNames{jj};
        BranchesArray{jj,2} = BranchesStruct.(BranchNames{jj});

    end
end
end