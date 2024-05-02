function [Aircraft] = ResizeBattery(Aircraft)
%
% [Aircraft] = ResizeBattery(Aircraft)
% originally written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 06 mar 2024
%
% After an aircraft flies a mission, update its battery size based on the
% following:
%     (1) if the final SOC is < 20%, increase the battery's size.
%     (2) if the final SOC is < 23%, decrease the battery's size.
%     (3) if battery discharges too quickly, increase its size.
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


%% INTERNALLY-PRESCRIBED PARAMETERS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% scale factor if SOC must be increased
ScaleSOC   = 1.01;

% scale factor if c-rate must be increased
ScaleCRate = 1.10;

% scale factor to downsize the battery
ScaleDown  = 0.99;

% acceptable SOC threshold
MinSOC = 20; 
MaxSOC = 23;

% maximum extracted capacity and voltage
QMax = 2.6; % Ah
VMax = 3.6; % V


%% INFO FROM THE AIRCRAFT STRUCTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% battery parameters         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% battery specific energy
ebatt = Aircraft.Specs.Power.SpecEnergy.Batt;

% number of cells in series and parallel
ParCells = Aircraft.Specs.Power.Battery.ParCells;
SerCells = Aircraft.Specs.Power.Battery.SerCells;

% find index associated with a battery
Batt = Aircraft.Specs.Propulsion.PropArch.ESType == 0;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% mission history            %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% SOC during flight
SOC = Aircraft.Mission.History.SI.Power.SOC(:, Batt);

% power consumed during flight
Pbatt = Aircraft.Mission.History.SI.Power.P_ES(:, Batt);

% energy consumed during flight
Ebatt = Aircraft.Mission.History.SI.Energy.E_ES(:, Batt);


%% CHECK IF SOC IS BELOW MINIMUM THRESHOLD %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume no energy needs to be added
E_add_soc = 0;

% find the first SOC that falls below the minimum threshold
FailSOC = find(SOC < MinSOC, 1);

% check if the SOC is too small
if (any(FailSOC))
        
    % add the extra energy needed
    E_add_soc = ScaleSOC * abs(Ebatt(end) - Ebatt(FailSOC));
    
end


%% CHECK IF DISCHARGE RATE (C-RATE) IS TOO HIGH %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume a maximum c-rate
MaxCRate = 5;

% get the energy consumed by the battery during each segment
dEbatt = diff(Ebatt);

% compute the C-rate (power in segment / energy consumed in segment)
C_rate = Pbatt(1:end-1) ./ dEbatt;

% check if the C-rate is exceeded
ExceedCRate = abs(C_rate) > MaxCRate;

% assume no energy needs to be added
E_add_crate = 0;

% check if the c-rate exceeds the maximum c-rate
if  any(ExceedCRate) 

    % find largest power requirement when c-rate is exceeded
    PbattMax = max(Pbatt(ExceedCRate));
    
    % add more energy to the battery
    E_add_crate = ScaleCRate .* PbattMax ./ MaxCRate;
    
end


%% UPDATE THE BATTERY'S SIZE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% assume number of cells in parallel remains the same (could change)
ParCellsNew = ParCells;

% check which case limits the battery's size
if E_add_soc > E_add_crate
    
    % adjust the charge stored in the battery
    Q_max_new = ParCells * QMax * (1 + (MinSOC - SOC(end)) / 100) * ScaleSOC;
    
    % adjust the battery's power 
    ParCellsNew = ceil(ParCells * Q_max_new / (ParCells * QMax));
    
elseif  E_add_soc < E_add_crate
    
    % adjust the battery's voltage
    V_new = SerCells * VMax * (max(C_rate) / MaxCRate) * ScaleCRate;
        
end

% figure out how much energy must be added to the battery
E_add = max(E_add_soc, E_add_crate);

% compute the new battery weight
WbattNew = VMax * SerCells * QMax * ParCells * 3600 / ebatt;


%% CHECK IF THE MAXIMUM SOC THRESHOLD IS EXCEEDED %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check the final SOC
if (SOC(end) > MaxSOC)
    
    % store less energy in the battery
    E_new = Ebatt(end) * (1 - ((SOC(end) - MinSOC) / 100)) * ScaleDown;
    
    % adjust the battery's power
    ParCellsNew = ceil(ParCells * E_new / Ebatt(end));
    
    % adjust the battery's weight
    WbattNew = VMax * SerCells * QMax * ParCells * 3600 / ebatt;
    
end


%% CHECK IF FINAL SOC IS IN ACCEPTABLE THRESHOLD %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check the final SOC
if ((SOC(end) < MaxSOC) && ...
    (SOC(end) > MinSOC) )

    % adjust the battery's weight
    WbattNew = VMax * SerCells * QMax * ParCells * 3600 / ebatt;
    
    % adjust the battery's power
    ParCellsNew = ParCells;
    
end


%% REMEMBER THE NEW BATTERY SIZE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% remember the cells in parallel
Aircraft.Specs.Power.Battery.ParCells = ParCellsNew;

% remember the battery weight
Aircraft.Specs.Weight.Batt = WbattNew;

% ----------------------------------------------------------

end