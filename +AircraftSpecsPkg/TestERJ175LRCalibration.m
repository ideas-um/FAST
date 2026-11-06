function Tests = TestERJ175LRCalibration()
Tests = functiontests(localfunctions);
end


function testPublishedBaselineMatchesCurrentFAST(~)
% Cassidy et al. (2025), Aerospace 12(7), 598. The paper's stated model
% agreement is enforced here with a 0.5-percent tolerance.
Aircraft = AircraftSpecsPkg.ERJ175LR();
Aircraft.Settings.PrintOut = 0;
Sized = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

Actual = [Sized.Specs.Weight.MTOW; Sized.Specs.Weight.OEW; ...
    Sized.Specs.Weight.Fuel];
Reference = [38637; 21545; 9398];
Names = ["MTOW"; "OEW"; "block fuel"];
RelativeError = abs(Actual - Reference) ./ Reference;
assert(logical(Sized.Settings.Converged), ...
    "The calibrated conventional ERJ175LR did not converge.");
for k = 1:numel(Names)
    assert(RelativeError(k) <= 0.005, ...
        "%s differs from the literature target by %.3f percent.", ...
        Names(k), 100 * RelativeError(k));
end
end


function testConventionalAndPHEShareCalibration(~)
Conventional = AircraftSpecsPkg.ERJ175LR();
PHE = AircraftSpecsPkg.ERJ175LR_PHE();
assert(Conventional.Specs.Aero.L_D.ClbCF == PHE.Specs.Aero.L_D.ClbCF);
assert(Conventional.Specs.Aero.L_D.CrsCF == PHE.Specs.Aero.L_D.CrsCF);
assert(Conventional.Specs.Propulsion.MDotCF == ...
    PHE.Specs.Propulsion.MDotCF);
assert(Conventional.Specs.Weight.WairfCF == PHE.Specs.Weight.WairfCF);
end
