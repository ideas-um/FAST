function TestTakeoffPowerRequired()
%
% Test finite power for the prescribed simplified takeoff trajectory.
%


%% ENERGY CONSERVATION %%
%%%%%%%%%%%%%%%%%%%%%%%%

Mass = repmat(1000, 4, 1);
TAS = [0; 20; 40; 60];
Time = [0; 20; 40; 60];

Preq = MissionSegsPkg.TakeoffPowerRequired(Mass, TAS, Time);
EnergyFromPower = sum(Preq(1:end-1) .* diff(Time));
EnergyRequired = 0.5 * Mass(end) * TAS(end) ^ 2;

assert(all(isfinite(Preq)));
assert(abs(EnergyFromPower - EnergyRequired) < 1.0e-09);


%% INVALID TIME HISTORY %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

FailedAsExpected = false;
try
    MissionSegsPkg.TakeoffPowerRequired(Mass, TAS, [0; 20; 20; 60]);
catch
    FailedAsExpected = true;
end
assert(FailedAsExpected);

fprintf("Takeoff required-power tests passed.\n");

% ----------------------------------------------------------

end
