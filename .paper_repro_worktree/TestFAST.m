function [] = TestFAST()
%
% [] = TestFAST()
% written by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 11 nov 2024
%
% Driver file for all FAST test cases.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     none
%


%% TEST BATTERY PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and print results
BatteryPkg.TestGroundCharge();
BatteryPkg.TestModel();
BatteryPkg.TestResizeBattery();


%% TEST POPULSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and print results
PropulsionPkg.TestCreatePropArch();
PropulsionPkg.TestPowerAvailable();
PropulsionPkg.TestSplitPower();
PropulsionPkg.TestUpstreamSplit();


%% TEST UNIT CONVERSION PACKAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run test cases and print results
UnitConversionPkg.TestConvForce();
UnitConversionPkg.TestConvLength();
UnitConversionPkg.TestConvMass();
UnitConversionPkg.TestConvTemp();
UnitConversionPkg.TestConvTSFC();
UnitConversionPkg.TestConvVel();


%% TESTS COMPLETED %%
%%%%%%%%%%%%%%%%%%%%%

% print a notice
fprintf(1, "\nAll FAST tests completed! Check above to see if any have failed.\n");


end