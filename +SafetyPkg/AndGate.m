function [FinalFails] = AndGate(DwnFails, ndwn)
%
% [FinalFails] = AndGate(DwnFails, ndwn)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 aug 2025
%
% enumerate all failures from the downstream inputs, simplifying as pairs
% of failures are enumerated to reduce the problem size.
%
% INPUTS:
%     DwnFails   - the set of downstream failures for each input into the
%                  current component.
%                  size/type/units: 1-by-ndwn / cell / []
%
%     ndwn       - number of downstream components that connect to the
%                  current one.
%                  size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     FinalFails - array of all possible failures after enumeration and
%                  simplification.
%                  size/type/units: m-by-p / integer / []
%

% remove any downstream failures that are empty
for idwn = 1:ndwn
    
    % check for an empty set of failures
    if (isempty(DwnFails{idwn}))
        
        % cannot enumerate, failures are missing
        FinalFails = [];
        
        % exit the code
        return
        
    end
end

% get the first sets of failures
TempFails = {DwnFails{1}, DwnFails{2}};

% loop through and enumerate each failure
for i = 2:ndwn
    
    % make sure both entries are not empty
    if (~isempty(TempFails{1})) && (~isempty(TempFails{2}))
        
        % enumerate the failures
        FinalFails = SafetyPkg.EnumerateFailures(TempFails);
        
        % for the first time, evaluate all columns
        if (i == 2)
            FinalFails = SafetyPkg.IdempotentLaw(FinalFails);
            
        else
            FinalFails = SafetyPkg.IdempotentLaw(FinalFails, ColIdx);
            
        end
        
        % simplify
        FinalFails = SafetyPkg.LawOfAbsorption(FinalFails);
        
    elseif (isempty(TempFails{1}))
        
        % keep only the second set of failures
        FinalFails = TempFails{2};
        
    elseif (isempty(TempFails{2}))
        
        % keep only the first set of failures
        FinalFails = TempFails{1};
        
    end
    
    % check if we're done
    if (i < ndwn)
        
        % add the next failure
        TempFails = {FinalFails, DwnFails{i+1}};
        
        % get the number of columns in the array
        [~, ColIdx] = size(FinalFails);
        
        % start reducing at the following column
        ColIdx = ColIdx + 1;
        
    end
end

% ----------------------------------------------------------

end