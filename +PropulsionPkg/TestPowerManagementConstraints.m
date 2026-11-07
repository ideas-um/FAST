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


%% FULL-POWER SUPPLIED SPLIT CONSTRAINTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The recomputed 20% electric allocation exactly matches the parallel
% components' 80/20 kW capacities. A 90% electric command overloads each
% 20 kW motor by 70 kW while leaving the mission calculation untouched.
Aircraft.Mission.Profile.SegsID = 1;
Pav = Aircraft.Mission.History.SI.Power.Pav;

[ComponentPower, PowerDeficit] = ...
    PropulsionPkg.FullPowerLambdaConstraints(Aircraft, Pav, 0.20, 1);
assert(max(abs(ComponentPower), [], "all") < 1.0e-12);
assert(abs(PowerDeficit) < 1.0e-12);

[ComponentPower, PowerDeficit] = ...
    PropulsionPkg.FullPowerLambdaConstraints(Aircraft, Pav, 0.90, 1);
assert(all(abs(ComponentPower([5, 6]) - 70) < 1.0e-12));
assert(abs(PowerDeficit - 70) < 1.0e-12);

fprintf("Full-power supplied-lambda constraint tests passed.\n");


%% REPEATED PARALLEL ENGINE GROUPS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% One engine may supplement several downstream components, with a different
% number of electric motors at each target. Each target must remain a separate
% group; combining rows by engine caused the historical vertcat/horzcat crash.
GroupAircraft.Specs.Propulsion.PropArch.SrcType = 1;
GroupAircraft.Specs.Propulsion.PropArch.TrnType = [1, 0, 0, 3, 3, 3];
GroupAircraft.Specs.Propulsion.PropArch.Arch = zeros(7);
GroupAircraft.Specs.Propulsion.PropArch.Arch(2, 5) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(3, 5) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(2, 6) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(3, 6) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(4, 6) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(2, 7) = 1;
GroupAircraft.Specs.Propulsion.PropArch.Arch(3, 7) = 1;
GroupAircraft.Specs.Propulsion.PropArch.OperUps = zeros(7);
GroupAircraft.Specs.Propulsion.PropArch.OperUps(2, [5, 6, 7]) = [0.5, 0.25, 0.25];
GroupAircraft.Specs.Propulsion.PropArch.OperUps(3, [5, 6, 7]) = [0.2, 0.3, 0.5];
GroupAircraft.Specs.Propulsion.PropArch.OperUps(4, 6) = 1;
GroupAircraft.Specs.Propulsion.PropArch.OperDwn = zeros(7);
GroupAircraft.Specs.Propulsion.PropArch.OperDwn(5, [2, 3]) = [40 / 44, 4 / 44];
GroupAircraft.Specs.Propulsion.PropArch.OperDwn(6, [2, 3, 4]) = [20 / 36, 6 / 36, 10 / 36];
GroupAircraft.Specs.Propulsion.PropArch.OperDwn(7, [2, 3]) = [20 / 30, 10 / 30];
GroupAircraft.Specs.Propulsion.PropArch.EtaUps = ones(7);
GroupAircraft = PropulsionPkg.PropArchConnections(GroupAircraft);

Groups = GroupAircraft.Specs.Propulsion.PropArch.ParConns;
assert(length(Groups) == 3);
assert(isequal([Groups.Target], [5, 6, 7]));
assert(isequal(Groups(1).Helping, 3));
assert(isequal(Groups(2).Helping, [3, 4]));
assert(isequal(Groups(3).Helping, 3));

GroupAircraft.Specs.Power.LamDwn.SLS = [];
GroupAircraft.Mission.History.SI.Power.Pav = [0, 80, 20, 10, 0, 0, 0];
GroupAircraft.Mission.History.SI.Power.LamUps = 1;
GroupAircraft.Mission.History.SI.Power.LamDwn = zeros(1, 0);
GroupAircraft = PropulsionPkg.RecomputeSplits(GroupAircraft, 1, 1);
assert(isempty(GroupAircraft.Mission.History.SI.Power.LamDwn));

[ComponentPower, PowerDeficit] = PropulsionPkg.FullPowerLambdaConstraints( ...
    GroupAircraft, GroupAircraft.Mission.History.SI.Power.Pav, zeros(1, 0), 1);
assert(all(isfinite(ComponentPower), "all"));
assert(max(abs(ComponentPower), [], "all") < 1.0e-12);
assert(abs(PowerDeficit) < 1.0e-12);

% A 50/50 command at the first target requests 22 kW from a motor with only
% 4 kW routed there. The residual must use routed, not full component power.
Overloaded = GroupAircraft;
Overloaded.Specs.Propulsion.PropArch.OperDwn(5, [2, 3]) = [0.5, 0.5];
[ComponentPower, PowerDeficit] = PropulsionPkg.FullPowerLambdaConstraints( ...
    Overloaded, Overloaded.Mission.History.SI.Power.Pav, zeros(1, 0), 1);
assert(abs(ComponentPower(3) - 18) < 1.0e-12);
assert(abs(PowerDeficit - 18) < 1.0e-12);

fprintf("Repeated parallel engine-group tests passed.\n");


%% PROPULSIVE SUPPLEMENT TARGETS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% An engine and motor may both drive an intermediate generator, while a
% different motor supplements the engine at the fan. The intermediate motor
% changes only the generator's input allocation; only the fan motor may be
% credited as propulsive assistance in the engine model.
TrnType = [1, 0, 0, 3, 2];
Arch = zeros(5);
Arch(1, 4) = 1;
Arch(2, 4) = 1;
Arch(1, 5) = 1;
Arch(3, 5) = 1;
Lambda = zeros(5);
Lambda(4, 1) = 0.6;
Lambda(4, 2) = 0.4;
Lambda(5, 1) = 0.7;
Lambda(5, 3) = 0.3;
Eta = ones(5);
Preq = [100, 20, 30, 50, 100];
EtaFan = 0.9;

Psupp = PropulsionPkg.PowerSupplementCheck( ...
    Preq, Arch, Lambda, Eta, TrnType, EtaFan);

% The engine loses 30 kW to its routed generator load and receives 27 kW
% of fan assistance. The 20 kW intermediate motor must not add another
% artificial 18 kW credit.
assert(abs(Psupp(1) + 3) < 1.0e-12);
assert(max(abs(Psupp(2:end))) < 1.0e-12);

fprintf("Propulsive supplement target tests passed.\n");

% ----------------------------------------------------------

end
