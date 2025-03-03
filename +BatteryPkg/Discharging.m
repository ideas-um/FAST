function [Voltage, Current, Pout, Capacity, SOC, C_rate] = Discharging(Aircraft, Preq, Time, SOCBeg, Parallel, Series)
%
% [Voltage, Pout, Capacity, SOC] = Model(Preq, Time, SOCBeg, Parallel, Series)
% originally written by Sasha Kryuchkov
% overhauled by Paul Mokotoff, prmoko@umich.edu
% last updated: 10 jul 2024
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
%     C_rate   - Rate of (dis)charge. 
%                size/type/units: n-by-1 / double / [C]


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


%% BATTERY QUANTITIES FOR A LITHIUM ION CELL %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Max cell voltage [V]
VoTemp = Aircraft.Specs.Battery.MaxExtVolCell; % 4.0880V

% internal resistance [Ohm]
ResistanceTemp = Aircraft.Specs.Battery.IntResist;

% compute the number of cells in the battery pack
ncell = Series * Parallel;

% exponential voltage [V]
A = Aircraft.Specs.Battery.expVol;

% exponential capacity [(Ah)^-1]
B = Aircraft.Specs.Battery.expCap;

% Determine maximum capacity [Ah] based on analysis type and degradation effect
if Aircraft.Settings.Analysis.Type < 0 && Aircraft.Settings.Degradation == 1

    % Off-design analysis with battery degradation effect
    Q = Aircraft.Specs.Battery.CapCell * Aircraft.Specs.Battery.SOH(end) / 100;
else
    
    % Either on-design analysis or off-design without degradation effect
    Q = Aircraft.Specs.Battery.CapCell;
end


% discharge curve slope (taken from E-PASS)
DischargeCurveSlope = 0.29732;

% compute the polarization voltage (taken from E-PASS)
PolarizedVoTemp = 0.0011;


%% MODEL BATTERY DISCHARGING %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the SOC
SOC      = repmat(SOCBeg, ntime, 1);
Current  = zeros(         ntime, 1);
Capacity = zeros(         ntime, 1);
Voltage  = zeros(         ntime, 1);
Pout     = zeros(         ntime, 1);
C_rate   = zeros(         ntime, 1);
% loop through all points
for itime = 1:ntime
    
    % compute the power required per cell
    TVreq_es_cell = Preq(itime) ./ ncell;
    
    % compute the initial discharged capacity
    DischargedCapacityStart = (1 - (SOC(itime) / 100)) .* Q;
        
    if (Preq >= 0)
        
        % compute the hot cell voltage
        VoltageCellHot = -(PolarizedVoTemp ./ (SOC(itime) / 100) + ResistanceTemp);
        
    else
        
        % compute the hot cell voltage
        VoltageCellHot = PolarizedVoTemp ./ ((DischargedCapacityStart + 0.1 * Q) ./ Q) + ResistanceTemp;
        
    end
        
    % compute the cold cell voltage
    VoltageCellCold = VoTemp + (A .* exp(-B .* DischargedCapacityStart) - PolarizedVoTemp .* DischargedCapacityStart ./ (SOC(itime) / 100) ...
        - DischargeCurveSlope .* DischargedCapacityStart);
    
    % solve the polynomial to find the minimum current
    CurrBattPoly = [VoltageCellHot, VoltageCellCold, -TVreq_es_cell];
    
    % find the root
    CurrBatt = roots(CurrBattPoly);
    
    if (Preq >= 0)
        
        % check if the current is less than 0
        CurrBatt(CurrBatt < 0) = NaN;
        
        % minimize the current
        CurrBatt = min(CurrBatt, [], 1);
        
    else
        
        % check if the current is greater than 0
        CurrBatt(CurrBatt > 0) = NaN;
        
        % maximize the current (because it is negative)
        CurrBatt = max(CurrBatt, [], 1);
        
    end
        
    % check for NaN
    CurrBatt(isnan(CurrBatt)) = 0;
    
    % check for any imaginary currents
    if (any(~isreal(CurrBatt)))
        
        if (Preq >= 0)
            
            % get the 2-norm (magnitude) of the complex current (initial guess)
            CurrBatt = norm(CurrBatt);
            
        else
            
            % get the 2-norm (magnitude) of the complex current (initial guess)
            CurrBatt = -norm(CurrBatt);
            
        end
        
        % assume a range of currents
        CurrBattTemp = CurrBatt - 10 : 0.1 : CurrBatt + 10;
        
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
    Capacity(itime) = Q * SOC(itime) / 100 * Parallel;
    
    % check if capacity is exceed (Q * Parallel is the max capacity a battery pack can have)
    if (Capacity(itime) > (Q * Parallel))
        Capacity(itime) = (Q * Parallel);
    end

    % compute the power output
    Pout(itime) = Voltage(itime) * Current(itime);
    
    % compute the c-rate
    C_rate(itime) = Current(itime) ./ (Q * Parallel);
end

% remove the first SOC value
SOC(1) = [];



% ----------------------------------------------------------

end