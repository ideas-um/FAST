function Aggregate = PrepareSelectedSequenceRun()
%PREPARESELECTEDSEQUENCERUN Validate a selected HEA and build shared inputs.

ResultsRoot = RequireEnvironmentPath("FAST_GL_RESULTS_DIR");
BaselineFile = RequireEnvironmentPath("FAST_HEA_BASELINE_FILE");
SequenceFile = RequireEnvironmentPath("FAST_SEQUENCE_FILE");
MaxIterations = ReadPositiveInteger("FAST_GL_MAX_ITERATIONS", 500);
if ~isfile(BaselineFile)
    error("GreatLakes:MissingHEABaseline", ...
        "Selected HEA baseline file does not exist: %s", BaselineFile);
end

[BasePHE, BaselineVariable] = LoadHEAAircraft(BaselineFile);
ValidateHEA(BasePHE, BaselineFile, BaselineVariable);
ExpectedSpecificEnergy_Whkg = ReadOptionalPositiveScalar( ...
    "FAST_EXPECTED_BATTERY_SPECIFIC_ENERGY_WHKG");
ActualSpecificEnergy_Whkg = ...
    BasePHE.Specs.Power.SpecEnergy.Batt / 3.6e3;
if isfinite(ExpectedSpecificEnergy_Whkg) && ...
        abs(ActualSpecificEnergy_Whkg - ExpectedSpecificEnergy_Whkg) > ...
        1e-9 * max(1, ExpectedSpecificEnergy_Whkg)
    error("GreatLakes:WrongBatterySpecificEnergy", ...
        "Expected %g Wh/kg HEA baseline; selected file contains %g Wh/kg.", ...
        ExpectedSpecificEnergy_Whkg, ActualSpecificEnergy_Whkg);
end

% The comparison uses the authoritative literature-calibrated conventional
% specification. Never back-propagate coefficients from an arbitrary MAT file.
ConventionalDefinition = AircraftSpecsPkg.ERJ175LR();
PHEDefinition = AircraftSpecsPkg.ERJ175LR_PHE();
ValidateCalibration(BasePHE, ConventionalDefinition, PHEDefinition);
BaseConventional = Main(ConventionalDefinition, ...
    @MissionProfilesPkg.ERJ_ClimbThenAccel);
if ~logical(BaseConventional.Settings.Converged)
    error("GreatLakes:ConventionalSizingFailed", ...
        "The matching conventional aircraft did not converge.");
end
ValidatePair(BasePHE, BaseConventional);

SizingMetadata = struct( ...
    "HEASourceFile", string(BaselineFile), ...
    "HEASourceVariable", string(BaselineVariable), ...
    "HEAConverged", logical(BasePHE.Settings.Converged), ...
    "BatterySpecificEnergy_Whkg", ActualSpecificEnergy_Whkg, ...
    "SequenceFile", string(SequenceFile), ...
    "ConventionalSpecification", "AircraftSpecsPkg.ERJ175LR", ...
    "ConventionalConverged", logical(BaseConventional.Settings.Converged), ...
    "MissionProfile", "MissionProfilesPkg.ERJ_ClimbThenAccel", ...
    "Generated", string(datetime("now")));

PreparedDir = fullfile(ResultsRoot, "prepared");
PreparedBaseFile = fullfile(PreparedDir, "SelectedHEA_BaseAircraft.mat");
PrepareOutput = fullfile(ResultsRoot, "prepare");
SharedCache = fullfile(ResultsRoot, "conventional_flight_cache");
if ~isfolder(PreparedDir), mkdir(PreparedDir); end
if ~isfolder(PrepareOutput), mkdir(PrepareOutput); end
if ~isfolder(SharedCache), mkdir(SharedCache); end
save(PreparedBaseFile, "BasePHE", "BaseConventional", ...
    "SizingMetadata", "-v7.3");
WriteRepresentativeMapping(SequenceFile, PreparedDir);

setenv("FAST_SEQUENCE_OUTPUT_DIR", PrepareOutput);
setenv("FAST_CONVENTIONAL_CACHE_DIR", SharedCache);
setenv("FAST_BASE_AIRCRAFT_FILE", PreparedBaseFile);
setenv("FAST_PREPARE_CACHE_ONLY", "1");
Cleanup = onCleanup(@() setenv("FAST_PREPARE_CACHE_ONLY", ""));
Aggregate = RunAllSequencesFullComparisonParallel(1, MaxIterations, 1);
clear Cleanup
end


function ValidateCalibration(PHE, ConventionalDefinition, PHEDefinition)
Expected = [ConventionalDefinition.Specs.Aero.L_D.ClbCF, ...
    ConventionalDefinition.Specs.Aero.L_D.CrsCF, ...
    ConventionalDefinition.Specs.Propulsion.MDotCF, ...
    ConventionalDefinition.Specs.Weight.WairfCF];
PHEExpected = [PHEDefinition.Specs.Aero.L_D.ClbCF, ...
    PHEDefinition.Specs.Aero.L_D.CrsCF, ...
    PHEDefinition.Specs.Propulsion.MDotCF, ...
    PHEDefinition.Specs.Weight.WairfCF];
Actual = [PHE.Specs.Aero.L_D.ClbCF, PHE.Specs.Aero.L_D.CrsCF, ...
    PHE.Specs.Propulsion.MDotCF, PHE.Specs.Weight.WairfCF];
if ~isequal(Expected, PHEExpected) || ~isequal(Actual, Expected)
    error("GreatLakes:LiteratureCalibrationMismatch", ...
        ["The conventional definition, PHE definition, and sized PHE MAT " ...
        "must all use [ClbCF CrsCF MDotCF WairfCF] = [%g %g %g %g]."], ...
        Expected);
end
end


function WriteRepresentativeMapping(SequenceFile, PreparedDir)
Input = load(SequenceFile, "tables", "OriginalSequenceIndices");
if ~isfield(Input, "tables") || ~iscell(Input.tables)
    error("GreatLakes:InvalidSequenceFile", ...
        "Sequence file must contain a cell array named tables: %s", ...
        SequenceFile);
end
nSequence = numel(Input.tables);
RepresentativeIndex = (1:nSequence)';
if isfield(Input, "OriginalSequenceIndices")
    OriginalSequenceIndex = Input.OriginalSequenceIndices(:);
    if numel(OriginalSequenceIndex) ~= nSequence || ...
            any(~isfinite(OriginalSequenceIndex)) || ...
            any(OriginalSequenceIndex ~= fix(OriginalSequenceIndex))
        error("GreatLakes:InvalidRepresentativeMapping", ...
            "OriginalSequenceIndices must contain one integer per table.");
    end
else
    OriginalSequenceIndex = RepresentativeIndex;
end
Mapping = table(RepresentativeIndex, OriginalSequenceIndex);
writetable(Mapping, fullfile(PreparedDir, ...
    "Representative_Sequence_Mapping.csv"));
save(fullfile(PreparedDir, "Representative_Sequence_Mapping.mat"), ...
    "Mapping");
end


function [Aircraft, VariableName] = LoadHEAAircraft(FileName)
Data = load(FileName);
Candidates = ["BasePHE", "SizedAircraft", "Aircraft", ...
    "HEA", "PHEAircraft"];
Present = Candidates(isfield(Data, Candidates));
if isempty(Present)
    error("GreatLakes:UnsupportedHEAFile", ...
        ["The selected MAT file must contain one aircraft variable named " ...
         "BasePHE, SizedAircraft, Aircraft, HEA, or PHEAircraft. File: %s"], ...
        FileName);
end
if numel(Present) > 1
    error("GreatLakes:AmbiguousHEAFile", ...
        "The MAT file contains multiple supported aircraft variables: %s", ...
        strjoin(Present, ", "));
end
VariableName = Present(1);
Aircraft = Data.(VariableName);
end


function ValidateHEA(Aircraft, FileName, VariableName)
if ~isstruct(Aircraft) || ~isscalar(Aircraft) || ...
        ~isfield(Aircraft, "Specs") || ~isfield(Aircraft, "Settings") || ...
        ~isfield(Aircraft.Settings, "Converged")
    error("GreatLakes:InvalidHEAStructure", ...
        "Variable %s in %s is not a complete scalar FAST aircraft.", ...
        VariableName, FileName);
end
if ~logical(Aircraft.Settings.Converged)
    error("GreatLakes:HEANotConverged", ...
        "The selected HEA baseline is not converged: %s", FileName);
end
if string(Aircraft.Specs.Propulsion.PropArch.Type) ~= "PHE"
    error("GreatLakes:WrongHEAArchitecture", ...
        "The selected baseline must have PHE architecture.");
end
end


function ValidatePair(PHE, Conventional)
if string(Conventional.Specs.Propulsion.PropArch.Type) ~= "C" || ...
        PHE.Specs.Performance.RCMax ~= Conventional.Specs.Performance.RCMax || ...
        PHE.Specs.Aero.L_D.ClbCF ~= Conventional.Specs.Aero.L_D.ClbCF || ...
        PHE.Specs.Aero.L_D.CrsCF ~= Conventional.Specs.Aero.L_D.CrsCF || ...
        PHE.Specs.Propulsion.MDotCF ~= Conventional.Specs.Propulsion.MDotCF || ...
        PHE.Specs.Weight.WairfCF ~= Conventional.Specs.Weight.WairfCF
    error("GreatLakes:BaselineMismatch", ...
        ["The selected HEA does not match the current ERJ175LR conventional " ...
         "climb-rate, fuel-flow, or airframe-weight requirements."]);
end
end


function Value = RequireEnvironmentPath(Name)
Value = string(getenv(Name));
if strlength(Value) == 0
    error("GreatLakes:MissingEnvironment", ...
        "Required environment variable %s is not set.", Name);
end
Value = char(Value);
end


function Value = ReadPositiveInteger(Name, DefaultValue)
Text = string(getenv(Name));
if strlength(Text) == 0
    Value = DefaultValue;
else
    Value = str2double(Text);
end
if ~isscalar(Value) || ~isfinite(Value) || Value ~= fix(Value) || Value < 1
    error("GreatLakes:BadInteger", "%s must be a positive integer.", Name);
end
end


function Value = ReadOptionalPositiveScalar(Name)
Text = string(getenv(Name));
if strlength(Text) == 0
    Value = NaN;
    return
end
Value = str2double(Text);
if ~isscalar(Value) || ~isfinite(Value) || Value <= 0
    error("GreatLakes:BadScalar", "%s must be a positive scalar.", Name);
end
end
