function [SizedERJ] = ElectrifyERJ(RunCases)
%
% [] = ElectrifyERJ(RunCases)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 18 jul 2024
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
nsplit = 13;

% assume a set of takeoff power splits
LambdaTko = linspace(8, 20, nsplit);

% remember the results
MTOW  = zeros(nsplit, 1);
OEW   = zeros(nsplit, 1);
Wbatt = zeros(nsplit, 1);
Wfuel = zeros(nsplit, 1);
Wem   = zeros(nsplit, 1);
Weng  = zeros(nsplit, 1);
TSLS  = zeros(nsplit, 1);
TTOC  = zeros(nsplit, 1);
SFCs  = zeros(nsplit, 7);
TSLS_per_engine = zeros(nsplit, 1);

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
    
    % remember the weights
    MTOW( isplit) = SizedERJ.Specs.Weight.MTOW   ;
    OEW(  isplit) = SizedERJ.Specs.Weight.OEW    ;
    Wfuel(isplit) = SizedERJ.Specs.Weight.Fuel   ;
    Wbatt(isplit) = SizedERJ.Specs.Weight.Batt   ;
    Wem(  isplit) = SizedERJ.Specs.Weight.EM     ;
    Weng( isplit) = SizedERJ.Specs.Weight.Engines;
    
    % remember the thrust results
    TSLS(isplit)            = SizedERJ.Specs.Propulsion.Thrust.SLS            ;
    TSLS_per_engine(isplit) = SizedERJ.Specs.Propulsion.SLSThrust(1)          ;
    TTOC(isplit)            = SizedERJ.Mission.History.SI.Power.Tout_PS(37, 1);
    
    % remember SFCs at specific points in the mission
    SFCs(isplit, 1) = SizedERJ.Mission.History.SI.Propulsion.TSFC(  2, 1); %TkoSFC
    SFCs(isplit, 2) = SizedERJ.Mission.History.SI.Propulsion.TSFC_EMT(  2, 1); %TkoSFC_EMT
    SFCs(isplit, 3) = SizedERJ.Mission.History.SI.Propulsion.TSFC( 37, 1); %TOCSFC
    SFCs(isplit, 4) = SizedERJ.Mission.History.SI.Propulsion.TSFC( 39, 1); %Beginning_of_CruiseSFC
    SFCs(isplit, 5) = SizedERJ.Mission.History.SI.Propulsion.TSFC( 45, 1); %TODSFC
    SFCs(isplit, 6) = SizedERJ.Mission.History.SI.Propulsion.TSFC(100, 1); %BegSFC
    SFCs(isplit, 7) = SizedERJ.Mission.History.SI.Propulsion.TSFC(117, 1); %EndSFC
    
end


%% POST-PROCESS %%
%%%%%%%%%%%%%%%%%%

% convert the SFCs
SFCs = UnitConversionPkg.ConvTSFC(SFCs, "SI", "Imp");

% retrieve the important SFCs for plotting
TkoSFC       = SFCs([1, 6, 8, 11], 1)';
TkoSFC_EMT   = SFCs([1, 6, 8, 11], 2)';
TOCSFC       = SFCs([1, 6, 8, 11], 3)';
BegCruiseSFC = SFCs([1, 6, 8, 11], 4)';
TODSFC       = SFCs([1, 6, 8, 11], 5)';
BegSFC       = SFCs([1, 6, 8, 11], 6)';
EndSFC       = SFCs([1, 6, 8, 11], 7)';

% compute the percent difference in MTOW, OEW, and fuel
PercDiffMTOW      = 100 .* ( MTOW(2:end) -  MTOW(1)) ./  MTOW(1);
PercDiffOEW       = 100 .* (  OEW(2:end) -   OEW(1)) ./   OEW(1);
PercDiffWfuel     = 100 .* (Wfuel(2:end) - Wfuel(1)) ./ Wfuel(1);
PercDiffWeng      = 100 .* ( Weng(2:end) -  Weng(1)) ./  Weng(1);
PercDiffTSLS      = 100 .* ( TSLS(2:end) -  TSLS(1)) ./  TSLS(1);
PercDiffTTOC      = 100 .* ( TTOC(2:end) -  TTOC(1)) ./  TTOC(1);
PercDiffSLSThrust = 100 .* ( TSLS_per_engine(2:end) - TSLS_per_engine(1)) ./ TSLS_per_engine(1); 

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

% plot the SLS thrust results
figure;
yyaxis left
plot(LambdaTko, TSLS ./ 1000, "-o", "LineWidth", 2);
ylabel("SLS Thrust (kN)");
yyaxis right
plot(LambdaTko(2:end), PercDiffTSLS, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - SLS Thrust");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the TOC thrust results
figure;
yyaxis left
plot(LambdaTko, TTOC ./ 1000, "-o", "LineWidth", 2);
ylabel("Top of Climb Thrust (kN)");
yyaxis right
plot(LambdaTko(2:end), PercDiffTTOC, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - Top of Climb Thrust");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% ratio of TOC thrust to SLS thrust
figure;
yyaxis left
plot(LambdaTko, TTOC ./ TSLS, "-o", "LineWidth", 2);
ylabel("T_{TOC} / T_{SLS}");
yyaxis right
plot(LambdaTko(2:end), 100 .* (TTOC(2:end) ./ TSLS(2:end) - TTOC(1) / TSLS(1)) / (TTOC(1) / TSLS(1)), "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - Ratio of Top of Climb to SLS Thrust");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% plot the important SFCs
figure;
hold on;
b = bar([TkoSFC; TkoSFC_EMT; TOCSFC; BegCruiseSFC; TODSFC; BegSFC; EndSFC]);

% add labels to the bars
for i = 1:4
    x = b(i).XEndPoints;
    y = b(i).YEndPoints;
    L = string(round(b(i).YData, 3));
    text(x, y, L, "HorizontalAlignment", "center", "VerticalAlignment", "bottom");
end

% format plot
title("Electrified ERJ - In-Flight SFCs");
xlabel("Flight Phase");
ylabel("SFC (lbm/lbf/hr)");
grid on
legend("Conventional", "5% PHE", "7% PHE", "10% PHE");
xticks(1:7);
xticklabels(["Takeoff", "Takeoff with EM thrust", "Top of Climb", "Beginning of Cruise", "Top of Descent", "Start of Reserve", "End of Reserve"]);
set(gca, "FontSize", 18);
ylim([0, 0.9]);

% plot the fuel burn results
figure;
yyaxis left
plot(LambdaTko, TSLS_per_engine, "-o", "LineWidth", 2);
ylabel("SLS Thrust per engine");
yyaxis right
plot(LambdaTko(2:end), PercDiffSLSThrust, "-o", "LineWidth", 2);
ylabel("Percent Difference (%)");

% format plot
title("Electrified ERJ - SLS Thrust per engine");
xlabel("Power Split (%)");
set(gca, "FontSize", 18);
grid on

% ----------------------------------------------------------

end