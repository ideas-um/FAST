function [NewModes] = LawOfAbsorption(FailModes)
%
% [NewModes] = LawOfAbsorption(FailModes)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 aug 2025
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
%                 size/type/units: m-by-n / integer / []
%
% OUTPUTS:
%     NewModes  - updated matrix after the law of absorbptiion is applied.
%                 the number of rows and columns returned may be reduced
%                 due to the simplifications (i.e., p <= m and q <= n).
%                 size/type/units: p-by-q / integer / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% find the maximum number of failure modes and components in a failure
[~, ncomp] = size(FailModes);


%% BOOLEAN ALGEBRA SIMPLIFICATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% use failure modes with icomp components to simplify more complex events
for icomp = 1:ncomp
    
    % compute the sum of the rows ahead of time
    RowSum = sum(FailModes > 0, 2);
    
    % get the index of the failure modes with icomp components
    Baseline = find(RowSum == icomp);
    
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
        
        % check if the current mode has any failure modes left
        if (sum(CurMode == 0, 2) == icomp)
            continue;
        end
        
        % look for common components
        CheckCommon = sum(ismember(FailModes, CurMode), 2);
        
        % check for indices
        idx = CheckCommon == icomp;
        
        % get the current failure index
        CurIdx = Baseline(imode);
        
        % ignore the present index
        idx(CurIdx) = 0;
        
        % a failure mode is shared - eliminate the current one
        FailModes(idx, :) = 0;
        
    end
end


%% POST-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%%

% check if any of the rows are empty
KeepRow = any(FailModes > 0, 2);

% check if any of the cols are empty
KeepCol = any(FailModes > 0, 1);

% use only the columns with failure modes in them
NewModes = FailModes(KeepRow, KeepCol);

% ----------------------------------------------------------

end