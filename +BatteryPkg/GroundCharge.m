function [Aircraft] = GroundCharge(Aircraft, GroundTime, ChrgRate)
%
% [SOCEnd] = GroundCharge(Aircraft, GroundTime, ChrgRate)
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% modified by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Yipeng Liu, yipenglx@umich.edu
% last updated: 19 sep 2024
%
% Simulate aircraft charging at an airport gate.
%
% INPUTS:
%     Aircraft   - structure with information about the aircraft's mission
%                  history and battery SOC after flying.
%                  size/type/units: 1-by-1 / struct / []
%
%     GroundTime - available charging time on the ground.
%                  size/type/units: 1-by-1 / double / [s]
%
%     ChrgRate   - airport charging rate.
%                  size/type/units: 1-by-1 / double / [kW]
%
% OUTPUTS:
%     Aircraft   - structure with information about the aircraft's mission
%                  history and charged battery parameters.
%                  size/type/units: 1-by-1 / struct / []
%

%% INFO FROM AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SOC upon arrival
SOCBeg = Aircraft.Mission.History.SI.Power.SOC(end);

% number of cells in series and parallel
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

%% DEFINE FIXED TIME STEP %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TimeStep = 1;  % Define the time step as recording data every 1 second


%% INITIALIZE OUTPUT VARIABLES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Calculate the number of time steps
numSteps = ceil(GroundTime / TimeStep);   % Making the function update and record data every second.

SOCSeries      = zeros(numSteps , 1);       % Initialize array for SOC at each step (extra step for final SOC)
VoltageSeries  = zeros(numSteps , 1);       % Initialize array for Voltage at each step
CurrentSeries  = zeros(numSteps , 1);       % Initialize array for Current at each step
PoutSeries     = zeros(numSteps , 1);       % Initialize array for Power output at each step
CapacitySeries = zeros(numSteps , 1);       % Initialize array for Capacity (extra step for final capacity)
C_rateSeries   = zeros(numSteps , 1);       % Initialize array for C-rate at each step

% Set initial SOC
SOCSeries(1) = SOCBeg;

% Calculate initial values for Voltage, Current, Pout, Capacity, and C_rate without altering SOC
[VoltageSeries(1), CurrentSeries(1), PoutSeries(1), CapacitySeries(1), SOCSeries(2), C_rateSeries(1)] = ...
    BatteryPkg.Charging(Aircraft, ChrgRate, TimeStep, SOCBeg, ParCells, SerCells);

%% SIMULATE CHARGING %%
%%%%%%%%%%%%%%%%%%%%%%%

for i = 2:numSteps
    % Update the charging model for each 1-second interval
    [VoltageSeries(i), CurrentSeries(i), PoutSeries(i), CapacitySeries(i), SOCSeries(i+1), C_rateSeries(i)] = ...
        BatteryPkg.Charging(Aircraft,ChrgRate, TimeStep, SOCSeries(i), ParCells, SerCells);

    % minimum SOC is 0% (fully depleted) and can't be negative
    if (SOCSeries(i) < 0)
        SOCSeries(i) = 0;
    end

    % maximum SOC is 100% (fully charged) and can't be "overcharged"
    if (SOCSeries(i) >= 100)
        SOCSeries(i) = 100;                         % Set SOC to 100% when fully charged
        SOCSeries(i+1:end) = SOCSeries(i);          % Set following SOC to 100% when fully charged
        VoltageSeries(i:end) = VoltageSeries(i);    % Set voltage as current values when fully charged
        CurrentSeries(i:end) = 0;                   % Set current to 0 when fully charged
        PoutSeries(i:end) = 0;                      % Set power output to 0 when fully charged
        CapacitySeries(i:end) = CapacitySeries(i);  % Set capacity as current value when fully charged (Working with Model.m, line 229)
        C_rateSeries(i:end) = 0;                    % Set C-rate to 0 when fully charged
        break
    end
    
end

% Add one more calculation for the last value of capacity due to issue
% of Model.m, line 227
[~, ~, ~, CapacitySeries(end + 1), ~, ~] = BatteryPkg.Charging(Aircraft, ChrgRate, TimeStep, SOCSeries(end), ParCells, SerCells);

%% POST PROCESS %%
%%%%%%%%%%%%%%%%%%

% Final SOC after the entire ground time
SOCEnd = SOCSeries(end);

% Remember each data during charging
Aircraft.Mission.History.SI.Power.ChargedAC.CtrlPtsTimeStep = TimeStep;
Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd          = SOCEnd;
Aircraft.Mission.History.SI.Power.ChargedAC.SOC             = SOCSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Voltage         = VoltageSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.VolCell         = VoltageSeries./ SerCells;
Aircraft.Mission.History.SI.Power.ChargedAC.Current         = CurrentSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.P_in            = PoutSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Capacity        = CapacitySeries;
Aircraft.Mission.History.SI.Power.ChargedAC.C_rate          = C_rateSeries;

end
