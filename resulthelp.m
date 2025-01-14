clc 
clear

load("HEA_2150nmi_250Whkg\ERJ_tko00_clb00.mat")
og = SizedERJ;

load("HEA_2150nmi_250Whkg\ERJ_tko0100_clb010.mat")


mtow = UnitConversionPkg.ConvMass(SizedERJ.Specs.Weight.MTOW, "kg", "lbm")
ogmtow = UnitConversionPkg.ConvMass(og.Specs.Weight.MTOW, "kg", "lbm");

oew = UnitConversionPkg.ConvMass(SizedERJ.Specs.Weight.OEW, "kg", "lbm")
ogoew = UnitConversionPkg.ConvMass(og.Specs.Weight.OEW, "kg", "lbm");

fuel = UnitConversionPkg.ConvMass(SizedERJ.Specs.Weight.Fuel, "kg", "lbm")
ogfuel = UnitConversionPkg.ConvMass(og.Specs.Weight.Fuel, "kg", "lbm");

S = UnitConversionPkg.ConvLength(UnitConversionPkg.ConvLength(SizedERJ.Specs.Aero.S, "m", "ft"), "m", "ft")

sls = sum(SizedERJ.Specs.Propulsion.SLSThrust);
sls = UnitConversionPkg.ConvForce(sls, "N", "lbf")

eng = UnitConversionPkg.ConvForce(SizedERJ.Specs.Propulsion.SLSThrust(1), "N", "lbf")

tsfcclb = sum(SizedERJ.Mission.History.SI.Propulsion.TSFC(10:36))/27 * 1/0.453592 * 4.44822 * 3600
tsfccrs = sum(SizedERJ.Mission.History.SI.Propulsion.TSFC(37:46))/10 * 1/0.453592 * 4.44822 * 3600

batt = UnitConversionPkg.ConvMass(SizedERJ.Specs.Weight.Batt, "kg", "lbm")

EM = SizedERJ.Specs.Weight.EM * 10

% percent diff
dmtow = (mtow - ogmtow )/ogmtow
doew = (oew - ogoew)/ogoew
dfuel = (fuel - ogfuel)/ogfuel