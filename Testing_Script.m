clc
clear
ERJ = AircraftSpecsPkg.ERJ175LR
ERJ.Specs.Power.LamTSPS.Tko = 2 / 100;
ERJ.Specs.Power.LamTSPS.SLS = 2 / 100;
ERJ.Settings.Plotting = 1;
ERJ = Main(ERJ,@MissionProfilesPkg.ERJ_ClimbThenAccel)
Actual = [38790, 21500, 9428];
Exper = [ERJ.Specs.Weight.MTOW, ERJ.Specs.Weight.OEW, ERJ.Specs.Weight.Fuel];
error = (Exper - Actual)./Actual

%%
ElectrifyERJ