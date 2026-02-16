function [Success] = TestResizeBattery()
%
% [Success] = TestResizeBattery()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Paul Mokotoff, prmoko@umich.edu
% modified by Yipeng Liu, yipenglx@umich.edu
% last updated: 23 sep 2025
%
% Generate simple test cases to confirm that the resize battery script
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
EPS05 = 1.0e-05;

% assume all tests passed
Pass = ones(2, 1);

% count the tests
itest = 1;


%% CASE 1: SIMPLE BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% define the values to be resized
TestIn.Specs.Propulsion.PropArch.SrcType = 0;
TestIn.Specs.Propulsion.PropArch.Arch    = 1;
TestIn.Specs.Power.SpecEnergy.Batt       = 0.4 * 3.6e+6;
TestIn.Mission.History.SI.Energy.E_ES    = [0; 100]; 
TestIn.Mission.History.SI.Energy.Eleft_ES= [0; 0];
TestIn.Settings.DetailedBatt             = 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the battery resize
TestOut = BatteryPkg.ResizeBattery(TestIn);

% get the output to be tested
TestValue = TestOut.Specs.Weight.Batt;

% list the correct values of the output
TrueValue = 6.9444e-05;

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS05);

% increment the test counter
itest = itest + 1;


%% CASE 2: DETAILED BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TestIn.Specs.Propulsion.PropArch.SrcType = 0;
TestIn.Specs.Propulsion.PropArch.Arch    = 1;
TestIn.Specs.Power.SpecEnergy.Batt       = 0.3 * 3.6e+6;   % [J/kg]
TestIn.Mission.History.SI.Energy.E_ES    = [0; 123];       % [J]
TestIn.Mission.History.SI.Energy.Eleft_ES= [0; 0];
TestIn.Settings.DetailedBatt             = 1;

TestIn.Specs.Power.Battery.SerCells      = 3;
TestIn.Specs.Power.Battery.ParCells      = 2;

TestIn.Specs.Battery.NomVolCell          = 3.9;            % [V]
TestIn.Specs.Battery.CapCell             = 2.4;            % [Ah]
TestIn.Specs.Battery.MinSOC              = 60;             % [%]
TestIn.Specs.Battery.MaxAllowCRate       = 2.0;            % [C]

TestIn.Mission.History.SI.Power.SOC      = [60; 60];       % [%]
TestIn.Mission.History.SI.Power.Pout     = [0; 0];         % [W]
TestIn.Mission.History.SI.Power.Current  = [0; 0];         % [A]

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% complete the battery resize
TestOut = BatteryPkg.ResizeBattery(TestIn);

% get the output to be tested
TestValue = TestOut.Specs.Weight.Batt;

% list the correct values of the output
TrueValue = 0.1872;

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS05);

% ----------------------------------------------------------

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "ResizeBattery tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "ResizeBattery tests failed:\n");
    
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