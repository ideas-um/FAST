function [] = AssessFaultTree(Arch, Components, RemoveSrc)
%
% AssessFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 nov 2024
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


%% PERFORM A BOOLEAN ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assemble the string
Failure = "";

% recursively search the graph
Failure = CreateFailureExp(Arch, Components, isnk, Failure);

split(Failure, ["(", ")", "+"])

% ----------------------------------------------------------

end

function [Failure] = CreateFailureExp(Arch, Components, icomp, Failure)
%
% [Failure] = CreateFailureExp(Arch, Components, icomp, Failure)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 nov 2024
%
% description.
%
% INPUTS:
%
% OUTPUTS:
%

% get the downstream components
idwn = find(Arch(:, icomp));

% check if there is an internal failure mode
if (~strcmpi(Components.FailMode(icomp), "") == 1)
    
    % add the component failure
    Failure = Failure + Components.Name(icomp);
    
    % check if there are downstream components
    if (~isempty(idwn) == 1)
        
        % add a plus
        Failure = Failure + "+";
        
    end
end


% get the number of downstream components
ndwn = length(idwn);

% loop through the downstream components
for i = 1:ndwn
    
    % add parenthesis
    if (ndwn > 1)
        Failure = Failure + "(";
    end
    
    % search recursively
    Failure = CreateFailureExp(Arch, Components, idwn(i), Failure);
    
    % add parenthesis
    if (ndwn > 1)
        Failure = Failure + ")";
    end
    
    % multiply, if needed
    if (i < ndwn)
        Failure = Failure + "*";
    end
end


end