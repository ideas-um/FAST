function [SOHs, FECs, MeanSOC, C_rate, DisC_rate, DOD, CellCapa, MaxV, MinV, Lifespan] = ...
    BattAgingOffDesign(AircraftSpecs, MissionProfile, SOHStop, MaxCycles, Visualization)
%
% [SOHs, FECs, MeanSOC, C_rate, DisC_rate, DOD, CellCapa, MaxV, MinV, Lifespan] = ...
% BattAgingOffDesign(AircraftSpecs, MissionProfile, SOHStop, MaxCycles, Visualization)
% written by Yipeng Liu, yipenglx@umich.edu
% last updated: 09 jan 2026
%
% A function used for battery SOH lifecycle analysis in Off-design only.
%
% INPUTS:
%     AircraftSpecs      - aircraft specification struct.
%                         size/type/units: struct / [] / []
%
%     MissionProfileFunc - handle to mission profile function.
%                         size/type/units: function_handle / [] / []
%
%     SOHStop            - stopping SOH threshold.
%                         size/type/units: 1-by-1 / double / [%]
%
%     MaxCycles          - maximum number of cycles to execute.
%                         size/type/units: 1-by-1 / double / [–]
%
%     Visualiztaion      - option to visualize the results: 1 for yes
%                         size/type/units: 1-by-1 / double / [–]
% OUTPUTS:
%     SOHs               - SOH [%] after each cycle.
%                         size/type/units: n-by-1 / array / [%]
%
%     FECs               - full equivalent cycles after each cycle.
%                         size/type/units: n-by-1 / array / [–]
%
%     MeanSOC            - mean SOC [%] per cycle.
%                         size/type/units: n-by-1 / array / [%]
%
%     C_rate             - mean charge C-rate [C] per cycle.
%                         size/type/units: n-by-1 / array / [C]
%
%     DisC_rate          - mean discharge C-rate [C] per cycle.
%                         size/type/units: n-by-1 / array / [C]
%
%     DOD                - depth of discharge [%] per cycle.
%                         size/type/units: n-by-1 / array / [%]
%
%     CellCapa           - max cell capacity [Ah] per cycle.
%                         size/type/units: n-by-1 / array / [Ah]
%
%     MaxV               - max cell voltage [V] per cycle.
%                         size/type/units: n-by-1 / array / [V]
%
%     MinV               - min cell voltage [V] per cycle.
%                         size/type/units: n-by-1 / array / [V]
%
%     Lifespan           - the battery pack lifespan in years
%                         size/type/units: n-by-1 / double / [year]
%
% ----------------------------------------------------------
%% PROCESS INPUTS %%
%%%%%%%%%%%%%%%%%%%%

% If no user input for "MaxCycles" parameter, a default 1e5 times of cycle is assumed
if nargin < 4 || isempty(MaxCycles)
    MaxCycles = 1e5;
end

% If no user input for "SOHStop" parameter, a default 70% threshold is assumed.
if nargin < 3 || isempty(SOHStop)
    SOHStop = 70;
end

% The "AircraftSpecs" and "MissionProfile" are mandatory inputs.
if nargin < 2
    error("ERROR - BattAgingOffDesign: requires at least AircraftSpecs and MissionProfile inputs.");
end

% The "MissionProfile" must be a vaild profile from "+MissionProfilesPkg"
if ~isa(MissionProfile,"function_handle")
    error("ERROR - BattAgingOffDesign: MissionProfile input must be a function handle.");
end

%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%
% Perform first sizing and set off-design mode
SizedAircraft = Main(AircraftSpecs, MissionProfile);
SizedAircraft.Settings.Analysis.Type = -1;
SizedAircraft.Settings.Degradation = 1;

% Preallocate arrays
SOHs      = [];
FECs      = [];
MeanSOC   = [];
C_rate    = [];
DisC_rate = [];
DOD       = [];
CellCapa  = [];
MaxV      = [];
MinV      = [];

% First off-design run
OffDesignAC = Main(SizedAircraft, MissionProfile);
OffDesignAC = BatteryPkg.GroundCharge(OffDesignAC, OffDesignAC.Specs.Battery.ChrgTime, OffDesignAC.Specs.Battery.Charging);

%% OFF-DESIGN CYCLE LOOP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for Cycle = 1:MaxCycles
    % Record metrics
    SOHs(end+1,1)     = OffDesignAC.Specs.Battery.SOH(end);
    FECs(end+1,1)     = OffDesignAC.Specs.Battery.FEC(end);

    SOCs = OffDesignAC.Mission.History.SI.Power.SOC(:,2);
    active_mSOC = SOCs([true; diff(SOCs)~=0]);  % remove repeats
    MeanSOC(end+1,1)    = mean(active_mSOC);

    OffDesignAC     = BatteryPkg.GroundCharge(OffDesignAC, OffDesignAC.Specs.Battery.ChrgTime, OffDesignAC.Specs.Battery.Charging);
    Cr = OffDesignAC.Mission.History.SI.Power.ChargedAC.C_rate;
    C_rate(end+1,1)  = mean(Cr(Cr~=0));

    DCr = OffDesignAC.Mission.History.SI.Power.C_rate;
    DisC_rate(end+1,1) = mean(DCr(DCr~=0));

    DOD(end+1,1)     = max(SOCs) - min(SOCs);
    CellCapa(end+1,1)= max(OffDesignAC.Mission.History.SI.Power.Cap_cell(:,2));
    MaxV(end+1,1)    = max(OffDesignAC.Mission.History.SI.Power.V_cell(:,2));
    MinV(end+1,1)    = OffDesignAC.Mission.History.SI.Power.V_cell(end-1,2);

    % Check stopping condition
    if SOHs(end) <= SOHStop
        break
    end

    % Next cycle
    OffDesignAC = Main(OffDesignAC, MissionProfile);
end

%% Battery Lifespan %%
%%%%%%%%%%%%%%%%%%%%%%

% Assumption of numbers of flight cycles per day
DayFly = 3;

% Lifespan is calculated by consider the total flight cycles / cycles per
% day to get how many "years" the battery life is.
Lifespan = length(FECs) / DayFly / 365; % [years]

%% PLOT RESULTS %%
%%%%%%%%%%%%%%%%%%%
if Visualization == 1
    figure; % Figure of SOH [%] vs. cycles
    plot(SOHs,'LineWidth',2); hold on
    yline(SOHStop,'r--','LineWidth',2);
    hold off
    xlabel('Flight Cycle Number');
    ylabel('Battery SOH [%]');
    grid on
    title('Battery SOH vs. Cycle');

    figure; % Figure of SOH [%] vs. full equivalent cycles
    plot(FECs, SOHs,'LineWidth',2); hold on
    yline(SOHStop,'r--','LineWidth',2);
    hold off
    xlabel('Full Equivalent Cycles');
    ylabel('Battery SOH [%]');
    grid on
    title('Battery SOH vs. FEC');

    figure; % Figure of mean SOC [%] vs. cycles
    plot(MeanSOC,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean SOC [%]');
    grid on
    title('Mean SOC per Cycle');

    figure; % Figure of mean discharge rate [C] vs. cycles
    plot(DisC_rate,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean Discharge C-rate [C]');
    grid on
    title('Mean Discharge C-rate');

    figure; % Figure of mean charge rate [C] vs. cycles
    plot(C_rate,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean Charge C-rate [C]');
    grid on
    title('Mean Charge C-rate');

    figure; % Figure of depth of discharge [%] vs. cycles
    plot(DOD,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Depth of Discharge [%]');
    grid on
    title('Depth of Discharge per Cycle');

    figure; % Figure of max cell capacity [Ah] vs. cycles
    plot(CellCapa,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Cell Capacity [Ah]');
    grid on
    title('Cell Capacity over Cycles');

    figure; % Figure of max cell terminal voltage [V] vs. cycles
    plot(MaxV,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Max Cell Voltage [V]');
    grid on
    title('Max Cell Voltage');

    figure; % Figure of min cell terminal voltage [V] vs. cycles
    plot(MinV,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Min Cell Voltage [V]');
    grid on
    title('Min Cell Voltage');
end
end
