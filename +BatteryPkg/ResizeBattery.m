function [Aircraft] = ResizeBattery(Aircraft)
%
% [Aircraft] = ResizeBattery(Aircraft)
% originally written by Sasha Kryuchkov
% overhauled by Paul Mokotoff, prmoko@umich.edu
% last updated: 12 nov 2024
%
% After an aircraft flies a mission, update its battery size. If a "simple"
% battery model is used (not considering cells in series and parallel),
% then only the battery weight is updated based on the energy required 
% during the flight. If a "detailed" battery model is used (considers cells
% in series and parallel), the number of cells in the battery is also
% updated based on the final state of charge and the assumed maximum
% C-rate.
%
% INPUTS:
%     Aircraft - aircraft structure containing the mission just flown.
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft structure with the updated battery weight and
%                number of cells in the battery.
%                size/type/units: 1-by-1 / struct / []
%


%% GET INFO FROM THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% find index associated with a battery
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

% if there is no battery, return a zero battery weight
if (all(~Batt, "all"))
    
    % return zero battery weight
    Aircraft.Specs.Weight.Batt = 0;
    
    % exit the function
    return
    
end

% battery specific energy
ebatt = Aircraft.Specs.Power.SpecEnergy.Batt;

% energy consumed during flight
Ebatt = Aircraft.Mission.History.SI.Energy.E_ES(:, Batt); 

% energy remaining during flight
Ebatt_re = Aircraft.Mission.History.SI.Energy.Eleft_ES(:, Batt); 


%% RESIZE THE BATTERY %%
%%%%%%%%%%%%%%%%%%%%%%%%

% first, size the battery based on energy demand
Aircraft.Specs.Weight.Batt = Ebatt(end, :) ./ ebatt;

% check if number of battery cells must be updated
if (Aircraft.Settings.DetailedBatt == 1)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % assumed constants          %
    % (to be enhanced in future) %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % maximum extracted capacity and voltage
    QMax = 2.6; % Ah
    VMax = 3.6; % V

    % acceptable SOC threshold
    MinSOC = 20;
    
    % assume a maximum c-rate
    MaxAllowCRate = 5;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % get additional information %
    % from aircraft structure    %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    % get the number of cells in series and in parallel
    Nser = Aircraft.Specs.Power.Battery.SerCells;
    Npar = Aircraft.Specs.Power.Battery.ParCells;
    
    % SOC during flight
    SOC = Aircraft.Mission.History.SI.Power.SOC(:, Batt);
    
    % power consumed during flight
    Pbatt = Aircraft.Mission.History.SI.Power.P_ES(:, Batt);

    % Current curing flight
    Cbatt = Aircraft.Mission.History.SI.Power.Current(:, Batt);
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check that the minimum SOC %
    % threshold is matched (i.e. %
    % the battery is neither     %
    % over/under-sized wrt SOC)  %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    % find the maximum SOC difference for resizing the battery
    DeltaSOC = max(MinSOC - SOC);
    
    % if a value is negative, min. SOC not surpassed - no SOC change needed
    DeltaSOC(DeltaSOC < 0) = 0;
    
    % indices for the number of batteries
    ibatt = 1:sum(Batt);
    
    % identify if the battery is too large
    TooLarge = ibatt(DeltaSOC == 0);
    
    % compute the SOC to reduce the battery size and convert to a fraction
    DownsizeTo = -(min(SOC) - MinSOC) / 100;
    
    % modify the change in SOC needed
    DeltaSOC(TooLarge) = DownsizeTo(TooLarge);
        
    % compute the total capacity of the existing battery pack
    ExistBattCap = QMax * Npar;
    
    % update number of cells in parallel (assume 1 cell per module, ./ Qmax is for aged cell capacity in EPASS, ./ 1 is for number of cells in parallel per module)
    NparSOC = ceil(ceil((ExistBattCap + DeltaSOC .* QMax .* Npar) ./ QMax) ./ 1);
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % check that the C-rate is   %
    % not exceeded (i.e., the    %
    % battery is not discharged  %
    % too rapidly)               %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % get the energy consumed by the battery during each segment
    dEbatt = diff(Ebatt);
    
    % compute the C-rate (power in segment / energy consumed in segment)
    % C_rate = Pbatt(1:end-1) ./ (dEbatt);
    % C_rate = Aircraft.Mission.History.SI.Power.C_rate; 
    C_rate = Cbatt ./ (ExistBattCap); 
    % C_rate = Pbatt(1:end-1) / (Ebatt_re(Batt)/3600); 
    % C_rate = Pbatt(1:end-1) / (ExistBattCap * VMax * Nser); 


    % ignore all NaNs (set to 0)
    C_rate(isnan(C_rate)) = 0;
    
    % check if the C-rate is exceeded
    ExceedCRate = abs(C_rate) > MaxAllowCRate;

    % resize the battery if the C-rate is exceeded
    if (any(ExceedCRate))
        
        % get the maximum C-rate
        MaxCrate = max(abs(C_rate));
        
        % get the required number of cells in parallel
        NparCrate = ceil(MaxCrate / MaxAllowCRate) * Npar;
        
    else
        
        NparCrate = 0;
        
    end
    % ------------------------------------------------------
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % get the new battery cell   %
    % configuration and compute  %
    % its new weight             %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % remember the new number of cells in parallel
    Npar = max(NparSOC, NparCrate);
    
%     % compute the number of battery cells (from E-PASS, not used)
%     Ncells = Npar * Nser;
% 
%     % compute the required capacity (from E-PASS, not used)
%     Qreq = Npar * QMax;
    
    % compute the mass of the battery (multiply by 3600 to convert from hr to seconds)
    Wbatt = QMax * Npar * VMax * Nser * 3600 ./ ebatt;
    
    % ------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % store the newly sized      %
    % battery in the aircraft    %
    % structure                  %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % remember the new battery size
    Aircraft.Specs.Weight.Batt = Wbatt;

    % remember the new cell arrangement
    Aircraft.Specs.Power.Battery.ParCells = Npar;

    % remember the battery c-rates arrangement
    % Aircraft.Mission.History.SI.Power.C_rate_2 = C_rate(:);
end

% ----------------------------------------------------------

end