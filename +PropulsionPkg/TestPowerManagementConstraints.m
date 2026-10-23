function TestPowerManagementConstraints()
%
% Test analytical supplied-lambda power-management constraint cases.
%


%% FEASIBLE ALLOCATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%

% Two sources feed an engine and motor that jointly satisfy a 90 kW sink
% requirement. A 15% electric split is feasible for 80/20 kW ratings.
Preq = [0, 0, 76.5, 13.5, 90];
Pav  = [0, 0, 80.0, 20.0, 100];
[ComponentPower, PowerDeficit] = PropulsionPkg.PowerManagementConstraints( ...
                                    Preq, Pav, 3:5);

assert(abs(ComponentPower(3) + 3.5) < 1.0e-12);
assert(abs(ComponentPower(4) + 6.5) < 1.0e-12);
assert(PowerDeficit <= 0);


%% INFEASIBLE ALLOCATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% A 50% electric split requests 45 kW from a 20 kW motor. The supplied
% split is not repaired; the positive 25 kW residual exposes infeasibility.
Preq = [0, 0, 45, 45, 90];
[ComponentPower, PowerDeficit] = PropulsionPkg.PowerManagementConstraints( ...
                                    Preq, Pav, 3:5);

assert(abs(ComponentPower(4) - 25) < 1.0e-12);
assert(abs(PowerDeficit - 25) < 1.0e-12);


%% MAXIMUM-POWER ALLOCATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% At 100 kW total power, the 80/20 kW ratings require exactly a 20%
% electric split. Neighboring allocations overload opposite components.
Pav = [0, 0, 80, 20, 100];

Preq = [0, 0, 80, 20, 100];
[~, PowerDeficit] = PropulsionPkg.PowerManagementConstraints(Preq, Pav, 3:5);
assert(abs(PowerDeficit) < 1.0e-12);

Preq = [0, 0, 81, 19, 100];
[~, PowerDeficit] = PropulsionPkg.PowerManagementConstraints(Preq, Pav, 3:5);
assert(abs(PowerDeficit - 1) < 1.0e-12);

Preq = [0, 0, 79, 21, 100];
[~, PowerDeficit] = PropulsionPkg.PowerManagementConstraints(Preq, Pav, 3:5);
assert(abs(PowerDeficit - 1) < 1.0e-12);


%% INVALID INPUTS %%
%%%%%%%%%%%%%%%%%%%%

FailedAsExpected = false;
try
    PropulsionPkg.PowerManagementConstraints(zeros(1, 2), zeros(1, 3), 1);
catch
    FailedAsExpected = true;
end
assert(FailedAsExpected);

fprintf("Power-management constraint tests passed.\n");


%% LEGACY SPLIT RECOMPUTATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Confirm the existing mode still derives the PHE split from available
% engine and motor power. SupplyLambda bypasses this call at the segment
% level, leaving the requested value unchanged for constraint evaluation.
Aircraft = AircraftSpecsPkg.ERJ175LR_Elec();
Aircraft = PropulsionPkg.CreatePropArch(Aircraft);
Aircraft = PropulsionPkg.PropArchConnections(Aircraft);

ncomp = length(Aircraft.Specs.Propulsion.PropArch.Arch);
Aircraft.Mission.History.SI.Power.Pav = zeros(1, ncomp);
Aircraft.Mission.History.SI.Power.Pav([3, 4]) = [80, 80];
Aircraft.Mission.History.SI.Power.Pav([5, 6]) = [20, 20];
Aircraft.Mission.History.SI.Power.LamUps = 1;
Aircraft.Mission.History.SI.Power.LamDwn = 0.73;

LegacyAircraft = PropulsionPkg.RecomputeSplits(Aircraft, 1, 1);
assert(abs(LegacyAircraft.Mission.History.SI.Power.LamDwn - 0.20) < 1.0e-12);
assert(abs(Aircraft.Mission.History.SI.Power.LamDwn - 0.73) < 1.0e-12);

fprintf("Legacy recomputation and supplied-lambda preservation tests passed.\n");

% ----------------------------------------------------------

end
