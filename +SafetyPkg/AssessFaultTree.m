function [Pfail] = AssessFaultTree(Arch, Components, RemoveSrc)
%
% AssessFaultTree.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 19 nov 2024
%
% Given an adjacency-like matrix, assemble a fault tree that accounts for
% internal failures and redundant primary events.
%
% INPUTS:
%     Arch       - the architecture matrix representing the system
%                  architecture to be analyzed.
%                  size/type/units: n-by-n / integer / []
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
%                  from the system architecture (1) or not (0). if no
%                  argument is provided, the default is to not remove any
%                  components (0).
%                  size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     Pfail      - the probability that the system fails.
%                  size/type/units: 1-by-1 / double / []
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
    
end


%% PERFORM A BOOLEAN ANALYSIS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% get all failure modes from %
% the system architecture    %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize a string to list all possible failure modes
Failure = "";

% recursively search the system architecture to extract all failure modes
Failure = CreateFailureExp(Arch, Components, isnk, Failure);

% convert the failure modes into a symbolic expression
MyFT = str2sym(Failure);

% expand the fault tree first and then simplify
SimpFT = simplify(expand(MyFT), "Steps", 10 * ncomp);

% convert the simplified fault tree to a string
FailString = string(SimpFT);

% print the failure modes after simplifying
fprintf(1, "Final String: %s\n", FailString);


%% COMPUTE PROBABILITY OF FAILURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% substitute the failure rates for their respective failure mode
WithNums = replace(FailString, [Components.Name; "&"; "|"], [string(Components.FailRate); "*"; "+"]);

% evaluate the string to find the probability of failure
Pfail = double(eval(WithNums));

% ----------------------------------------------------------

end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Failure] = CreateFailureExp(Arch, Components, icomp, Failure)
%
% [Failure] = CreateFailureExp(Arch, Components, icomp, Failure)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 18 nov 2024
%
% Create a symbolic failure expression by recursively searching the fault
% tree. For each function call, check whether an internal failure mode
% exists and if there are any downstream components that need to be
% considered in this failure mode.
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
%                      b) a column vector of failure rates
%                  size/type/units: 1-by-1 / struct / []
%
%     icomp      - the index of the component in the fault tree currently
%                  being assessed.
%                  size/type/units: 1-by-1 / integer / []
%
%     Failure    - a string to be updated with additional failure modes.
%                  size/type/units: 1-by-1 / string / []
%
% OUTPUTS:
%     Failure    - the input string updated with all of the necessary
%                  failure modes after recursively searching the fault
%                  tree.
%                  size/type/units: 1-by-1 / string / []
%


%% CHECK FOR AN INTERNAL FAILURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the downstream components
idwn = find(Arch(:, icomp));

% check if there is an internal failure mode
if (~strcmpi(Components.FailMode(icomp), "") == 1)
    
    % add the component failure
    Failure = Failure + Components.Name(icomp);
    
    % check if there are downstream components
    if (~isempty(idwn) == 1)
        
        % add an OR gate
        Failure = Failure + "|";
        
    end
end


%% CHECK FOR DOWNSTREAM FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of downstream components
ndwn = length(idwn);

% loop through the downstream components
for i = 1:ndwn
    
    % add parenthesis
    if (ndwn > 1)
        Failure = Failure + "(";
    end
    
    % search recursively and add on to the string
    Failure = CreateFailureExp(Arch, Components, idwn(i), Failure);
    
    % add parenthesis
    if (ndwn > 1)
        Failure = Failure + ")";
    end
    
    % add an AND gate, if needed
    if (i < ndwn)
        Failure = Failure + "&";
    end
end


end