function [] = ElectrifyERJ(RunCases)
%
% [] = ElectrifyERJ(RunCases)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 17 jul 2024
%
% Given an ERJ175LR model, electrify takeoff using different power splits
% to determine the overall aircraft size and fuel burn trends.
%
% INPUTS:
%     RunCases - flag to size the aircraft (1) or just load results (0)
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all

% assume cases must be run
if (nargin < 1)
    RunCases = 1;
end


%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%

% get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% number of power splits
nsplit = 11;

% assume a set of takeoff power splits
LambdaTko = linspace(0, 10, nsplit);

% remember the results
MTOW  = zeros(nsplit, 1);
OEW   = zeros(nsplit, 1);
Wbatt = zeros(nsplit, 1);
Wfuel = zeros(nsplit, 1);
Wem   = zeros(nsplit, 1);
Weng  = zeros(nsplit, 1);


%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%

% loop through all power splits
for isplit = 1:nsplit
    
    % filename for a .mat file
    MyMat = sprintf("ERJ%02d.mat", LambdaTko(isplit));
    
    % remember the new power split
    ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(isplit) / 100;
    ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(isplit) / 100;
    
    % check if cases must be run
    if (RunCases == 1)
        
        % size the aircraft
        SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        
        % save the aircraft
        save(MyMat, "SizedERJ");
        
    else
        
        % get the .mat file
        foo = load(MyMat);
        
        % get the sized aircraft
        SizedERJ = foo.SizedERJ;
        
    end
    
    % remember the aircraft weights
    MTOW( isplit) = SizedERJ.Specs.Weight.MTOW   ;
    OEW(  isplit) = SizedERJ.Specs.Weight.OEW    ;
    Wfuel(isplit) = SizedERJ.Specs.Weight.Fuel   ;
    Wbatt(isplit) = SizedERJ.Specs.Weight.Batt   ;
    Wem(  isplit) = SizedERJ.Specs.Weight.EM     ;
    Weng( isplit) = SizedERJ.Specs.Weight.Engines;
    
end


%% POST-PROCESS %%
%%%%%%%%%%%%%%%%%%

% compute the percent difference in MTOW, OEW, and fuel
PercDiffMTOW  = 100 .* ( MTOW(2:end) -  MTOW(1)) ./  MTOW(1);
PercDiffOEW   = 100 .* (  OEW(2:end) -   OEW(1)) ./   OEW(1);
PercDiffWfuel = 100 .* (Wfuel(2:end) - Wfuel(1)) ./ Wfuel(1);
PercDiffWeng  = 100 .* ( Weng(2:end) -  Weng(1)) ./  Weng(1);

% plot the MTOW results
figure;
yyaxis left
plot(LambdaTko, MTOW, "-o", "LineWidth", 2);
ylabel("MTOW (kg)");
yyaxis right
plot(LambdaTko(2:end), PercDiffMTOW, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - MTOW");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the fuel burn results
figure;
yyaxis left
plot(LambdaTko, Wfuel, "-o", "LineWidth", 2);
ylabel("Block Fuel (kg)");
yyaxis right
plot(LambdaTko(2:end), PercDiffWfuel, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - Block Fuel");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the OEW results
figure;
yyaxis left
plot(LambdaTko, OEW, "-o", "LineWidth", 2);
ylabel("OEW (kg)");
yyaxis right
plot(LambdaTko(2:end), PercDiffOEW, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - OEW");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the engine weight results
figure;
yyaxis left
plot(LambdaTko, Weng, "-o", "LineWidth", 2);
ylabel("Engine Weight (kg)");
yyaxis right
plot(LambdaTko(2:end), PercDiffWeng, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - Engine Weight");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the battery and electric motor weight results
figure;
yyaxis left
plot(LambdaTko, Wbatt, "-o", "LineWidth", 2);
ylabel("Battery Weight (kg)");
yyaxis right
plot(LambdaTko, Wem, "-o", "LineWidth", 2);
ylabel("Electric Motor Weight (kg)");

% format plot
title("Electrified ERJ - Electrical Components");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% ----------------------------------------------------------

end