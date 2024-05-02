function [Split] = EvalSplit(SplitFun, SplitVal)
%
% [Split] = EvalSplit(SplitFun, SplitVal)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 08 mar 2024
%
% Given a energy/power/thrust split (SplitFun), evaluate it for a given
% value (SplitVal). This function currently works for up to 4 splits
% in a single matrix.
%
% INPUTS:
%     SplitFun - function handle to evaluate the energy/power/thrust split.
%                size/type/units: 1-by-1 / function handle / []
%
%     SplitVal - value(s) to use in the energy/power/thrust split
%                evaluation.
%                size/type/units: 1-by-n / double / []
%
% OUTPUTS:
%     Split    - the power split after it has been evaluated.
%                size/type/units: m-by-p / double / []
%

% ----------------------------------------------------------

% get the number of arguments in the split
narg = nargin(SplitFun);

% call the function with an appropriate number of inputs
if     (narg < 1)
    
    % evaluate with 0 arguments
    Split = SplitFun();
    
elseif (narg < 2)
    
    % evaluate with 1 arguments
    Split = SplitFun(SplitVal(1));
    
elseif (narg < 3)
    
    % evaluate with 2 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2));
    
elseif (narg < 4)
    
    % evaluate with 3 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3));
    
elseif (narg < 5)
    
    % evaluate with 4 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3), SplitVal(4));
    
else
    
    % throw error
    error("ERROR - EvalSplit: only up to 4 distinct split are currently accepted.");
    
end

% ----------------------------------------------------------

end