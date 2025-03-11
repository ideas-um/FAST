% optimize fuel burn for HEAs flown on AA routes
file = '+ExperimentPkg/AARoutes.xlsx';
route = readtable(file);

HEA = [HEA1; HEA2];

dist = route.Dist;
Alt = route.CrsAlt;

fburn = zeros(height(dist),2);
eBatt = zeros(height(dist),2);

for k = 2
    Aircraft = HEA(k);
    for i = 474:height(dist)
        if dist(i) >2150
            fburn(i,k) = NaN;
            eBatt(i,k) = NaN;
        else
            Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(dist(i), "naut mi", "m");
            Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(Alt(i), "ft", "m");
    
            Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);
    
            fburn(i,k) = Aircraft.Mission.History.SI.Weight.Fburn(74);
            eBatt(i,k) = Aircraft.Mission.History.SI.Energy.E_ES(end,2)/3600; % energy in watthr
        end
        
    end
end

route.HEA1_Fburn = fburn(:,2);
route.HEA1_eBatt = eBatt(:,2);
%route.HEA2_Fburn = fburn(:,2);
%route.HEA2_eBatt = eBatt(:,2);
save("routeTba.mat", "route");
%writetable(route, file)

%% sequnce but with single mission opt
fburn = 0;
nflight = height(Sequence);
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Optimized HEA power for    %
    %           mission          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    

    % run optimizer
    Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);

    % save fuel burn
    fburn = fburn + Aircraft.Mission.History.SI.Weight.Fburn(73);

    % SOC for mission
    %SOC(iflight, :) = Aircraft.Mission.History.SI.Power.SOC(n1:n2+1,2);

    % rate of climb
    %dh_dt(iflight, :) = Aircraft.Mission.History.SI.Performance.RC(n1:n2+1);

    % charge battery
    Aircraft = BatteryPkg.GroundCharge(Aircraft, ChargeTime);

    % assign charges SOC to begSOC for next flight
    Aircraft.Specs.Battery.BegSOC = Aircraft.Mission.History.SI.Power.ChargedAC.SOC(end);
    
    % save optimized aircraft struct
    nameAC = sprintf("OptAircraft%d", iflight);
    OptimizedAircraft.(nameAC) = Aircraft;
end