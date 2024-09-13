function [Success] = TestUpstreamSplit()
%battery resize
% [Success] = TestUpstreamSplit()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% last updated: 12 sep 2024
%
% Generate simple test cases to confirm that the upstream power script
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
EPS04 = 1.0e-04;

% assume all tests passed
Pass = ones(3, 1);

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
TestIn.Pups = [5000, 3000];
TestIn.Pdwn = 1.0e+03 * [6.1557, 2.2105];
TestIn.Arch = [1, 0; 1, 1]; 
TestIn.Oper = [1, 0; 0.3, 0.7];
TestIn.Eff = [0.96, 1; 0.95, 0.95];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the power split
TestValue = PropulsionPkg.UpstreamSplit(TestIn.Pups, TestIn.Pdwn, ...
    TestIn.Arch, TestIn.Oper, TestIn.Eff, 1);

% list the correct values of the output
TrueValue = [0.8461, 0.0000; 0.1539, 1.0000];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS04);

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
TestIn.Pups = [800000, 800000, 400000, 300000];
TestIn.Pdwn = 1.0e+06 * [2.6018, 0.7629, 0.3214];
TestIn.Arch = [1, 0, 0; 1, 0, 0; 0, 1, 0; 0, 1, 1]; 
TestIn.Oper = [1, 0, 0; 1, 0, 0; 0, 1, 0; 0, 0.25, 0.75];
TestIn.Eff = [0.61, 1, 1; 0.62, 1, 1; 1, 0.61, 1; 1, 0.7, 0.7];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the power split
TestValue = PropulsionPkg.UpstreamSplit(TestIn.Pups, TestIn.Pdwn, ...
    TestIn.Arch, TestIn.Oper, TestIn.Eff);

% list the correct values of the output
TrueValue = [0.5041, 0.0000, 0.0000; 0.4959, 0.0000, 0.0000; 
    0.0000, 0.8595, 0.0000; 0.0000, 0.1404, 1.0000];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS04);

% increment the test counter
itest = itest + 1;

%% CASE 3: MULTIPLE ENGINES WISK %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define constants for the split
TestIn.Pups = [800000, 800000, 400000, 300000, 300000, 500000, 350000];
TestIn.Pdwn = 1.0e+06 * [1.6368, 0.8134, 0.0928, 0.9907];
TestIn.Arch = [1, 0, 0, 0; 1, 0, 0, 0; 0, 1, 0, 0; 0, 1, 0, 0; 
    0, 1, 1, 1; 0, 0, 0, 1; 0, 0, 0, 1]; 
TestIn.Oper = [1, 0, 0, 0; 1, 0, 0, 0; 0, 1, 0, 0; 0, 1, 0, 0; 
    0, 0.3, 0.3, 0.4; 0, 0, 0, 1; 0, 0, 0, 1];
TestIn.Eff = [0.98, 1, 1, 1; 0.975, 1, 1, 1; 1, 0.98, 1, 1; 1, 0.96, 1, 1; 
    1, 0.97, 0.97, 0.97; 1, 1, 1, 0.99; 1, 1, 1, 0.967];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the power split
TestValue = PropulsionPkg.UpstreamSplit(TestIn.Pups, TestIn.Pdwn, ...
    TestIn.Arch, TestIn.Oper, TestIn.Eff);

% list the correct values of the output
TrueValue = [0.4987, 0.0000, 0.0000, 0.0000; 0.5013, 0.0000, 0.0000, 0.0000;
    0.0000, 0.5018, 0.0000, 0.0000; 0.0000, 0.3842, 0.0000, 0.0000;
    0.0000, 0.1141, 1.0000, 0.1249; 0.0000, 0.0000, 0.0000, 0.5098;
    0.0000, 0.0000, 0.0000, 0.3653];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS04);

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
    fprintf(1, "TestUpstreamSplit tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "TestUpstreamSplit tests failed:\n");
    
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