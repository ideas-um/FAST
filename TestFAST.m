function [Success] = TestFAST()
%battery resize
% [Success] = TestFAST()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% last updated: 12 sep 2024
%
% Driver file for all FAST test cases
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%

%% TEST BATTERY PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
BatteryPkg.TestGroundCharge();
BatteryPkg.TestModel();
BatteryPkg.TestResizeBattery();

%% TEST POPULSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
PropulsionPkg.TestCreatePropArch();
PropulsionPkg.TestPowerAvailable();
PropulsionPkg.TestSplitPower();
PropulsionPkg.TestUpstreamSplit();

%% TEST UNIT CONVERSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and store results
UnitConversionPkg.TestConvForce();
UnitConversionPkg.TestConvLength();
UnitConversionPkg.TestConvMass();
UnitConversionPkg.TestConvTemp();
UnitConversionPkg.TestConvTSFC();
UnitConversionPkg.TestConvVel();

end