function [total_time] = TestGNU()
% function [] = TestGNU()
% Tests FAST's GNU Octave Compatibility
% Max Arnson || marnson@umich.edu
% Last Updated: 17 Sep 2025

%{

    Run this function in MATLAB and in GNU Octave as a tester for future
    updates. It covers regression searches and calls, aircraft sizing, and
    engine sizing.

    Aircraft sizing runs are as follows:

        Turbofan Class: Conventional and fully electric
        Turboprop Class: Conventional and parallel hybrid

%}

tic

%% Search Database Call
clear; clc; close all;

% load database from FAST
load('+DatabasePkg\IDEAS_DB.mat')

% simple manufacturer return call
[structs, vals] = RegressionPkg.SearchDB(TurbofanAC,{"Overview","Manufacturer"});

%% Regression Call
clear; clc; close all

% load database from FAST
load('+DatabasePkg\IDEAS_DB.mat')

% set an IOspace; simple 1 in 1 out
IOSpace = {{"Specs","Weight","MTOW"},{"Specs","Weight","OEW"}};

% target is simple single value
Target = 100e3;

% Run Regression
[Pred_OEW, OEW_Var] = RegressionPkg.NLGPR(TurbofanAC,IOSpace,Target);


% set an IOspace; more complex
IOSpace = {
    {"Specs","Weight","MTOW"},...
    {"Specs","Performance","Range"},...
    {"Specs","Aero","W_S","SLS"},...
    {"Specs","Weight","OEW"}
    };

% Target reflects higher dimensionality, add a second query point
Target = [
    100e3, 3000e3, 500
    75e3, 2000e3, 400
    ];

% run regression
[Pred_OEW, OEW_Var] = RegressionPkg.NLGPR(TurbofanAC,IOSpace,Target);


%% Test an aircraft sizing: Turbofan, conventional
clear; clc; close all;

% read in file
AC_In = AircraftSpecsPkg.CeRAS;
AC_In.Settings.Plotting = 0;

% size
AC_Out = Main(AC_In,@MissionProfilesPkg.CeRAS);

%% Test an aircraft sizing: Turbofan, all electric
clear; clc; close all;

% read in file
AC_In = AircraftSpecsPkg.AEA;
AC_In.Settings.Plotting = 0;
AC_In.Specs.Power.SpecEnergy.Batt = 3;

% size
AC_Out = Main(AC_In,@MissionProfilesPkg.A320);

%% Test an aircraft sizing: Turboprop
clear; clc; close all;

% read in file
AC_In = AircraftSpecsPkg.LM100J_Conventional;
AC_In.Settings.Plotting = 0;

% size
AC_Out = Main(AC_In,@MissionProfilesPkg.LM100J);

%% Test an aircraft sizing: Turboprop
clear; clc; close all;

% read in file
AC_In = AircraftSpecsPkg.LM100J_Hybrid;
AC_In.Settings.Plotting = 0;

% size
AC_Out = Main(AC_In,@MissionProfilesPkg.LM100J);

%% Test an Engine Sizing; Turbofan
clear; clc; close all;

% read in file
Eng_In = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;
Eng_In.Visualize = 0;

% size
Eng_Out = EngineModelPkg.TurbofanNonlinearSizing(Eng_In);

%% Test an Engine Sizing; Turboprop
clear; clc; close all;

% read in file
Eng_In = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
Eng_In.Visualize = 0;

% size
Eng_Out = EngineModelPkg.TurbopropNonlinearSizing(Eng_In);




%% output time
total_time = toc;

end

