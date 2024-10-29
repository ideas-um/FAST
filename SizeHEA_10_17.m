% Initial cleanup
clc;
clear;

%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%
% Get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% Changing Battery Specific Energy & Range
ERJ.Specs.Power.SpecEnergy.Batt = 0.25;
ERJ.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150, "naut mi", "m");

% Assume a set of takeoff power splits (LambdaTko)
LambdaTko = 0:1:10;  % Takeoff power splits in % 
LambdaClb = 0:1:6;   % Climbing power splits in % 
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

%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%
% Loop through all power splits
for tsplit = 1:nsplit
    for csplit = 1:nclb
        % filename for a .mat file
        MyMat = sprintf("ERJ_tko0%d_clb0%d.mat", tkoname(tsplit), clbname(csplit));
        % Set the power splits for the current iteration
        if LambdaTko(tsplit) == 0 && LambdaClb(csplit) == 0
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

        ERJ.Specs.Propulsion.Engine.HEcoeff = 1 +  ERJ.Specs.Power.LamTSPS.SLS;

        SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        % save the aircraft
        save(MyMat, "SizedERJ");

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
xlabel('Takeoff Power Split (λ_{Tko})','FontSize',14);
ylabel('Fuel Burn (kg)','FontSize',14);
title_text = sprintf('Fuel Burn vs Lambda Tko for Various Climb Power Splits\nat %.0f nmi Range and %.2f kWh/kg Battery Specific Energy', ...
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


%% -----------------------------------TESTING SECTION ---------------------------------------------%%

a = AircraftSpecsPkg.ERJ175LR;

a.Specs.Power.LamTSPS.Tko = 0.5 / 100;
a.Specs.Power.LamTSPS.Clb = 8 / 100;
a.Specs.Power.LamTSPS.SLS = 0.5 / 100;

a.Specs.Power.Battery.ParCells = 100; %100 
a.Specs.Power.Battery.SerCells = 62;  % 62
a.Specs.Power.Battery.BegSOC = 100;   %100

a.Specs.Power.SpecEnergy.Batt = 0.25;
a.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150, "naut mi", "m");

a.Specs.Propulsion.Engine.HEcoeff = 1 +  a.Specs.Power.LamTSPS.SLS;

b = Main(a, @MissionProfilesPkg.ERJ_ClimbThenAccel);
b.Specs.Weight.Fuel