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




%% Conceptual Battery degradation study

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
SOHs(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);
FECs(end+1) = Off_SizedERJ.Specs.Battery.FEC(end);
for i = 1:1000

    Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
   
    if Off_SizedERJ.Specs.Battery.SOH(end) < 0
        break
    end

    SOHs(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);
    FECs(end+1) = Off_SizedERJ.Specs.Battery.FEC(end); 

end


plot(SOHs, 'LineWidth', 2);
hold on
plot(1:length(FECs), repmat(70, 1, length(FECs)), 'LineWidth', 2, 'LineStyle', '--', 'Color', 'r'); % Ensure horizontal line works
hold off
xlabel('Battery Cycling Times');
ylabel("Battery SOH [%]");
grid on
title('Battery Degradation')



%%

clc;clear
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SizedERJ.Settings.Analysis.Type=-2;

SOHs_20 = [];
SOHs_25 = [];
SOHs_30 = [];
SOHs_35 = [];

SizedERJ.Specs.Battery.OpTemp = 35;

Off_SizedERJ = Main(SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SOHs_35(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);

for i = 1:1000

    Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
   
    if Off_SizedERJ.Specs.Battery.SOH(end) < 0
        break
    end

    SOHs_35(end+1) = Off_SizedERJ.Specs.Battery.SOH(end);

end


plot(SOHs_20, 'LineWidth', 2);
hold on
plot(SOHs_25, 'LineWidth', 2);
plot(SOHs_30, 'LineWidth', 2);
plot(SOHs_35, 'LineWidth', 2);
plot(1:length(SOHs_20), repmat(70, 1, length(SOHs_20)), 'LineWidth', 2, 'LineStyle', '--', 'Color', 'r'); 
hold off
xlabel('Battery Cycling Times');
ylabel("Battery SOH [%]");
grid on
title('Battery Degradation');
legend( "T=20°C", "T=25°C", "T=30°C", "T=35°C");

