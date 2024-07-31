function [Success] = TestModel()
%
% [Success] = TestModel()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% last updated: 31 jul 2024
%
% Generate simple test cases to confirm that the battery model script 
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
EPS06 = 1.0e-06;

% assume all tests passed
Pass = ones(3, 1);

% count the tests
itest = 1;

%% CASE 1: SINGLE CELL BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the value to be converted
TestIn.Preq = 1000;
TestIn.Time = 89;
TestIn.SOCi = 85;
TestIn.Parallel = 1;
TestIn.Series = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, SOC] = BatteryPkg.Model(TestIn.Preq,TestIn.Time,TestIn.SOCi, ...
    TestIn.Parallel,TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, SOC];

% list the correct values of the output
TrueValue = [-0.4381, 207.2163, -90.7901, 2.550];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 2: MULTIPLE CELL, SINGLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the value to be converted
TestIn.Preq = 1000;
TestIn.Time = 89;
TestIn.SOCi = 85;
TestIn.Parallel = 1;
TestIn.Series = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, SOC] = BatteryPkg.Model(TestIn.Preq,TestIn.Time,TestIn.SOCi, ...
    TestIn.Parallel,TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, SOC];

% list the correct values of the output
TrueValue = [-0.4381, 207.2163, -90.7901, 2.550];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;

%% CASE 3: MULTIPLE CELL, MULTIPLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the value to be converted
TestIn.Preq = 1000;
TestIn.Time = 89;
TestIn.SOCi = 85;
TestIn.Parallel = 1;
TestIn.Series = 1;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Pout, Capacity, SOC] = BatteryPkg.Model(TestIn.Preq,TestIn.Time,TestIn.SOCi, ...
    TestIn.Parallel,TestIn.Series);

% store resulting values
TestValue = [Voltage, Pout, Capacity, SOC];

% list the correct values of the output
TrueValue = [-0.4381, 207.2163, -90.7901, 2.550];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

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
    fprintf(1, "TestModel tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "TestModel tests failed:\n");
    
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