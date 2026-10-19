% Generate repeatable whole-sequence comparison plots from completed
% all-sequence production checkpoints. No optimization is rerun.

clearvars;
clc;

RootDir = fileparts(mfilename("fullpath"));
RunDir = fullfile(RootDir, "output", "all_sequences_full_comparison");
CheckpointDir = fullfile(RunDir, "checkpoints");
PlotRoot = fullfile(RunDir, "plots");
if ~isfolder(PlotRoot), mkdir(PlotRoot); end

Files = dir(fullfile(CheckpointDir, "Sequence_*.mat"));
Completed = [];
for k = 1:numel(Files)
    FileName = fullfile(Files(k).folder, Files(k).name);
    try
        M = load(FileName, "Status", "RunMetadata");
        if M.Status == "success" && M.RunMetadata.MaxIterations == 500
            Completed(end + 1) = M.RunMetadata.SequenceIndex; %#ok<SAGROW>
        end
    catch
    end
end
Completed = unique(Completed);
if isempty(Completed)
    error("No completed 500-iteration production checkpoints are available.");
end

rng(20261014, "twister");
nSample = min(3, numel(Completed));
RandomSelected = Completed(randperm(numel(Completed), nSample));
% Also retain the strongest joint-versus-individual result found in the
% first 174 completed remote checkpoints as a useful non-random diagnostic.
PrioritySequences = intersect(177, Completed, "stable");
Selected = sort(unique([RandomSelected, PrioritySequences]));
fprintf("Plotting completed sequences: %s\n", mat2str(Selected));

SelectedSummary = table;
for iSample = 1:numel(Selected)
    iSequence = Selected(iSample);
    InputFile = fullfile(CheckpointDir, ...
        sprintf("Sequence_%04d.mat", iSequence));
    D = load(InputFile, "MissionResults", "ChargeHistories", ...
        "FlightResults", "ChargeResults", "SequenceSummary", "Sequence");
    SequencePlotDir = fullfile(PlotRoot, sprintf("Sequence_%04d", iSequence));
    if ~isfolder(SequencePlotDir), mkdir(SequencePlotDir); end

    Cases = ["Joint", "Individual", "Unoptimized", "Conventional"];
    Timelines = struct;
    for iCase = 1:numel(Cases)
        Timelines.(Cases(iCase)) = BuildTimeline( ...
            D.MissionResults, D.Sequence, Cases(iCase));
    end

    PHECases = ["Joint", "Individual", "Unoptimized"];
    SOCTimelines = struct;
    for iCase = 1:numel(PHECases)
        SOCTimelines.(PHECases(iCase)) = BuildSOCTimeline( ...
            D.MissionResults, D.ChargeHistories, D.Sequence, PHECases(iCase));
    end

    MakePowerPlot(Timelines, Cases, iSequence, SequencePlotDir);
    MakeSOCFuelPlot(Timelines, SOCTimelines, Cases, PHECases, ...
        iSequence, SequencePlotDir);
    MakePropulsionPlot(Timelines, Cases, iSequence, SequencePlotDir);
    MakeTrajectoryPlot(Timelines, Cases, iSequence, SequencePlotDir);
    MakeObjectivePlot(D.FlightResults, D.ChargeResults, ...
        D.SequenceSummary, iSequence, SequencePlotDir);
    MakeSplitPlot(Timelines, PHECases, iSequence, SequencePlotDir);
    MakeSixPanelSequencePlot(Timelines, SOCTimelines, ...
        iSequence, SequencePlotDir);

    writetable(D.FlightResults, fullfile(SequencePlotDir, ...
        sprintf("Sequence_%04d_FlightResults.csv", iSequence)));
    writetable(D.ChargeResults, fullfile(SequencePlotDir, ...
        sprintf("Sequence_%04d_ChargeResults.csv", iSequence)));
    writetable(D.SequenceSummary, fullfile(SequencePlotDir, ...
        sprintf("Sequence_%04d_Summary.csv", iSequence)));
    SelectedSummary = [SelectedSummary; D.SequenceSummary]; %#ok<AGROW>
end

writetable(SelectedSummary, fullfile(PlotRoot, ...
    "RandomCompletedSequences_Summary.csv"));
save(fullfile(PlotRoot, "RandomCompletedSequences_Selection.mat"), ...
    "Selected", "Completed", "SelectedSummary");


function T = BuildTimeline(MissionResults, Sequence, CaseName)
nFlight = height(Sequence);
T = EmptyTimeline;
TimeOffset_s = 0;
DistanceOffset_nmi = 0;
FuelOffset_kg = 0;
T.FlightStart_h = zeros(nFlight, 1);
T.FlightEnd_h = zeros(nFlight, 1);
T.GroundStart_h = [];
T.GroundEnd_h = [];
for k = 1:nFlight
    R = MissionResults(k).(CaseName);
    H = R.MissionHistory.SI;
    Last = R.MainMissionEndIndex;
    LocalTime_s = H.Performance.Time(1:Last);
    LocalTime_s = LocalTime_s - LocalTime_s(1);
    Time_h = (TimeOffset_s + LocalTime_s) / 3600;
    T.FlightStart_h(k) = Time_h(1);
    T.FlightEnd_h(k) = Time_h(end);
    LocalDistance_nmi = H.Performance.Dist(1:Last) / 1852;
    Fuel = FuelOffset_kg + H.Weight.Fburn(1:Last);

    Pout = H.Power.Pout(1:Last, end) / 1e6;
    Pav = H.Power.Pav(1:Last, end) / 1e6;
    Preq = H.Power.Preq(1:Last, end) / 1e6;
    MDotFuel = sum(H.Propulsion.MDotFuel(1:Last, :), 2);
    TSFC = H.Propulsion.TSFC(1:Last, :);
    TSFC(TSFC <= 0) = NaN;
    TSFC = mean(TSFC, 2, "omitnan") * 1e6;
    TSFC(~isfinite(TSFC)) = NaN;

    nSrc = numel(R.PropArch.SrcType);
    iEM = find(R.PropArch.TrnType == 0);
    iGT = find(R.PropArch.TrnType == 1);
    MotorUtil = mean(R.LamUpsFullRatedUtilization(1:Last, nSrc + iEM), 2);
    TurbineUtil = mean(R.LamUpsFullRatedUtilization(1:Last, nSrc + iGT), 2);
    MotorDwn = mean(R.LamDwn(1:Last, iEM), 2);

    T.Time_h = [T.Time_h; Time_h(:); NaN]; %#ok<AGROW>
    T.Pout_MW = [T.Pout_MW; Pout(:); NaN]; %#ok<AGROW>
    T.Pav_MW = [T.Pav_MW; Pav(:); NaN]; %#ok<AGROW>
    T.Preq_MW = [T.Preq_MW; Preq(:); NaN]; %#ok<AGROW>
    T.Altitude_ft = [T.Altitude_ft; H.Performance.Alt(1:Last) / 0.3048; NaN]; %#ok<AGROW>
    T.Speed_kts = [T.Speed_kts; H.Performance.TAS(1:Last) * 1.943844; NaN]; %#ok<AGROW>
    T.Distance_nmi = [T.Distance_nmi; DistanceOffset_nmi + LocalDistance_nmi(:); NaN]; %#ok<AGROW>
    T.MDotFuel_kgs = [T.MDotFuel_kgs; MDotFuel(:); NaN]; %#ok<AGROW>
    T.TSFC_mgNs = [T.TSFC_mgNs; TSFC(:); NaN]; %#ok<AGROW>
    T.MotorUtilization = [T.MotorUtilization; MotorUtil(:); NaN]; %#ok<AGROW>
    T.TurbineUtilization = [T.TurbineUtilization; TurbineUtil(:); NaN]; %#ok<AGROW>
    T.MotorLamDwn = [T.MotorLamDwn; MotorDwn(:); NaN]; %#ok<AGROW>

    if k == 1
        T.FuelTime_h = Time_h(:);
        T.CumulativeFuel_kg = Fuel(:);
    else
        T.FuelTime_h = [T.FuelTime_h; Time_h(:)]; %#ok<AGROW>
        T.CumulativeFuel_kg = [T.CumulativeFuel_kg; Fuel(:)]; %#ok<AGROW>
    end
    FuelOffset_kg = Fuel(end);
    DistanceOffset_nmi = DistanceOffset_nmi + LocalDistance_nmi(end);
    TimeOffset_s = TimeOffset_s + LocalTime_s(end);
    if k < nFlight
        Ground_s = Sequence.GROUND_TIME(k + 1) * 60;
        T.GroundStart_h(end + 1, 1) = TimeOffset_s / 3600; %#ok<AGROW>
        T.GroundEnd_h(end + 1, 1) = ...
            (TimeOffset_s + Ground_s) / 3600; %#ok<AGROW>
        T.FuelTime_h = [T.FuelTime_h; TimeOffset_s/3600; ...
            (TimeOffset_s + Ground_s)/3600]; %#ok<AGROW>
        T.CumulativeFuel_kg = [T.CumulativeFuel_kg; FuelOffset_kg; FuelOffset_kg]; %#ok<AGROW>
        TimeOffset_s = TimeOffset_s + Ground_s;
    end
end
end


function T = EmptyTimeline
Names = ["Time_h","Pout_MW","Pav_MW","Preq_MW","Altitude_ft", ...
    "Speed_kts","Distance_nmi","MDotFuel_kgs","TSFC_mgNs", ...
    "MotorUtilization","TurbineUtilization","MotorLamDwn", ...
    "FuelTime_h","CumulativeFuel_kg"];
for Name = Names, T.(Name) = []; end
T.FlightStart_h = [];
T.FlightEnd_h = [];
T.GroundStart_h = [];
T.GroundEnd_h = [];
end


function T = BuildSOCTimeline(MissionResults, ChargeHistories, Sequence, CaseName)
nFlight = height(Sequence);
T.Time_h = [];
T.SOC_pct = [];
T.FlightStart_h = zeros(nFlight, 1);
Offset_s = 0;
for k = 1:nFlight
    R = MissionResults(k).(CaseName);
    H = R.MissionHistory.SI;
    Last = R.MainMissionEndIndex;
    Batt = find(R.PropArch.SrcType == 0, 1);
    FlightTime_s = H.Performance.Time(1:Last);
    FlightTime_s = FlightTime_s - FlightTime_s(1);
    T.FlightStart_h(k) = Offset_s / 3600;
    T.Time_h = [T.Time_h; (Offset_s + FlightTime_s(:))/3600]; %#ok<AGROW>
    T.SOC_pct = [T.SOC_pct; H.Power.SOC(1:Last, Batt)]; %#ok<AGROW>
    Offset_s = Offset_s + FlightTime_s(end);
    if k < nFlight
        C = GetChargeHistory(ChargeHistories, CaseName, k);
        T.Time_h = [T.Time_h; (Offset_s + C.Time_s(:))/3600]; %#ok<AGROW>
        T.SOC_pct = [T.SOC_pct; C.SOC(:)]; %#ok<AGROW>
        Ground_s = Sequence.GROUND_TIME(k + 1) * 60;
        Offset_s = Offset_s + Ground_s;
        T.Time_h = [T.Time_h; Offset_s/3600]; %#ok<AGROW>
        T.SOC_pct = [T.SOC_pct; C.SOCEnd]; %#ok<AGROW>
    end
end
end


function C = GetChargeHistory(ChargeHistories, CaseName, k)
% Production checkpoints store charge histories as one scalar struct whose
% case fields are per-ground-stop cell arrays. Keep compatibility with the
% earlier struct-array checkpoint format as well.
if isscalar(ChargeHistories) && iscell(ChargeHistories.(CaseName))
    C = ChargeHistories.(CaseName){k};
else
    C = ChargeHistories(k).(CaseName);
end
end


function MakePowerPlot(T, Cases, Index, OutDir)
Fig = figure("Visible", "off", "Color", "w", "Position", [80 80 1500 900]);
L = tiledlayout(Fig, 2, 2, "TileSpacing", "compact", "Padding", "compact");
for i = 1:numel(Cases)
    Ax = nexttile(L); C = T.(Cases(i));
    plot(Ax, C.Time_h, C.Pout_MW, "LineWidth", 1.25, "DisplayName", "Pout"); hold(Ax,"on");
    plot(Ax, C.Time_h, C.Pav_MW, "--", "LineWidth", 1.15, "DisplayName", "Pav");
    plot(Ax, C.Time_h, C.Preq_MW, ":", "LineWidth", 1.35, "DisplayName", "Preq");
    AddFlightDividers(Ax, C.FlightStart_h); grid(Ax,"on"); title(Ax,Cases(i));
    ylabel(Ax,"Power (MW)"); xlabel(Ax,"Elapsed sequence time (h)"); legend(Ax,"Location","best");
end
title(L, sprintf("Sequence %d: propulsion Pout, Pav, and Preq", Index));
exportgraphics(Fig, fullfile(OutDir, "Power_Pout_Pav_Preq.png"), "Resolution", 180); close(Fig);
end


function MakeSOCFuelPlot(T, S, Cases, PHECases, Index, OutDir)
Colors = lines(4);
Fig = figure("Visible", "off", "Color", "w", "Position", [80 80 1450 820]);
L = tiledlayout(Fig, 2, 1, "TileSpacing", "compact", "Padding", "compact");
Ax = nexttile(L);
for i=1:numel(PHECases), C=S.(PHECases(i)); plot(Ax,C.Time_h,C.SOC_pct,"LineWidth",1.6,"Color",Colors(i,:),"DisplayName",PHECases(i)); hold(Ax,"on"); end
AddFlightDividers(Ax,S.Joint.FlightStart_h); grid(Ax,"on"); ylabel(Ax,"SOC (%)"); legend(Ax,"Location","best");
Ax = nexttile(L);
for i=1:numel(Cases), C=T.(Cases(i)); plot(Ax,C.FuelTime_h,C.CumulativeFuel_kg,"LineWidth",1.6,"Color",Colors(i,:),"DisplayName",Cases(i)); hold(Ax,"on"); end
AddFlightDividers(Ax,T.Joint.FlightStart_h); grid(Ax,"on"); ylabel(Ax,"Cumulative main-mission fuel (kg)"); xlabel(Ax,"Elapsed sequence time (h)"); legend(Ax,"Location","best");
title(L,sprintf("Sequence %d: SOC with charging and cumulative fuel",Index));
exportgraphics(Fig,fullfile(OutDir,"SOC_and_CumulativeFuel.png"),"Resolution",180); close(Fig);
end


function MakePropulsionPlot(T, Cases, Index, OutDir)
Colors=lines(4); Fig=figure("Visible","off","Color","w","Position",[80 80 1450 820]);
L=tiledlayout(Fig,2,1,"TileSpacing","compact","Padding","compact");
Ax=nexttile(L); for i=1:numel(Cases), C=T.(Cases(i)); plot(Ax,C.Time_h,C.MDotFuel_kgs,"LineWidth",1.3,"Color",Colors(i,:),"DisplayName",Cases(i)); hold(Ax,"on"); end
AddFlightDividers(Ax,T.Joint.FlightStart_h); grid(Ax,"on"); ylabel(Ax,"Total fuel flow (kg/s)"); legend(Ax,"Location","best");
Ax=nexttile(L); for i=1:numel(Cases), C=T.(Cases(i)); plot(Ax,C.Time_h,C.TSFC_mgNs,"LineWidth",1.3,"Color",Colors(i,:),"DisplayName",Cases(i)); hold(Ax,"on"); end
AddFlightDividers(Ax,T.Joint.FlightStart_h); grid(Ax,"on"); ylabel(Ax,"Mean positive TSFC (mg/N/s)"); xlabel(Ax,"Elapsed sequence time (h)"); legend(Ax,"Location","best");
title(L,sprintf("Sequence %d: fuel flow and TSFC",Index)); exportgraphics(Fig,fullfile(OutDir,"FuelFlow_and_TSFC.png"),"Resolution",180); close(Fig);
end


function MakeTrajectoryPlot(T, Cases, Index, OutDir)
Colors=lines(4); Fig=figure("Visible","off","Color","w","Position",[80 80 1500 950]);
L=tiledlayout(Fig,3,1,"TileSpacing","compact","Padding","compact");
Fields=["Altitude_ft","Speed_kts","Distance_nmi"]; Labels=["Altitude (ft)","TAS (kt)","Cumulative distance (nmi)"];
for j=1:3, Ax=nexttile(L); for i=1:numel(Cases), C=T.(Cases(i)); plot(Ax,C.Time_h,C.(Fields(j)),"LineWidth",1.25,"Color",Colors(i,:),"DisplayName",Cases(i)); hold(Ax,"on"); end; AddFlightDividers(Ax,T.Joint.FlightStart_h); grid(Ax,"on"); ylabel(Ax,Labels(j)); if j==1,legend(Ax,"Location","best");end; end
xlabel(Ax,"Elapsed sequence time (h)"); title(L,sprintf("Sequence %d: trajectory over the complete daily sequence",Index)); exportgraphics(Fig,fullfile(OutDir,"Trajectory_Altitude_Speed_Distance.png"),"Resolution",180); close(Fig);
end


function MakeObjectivePlot(Flights, Charges, Summary, Index, OutDir)
CaseOrder=["Joint","Individual","Unoptimized","Conventional"]; nFlight=max(Flights.Flight); Fuel=nan(nFlight,4); EndSOC=nan(nFlight,3);
for i=1:4, Rows=Flights.CaseName==CaseOrder(i); Fuel(:,i)=Flights.FuelBurn_kg(Rows); if i<=3,EndSOC(:,i)=Flights.EndSOC_pct(Rows);end; end
JointCharge=Charges(Charges.CaseName=="Joint",:);
Fig=figure("Visible","off","Color","w","Position",[80 80 1500 900]); L=tiledlayout(Fig,2,2,"TileSpacing","compact","Padding","compact");
Ax=nexttile(L); bar(Ax,Fuel); grid(Ax,"on"); xlabel(Ax,"Flight"); ylabel(Ax,"Fuel burn (kg)"); legend(Ax,CaseOrder,"Location","best"); title(Ax,"Main-mission fuel by flight");
Ax=nexttile(L); bar(Ax,EndSOC); grid(Ax,"on"); xlabel(Ax,"Flight"); ylabel(Ax,"Landing SOC (%)"); legend(Ax,CaseOrder(1:3),"Location","best"); title(Ax,"Beginning-to-landing dispatch outcome");
Ax=nexttile(L); if ~isempty(JointCharge), yyaxis(Ax,"left"); bar(Ax,JointCharge.AfterFlight,JointCharge.SOCAdded_pct); ylabel(Ax,"SOC added (% points)"); yyaxis(Ax,"right"); plot(Ax,JointCharge.AfterFlight,JointCharge.ActualTime_min,"o-","LineWidth",1.5); ylabel(Ax,"Charge time (min)"); end; grid(Ax,"on"); xlabel(Ax,"After flight"); title(Ax,"Joint charging");
Ax=nexttile(L); Values=[Summary.JointFuelSavedVsUnoptimized_kg_per_day,Summary.IndividualFuelSavedVsUnoptimized_kg_per_day,Summary.JointFuelSavedVsConventional_kg_per_day,Summary.IndividualFuelSavedVsConventional_kg_per_day]; bar(Ax,Values); yline(Ax,0,"k-"); grid(Ax,"on"); ylabel(Ax,"Fuel saved (kg/day)"); xticks(Ax,1:4); xticklabels(Ax,["Joint vs unopt","Individual vs unopt","Joint vs conv","Individual vs conv"]); xtickangle(Ax,20); title(Ax,"Daily objective comparison");
title(L,sprintf("Sequence %d: objective and battery summary",Index)); exportgraphics(Fig,fullfile(OutDir,"Objectives_Fuel_SOC_Charging.png"),"Resolution",180); close(Fig);
end


function MakeSplitPlot(T, Cases, Index, OutDir)
Colors=lines(3); Fig=figure("Visible","off","Color","w","Position",[80 80 1450 900]); L=tiledlayout(Fig,3,1,"TileSpacing","compact","Padding","compact");
Fields=["MotorUtilization","TurbineUtilization","MotorLamDwn"]; Labels=["Motor Pout/full-rated Pav","Turbine Pout/full-rated Pav","Motor LamDwn"];
for j=1:3, Ax=nexttile(L); for i=1:numel(Cases), C=T.(Cases(i)); plot(Ax,C.Time_h,C.(Fields(j)),"LineWidth",1.25,"Color",Colors(i,:),"DisplayName",Cases(i)); hold(Ax,"on"); end; AddFlightDividers(Ax,T.Joint.FlightStart_h); ylim(Ax,[-0.03 1.05]); grid(Ax,"on"); ylabel(Ax,Labels(j)); if j==1,legend(Ax,"Location","best");end; end
xlabel(Ax,"Elapsed sequence time (h)"); title(L,sprintf("Sequence %d: electrical/turbine utilization and split",Index)); exportgraphics(Fig,fullfile(OutDir,"PowerSplit_and_FullRatedUtilization.png"),"Resolution",180); close(Fig);
end


function MakeSixPanelSequencePlot(T, S, Index, OutDir)
% One compact whole-day diagnostic requested for direct case comparison.
Cases = ["Conventional","Unoptimized","Individual","Joint"];
Labels = ["Conventional","Unoptimized PHE", ...
    "Individual optimized","Sequence optimized"];
Colors = [0.4940 0.1840 0.5560; ...
          0.4660 0.6740 0.1880; ...
          0.8500 0.3250 0.0980; ...
          0.0000 0.4470 0.7410];
Reference = T.Joint;

Fig = figure("Visible", "off", "Color", "w", ...
    "Position", [40 40 1750 1850]);
L = tiledlayout(Fig, 6, 1, "TileSpacing", "compact", ...
    "Padding", "compact");

% 1. Altitude and cumulative distance share the time axis. Shaded regions
% are the scheduled ground intervals between flights.
Ax = nexttile(L); yyaxis(Ax, "left");
for i = 1:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.Time_h, C.Altitude_ft / 1000, "-", ...
        "LineWidth", 1.25, "Color", Colors(i, :), ...
        "DisplayName", Labels(i) + " altitude"); hold(Ax, "on");
end
ylabel(Ax, "Altitude (kft)");
yyaxis(Ax, "right");
for i = 1:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.Time_h, C.Distance_nmi, "--", ...
        "LineWidth", 1.15, "Color", Colors(i, :), ...
        "DisplayName", Labels(i) + " distance"); hold(Ax, "on");
end
ylabel(Ax, "Cumulative distance (nmi)");
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); legend(Ax, "Location", "eastoutside", "NumColumns", 2);
title(Ax, "Trajectory and scheduled ground time");

% 2. Battery SOC, including the thermal-equivalent-circuit charging trace.
Ax = nexttile(L);
plot(Ax, nan, nan, "LineWidth", 1.4, "Color", Colors(1, :), ...
    "DisplayName", Labels(1) + " (no battery)"); hold(Ax, "on");
for i = 2:numel(Cases)
    C = S.(Cases(i));
    plot(Ax, C.Time_h, C.SOC_pct, "LineWidth", 1.45, ...
        "Color", Colors(i, :), "DisplayName", Labels(i));
end
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); ylim(Ax, [0 105]); ylabel(Ax, "Battery SOC (%)");
legend(Ax, "Location", "eastoutside"); title(Ax, "SOC and ground charging");

% 3. Recalculated electric-machine utilization (effective lambda-up).
Ax = nexttile(L);
plot(Ax, nan, nan, "LineWidth", 1.3, "Color", Colors(1, :), ...
    "DisplayName", Labels(1) + " (no EM)"); hold(Ax, "on");
for i = 2:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.Time_h, C.MotorUtilization, "LineWidth", 1.25, ...
        "Color", Colors(i, :), "DisplayName", Labels(i));
end
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); ylim(Ax, [-0.03 1.05]);
ylabel(Ax, "EM effective \lambda_{up}"); legend(Ax, "Location", "eastoutside");
title(Ax, "Electric-machine utilization");

% 4. Recalculated gas-turbine utilization (effective lambda-up).
Ax = nexttile(L);
for i = 1:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.Time_h, C.TurbineUtilization, "LineWidth", 1.25, ...
        "Color", Colors(i, :), "DisplayName", Labels(i)); hold(Ax, "on");
end
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); ylim(Ax, [-0.03 1.05]);
ylabel(Ax, "GT effective \lambda_{up}"); legend(Ax, "Location", "eastoutside");
title(Ax, "Gas-turbine utilization");

% 5. Required and available power are combined to retain six panels.
Ax = nexttile(L);
for i = 1:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.Time_h, C.Preq_MW, "-", "LineWidth", 1.25, ...
        "Color", Colors(i, :), "DisplayName", Labels(i) + " P_{req}");
    hold(Ax, "on");
    plot(Ax, C.Time_h, C.Pav_MW, "--", "LineWidth", 1.15, ...
        "Color", Colors(i, :), "DisplayName", Labels(i) + " P_{av}");
end
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); ylabel(Ax, "Power (MW)");
legend(Ax, "Location", "eastoutside", "NumColumns", 2);
title(Ax, "Required power (solid) and available power (dashed)");

% 6. Main-mission fuel only, held flat during ground time.
Ax = nexttile(L);
for i = 1:numel(Cases)
    C = T.(Cases(i));
    plot(Ax, C.FuelTime_h, C.CumulativeFuel_kg, "LineWidth", 1.45, ...
        "Color", Colors(i, :), "DisplayName", Labels(i)); hold(Ax, "on");
end
AddGroundRegions(Ax, Reference.GroundStart_h, Reference.GroundEnd_h);
grid(Ax, "on"); ylabel(Ax, "Cumulative fuel burn (kg)");
xlabel(Ax, "Elapsed sequence time, including ground time (h)");
legend(Ax, "Location", "eastoutside"); title(Ax, "Main-mission fuel burn");

title(L, sprintf(['Sequence %d: conventional, unoptimized PHE, ' ...
    'individual optimization, and sequence optimization'], Index));
OutFile = fullfile(OutDir, sprintf( ...
    "Sequence_%04d_SixPanel_WholeSequence.png", Index));
exportgraphics(Fig, OutFile, "Resolution", 200);
savefig(Fig, replace(OutFile, ".png", ".fig"));
close(Fig);
end


function AddGroundRegions(Ax, Starts, Ends)
for k = 1:numel(Starts)
    xregion(Ax, Starts(k), Ends(k), ...
        "FaceColor", [0.82 0.82 0.82], "FaceAlpha", 0.18, ...
        "EdgeColor", [0.55 0.55 0.55], "HandleVisibility", "off");
end
end


function AddFlightDividers(Ax, Starts)
for k=2:numel(Starts), xline(Ax,Starts(k),":",sprintf("F%d",k),"HandleVisibility","off"); end
end
