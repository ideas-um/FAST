function [NewModes] = IdempotentLaw(FailModes, SplitCol)
%
% [NewModes] = IdempotentLaw(FailModes)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 apr 2025
%
% use the idempotent law to eliminate duplicate events in a single failure
% mode of a fault tree. the idempotent law is a boolean algebra rule,
% stating that: X * X = X
%
% INPUTS:
%     FailModes - matrix of required failures for the system to fail. each
%                 row represents a single failure mode.
%                 size/type/units: m-by-n / integer / []
%
% OUTPUTS:
%     NewModes  - updated matrix after the idempotent law is applied. the
%                 number of columns returned may be reduced due to the
%                 simplifications (i.e., p <= n).
%                 size/type/units: m-by-p / integer / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the number of failure modes and maximum number of comopnents
[nmode, ncomp] = size(FailModes);

% check if two arguments are given
if (nargin < 2)
    SplitCol = 0;
end


%% BOOLEAN ALGEBRA SIMPLIFICATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check if there is a column to split at
if (SplitCol > 0)
    OutIdx =  1 : SplitCol - 1        ;
    InrIdx = @(x) SplitCol     : ncomp;
    
else
    OutIdx =          1 : ncomp - 1;
    InrIdx = @(x) x + 1 : ncomp    ;
    
end

% loop through all columns except the last one
for icomp = OutIdx
    
    % remember the current column
    TempCol = FailModes(:, icomp);
    
    % loop through remaining columns
    for jcomp = InrIdx(icomp)
        
        % compare elements in the columns
        FailModes(:, jcomp) = SafetyPkg.CompareCols(TempCol, FailModes(:, jcomp));
        
    end
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% get the maximum number of components now used
ncomp = max(sum(FailModes > 0, 2));

% create a new array for returning values
NewModes = zeros(nmode, ncomp);

% loop through each row
for imode = 1:nmode
    
    % get the remaining components
    CompsLeft = FailModes(imode, :) > 0;
    
    % get the number of components remaining
    ncomp = sum(CompsLeft);
    
    % remember the remaining components
    NewModes(imode, 1:ncomp) = FailModes(imode, CompsLeft);
    
end

% ----------------------------------------------------------

end