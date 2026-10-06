% Size a conventional ERJ-175LR, fly sequence 8 off design, and compare
% main-mission fuel against the optimized hybrid-electric sequence result.

clearvars;
clc;
TotalRunTimer = tic;
RunStarted = datetime("now");

SequenceData = load("Sequence.mat", "tables");
Sequence = SequenceData.tables{8};

% Size the conventional aircraft once on its design mission.
DesignInput = AircraftSpecsPkg.ERJ175LR;
DesignInput.Settings.Analysis.Type = 1;
DesignInput.Settings.PrintOut = 0;
DesignInput.Settings.Plotting = 0;
DesignInput.Settings.Table = 0;
SizedConventional = Main(DesignInput, @MissionProfilesPkg.ERJ_ClimbThenAccel);

DesignMTOW_kg = SizedConventional.Specs.Weight.MTOW;
DesignOEW_kg = SizedConventional.Specs.Weight.OEW;
DesignFuel_kg = SizedConventional.Specs.Weight.Fuel;

nflight = height(Sequence);
FlightAircraft = struct();
MainMissionFuel_kg = zeros(nflight, 1);
FullProfileFuel_kg = zeros(nflight, 1);
TakeoffWeight_kg = zeros(nflight, 1);
MinimumPowerMargin_W = zeros(nflight, 1);

for iflight = 1:nflight
    Aircraft = SizedConventional;
    Aircraft.Settings.Analysis.Type = -1;
    Aircraft.Settings.PrintOut = 0;
    Aircraft.Settings.Plotting = 0;
    Aircraft.Settings.Table = 0;

    speed = convvel(Sequence.SPEED_mph(iflight), "mph", "m/s");
    Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength( ...
        Sequence.DISTANCE(iflight), "naut mi", "m");
    [~, ~, Aircraft.Specs.Performance.Vels.Crs] = ...
        MissionSegsPkg.ComputeFltCon( ...
        Sequence.ALTITUDE_m(iflight), 0, "TAS", speed);
    Aircraft.Specs.Performance.Alts.Crs = Sequence.ALTITUDE_m(iflight);
    Aircraft.Specs.Weight.Payload = convmass( ...
        Sequence.PAYLOAD_lb(iflight), "lbm", "kg");

    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

    MainSegs = find(Aircraft.Mission.Profile.ID == 1);
    MainEnd = Aircraft.Mission.Profile.SegEnd(MainSegs(end));
    MainMissionFuel_kg(iflight) = ...
        Aircraft.Mission.History.SI.Weight.Fburn(MainEnd);
    FullProfileFuel_kg(iflight) = ...
        Aircraft.Mission.History.SI.Weight.Fburn(end);
    TakeoffWeight_kg(iflight) = ...
        Aircraft.Mission.History.SI.Weight.CurWeight(1);

    PowerMargin = Aircraft.Mission.History.SI.Power.Pav - ...
        Aircraft.Mission.History.SI.Power.Preq;
    MinimumPowerMargin_W(iflight) = ...
        min(PowerMargin, [], "all", "omitnan");

    FlightAircraft.(sprintf("Aircraft%d", iflight)) = Aircraft;
end

TotalConventionalMainFuel_kg = sum(MainMissionFuel_kg);
TotalConventionalFullFuel_kg = sum(FullProfileFuel_kg);

FlightResults = table((1:nflight)', Sequence.DISTANCE, ...
    Sequence.GROUND_TIME, Sequence.PAYLOAD_lb, ...
    MainMissionFuel_kg, FullProfileFuel_kg, TakeoffWeight_kg, ...
    repmat(DesignMTOW_kg, nflight, 1), MinimumPowerMargin_W, ...
    'VariableNames', {'Flight', 'Distance_nmi', 'GroundTime_min', ...
    'Payload_lb', 'ConventionalMainFuel_kg', ...
    'ConventionalFullFuel_kg', 'ConventionalTakeoffWeight_kg', ...
    'ConventionalDesignMTOW_kg', 'ConventionalMinimumPowerMargin_W'});

SizingResults = table(DesignMTOW_kg, DesignOEW_kg, DesignFuel_kg);
TotalRunTime_min = toc(TotalRunTimer) / 60;
RunMetadata = struct( ...
    "SequenceIndex", 8, ...
    "SizingProfile", "MissionProfilesPkg.ERJ_ClimbThenAccel", ...
    "FlightMode", "Fixed-size off-design", ...
    "ComparisonBoundary", "End of main mission (Mission.Profile.ID == 1)", ...
    "ReserveFuelExcludedFromComparison", true, ...
    "RunStarted", string(RunStarted), ...
    "TotalRunTime_min", TotalRunTime_min);

save(fullfile("output", "ERJ175LR_Conventional_Sequence8_MainMission.mat"), ...
    "SizedConventional", "FlightAircraft", "Sequence", ...
    "FlightResults", "SizingResults", ...
    "TotalConventionalMainFuel_kg", "TotalConventionalFullFuel_kg", ...
    "RunMetadata", ...
    "TotalRunTime_min", "RunStarted", "-v7.3");

disp(SizingResults);
disp(FlightResults);
fprintf("Conventional sequence main-mission fuel: %.3f kg\n", ...
    TotalConventionalMainFuel_kg);
fprintf("Total runtime: %.3f min\n", TotalRunTime_min);
