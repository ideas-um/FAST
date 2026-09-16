function [Success] = TestEngineMotorRegressions()
%
% [Success] = TestEngineMotorRegressions()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check gas-turbine and electric-motor accounting on controlled propulsion
% architectures. Include physically consistent split and efficiency cases,
% since arbitrary test matrices can conceal edge-power attribution errors.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - 1 when all 21 checks pass, otherwise 0.
%               size/type/units: 1-by-1 / int / []
%

%% TEST CASE SETUP %%
%%%%%%%%%%%%%%%%%%%%%

% Keep one result per case so a failure identifies the affected behavior.
Pass = false(21, 1);

%% ENGINE TO PROPELLER CONNECTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% one engine driving one propeller
aircraft = PropulsionPkg.ProcessPropArch(makeAircraft([1]));
Pass(1) = isequal(propellerConnections(aircraft, 1), 3);

% one engine driving two propellers must retain both connections
aircraft = PropulsionPkg.ProcessPropArch(makeAircraft([1, 1]));
Pass(2) = isequal(propellerConnections(aircraft, 1), [3, 4]);

% the connection list must also retain a third propeller
aircraft = PropulsionPkg.ProcessPropArch(makeAircraft([1, 1, 1]));
Pass(3) = isequal(propellerConnections(aircraft, 1), [3, 4, 5]);

% separate engines must not acquire each other's propeller
aircraft = PropulsionPkg.ProcessPropArch(makeAircraft([1, 2]));
Pass(4) = isequal(propellerConnections(aircraft, 1), 4) && ...
          isequal(propellerConnections(aircraft, 2), 5);

%% PER ENGINE MOTOR SUPPLEMENTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% different motor shares must produce distinct per-engine supplements
Pass(5) = CheckEngineSupplements(0.2, 0.4);

% reversing the shares must not reuse the first engine's supplement
Pass(6) = CheckEngineSupplements(0.4, 0.2);

%% TARGET EFFICIENCY AND MOTOR CREDIT %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% fan target applies fan efficiency to the motor contribution
Pass(7) = CheckValue(parallelSupplement([1, 0, 2], [0, 10, 0], 0.8), 8);

% generator and cable targets do not incur a fan-efficiency loss
Pass(8) = CheckValue(parallelSupplement([1, 0, 3], [0, 10, 0], 0.8), 10);
Pass(9) = CheckValue(parallelSupplement([1, 0, 4], [0, 10, 0], 0.65), 10);

% contributions from two motors must both be counted at a shared target
Pass(10) = CheckValue(parallelSupplement([1, 0, 0, 3], [0, 7, 11, 0], 0.8), 18);

% unity fan efficiency leaves the motor contribution unchanged
Pass(11) = CheckValue(parallelSupplement([1, 0, 3], [0, 10, 0], 1), 10);

% only one quarter of the first fan's demand comes from the motor
architecture = zeros(4);
architecture(1, 3) = 1;
architecture(2, 3:4) = 1;
splits = zeros(4);
splits(3, 1) = 0.75;
splits(3, 2) = 0.25;
splits(4, 2) = 1;
actual = PropulsionPkg.PowerSupplementCheck([15, 20, 20, 15], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
Pass(12) = CheckValue(actual(1), 4);

% a half-efficient motor path delivers half of its available power
architecture = zeros(3);
architecture(1:2, 3) = 1;
splits = zeros(3);
splits(3, 1:2) = 0.5;
efficiencies = ones(3);
efficiencies(3, 2) = 0.5;
actual = PropulsionPkg.PowerSupplementCheck([10, 20, 20], architecture, splits, efficiencies, [1, 0, 2], 0.8);
Pass(13) = CheckValue(actual(1), 8);

% shared targets must credit each split motor contribution only once
architecture = zeros(4);
architecture(1:2, 3:4) = 1;
splits = zeros(4);
splits(3:4, 1:2) = 0.5;
actual = PropulsionPkg.PowerSupplementCheck([20, 20, 20, 20], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
Pass(14) = CheckValue(actual(1), 16);

%% EDGE-CONSISTENT PARALLEL HYBRIDS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A 50/50 fan demand has 50 W of delivered motor power, or 49.5 W after
% fan efficiency. A downstream split is normalized by fan demand, not by
% motor power; applying it to both quantities would count the split twice.
Pass(15) = CheckValue(consistentParallelSupplement(0.99, 0.99), 49.5);

% The graph's fan-edge efficiency can differ from the engine model's
% EtaFan. Only the latter reduces the delivered motor power again.
Pass(16) = CheckValue(consistentParallelSupplement(0.8, 0.99), 49.5);

% One motor sends 25 W to a 100 W fan and 75 W to a 200 W fan. Their
% downstream shares differ from the motor's 25/75 outgoing allocation.
architecture = zeros(4);
architecture(1:2, 3:4) = 1;
splits = zeros(4);
splits(3, 1:2) = [0.75, 0.25];
splits(4, 1:2) = [0.625, 0.375];
efficiencies = ones(4);
efficiencies(3:4, 1:2) = 0.8;
actual = PropulsionPkg.PowerSupplementCheck( ...
    [250, 125, 100, 200], architecture, splits, efficiencies, [1, 0, 2, 2], 0.99);
Pass(17) = CheckValue(actual(1), 99);

% If two TSEs and one motor feed one fan, silently skipping the motor
% loses 49.5 W of assistance after fan efficiency. The total credit
% should conserve this contribution regardless of its engine allocation.
architecture = zeros(4);
architecture(1:3, 4) = 1;
splits = zeros(4);
splits(4, 1:3) = [0.25, 0.25, 0.5];
efficiencies = ones(4);
efficiencies(4, 1:3) = 0.8;
actual = PropulsionPkg.PowerSupplementCheck( ...
    [31.25, 31.25, 62.5, 100], architecture, splits, efficiencies, [1, 1, 0, 2], 0.99);
Pass(18) = CheckValue(sum(actual(1:2)), 49.5);

%% GRAPH INDEXING AND FULL-THROTTLE SPLITS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% User-supplied graphs need not place engines before motors. Each sized
% engine must assign its inlet area to its own fan in an interleaved graph.
Pass(19) = CheckInterleavedEngineInletAreas();

% One engine can share two different fans with two different motors.
% Full-throttle split recomputation must not assume one common target.
Pass(20) = CheckSeparateParallelTargets();

% A direct engine and an engine connected through a cable can both feed
% one propeller. Finding the direct engine must not hide the indirect one.
Pass(21) = CheckMixedDepthEngineConnections();

%% CHECK THE TEST RESULTS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Success = all(Pass);
if (Success)
    fprintf(1, "EngineMotorRegressions tests passed!\n");
else
    fprintf(1, "EngineMotorRegressions tests failed:\n");
    fprintf(1, "    Test %d\n", find(~Pass));
end

end

function [Pass] = CheckEngineSupplements(firstMotorShare, secondMotorShare)
%
% [Pass] = CheckEngineSupplements(firstMotorShare, secondMotorShare)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Confirm that sizing gives each engine its own electric-motor supplement.
% The supplements must differ enough to expose accidental reuse.
%
% INPUTS:
%     firstMotorShare  - fraction of the first engine target fed by its motor.
%                        size/type/units: 1-by-1 / double / []
%     secondMotorShare - corresponding fraction for the second engine.
%                        size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     Pass             - true if both sized engines receive their own load.
%                        size/type/units: 1-by-1 / logical / []
%

aircraft = makeTwoEngineSizingAircraft(firstMotorShare, secondMotorShare);
aircraft = PropulsionPkg.PropulsionSizing(aircraft);
expected = aircraft.Specs.Propulsion.PowerSupp(1:2);
actual = arrayfun(@(engine) engine.FanSysObject.ElecWork, aircraft.Specs.Propulsion.SizedEngine);
actual = actual(:)';
Pass = abs(diff(expected)) > 1e5 && ...
       isequal(size(actual), size(expected)) && ...
       all(isfinite(actual)) && all(isfinite(expected)) && ...
       all(abs(actual - expected) <= 1e-8 * max(1, abs(expected)));
end

function [Pass] = CheckValue(actual, expected)
%
% [Pass] = CheckValue(actual, expected)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check a finite scalar power contribution within a 1e-10 W tolerance.
%
% INPUTS:
%     actual   - calculated supplemental power.
%                size/type/units: 1-by-1 / double / [W]
%     expected - expected supplemental power.
%                size/type/units: 1-by-1 / double / [W]
%
% OUTPUTS:
%     Pass     - true if the values agree within tolerance.
%                size/type/units: 1-by-1 / logical / []
%

Pass = isscalar(actual) && isfinite(actual) && abs(actual - expected) <= 1e-10;
end

function aircraft = makeTwoEngineSizingAircraft(firstMotorShare, secondMotorShare)
%
% aircraft = makeTwoEngineSizingAircraft(firstMotorShare, secondMotorShare)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Build two otherwise matched engines with independently adjustable motor
% loads. The graph includes two engines, two motors, two fans, and a sink.
%
% INPUTS:
%     firstMotorShare  - fraction of the first fan power from its motor.
%                        size/type/units: 1-by-1 / double / []
%     secondMotorShare - fraction of the second fan power from its motor.
%                        size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     aircraft         - ERJ175LR structure with the test architecture.
%                        size/type/units: 1-by-1 / struct / []
%

aircraft = DataStructPkg.PreSpecProcessing(AircraftSpecsPkg.ERJ175LR());
aircraft = DataStructPkg.SpecProcessing(aircraft);
architecture = zeros(9);
architecture(1, 3:4) = 1;
architecture(2, 5:6) = 1;
architecture(3, 7) = 1;
architecture(5, 7) = 1;
architecture(4, 8) = 1;
architecture(6, 8) = 1;
architecture(7:8, 9) = 1;
splits = ones(9);
splits(7, 3) = 1 - firstMotorShare;
splits(7, 5) = firstMotorShare;
splits(8, 4) = 1 - secondMotorShare;
splits(8, 6) = secondMotorShare;
splits(9, 7:8) = 0.5;
aircraft.Specs.Propulsion.PropArch.Arch = architecture;
aircraft.Specs.Propulsion.PropArch.SrcType = [1, 0];
aircraft.Specs.Propulsion.PropArch.TrnType = [1, 1, 0, 0, 2, 2];
aircraft.Specs.Propulsion.PropArch.OperDwn = @() splits;
aircraft.Specs.Propulsion.PropArch.EtaDwn = ones(9);
aircraft.Specs.Power.LamDwn.SLS = [];
end

function aircraft = makeAircraft(propellerEngine)
%
% aircraft = makeAircraft(propellerEngine)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Build a fuel-to-engine-to-propeller graph with one sink. Each vector
% entry identifies the engine that drives the corresponding propeller.
%
% INPUTS:
%     propellerEngine - one-based engine index for each propeller.
%                       size/type/units: 1-by-n / integer / []
%
% OUTPUTS:
%     aircraft        - aircraft structure with the test graph and powers.
%                       size/type/units: 1-by-1 / struct / []
%

engineCount = max(propellerEngine);
propellerCount = numel(propellerEngine);
componentCount = 1 + engineCount + propellerCount + 1;
architecture = zeros(componentCount);
for engine = 1:engineCount
    architecture(1, 1 + engine) = 1;
end
for propeller = 1:propellerCount
    propellerIndex = 1 + engineCount + propeller;
    architecture(1 + propellerEngine(propeller), propellerIndex) = 1;
    architecture(propellerIndex, componentCount) = 1;
end
aircraft.Specs.Propulsion.PropArch.Arch = architecture;
aircraft.Specs.Propulsion.PropArch.SrcType = 1;
aircraft.Specs.Propulsion.PropArch.TrnType = [ones(1, engineCount), 2 * ones(1, propellerCount)];
aircraft.Specs.Propulsion.PropArch.OperDwn = @() ones(componentCount);
aircraft.Specs.Propulsion.SLSPower = [100 * ones(1, engineCount), 40 * ones(1, propellerCount)];
aircraft.Specs.Power.LamDwn.SLS = [];
end

function connections = propellerConnections(aircraft, engine)
%
% connections = propellerConnections(aircraft, engine)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Return sorted propeller indices, accepting both scalar and cell-array
% representations of the engine's connection list.
%
% INPUTS:
%     aircraft   - processed aircraft structure with propeller links.
%                  size/type/units: 1-by-1 / struct / []
%     engine     - one-based transmitter index of the engine.
%                  size/type/units: 1-by-1 / integer / []
%
% OUTPUTS:
%     connections - sorted, one-based propeller component indices.
%                   size/type/units: 1-by-n / integer / []
%

entry = aircraft.Specs.Propulsion.PropArch.WhichProp(engine);
if iscell(entry)
    entry = entry{1};
end
connections = sort(entry(:)');
end

function supplement = parallelSupplement(types, requiredPower, fanEfficiency)
%
% supplement = parallelSupplement(types, requiredPower, fanEfficiency)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Make one engine and each motor feed a common target. The input powers
% determine matching target demand and downstream fractions.
%
% INPUTS:
%     types         - transmitter type for each graph component.
%                     size/type/units: 1-by-n / integer / []
%     requiredPower - required power of each component.
%                     size/type/units: 1-by-n / double / [W]
%     fanEfficiency - fan efficiency applied at fan targets.
%                     size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     supplement    - motor power credited to the engine.
%                     size/type/units: 1-by-1 / double / [W]
%

componentCount = numel(types);
architecture = zeros(componentCount);
architecture(1:end-1, end) = 1;
targetPower = sum(requiredPower(1:end-1));
requiredPower(end) = targetPower;
splits = zeros(componentCount);
splits(end, 1:end-1) = requiredPower(1:end-1) ./ targetPower;
efficiencies = ones(componentCount);
output = PropulsionPkg.PowerSupplementCheck(requiredPower, architecture, splits, efficiencies, types, fanEfficiency);
supplement = output(1);
end

function supplement = consistentParallelSupplement(edgeEfficiency, fanEfficiency)
%
% supplement = consistentParallelSupplement(edgeEfficiency, fanEfficiency)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Return motor assistance for a power-consistent, equal-share fan. The fan
% requires 100 W; each parent delivers 50 W after its edge loss.
%
% INPUTS:
%     edgeEfficiency - efficiency of both parent-to-fan connections.
%                      size/type/units: 1-by-1 / double / []
%     fanEfficiency  - fan efficiency used for motor credit.
%                      size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     supplement     - motor assistance credited to the engine.
%                      size/type/units: 1-by-1 / double / [W]
%

architecture = zeros(3);
architecture(1:2, 3) = 1;
splits = zeros(3);
splits(3, 1:2) = 0.5;
efficiencies = ones(3);
efficiencies(3, 1:2) = edgeEfficiency;
parentPower = 50 / edgeEfficiency;
output = PropulsionPkg.PowerSupplementCheck( ...
    [parentPower, parentPower, 100], architecture, splits, efficiencies, ...
    [1, 0, 2], fanEfficiency);
supplement = output(1);
end

function pass = CheckInterleavedEngineInletAreas()
%
% pass = CheckInterleavedEngineInletAreas()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Reorder the two-engine sizing graph so motors precede engines, then check
% that each sized engine assigns its inlet area to its connected fan.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     pass - true if both fan slots receive finite inlet areas.
%            size/type/units: 1-by-1 / logical / []
%

aircraft = makeTwoEngineSizingAircraft(0.2, 0.4);
propArch = aircraft.Specs.Propulsion.PropArch;
order = [1, 2, 5, 3, 6, 4, 7, 8, 9];
splits = propArch.OperDwn();
propArch.Arch = propArch.Arch(order, order);
propArch.OperDwn = @() splits(order, order);
propArch.TrnType = propArch.TrnType(order(3:8) - 2);
aircraft.Specs.Propulsion.PropArch = propArch;
aircraft.Specs.Propulsion.InletArea = NaN(1, 6);
aircraft = PropulsionPkg.PropulsionSizing(aircraft);
areas = aircraft.Specs.Propulsion.InletArea;
pass = numel(areas) == 6 && all(isfinite(areas(5:6))) && ...
       all(isnan(areas([1, 3])));
if (~pass)
    fprintf(1, "Interleaved engine inlet areas: %s\n", mat2str(areas));
end
end

function pass = CheckSeparateParallelTargets()
%
% pass = CheckSeparateParallelTargets()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check full-throttle recomputation when one engine has a different motor
% helper at each of two fans. Expected splits use each fan's own output.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     pass - true if both fan-specific splits are recomputed correctly.
%            size/type/units: 1-by-1 / logical / []
%

aircraft.Specs.Propulsion.PropArch.Arch = zeros(5);
aircraft.Specs.Propulsion.PropArch.Arch(1, 4:5) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(2, 4) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(3, 5) = 1;
aircraft.Specs.Propulsion.PropArch.SrcType = [];
aircraft.Specs.Propulsion.PropArch.TrnType = [1, 0, 0, 2, 2];
aircraft.Specs.Propulsion.PropArch.OperUps = @separateParallelUps;
aircraft.Specs.Propulsion.PropArch.OperDwn = @separateParallelSplits;
aircraft.Specs.Propulsion.PropArch.EtaUps = ones(5);
aircraft.Specs.Power.LamDwn.SLS = [0.5, 0.5];
aircraft.Mission.History.SI.Power.Pav = [100, 20, 30, 70, 80];
aircraft.Mission.History.SI.Power.LamUps = 1;
aircraft.Mission.History.SI.Power.LamDwn = [0.5, 0.5];
aircraft = PropulsionPkg.PropArchConnections(aircraft);
try
    output = PropulsionPkg.RecomputeSplits(aircraft, 1, 1);
    actual = output.Mission.History.SI.Power.LamDwn;
    expected = [20 / 70, 30 / 80];
    pass = isequal(size(actual), size(expected)) && ...
           all(abs(actual - expected) < 1e-10);
catch error
    fprintf(1, "Separate parallel targets: %s\n", error.message);
    pass = false;
end
end

function splits = separateParallelSplits(firstMotorShare, secondMotorShare)
%
% splits = separateParallelSplits(firstMotorShare, secondMotorShare)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Evaluate independent motor shares for two different fans.
%
% INPUTS:
%     firstMotorShare  - motor fraction at the first fan.
%                        size/type/units: 1-by-1 / double / []
%     secondMotorShare - motor fraction at the second fan.
%                        size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     splits           - downstream operational matrix.
%                        size/type/units: 5-by-5 / double / []
%

splits = zeros(5);
splits(4, 1:2) = [1 - firstMotorShare, firstMotorShare];
splits(5, [1, 3]) = [1 - secondMotorShare, secondMotorShare];
end

function splits = separateParallelUps(~)
%
% splits = separateParallelUps(~)
% written by Triet Ho
% last updated: 16 sep 2026
%
% Route half the engine output to each fan and each motor to its own fan.
%
% INPUTS:
%     unused - full-throttle upstream split marker.
%              size/type/units: 1-by-1 / double / []
%
% OUTPUTS:
%     splits - upstream operational matrix.
%              size/type/units: 5-by-5 / double / []
%

splits = zeros(5);
splits(1, 4:5) = 0.5;
splits(2, 4) = 1;
splits(3, 5) = 1;
end

function pass = CheckMixedDepthEngineConnections()
%
% pass = CheckMixedDepthEngineConnections()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check a propeller receiving half its power from a direct engine and half
% from an engine reached through a cable. Both engines must be accounted for.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     pass - true if both engines receive their expected hybrid coefficient.
%            size/type/units: 1-by-1 / logical / []
%

aircraft.Specs.Propulsion.PropArch.Arch = zeros(6);
aircraft.Specs.Propulsion.PropArch.Arch(1, 2:3) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(2, 5) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(3, 4) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(4, 5) = 1;
aircraft.Specs.Propulsion.PropArch.Arch(5, 6) = 1;
aircraft.Specs.Propulsion.PropArch.SrcType = 1;
aircraft.Specs.Propulsion.PropArch.TrnType = [1, 1, 4, 2];
splits = zeros(6);
splits(2:3, 1) = 1;
splits(4, 3) = 1;
splits(5, [2, 4]) = 0.5;
splits(6, 5) = 1;
aircraft.Specs.Propulsion.PropArch.OperDwn = @() splits;
aircraft.Specs.Propulsion.SLSPower = [100, 100, 100, 100];
aircraft.Specs.Power.LamDwn.SLS = [];
aircraft = PropulsionPkg.ProcessPropArch(aircraft);
actual = aircraft.Specs.Propulsion.Engine.HEcoeff(1:2);
pass = all(abs(actual - [1.5, 1.5]) < 1e-10);
if (~pass)
    fprintf(1, "Mixed-depth engine coefficients: %s\n", mat2str(actual));
end
end
