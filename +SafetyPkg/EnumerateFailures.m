function [EnumFails] = EnumerateFailures(FailList)
%
% [EnumFails] = EnumerateFailures(FailList)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 aug 2025
%
% Given a set of failures from multiple AND gates, enumerate all possible
% failures that could cause a system failure.
%
% INPUTS:
%     FailList  - an array of possible failures from each part of an AND
%                 gate. all failures from a single part of the AND gate
%                 must be in a column vector.
%                 size/type/units: m-by-n / integer / []
%
% OUTPUTS:
%     EnumFails - an array of enumerated failures that could cause the
%                 system to fail.
%                 size/type/units: p-ny-n / integer / []
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
EnumFails = zeros(mrow, mcol);


%% ENUMERATE %%
%%%%%%%%%%%%%%%

% keep track of the column index
ColIdx = 0;

% loop through each set of components
for ielem = 1:nelem
    
    % get the current failure
    CurFail = FailList{ielem};
    
    % number of times the matrix must repeat
    nrep1 = prod(nrow(ielem+1:end));
    
    % number of times the repeated matrix repeats
    nrep2 = prod(nrow(1:ielem-1));
    
    % loop through all columns
    for icol = 1:ncol(ielem)
        
        % repeatedly represent the matrix elements
        TempCol = repelem(CurFail(:, icol), nrep1);
        
        % repeatedly represent the column
        EnumFails(:, ColIdx + icol) = repmat(TempCol, nrep2, 1);
        
    end
    
    % update the column index
    ColIdx = ColIdx + ncol(ielem);
    
end

% ----------------------------------------------------------

end