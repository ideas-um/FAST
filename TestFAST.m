function [Success] = TestFAST()
%battery resize
% [Success] = TestUpstreamSplit()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% last updated: 9 sep 2024
%
% Driver file for all FAST test cases
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - flag to show whether all of the tests passed (1) or not (0)
%

%% TEST BATTERY PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
successArr = [BatteryPkg.TestGroundCharge()];
successArr = [successArr, BatteryPkg.TestModel()];
successArr = [successArr, BatteryPkg.TestResizeBattery()];

%% TEST POPULSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
successArr = [successArr, PropulsionPkg.TestCreatePropArch()];
successArr = [successArr, PropulsionPkg.TestPowerAvailable()];
successArr = [successArr, PropulsionPkg.TestSplitPower()];
successArr = [successArr, PropulsionPkg.TestUpstreamSplit()];

%% TEST UNIT CONVERSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
successArr = [successArr, UnitConversionPkg.TestConvForce()];
successArr = [successArr, UnitConversionPkg.TestConvLength()];
successArr = [successArr, UnitConversionPkg.TestConvMass()];
successArr = [successArr, UnitConversionPkg.TestConvTemp()];
successArr = [successArr, UnitConversionPkg.TestConvTSFC()];
successArr = [successArr, UnitConversionPkg.TestConvVel()];

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume all test cases are successful
Success = 1;

% iterate over success loop to verify test cases
for i = 1 : length(successArr)
    if successArr(i) ~= 1
        Success = 0;
    end
end

% ----------------------------------------------------------

end