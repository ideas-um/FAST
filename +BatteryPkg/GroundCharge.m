function [Aircraft] = GroundCharge(Aircraft, ChrgTime, PowerStrategy)
%
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% modified by Vaibhav Rau, vaibhav.rau@warriorlife.net
% modified by Yipeng Liu, yipenglx@umich.edu
% last updated: 21 oct 2025
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
if nargin<3
    PowerStrategy = Aircraft.Specs.Battery.Charging;
end

TimeStep = 1;                           % simulate in 1-second increments
maxSteps = ceil(ChrgTime / TimeStep);

% Initial empty arrays
SOCSeries      = zeros(maxSteps+1, 1);
VoltageSeries  = zeros(maxSteps,   1);
CurrentSeries  = zeros(maxSteps,   1);
PoutSeries     = zeros(maxSteps,   1);
CapacitySeries = zeros(maxSteps+1, 1);
C_rateSeries   = zeros(maxSteps,   1);


%% Initial SOC and cell parameters %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SOCBeg = Aircraft.Mission.History.SI.Power.SOC(end);
SOCSeries(1) = SOCBeg;

SerCells = Aircraft.Specs.Power.Battery.SerCells;
ParCells = Aircraft.Specs.Power.Battery.ParCells;

% Determine if PowerStrategy is scalar or array
if isscalar(PowerStrategy)
    DynamicArray = false;
    BasePower       = PowerStrategy;
else
    DynamicArray = true;
    PowerArray      = PowerStrategy(:);  % ensure column vector
    Narray          = length(PowerArray);
end

% Compute cell capacity (also if degradation is considered)
if Aircraft.Settings.Analysis.Type < 0 && Aircraft.Specs.Battery.Degradation == 1
    Q_cell = Aircraft.Specs.Battery.CapCell * (Aircraft.Specs.Battery.SOH(end) / 100);
else
    Q_cell = Aircraft.Specs.Battery.CapCell;
end

V_cell_cutoff = Aircraft.Specs.Battery.MaxExtVolCell;  % 4.0880 V

% Flags and storage for the CC/CV stage:
InCV             = false;    % becomes true when cell voltage first ≥ cutoff
C_cutoff         = 0;        % magnitude of C-rate at moment of cutoff
V_pack_cutoff    = 0;        % pack voltage at cutoff instant
SOC_cutoffActual = 80;       % SOC at which CV taper begins


%% Estimate OCV at given SOC %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function [Vcell_OCV] = estimateOCV(soc_percent)
        [V_pack, ~, ~, ~, ~, ~] = BatteryPkg.Charging( ...
            Aircraft, 0, TimeStep, soc_percent, ParCells, SerCells );
        Vcell_OCV = V_pack / SerCells;
    end


%% Main charging loop %%
%%%%%%%%%%%%%%%%%%%%%%%%
for step = 1:maxSteps
    SOC_now = SOCSeries(step);

    if ~InCV

        %%%%%%%%%% Part 1 or 2 (CC) %%%%%%%%%%%%%%%%%%
        if SOC_now < 80
            % Part 1: SOC < 80%: use custom strategy or basePower
            if DynamicArray
                % If array index ≤ length, take that element; else hold last
                if step <= Narray
                    Pdesired = PowerArray(step);
                else
                    Pdesired = PowerArray(Narray);
                end
            else
                Pdesired = BasePower;
            end
            CurrentPower = -abs(Pdesired);

        else
            % SOC ≥ 80%: determine whether to hold previous C-rate or force 1C
            % Estimate cell OCV at current SOC
            Vcell_OCV_now = estimateOCV(SOC_now);

            C_rate_prev  = abs(C_rateSeries(step-1));
            I_pack_prev  = CurrentSeries(step-1);
            V_pack_prev  = VoltageSeries(step-1);

            if Vcell_OCV_now < V_cell_cutoff
                % Part 2: still below cutoff voltage
                if C_rate_prev < 1
                    % Part 2b: previous C-rate < 1C, hold that
                    CurrentPower = V_pack_prev * I_pack_prev;
                    % (I_pack_prev is negative: currentPower negative)

                else
                    % Part 2a: previous C-rate ≥ 1C: force 1C CC
                    I_cell_target = Q_cell;
                    I_pack_target = I_cell_target * ParCells;
                    V_pack_est    = Vcell_OCV_now * SerCells;
                    CurrentPower  = -abs(I_pack_target * V_pack_est);
                end

            else
                % Voltage ≥ cutoff: switch to CV taper
                InCV             = true;
                SOC_cutoffActual = SOC_now;
                C_cutoff         = abs(C_rate_prev);
                V_pack_cutoff    = V_pack_prev;

                % Build taper reference power from last-step current & voltage
                P_taper_ref     = V_pack_cutoff * I_pack_prev;  % negative
                % Quadratic taper fraction at cutoff: 1
                TaperFrac       = ((100 - SOC_now)/(100 - SOC_cutoffActual))^2;
                CurrentPower    = P_taper_ref * TaperFrac;
            end
        end

    else

        %%%%%%%%%%% Part 3: CV %%%%%%%%%%
        % taper
        TaperFrac       = ((100 - SOC_now)/(100 - SOC_cutoffActual))^2;
        TaperFrac       = max(min(TaperFrac, 1), 0);

        I_pack_target   = C_cutoff * Q_cell * ParCells * TaperFrac;
        CurrentPower    = -abs(I_pack_target * V_pack_cutoff);
    end

    % A first charging step
    [VoltageSeries(step), CurrentSeries(step), PoutSeries(step), CapacitySeries(step), ...
        SOC_next, C_rateSeries(step)] = ...
        BatteryPkg.Charging(Aircraft, CurrentPower, TimeStep, SOC_now, ParCells, SerCells);

    % Clamp SOC_next into [0,100]
    SOC_next = max(min(SOC_next, 100), 0);
    SOCSeries(step+1) = SOC_next;

    % Stop when |C-rate| ≤ 0.02 C
    if abs(C_rateSeries(step)) <= 0.02
        SOCSeries(step)        = SOC_next;
        CapacitySeries(step+1) = CapacitySeries(step);
        break;
    end

    % If reached 100% SOC, stop
    if SOC_now >= 100
        SOCSeries(step)        = 100;
        CapacitySeries(step+1) = CapacitySeries(step);
        break;
    end
end


%% TRIM ARRAYS TO ACTUAL SIMULATION LENGTH %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
validLen       = step;
VoltageSeries  = VoltageSeries(1:validLen);
CurrentSeries  = CurrentSeries(1:validLen);
PoutSeries     = PoutSeries(1:validLen);
CapacitySeries = CapacitySeries(1:validLen+1);
C_rateSeries   = C_rateSeries(1:validLen);
SOCSeries      = SOCSeries(1:validLen+1);


%% UPDATE AIRCRAFT STRUCTURE WITH CHARGING HISTORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Aircraft.Mission.History.SI.Power.ChargedAC.CtrlPtsTimeStep = TimeStep;
Aircraft.Mission.History.SI.Power.ChargedAC.SOCEnd         = SOCSeries(end);
Aircraft.Mission.History.SI.Power.ChargedAC.SOC            = SOCSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Voltage        = VoltageSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.VolCell        = VoltageSeries ./ SerCells;
Aircraft.Mission.History.SI.Power.ChargedAC.Current        = -CurrentSeries;   % negative = charging
Aircraft.Mission.History.SI.Power.ChargedAC.P_in           = PoutSeries;
Aircraft.Mission.History.SI.Power.ChargedAC.Capacity       = CapacitySeries;
Aircraft.Mission.History.SI.Power.ChargedAC.C_rate         = -C_rateSeries;

end
