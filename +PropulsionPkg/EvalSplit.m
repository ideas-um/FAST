function [Split] = EvalSplit(SplitFun, SplitVal)
%
% [Split] = EvalSplit(SplitFun, SplitVal)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 sep 2026
%
% Given a energy/power/thrust split (SplitFun), evaluate it for a given
% value (SplitVal). This function currently works for a varying number of
% power splits in a single function evaluation. Any user may follow the
% same pattern to edit this script for their use and incorporate a new
% number of power splits into the code.
%
% INPUTS:
%     SplitFun - function handle to evaluate, or a fixed numeric power
%                split matrix. Numeric matrices are returned unchanged.
%                size/type/units: 1-by-1 or p-by-q / function handle or double / []
%
%     SplitVal - power split values.
%                size/type/units: m-by-n / double / []
%
% OUTPUTS:
%     Split    - the power split after it has been evaluated.
%                size/type/units: p-by-q / double / []
%

% ----------------------------------------------------------

% A numeric operational matrix is already fully resolved. This permits a
% custom architecture to prescribe one direct matrix per mission segment
% without inventing unused lambda inputs.
if (isnumeric(SplitFun))
    Split = SplitFun;
    return
end

% get the number of arguments in the split
narg = length(SplitVal);

% create a cell array for storing arguments
Vals = cell(1, narg);

% loop through all values
for i = 1:narg
    Vals{i} = SplitVal(i);
end

% evaluate the function
if (narg > 0)
    Split = SplitFun(Vals{:});
    
else
    Split = SplitFun();
    
end

% ----------------------------------------------------------

end
