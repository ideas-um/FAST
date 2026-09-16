classdef TestEngineMotorRegressions < matlab.unittest.TestCase
    % Exercise engine and motor accounting on small, controlled architectures.

    methods (Test)
        function oneEngineOnePropeller(testCase)
            aircraft = makeAircraft([1]);
            aircraft = PropulsionPkg.ProcessPropArch(aircraft);
            testCase.verifyEqual(propellerConnections(aircraft, 1), 3);
        end

        function oneEngineTwoPropellers(testCase)
            aircraft = makeAircraft([1, 1]);
            aircraft = PropulsionPkg.ProcessPropArch(aircraft);
            testCase.verifyEqual(propellerConnections(aircraft, 1), [3, 4]);
        end

        function oneEngineThreePropellers(testCase)
            aircraft = makeAircraft([1, 1, 1]);
            aircraft = PropulsionPkg.ProcessPropArch(aircraft);
            testCase.verifyEqual(propellerConnections(aircraft, 1), [3, 4, 5]);
        end

        function twoEnginesSeparatePropellers(testCase)
            aircraft = makeAircraft([1, 2]);
            aircraft = PropulsionPkg.ProcessPropArch(aircraft);
            testCase.verifyEqual(propellerConnections(aircraft, 1), 4);
            testCase.verifyEqual(propellerConnections(aircraft, 2), 5);
        end

        function eachEngineReceivesItsOwnMotorSupplement(testCase)
            aircraft = makeTwoEngineSizingAircraft(0.2, 0.4);
            aircraft = PropulsionPkg.PropulsionSizing(aircraft);
            expected = aircraft.Specs.Propulsion.PowerSupp(1:2);
            actual = arrayfun(@(engine) engine.FanSysObject.ElecWork, aircraft.Specs.Propulsion.SizedEngine);
            actual = actual(:)';
            testCase.verifyGreaterThan(abs(diff(expected)), 1e5);
            testCase.verifyEqual(actual, expected, "RelTol", 1e-8);
        end

        function engineOrderDoesNotChangeMotorSupplement(testCase)
            aircraft = makeTwoEngineSizingAircraft(0.4, 0.2);
            aircraft = PropulsionPkg.PropulsionSizing(aircraft);
            expected = aircraft.Specs.Propulsion.PowerSupp(1:2);
            actual = arrayfun(@(engine) engine.FanSysObject.ElecWork, aircraft.Specs.Propulsion.SizedEngine);
            actual = actual(:)';
            testCase.verifyGreaterThan(abs(diff(expected)), 1e5);
            testCase.verifyEqual(actual, expected, "RelTol", 1e-8);
        end

        function fanTargetUsesFanEfficiency(testCase)
            actual = parallelSupplement([1, 0, 2], [0, 10, 0], 0.8);
            testCase.verifyEqual(actual, 8, "AbsTol", 1e-10);
        end

        function generatorTargetDoesNotUseFanEfficiency(testCase)
            actual = parallelSupplement([1, 0, 3], [0, 10, 0], 0.8);
            testCase.verifyEqual(actual, 10, "AbsTol", 1e-10);
        end

        function cableTargetDoesNotUseFanEfficiency(testCase)
            actual = parallelSupplement([1, 0, 4], [0, 10, 0], 0.65);
            testCase.verifyEqual(actual, 10, "AbsTol", 1e-10);
        end

        function multipleMotorsOnNonFanTarget(testCase)
            actual = parallelSupplement([1, 0, 0, 3], [0, 7, 11, 0], 0.8);
            testCase.verifyEqual(actual, 18, "AbsTol", 1e-10);
        end

        function fanEfficiencyOneIsNeutral(testCase)
            actual = parallelSupplement([1, 0, 3], [0, 10, 0], 1);
            testCase.verifyEqual(actual, 10, "AbsTol", 1e-10);
        end

        function motorSplitLimitsEngineSupplement(testCase)
            architecture = zeros(4);
            architecture(1, 3) = 1;
            architecture(2, 3:4) = 1;
            splits = ones(4);
            splits(3, 2) = 0.25;
            splits(4, 2) = 0.75;
            actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0, 0], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
            testCase.verifyEqual(actual(1), 4, "AbsTol", 1e-10);
        end

        function motorPathLossLimitsEngineSupplement(testCase)
            architecture = zeros(3);
            architecture(1:2, 3) = 1;
            efficiencies = ones(3);
            efficiencies(3, 2) = 0.5;
            actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0], architecture, ones(3), efficiencies, [1, 0, 2], 0.8);
            testCase.verifyEqual(actual(1), 8, "AbsTol", 1e-10);
        end

        function sharedTargetsDoNotCreditMotorTwice(testCase)
            architecture = zeros(4);
            architecture(1:2, 3:4) = 1;
            splits = ones(4);
            splits(3, 2) = 0.25;
            splits(4, 2) = 0.75;
            actual = PropulsionPkg.PowerSupplementCheck([0, 20, 0, 0], architecture, splits, ones(4), [1, 0, 2, 2], 0.8);
            testCase.verifyEqual(actual(1), 16, "AbsTol", 1e-10);
        end
    end
end

function aircraft = makeTwoEngineSizingAircraft(firstMotorShare, secondMotorShare)
% Give two otherwise matched engines distinct motor loads during sizing.
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
% Build a fuel-to-engine-to-propeller graph with one sink and known indices.
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
% Accept either a scalar, vector, or cell representation of engine links.
entry = aircraft.Specs.Propulsion.PropArch.WhichProp(engine);
if iscell(entry)
    entry = entry{1};
end
connections = sort(entry(:)');
end

function supplement = parallelSupplement(types, requiredPower, fanEfficiency)
% Make one engine and each motor feed the same final transmitter.
componentCount = numel(types);
architecture = zeros(componentCount);
architecture(1:end-1, end) = 1;
splits = ones(componentCount);
efficiencies = ones(componentCount);
output = PropulsionPkg.PowerSupplementCheck(requiredPower, architecture, splits, efficiencies, types, fanEfficiency);
supplement = output(1);
end
