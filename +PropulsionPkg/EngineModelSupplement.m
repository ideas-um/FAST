function [ModelSupplement] = EngineModelSupplement(AircraftClass, MotorSupplement)
%
% [ModelSupplement] = EngineModelSupplement(AircraftClass, MotorSupplement)
% written by Triet Ho
% last updated: 09 nov 2026
%
% Select the electric supplement passed to the engine cycle model. FAST
% obtains turboprop and piston required shaft power from the split-aware
% graph power flow, so subtracting motor power again would underpredict fuel
% burn. Turbofan thrust is based on total fan demand and needs the explicit
% motor supplement.
%
% INPUTS:
%     AircraftClass   - FAST aircraft class.
%                       size/type/units: scalar / string or char / []
%
%     MotorSupplement - motor contribution at the shared target.
%                       size/type/units: numeric array / double / [W]
%
% OUTPUTS:
%     ModelSupplement - electric input for the engine cycle model.
%                       size/type/units: numeric array / double / [W]
%

if (strcmpi(AircraftClass, "Turbofan"))
    ModelSupplement = MotorSupplement;
elseif (strcmpi(AircraftClass, "Turboprop") || ...
        strcmpi(AircraftClass, "Piston"))
    ModelSupplement = zeros(size(MotorSupplement));
else
    error("FAST:InvalidAircraftClass", ...
          "Unsupported aircraft class for engine supplement accounting.");
end

end
