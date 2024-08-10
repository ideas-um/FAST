function [Success] = TestSplitPower()
%battery resize
% [Success] = TestSplitPower()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% last updated: 3 aug 2024
%
% Generate simple test cases to confirm that the power split script 
% is working properly.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - flag to show whether all of the tests passed (1) or not (0)
%


%% TEST CASE SETUP %%
%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup testing methods      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% relative tolerance for checking if the tests passed
EPS03 = 1.0e-03;

% assume all tests passed
Pass = ones(2, 1);

% count the tests
itest = 1;

%% CASE 1: SINGLE ENGINE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define constants for the split
TestIn.Specs.Propulsion.Eta.TSPS = [0.8, 0.8];
TestIn.Specs.Propulsion.Eta.PSPS = [0.3, 0.3; 0.3, 0.3];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the power split
TestValue = PropulsionPkg.SplitPower(TestIn, [1500000; 2000000; 1000000], ...
    1, [0, 1], [1, 0; 1, 1]);

% list the correct values of the output
TrueValue = [6.2500e+06, 6.2500e+06; 8.3333e+06, 8.3333e+06;
    4.1667e+06, 4.1667e+06];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% increment the test counter
itest = itest + 1;

%% CASE 2: MULTIPLE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define constants for the split
TestIn.Specs.Propulsion.Eta.TSPS = [0.88, 0.88, 0.88, ; 0.88, 0.88, 0.88];
TestIn.Specs.Propulsion.Eta.PSPS = [0.38, 0.38, 0.38; 0.38, 0.38, 0.38; 0.38, 0.38, 0.38];
format short;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the power split
TestValue = PropulsionPkg.SplitPower(TestIn, [45000000; 3000000; 6000000; 3000000], ...
    [0.5, 0.5], [0, 1, 0; 0, 0, 1], [1, 0, 0; 1, 1, 0; 1, 0, 1]);

% list the correct values of the output
TrueValue = [1.3457e+08, 0.6728e+08, 0.6728e+08;
    0.0897e+08, 0.0449e+08, 0.0449e+08; 0.1794e+08, 0.0897e+08, 0.0897e+08;
    0.0897e+08, 0.0449e+08, 0.0449e+08];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% increment the test counter
itest = itest + 1;

% ----------------------------------------------------------

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%compute the answers

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "TestSplitPower tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "TestSplitPower tests failed:\n");
    
    % print which tests failed
    fprintf(1, "    Test %d\n", itest);
    
    % return failure
    Success = 0;
    
end

% ----------------------------------------------------------

end

% ----------------------------------------------------------
% ----------------------------------------------------------
% ----------------------------------------------------------

function [Pass] = CheckTest(TestValue, TrueValue, Tol)
%
% [Pass] = CheckTest(TestValue, TrueValue, Tol)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 may 2024
%
% Helper function to check if a test passed.
%
% INPUTS:
%     TestValue - array of the returned values from the function.
%                 size/type/units: m-by-n / double / []
%
%     TrueValue - array of the expected values output from the function.
%                 size/type/units: m-by-n / double / []
%
%     Tol       - acceptable relative tolerance between the test and true
%                 values.
%                 size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Pass      - flag to show whether the test passed (1) or not (0)
%

% compute the relative tolerance
RelTol = abs(TestValue - TrueValue) ./ TrueValue;

% check the tolerance
if (any(RelTol > Tol))
    
    % the test fails
    Pass = 0;
    
else
    
    % the test passes
    Pass = 1;
    
end

% ----------------------------------------------------------

end