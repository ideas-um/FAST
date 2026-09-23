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

figure 
crate = [];
for i = 1:length(loadedData)
    crate(end+1,1) = max(loadedData{i, 1}.Aircraft.Mission.History.SI.Power.C_rate) ; 
end

plot(1:length(loadedData),crate, "LineWidth", 2);

figure 
weight = [];
for i = 1:length(loadedData)
    weight(end+1,1) = max(loadedData{i, 1}.Aircraft.Specs.Weight.Batt) ; 
end

plot(1:length(loadedData),weight, "LineWidth", 2);



%% Battery ground charging testing
clc;clear;close all
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);


ChargedERJ = BatteryPkg.GroundCharge(SizedERJ, 60*60, -500e3);


figure(1)
plot(ChargeERJ.Mission.History.SI.Power.ChargedAC.C_rate, 'LineWidth', 2);
hold on
yline(70, 'r--', 'LineWidth', 2); % More efficient way to plot a horizontal line at y=70
hold off
xlabel('Flight Cycling Times');
ylabel("Battery SOH [%]");
% xlim([0 FECs(end)]);
grid on
title('Battery Degradation')

%% OFF-design test
clc;clear;close all
SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SizedERJ.Settings.Analysis.Type=-2;

SOHs = [];
FECs = [];
mSOC = [];
dc_rate = [];
c_rate = [];
DOD = [];
CellCapa = [];
MaxV = [];
MinV = [];

Off_SizedERJ = Main(SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
SOHs(end+1,1) = Off_SizedERJ.Specs.Battery.SOH(end);
FECs(end+1,1) = Off_SizedERJ.Specs.Battery.FEC(end);
% mean/median SOC %
SOCs = Off_SizedERJ.Mission.History.SI.Power.SOC(:,2);
active_mSOC = SOCs([true; diff(SOCs) ~= 0]); % Remove consecutive repeated SOC values
mSOC(end+1,1) = mean(active_mSOC); % Averaged SOCs
c_rate(end+1,1) = mean(Off_SizedERJ.Mission.History.SI.Power.ChargedAC.C_rate(Off_SizedERJ.Mission.History.SI.Power.ChargedAC.C_rate~=0));
dc_rate(end+1,1) = mean(Off_SizedERJ.Mission.History.SI.Power.C_rate(Off_SizedERJ.Mission.History.SI.Power.C_rate~=0));
DOD(end+1,1) = (max(Off_SizedERJ.Mission.History.SI.Power.SOC(:,2)) - min(Off_SizedERJ.Mission.History.SI.Power.SOC(:,2)));     
CellCapa(end+1,1) = max(Off_SizedERJ.Mission.History.SI.Power.Cap_cell(:,2));
MaxV(end+1,1) = max(Off_SizedERJ.Mission.History.SI.Power.V_cell(:,2));
% MinV(end+1,1) = min(Off_SizedERJ.Mission.History.SI.Power.V_cell(Off_SizedERJ.Mission.History.SI.Power.V_cell(:,2)~=0, 2));
MinV(end+1,1) = Off_SizedERJ.Mission.History.SI.Power.V_cell(end-1,2);


for i = 1:100000

    Off_SizedERJ = Main(Off_SizedERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
   

    SOHs(end+1,1) = Off_SizedERJ.Specs.Battery.SOH(end);
    FECs(end+1,1) = Off_SizedERJ.Specs.Battery.FEC(end); 

    % mean/median SOC %
    SOCs = Off_SizedERJ.Mission.History.SI.Power.SOC(:,2);
    active_mSOC = SOCs([true; diff(SOCs) ~= 0]); % Remove consecutive repeated SOC values
    mSOC(end+1,1) = mean(active_mSOC); % Averaged SOCs
    
    c_rate(end+1,1) = mean(Off_SizedERJ.Mission.History.SI.Power.ChargedAC.C_rate(Off_SizedERJ.Mission.History.SI.Power.ChargedAC.C_rate~=0));
    
    dc_rate(end+1,1) = mean(Off_SizedERJ.Mission.History.SI.Power.C_rate(Off_SizedERJ.Mission.History.SI.Power.C_rate~=0));

    DOD(end+1,1) = (max(Off_SizedERJ.Mission.History.SI.Power.SOC(:,2)) - min(Off_SizedERJ.Mission.History.SI.Power.SOC(:,2)));     

    CellCapa(end+1,1) = max(Off_SizedERJ.Mission.History.SI.Power.Cap_cell(:,2));

    MaxV(end+1,1) = max(Off_SizedERJ.Mission.History.SI.Power.V_cell(:,2));

    % MinV(end+1,1) = min(Off_SizedERJ.Mission.History.SI.Power.V_cell(Off_SizedERJ.Mission.History.SI.Power.V_cell(:,2)~=0, 2));
    MinV(end+1,1) = Off_SizedERJ.Mission.History.SI.Power.V_cell(end-1,2);
    if Off_SizedERJ.Specs.Battery.SOH(end) <= 70
        break
    end
end

figure(1)
plot(SOHs, 'LineWidth', 2);
hold on
yline(70, 'r--', 'LineWidth', 2); % More efficient way to plot a horizontal line at y=70
hold off
xlabel('Flight Cycling Times');
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
title('Battery Degradation')

figure(3)
plot(mSOC, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Mean SOC");
grid on
title('Mean SOC')

figure(4)
plot(dc_rate, 'LineWidth', 2);
ylabel('Discharge c_{rates}');
xlabel("Flight Cycling Times");
grid on
title('Discharge c-rates')

figure(5)
plot(c_rate, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Charge c_{rate}");
grid on
title('Charge c-rates')

figure(6)
plot(DOD, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Depth of Discharge (DoD)");
grid on
title('Depth of Discharge (DoD)')

figure(7)
plot(CellCapa, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Cell Available Capacity [Ah]");
grid on
title('Cell Available Capacity')

figure(8)
plot(MaxV, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Max Cell Voltage [V]");
grid on
title('Max Cell Voltage [V]')

figure(9)
plot(MinV, 'LineWidth', 2);
xlabel('Flight Cycling Times');
ylabel("Min Cell Voltage [V]");
grid on
title('Min Cell Voltage [V]')
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


%% Battery Charging Model testing (dynamic array power strategy input generation function)
clc;clear
function P = randomChargingSegments(TotalTime, minSegLen, maxSegLen)
    if minSegLen < 1 || maxSegLen < minSegLen
        error('Require 1 ≤ minSegLen ≤ maxSegLen.');
    end
    P = zeros(TotalTime, 1); 
    idx = 1;                  
    while idx <= TotalTime
        segLen = randi([minSegLen, maxSegLen]);
        if idx + segLen - 1 > TotalTime
            segLen = TotalTime - idx + 1;
        end
        powerLevel = randi([250e3, 750e3]);
        P(idx : idx + segLen - 1) = -powerLevel;
        idx = idx + segLen;
    end
end

TotalTime= 1500;
minSegLen= 100;
maxSegLen= 300;
PowerStrategy = randomChargingSegments(TotalTime, minSegLen, maxSegLen);

figure;
stairs(PowerStrategy, 'LineWidth', 1.2);
xlabel('Time');
ylabel('Charging Power (kW)');
title('Random Charging Strategy');


SizedERJ = Main(AircraftSpecsPkg.ERJ175LR, @MissionProfilesPkg.ERJ_ClimbThenAccel);

ChargedERJ = BatteryPkg.GroundCharge(SizedERJ, 60*60, -500e3);
plot(ChargedERJ.Mission.History.SI.Power.ChargedAC.SOC)


%%
%% Prepare data
soc   = ChargedERJ.Mission.History.SI.Power.ChargedAC.SOC;
t     = (0:length(soc)-1) * ChargedERJ.Mission.History.SI.Power.ChargedAC.CtrlPtsTimeStep;
tmin  = t/60;

% Find the 80% index
idx80 = find(soc>=80,1,'first');

% Find CV start index
crate    = abs(ChargedERJ.Mission.History.SI.Power.ChargedAC.C_rate);
C_cutoff = crate(idx80);
sub      = crate(idx80:end) < C_cutoff;
firstInSub = find(sub,1,'first');
if ~isempty(firstInSub)
    idxCV = idx80 - 1 + firstInSub;
else
    idxCV = length(crate);
end

figure('Color','w'), hold on

% Phase shading
hBulk = patch([tmin(1) tmin(idx80) tmin(idx80) tmin(1)], [20 20 100 100], ...
    [0.9 0.9 1], 'EdgeColor','none', 'FaceAlpha',0.3, 'DisplayName','Bulk CC');
hCC1  = patch([tmin(idx80) tmin(idxCV) tmin(idxCV) tmin(idx80)], [20 20 100 100], ...
    [0.9 1 0.9], 'EdgeColor','none', 'FaceAlpha',0.3, 'DisplayName','CC @ 1 C');
hCV   = patch([tmin(idxCV) tmin(end) tmin(end) tmin(idxCV)], [20 20 100 100], ...
    [1 0.9 0.9], 'EdgeColor','none', 'FaceAlpha',0.3, 'DisplayName','CV taper');

% SOC curve
hSOC = plot(tmin, soc, 'b-', 'LineWidth',2, 'DisplayName','SOC');

% Threshold lines
h80h = yline(80, ':r', '80%', ...
    'LabelHorizontalAlignment','right', ...
    'LabelVerticalAlignment','top', ...
    'FontAngle','italic', ...
    'DisplayName','80% threshold');
hX80 = xline(tmin(idx80), '--k', 'I_{CC}=1C', ...
    'LabelVerticalAlignment','bottom', ...
    'DisplayName','80% entry');
hXcv = xline(tmin(idxCV), '--k', 'CV start', ...
    'LabelVerticalAlignment','bottom', ...
    'DisplayName','CV start');

% Annotations
text(mean(tmin(1:idx80)),    70, 'Full Power', 'HorizontalAlignment','center');
text(mean(tmin(idx80:idxCV)),70, 'CC Phase',   'HorizontalAlignment','center');
text(mean(tmin(idxCV:end)),  70, 'CV Phase',   'HorizontalAlignment','center');

% Labels & styling
xlabel('Time (min)')
ylabel('SOC (%)')
title('SOC Profile with CC–CV Phases')
ylim([20 100])
grid on

% Build the legend
legend([hSOC, h80h], ...
       'Location','southeast')

hold off


%% Battery degradation model testing
close all;
% ---------------------------
% 1) CHOOSE CHEMISTRY & PARAMETERS
% ---------------------------
% For NMC:
% beta    = 0.001673;   
% kT      = -21.6745;    % !!
% kDoD    = 0.022;     
% kCch    = 0.2553;   
% kCdis   = 0.1571;     
% kmSOC   = -0.0212;   
% alpha   = 0.915;     
% Tref    = 293;    
% mSOCref = 42;       

% %-- Uncomment to test LFP by replacing the above values:
beta    = 0.003414;
kT      = 5.8755;
kDoD    = -0.0045;
kCch    = 0.1038;
kCdis   = 0.296;
kmSOC   = 0.0513;
alpha   = 0.869;
Tref    = 293;
mSOCref = 42;

% ---------------------------
% 2) SET TEST CONDITIONS
% ---------------------------
temp_C   = 33;            
temp_act = temp_C + 273; 
DOD      = 80;          
Cch      = 4;           
Cdis     = 4;           
mSOC     = 50;         

% ---------------------------
% 3) DEFINE CYCLE RANGE
% ---------------------------
maxCycles = 5000;            % number of cycles to simulate
FEC       = (0:maxCycles)'; % full-equivalent cycle vector

% ---------------------------
% 4) COMPUTE SOH
% ---------------------------
ageing_term = exp( kT*((temp_act - Tref)./temp_act) ...
                 + kDoD*DOD + kCch*Cch + kCdis*Cdis );
msoc_term   = 1 + kmSOC*mSOC.*(1 - (mSOC/(2*mSOCref)));
SOH         = 100 - beta * ageing_term .* msoc_term .* (FEC.^alpha);

% ---------------------------
% 5) PLOT RESULTS
% ---------------------------
figure;
plot(FEC, SOH, 'LineWidth',1.5);
xlabel('Full Equivalent Cycles');
ylabel('State of Health (%)');
title('Empirical SOH vs. Cycles');
grid on;

% ---------------------------
% 6) OPTIONAL: STOP AT THRESHOLD
% ---------------------------
thresh = 70;  % SOH threshold [%]
id = find(SOH <= thresh, 1, 'first');
if ~isempty(id)
    fprintf('SOH drops to %.1f%% at cycle %d.\n', SOH(id), id);
end



%% BatteryDegradationValidation_CaseSeparated.m
% Compare empirical aging model to experimental Case A & Case B data
% Produces separate plots for each case with matching model conditions
% Calculates RMSE and MAE for each experimental file

clear; clc; close all;

% ---------------------------
% 1) MODEL PARAMETERS (NMC example)
% ---------------------------
beta    = 0.003414;
kT      = 5.8755;
kDoD    = -0.0045;
kCch    = 0.1038;
kCdis   = 0.296;
kmSOC   = 0.0513;
alpha   = 0.869;
Tref    = 293;
mSOCref = 42;

% ---------------------------
% 2) Define case-specific conditions
% ---------------------------
cases = { ...
    struct('name','CaseA', 'folder','Battery_validation/CaseA', ...
           'temp_C',35, 'DOD',100, 'Cch',4.8, 'Cdis',4, 'mSOC',50), ...
    struct('name','CaseB', 'folder','Battery_validation/CaseB', ...
           'temp_C',35, 'DOD',100, 'Cch',5.3,  'Cdis',4, 'mSOC',50)  ...
};

% ---------------------------
% 3) Loop over cases
% ---------------------------
for ci = 1:numel(cases)
    c = cases{ci};
    % determine maximum cycle across experimental files
    files = dir(fullfile(c.folder,'*.csv'));
    maxCycle = 0;
    for f = 1:numel(files)
        Texp = readtable(fullfile(c.folder, files(f).name));
        maxCycle = max(maxCycle, max(Texp.Cycle));
    end
    % compute model SOH up to maxCycle
    FEC = (0:maxCycle)';
    temp_act = c.temp_C + 273.15;
    ageing_term = exp(kT*((temp_act - Tref)./temp_act) + kDoD*c.DOD + kCch*c.Cch + kCdis*c.Cdis);
    msoc_term   = 1 + kmSOC*(c.mSOC/100)*(1 - (c.mSOC/100)/(2*(mSOCref/100)));
    SOH_model   = 100 - beta * ageing_term .* msoc_term .* (FEC.^alpha);

    % create figure for this case
    figure('Name',c.name,'NumberTitle','off'); hold on;
    legendEntries = {};

    % plot experimental data and compute errors
    for f = 1:numel(files)
        fname = files(f).name;
        Texp = readtable(fullfile(c.folder, fname));
        cycles_exp = Texp.Cycle;
        SOH_exp    = Texp.SOH * 100;
        plot(cycles_exp, SOH_exp, 'o', 'DisplayName', fname);
        legendEntries{end+1} = fname;

        % model prediction at experimental cycles
        idx = cycles_exp + 1; % account for zero-cycle at index 1
        SOH_pred = SOH_model(idx);

        % compute errors
        err = SOH_pred - SOH_exp;
        rmse = sqrt(mean(err.^2));
        mae  = mean(abs(err));
        fprintf('%s: %s -> RMSE = %.2f%%, MAE = %.2f%%\n', c.name, fname, rmse, mae);
    end

    % plot model curve
    plot(FEC, SOH_model, 'k-', 'LineWidth',1.5, 'DisplayName','Model');
    legendEntries{end+1} = 'Model';

    % finalize plot
    xlabel('Full Equivalent Cycles');
    ylabel('SOH (%)');
    title(sprintf('Empirical Model vs. %s Data', c.name));
    grid on;
    legend(legendEntries,'Location','best');
end


%% NMC validation (weird)
clear; clc; close all;

% —– 1) Load the experimental data —–
T = readtable('C:\Users\49401\Desktop\IDEAS\FAST\Battery_validation\esoh\aging_param_cell_09.csv');
cycles = T.N;              % cycle numbers
Cap   = T.Cap;            % measured capacity [Ah]
SOH_exp = Cap./Cap(1)*100; % experimental SOH [%]

% —– 2) Define your model parameters (NMC) —–
beta    = 0.001673;
kT      = 21.6745;
kDoD    = 0.022;
kCch    = 0.2553;
kCdis   = 0.1571;
kmSOC   = -0.0212;
alpha   = 0.915;
Tref    = 293.15;    % [K]
mSOCref = 42;      % 42% reference
% test conditions from Case #1
temp_act = 45 + 273.15;  % [K]
DOD      = 100;          % full 0–100% DoD
Cch      = 2;          % C/5
Cdis     = 2;          % C/5
mSOC     = 50;         % assume midpoint ~50%

% —– 3) Compute model prediction at each experimental cycle —–
SOH_pred = zeros(size(cycles));
for ii = 1:numel(cycles)
    FEC = cycles(ii);
    ageing = exp( kT*((temp_act-Tref)/temp_act) ...
                 + kDoD*DOD + kCch*Cch + kCdis*Cdis );
    mterm  = 1 + kmSOC*mSOC*(1 - (mSOC/(2*mSOCref)));
    SOH_pred(ii) = 100 - beta * ageing * mterm * FEC^alpha;
    % finalize plot
    xlabel('Full Equivalent Cycles');
    ylabel('SOH (%)');
    grid on;
end

% —– 4) Plot & compute error —–
figure; hold on;
plot(cycles, SOH_exp, 'o-', 'LineWidth',1.2, 'DisplayName','Experiment');
plot(cycles, SOH_pred,'s--','LineWidth',1.2,'DisplayName','Model');
xlabel('Full Equivalent Cycles'); ylabel('SOH (%)');
legend('Location','best'); grid on;
title('Validation of CyclAging vs. Case #1 Data');
hold off
% RMSE
rmse = sqrt(mean((SOH_pred - SOH_exp).^2));
fprintf('RMSE = %.2f %% SOH\n', rmse);