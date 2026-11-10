function [Success] = TestERJ175LRPHENearZeroSplit()
%
% [Success] = TestERJ175LRPHENearZeroSplit()
% written by Triet Ho
% last updated: 09 nov 2026
%
% Verify that a microscopic electric split cannot create an artificial
% ERJ175LR fuel-burn or takeoff-weight benefit. A positive split may carry
% the detailed battery model's minimum realizable cell mass.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - 1 when the near-zero PHE result has no artificial benefit.
%               size/type/units: 1-by-1 / logical / []
%

Mission = @MissionProfilesPkg.ERJ_ClimbThenAccel;
Conventional = Main(AircraftSpecsPkg.ERJ175LR(), Mission);

EpsilonPHE = AircraftSpecsPkg.ERJ175LR_PHE();
EpsilonPHE = SetFixedSplit(EpsilonPHE, 1.0e-06);
EpsilonPHE = Main(EpsilonPHE, Mission);

FuelTolerance = 1.0e-08 * max(1, Conventional.Specs.Weight.Fuel);
MTOWTolerance = 1.0e-08 * max(1, Conventional.Specs.Weight.MTOW);
Success = ...
    EpsilonPHE.Specs.Weight.Fuel >= ...
        Conventional.Specs.Weight.Fuel - FuelTolerance && ...
    EpsilonPHE.Specs.Weight.MTOW >= ...
        Conventional.Specs.Weight.MTOW - MTOWTolerance;

if (Success)
    fprintf(1, ...
        "ERJ175LR PHE near-zero test passed: conventional %.6f kg and PHE %.6f kg fuel; conventional %.6f kg and PHE %.6f kg MTOW.\n", ...
        Conventional.Specs.Weight.Fuel, EpsilonPHE.Specs.Weight.Fuel, ...
        Conventional.Specs.Weight.MTOW, EpsilonPHE.Specs.Weight.MTOW);
else
    fprintf(1, ...
        "ERJ175LR PHE near-zero test failed: conventional %.6f kg and PHE %.6f kg fuel; conventional %.6f kg and PHE %.6f kg MTOW.\n", ...
        Conventional.Specs.Weight.Fuel, EpsilonPHE.Specs.Weight.Fuel, ...
        Conventional.Specs.Weight.MTOW, EpsilonPHE.Specs.Weight.MTOW);
end

end

function [Aircraft] = SetFixedSplit(Aircraft, FixedPowerSplit)
%
% Apply one prescribed downstream split to all active mission phases.
%
Aircraft.Specs.Power.LamDwn.SLS = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Tko = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Clb = FixedPowerSplit;
Aircraft.Specs.Power.LamDwn.Crs = FixedPowerSplit;
end
