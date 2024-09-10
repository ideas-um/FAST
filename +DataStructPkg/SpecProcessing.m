function [Aircraft] = SpecProcessing(Aircraft)
%
% [Aircraft] = SpecProcessing(Aircraft)
% written by Maxfield Arnson, marnson@umich.edu
% lasat updated: 24 apr 2024
%
% This function initializes mission outputs, runs regressions, and
% overwrites values left as NaN in the user input. It prepares the aircraft
% structure such that when called in eapSizing, naming conventions and
% values are consistent with what EAPAnalysis demands. In addition, this
% function throws errors if the user has not complied with required inputs
% or warnings if they have overconstrained their design.
%
%
% INPUTS:
%     Aircraft - aircraft data structure (requires that all possible fields
%                have been instantiated, but may be set to NaN).
%                size/type/units: 1-by-1 / struct / []
%
% OUTPUTS:
%     Aircraft - aircraft data structure with all unspecified parameters
%                set to default values or calculated via regressions.
%                size/type/units: 1-by-1 / struct / []

% NOTE
%----------
% All unused block comments have been removed. Any remaining comments are
% used to store information that may or may not change in the future.
% Default values/projection calls etc. change frequently and when a new
% parameter is implemented it is useful to have the code saved via a
% comment


%% Initialize local structs (easier readability)

Weight = Aircraft.Specs.Weight;
TLAR = Aircraft.Specs.TLAR;
Performance = Aircraft.Specs.Performance;
Aero = Aircraft.Specs.Aero;
Propulsion = Aircraft.Specs.Propulsion;
Power = Aircraft.Specs.Power;
Settings = Aircraft.Settings;
Geometry = Aircraft.Geometry;

% remember the sizing directory
SizeDir = Aircraft.Settings.Dir.Size;


% remove the engine field for the regressions
Engine = Propulsion.Engine;
Propulsion = rmfield(Propulsion,'Engine');


%% Check all required inputs have been entered

if ~isstring(TLAR.Class) && ~ischar(TLAR.Class)
    error('Aircraft Class (Aircraft.TLAR.Class) not specified')
end

if isnan(TLAR.MaxPax)
    error('Number of Passengers (Aircraft.TLAR.MaxPax) not specified')
end

if isnan(Performance.Range)
    error('Design Range (Aircraft.Performance.Range) not specified')
end

if ~isstring(Propulsion.Arch.Type) && ~ischar(Propulsion.Arch.Type)
    error('Propulsion Architecture (Aircraft.Propulsion.Arch) not specified')
end


%% Check for overconstraint on thrust inputs
switch TLAR.Class
    case "Turbofan"
        if sum(isnan([Weight.MTOW, Propulsion.Thrust.SLS, Propulsion.T_W.SLS])) == 0
            warning('Thrust variables (MTOW, T/W, SLS Thrust) overconstrained. Prioritizing MTOW and T/W.')
        end
        %Power.SLS = NaN;
    case "Turboprop"
        if sum(isnan([Weight.MTOW, Power.SLS, Power.P_W.SLS])) == 0
            warning('Power variables (MTOW, P/W, SLS Power) overconstrained. Prioritizing MTOW and P/W.')
        end
        %Propulsion.Thrust.SLS = NaN;
end

%% Set Default year and define future

if isnan(TLAR.EIS)
    TLAR.EIS = 2021;
end

future = 0;
if TLAR.EIS > 2021
    future  = 1;
end

%% Pre-Regression Initializatons
switch TLAR.Class
    case "Turbofan"
        DefaultPropulsion.T_W.SLS = Propulsion.T_W.SLS;
    case "Turboprop"
        DefaultPower.SLS = Power.SLS;
end
DefaultPower.P_W.SLS = Power.P_W.SLS;

DefaultPerformance.Vels.Tko = Performance.Vels.Tko;
DefaultAero.TipChord = NaN;
DefaultAero.RootChord = NaN;
DefaultAero.TaperRatio = NaN;
DefaultAero.Sweep = NaN;
DefaultAero.WingtipDevice = NaN;
DefaultAero.MAC = NaN;
DefaultAero.S = NaN;
DefaultAero.AR = NaN;
DefaultAero.L_D.CrsMAC = NaN;

DefaultWeight.Cargo = NaN;
DefaultWeight.OEW = NaN;
DefaultWeight.OEW_MTOW = NaN;
DefaultWeight.Fuel = NaN;
DefaultWeight.FuelFrac = NaN;

DefaultPropulsion.Fuel.Type = NaN;
DefaultPropulsion.Fuel.Density = NaN;
DefaultPropulsion.Fuel.CapUsable = NaN;
DefaultPropulsion.Fuel.CapUnusable = NaN;
DefaultPropulsion.EngineDesignation = NaN;
DefaultPropulsion.AlternateEngines = NaN;
DefaultPropulsion.Thrust.Crs = NaN;

DefaultPerformance.TOFL = NaN;
DefaultPerformance.Vels.MaxOp = NaN;


%% Regressions and projections



load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
switch TLAR.Class
    case "Turbofan"
        DataAC = TurbofanAC;
        DataEngine = TurbofanEngines; % will be used once engine model specification processing is added
    case "Turboprop"
        DataAC = TurbopropAC;
        DataEngine = TurbopropEngines; % will be used once engine model specification processing is added
end

[knowns,unknowns] = RegressionPkg.VaryUserInputs(Aircraft,TLAR.Class);


Input = [{["Specs","TLAR","EIS"]}, {["Specs","Performance","Range"]}, {["Specs","TLAR","MaxPax"]}, knowns.names];
target = [TLAR.EIS, Performance.Range, TLAR.MaxPax, knowns.values];

w = ones(1,size(target,2)); w(1) = 0.2;
%#ok<*BDSCA> (Suppresses irrelevant warning)
for i = 1:length(unknowns)

    Output = unknowns{i};
    IO = Input;
    IO{end+1} = Output;
    if length(Output) == 4 && isequal(Output,["Specs","Performance","Vels","Crs"])
        [DefaultPerformance.Vels.Crs,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 4 && isequal(Output,["Specs","Performance","Alts","Crs"])
        [DefaultPerformance.Alts.Crs,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 4 && isequal(Output,["Specs","Aero","L_D","Crs"])
        switch TLAR.Class
            case "Turbofan"
                IO{end} = ["Specs","Aero","L_D","CrsMAC"];
                [DefaultAero.L_D.Crs,~] = ...
                    RegressionPkg.NLGPR(DataAC,IO,target,w);
            case "Turboprop"
                DefaultAero.L_D.Crs = 16;
        end
    elseif length(Output) == 3 && isequal(Output,["Specs","Weight","MTOW"])
        [DefaultWeight.MTOW,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 4 && isequal(Output,["Specs","Propulsion","T_W","SLS"])
        %             if future
        %                 [DefaultPropulsion.T_W.SLS] = ...
        %                     Projection.KPPProjection(TLAR.Class, TLAR.EIS, 'Total Takeoff T/ MTOW');
        %             else
        [DefaultPropulsion.T_W.SLS,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
        %             end


    elseif length(Output) == 4 && isequal(Output,["Specs","Propulsion","Thrust","SLS"])
        [DefaultPropulsion.Thrust.SLS,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
        %         elseif length(Output) == 4 && isequal(Output,["Specs","Propulsion","Engine","TSFC_SLS"])
        %             if future
        %                 [DefaultPropulsion.TSFC] = ...
        %                     Projection.KPPProjection(TLAR.Class, TLAR.EIS, 'Cruise SFC');
        %             else
        %                 [DefaultPropulsion.TSFC,~] = ...
        %                     RegressionPkg.NLGPR(DataAC,IO,target,w);
        %             end
    elseif length(Output) == 4 && isequal(Output,["Specs","Power","P_W","SLS"])
        [DefaultPower.P_W.SLS,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 3 && isequal(Output,["Specs","Power","SLS"])
        [DefaultPower.SLS,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 3 && isequal(Output,["Specs","Weight","Fuel"])
        [DefaultWeight.Fuel,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    elseif length(Output) == 4 && isequal(Output,["Specs","Aero","W_S","SLS"])
        [DefaultAero.W_S.SLS,~] = ...
            RegressionPkg.NLGPR(DataAC,IO,target,w);
    end
end




%% Variables that use regression values
switch TLAR.Class

    case "Turbofan"
        try
            DefaultPropulsion.Thrust.SLS = DefaultPropulsion.T_W.SLS*DefaultWeight.MTOW;
        catch
            try
                DefaultPropulsion.Thrust.SLS = Propulsion.T_W.SLS*DefaultWeight.MTOW;
            catch
                try
                    DefaultPropulsion.Thrust.SLS = DefaultPropulsion.T_W.SLS*Weight.MTOW;
                catch
                    DefaultPropulsion.Thrust.SLS = Propulsion.T_W.SLS*Weight.MTOW;
                end
            end
        end

    case "Turboprop"
        try
            DefaultPower.SLS = DefaultPower.P_W.SLS*DefaultWeight.MTOW;
        catch
            try
                DefaultPower.SLS = Power.P_W.SLS*DefaultWeight.MTOW;
            catch
                try
                    DefaultPower.SLS = DefaultPower.P_W.SLS*Weight.MTOW;
                catch
                    DefaultPower.SLS = Power.P_W.SLS*Weight.MTOW;
                end
            end
        end

        % multiply by 1000 to convert from kW/kg to W/kg
        DefaultPower.SLS = DefaultPower.SLS * 1000;
end


if isnan(Aero.L_D.Crs)
    DefaultAero.L_D.Clb = DefaultAero.L_D.Crs*0.6;   % 60% cruise L_D
else
    DefaultAero.L_D.Clb = Aero.L_D.Crs*0.6;   % 60% cruise L_D
end

DefaultAero.L_D.Des = DefaultAero.L_D.Clb; % set descent L/D to Clb value

%% Set Default Variable Values

% Default_TLAR.EIS = 2021;                   % already specified
% Default_TLAR.Class = 'Turbofan';           *required*
%Default_TLAR.MaxPax = 150;                     % switch case
% DefaultPerformance.Vels.Tko = 0;           *regression*
% DefaultPerformance.Vels.Crs = 0;            *regression*
%DefaultPerformance.Vels.Type = 'TAS';        % good
DefaultPerformance.Alts.Tko = 0;             % good
% DefaultPerformance.Alts.Crs = 0;            *regression*
% DefaultPerformance.Range =                 *required*
DefaultPerformance.RCMax = 10.5;             % m/s
switch TLAR.Class
    case "Turbofan"
        DefaultPerformance.Vels.Tko = UnitConversionPkg.ConvVel(135,'kts','m/s');
    case "Turboprop"
        DefaultPerformance.Vels.Tko = UnitConversionPkg.ConvVel(115,'kts','m/s');
end
% DefaultAero.L_D.Clb = 15;                    % 0.6*cruise L_D
%DefaultAero.L_D.Crs = 15;                     % regression
%DefaultWeight.MTOW = 0;                     % regression
DefaultWeight.MLW = 0;                      % good
DefaultWeight.Batt = 0;                      % good
DefaultWeight.EG = 0;                        % good
DefaultWeight.EM = 0;                        % good
DefaultWeight.WairfCF = 1;
% DefaultWeight.Fuel = 0;                    % regression
% DefaultPropulsion.Arch = 'C';             *required*
DefaultPropulsion.NumEngines = 2;           % good
DefaultPropulsion.MDotCF = 1;
%DefaultPropulsion.T_W.SLS = 0;                  % regression
%DefaultPropulsion.Thrust.SLS = 0;           % regression
%DefaultPropulsion.Thrust.Tko = DefaultPropulsion.Thrust.SLS;
%DefaultPropulsion.Thrust.Crs = 0;           % regression
% DefaultPropulsion.TSFC = 0.5;              % regression
%DefaultPropulsion.Eta.Therm = 0.3;          % switch case
%DefaultPropulsion.Eta.Prop = 0.85;          % switch case
% DefaultPower.P_W.AC = 5;                    regression
% DefaultPower.P_W.Batt =                     *calculated*
DefaultPower.Eta.Propeller = 0.8;
DefaultPower.Phi.SLS = 0;                     % good
DefaultPower.Phi.Tko = 0;                     % good
DefaultPower.Phi.Clb = 0;                     % good
DefaultPower.Phi.Crs = 0;                     % good
DefaultPower.Phi.Des = 0;                     % good
DefaultPower.Phi.Lnd = 0;                     % good
DefaultPower.P_W.EG = 5;                      % good
%DefaultPower.P_W.EM = 5;                     % EDC Projection
% DefaultPower.SpecEnergy.Fuel = 4.32e7;               % if statement
%DefaultPower.SpecEnergy.Batt = 0;                     % EDC Projection
%DefaultPower.Eta.EM = 0.96;                 % switch case
%DefaultPower.Eta.EG = 0.96;                 % switch case
DefaultPower.LamTS.Tko = 0;
DefaultPower.LamTS.Clb = 0;
DefaultPower.LamTS.Crs = 0;
DefaultPower.LamTS.Des = 0;
DefaultPower.LamTS.Lnd = 0;
DefaultPower.LamTS.SLS = 0;
DefaultPower.LamTSPS.Tko = 0;
DefaultPower.LamTSPS.Clb = 0;
DefaultPower.LamTSPS.Crs = 0;
DefaultPower.LamTSPS.Des = 0;
DefaultPower.LamTSPS.Lnd = 0;
DefaultPower.LamTSPS.SLS = 0;
DefaultPower.LamPSPS.Tko = 0;
DefaultPower.LamPSPS.Clb = 0;
DefaultPower.LamPSPS.Crs = 0;
DefaultPower.LamPSPS.Des = 0;
DefaultPower.LamPSPS.Lnd = 0;
DefaultPower.LamPSPS.SLS = 0;
DefaultPower.LamPSES.Tko = 0;
DefaultPower.LamPSES.Clb = 0;
DefaultPower.LamPSES.Crs = 0;
DefaultPower.LamPSES.Des = 0;
DefaultPower.LamPSES.Lnd = 0;
DefaultPower.LamPSES.SLS = 0;
DefaultPower.Battery.ParCells = NaN;
DefaultPower.Battery.SerCells = NaN;
DefaultPower.Battery.BegSOC   = NaN;

%% Default Settings
DefaultSettings.TkoPoints = 10;
DefaultSettings.ClbPoints = 10;
DefaultSettings.CrsPoints = 10;
DefaultSettings.DesPoints = 10;
DefaultSettings.OEW.MaxIter = 20;
DefaultSettings.OEW.Tol = 1e-6;
DefaultSettings.Analysis.MaxIter = 50;
DefaultSettings.Analysis.Type = 1;       % 1 = on design. -1 = off design
DefaultSettings.Plotting = 0;            % 1 = plot 0 = no plots
DefaultSettings.Table = 0;
DefaultSettings.VisualizeAircraft = 0;

% optimization settings.
DefaultSettings.PowerOpt.DesPowSplit =  0;
DefaultSettings.PowerOpt.OpsPowSplit =  0;

% directory
DefaultSettings.Dir.Size = pwd;

% get the folder that the EAP repository lives in
HomeFolder = fileparts(pwd);
% replace EAP with EAP-CNAP to get the operations directory
DefaultSettings.Dir.Oper = fullfile(HomeFolder, "EAP-CNAP");



%% Default gravimetric Fuel energy

switch TLAR.Class
    case "Piston"
        DefaultPower.SpecEnergy.Fuel = 4.465e7/3.6e6; % BP Avgas 80
    otherwise
        DefaultPower.SpecEnergy.Fuel = 4.32e7/3.6e6;  % Jet A
end

%% Default Efficiencies

DefaultPropulsion.Eta.Therm = 0.3;
DefaultPropulsion.Eta.Prop = 0.85;
DefaultPower.Eta.EM = 0.96;
DefaultPower.Eta.EG = 0.96;

%% EDC Projections
DefaultPower.P_W.EM = ProjectionPkg.KPPProjection(TLAR.Class, TLAR.EIS, 'Electric Motor Specific Power');
DefaultPower.SpecEnergy.Batt = ProjectionPkg.KPPProjection(TLAR.Class,TLAR.EIS,'Battery Specific Energy');
DefaultPower.SpecEnergy.Batt = DefaultPower.SpecEnergy.Batt/1e3; % W to KW per kg

%% Geometry Presets
% Shape Preset
switch TLAR.Class
    case "Turbofan"
        if TLAR.MaxPax > 200 % CHANGE THIS LATER/ find exact pax count
            DefaultGeometry.Preset = @(ACStruct)VisualizationPkg.GeometrySpecsPkg.LargeTurbofan(ACStruct);
        elseif TLAR.MaxPax > 100
            DefaultGeometry.Preset = @(ACStruct)VisualizationPkg.GeometrySpecsPkg.SmallDoubleAisleTurbofan(ACStruct); 
        else
            DefaultGeometry.Preset = @(ACStruct)VisualizationPkg.GeometrySpecsPkg.Transport(ACStruct);
        end
    case "Turboprop"
        if TLAR.MaxPax > 19
            DefaultGeometry.Preset = @(ACStruct)VisualizationPkg.GeometrySpecsPkg.LargeTurboprop(ACStruct);
        else
            DefaultGeometry.Preset = @(ACStruct)VisualizationPkg.GeometrySpecsPkg.SmallTurboprop(ACStruct);
        end
end

[DefaultGeometry.LengthSet,~] = RegressionPkg.NLGPR(DataAC,...
    {["Specs","TLAR","MaxPax"],["Specs","Aero","Length"]},TLAR.MaxPax);


%% Set equivalent thrust or power for turbofans and turboprops

switch TLAR.Class
    case "Turbofan"
        DefaultPower.P_W.AC = DefaultPropulsion.T_W.SLS*DefaultPerformance.Vels.Tko;
        if isfield(Power.Eta,"Propeller")
            Power.Eta = rmfield(Power.Eta,"Propeller");
        end
        if isfield(Power,"SLS")
            Power = rmfield(Power,"SLS");
        end
    case "Turboprop"
        DefaultPropulsion.Thrust.T_W.SLS = DefaultPower.P_W.SLS/DefaultPerformance.Vels.Tko;
        if isfield(Propulsion,"T_W")
            Propulsion = rmfield(Propulsion,"T_W");
        end
        if isfield(Propulsion,"Thrust")
            Propulsion = rmfield(Propulsion,"Thrust");
        end
end


%% Overwrite NaNs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                          %
% Overwrite NaN Inputs with Default Values %
%                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Keep this comment block in the case Non-required TLAR variables get added
% in the future

% Overwrite NaNs in TLAR structure
% TLARfields = fieldnames(TLAR);
% for i = 1:length(TLARfields)
%     if isstruct(TLAR.(TLARfields{i}))
%         subfields = fieldnames(TLAR.(TLARfields{i}));
%         for j = 1:length(subfields)
%             if isnan(TLAR.(TLARfields{i}).(subfields{j}))
%                 TLAR.(TLARfields{i}).(subfields{j}) = Default_TLAR.(TLARfields{i}).(subfields{j});
%             end
%         end
%     elseif isnan(TLAR.(TLARfields{i}))
%         TLAR.(TLARfields{i}) = Default_TLAR.(TLARfields{i});
%     end
% end

% Overwrite NaNs in perormance Structure
Performancefields = fieldnames(Performance);
for i = 1:length(Performancefields)
    if isstruct(Performance.(Performancefields{i}))
        subfields = fieldnames(Performance.(Performancefields{i}));
        for j = 1:length(subfields)
            if isstring(Performance.(Performancefields{i}).(subfields{j})) || ischar(Performance.(Performancefields{i}).(subfields{j}))
            elseif isnan(Performance.(Performancefields{i}).(subfields{j}))
                Performance.(Performancefields{i}).(subfields{j}) = DefaultPerformance.(Performancefields{i}).(subfields{j});
            end
        end
    elseif isnan(Performance.(Performancefields{i}))
        Performance.(Performancefields{i}) = DefaultPerformance.(Performancefields{i});
    end
end


% Overwrite NaNs in Aero structure
Aerofields = fieldnames(Aero);
for i = 1:length(Aerofields)
    if isstruct(Aero.(Aerofields{i}))
        subfields = fieldnames(Aero.(Aerofields{i}));
        for j = 1:length(subfields)
            if isnan(Aero.(Aerofields{i}).(subfields{j}))
                Aero.(Aerofields{i}).(subfields{j}) = DefaultAero.(Aerofields{i}).(subfields{j});
            end
        end
    elseif isnan(Aero.(Aerofields{i}))
        Aero.(Aerofields{i}) = DefaultAero.(Aerofields{i});
    end
end

% Overwrite NaNs in Weight structure
Weightfields = fieldnames(Weight);
for i = 1:length(Weightfields)
    if isstruct(Weight.(Weightfields{i}))
        subfields = fieldnames(Weight.(Weightfields{i}));
        for j = 1:length(subfields)
            if isnan(Weight.(Weightfields{i}).(subfields{j}))
                Weight.(Weightfields{i}).(subfields{j}) = DefaultWeight.(Weightfields{i}).(subfields{j});
            end
        end
    elseif isnan(Weight.(Weightfields{i}))
        Weight.(Weightfields{i}) = DefaultWeight.(Weightfields{i});
    end
end


% Overwrite NaNs in Propulsion structure
Propulsionfields = fieldnames(Propulsion);
for i = 1:length(Propulsionfields)
    if isstruct(Propulsion.(Propulsionfields{i}))
        subfields = fieldnames(Propulsion.(Propulsionfields{i}));
        for j = 1:length(subfields)
            if isstring(Propulsion.(Propulsionfields{i}).(subfields{j})) || ischar(Propulsion.(Propulsionfields{i}).(subfields{j})) || isa(Propulsion.(Propulsionfields{i}).(subfields{j}), 'function_handle')
            elseif isnan(Propulsion.(Propulsionfields{i}).(subfields{j}))
                Propulsion.(Propulsionfields{i}).(subfields{j}) = DefaultPropulsion.(Propulsionfields{i}).(subfields{j});
            end
        end
    elseif isstring(Propulsion.(Propulsionfields{i})) || ischar(Propulsion.(Propulsionfields{i}))
    elseif isnan(Propulsion.(Propulsionfields{i}))
        Propulsion.(Propulsionfields{i}) = DefaultPropulsion.(Propulsionfields{i});
    end
end
% error('update propulsion substruct finder')

% Overwrite NaNs in Power structure
Powerfields = fieldnames(Power);
for i = 1:length(Powerfields)
    if isstruct(Power.(Powerfields{i}))
        subfields = fieldnames(Power.(Powerfields{i}));
        for j = 1:length(subfields)
            if iscell(Power.(Powerfields{i}).(subfields{j}))
                continue;
            elseif isnan(Power.(Powerfields{i}).(subfields{j}))
                Power.(Powerfields{i}).(subfields{j}) = DefaultPower.(Powerfields{i}).(subfields{j});
            end
        end
    elseif isnan(Power.(Powerfields{i}))
        Power.(Powerfields{i}) = DefaultPower.(Powerfields{i});
    end
end


% Overwrite NaNs in Settings structure
Settingsfields = fieldnames(Settings);
for i = 1:length(Settingsfields)
    if isstruct(Settings.(Settingsfields{i}))
        subfields = fieldnames(Settings.(Settingsfields{i}));
        for j = 1:length(subfields)
            % Keep comment block in the case more Settings variables are
            % added in the future

            %if isstruct(Settings.(Settingsfields{i}).(subfields{j}))
            %subsubfields = fieldnames(Settings.(Settingsfields{i}).(subfields{j}));
            %                 for k = 1:length(subsubfields)
            %                     if isnan(Settings.(Settingsfields{i}).(subfields{j}).(subsubfields{k}))
            %                         Settings.(Settingsfields{i}).(subfields{j}).(subsubfields{k}) = DefaultSettings.(Settingsfields{i}).(subfields{j}).(subsubfields{k});
            %                     end
            %                 end
            if (isstring(Settings.(Settingsfields{i}).(subfields{j})))
                continue;
            elseif isnan(Settings.(Settingsfields{i}).(subfields{j}))
                Settings.(Settingsfields{i}).(subfields{j}) = DefaultSettings.(Settingsfields{i}).(subfields{j});
            end
        end
    elseif isnan(Settings.(Settingsfields{i}))
        Settings.(Settingsfields{i}) = DefaultSettings.(Settingsfields{i});
    end
end



% Geometry presets (hardcoded, change later?)
if isnan(Geometry.LengthSet)
    Geometry.LengthSet = DefaultGeometry.LengthSet;
end

if ~isa(Geometry.Preset,"function_handle")
    Geometry.Preset = DefaultGeometry.Preset;
end




%% Convert Units

if Settings.Analysis.Type ~= -2
    Power.P_W.SLS = Power.P_W.SLS*1e3;                             % kW/kg to W/kg
    Power.P_W.EG = Power.P_W.EG*1e3;                               % kW/kg to W/kg
    Power.P_W.EM = Power.P_W.EM*1e3;                               % kW/kg to W/kg
    Power.SpecEnergy.Fuel = Power.SpecEnergy.Fuel*3.6e6;           % kWh/kg to J/kg
    Power.SpecEnergy.Batt = Power.SpecEnergy.Batt*3.6e6;           % kWh/kg to J/kg
end



%% Passenger and Crew Weights

Weight.Payload = Aircraft.Specs.TLAR.MaxPax*95; % atr paper

if Settings.Analysis.Type > -2
    Weight.Crew = Weight.Payload/26.1; % from Martins' Metabook
end


%% Prepare Output Structure
Propulsion.Engine = Engine;

Aircraft.Specs.TLAR = TLAR;
Aircraft.Specs.Performance = Performance;
Aircraft.Specs.Aero = Aero;
Aircraft.Specs.Weight = Weight;
Aircraft.Specs.Propulsion = Propulsion;
Aircraft.Specs.Power = Power;
Aircraft.Settings = Settings;
Aircraft.Geometry = Geometry;
Aircraft.HistData.AC = DataAC;
Aircraft.HistData.Eng = DataEngine;

%% Engine Specs

Aircraft = DataStructPkg.EngineSpecProcessing(Aircraft);


end



