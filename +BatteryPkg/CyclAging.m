function [SOH, FEC] = CyclAging(Aircraft, ChemType, CumulFECs, GroundTime, ChrgRate)

% [Aircraft] = CyclAging(Aircraft)
% written by Yipeng Liu, yipenglx@umich.edu
%
% Predicts the Cycling Aging effect of battery SOH (State of Health) in
% operational usage. Notably, this battery degradation is accurate only
% on the Lithium ion battery with NMC and LFP chemistry component.
% 
% Last updated by 25 Jan 2025
%
% INPUTS:
%     Aircraft - aircraft structure with battery usage info to be analyzed.
%                size/type/units: 1-by-1 / struct / []
%
%     ChemType - battery chemistry component type from either "NMC" (1) or
%                "LFP" (2) LIB.
%                size/type/units: 1-by-1 / integer / []
%
%     FEC      - Full Equivalent Cycles (FEC) is how many complete 
%                charge-discharge cycles the battery has undergone, even if 
%                the actual usage consists of partial cycles.
%                size/type/units: 1-by-1 / integer / []
%
%     GroundTime - available charging time on the ground.
%                  size/type/units: 1-by-1 / double / [s]
%
%     ChrgRate   - airport charging rate.
%                  size/type/units: 1-by-1 / double / [kW]
%
% OUTPUTS:
%     SOH      - State of Health degraded in a Full Equivalent Cycle(FEC).
%                size/type/units: 1-by-1 / double / [%]
%
%     Aircraft - updated aircraft structure, which fills the
%                "Aircraft.Mission.History.SI" structure.
%                size/type/units: 1-by-1 / struct / []
%
%     FEC      - Full Equivalent Cycles (FEC) from this single cycle
%                size/type/units: 1-by-1 / integer / []

%% BASIC AGING MODEL INITIALIZATION %%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET UP PARAMETERS FOR NMC LIB %
if ChemType == 1

% NMC MODEL PARAMETER %
beta_nmc       = 0.001673;  % Baseline degradation rate factor
coeff_T_nmc    = 21.6745;   % Temperature sensitivity factor
coeff_DOD_nmc  = 0.022;     % DoD sensitivity factor
coeff_Cch_nmc  = 0.2553;    % Charge rate sensitivity factor
coeff_Cdch_nmc = 0.1571;    % Discharge rate sensitivity factor
coeff_mSOC_nmc = -0.0212;   % Middle state-of-charge sensitivity factor
alpha_opt_nmc  = 0.915;     % Exponent for FEC effect
temp_ref_nmc   = 293.15;       % Reference temperature [Kelvin]
mSOC_ref_nmc   = 0.42;      % Reference middle state-of-charge (42%)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET UP PARAMETERS FOR LFP LIB %
elseif ChemType == 2

% LFP MODEL PARAMETER %
beta_lfp       = 0.003414;  % Baseline degradation rate factor
coeff_T_lfp    = 5.8755;    % Temperature sensitivity factor
coeff_DOD_lfp  = -0.0045;   % DoD sensitivity factor
coeff_Cch_lfp  = 0.1038;    % Charge rate sensitivity factor
coeff_Cdch_lfp = 0.296;     % Discharge rate sensitivity factor
coeff_mSOC_lfp = 0.0513;    % Middle state-of-charge sensitivity factor
alpha_opt_lfp  = 0.869;     % Exponent for FEC effect
temp_ref_lfp   = 293.15;    % Reference temperature [Kelvin]
mSOC_ref_lfp   = 0.42;      % Reference middle state-of-charge (42%)

%%%%%%%%%%%%%%%%%%%%
% ERROR FOR OTHERS %
else
% Handle invalid inputs
error('Invalid ChemType input. Please input "NMC" or "LFP".');
end

%% INPUTTING DEGRADATION PARAMETERS %%

% THE COLUMN WITH BATTERY
ValiColumn = find(any(Aircraft.Mission.History.SI.Power.Capacity ~= 0, 1));

% AIRCRAFT BATTERY SPECS INPUT %
% battery actual operating temperature assumed at 35°C constantly
temp_act =  Aircraft.Specs.Battery.OpTemp + 273.15; % [k]      

% Depth of Discharge of battery
DOD = (max(Aircraft.Mission.History.SI.Power.SOC(:,ValiColumn)) - ... 
      min(Aircraft.Mission.History.SI.Power.SOC(:,ValiColumn)))/100;           

% C-rates during discharging %
DisCCrate = mean(Aircraft.Mission.History.SI.Power.C_rate ...
         (Aircraft.Mission.History.SI.Power.C_rate~=0));

% C-rates during charging %  %%%%%%%%% THIS PART CAN BE IMPROVED FURTHER IN THE FUTURE  %%%%%%%%%  
Aircraft = BatteryPkg.GroundCharge(Aircraft, GroundTime, ChrgRate);
CCrate = -mean(Aircraft.Mission.History.SI.Power.ChargedAC.C_rate ...
         (Aircraft.Mission.History.SI.Power.ChargedAC.C_rate~=0));

% mean/median SOC %
SOCValues = [];
SOCValues(end+1, 1)=Aircraft.Mission.History.SI.Power.SOC(1,ValiColumn);
for i = 2:length(Aircraft.Mission.History.SI.Power.SOC(:,ValiColumn))
    if Aircraft.Mission.History.SI.Power.SOC(i,ValiColumn) - Aircraft.Mission.History.SI.Power.SOC(i-1,ValiColumn) ~= 0
        SOCValues(end+1, 1) = Aircraft.Mission.History.SI.Power.SOC(i,ValiColumn);
    end
end
mSOC = mean(SOCValues)/100;

% Full Equivalent Cycles %
QMax = Aircraft.Specs.Battery.CapCell; % max capacity for a single cell

FEC = (((max(Aircraft.Mission.History.SI.Power.Capacity(:,ValiColumn))-Aircraft.Mission.History.SI.Power.Capacity(end,ValiColumn))...
    + (max(Aircraft.Mission.History.SI.Power.ChargedAC.Capacity)-min(Aircraft.Mission.History.SI.Power.ChargedAC.Capacity)))) ...
    / (2* QMax * Aircraft.Specs.Power.Battery.ParCells) ...
    + CumulFECs; % flight FEC for this single mission (charge + discharge)

%% THE FULL MODEL %%

% MODEL FOR NMC LIB 
if ChemType == 1

    SOH = 100-beta_nmc * exp(coeff_T_nmc*((temp_act-temp_ref_nmc)/temp_act) + coeff_DOD_nmc*DOD + ...
        coeff_Cch_nmc*CCrate + coeff_Cdch_nmc*DisCCrate) * (1+coeff_mSOC_nmc*mSOC*(1-(mSOC/(2*mSOC_ref_nmc)))) * FEC^(alpha_opt_nmc);

% MODEL FOR LFP LIB 
elseif ChemType == 2

    SOH = 100 - beta_lfp * exp(coeff_T_lfp*((temp_act-temp_ref_lfp)/temp_act) + coeff_DOD_lfp*DOD + ...
        coeff_Cch_lfp*CCrate + coeff_Cdch_lfp*DisCCrate) * (1+coeff_mSOC_lfp*mSOC*(1-(mSOC/(2*mSOC_ref_lfp)))) * FEC^(alpha_opt_lfp);
end
% ----------------------------------------------------------
