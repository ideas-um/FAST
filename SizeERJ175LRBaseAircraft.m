function [BasePHE, BaseConventional, SizingMetadata] = ...
        SizeERJ175LRBaseAircraft(OutputFile)
%SIZEERJ175LRBASEAIRCRAFT Size the production ERJ aircraft from source.
%
% Both aircraft are sized exactly once from the authoritative specification
% functions.  OutputFile is optional and is intended for sharing the two
% results between jobs in one HPC submission, not for staging an input MAT
% file from another machine.

if nargin < 1
    OutputFile = "";
end

ConventionalDefinition = AircraftSpecsPkg.ERJ175LR();
PHEDefinition = AircraftSpecsPkg.ERJ175LR_PHE();
ValidateSharedDefinitions(ConventionalDefinition, PHEDefinition);

BaseConventional = Main(ConventionalDefinition, ...
    @MissionProfilesPkg.ERJ_ClimbThenAccel);
BasePHE = Main(PHEDefinition, @MissionProfilesPkg.ERJ_ClimbThenAccel);

if ~logical(BaseConventional.Settings.Converged) || ...
        ~logical(BasePHE.Settings.Converged)
    error("FAST:ERJ175LR:SizingDidNotConverge", ...
        "Both ERJ175LR base-aircraft sizing runs must converge.");
end
if string(BasePHE.Specs.Propulsion.PropArch.Type) ~= "PHE" || ...
        string(BaseConventional.Specs.Propulsion.PropArch.Type) ~= "C"
    error("FAST:ERJ175LR:WrongArchitecture", ...
        "The sized base aircraft do not have the required C and PHE architectures.");
end

SizingMetadata = struct( ...
    "ConventionalSpecification", "AircraftSpecsPkg.ERJ175LR", ...
    "PHESpecification", "AircraftSpecsPkg.ERJ175LR_PHE", ...
    "MissionProfile", "MissionProfilesPkg.ERJ_ClimbThenAccel", ...
    "ConventionalConverged", logical(BaseConventional.Settings.Converged), ...
    "PHEConverged", logical(BasePHE.Settings.Converged), ...
    "Generated", string(datetime("now")));

if strlength(string(OutputFile)) > 0
    OutputFile = char(OutputFile);
    OutputDir = fileparts(OutputFile);
    if ~isfolder(OutputDir), mkdir(OutputDir); end
    save(OutputFile, "BasePHE", "BaseConventional", ...
        "SizingMetadata", "-v7.3");
end
end


function ValidateSharedDefinitions(Conventional, PHE)
% Whole shared substructures must be identical.
CheckEqual(Conventional.Specs.TLAR, PHE.Specs.TLAR, "TLAR");
CheckEqual(Conventional.Specs.Performance, PHE.Specs.Performance, ...
    "performance requirements");
CheckEqual(func2str(Conventional.Specs.Aero.L_D.Method), ...
    func2str(PHE.Specs.Aero.L_D.Method), "aerodynamic method");
ConventionalAero = Conventional.Specs.Aero;
PHEAero = PHE.Specs.Aero;
ConventionalAero.L_D = rmfield(ConventionalAero.L_D, "Method");
PHEAero.L_D = rmfield(PHEAero.L_D, "Method");
CheckEqual(ConventionalAero, PHEAero, "aerodynamics");
CheckEqual(Conventional.Specs.Weight, PHE.Specs.Weight, ...
    "initial weights and weight calibration");
CheckEqual(Conventional.Specs.Battery, PHE.Specs.Battery, ...
    "battery-cell model");

% Propulsion differs only in architecture and the topology-dependent inlet
% array.  Engine, thrust, engine count, T/W, and efficiency must match.
ConventionalPropulsion = Conventional.Specs.Propulsion;
PHEPropulsion = PHE.Specs.Propulsion;
PHEPropulsion.PropArch = ConventionalPropulsion.PropArch;
PHEPropulsion.InletArea = ConventionalPropulsion.InletArea;
CheckEqual(ConventionalPropulsion, PHEPropulsion, "engine and propulsion");

% Check the power fields that are not intentionally hybrid-specific.
CheckEqual(Conventional.Specs.Power.SpecEnergy.Fuel, ...
    PHE.Specs.Power.SpecEnergy.Fuel, "fuel specific energy");
CheckEqual(Conventional.Specs.Power.P_W.SLS, ...
    PHE.Specs.Power.P_W.SLS, "aircraft SLS power density");
CheckEqual(Conventional.Specs.Power.P_W.EG, ...
    PHE.Specs.Power.P_W.EG, "generator power density");
CheckEqual(Conventional.Specs.Power.Windmill, ...
    PHE.Specs.Power.Windmill, "windmilling settings");

% PHE intentionally allows more sizing iterations; all other settings
% defined by the two specification functions must match.
ConventionalSettings = Conventional.Settings;
PHESettings = PHE.Settings;
PHESettings.Analysis.MaxIter = ConventionalSettings.Analysis.MaxIter;
CheckEqual(ConventionalSettings, PHESettings, "analysis settings");
end


function CheckEqual(ConventionalValue, PHEValue, Label)
if ~isequaln(ConventionalValue, PHEValue)
    error("FAST:ERJ175LR:DefinitionMismatch", ...
        "ERJ175LR and ERJ175LR_PHE %s do not match.", Label);
end
end
