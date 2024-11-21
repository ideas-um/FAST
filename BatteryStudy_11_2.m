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
% Batt_weight = NaN(nsplit, nclb);

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
        % Batt_weight(tsplit, csplit) = SizedERJ.Specs.Weight.Batt  
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

c_rate_list = zeros(length(loadedData),1);

for i = 1:length(loadedData)
    c_rate_list = max(loadedData{i, 1}.Aircraft.Mission.History.SI.Power.C_rate);
    disp(c_rate_list)
end


%% Battery study