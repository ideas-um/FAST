function [Success] = TestPowerAvailable()
%
% [Success] = TestPowerAvailable()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 30 may 2024
%
% Generate simple test cases to confirm that the power available function
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
Pass = ones(6, 1);

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup aircraft structure   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% segment ID
TestIn.Mission.Profile.SegsID = 1;

% beginning/ending control points
TestIn.Mission.Profile.SegBeg = 1;
TestIn.Mission.Profile.SegEnd = 2;

% flight conditions
TestIn.Mission.History.SI.Performance.TAS = [50    ; 100    ];
TestIn.Mission.History.SI.Performance.Rho = [ 1.225;   1.225];

% aircraft class
TestIn.Specs.TLAR.Class = "Turboprop";

% TV power
TestIn.Mission.History.SI.Power.TV = zeros(2, 1);


%% CASE 1: PARALLEL HYBRID %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = [82, 18];
TestIn.Specs.Propulsion.SLSThrust = [ 0,  0];

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = [1, 1];
TestIn.Specs.Propulsion.PropArch.PSPS = eye(2);
TestIn.Specs.Propulsion.PropArch.PSES = eye(2);

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() 1;
TestIn.Specs.Propulsion.Oper.TSPS = @(lambda) [1 - lambda, lambda];
TestIn.Specs.Propulsion.Oper.PSPS = @() eye(2);
TestIn.Specs.Propulsion.Oper.PSES = @() eye(2);

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = ones(1, 2);
TestIn.Specs.Propulsion.Eta.PSPS = ones(   2);
TestIn.Specs.Propulsion.Eta.PSES = ones(   2);

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = repmat(0.18, 2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamPSES = ones(        2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 0];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(1) = CheckTest(TestValue, TrueValue, EPS06);


%% CASE 2: SERIES HYBRID %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = [82, 100];
TestIn.Specs.Propulsion.SLSThrust = [ 0,   0];

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = [0, 1      ];
TestIn.Specs.Propulsion.PropArch.PSPS = [1, 0; 1, 1];
TestIn.Specs.Propulsion.PropArch.PSES = [1, 0; 0, 1];

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() 1;
TestIn.Specs.Propulsion.Oper.TSPS = @() [0, 1];
TestIn.Specs.Propulsion.Oper.PSPS = @(lambda) [1, 0; 1 - lambda, 1];
TestIn.Specs.Propulsion.Oper.PSES = @(lambda) [1, 0; 0,  lambda   ];

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = ones(1, 2);
TestIn.Specs.Propulsion.Eta.PSPS = ones(   2);
TestIn.Specs.Propulsion.Eta.PSES = ones(   2);

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = repmat(0.18, 2, 1);
TestIn.Mission.History.SI.Power.LamPSES = repmat(0.18, 2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 0];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(2) = CheckTest(TestValue, TrueValue, EPS06);


%% CASE 3: SERIES-PARALLEL HYBRID %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = [93.52, 18.00];
TestIn.Specs.Propulsion.SLSThrust = [ 0   ,  0   ];

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = [1, 1      ];
TestIn.Specs.Propulsion.PropArch.PSPS = [1, 0; 1, 1];
TestIn.Specs.Propulsion.PropArch.PSES = [1, 0; 0, 1];

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() 1;
TestIn.Specs.Propulsion.Oper.TSPS = @(lambda) [1 - lambda, lambda];
TestIn.Specs.Propulsion.Oper.PSPS = @(lambda) [1, 0; lambda, 1];
TestIn.Specs.Propulsion.Oper.PSES = @(lambda) [1, 0; 0, lambda];

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = ones(1, 2);
TestIn.Specs.Propulsion.Eta.PSPS = ones(   2);
TestIn.Specs.Propulsion.Eta.PSES = ones(   2);

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = repmat(0.18, 2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = repmat(0.64, 2, 1);
TestIn.Mission.History.SI.Power.LamPSES = repmat(0.36, 2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 0];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(3) = CheckTest(TestValue, TrueValue, EPS06);


%% CASE 4: CONVENTIONAL/ELECTRIC %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = repmat(50, 1, 2);
TestIn.Specs.Propulsion.SLSThrust = zeros(     1, 2);

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = eye(2);
TestIn.Specs.Propulsion.PropArch.PSPS = eye(2);
TestIn.Specs.Propulsion.PropArch.PSES = eye(2);

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() ones(1, 2) ./ 2;
TestIn.Specs.Propulsion.Oper.TSPS = @() eye(2);
TestIn.Specs.Propulsion.Oper.PSPS = @() eye(2);
TestIn.Specs.Propulsion.Oper.PSES = @() eye(2);

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = ones(2);
TestIn.Specs.Propulsion.Eta.PSPS = ones(2);
TestIn.Specs.Propulsion.Eta.PSES = ones(2);

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = ones(2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = ones(2, 1);
TestIn.Mission.History.SI.Power.LamPSES = ones(2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 1];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(4) = CheckTest(TestValue, TrueValue, EPS06);


%% CASE 5: SERIES WITH TWO DRIVING PS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = [37, 63, 100];
TestIn.Specs.Propulsion.SLSThrust = [ 0,  0,   0];

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = [0, 0, 1];
TestIn.Specs.Propulsion.PropArch.PSPS = [1, 0, 0; 0, 1, 0; 1, 1, 1];
TestIn.Specs.Propulsion.PropArch.PSES = [1; 1; 0];

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() 1;
TestIn.Specs.Propulsion.Oper.TSPS = @() [0, 0, 1];
TestIn.Specs.Propulsion.Oper.PSPS = @(lambda) [1, 0, 0; 0, 1, 0; lambda, 1 - lambda, 1];
TestIn.Specs.Propulsion.Oper.PSES = @() [1; 1; 0];

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = ones(1, 3);
TestIn.Specs.Propulsion.Eta.PSPS = ones(   3);
TestIn.Specs.Propulsion.Eta.PSES = ones(3, 1);

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = ones(        2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = repmat(0.37, 2, 1);
TestIn.Mission.History.SI.Power.LamPSES = ones(        2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 1, 1];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(5) = CheckTest(TestValue, TrueValue, EPS06);


%% CASE 6: TURBOELECTRIC WITH NON-PERFECT EFFICIENCIES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set the SLS power and thrust (thrust can be arbitrary for prop aircraft)
TestIn.Specs.Propulsion.SLSPower  = [160, 100];
TestIn.Specs.Propulsion.SLSThrust = [  0,   0];

% create the propulsion architecture
TestIn.Specs.Propulsion.PropArch.TSPS = [0, 1];
TestIn.Specs.Propulsion.PropArch.PSPS = [1, 0; 1, 1];
TestIn.Specs.Propulsion.PropArch.PSES = [1; 0];

% create the operational matrices
TestIn.Specs.Propulsion.Oper.TS   = @() 1;
TestIn.Specs.Propulsion.Oper.TSPS = @() [0, 1];
TestIn.Specs.Propulsion.Oper.PSPS = @() [1, 0; 1, 1];
TestIn.Specs.Propulsion.Oper.PSES = @() [1; 0];

% create the efficiency matrices
TestIn.Specs.Propulsion.Eta.TSPS = [1.0, 1.0];
TestIn.Specs.Propulsion.Eta.PSPS = [1.0, 1.0; 0.625, 1.0];
TestIn.Specs.Propulsion.Eta.PSES = [0.4; 1.0];

% power split mission history
TestIn.Mission.History.SI.Power.LamTS   = ones(2, 1);
TestIn.Mission.History.SI.Power.LamTSPS = ones(2, 1);
TestIn.Mission.History.SI.Power.LamPSPS = ones(2, 1);
TestIn.Mission.History.SI.Power.LamPSES = ones(2, 1);

% power source types
TestIn.Specs.Propulsion.PropArch.PSType = [1, 0];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestOut = PropulsionPkg.PowerAvailable(TestIn);

% get the output to be tested
TestValue = TestOut.Mission.History.SI.Power.TV;

% list the correct values of the output
TrueValue = [100; 100];

% run the test
Pass(6) = CheckTest(TestValue, TrueValue, EPS06);


%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "PowerAvailable tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "PowerAvailable tests failed:\n");
    
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