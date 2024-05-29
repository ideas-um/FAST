%% LEAP
clear; clc; close all;
EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;
tic
OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle(SizedEngine,OffParams);
toc
TSFC_Error = (OffDesign.TSFC_Imperial - SizedEngine.TSFC_Imperial)/SizedEngine.TSFC_Imperial
On = SizedEngine;
Off = OffDesign;