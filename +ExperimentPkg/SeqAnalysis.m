


OptACs = OptimizedAircraft;

fburn = OptACs.OptAircraft1.Mission.History.SI.Weight.Fburn(73) + ...
        OptACs.OptAircraft2.Mission.History.SI.Weight.Fburn(73) + ...
        OptACs.OptAircraft3.Mission.History.SI.Weight.Fburn(73) + ...
        OptACs.OptAircraft4.Mission.History.SI.Weight.Fburn(73);

totFuel=OptACs.OptAircraft1.Specs.Weight.Fuel + ...
        OptACs.OptAircraft2.Specs.Weight.Fuel + ...
        OptACs.OptAircraft3.Specs.Weight.Fuel + ...
        OptACs.OptAircraft4.Specs.Weight.Fuel;

        alt1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Alt(1:73);
        alt1(end) = 0;
        t1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Time(1:73);
        
        alt2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Alt(1:73);
        alt2(end) = 0;
        t2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Time(1:73) + t1(end) + 46*60;
        
        alt3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Alt(1:73);
        t3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Time(1:73) + t2(end) + 32*60;
        alt3(end) = 0;
        alt4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Alt(1:73);
        t4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Time(1:73)+t3(end)+ 27*60;
        alt4(end) = 0;
        alt = [alt1; alt2; alt3; alt4;];
        t = [t1; t2; t3; t4]./60./60;
        


opt = MakeTTable(OptimizedAircraft);
figure;
stackedplot(opt, ["Altitude (m)", "Fuel Burn (kg)", "Ebatt (kWh)", "GT PC", "EM PC"]);
title("AC Performance");

og = MakeTTable(NonOptAC);

tthist = synchronize(opt, og, 'union', 'linear');
figure;
stackedplot(tthist, ["Altitude (m)_opt", "Fuel Burn (kg)_opt", "Fuel Burn (kg)_og", "SOC_opt", "SOC_og", "GT PC_opt", "GT PC_og", "EM PC_opt", "EM PC_og"]);



function [History] = MakeTTable(OptACs)
fburn1 = OptACs.OptAircraft1.Mission.History.SI.Weight.Fburn(1:73);
fburn2 = OptACs.OptAircraft2.Mission.History.SI.Weight.Fburn(1:73) + fburn1(end);
fburn3 = OptACs.OptAircraft3.Mission.History.SI.Weight.Fburn(1:73) + fburn2(end);
fburn4 = OptACs.OptAircraft4.Mission.History.SI.Weight.Fburn(1:73) + fburn3(end);
fburn = [fburn1; fburn2; fburn3; fburn4;];

e1 = OptACs.OptAircraft1.Mission.History.SI.Energy.E_ES(1:73, 2);
e2 = OptACs.OptAircraft2.Mission.History.SI.Energy.E_ES(1:73, 2) + e1(end);
e3 = OptACs.OptAircraft3.Mission.History.SI.Energy.E_ES(1:73, 2) + e2(end);
e4 = OptACs.OptAircraft4.Mission.History.SI.Energy.E_ES(1:73, 2) + e3(end);
e = [e1; e2; e3; e4;]./3600./1000;%kWh

GTPC1 = OptACs.OptAircraft1.Mission.History.SI.Power.PC(1:73, 1);
GTPC1(end) = 0;
GTPC2 = OptACs.OptAircraft2.Mission.History.SI.Power.PC(1:73, 1);
GTPC2(end) = 0;
GTPC3 = OptACs.OptAircraft3.Mission.History.SI.Power.PC(1:73, 1);
GTPC3(end) = 0;
GTPC4 = OptACs.OptAircraft4.Mission.History.SI.Power.PC(1:73, 1);
GTPC4(end) = 0;
GTPC = [GTPC1; GTPC2; GTPC3; GTPC4;];

EMPC1 = OptACs.OptAircraft1.Mission.History.SI.Power.PC(1:73, 3);
EMPC2 = OptACs.OptAircraft2.Mission.History.SI.Power.PC(1:73, 3);
EMPC3 = OptACs.OptAircraft3.Mission.History.SI.Power.PC(1:73, 3);
EMPC4 = OptACs.OptAircraft4.Mission.History.SI.Power.PC(1:73, 3);
EMPC = [EMPC1; EMPC2; EMPC3; EMPC4;];
SOC1 = OptACs.OptAircraft1.Mission.History.SI.Power.SOC(1:73, 2);
SOC2 = OptACs.OptAircraft2.Mission.History.SI.Power.SOC(1:73, 2);
SOC3 = OptACs.OptAircraft3.Mission.History.SI.Power.SOC(1:73, 2);
SOC4 = OptACs.OptAircraft4.Mission.History.SI.Power.SOC(1:73, 2);
SOC = [SOC1; SOC2; SOC3; SOC4;];

alt1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Alt(1:73);
alt1(end) = 0;
t1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Time(1:73);

alt2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Alt(1:73);
alt2(end) = 0;
t2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Time(1:73) + t1(end) + 46*60;

alt3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Alt(1:73);
t3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Time(1:73) + t2(end) + 32*60;
alt3(end) = 0;
alt4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Alt(1:73);
t4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Time(1:73)+t3(end)+ 27*60;
alt4(end) = 0;
alt = [alt1; alt2; alt3; alt4;];
t = [t1; t2; t3; t4]./60;

% make miss hist table
time = minutes(t);
mytable = table(time, alt, fburn, e, SOC, GTPC, EMPC);
mytable.Properties.VariableNames = string(["Time (min)", "Altitude (m)", "Fuel Burn (kg)", "Ebatt (kWh)", "SOC", "GT PC", "EM PC"]);

History = table2timetable(mytable);
end
