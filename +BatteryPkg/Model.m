function [Voltage, Pout, Capacity, SOC] = Model(Preq, Time, SOCBeg, Parallel, Series)
%
% [Voltage, Pout, Capacity, SOC] = Model(Preq, Time, SOCBeg, Parallel, Series)
% written by Sasha Kryuchkov
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 mar 2024
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

% exponential voltage [V]
A = Series * 0.311;

% exponential capacity [(Ah)^-1]
B = Parallel * 3 / 0.1277;

% constant voltage [V]
E0 = Series * 3.889;

% Nominal voltage [V]
E_nom = Series * 3.6;

% nominal capacity [Ah]
Q_nom = Parallel * 2.351;

% internal resistance [Ohms]
R = 0.01385;

% maximum capacity
Q = Parallel * 2.6;

% Calculate the drawn current [A] - initial guess 
current = Preq ./ E0;

% Calculate the extracted capacity [Ah].
QExt = Time .* current;

% Calculate the polarization constant/resistance [Ohms] The absolute value 
% is there to prevent from Q_act become a negative value when the battery
% is charging.
K = (-E_nom + E0 + A * exp(-B * Q_nom) * (Q - Q_nom)) ./ ...
    (Q * (Q_nom + abs(current)));

% Pre-allocate the output vectors depending on the vector length
Voltage = zeros(ntime,1);
SOC = zeros(ntime,1);
Capacity = zeros(ntime,1);
Pout = zeros(ntime,1);

% remember the initial charge as a function of time
Q_act_i = Q - SOCBeg / 100 * Q;

% calculate the initial discharge voltage
VInit = E0 - R * current(1) - ...
                  K(1) .* Q ./ (Q - Q_act_i) * current(1) - ...
                  K(1) .* Q ./ (Q - Q_act_i) + ...
                  A .* exp(-B .* Q_act_i);

% get a cumulative sum of the charge consumed
Q_consumed = cumsum(QExt);
              
% begin the loop over the length of the vectors
for frame = 1:ntime
    
    % check if charging (current < 0) or discharging (current >= 0)
    if current(frame) >= 0
        
        % calculate the final discharge voltage
        Voltage(frame) = E0 - R * current(frame) - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) * current(frame) - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) + ...
        A .* exp(-B .* Q_consumed(frame));
        
        % calculate the final SOC
        SOC(frame) = SOCBeg - 100 * Q_consumed(frame) / Q;
        
        % calculate the capacity left from the discharge
        Capacity(frame) = Q - Q_consumed(frame);
        
        % Calculate the average power
        Pavg = (VInit + Voltage(frame)) / ...
                    2 * current(frame);
        
        % calculate the final current with the average power and final
        % voltage
        current_final = Pavg / Voltage(frame);
        
        % calculate the final voltage with the new current
        Voltage(frame) = E0 - R * current_final - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) * current_final - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) + ...
        A .* exp(-B .* Q_consumed(frame));
        
        % calculate the required power using the new final voltage and
        % the final current
        Pav = Voltage(frame) * current_final;
        
        % Check the required power against the power in the function
        % input
        if (Pav > Preq(frame))
            Pout(frame) = Preq(frame);
            
        elseif (Pav < Preq(frame))
            Pout(frame) = Pav;
            
        end
        
        % Calculate what the next inital voltage is
        VInit = Voltage(frame);
        
    elseif current(frame) < 0
        
        % calculate the charge voltage
        Voltage(frame) = E0 + R * current(frame) - ...
        K(frame) .* Q ./ (Q_consumed(frame) + 0.1 * Q) * current(frame) - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) .* Q_consumed(frame) + ...
        A .* exp(B .* Q_consumed(frame));
        
        % calculate the final SOC
        SOC(frame) = SOCBeg - 100 * Q_consumed(frame) / Q;
        
        % calculate the capacity left
        Capacity(frame) = Q - Q_consumed(frame);
        
        % Calculate the average power
        Pavg = (VInit + Voltage(frame)) / ...
                    2 * current(frame);
        
        % calculate the final current with the average power and final
        % voltage
        current_final = Pavg / Voltage(frame);
        
        % calculate the final voltage with the new current
        Voltage(frame) = E0 - R * current_final - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) * current_final - ...
        K(frame) .* Q ./ (Q - Q_consumed(frame)) + ...
        A .* exp(B .* Q_consumed(frame));
        
        % calculate the required power using the new final voltage and
        % the final current
        Pav = Voltage(frame) * current_final;
        
        % Check the required power against the power in the function
        % input
        if (Pav > Preq(frame))
            Pout(frame) = Preq(frame);
            
        elseif (Pav < Preq(frame))
            Pout(frame) = Pav;
            
        end
        
        % Calculate what the next inital voltage is
        VInit = Voltage(frame);
        
    end
end

% ----------------------------------------------------------

end