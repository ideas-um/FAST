clc;clear;

%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%
% Get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% Changing Battery Specific Energy & Range
ERJ.Specs.Power.SpecEnergy.Batt = 0.25;
ERJ.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150, "naut mi", "m");

% Assume a set of takeoff power splits (LambdaTko)
LambdaTko = 8.5;  % Takeoff power splits in % 
LambdaClb = 0;   % Climbing power splits in % 
nsplit = length(LambdaTko);
nclb = length(LambdaClb);

% % Initialize the matrix to store fuel burn
FuelBurn = NaN(nsplit, nclb);  % Fuel burn for each tko and clb combo (use NaN for non-converged cases)
% MTOW = NaN(nsplit, nclb);
% avg_TSFC_crs = NaN(nsplit, nclb);
% avg_TSFC_clb = NaN(nsplit, nclb);
% EG_weight = NaN(nsplit, nclb);
Batt_weight = NaN(nsplit, nclb);
C_rate = NaN(nsplit, nclb);

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

        % % Check if the sizing converged
        % if SizedERJ.Settings.Converged == 0
        %     % If the aircraft did not converge, skip this iteration
        %     fprintf('Skipped: (Tko = %.1f, Clb = %.1f) did not converge\n', LambdaTko(tsplit), LambdaClb(csplit));
        %     continue;
        % end

        % % Store the fuel burn for the current LambdaTko and LambdaClb
        FuelBurn(tsplit, csplit) = SizedERJ.Mission.History.SI.Weight.Fburn(end);
        % MTOW(tsplit, csplit) = SizedERJ.Specs.Weight.MTOW;
        % avg_TSFC_crs(tsplit, csplit) = mean(SizedERJ.Mission.History.SI.Propulsion.TSFC(37:46,1));
        % avg_TSFC_clb(tsplit, csplit) = mean(SizedERJ.Mission.History.SI.Propulsion.TSFC(10:37,1));
        % EG_weight(tsplit, csplit) = SizedERJ.Specs.Weight.Engines;
        Batt_weight(tsplit, csplit) = SizedERJ.Specs.Weight.Batt;
        C_rate(tsplit, csplit) = max(SizedERJ.Mission.History.SI.Power.C_rate);


        % % Optional: Display the progress
        % fprintf('Iteration (Tko = %.1f, Clb = %.1f) - Fuel Burn: %.2f kg\n', ...
        %         LambdaTko(tsplit), LambdaClb(csplit), FuelBurn(tsplit, csplit));
    end
end

%% Save the battery structure of each iterations


% Define the folder containing the .mat files
loadFolder = 'AircraftIterations';

% Get a list of all .mat files in the folder
matFiles = dir(fullfile(loadFolder, '*.mat'));

% Check if there are any files to load
if isempty(matFiles)
    disp('No .mat files found in the folder.');
else
    % Initialize a cell array to store the loaded data
    loadedData = cell(length(matFiles), 1);

    % Loop through each file and load the data
    for k = 1:length(matFiles)
        % Construct the full path to the .mat file
        filePath = fullfile(loadFolder, matFiles(k).name);

        % Load the file
        tempData = load(filePath);

        % Store the loaded data in the cell array
        loadedData{k} = tempData;

        % Display progress
        fprintf('Loaded file: %s\n', matFiles(k).name);
    end

    % Display completion message
    fprintf('Successfully loaded %d files from %s.\n', length(matFiles), loadFolder);
end




%% Conceptual Battery degradation study (没啥用)

SOHss = [];
FECss = 0;
FEC_info = [];

for i = 1:1000
    [a, b] = BatteryPkg.CyclAging(SizedERJ, 1, FECss, 30*60,-250000);

    if a < 70
        break
    end
    FECss = b;
    FEC_info(i) = FECss;
    SOHss(i) = a;
end

plot(SOHss, LineWidth= 2)
xlabel('Battery Cycling Times');
ylabel("Battery SOH [%]");
grid on
title('Battery Degradation')


%% OFF-design test
clc;clear
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SizedERJ.Settings.Analysis.Type=-2;

SOHs = [];
FECs = [];
Off_SizedERJ = Main(SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SOHs(end+1,1) = Off_SizedERJ.Specs.Battery.SOH(end);
FECs(end+1,1) = Off_SizedERJ.Specs.Battery.FEC(end);
for i = 1:100000

    Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
   

    SOHs(end+1,1) = Off_SizedERJ.Specs.Battery.SOH(end);
    FECs(end+1,1) = Off_SizedERJ.Specs.Battery.FEC(end); 

    if Off_SizedERJ.Specs.Battery.SOH(end) <= 70
        break
    end
end

figure(1)
plot(SOHs, 'LineWidth', 2);
hold on
yline(70, 'r--', 'LineWidth', 2); % More efficient way to plot a horizontal line at y=70
hold off
xlabel('Battery Cycling Times');
ylabel("Battery SOH [%]");
% xlim([0 FECs(end)]);
grid on
title('Battery Degradation')

figure(2)
plot(FECs, SOHs, 'LineWidth', 2);
hold on
yline(70, 'r--', 'LineWidth', 2); % More efficient way to plot a horizontal line at y=70
hold off
xlabel('FEC');
ylabel("Battery SOH [%]");
% xlim([0 FECs(end)]);
grid on


%% TEST degradation effect at different operation temperature

clc; clear;

% Initialize Storage Arrays for SOH at Different Temperatures
SOHs = cell(1,4);  % Cell array to store results for each temperature
OpTemps = [20, 25, 30, 35]; % Battery operational temperatures

% Initialize the SizedERJ aircraft model
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SizedERJ.Settings.Analysis.Type = -2;

% Loop over each operational temperature
for temp_idx = 1:length(OpTemps)
    % Set the battery operational temperature
    SizedERJ.Specs.Battery.OpTemp = OpTemps(temp_idx);

    % Initialize storage for this temperature
    SOHs{temp_idx} = [];

    % Run the first cycle
    Off_SizedERJ = Main(SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    SOHs{temp_idx}(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);

    % Continue cycling until SOH ≤ 70%
    for i = 1:100000
        Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

        % Stop iterating if SOH reaches 70%
        if Off_SizedERJ.Specs.Battery.SOH(end) <= 70
            break;
        end

        % Store SOH value
        SOHs{temp_idx}(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);
    end
end

% Plot SOH degradation for different temperatures
figure; hold on;
colors = {'b', 'g', 'm', 'r'}; % Colors for each temp
line_styles = {'-', '--', '-.', ':'}; % Different line styles

for temp_idx = 1:length(OpTemps)
    plot(SOHs{temp_idx}, 'LineWidth', 2, 'Color', colors{temp_idx}, 'LineStyle', line_styles{temp_idx});
end

% Add a reference line at SOH = 70%
yline(70, 'k--', 'LineWidth', 2); 

% Formatting
xlabel('Battery Cycling Times', 'FontSize', 14);
ylabel('Battery SOH [%]', 'FontSize', 14);
grid on;
title('Battery Degradation at Different Operational Temperatures', 'FontSize', 14);
legend("T = 20°C", "T = 25°C", "T = 30°C", "T = 35°C", 'Location', 'best');

hold off;

%% Different charging power vs SOH
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SizedERJ.Settings.Analysis.Type = -2;

% Define charging power values from -100e3 to -250e3 with a step of -10e3
Charging_P = -100e3:-50e3:-250e3;

% Initialize storage array for cycle counts
CycleCounts = zeros(size(Charging_P));

% Loop over different charging power values
for cp_idx = 1:length(Charging_P)
    % Set battery charging power
    SizedERJ.Specs.Battery.Cpower = Charging_P(cp_idx);

    % Initialize cycle count
    cycle_count = 0;

    % Run the first cycle
    Off_SizedERJ = Main(SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

    % Check if SOH is already below 70% at start
    if Off_SizedERJ.Specs.Battery.SOH(end) <= 70
        CycleCounts(cp_idx) = cycle_count;
        continue; % Move to the next charging power level
    end

    % Run subsequent cycles
    for i = 1:1000
        Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        cycle_count = cycle_count + 1;

        % Stop iterating when SOH reaches 70%
        if Off_SizedERJ.Specs.Battery.SOH(end) <= 70
            break;
        end
    end

    % Store the number of cycles before reaching SOH = 70%
    CycleCounts(cp_idx) = cycle_count;
end

% Plot Charging Power vs Number of Cycles Until SOH = 70%
figure;
plot(Charging_P / 1e3, CycleCounts, 'o-', 'LineWidth', 2, 'MarkerSize', 8, 'Color', 'b');

% Formatting
xlabel('Charging Power (kW)', 'FontSize', 14);
ylabel('Number of Cycles Until SOH = 70%', 'FontSize', 14);
grid on;
title('Battery Cycle Life vs Charging Power', 'FontSize', 14);
set(gca, 'XDir', 'reverse'); % Reverse x-axis to show -100 kW to -250 kW


%%
SOCValues = [];
SOCValues(end+1, 1)=SizedERJ.Mission.History.SI.Power.SOC(1,2);
for i = 2:length(SizedERJ.Mission.History.SI.Power.SOC(:,2))
    if SizedERJ.Mission.History.SI.Power.SOC(i,2) - SizedERJ.Mission.History.SI.Power.SOC(i-1,2) ~= 0
        SOCValues(end+1, 1) = SizedERJ.Mission.History.SI.Power.SOC(i,2);
    end
end
mSOC = mean(SOCValues)

a = SizedERJ.Mission.History.SI.Power.SOC(:,2)
active_mSOC = a([true; diff(a) ~= 0]);
mSOC = mean(active_mSOC)
