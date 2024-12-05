function [Pfail] = FindMinimumCutSets(Arch, Components, RemoveSrc)
%
% [Pfail] = FindMinimumCutSets(Arch, Components, RemoveSrc)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 dec 2024
%
% Given an adjacency-like matrix, find the minimum cut sets that account
% for internal failures and redundant primary events. then, using the
% minimum cut sets, compute the system-level failure rate.
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

% recursively search the system architecture to extract all failure modes
FailModes = CreateCutSets(Arch, Components, isnk);

% eliminate duplicate events in single failure mode (idempotent law)
FailModes = IdempotentLaw(FailModes);

% eliminate duplicate events across failure modes (law of absorption)
FailModes = LawOfAbsorption(FailModes);


%% COMPUTE FAILURE RATE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the size of the failure modes
[nrow, ncol] = size(FailModes);

% allocate memory for the failure rates (allocate ones for ease of
% multiplying across rows in a later step)
FailRates = ones(nrow, ncol);

% loop through each component and add in its failure rate
for icomp = 1:ncomp
    
    % find the component in the failure modes
    idx = find(strcmpi(FailModes, Components.Name(icomp)));
    
    % fill in the failure rate
    FailRates(idx) = Components.FailRate(icomp);
    
end

% multiply failure rates in the given row
PfailIndiv = prod(FailRates, 2);

% add all failure rates together for the system-level failure rate
Pfail = sum(PfailIndiv);

% ----------------------------------------------------------

end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Failures] = CreateCutSets(Arch, Components, icomp)
%
% [Failures] = CreateCutSets(Arch, Components, icomp)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 02 dec 2024
%
% List out all components in the cut set for a system architecture. For
% each function call, check whether an internal failure mode exists and if
% there are any downstream components that need to be considered in this
% cut set.
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
% OUTPUTS:
%     Failures   - the matrix updated with all of the necessary failure
%                  modes after recursively searching the system
%                  architecture.
%                  size/type/units: m-by-p / string / []
%


%% CHECK FOR AN INTERNAL FAILURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the downstream components
idwn = find(Arch(:, icomp));

% check if there is an internal failure mode
if (~strcmpi(Components.FailMode(icomp), "") == 1)
    
    % add the component failure
    IntFails = Components.Name(icomp);

else
    
    IntFails = [];

end


%% CHECK FOR DOWNSTREAM FAILURES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of downstream components
ndwn = length(idwn);

% allocate memory
DwnFails = cell(1, ndwn);

% loop through the downstream components
for i = 1:ndwn
        
    % search recursively and remember the downstream failures
    DwnFails{i} = CreateCutSets(Arch, Components, idwn(i));

end

% enumerate the downstream failures, if any exist
if (ndwn > 0)
    
    % get the final set of downstream failures
    FinalFails = EnumerateFailures(DwnFails);
    
    % get the size of the downstream failures
    [~, ncol] = size(FinalFails);
    
    % add columns to the internal failure mode and append downstream fails
    Failures = [IntFails, repmat("", 1, ncol - 1); FinalFails];
    
else
    
    % return only the internal failures
    Failures = IntFails;
    
end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [EnumFails] = EnumerateFailures(FailList)
%
% [EnumFails] = EnumerateFailures(FailList)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 02 dec 2024
%
% Given a set of failures from multiple AND gates, enumerate all possible
% failures that could cause a system failure.
%
% INPUTS:
%     FailList  - an array of possible failures from each part of an AND
%                 gate. all failures from a single part of the AND gate
%                 must be in a column vector.
%                 size/type/units: m-by-n / string / []
%
% OUTPUTS:
%     EnumFails - an array of enumerated failures that could cause the
%                 system to fail.
%                 size/type/units: p-ny-n / string / []
%


%% SETUP FOR ENUMERATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the number of elements in the input array
[~, nelem] = size(FailList);

% remember the number of rows/columns required
nrow = zeros(1, nelem);
ncol = zeros(1, nelem);

% compute the maximum number of elements in a column
for ielem = 1:nelem
    
    % get the size of the string array
    [nrow(ielem), ncol(ielem)] = size(FailList{ielem});
    
end

% get the total number of rows and columns required
mrow = prod(nrow);
mcol =  sum(ncol);

% allocate memory for the output array
EnumFails = repmat("", mrow, mcol);


%% ENUMERATE %%
%%%%%%%%%%%%%%%

% list indices of components
RowIdx = ones(1, nelem);

for irow = 1:mrow
    
    % loop through all elements
    for ielem = 1:nelem
        
        % get the current element
        CurFail = FailList{ielem};
        
        % get the current row
        CurRow = CurFail(RowIdx(ielem), :);
                
        % find the first empty element in the row
        ColIdx = find(strcmpi(EnumFails(irow, :), ""), 1);
        
        % add in the values
        EnumFails(irow, ColIdx:ColIdx+ncol(ielem)-1) = CurRow;
        
    end
    
    % increment the final index
    RowIdx(end) = RowIdx(end) + 1;
    
    % go through all indices backwards
    for ielem = nelem:-1:2
        if (RowIdx(ielem) > nrow(ielem))
            
            % increase the prior row index
            RowIdx(ielem-1) = RowIdx(ielem-1) + 1;
            
            % reset the prior index
            RowIdx(ielem) = 1;
            
        end
    end
end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [NewModes] = IdempotentLaw(FailModes)
%
% [NewModes] = IdempotentLaw(FailModes)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 dec 2024
%
% use the idempotent law to eliminate duplicate events in a single failure
% mode of a fault tree. the idempotent law is a boolean algebra rule,
% stating that: X * X = X
%
% INPUTS:
%     FailModes - matrix of required failures for the system to fail. each
%                 row represents a single failure mode.
%                 size/type/units: m-by-n / string / []
%
% OUTPUTS:
%     NewModes  - updated matrix after the idempotent law is applied. the
%                 number of columns returned may be reduced due to the
%                 simplifications (i.e., p <= n).
%                 size/type/units: m-by-p / string / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the number of failure modes and maximum number of comopnents
[nmode, ncomp] = size(FailModes);


%% BOOLEAN ALGEBRA SIMPLIFICATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% loop through all columns except the last one
for icomp = 1:(ncomp - 1)
        
    % loop through remaining columns
    for jcomp = (icomp+1) : ncomp
            
        % compare the strings
        StrCmp = strcmpi(FailModes(:, icomp), FailModes(:, jcomp));
        
        % eliminate all repeated events
        FailModes(StrCmp, jcomp) = "";
        
    end
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% get the maximum number of components now used
ncomp = max(sum(~strcmpi(FailModes, ""), 2));

% create a new array for returning values
NewModes = repmat("", nmode, ncomp);

% loop through each row
for imode = 1:nmode
    
    % get the remaining components
    CompsLeft = ~strcmpi(FailModes(imode, :), "");
    
    % get the number of components remaining
    ncomp = sum(CompsLeft);
    
    % remember the remaining components
    NewModes(imode, 1:ncomp) = FailModes(imode, CompsLeft);
    
end


end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [NewModes] = LawOfAbsorption(FailModes)
%
% [NewModes] = LawOfAbsorption(FailModes)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 04 dec 2024
%
% use the law of absorbption to eliminate duplicate events across multiple
% failure modes in a fault tree. the law of absorbption is a boolean
% algebra rule stating that:
%     a) X * (X + Y) = X
%     b) X +  X * Y  = X
%
% INPUTS:
%     FailModes - matrix of required failures for the system to fail. each
%                 row represents a single failure mode.
%                 size/type/units: m-by-n / string / []
%
% OUTPUTS:
%     NewModes  - updated matrix after the law of absorbptiion is applied.
%                 the number of rows and columns returned may be reduced
%                 due to the simplifications (i.e., p <= m and q <= n).
%                 size/type/units: p-by-q / string / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% find the maximum number of failure modes and components in a failure
[nfail, ncomp] = size(FailModes);


%% BOOLEAN ALGEBRA SIMPLIFICATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of components in a failure mode
icomp = 0;

% use failure modes with icomp components to simplify more complex events
while (icomp <= ncomp)
    
    % increment the number of components in the failure mode
    icomp = icomp + 1;
    
    % get the index of the failure modes with icomp components
    Baseline = find(sum(~strcmpi(FailModes, ""), 2) == icomp);
    
    % get the number of failure modes in the baseline
    nmode = length(Baseline);
    
    % check if any exist
    if (nmode == 0)
        
        % continue on
        continue
        
    end
    
    % loop through all the failure modes
    for imode = 1:nmode
        
        % get the failure
        CurMode = FailModes(Baseline(imode), 1:icomp);
                
        % index for the failure modes
        ifail = 0;
        
        % loop through all of the failure modes
        while (ifail < nfail)
    
            % increment the failure mode
            ifail = ifail + 1;
            
            % check if failure mode is used for comparison
            if (ifail == Baseline(imode))
                
                % continue on
                continue;
                
            end
            
            % look for common components
            CheckCommon = matches(FailModes(ifail, :), CurMode);
            
            % check if the current failure is within other failures
            if (sum(CheckCommon) == icomp)
                
                % a failure mode is shared - eliminate the current one
                FailModes(ifail, :) = "";
                
            end                
        end
    end
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% check if any of the rows are empty
KeepRow = any(~strcmpi(FailModes, ""), 2);

% check if any of the cols are empty
KeepCol = any(~strcmpi(FailModes, ""), 1);

% use only the columns with failure modes in them
NewModes = FailModes(KeepRow, KeepCol);


end