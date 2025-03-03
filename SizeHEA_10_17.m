% Initial cleanup
clc;
clear;

%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%
% Get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% Changing Battery Specific Energy & Range
ERJ.Specs.Power.SpecEnergy.Batt = 0.25;
ERJ.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");

% Assume a set of takeoff power splits (LambdaTko)
LambdaTko = 0:0.5:10;  % Takeoff power splits in % 
LambdaClb = 0;   % Climbing power splits in % 
nsplit = length(LambdaTko);
nclb = length(LambdaClb);

% Initialize the matrix to store fuel burn
FuelBurn = NaN(nsplit, nclb);  % Fuel burn for each tko and clb combo (use NaN for non-converged cases)
MTOW = NaN(nsplit, nclb);
avg_TSFC_crs = NaN(nsplit, nclb);
avg_TSFC_clb = NaN(nsplit, nclb);
EG_weight = NaN(nsplit, nclb);
Batt_weight = NaN(nsplit, nclb);
Max_crate = NaN(nsplit, nclb);
CellPar = NaN(nsplit, nclb);
CellSer = NaN(nsplit, nclb);

%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%
% Loop through all power splits
for tsplit = 1:nsplit
    for csplit = 1:nclb
        % Set the power splits for the current iteration
        if LambdaTko(tsplit) == 0 && LambdaClb(csplit) == 0
            % Case when both takeoff and climb power splits are 0%
            ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(tsplit) / 100;
            ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(csplit) / 100;
            ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(tsplit) / 100;
            ERJ.Specs.Power.Battery.ParCells = NaN; %100 
            ERJ.Specs.Power.Battery.SerCells = NaN;  % 62
            ERJ.Specs.Power.Battery.BegSOC = NaN;   %100
        else
            % General case when takeoff power split is non-zero
            ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(tsplit) / 100;
            ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(csplit) / 100;
            ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(tsplit) / 100;  % SLS based on takeoff split
            ERJ.Specs.Power.Battery.ParCells = 100; %100 
            ERJ.Specs.Power.Battery.SerCells = 62;  % 62
            ERJ.Specs.Power.Battery.BegSOC = 100;   %100
        end

        ERJ.Specs.Propulsion.Engine.HEcoeff = 1 +  ERJ.Specs.Power.LamTSPS.SLS;

        % Size the aircraft for the current power split
        SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

        % Check if the sizing converged
        % if SizedERJ.Settings.Converged == 0
        %     % If the aircraft did not converge, skip this iteration
        %     fprintf('Skipped: (Tko = %.1f, Clb = %.1f) did not converge\n', LambdaTko(tsplit), LambdaClb(csplit));
        %     continue;
        % end

        % Store the fuel burn for the current LambdaTko and LambdaClb
        FuelBurn(tsplit, csplit) = SizedERJ.Mission.History.SI.Weight.Fburn(end);
        MTOW(tsplit, csplit) = SizedERJ.Specs.Weight.MTOW;
        avg_TSFC_crs(tsplit, csplit) = mean(SizedERJ.Mission.History.SI.Propulsion.TSFC(37:46,1));
        avg_TSFC_clb(tsplit, csplit) = mean(SizedERJ.Mission.History.SI.Propulsion.TSFC(10:37,1));
        EG_weight(tsplit, csplit) = SizedERJ.Specs.Weight.Engines;
        Batt_weight(tsplit, csplit) = SizedERJ.Specs.Weight.Batt ; 
        CellPar(tsplit, csplit) = SizedERJ.Specs.Power.Battery.ParCells; 
        CellSer(tsplit, csplit) = SizedERJ.Specs.Power.Battery.SerCells; 

        if LambdaTko(tsplit) == 0 && LambdaClb(csplit) == 0
            Max_crate(tsplit, csplit) = 0 ;
        else
            Max_crate(tsplit, csplit) = max(SizedERJ.Mission.History.SI.Power.C_rate) ;
        end
        
        % Optional: Display the progress
        fprintf('Iteration (Tko = %.1f, Clb = %.1f) - Fuel Burn: %.2f kg\n', ...
                LambdaTko(tsplit), LambdaClb(csplit), FuelBurn(tsplit, csplit));
    end
end

%% POST-PROCESS %%
%%%%%%%%%%%%%%%%%%

% Define a set of colors and line styles
cmap = lines(nclb);  % Use the 'lines' colormap, which gives you distinct colors
linestyles = {'-', '--', ':', '-.'};  % Different line styles
markers = {'o', 's', 'd', '^', 'v', '*', '+', 'x'};  % Different markers


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Post process for Furn burn %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
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
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Fuel Burn (kg)','FontSize',14);
title_text = sprintf('Fuel Burn vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%% Post process for MTOW %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, MTOW(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('MTOW (kg)','FontSize',14);
title_text = sprintf('MTOW vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Post process for avg_TSFC_crs %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, avg_TSFC_crs(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Average TSFC in Cruise','FontSize',14);
title_text = sprintf('Avg TSFC_{crs} vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Post process for avg_TSFC_clb %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, avg_TSFC_clb(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Average TSFC in Climbing','FontSize',14);
title_text = sprintf('Avg TSFC_{clb} vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Post process for Engine Weight %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, EG_weight(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Engine Weight (kg)','FontSize',14);
title_text = sprintf('Engine Weight vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%    Post process for C-rates    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, Max_crate(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Max C-rate (C)','FontSize',14);
title_text = sprintf('Max C-rate vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Post process for Battery Weight %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;

yyaxis left;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, Batt_weight(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Battery Weight (kg)','FontSize',14);
title_text = sprintf('Battery Weight vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;
%%%% Right Y-Axis: plotting Battery Cells (Parallel and Series)
yyaxis right;
plot(LambdaTko, CellPar, 'square', 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Parallel Cells'); % Red circles
hold on;
plot(LambdaTko, CellSer, 'pentagram', 'LineWidth', 2,  'MarkerSize', 6, 'DisplayName', 'Series Cells'); % Blue circles
ylabel('Battery Cells Count','FontSize',14);

% Title and Legend
title_text = sprintf('Battery Weight and Battery Cells vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);

legend('show','FontSize',12, 'Location', 'best'); % Ensures all legend labels appear
grid on;
hold off;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Post process for Battery Parallel Cell # %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
% Plot one line for each LambdaClb
for csplit = 1:nclb
    % Only plot for non-NaN fuel burn values
    plot(LambdaTko, CellPar(:, csplit), ...
         'Color', cmap(csplit, :), ...  % Assign a unique color from the colormap
         'LineStyle', linestyles{mod(csplit-1, length(linestyles)) + 1}, ...  % Cycle through line styles
         'Marker', markers{mod(csplit-1, length(markers)) + 1}, ...  % Cycle through markers
         'LineWidth', 1.5, ...  % Set line width for better visibility
         'DisplayName', sprintf('Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

% Add labels, title, and legend
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Battery Cell Parallel #','FontSize',14);
title_text = sprintf('Cell Parallel # vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text, 'FontSize', 14);
legend('show','FontSize',12);
grid on;
hold off;
% ----------------------------------------------------------


%% Percentage Change of Fuel burn to Conventional vs Tko power split

clc;clear;

ERJ = AircraftSpecsPkg.ERJ175LR;
ERJ_conv = AircraftSpecsPkg.ERJ175LR_conv;

% Takeoff Power split %
LambdaTko = 0:0.5:10;  % Takeoff power splits in %
LambdaClb = 0:0.5:0.5;   % Climbing power splits in % 

% Changing Battery Specific Energy & Range
% Tko power split case
ERJ.Specs.Power.SpecEnergy.Batt = 0.25;
ERJ.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");
% Conventional case
ERJ_conv.Specs.Power.SpecEnergy.Batt = 0.25;
ERJ_conv.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");

% Size conventional aircraft
SizedERJ_conv = Main(ERJ_conv, @MissionProfilesPkg.ERJ_ClimbThenAccel);

% Store percentage diff
Percentage_diff_clb = NaN(length(LambdaTko), length(LambdaClb));

for j = 1:length(LambdaClb)
    for i = 1:length(LambdaTko)
        
        if LambdaTko(i) == 0 && LambdaClb(j) == 0
            % Case when both takeoff and climb power splits are 0%
            ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(i) / 100;
            ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(j) / 100;
            ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(i) / 100;
            ERJ.Specs.Power.Battery.ParCells = NaN; %100 
            ERJ.Specs.Power.Battery.SerCells = NaN;  % 62
            ERJ.Specs.Power.Battery.BegSOC = NaN;   %100
        else
            % General case when takeoff power split is non-zero
            ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(i) / 100;
            ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(j) / 100;
            ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(i) / 100;  % SLS based on takeoff split
            ERJ.Specs.Power.Battery.ParCells = 100; %100 
            ERJ.Specs.Power.Battery.SerCells = 62;  % 62
            ERJ.Specs.Power.Battery.BegSOC = 100;   %100
        end
    
        % sizing power split aircraft for tko
        ERJ.Specs.Propulsion.Engine.HEcoeff = 1 +  ERJ.Specs.Power.LamTSPS.SLS;
        SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    
        if SizedERJ.Settings.Converged == 0
            continue
        end
    
        % Percentage diff
        Diff = (SizedERJ.Specs.Weight.Fuel - SizedERJ_conv.Specs.Weight.Fuel)/SizedERJ_conv.Specs.Weight.Fuel;
        Percentage_diff_clb(i, j) = Diff*100;
    
    end
end

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
         'DisplayName', sprintf('% Diff of Clb %.1f%%', LambdaClb(csplit)));  % Label for the legend
end

xlabel('Takeoff Power Split (%)','FontSize',14);
ylabel('Percentage Difference (%)','FontSize',14);
title_text = sprintf(['Percentage Difference of Fuel Burn: Conventional vs. Tko-Power-Split AC \n' ...
    'at %.0f nmi Range and %.2f kWh/kg Battery Specific Energy'], ...
    UnitConversionPkg.ConvLength(SizedERJ.Specs.Performance.Range, "m", "naut mi"), ERJ.Specs.Power.SpecEnergy.Batt);
title(title_text,'FontSize',14);
legend('show','FontSize',12);
grid on;
hold off;





% 
% 
% figure
% yyaxis left;
% plot(diff(Tko8_5_Clb_3.Mission.History.SI.Performance.Time), "LineWidth", 1.5, 'Color', 'b');
% xlabel("Segment Points", "FontSize", 14);
% ylabel("Time Difference [sec]", "FontSize", 14);
% title("Time difference vs. SOC change rate", 'FontSize', 14);
% 
% yyaxis right
% plot(diff(Tko8_5_Clb_3.Mission.History.SI.Power.SOC(:,2)), "LineWidth", 1.5, 'Color', 'r');
% ylabel("SOC rate of change", "FontSize", 14);
% legend("Time Difference", "SOC Rate of Change");
% 
% 
% 
% figure
% plot(Tko8_5_Clb_3.Mission.History.SI.Power.SOC(:,2), "LineWidth", 1.5, 'Color', 'b');
% hold on
% plot(Tko8_5.Mission.History.SI.Power.SOC(:,2), "LineWidth", 1.5, 'Color', 'r');
% hold off
% xlabel("Segment Points", "FontSize", 14);
% ylabel("SOC rate of change", "FontSize", 14);
% title("SOC change rate of 3% vs. 0% power split", 'FontSize', 14);
% legend("Clb Power Split 3%", "Clb Power Split 0%");