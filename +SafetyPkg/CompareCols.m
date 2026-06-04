function [Col2] = CompareCols(Col1, Col2)
%
% [Col2] = CompareCols(Col1, Col2)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 28 aug 2025
%
% for the elements in Col2 that match those in Col1, set them to be an
% zero. this is a helper function for performing a vectorized fault tree
% analysis.
%
% INPUTS:
%     Col1 - first  column to be compared.
%            size/type/units: n-by-1 / integer / []
%
%     Col2 - second column to be compared.
%            size/type/units: n-by-1 / integer / []
%
% OUTPUTS:
%     Col2 - updated column with zeros in the elements that matched.
%            size/type/units: n-by-1 / integer / []
%

% compare the two columns
StrCmp = Col1 == Col2;

% remove the ones that match
Col2(StrCmp) = 0;

% ----------------------------------------------------------

end