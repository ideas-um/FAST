function [Split] = EvalSplit(SplitFun, SplitVal)
%
% [Split] = EvalSplit(SplitFun, SplitVal)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 05 mar 2026
%
% Given a energy/power/thrust split (SplitFun), evaluate it for a given
% value (SplitVal). This function currently works for a varying number of
% power splits in a single function evaluation. Any user may follow the
% same pattern to edit this script for their use and incorporate a new
% number of power splits into the code.
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
    
elseif (narg < 6)
    
    % evaluate with 5 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3), SplitVal(4), SplitVal(5));
    
elseif (narg < 7)
    
    % evaluate with 6 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3), SplitVal(4), SplitVal(5), SplitVal(6));
    
elseif (narg < 8)
    
    % evaluate with 7 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3), SplitVal(4), SplitVal(5), SplitVal(6), SplitVal(7));
    
elseif (narg < 9)
    
    % evaluate with 8 arguments
    Split = SplitFun(SplitVal(1), SplitVal(2), SplitVal(3), SplitVal(4), SplitVal(5), SplitVal(6), SplitVal(7), SplitVal(8));
    
elseif (narg < 17)
    
    % evaluate with 16 arguments
    Split = SplitFun(SplitVal( 1), SplitVal( 2), SplitVal( 3), SplitVal( 4), ...
                     SplitVal( 5), SplitVal( 6), SplitVal( 7), SplitVal( 8), ...
                     SplitVal( 9), SplitVal(10), SplitVal(11), SplitVal(12), ...
                     SplitVal(13), SplitVal(14), SplitVal(15), SplitVal(16)) ;
                 
elseif (narg < 18)
    
    % evaluate with 17 arguments
    Split = SplitFun(SplitVal( 1), SplitVal( 2), SplitVal( 3), SplitVal( 4), ...
                     SplitVal( 5), SplitVal( 6), SplitVal( 7), SplitVal( 8), ...
                     SplitVal( 9), SplitVal(10), SplitVal(11), SplitVal(12), ...
                     SplitVal(13), SplitVal(14), SplitVal(15), SplitVal(16), ...
                     SplitVal(17)                                          ) ;
    
else
    
    % throw error
    error("ERROR - EvalSplit: function evaluation currently unavailable for the desired quantity of power splits.");
    
end

% ----------------------------------------------------------

end