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
% Get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% Changing Battery Specific Energy & Range
batt = 250;
ERJ.Specs.Power.SpecEnergy.Batt = batt/1000;
range = 1000;
ERJ.Specs.Performance.Range = UnitConversionPkg.ConvLength(range, "naut mi", "m");

% Assume a set of takeoff power splits (LambdaTko)
LambdaTko = 0:.5:10;  % Takeoff power splits in % 
LambdaClb = 0:.5:5;   % Climbing power splits in % 
nsplit = length(LambdaTko);
nclb = length(LambdaClb);
tkoname = 10*LambdaTko;
clbname = 10*LambdaClb;

ERJ.Specs.Power.LamTSPS.Tko = 0;
ERJ.Specs.Power.LamTSPS.Clb = 0;
ERJ.Specs.Power.LamTSPS.SLS = 0;
ERJ.Specs.Power.Battery.ParCells = NaN; %100 
ERJ.Specs.Power.Battery.SerCells = NaN;  % 62
ERJ.Specs.Power.Battery.BegSOC = NaN;   %100
% Size the aircraft for the current power split
Conv = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

% Initialize the matrix to store fuel burn
FuelBurn = NaN(nsplit, nclb);  % Fuel burn for each tko and clb combo (use NaN for non-converged cases)

% Store percentage diff
Percentage_diff_clb = NaN(length(LambdaTko), length(LambdaClb));

Subdir = sprintf("HEA_%dnmi_%dWhkg", range, batt);

%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%
% Loop through all power splits
for tsplit = 1:nsplit
    for csplit = 1:nclb
        % filename for a .mat file
        MyMat = sprintf("ERJ_tko0%d_clb0%d.mat", tkoname(tsplit), clbname(csplit));
        HEA_Path = fullfile(Subdir, MyMat);
        % Set the power splits for the current iteration
        if LambdaTko(tsplit) == 0
            % Store the fuel burn for the current LambdaTko and LambdaClb
            FuelBurn(tsplit, csplit) = Conv.Specs.Weight.Fuel;
            % Percentage diff
            Percentage_diff_clb(tsplit, csplit) = 0;
            continue;
        else
            % General case when takeoff power split is non-zero
            ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(tsplit) / 100;
            ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(csplit) / 100;
            ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(tsplit) / 100;  % SLS based on takeoff split
            ERJ.Specs.Power.Battery.ParCells = 100; %100 
            ERJ.Specs.Power.Battery.SerCells = 62;  % 62
            ERJ.Specs.Power.Battery.BegSOC = 100;   %100
        end

        if RunCases == 0
            load(HEA_Path);
        else
            ERJ.Specs.Propulsion.Engine.HEcoeff = 1 +  ERJ.Specs.Power.LamTSPS.SLS;
    
            SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
            % save the aircraft
            save(HEA_Path, "SizedERJ");
        end

        % Check if the sizing converged
        if SizedERJ.Settings.Converged == 0
            % If the aircraft did not converge, skip this iteration
            fprintf('Skipped: (Tko = %.1f, Clb = %.1f) did not converge\n', LambdaTko(tsplit), LambdaClb(csplit));
            continue;
        end

        % Store the fuel burn for the current LambdaTko and LambdaClb
        FuelBurn(tsplit, csplit) = SizedERJ.Specs.Weight.Fuel;

        % Percentage diff
        Percentage_diff_clb(tsplit, csplit) = (SizedERJ.Specs.Weight.Fuel - Conv.Specs.Weight.Fuel)/Conv.Specs.Weight.Fuel * 100;

        % Optional: Display the progress
        fprintf('Iteration (Tko = %.1f, Clb = %.1f) - Fuel Burn: %.2f kg\n', ...
                LambdaTko(tsplit), LambdaClb(csplit), FuelBurn(tsplit, csplit));
    end
end

%% POST-PROCESS %%
%%%%%%%%%%%%%%%%%%
figure;
hold on;

FuelBurn = UnitConversionPkg.ConvMass(FuelBurn, "kg", "lbm");

% Define a set of colors and line styles
cmap = lines(nclb);  % Use the 'lines' colormap, which gives you distinct colors
linestyles = {'-', '--', ':', '-.'};  % Different line styles
markers = {'o', 's', 'd', '^', 'v', '*', '+', 'x'};  % Different markers

% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, FuelBurn(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Split','FontSize',14);
ylabel('Fuel Burn (lbm)','FontSize',14);
title_text = sprintf('Fuel Burn for Varing Power Splits - %.0f nmi, %.2f kWh/kg', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
lgd = legend('show','FontSize',12);
title(lgd, "Climb Split")
grid on;
hold off;


% ----------------------------------------------------------


%% Percentage Change of Fuel burn to Conventional vs Tko power split

cmap = lines(length(LambdaClb));  % Use the 'lines' colormap, which gives you distinct colors
linestyles = {'-', '--', ':', '-.'};  % Different line styles
markers = {'o', 's', 'd', '^', 'v', '*', '+', 'x'};  % Different markers

figure;
hold on;

% Plot one line for each LambdaClb
for csplit = 1:length(LambdaClb)
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, Percentage_diff_clb(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

xlabel('Takeoff Split','FontSize',14);
ylabel('Percentage Difference (%)','FontSize',14);
title_text = sprintf('Fuel Burn Percent Difference wrt Baseline- \n %.0f nmi, %.2f kWh/kg', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text,'FontSize',14);
lgd = legend('show','FontSize',12);
title(lgd, "Climb Split")
grid on;
hold off;

end