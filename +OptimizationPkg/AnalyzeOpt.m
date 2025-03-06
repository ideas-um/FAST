function [MissTable, PCOpt, OptmizedAircraft, t] = AnalyzeOpt(Aircraft, Sequence)


% number of missions to fly
nflight = height(Sequence);

% setup a table large enough for all flights
% note that 24 = number of data metrics returned (setup in varTypes/Names)
sz = [nflight*3, 14];

% list the variable types to be returned in the table (24 total)
varTypes = ["double", "string", "double", "double", "double",...
            "double", "double", "double", "double", ...
            "double", "double", "double", "double", ...
             "double"                                  ] ;

% list the variable names to be returned in the table (24 total)
varNames = ["Segment"               , ...
            "Type"                  , ...
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
MissTable = table('Size', sz, 'VariableTypes', varTypes, ...
                            'VariableNames', varNames) ;

% run off design mission
Aircraft.Settings.Analysis.Type = -2;

% turn off FAST print outs
Aircraft.Settings.PrintOut = 0;

% turn off FAST internal SOC constraint
Aircraft.Settings.ConSOC = 0;

% no mission history table
Aircraft.Settings.Table = 0;

% designate space for optimized PC
PCOpt = zeros(73, nflight*2);

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
    GroundTimeMin = Sequence.GROUND_TIME(iflight);
    
    % payload
    Wpayload = Sequence.PAYLOAD_lb(iflight);

    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %                            %
    % convert units              %
    %                            %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % convert ground time from minutes to seconds
    GroundTime = GroundTimeMin * 60;
    
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
    % fly non-optimized aircraft %
    % on mission and save        %
    % performance parameters     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % fly off deisgn mission
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

    % extract desired parmaters
    %[TOGW, Fburn, Ebatt,...
    %SOCi,SOC_TKO, SOC_TOC, SOCf,     ...
    %TSFC_TKO, TSFC_TOC, TSFC_crs] = AnaylzeMiss(Aircraft);
    Results = AnaylzeMiss(Aircraft);

     % SAVE MISSION PERFORMANCE RESULTS 
    %MissTable{iflight*3 - 2, :}= [iflight, "Non-Optimized", Range,...
                            %GroundTimeMin, TOGW, Fburn, Ebatt,...
                            %SOCi,SOC_TKO, SOC_TOC, SOCf,     ...
                            %TSFC_TKO, TSFC_TOC, TSFC_crs] ;

    % SAVE OPTIMIZED MISSION PERFORMANCE RESULTS 
    MissTable{iflight * 3 - 2, :}= [iflight, "Non-Optimized", Range,...
                                    GroundTimeMin, Results] ;

    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % fly non-optimized aircraft %
    % on mission and save        %
    % performance parameters     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [OptAC, t(iflight)] = OptimizationPkg.MissionPowerOpt(Aircraft);

    % extract desired parmaters
    %{
    [TOGW2, Fburn2, Ebatt2,...
    SOCi2,SOC_TKO2, SOC_TOC2, SOCf2,     ...
    TSFC_TKO2, TSFC_TOC2, TSFC_crs2] = AnaylzeMiss(OptAC);

    % SAVE OPTIMIZED MISSION PERFORMANCE RESULTS 
    MissTable{iflight * 3 - 1, :}= [iflight, "Optimized", Range,...
                                    GroundTimeMin, TOGW2, Fburn2, Ebatt2,...
                                    SOCi2,SOC_TKO2, SOC_TOC2, SOCf2,     ...
                                    TSFC_TKO2, TSFC_TOC2, TSFC_crs2] ;
    %}
    Results2 = AnaylzeMiss(OptAC);
    MissTable{iflight * 3 - 1, :}= [iflight, "Optimized", Range,...
                                    GroundTimeMin, Results2] ;

    % ----------------------------------------------------------
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Compare nonoptimized to    %
    %   optimized results and    %
    %       prepare outputs      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    dResults = PerDiff(Results, Results2);
    % save % difference of results 
    MissTable{iflight * 3, :}= [iflight, "% Diff", Range,...
                                GroundTimeMin, dResults] ;
    % save optimized aircraft struct
    nameAC = sprintf("OptAircraft%d", iflight);
    OptmizedAircraft.(nameAC) = OptAC;
    %extract optimized powercode
    PCOpt(:, iflight*2-1 : iflight*2) = OptAC.Specs.Power.PC(1:73, [1,3]);
end


end

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Post Process Off-Design    %
% Aircraft                   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Results = AnaylzeMiss(Aircraft)

%% EXTRACT MISSION SEGMENT INDECES %% 
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

% --------------------------------------------------------------------------------------------------------------------------
%% EXTRACT MISSION SEGMENT INDECES %% 

% takeoff gross weight
TOGW = Aircraft.Specs.Weight.MTOW;

% main mission fuelburn
Fburn = Aircraft.Mission.History.SI.Weight.Fburn(npnt);

% main mission battery energy use
EBatt = Aircraft.Mission.History.SI.Energy.E_ES(npnt, 2);

% SOC after segement values
SOCbeg = Aircraft.Mission.History.SI.Power.SOC(1, 2);
SOCtko = Aircraft.Mission.History.SI.Power.SOC(EndTko, 2);
SOCclb = Aircraft.Mission.History.SI.Power.SOC(EndClb, 2);
SOCf = Aircraft.Mission.History.SI.Power.SOC(npnt, 2);

% mission seg TSFC values
TSFC_tko = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(1     :EndTko))/EndTko            ;
TSFC_clb = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndTko:EndClb))/(EndClb-EndTko +1);
TSFC_crs = sum(Aircraft.Mission.History.SI.Propulsion.TSFC(EndClb:EndCrs))/(EndCrs-EndClb +1);

% save results in a vector
Results = [TOGW, Fburn, EBatt, SOCbeg, SOCtko, SOCclb, SOCf, TSFC_tko, TSFC_clb, TSFC_crs];

end

function d = PerDiff(a, b)
    d = (a-b)./a .* 100;
end