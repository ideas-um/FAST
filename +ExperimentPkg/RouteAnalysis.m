% optimize fuel burn for HEAs flown on AA routes
file = '+ExperimentPkg/AARoutes.xlsx';
route = readtable(file);

HEA = [HEA1; HEA2];

dist = route.Dist;
Alt = route.CrsAlt;

fburn = zeros(height(dist),2);
eBatt = zeros(height(dist),2);

for k = 1:2
    Aircraft = HEA(k);
    for i = 1:height(dist)
        Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(dist(i), "naut mi", "m");
        Aircraft.Specs.Performance.Alts.Crs = UnitConversionPkg.ConvLength(Alt(i), "ft", "m");

        Aircraft = OptimizationPkg.MissionPowerOpt(Aircraft);

        fburn(i,k) = Aircraft.Mission.History.SI.Weight.Fburn(73);
        eBatt(i,k) = Aircraft.Mission.History.SI.Energy.E_ES(end,2)/3600; % energy in watthr
        
    end
end

route.HEA1_Fburn = fburn(:,1);
route.HEA1_eBatt = eBatt(:,1);
route.HEA2_Fburn = fburn(:,2);
route.HEA2_eBatt = eBatt(:,2);

writetable(route, file)