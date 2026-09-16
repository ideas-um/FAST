function [Success] = TestEngineMotorRegressions()
%
% [Success] = TestEngineMotorRegressions()
% written by Triet Ho
% last updated: 16 sep 2026
%
% Check gas-turbine and electric-motor accounting on controlled propulsion
% architectures. Each case isolates one connection or power-flow behavior.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - 1 when all 14 checks pass, otherwise 0.
%               size/type/units: 1-by-1 / int / []
%

%% TEST CASE SETUP %%
%%%%%%%%%%%%%%%%%%%%%

% Keep one result per case so a failure identifies the affected behavior.
Pass = false(14, 1);

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

% only one quarter of the motor power is routed to this engine's target
architecture = zeros(4);
architecture(1, 3) = 1;
architecture(2, 3:4) = 1;
splits = ones(4);
splits(3, 2) = 0.25;
splits(4, 2) = 0.75;
actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0, 0], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
Pass(12) = CheckValue(actual(1), 4);

% a half-efficient motor path delivers half of its available power
architecture = zeros(3);
architecture(1:2, 3) = 1;
efficiencies = ones(3);
efficiencies(3, 2) = 0.5;
actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0], architecture, ones(3), efficiencies, [1, 0, 2], 0.8);
Pass(13) = CheckValue(actual(1), 8);

% shared targets must credit each split motor contribution only once
architecture = zeros(4);
architecture(1:2, 3:4) = 1;
splits = ones(4);
splits(3, 2) = 0.25;
splits(4, 2) = 0.75;
actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0, 0], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
Pass(14) = CheckValue(actual(1), 16);

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
% Make one engine and each motor feed the same final transmitter, then
% return the engine's supplemental power.
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
splits = ones(componentCount);
efficiencies = ones(componentCount);
output = PropulsionPkg.PowerSupplementCheck(requiredPower, architecture, splits, efficiencies, types, fanEfficiency);
supplement = output(1);
end
