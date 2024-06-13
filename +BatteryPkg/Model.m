function [Voltage, Current, Pout, Capacity, SOC] = Model(Preq, Time, SOCBeg, Parallel, Series)
%
% [Voltage, Pout, Capacity, SOC] = Model(Preq, Time, SOCBeg, Parallel, Series)
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 13 jun 2024
%
% Model (dis)charging for a Lithium-ion battery.
%
% INPUTS:
%     Preq     - power required by the battery.
%                size/type/units: n-by-1 / double / [W]
%
%     Time     - time to fly between control points.
%                size/type/units: n-by-1 / double / [s]
%
%     SOCi     - initial state of charge.
%                size/type/units: 1-by-1 / double / [%]
%
%     Parallel - number of cells connected in parallel. for a single cell,
%                set this variable to 1.
%                size/type/units: 1-by-1 / integer / []
%
%    Series    - number of cells connceted in series. for a single cell,
%                set this variable to 1.
%                size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     Voltage  - battery voltage as a function of time.
%                size/type/units: n-by-1 / double / [V]
%
%     Pout     - battery output power.
%                size/type/units: n-by-1 / double / [W]
%
%     Capacity - battery charge as a function of time.
%                size/type/units: n-by-1 / double / [Ah]
%
%     SOC      - state of charge as a function of time, between 0% (no
%                charge) and 100% (fully charged).
%                size/type/units: n-by-1 / double / [%]
%


%% PROCESS INPUTS %%
%%%%%%%%%%%%%%%%%%%%

% check input sizes
[npreq, ~] = size(Preq);
[ntime, ~] = size(Time);
[nsocs, ~] = size(SOCBeg);

% check for valid input sizes
if     ((npreq == 1) && (ntime >  1))
    
    % same power requirement for each time step
    Preq = repmat(Preq, ntime, 1);
        
elseif ((npreq >  1) && (ntime == 1))
    
    % same time to fly for each segment
    Time = repmat(Time, npreq, 1);
    
    % update the number of time steps to match number of segments
    ntime = npreq;
    
elseif (npreq ~= ntime)
    
    % throw an error
    error("ERROR - Model: required power and time are different sizes.");
        
end

% initial SOC must be a scalar (or empty)
if     (nsocs >  1)
    
    % throw an error
    error("ERROR - Model: initial SOC must be a scalar or an empty array.");
    
elseif (nsocs == 0)
    
    % assume the battery is fully charged
    SOCBeg = 100;
    
end

% convert the time from seconds to hours (for computing charge used)
Time = Time ./ 3600;


%% BATTERY MODEL %%
%%%%%%%%%%%%%%%%%%%

% nominal cell voltage [V]
VoTemp = 4.0880;%3.6;

% polarization voltage --> currently unknown

% internal resistance [Ohm]
ResistanceTemp = 0.0199;%0.01385;

% SOC Limit --> skip for now, want to omit for sizing

% compute the number of cells in the battery pack
ncell = Series * Parallel;

% exponential voltage [V]
A = 0.0986;%0.311;

% exponential capacity [(Ah)^-1]
B = 30;%3 / 0.1277;

% % constant voltage [V]
% E0 = 3.889;
% 
% % Nominal voltage [V]
% E_nom = 3.6;
% 
% % nominal capacity [Ah]
% Q_nom = 2.351;

% internal resistance [Ohms]
R = 0.01385;

% maximum capacity
Q = 3;%2.6;

% discharge curve slope (taken from E-PASS)
DischargeCurveSlope = 0.29732;

% Calculate the drawn current [A] - initial guess 
% current = Preq ./ E0;

% compute the polarization resistance
% K = (-E_nom + E0 + A * exp(-B * Q_nom) * (Q - Q_nom)) ./ ...
%     (Q * (Q_nom + abs(current)));

% compute the polarization voltage (taken from E-PASS)
PolarizedVoTemp = 0.0011;%K .* current;

% get the SOC
SOC      = repmat(SOCBeg, ntime, 1);
Current  = zeros(ntime, 1);
Capacity = zeros(ntime, 1);
Voltage  = zeros(ntime, 1);
Pout     = zeros(ntime, 1);

% loop through all points
for itime = 1:ntime
    
    % compute the power required per cell
    TVreq_es_cell = Preq(itime) ./ ncell;
    
    % compute the hot cell voltage
    VoltageCellHot = -(PolarizedVoTemp ./ (SOC(itime) / 100) + ResistanceTemp);
    
    % compute the initial discharged capacity
    DischargedCapacityStart = (1 - (SOC(itime) / 100)) .* Q;
    
    % compute the cold cell voltage
    VoltageCellCold = VoTemp + (A .* exp(-B .* DischargedCapacityStart) - PolarizedVoTemp(1) .* DischargedCapacityStart ./ (SOC(itime) / 100) - DischargeCurveSlope .* DischargedCapacityStart);
    
    % solve the polynomial to find the minimum current
    CurrBattPoly = [VoltageCellHot, VoltageCellCold, -TVreq_es_cell];
    
    % find the root
    CurrBatt = roots(CurrBattPoly);
    
    % check if the current is less than 0
    CurrBatt(CurrBatt < 0) = NaN;
    
    % minimize the current
    CurrBatt = min(CurrBatt, [], 1);
    
    % check for NaN
    CurrBatt(isnan(CurrBatt)) = 0;
    
    % check for any imaginary currents
    if (any(~isreal(CurrBatt)))
        
        % get the 2-norm (magnitude) of the complex current (initial guess)
        CurrBatt = norm(CurrBatt);
        
        % assume a range of currents
        CurrBattTemp = [CurrBatt - 10 : 0.1 : CurrBatt + 10];
        
        % compute the cell voltages
        VoltageCellTemp = VoltageCellCold + VoltageCellHot * CurrBattTemp;
        
        % find the current that maximizes the power produced
        [~, idx] = min(abs(TVreq_es_cell - VoltageCellTemp .* CurrBattTemp));
        
        % use the minimized current
        CurrBatt = CurrBattTemp(idx);
        
    end
    
    % compute the total current
    Current(itime) = CurrBatt * Parallel;
    
    % compute the cell voltage
    VoltageCell = VoltageCellCold + VoltageCellHot .* CurrBatt;
    
    % compute the pack voltage
    Voltage(itime) = VoltageCell * Series;
    
    % update the capacity
    DischargedCapacity = CurrBatt * Time(itime);
    
    % update the SOC
    SOC(itime+1) = SOC(itime) - 100 * DischargedCapacity / Q;
    
    % update the capacity
    Capacity(itime) = Q * SOC(itime) / 100 * Series * Parallel;
    
    % compute the power output
    Pout(itime) = Voltage(itime) * Current(itime);
    
end

% remove the first SOC value
SOC(1) = [];

% %% FAST BATTERY MODEL %%
% 
% % exponential voltage [V]
% A = Series * 0.311;
% 
% % exponential capacity [(Ah)^-1]
% B = Parallel * 3 / 0.1277;
% 
% % constant voltage [V]
% E0 = Series * 3.889;
% 
% % Nominal voltage [V]
% E_nom = Series * 3.6;
% 
% % nominal capacity [Ah]
% Q_nom = Parallel * 2.351;
% 
% % internal resistance [Ohms]
% R = 0.01385;
% 
% % maximum capacity
% Q = Parallel * 2.6;
% 
% % Calculate the drawn current [A] - initial guess 
% current = Preq ./ E0;
% 
% % Calculate the extracted capacity [Ah].
% QExt = Time .* current;
% 
% % Calculate the polarization constant/resistance [Ohms] The absolute value 
% % is there to prevent from Q_act become a negative value when the battery
% % is charging.
% K = (-E_nom + E0 + A * exp(-B * Q_nom) * (Q - Q_nom)) ./ ...
%     (Q * (Q_nom + abs(current)));
% 
% % Pre-allocate the output vectors depending on the vector length
% Voltage = zeros(ntime,1);
% SOC = zeros(ntime,1);
% Current = zeros(ntime,1);
% Capacity = zeros(ntime,1);
% Pout = zeros(ntime,1);
% 
% % remember the initial charge as a function of time
% Q_act_i = Q - SOCBeg / 100 * Q;
% 
% % calculate the initial discharge voltage
% VInit = E0 - R * current(1) - ...
%                   K(1) .* Q ./ (Q - Q_act_i) * current(1) - ...
%                   K(1) .* Q ./ (Q - Q_act_i) * current(1) + ...
%                   A .* exp(-B .* Q_act_i);
% 
% % get a cumulative sum of the charge consumed
% Q_consumed = cumsum(QExt);
%               
% % begin the loop over the length of the vectors
% for frame = 1:ntime
%     
%     % check if charging (current < 0) or discharging (current >= 0)
%     if current(frame) >= 0
%         
%         % calculate the final discharge voltage
%         Voltage(frame) = E0 - R * current(frame) - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) * current(frame) - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) * current(frame) + ...
%         A .* exp(-B .* Q_consumed(frame));
%         
%         % calculate the final SOC
%         SOC(frame) = SOCBeg - 100 * Q_consumed(frame) / Q;
%         
%         % calculate the capacity left from the discharge
%         Capacity(frame) = Q - Q_consumed(frame);
%         
%         % Calculate the average power
%         Pavg = (VInit + Voltage(frame)) / ...
%                     2 * current(frame);
%         
%         % calculate the final current with the average power and final
%         % voltage
%         current_final = Pavg / Voltage(frame);
%         
%         % calculate the final voltage with the new current
%         Voltage(frame) = E0 - R * current_final - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) * current_final - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) * current_final + ...
%         A .* exp(-B .* Q_consumed(frame));
%         
%         % calculate the required power using the new final voltage and
%         % the final current
%         Pav = Voltage(frame) * current_final;
%         
%         % Check the required power against the power in the function
%         % input
%         if (Pav > Preq(frame))
%             Pout(frame) = Preq(frame);
%             
%         elseif (Pav < Preq(frame))
%             Pout(frame) = Pav;
%             
%         end
%         
%         % Calculate what the next inital voltage is
%         VInit = Voltage(frame);
%         
%     elseif current(frame) < 0
%         
%         % calculate the charge voltage
%         Voltage(frame) = E0 + R * current(frame) - ...
%         K(frame) .* Q ./ (Q_consumed(frame) + 0.1 * Q) * current(frame) - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) .* Q_consumed(frame) + ...
%         A .* exp(B .* Q_consumed(frame));
%         
%         % calculate the final SOC
%         SOC(frame) = SOCBeg - 100 * Q_consumed(frame) / Q;
%         
%         % calculate the capacity left
%         Capacity(frame) = Q - Q_consumed(frame);
%         
%         % Calculate the average power
%         Pavg = (VInit + Voltage(frame)) / ...
%                     2 * current(frame);
%         
%         % calculate the final current with the average power and final
%         % voltage
%         current_final = Pavg / Voltage(frame);
%         
%         % calculate the final voltage with the new current
%         Voltage(frame) = E0 - R * current_final - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) * current_final - ...
%         K(frame) .* Q ./ (Q - Q_consumed(frame)) + ...
%         A .* exp(B .* Q_consumed(frame));
%         
%         % calculate the required power using the new final voltage and
%         % the final current
%         Pav = Voltage(frame) * current_final;
%         
%         % Check the required power against the power in the function
%         % input
%         if (Pav > Preq(frame))
%             Pout(frame) = Preq(frame);
%             
%         elseif (Pav < Preq(frame))
%             Pout(frame) = Pav;
%             
%         end
%         
%         % Calculate what the next inital voltage is
%         VInit = Voltage(frame);
%         
%     end
% end
% Current = current;
% ----------------------------------------------------------

end