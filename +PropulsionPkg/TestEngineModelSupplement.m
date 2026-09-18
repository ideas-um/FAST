function [Success] = TestEngineModelSupplement()
%
% [Success] = TestEngineModelSupplement()
% written by Triet Ho
%
% Check that an electric-motor contribution is not credited twice when
% FAST has already propagated the split propeller demand to a turboprop.
% Turbofan thrust is derived from the whole fan demand and still needs its
% separately computed motor supplement.
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Success - true when the three aircraft classes use the appropriate
%               engine-model supplement. size/type/units: scalar/logical/[]
%

MotorPower = [25, 75];
Turboprop = PropulsionPkg.EngineModelSupplement("Turboprop", MotorPower);
Piston = PropulsionPkg.EngineModelSupplement("Piston", MotorPower);
Turbofan = PropulsionPkg.EngineModelSupplement("Turbofan", MotorPower);

Success = isequal(Turboprop, zeros(size(MotorPower))) && ...
          isequal(Piston, zeros(size(MotorPower))) && ...
          isequal(Turbofan, MotorPower);

if (Success)
    fprintf(1, "EngineModelSupplement tests passed!\n");
else
    fprintf(1, "EngineModelSupplement tests failed!\n");
end

end
