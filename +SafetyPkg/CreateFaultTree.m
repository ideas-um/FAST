function [] = CreateFaultTree(Arch, Components, RemoveSrc)
%
% CreateFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 24 sep 2024
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

% % check that there are the same number of components as entries in matrix
% if (ncomp ~= nrow)
%     
%     % throw an error
%     error("ERROR - CreateFaultTree: number of compononents must match dimension of architecture matrix.");
%     
% end

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
ninput  = sum(Arch, 1);
noutput = sum(Arch, 2);

% find the sources and sinks
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
    Arch(isrc, :) = 0;
    
end


%% CREATE THE FAULT TREE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% count the number of AND/OR gates
nand = 0;
nor  = 0;

% allocate memory for the gate type and index
Components.GateType = repmat("", ncomp, 1);
Components.GateIdx  = zeros(     ncomp, 1);

% loop through the components to get each gate type
for icomp = 1:ncomp
    
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
        Components.GateType(icomp) = "";
        
    end
end

% draw the fault tree
SafetyPkg.FaultTree(Arch, Components);

% ----------------------------------------------------------

end