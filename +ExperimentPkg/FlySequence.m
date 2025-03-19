function [ACs, SeqTable] = FlySequence(Aircraft, Sequence)


% number of missions to fly
nflight = height(Sequence);

% setup a table large enough for all flights
% note that 24 = number of data metrics returned (setup in varTypes/Names)
sz = [nflight, 13];

% list the variable types to be returned in the table (24 total)
varTypes = ["double", "double", "double", "double",...
            "double", "double", "double", "double", ...
            "double", "double", "double", "double", ...
             "double"                                  ] ;

% list the variable names to be returned in the table (24 total)
varNames = ["Segment"               , ...
            "Distance (nmi)"        , ...
            "Ground Time (min)"     , ...
            "TOGW (kg)"             , ...
            "Fuel Burn (kg)"        , ...
            "Batt Energy (MJ)"      , ...
            "Intial SOC (%)"        , ...
            "SOC End of Takeoff (%)", ...
            "SOC End of Climb   (%)", ...
            "Final SOC (%)"         , ...
            "Avg Tko TSFC"          , ...
            "Avg Clb TSFC"          , ...
            "Avg Crs TSFC"          ] ;

% setup the table
SeqTable = table('Size', sz, 'VariableTypes', varTypes, ...
                            'VariableNames', varNames) ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% Aircraft  Settings         %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% run off design mission
Aircraft.Settings.Analysis.Type = -2;

% mark optimization
Aircraft.Settings.Analysis.PowerOpt = 0;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% no mission history table
Aircraft.Settings.Table = 0;

% climb beg and end ctrl pt indeces
% get the number of points in each segment
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);

% save storage values
ACs = [];
g = 9.81;
    
%% Nested Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%

fburn = 0;
% iterate through missions
for iflight = 1:nflight
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % extract flight performance %
    % parameters from the table  %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % cruise speed
    speed = Sequence.SPEED_mph(iflight);
    
    % mission range
    Range = Sequence.DISTANCE(iflight); 

    % cruise altitude
    Alt = Sequence.ALTITUDE_m(iflight);
    
    % ground time (mimutes)
    if iflight < nflight
        ChargeTimeMin = Sequence.GROUND_TIME(iflight+1) - 5;
    else
        ChargeTimeMin = 1e3;
    end
    
    % payload
    Wpayload = Sequence.PAYLOAD_lb(iflight);

    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % convert units              %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % convert ground time from minutes to seconds
    ChargeTime = ChargeTimeMin * 60;
    
    % convert speed from mph to m/s
    speed = convvel(speed, 'mph', 'm/s');
    
    % convert mission range from naut mi to m
    RangeM = UnitConversionPkg.ConvLength(Range, "naut mi", "m"); % convert to m
    
    % convert payload from lbm to kg
    Wpayload = convmass(Wpayload, 'lbm', 'kg');
    
    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % update aircraft structure  %
    % with the flight's          %
    % performance parameters     %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % mission range
    Aircraft.Specs.Performance.Range = RangeM;

    % convert speed from TAS to Mach
    [~, ~, Mach] = MissionSegsPkg.ComputeFltCon(Alt, 0, "TAS", speed);
    
    % cruise speed
    Aircraft.Specs.Performance.Vels.Crs = Mach;
    
    % cruise altitude
    Aircraft.Specs.Performance.Alts.Crs = Alt;
    
    % payload
    Aircraft.Specs.Weight.Payload = Wpayload;

    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Optimized HEA power for    %
    %           mission          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 Aircraft.Specs.Power.PC(10:36, [3,4]) = 0.05;
%Aircraft.Mission.History.SI.Power.PC(10:36, [3,4]) = 0.05;
    

    % fly mission
    %try
        %Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);
         %save fuel burn
        fburn = fburn + Aircraft.Mission.History.SI.Weight.Fburn(npt);
    %catch
     %   fburn = 10^9;
    %end

if ~isnan(Aircraft.Specs.Power.Battery.ParCells) 
    try
        % charge battery
        Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);

        % assign charges SOC to begSOC for next flight
        Aircraft.Specs.Battery.BegSOC = Aircraft.Mission.History.SI.Power.ChargedAC.SOC(end);
    catch
        Aircraft.Specs.Battery.BegSOC = 20;
    end
end
    
    % save optimized aircraft struct
    nameAC = sprintf("Aircraft%d", iflight);
    ACs.(nameAC) = Aircraft;
end

%% Post-Processing %%
%%%%%%%%%%%%%%%%%%%%%%%%%
for iflight =1:nflight
        nameAC = sprintf("Aircraft%d", iflight);
        Aircraft = ACs.(nameAC);
        results = AnaylzeMiss(Aircraft);
        
        SeqTable{iflight, :}= [iflight, Sequence.DISTANCE(iflight),...
                                Sequence.GROUND_TIME(iflight), results] ;
end

save("Opt_singlemiss.mat", "ACs");
save("single.mat", "SeqTable");

%% ANALYZE AIRCRAFT %%
function Results = AnaylzeMiss(Aircraft)

% get the number of points in each segment
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npnt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);

% get the index of the last takeoff segment
EndTko = Aircraft.Settings.TkoPoints;

% get the index of the last climb segment
EndClb = 2 * Aircraft.Settings.ClbPoints + EndTko - 2;

% get the index of end of cruise
EndCrs = EndClb + Aircraft.Settings.ClbPoints + Aircraft.Settings.CrsPoints + Aircraft.Settings.DesPoints - 3;

% takeoff gross weight
TOGW = Aircraft.Specs.Weight.MTOW;

% main mission fuelburn
Fburn = Aircraft.Mission.History.SI.Weight.Fburn(npnt);

if ~isnan(Aircraft.Specs.Power.Battery.ParCells) 

% main mission battery energy use
EBatt = Aircraft.Mission.History.SI.Energy.E_ES(npnt, 2);

% SOC after segement values
SOCbeg = Aircraft.Mission.History.SI.Power.SOC(1, 2);
SOCtko = Aircraft.Mission.History.SI.Power.SOC(EndTko, 2);
SOCclb = Aircraft.Mission.History.SI.Power.SOC(EndClb, 2);
SOCf = Aircraft.Mission.History.SI.Power.SOC(npnt, 2);
else
% main mission battery energy use
EBatt = NaN;
% SOC 
SOCbeg = NaN;
SOCtko = NaN;
SOCclb = NaN;
SOCf = NaN;
end
% mission seg TSFC values
TSFC_tko = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(1     :EndTko))/EndTko            ;
TSFC_clb = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndTko:EndClb))/(EndClb-EndTko +1);
TSFC_crs = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndClb:EndCrs))/(EndCrs-EndClb +1);

% save results in a vector
Results = [TOGW, Fburn, EBatt, SOCbeg, SOCtko, SOCclb, SOCf, TSFC_tko, TSFC_clb, TSFC_crs];

end


end