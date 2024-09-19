function [Success] = TestModel()
%
% [Success] = TestModel()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 19 sep 2024
%
% Generate simple test cases to confirm that the battery model script 
% is working properly.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - flag to show if all of the tests passed (1) or not (0).
%               size/type/units: 1-by-1 / int / []
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
Pass = ones(3, 1);

% count the tests
itest = 1;


%% CASE 1: SINGLE CELL BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC = 100;
TestIn.Time = 100;
TestIn.SOCi = 90;
TestIn.Parallel = 1;
TestIn.Series = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, Q, SOC] = BatteryPkg.Model(TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel,TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, Q, SOC];

% list the correct values of the output
TrueValue = [3.3702, 29.6720, 100.0000, 2.7000, 62.5412];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% increment the test counter
itest = itest + 1;


%% CASE 2: MULTIPLE PARALLEL, SINGLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC = 100;
TestIn.Time = 56;
TestIn.SOCi = 72;
TestIn.Parallel = 3;
TestIn.Series = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, Q, SOC] = BatteryPkg.Model(TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, Q, SOC];

% list the correct values of the output
TrueValue = [3.6403, 27.4707, 100, 6.48, 67.2527];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% increment the test counter
itest = itest + 1;


%% CASE 3: MULTIPLE PARALLEL, SINGLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC = 72;
TestIn.Time = 9;
TestIn.SOCi = 50;
TestIn.Parallel = 1;
TestIn.Series = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, Q, SOC] = BatteryPkg.Model(TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, Q, SOC];

% list the correct values of the output
TrueValue = [10.4583, 6.8844, 72.0000, 4.5000, 49.4264];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% increment the test counter
itest = itest + 1;


%% CASE 4: MULTIPLE PARALLEL, MULTIPLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC = 500;
TestIn.Time = 90;
TestIn.SOCi = 70;
TestIn.Parallel = 5;
TestIn.Series = 3;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, Q, SOC] = BatteryPkg.Model(TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, Q, SOC];

% list the correct values of the output
TrueValue = [10.8624, 46.0300, 499.9950, 31.5000, 62.3295];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS03);

% ----------------------------------------------------------

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "Model tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "Model tests failed:\n");
    
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