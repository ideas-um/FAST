function [] = TestCyclAgingBaselines()
%
% [] = TestCyclAgingBaselines()
%
% written by Yipeng Liu, yipenglx@umich.edu
% last updated: 21 oct 2025
%
% This is a local function. Generating the baseline values for CyclAging
% regression tests based on your desired sample specs.
% Run once, then paste results into TestCyclAging.m.
%
% ----------------------------------------------------------

%% CASE 1: NMC BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 20;
A.Specs.Battery.CapCell             = 5.0;
A.Specs.Power.Battery.ParCells      = 2;
A.Specs.Power.Battery.SerCells      = 3;

A.Mission.History.SI.Power.SOC      = [70; 60; 50; 60; 70];
A.Mission.History.SI.Power.C_rate   = [0.3; 0.4; 0.5; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 2; 4; 4; 4];


ChemType     = 1;
CumulFECs    = 0;
ChargingTime = 60;
ChrgRate     = -1500;

[SOH1, FEC1, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);


%% CASE 2: LFP BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 25;
A.Specs.Battery.CapCell             = 4.0;
A.Specs.Power.Battery.ParCells      = 3;
A.Specs.Power.Battery.SerCells      = 2;

A.Mission.History.SI.Power.SOC      = [80; 60; 50; 55; 65];
A.Mission.History.SI.Power.C_rate   = [0.2; 0.3; 0.35; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 1.5; 3.0; 3.0; 3.0];

ChemType     = 2;
CumulFECs    = 0.25;
ChargingTime = 90;
ChrgRate     = -2000;

[SOH2, FEC2, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);


%% PRINT RESULTS %%
%%%%%%%%%%%%%%%%%%%

fprintf(1, "Paste these into TestCyclAging.m:\n");
fprintf(1, "  NMC: SOH_true = %.10f;  FEC_true = %.10f;\n", SOH1, FEC1);
fprintf(1, "  LFP: SOH_true = %.10f;  FEC_true = %.10f;\n", SOH2, FEC2);

% ----------------------------------------------------------

end

%% CASE 1: NMC BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 20;
A.Specs.Battery.CapCell             = 5.0;
A.Specs.Power.Battery.ParCells      = 2;
A.Specs.Power.Battery.SerCells      = 3;

A.Mission.History.SI.Power.SOC      = [70; 60; 50; 60; 70];
A.Mission.History.SI.Power.C_rate   = [0.3; 0.4; 0.5; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 2; 4; 4; 4];


ChemType     = 1;
CumulFECs    = 0;
ChargingTime = 60;
ChrgRate     = -1500;

[SOH1, FEC1, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);


%% CASE 2: LFP BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%%

A.Specs.Battery.NomVolCell     = 3.7;
A.Specs.Battery.MaxExtVolCell  = 4.0880;
A.Specs.Battery.ExpVol         = 0.12;
A.Specs.Battery.ExpCap         = 0.6;
A.Specs.Battery.IntResist      = 0.01;
A.Settings.Analysis.Type       = 0;
A.Settings.Degradation         = 0;

A.Specs.Battery.OpTemp              = 25;
A.Specs.Battery.CapCell             = 4.0;
A.Specs.Power.Battery.ParCells      = 3;
A.Specs.Power.Battery.SerCells      = 2;

A.Mission.History.SI.Power.SOC      = [80; 60; 50; 55; 65];
A.Mission.History.SI.Power.C_rate   = [0.2; 0.3; 0.35; 0; 0];
A.Mission.History.SI.Power.Capacity = [0; 1.5; 3.0; 3.0; 3.0];

ChemType     = 2;
CumulFECs    = 0.25;
ChargingTime = 90;
ChrgRate     = -2000;

[SOH2, FEC2, ~] = BatteryPkg.CyclAging(A, ChemType, CumulFECs, ChargingTime, ChrgRate);


%% PRINT RESULTS %%
%%%%%%%%%%%%%%%%%%%

fprintf(1, "Paste these into TestCyclAging.m:\n");
fprintf(1, "  NMC: SOH_true = %.10f;  FEC_true = %.10f;\n", SOH1, FEC1);
fprintf(1, "  LFP: SOH_true = %.10f;  FEC_true = %.10f;\n", SOH2, FEC2);

% ----------------------------------------------------------