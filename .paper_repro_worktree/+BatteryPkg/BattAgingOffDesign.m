function [SOHs, FECs, mSOC, c_rate, dc_rate, DOD, CellCapa, MaxV, MinV, Lifespan] = ...
    BattAgingOffDesign(AircraftSpecs, MissionProfile, SOHStop, MaxCycles, Visualization)
%
% Runs an off-design cycling simulation until the battery SOH reaches a
% specified threshold or a maximum number of cycles is reached.
%
% written by Yipeng Liu, yipenglx@umich.edu
% last updated: 13 Jun 2025
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
%     mSOC               - mean SOC [%] per cycle.
%                         size/type/units: n-by-1 / array / [%]
%
%     c_rate             - mean charge C-rate [C] per cycle.
%                         size/type/units: n-by-1 / array / [C]
%
%     dc_rate            - mean discharge C-rate [C] per cycle.
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
if nargin < 4 || isempty(MaxCycles)
    MaxCycles = 1e5;
end
if nargin < 3 || isempty(SOHStop)
    SOHStop = 70;
end
if nargin < 2
    error("ERROR - OffDesignTest: requires at least AircraftSpecs and MissionProfileFunc inputs.");
end
if ~isa(MissionProfile,"function_handle")
    error("ERROR - OffDesignTest: MissionProfileFunc must be a function handle.");
end

%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%
% Perform first sizing and set off-design mode
SizedERJ = Main(AircraftSpecs, MissionProfile);
SizedERJ.Settings.Analysis.Type = -2;
SizedERJ.Settings.Degradation = 1;

% Preallocate arrays
SOHs     = [];
FECs     = [];
mSOC     = [];
c_rate   = [];
dc_rate  = [];
DOD      = [];
CellCapa = [];
MaxV     = [];
MinV     = [];

% First off-design run
Off_SizedERJ = Main(SizedERJ, MissionProfile);
Off_SizedERJ = BatteryPkg.GroundCharge(Off_SizedERJ, Off_SizedERJ.Specs.Battery.ChrgTime, Off_SizedERJ.Specs.Battery.Charging)
cycle = 1;

%% OFF-DESIGN CYCLE LOOP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while cycle <= MaxCycles

    % Record metrics
    SOHs(end+1,1)     = Off_SizedERJ.Specs.Battery.SOH(end);
    FECs(end+1,1)     = Off_SizedERJ.Specs.Battery.FEC(end);
    
    SOCs = Off_SizedERJ.Mission.History.SI.Power.SOC(:,2);
    active_mSOC = SOCs([true; diff(SOCs)~=0]);  % remove repeats
    mSOC(end+1,1)    = mean(active_mSOC);
    
    Off_SizedERJ     = BatteryPkg.GroundCharge(Off_SizedERJ, Off_SizedERJ.Specs.Battery.ChrgTime, Off_SizedERJ.Specs.Battery.Charging);
    cr = Off_SizedERJ.Mission.History.SI.Power.ChargedAC.C_rate;
    c_rate(end+1,1)  = mean(cr(cr~=0));
    
    dcr = Off_SizedERJ.Mission.History.SI.Power.C_rate;
    dc_rate(end+1,1) = mean(dcr(dcr~=0));
    
    DOD(end+1,1)     = max(SOCs) - min(SOCs);
    CellCapa(end+1,1)= max(Off_SizedERJ.Mission.History.SI.Power.Cap_cell(:,2));
    MaxV(end+1,1)    = max(Off_SizedERJ.Mission.History.SI.Power.V_cell(:,2));
    MinV(end+1,1)    = Off_SizedERJ.Mission.History.SI.Power.V_cell(end-1,2);
    
    % Check stopping condition
    if SOHs(end) <= SOHStop
        break
    end

    % Next cycle
    Off_SizedERJ = Main(Off_SizedERJ, MissionProfile);
    cycle = cycle + 1;
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
    figure;
    plot(SOHs,'LineWidth',2); hold on
    yline(SOHStop,'r--','LineWidth',2);
    hold off
    xlabel('Flight Cycle Number');
    ylabel('Battery SOH [%]');
    grid on
    title('Battery SOH vs. Cycle');
    
    figure;
    plot(FECs, SOHs,'LineWidth',2); hold on
    yline(SOHStop,'r--','LineWidth',2);
    hold off
    xlabel('Full Equivalent Cycles');
    ylabel('Battery SOH [%]');
    grid on
    title('Battery SOH vs. FEC');
    
    figure;
    plot(mSOC,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean SOC [%]');
    grid on
    title('Mean SOC per Cycle');
    
    figure;
    plot(dc_rate,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean Discharge C-rate [C]');
    grid on
    title('Mean Discharge C-rate');
    
    figure;
    plot(c_rate,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Mean Charge C-rate [C]');
    grid on
    title('Mean Charge C-rate');
    
    figure;
    plot(DOD,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Depth of Discharge [%]');
    grid on
    title('Depth of Discharge per Cycle');
    
    figure;
    plot(CellCapa,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Cell Capacity [Ah]');
    grid on
    title('Cell Capacity over Cycles');
    
    figure;
    plot(MaxV,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Max Cell Voltage [V]');
    grid on
    title('Max Cell Voltage');
    
    figure;
    plot(MinV,'LineWidth',2);
    xlabel('Cycle Number');
    ylabel('Min Cell Voltage [V]');
    grid on
    title('Min Cell Voltage');
end
end
