function Preq = TakeoffPowerRequired(Mass, TAS, Time)
%
% Preq = TakeoffPowerRequired(Mass, TAS, Time)
%
% Compute the interval-average power required to follow a prescribed
% takeoff speed history. The simplified takeoff segment currently models
% only kinetic-energy change, so this function does not include rolling
% resistance or aerodynamic drag.
%
% INPUTS:
%     Mass - aircraft mass at each takeoff control point, kg.
%     TAS  - true airspeed at each takeoff control point, m/s.
%     Time - elapsed time at each takeoff control point, s.
%
% OUTPUTS:
%     Preq - average power required over each interval, W. The final value
%            repeats the last interval because segment energy integration
%            uses all points except the last.
%


%% COMPUTE REQUIRED POWER %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ((length(Mass) ~= length(TAS)) || (length(TAS) ~= length(Time)))
    error("ERROR - TakeoffPowerRequired: Mass, TAS, and Time must have equal lengths.");
end

if (length(Time) < 2)
    error("ERROR - TakeoffPowerRequired: at least two control points are required.");
end

if (any(diff(Time) <= 0))
    error("ERROR - TakeoffPowerRequired: Time must be strictly increasing.");
end

KE = 0.5 .* Mass .* TAS .^ 2;
Preq = diff(KE) ./ diff(Time);
Preq = [Preq; Preq(end)];

% ----------------------------------------------------------

end
