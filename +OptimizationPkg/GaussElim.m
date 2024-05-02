function [A] = GaussElim(A, prow, pcol)
%
% [A] = GaussElim(A, prow, pcol)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 mar 2024
%
% Perform one step of gaussian elimination (i.e., eliminate a single
% column).
%
% INPUTS:
%     A    - matrix before gaussian elimination.
%            size/type/units: n-by-n / double / []
%
%     prow - pivot's row index.
%            size/type/units: 1-by-1 / int / []
%
%     pcol - pivot's column index.
%            size/type/units: 1-by-1 / int / []
%
% OUTPUTS:
%     A    - updated matrix.
%            size/type/units: n-by-n / double / []
%


%% PRE-PROCESSING %%
%%%%%%%%%%%%%%%%%%%%

% get the number of rows in the matrix
nrow = size(A);


%% PERFORM GAUSSIAN ELIMINATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the pivot
pivot = A(prow, pcol);

% update the pivot row
A(prow, :) = A(prow, :) ./ pivot;

% eliminate the other rows
for irow = 1:nrow
    
    % skip the pivot row
    if (irow == prow)
        continue
    end
    
    % eliminate the row
    A(irow, :) = A(irow, :) - A(irow, pcol) .* A(prow, :);
    
end

% ----------------------------------------------------------

end