function [Aircraft] = GroundCharge(Aircraft, ChrgTime, PowerStrategy)
%
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% modified by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Yipeng Liu, yipenglx@umich.edu
% last updated: 03 mar 2025
%
% Simulate aircraft charging with desired charging time and power strategy.
%
% INPUTS:
%     Aircraft      - structure with information about the aircraft's mission
%                     history and battery SOC after flying.
%                     size/type/units: 1-by-1 / struct / []
%
%     ChrgTime      - available charging time on the ground 
%                     size/type/units: 1-by-1 / double / [s].
%
%     PowerStrategy - charging power input. This can be either:
%                     a scalar value or an array of charging power 
%                     values (which will be used with a dynamic
%                     battery charging way) for each time step.
%                     size/type/units: 1-by-1 / double & array / [W]
% OUTPUTS:
%     Aircraft      - structure with updated mission history and charged battery
%                     parameters.
%                     size/type/units: 1-by-1 / struct / []

%% Check Inputs %%
%%%%%%%%%%%%%%%%%%

if nargin < 3
%    assign charging power
    PowerStrategy = Aircraft.Specs.Battery.Cpower;
end

%% A Dynamic Charging Power Strategy For Constant Power%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function outputs a dynamic charging power based on the different SOC.
% When the input is a scalar, the charging power is tapered as the battery
% approaches full charge (since 80% SOC).
function dynamicPower = DynamicChargePower(SOC, basePower)
    if SOC < 80
        dynamicPower = basePower;
    else
        dynamicPower = basePower * (100 - SOC) / 20;  % linearly taper to 0 as SOC nears 100%
    end
end

%% SETTING PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%
% Define a fixed time step (in seconds)
TimeStep = 1; 
maxSteps = ceil(ChrgTime / TimeStep);

% Preallocate arrays (add an extra element for initial SOC)
SOCSeries      = zeros(maxSteps+1, 1);
VoltageSeries  = zeros(maxSteps, 1);
CurrentSeries  = zeros(maxSteps, 1);
PoutSeries     = zeros(maxSteps, 1);
CapacitySeries = zeros(maxSteps+1, 1);
C_rateSeries   = zeros(maxSteps, 1);

% Get initial SOC from the Aircraft structure
SOCBeg = Aircraft.Mission.History.SI.Power.SOC(end);
SOCSeries(1) = SOCBeg;

% Get battery cell configuration from Aircraft specs
SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

%% DETERMINE POWER INPUT TYPE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% If PowerStrategy is a scalar, we use the DynamicChargePower function to taper.
% Otherwise, assume it's a dynamic array and ensure it's a column vector.
if isscalar(PowerStrategy)
    useDynamicFunction = true;
else
    useDynamicFunction = false;
    PowerArray = PowerStrategy(:);
end

%% INITIAL CHARGING CALL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
if useDynamicFunction
    currentPower = DynamicChargePower(SOCBeg, PowerStrategy);
else
    currentPower = PowerArray(1);
end

[VoltageSeries(1), CurrentSeries(1), PoutSeries(1), CapacitySeries(1), ...
    SOCSeries(2), C_rateSeries(1)] = ...
    BatteryPkg.Charging(Aircraft, currentPower, TimeStep, SOCBeg, ParCells, SerCells);

%% SIMULATE CHARGING %%
%%%%%%%%%%%%%%%%%%%%%%%
step = 1;
while step < maxSteps
    step = step + 1;
    
    % Compute the charging power for the current step:
    if useDynamicFunction
        currentPower = DynamicChargePower(SOCSeries(step), PowerStrategy);
    else
        if step <= length(PowerArray)
            currentPower = PowerArray(step);
        else
            currentPower = DynamicChargePower(SOCSeries(step), PowerArray(end));
        end
    end
    
    [VoltageSeries(step), CurrentSeries(step), PoutSeries(step), CapacitySeries(step), ...
        SOCSeries(step+1), C_rateSeries(step)] = ...
        BatteryPkg.Charging(Aircraft, currentPower, TimeStep, SOCSeries(step), ParCells, SerCells);
    
    % Enforce lower SOC bound
    if SOCSeries(step) < 0
        SOCSeries(step) = 0;
    end
    
    % Stop simulation if battery is fully charged.
    if SOCSeries(step) >= 100
        SOCSeries(step) = 100;
        [~, ~, ~, CapacitySeries(step+1), ~, ~] = ...
            BatteryPkg.Charging(Aircraft, currentPower, TimeStep, SOCSeries(step), ParCells, SerCells);
        break;
    end
end

%% TRIM ARRAYS TO ACTUAL SIMULATION LENGTH %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VoltageSeries  = VoltageSeries(1:step);
CurrentSeries  = CurrentSeries(1:step);
PoutSeries     = PoutSeries(1:step);
CapacitySeries = CapacitySeries(1:step);
C_rateSeries   = C_rateSeries(1:step);
SOCSeries      = SOCSeries(1:step);

%% UPDATE AIRCRAFT STRUCTURE WITH CHARGING HISTORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Aircraft.Mission.History.SI.Power.ChargedAC.CtrlPtsTimeStep = TimeStep;
Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd          = SOCSeries(end);
Aircraft.Mission.History.SI.Power.ChargedAC.SOC             = SOCSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Voltage         = VoltageSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.VolCell         = VoltageSeries ./ SerCells;
Aircraft.Mission.History.SI.Power.ChargedAC.Current         = -CurrentSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.P_in            = PoutSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Capacity        = CapacitySeries;
Aircraft.Mission.History.SI.Power.ChargedAC.C_rate          = -C_rateSeries;


end
