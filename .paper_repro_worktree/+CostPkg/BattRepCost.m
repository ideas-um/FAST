function [C_rep] = BattRepCost(Aircraft, Year, BMS, Lifespan)
%
% written by Yipeng Liu, yipenglx@umich.edu
% last updated: 05 Jun 2025
%
% Compute the battery (and its battery management system if needed)
% replacement cost during the life cycle of the general battery energy
% storage system. Some parameters should be aware of updating year by year.
%
% INPUTS:
%     Aircraft      - structure with information about the aircraft's mission
%                     history and battery SOC after flying.
%                     size/type/units: 1-by-1 / struct / []
%
%     Year          - the calender year of the current cost is at.
%                     size/type/units: 1-by-1 / integer / [years]
%
%     BMS           - providing the flexibility for the function input that
%                     whether user wants to consider the cost of BMS, or
%                     just battery cells cost solely. 1 - Yes, 0 - No.
%                     size/type/units: 1-by-1 / integer / []
%
%     Lifespan      - the lifespan of the specific battery system, from
%                     your battery EOL analysis results. The unit is in
%                     years, i.e. 2, or 5 years until the battery reaches
%                     to its EOL (70%) from its BOL (100%). 
%                     size/type/units: 1-by-1 / integer / [years]
%
% OUTPUTS:
%     Cost          - the battery (w/ or w/o BMS) replacement cost for its
%                     lifecycle.
%                     size/type/units: 1-by-1 / struct / [$]

%% BMS Cost Portion to Battery System Cost Model %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Call the LIB battery type from specs
BattType = Aircraft.Specs.Battery.Chem; % NMC = 1, LFP = 2

years_data = [2023, 2026, 2030, 2035]'; % [1]

% Choose the corresponding BMS portion for desired battery chem (if BMS is
% considered or not)
if BMS == 1

    if BattType == 1
    
        bms_nm  = [2, 2.2, 3, 3.5]';  % [1]
        coeffs_nm  = polyfit(years_data, bms_nm,  1);
        BMS_lambda = polyval(coeffs_nm, Year);%   For Ni/Mn (NMC), in %

    elseif BattType == 2
    
        bms_lfp = [2.2, 3.1, 3.5, 2.6]';  % [1]
        coeffs_lfp = polyfit(years_data, bms_lfp, 2); 
        BMS_lambda = polyval(coeffs_lfp, Year);%   For LFP, in %
    
    else
        error('Invalid ChemType input. Please input "1" for NMC or "2" for LFP.');
    end

elseif BMS == 0 % If user don't consider BMS cost portion
    BMS_lambda = 0;
else
    error('Invalid BMS requirement. Please input "1" for YES or "2" for NO.');
end

%% Unit Capacity Cost of the Battery [$/kWh] Model %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Choose the corresponding BMS portion for desired battery chem (if BMS is
% considered or not)

if BattType == 1

    % NMC costs
    cost_nm  = [127.61; 112.42; 96.52; 76.35];
    coef_nm1  = polyfit(years_data, cost_nm,  2);
    C_E_rep = polyval(coef_nm1, Year);%   For Ni/Mn (NMC), in %

elseif BattType == 2

    % LFP costs
    cost_lfp = [120.91;  97.56;  82.73;  76.62];
    coef_lfp1  = polyfit(years_data, cost_lfp, 3);
    C_E_rep = polyval(coef_lfp1, Year);%   For LFP, in %

else
    error('Invalid ChemType input. Please input "1" for NMC or "2" for LFP.');
end


%% Battery Rated Capacity %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SpecEnergy = Aircraft.Specs.Power.SpecEnergy.Batt / 3600 / 1000; % J -> Wh/kg -> kWh/kg
BattWeight = Aircraft.Specs.Weight.Batt; % Battery Weight in kg
E_rat = SpecEnergy * BattWeight; % Battery Rated Capacity in [kWh]


%% Discount Rate %%
%%%%%%%%%%%%%%%%%%%

DiscRate = 0.07; % [3] 

%% Final Battery Replacement Model %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

C_rep = (1 + BMS_lambda/100) * C_E_rep * E_rat / (1+DiscRate)^Lifespan;

end



%% Reference
% [1] Knehr, Kevin, Joseph Kubal, and Shabbir Ahmed. 0motive lithium-ion batteries. No.
% ANL/CSE-24/1. Argonne National Laboratory (ANL), Argonne, IL (United
% States), 2024.   ------ Table 29, Page 44

% [2] Chen, Z., Li, Z., & Chen, G. (2023). Optimal configuration and
% operation for user-side energy storage considering lithium-ion battery
% degradation. International Journal of Electrical Power & Energy Systems,
% 145, 108621.

% [3] He, G., Ciez, R., Moutis, P., Kar, S., & Whitacre, J. F. (2020). The
% economic end of life of electrochemical energy storage. Applied Energy,
% 273, 115151.