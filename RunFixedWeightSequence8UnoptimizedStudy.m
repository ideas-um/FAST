function Summary = RunFixedWeightSequence8UnoptimizedStudy()
%RUNFIXEDWEIGHTSEQUENCE8UNOPTIMIZEDSTUDY No fmincon; fixed dispatch only.
Root=fileparts(mfilename("fullpath"));
OutputRoot=fullfile(Root,"output","fixed_weight_sequence_8_unoptimized");
PDFRoot=fullfile(Root,"output","pdf");
if ~isfolder(OutputRoot),mkdir(OutputRoot);end
if ~isfolder(PDFRoot),mkdir(PDFRoot);end
CreateFixedWeightBatteryTechnologyVariants;
Original=load(fullfile(Root,"ERJ175LR_current_Lam_10pctTko_30pctEMClimb.mat"),"SizedAircraft");
Reference=load(fullfile(Root,"ERJ175LR_PHE_Fixed250Weight_500Whkg.mat"),"BaseConventional");
BasePHE=Original.SizedAircraft; BaseConventional=Reference.BaseConventional;
SizingMetadata=struct("Study","original fixed-weight 250 Wh/kg HEA", ...
    "BatterySpecificEnergy_Whkg",250,"PHE_MTOW_kg",BasePHE.Specs.Weight.MTOW, ...
    "PHE_OEW_kg",BasePHE.Specs.Weight.OEW,"PHE_BatteryWeight_kg",BasePHE.Specs.Weight.Batt, ...
    "PHE_BatteryEnergy_kWh",BasePHE.Specs.Weight.Batt*BasePHE.Specs.Power.SpecEnergy.Batt/3.6e6, ...
    "PHE_DesignFuel_kg",BasePHE.Specs.Weight.Fuel, ...
    "PHE_ElectricMachineWeight_kg",BasePHE.Specs.Weight.EM);
Base250=fullfile(OutputRoot,"Base250.mat");
save(Base250,"BasePHE","BaseConventional","SizingMetadata","-v7.3");

Names=["FAST_SEQUENCE_FILE","FAST_SEQUENCE_OUTPUT_DIR", ...
    "FAST_CONVENTIONAL_CACHE_DIR","FAST_BASE_AIRCRAFT_FILE", ...
    "FAST_GL_JOINT_MAX_ITERATIONS"];
for k=1:numel(Names),Old.(Names(k))=string(getenv(Names(k)));end
Cleanup=onCleanup(@()Restore(Old));
setenv("FAST_SEQUENCE_FILE",fullfile(Root,"Sequence.mat"));
setenv("FAST_CONVENTIONAL_CACHE_DIR",fullfile(Root,"output", ...
    "fixed_weight_sequence_8","conventional_flight_cache"));
setenv("FAST_GL_JOINT_MAX_ITERATIONS","");

Tech=[250;500;1000]; Rows=cell(3,1);
for k=1:3
    E=Tech(k); CaseDir=fullfile(OutputRoot,sprintf("%dWhkg",E));
    if ~isfolder(CaseDir),mkdir(CaseDir);end
    if E==250,Input=Base250;else,Input=fullfile(Root,sprintf( ...
            "ERJ175LR_PHE_Fixed250Weight_%dWhkg.mat",E));end
    setenv("FAST_SEQUENCE_OUTPUT_DIR",CaseDir);
    setenv("FAST_BASE_AIRCRAFT_FILE",Input);
    A=RunAllSequencesFullComparisonParallel(1,0,8);
    Checkpoint=fullfile(CaseDir,"checkpoints","Sequence_0008.mat");
    PDF=fullfile(PDFRoot,sprintf( ...
        "FixedWeight_%dWhkg_Sequence_0008_Unoptimized_EightPanel.pdf",E));
    MakeUnoptimizedSequenceEightPanel(Checkpoint,E,PDF);
    S=A.SequenceSummary(A.SequenceSummary.Sequence==8,:);
    Rows{k}=table(E,S.ConventionalFuelBurn_kg,S.UnoptimizedFuelBurn_kg, ...
        S.UnoptimizedFuelSavedVsConventional_kg_per_day, ...
        'VariableNames',{'BatterySpecificEnergy_Whkg', ...
        'ConventionalFuelBurn_kg','UnoptimizedFuelBurn_kg', ...
        'UnoptimizedFuelSavedVsConventional_kg'});
end
Summary=vertcat(Rows{:});
writetable(Summary,fullfile(OutputRoot,"Sequence_0008_Unoptimized_Summary.csv"));
disp(Summary); clear Cleanup
end


function Restore(S)
N=string(fieldnames(S));
for k=1:numel(N),setenv(N(k),S.(N(k)));end
end
