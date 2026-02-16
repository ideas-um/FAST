function [Success] = TestModel()
%
% [Success] = TestModel()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Paul Mokotoff, prmoko@umich.edu
% modified by Yipeng Liu, yipenglx@umich.edu
% last updated: 23 sep 2025
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
Pass = ones(4, 1);

NumTest = 1;


%% CASE 1: SINGLE CELL BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC   = 100;
TestIn.Time     = 100;
TestIn.SOCi     = 90;
TestIn.Parallel = 1;
TestIn.Series   = 1;

A1 = MakeAircraft();

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
% store resulting values
[Voltage, Current, ~, ~, SOC, ~] = BatteryPkg.Discharging(A1, TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

TestValue = [Voltage(end), Current(end), TestIn.PreSOC, SOC(end)];
TrueValue = [3.3702, 29.6720, 100.0000, 62.5412];

% run the test
% increment the test counter
Pass(NumTest) = CheckTest(TestValue, TrueValue, EPS03);
NumTest = NumTest + 1;


%% CASE 2: MULTIPLE PARALLEL, SINGLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC   = 100;
TestIn.Time     = 56;
TestIn.SOCi     = 72;
TestIn.Parallel = 3;
TestIn.Series   = 1;

A2 = MakeAircraft();

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Current, ~, ~, SOC, ~] = BatteryPkg.Discharging(A2, TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
% list the correct values of the output
% run the test
TestValue = [Voltage(end), Current(end), TestIn.PreSOC, SOC(end)];
TrueValue = [3.6403, 27.4707, 100.0000, 67.2527];

Pass(NumTest) = CheckTest(TestValue, TrueValue, EPS03);
NumTest = NumTest + 1;


%% CASE 3: MULTIPLE PARALLEL, SINGLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC   = 72;
TestIn.Time     = 9;
TestIn.SOCi     = 50;
TestIn.Parallel = 1;
TestIn.Series   = 3;

A3 = MakeAircraft();

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Current, ~, ~, SOC, ~] = BatteryPkg.Discharging(A3, TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
% list the correct values of the output
TestValue = [Voltage(end), Current(end), TestIn.PreSOC, SOC(end)];
TrueValue = [10.4583, 6.8844, 72.0000, 49.4264];

Pass(NumTest) = CheckTest(TestValue, TrueValue, EPS03);
NumTest = NumTest + 1;


%% CASE 4: MULTIPLE PARALLEL, MULTIPLE SERIES BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the battery to be modeled
TestIn.PreSOC   = 500;
TestIn.Time     = 90;
TestIn.SOCi     = 70;
TestIn.Parallel = 5;
TestIn.Series   = 3;

% ----------------------------------------------------------
A4 = MakeAircraft();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the model
[Voltage, Current, ~, ~, SOC, ~] = BatteryPkg.Discharging(A4, TestIn.PreSOC, ...
    TestIn.Time, TestIn.SOCi, TestIn.Parallel, TestIn.Series);

% store resulting values
TestValue = [Voltage(end), Current(end), TestIn.PreSOC, SOC(end)];
TrueValue = [10.8624, 46.0300, 499.9950, 62.3295];

Pass(NumTest) = CheckTest(TestValue, TrueValue, EPS03);


%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
NumTest = find(~Pass);

% check whether any tests failed
if (isempty(NumTest))
    
    % all tests passed
    fprintf(1, "Model tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "Model tests failed:\n");
    
    % print which tests failed
    fprintf(1, "    Test %d\n", NumTest);
    
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
% updated by Yipeng Liu, yipenglx@umich.edu
% last updated: 21 oct 2025
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

RelTol = abs(TestValue - TrueValue) ./ max(abs(TrueValue), 1e-12);

% check the tolerance
if (any(RelTol > Tol))
    
    % the test fails
    Pass = 0;
    fprintf(1,"  Test expected: [%0.4f %0.4f %0.4f %0.4f %0.4f]\n", TrueValue);
    fprintf(1,"  Test got     : [%0.4f %0.4f %0.4f %0.4f %0.4f]\n", TestValue);
else
    
    % the test passes
    Pass = 1;
end

end

% ----------------------------------------------------------

function Aircraft = MakeAircraft()
Aircraft.Specs.Battery.MaxExtVolCell = 4.0880;
Aircraft.Specs.Battery.IntResist     = 0.0199;
Aircraft.Specs.Battery.ExpVol        = 0.0986;
Aircraft.Specs.Battery.ExpCap        = 30;
Aircraft.Specs.Battery.CapCell       = 3.0;
Aircraft.Specs.Battery.SOH           = 100;
Aircraft.Settings.Analysis.Type      = 0;
Aircraft.Settings.Degradation        = 0;
end
