


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
        
        figure;
        plot(t, alt, "k", "LineWidth", 1)
        xlabel("Time (hr)")
        ylabel("Alt (m)")
        title("Sequence Flight Profile")



OAC = OptimizedAircraft;
NAC = NonOptAC;

[of, ot] = seqanal(OAC);
[nf, nt] = seqanal(NAC);

dif = (ot - nt)./nt*100;

figure;
plot(nt, nf, "LineWidth",1.5)
hold on
plot(ot, of, "LineWidth",1.5)
title("Cummulative Fuel Burn across Sequence")
xlabel("Time (hr)")
ylabel("Cummulative Fuel Burn (kg)")

yyaxis right
plot(ot, dif, "LineWidth",1)
ylabel("Cummulative Fuel Burn % Difference")
legend("Non-Optimized HEA", "Optimized HEA", "% Diff")
set(gca, "FontSize", 12)

function [f, t] = seqanal(OptACs)
fburn1 = OptACs.OptAircraft1.Mission.History.SI.Weight.Fburn(1:73);
fburn2 = OptACs.OptAircraft2.Mission.History.SI.Weight.Fburn(1:73) + fburn1(end);
fburn3 = OptACs.OptAircraft3.Mission.History.SI.Weight.Fburn(1:73) + fburn2(end);
fburn4 = OptACs.OptAircraft4.Mission.History.SI.Weight.Fburn(1:73) + fburn3(end);
f = [fburn1; fburn2; fburn3; fburn4;];

t1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Time(1:73);
t2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Time(1:73) + t1(end) + 46*60;
t3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Time(1:73) + t2(end) + 32*60;
t4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Time(1:73)+t3(end)+ 27*60;
t = [t1; t2; t3; t4]./60./60;

end

function [f, t] = seqanal(OptACs)
fburn1 = OptACs.OptAircraft1.Mission.History.SI.Weight.Fburn(1:73);
fburn2 = OptACs.OptAircraft2.Mission.History.SI.Weight.Fburn(1:73) + fburn1(end);
fburn3 = OptACs.OptAircraft3.Mission.History.SI.Weight.Fburn(1:73) + fburn2(end);
fburn4 = OptACs.OptAircraft4.Mission.History.SI.Weight.Fburn(1:73) + fburn3(end);
f = [fburn1; fburn2; fburn3; fburn4;];

t1 = OptACs.OptAircraft1.Mission.History.SI.Performance.Time(1:73);
t2 = OptACs.OptAircraft2.Mission.History.SI.Performance.Time(1:73) + t1(end) + 46*60;
t3 = OptACs.OptAircraft3.Mission.History.SI.Performance.Time(1:73) + t2(end) + 32*60;
t4 = OptACs.OptAircraft4.Mission.History.SI.Performance.Time(1:73)+t3(end)+ 27*60;
t = [t1; t2; t3; t4]./60./60;

end