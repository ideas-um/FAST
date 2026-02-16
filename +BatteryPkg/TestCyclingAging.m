function [Success] = TestCyclingAging()
%
% [Success] = TestCyclAging()
% written by Yipeng Liu, yipenglx@umich.edu
% last updated: 23 sep 2025
%
% Testing the error of CyclAging.m model based on a sample baseline values
% generated from CyclAgingBaselines.m regression.
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

% relative tolerance for checking if the tests passed
EPS07 = 1.0e-06;

% assume all tests passed
Pass = ones(2, 1);

% count the tests
itest = 1;


%% CASE 1: NMC BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% define the aircraft structure
A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 20;     % [C]
A.Specs.Battery.CapCell             = 5.0;    % [Ah]
A.Specs.Power.Battery.ParCells      = 2;
A.Specs.Power.Battery.SerCells      = 3;

A.Mission.History.SI.Power.SOC      = [70; 60; 50; 60; 70];
A.Mission.History.SI.Power.C_rate   = [0.3; 0.4; 0.5; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 2; 4; 4; 4];

ChemType     = 1;
CumulFECs    = 0;
ChargingTime = 60;
ChrgRate     = -1500;

[SOH, FEC, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);

% list the correct values of the output (paste from BakeCyclAgingBaselines)
SOH_true = 99.9980155310;  
FEC_true = 0.1579166798;  

% run the test
Pass(itest) = CheckTest([SOH, FEC], [SOH_true, FEC_true], EPS07);

% increment the test counter
itest = itest + 1;


%% CASE 2: LFP BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% define the aircraft structure
A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 25;     % [C]
A.Specs.Battery.CapCell             = 4.0;    % [Ah]
A.Specs.Power.Battery.ParCells      = 3;
A.Specs.Power.Battery.SerCells      = 2;

A.Mission.History.SI.Power.SOC      = [80; 60; 50; 55; 65];
A.Mission.History.SI.Power.C_rate   = [0.2; 0.3; 0.35; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 1.5; 3.0; 3.0; 3.0];

ChemType     = 2;
CumulFECs    = 0.25;
ChargingTime = 90;
ChrgRate     = -2000;

[SOH, FEC, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);

% list the correct values of the output (paste from BakeCyclAgingBaselines)
SOH_true = 99.9937920058; 
FEC_true = 0.4012487844;  

% run the test
Pass(itest) = CheckTest([SOH, FEC], [SOH_true, FEC_true], EPS07);


%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% identify any tests that failed
itest = find(~Pass);

% check whether any tests failed
if (isempty(itest))
    
    % all tests passed
    fprintf(1, "CyclAging tests passed!\n");
    
    % return success
    Success = 1;
    
else
    
    % print out header
    fprintf(1, "CyclAging tests failed:\n");
    
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

% compute the relative tolerance
RelTol = abs(TestValue - TrueValue) ./ max(abs(TrueValue), 1);

% check the tolerance
if (any(RelTol > Tol))
    Pass = 0;
else
    Pass = 1;
end

% ----------------------------------------------------------

end
