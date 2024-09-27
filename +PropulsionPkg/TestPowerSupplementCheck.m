function [Success] = TestPowerSupplementCheck()
%
% [Success] = TestPowerSupplementCheck()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 27 sep 2024
%
% Generate simple test cases to confirm that the power supplement checker
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

% relative tolerance for checking if the tests passed
EPS06 = 1.0e-06;

% assume all tests passed
Pass = ones(6, 1);

% count the tests
itest = 1;


%% CASE 1A: SERIES/PARALLEL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [1   , 1   ];
PSPS   = [1, 0; 1, 1];
PSType = [1   , 0   ];

% operational matrix
SplitPSPS = [1, 0; 0.9, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [80, 20; 70, 30];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [2, 0; 3, 0];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 1B: SERIES/PARALLEL, SWAP PS ORDER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [1,    1   ];
PSPS   = [1, 1; 0, 1];
PSType = [0,    1   ];

% operational matrix
SplitPSPS = [1, 0.9; 0, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [20, 80; 30, 70];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [0, 2; 0, 3];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 2A: SERIES HYBRID %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [0,    1   ];
PSPS   = [1, 0; 1, 1];
PSType = [1,    0   ];

% operational matrix
SplitPSPS = [1, 0; 1, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [10, 90; 15, 85];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [-90, 0; -85, 0];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 2B: SERIES HYBRID, SWAP PS ORDER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [1,    0   ];
PSPS   = [1, 1; 0, 1];
PSType = [0,    1   ];

% operational matrix
SplitPSPS = [1, 1; 0, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [90, 10; 85, 15];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [0, -90; 0, -85];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 3A: PARALLEL HYBRID %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [1,    1   ];
PSPS   = [1, 0; 0, 1];
PSType = [1,    0   ];

% operational matrix
SplitPSPS = [1, 0; 0, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [80, 20; 90, 10];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [20, 0; 10, 0];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);

% increment the test counter
itest = itest + 1;


%% CASE 3B: PARALLEL HYBRID, SWAP PS ORDER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% setup the inputs           %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% architecture matrices and PS types
TSPS   = [1,    1   ];
PSPS   = [1, 0; 0, 1];
PSType = [0,    1   ];

% operational matrix
SplitPSPS = [1, 0; 0, 1];

% efficiency matrix
EtaPSPS = [1, 1; 1, 1];

% fan efficiency
FanEfficiency = 1;

% power required by the driven power sources
PreqDr = [20, 80; 10, 90];

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% run the test               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% compute the power available
TestValue = PropulsionPkg.PowerSupplementCheck(PreqDr, TSPS, PSPS, SplitPSPS, EtaPSPS, PSType, FanEfficiency);

% list the correct values of the output
TrueValue = [0, 20; 0, 10];

% run the test
Pass(itest) = CheckTest(TestValue, TrueValue, EPS06);


%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "PowerSupplementCheck tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "PowerSupplementCheck tests failed:\n");
    
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
% last updated: 27 sep 2024
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

% check for any NaN
RelTol(isnan(RelTol)) = 0;

% check the tolerance
if (any(abs(RelTol) > Tol))
    
    % the test fails
    Pass = 0;
    
else
    
    % the test passes
    Pass = 1;
    
end

% ----------------------------------------------------------

end