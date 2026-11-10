function [Success] = TestEngineMotorRegressions()
%
% [Success] = TestEngineMotorRegressions()
% written by Triet Ho
% last updated: 09 nov 2026
%
% Check the engine idle, cycle-model supplement, and independent per-engine
% sizing rules that prevent artificial hybrid-electric fuel-burn benefits.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - 1 when all checks pass, otherwise 0.
%               size/type/units: 1-by-1 / logical / []
%

Pass = false(7, 1);

% A conventional engine with no demand remains at idle.
Pass(1) = CheckValue(PropulsionPkg.ResolveEngineDemand(0, 50, false), 50);

% Electric-only operation at one point cannot disable idle elsewhere.
Actual = PropulsionPkg.ResolveEngineDemand([0; 0], 50, [false; true]);
Pass(2) = isequal(Actual, [50; 0]);

% Positive demand passes through unchanged.
Pass(3) = CheckValue( ...
    PropulsionPkg.ResolveEngineDemand(100, 50, false), 100);

% Turbofans apply the explicit motor contribution exactly once.
Actual = PropulsionPkg.EngineModelSupplement("Turbofan", [10; 20]);
Pass(4) = isequal(Actual, [10; 20]);

% Shaft-power models receive graph-resolved demand and no second credit.
Pass(5) = isequal( ...
    PropulsionPkg.EngineModelSupplement("Turboprop", [10; 20]), [0; 0]);
Pass(6) = isequal( ...
    PropulsionPkg.EngineModelSupplement("Piston", [10; 20]), [0; 0]);

% Distinct motor shares must reach their corresponding engine sizing calls.
Aircraft = MakeTwoEngineSizingAircraft(0.2, 0.4);
Aircraft = PropulsionPkg.PropulsionSizing(Aircraft);
Expected = Aircraft.Specs.Propulsion.PowerSupp(1:2);
Actual = arrayfun(@(Engine) Engine.FanSysObject.ElecWork, ...
                  Aircraft.Specs.Propulsion.SizedEngine);
Actual = Actual(:)';
Pass(7) = abs(diff(Expected)) > 1.0e05 && ...
          isequal(size(Actual), size(Expected)) && ...
          all(isfinite(Actual)) && ...
          all(abs(Actual - Expected) <= 1.0e-08 * max(1, abs(Expected)));

Success = all(Pass);
if (Success)
    fprintf(1, "EngineMotorRegressions tests passed!\n");
else
    fprintf(1, "EngineMotorRegressions tests failed:\n");
    fprintf(1, "    Test %d\n", find(~Pass));
end

end

function [Pass] = CheckValue(Actual, Expected)
%
% Return true when two finite scalar values agree to numerical precision.
%
Pass = isscalar(Actual) && isfinite(Actual) && ...
       abs(Actual - Expected) <= 1.0e-10;
end

function [Aircraft] = MakeTwoEngineSizingAircraft(FirstMotorShare, SecondMotorShare)
%
% Build two matched engines with independently adjustable motor loads.
%
Aircraft = DataStructPkg.PreSpecProcessing(AircraftSpecsPkg.ERJ175LR());
Aircraft = DataStructPkg.SpecProcessing(Aircraft);
Architecture = zeros(9);
Architecture(1, 3:4) = 1;
Architecture(2, 5:6) = 1;
Architecture(3, 7) = 1;
Architecture(5, 7) = 1;
Architecture(4, 8) = 1;
Architecture(6, 8) = 1;
Architecture(7:8, 9) = 1;
Splits = ones(9);
Splits(7, 3) = 1 - FirstMotorShare;
Splits(7, 5) = FirstMotorShare;
Splits(8, 4) = 1 - SecondMotorShare;
Splits(8, 6) = SecondMotorShare;
Splits(9, 7:8) = 0.5;
Aircraft.Specs.Propulsion.PropArch.Arch = Architecture;
Aircraft.Specs.Propulsion.PropArch.SrcType = [1, 0];
Aircraft.Specs.Propulsion.PropArch.TrnType = [1, 1, 0, 0, 2, 2];
Aircraft.Specs.Propulsion.PropArch.OperDwn = @() Splits;
Aircraft.Specs.Propulsion.PropArch.EtaDwn = ones(9);
Aircraft.Specs.Power.LamDwn.SLS = [];
end
