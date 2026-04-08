
load("Sequence.mat")
seq = tables{8};
load("SeqOptAC_fuele.mat")
Case1 = OptimizedAircraft;
disp("Case 1")
case1 = AnalyzeAC(Case1, seq);
load("SeqOptAC_cost.mat")
Case2 = OptimizedAircraft;
disp("Case 2")
case2 = AnalyzeAC(Case2, seq);
load("SeqOptAC_futDOC.mat")
Case3 = OptimizedAircraft;
disp("Case 3")
case3 = AnalyzeAC(Case3, seq);
load("Conv.mat")
Case4 = ACs;
disp("Case 4")
case4 = AnalyzeAC(Case4, seq);


case1.diff = (case1.fburn-case4.fburn)./case4.fburn.*100;
case2.diff = (case2.fburn-case4.fburn)./case4.fburn.*100;
case3.diff = (case3.fburn-case4.fburn)./case4.fburn.*100;

%%
a = [2.85134, 6.32045, 8.54197, 10.5635];
b = [3.48715, 7.42292, 9.4444, 11.4005];

X = [a; b; nan(size(a))];
Y = [zeros(size(a)); zeros(size(a)); nan(size(a))];

f = 12;
figure;

% Plot alt and TAS v time
t = plot(case1.Time, case1.Alt, "k-", 'LineWidth', 1, 'MarkerSize', 5);
grid on
xlabel('Flight Time (hr)', 'FontSize', 12)
ylabel('Altitude (m)', 'FontSize', f)
title('Sequence Mission Profile', 'FontSize', f)
hold on
flight = xline(a,'--b', 'LineWidth',1);
b2 = plot(case1.Time(10:32),         case1.Alt(10:32), "*", 'LineWidth', 1, 'MarkerSize', 5, 'Color', 'r');
n = 74;
c = plot(case1.Time(10+n:32+n), case1.Alt(10+n:32+n), "*", 'LineWidth', 1, 'MarkerSize', 5, 'Color', 'r');
n = 2*(74)-1;
d = plot(case1.Time(10+n:32+n), case1.Alt(10+n:32+n), "*", 'LineWidth', 1, 'MarkerSize', 5, 'Color', 'r');
n = 3*(74)-2;
e = plot(case1.Time(10+n:32+n), case1.Alt(10+n:32+n), "*", 'LineWidth', 1, 'MarkerSize', 5, 'Color', 'r');
n = 4*(74)-3;
f2 = plot(case1.Time(10+n:32+n), case1.Alt(10+n:32+n), "*", 'LineWidth', 1, 'MarkerSize', 5, 'Color', 'r');
charge = plot(X(:), Y(:), '-g','LineWidth', 2);
legend([b2, charge, flight(1), t], {'Climb Evaluation Points', 'Charging', 'Flight Divider', 'Mission Profile'})

%%
font = 12;
figure;

% Create the first subplot
ax1 = subplot(4, 1, 1);
% Plot alt and TAS v time
plot(case1.Time, case1.Alt, "-k", 'LineWidth', 2);
ylabel("Alt (m)");
hold on;
yyaxis right;
plot(case1.Time, case1.TAS, "-b", 'LineWidth', 2);
ylabel("TAS (m/s)");
ax1.YColor = 'k'; 
yyaxis right; 
ax1.YColor = 'b'; 
set(ax1, "FontSize", font);

% Create the second subplot
ax2 = subplot(4, 1, 2);
hold on;
plot(case1.Time, case1.GTPC, 'LineWidth', 1.5);
plot(case2.Time, case2.GTPC, 'LineWidth', 1.5);
plot(case3.Time, case3.GTPC, 'LineWidth', 1.5);
plot(case4.Time, case4.GTPC, 'LineWidth', 1.5); 
ylabel("GT PC (%)");
%legend("Cost", "Fuel kg", "Fuel E")
legend("Case 5", "Case 6", "Case 3", "Case 4", 'FontSize', font);
set(ax2, "FontSize", font);

% Create the third subplot
ax3 = subplot(4, 1, 3);
hold on;
plot(case1.Time, case1.EMPC, 'LineWidth', 1.5);
plot(case2.Time, case2.EMPC, 'LineWidth', 1.5);
plot(case3.Time, case3.EMPC, 'LineWidth', 1.5);
ylabel("EM PC (%)");
%legend("Case 1", "Case 2", "Case 3", 'FontSize', font);
set(ax3, "FontSize", font);

% Create the fourth subplot
ax4 = subplot(4, 1, 4);
hold on;
plot(case1.Time, case1.SOC, 'LineWidth', 1.5);
plot(case2.Time, case2.SOC, 'LineWidth', 1.5);
plot(case3.Time, case3.SOC, 'LineWidth', 1.5);
ylabel("SOC (%)");
xlabel("Time (hr)");
%legend("Case 1", "Case 2", "Case 3", 'FontSize', font);
set(ax4, "FontSize", font);

% Link the x-axes of all subplots explicitly
linkaxes([ax1, ax2, ax3, ax4], 'x');

figure;
hold on;
plot(case1.Time, case1.FuelE, 'LineWidth', 1.5);
plot(case2.Time, case2.FuelE, 'LineWidth', 1.5);
plot(case3.Time, case3.FuelE, 'LineWidth', 1.5);
ylabel("Fuele");
xlabel("Time (hr)");
legend("Case 1", "Case 2", "Case 3", 'FontSize', font);
set(ax4, "FontSize", font);

figure;
hold on;
plot(case1.Time, case1.fburn, 'LineWidth', 1.5);
plot(case2.Time, case2.fburn, 'LineWidth', 1.5);
plot(case3.Time, case3.fburn, 'LineWidth', 1.5);
ylabel("Fuel burn");
xlabel("Time (hr)");
legend("Case 1", "Case 2", "Case 3", 'FontSize', font);
set(ax4, "FontSize", font);

figure;
hold on;
plot(case1.Time, case1.BattE, 'LineWidth', 1.5);
plot(case2.Time, case2.BattE, 'LineWidth', 1.5);
plot(case3.Time, case3.BattE, 'LineWidth', 1.5);
ylabel("BattE");
xlabel("Time (hr)");
legend("Case 1", "Case 2", "Case 3", 'FontSize', font);
set(ax4, "FontSize", font);

%%
%{
% plot fburn
subplot(3,2,2)
plot(case1.Time, case1.diff, LineWidth=1.5)
hold on
plot(case2.Time, case2.diff, LineWidth=1.5)
plot(case3.Time, case3.diff, LineWidth=1.5)
yline(0,"--k")
ylabel("Fuel Burn % Difference wrt Case 4")
legend("Case 1", "Case 2", "Case 3")
set(gca, "FontSize", font)

% plot batt E
subplot(3,2,5)
hold on
plot(case1.Time, case1.BattE, LineWidth=1.5)
plot(case2.Time, case2.BattE, LineWidth=1.5)
plot(case3.Time, case3.BattE, LineWidth=1.5)
ylabel("Battery Energy Used (kWh)")
legend("Case 1", "Case 2", "Case 3")
set(gca, "FontSize", font)
%}
%%
function [result] = AnalyzeAC(air, seq)
AC = fieldnames(air);
n = length(AC);

time = [];
alt = [];
TAS = [];
fburn = [];
fuele = [];
GTPC = [];
EMPC = [];
battE = [];
SOC = [];
ground = [];



for i = 1:n
    % get ac from struct
    Aircraft = air.(AC{i}); 
    
    % extract mission points
    TkoPts = Aircraft.Settings.TkoPoints;
    ClbPts = Aircraft.Settings.ClbPoints;
    CrsPts = Aircraft.Settings.CrsPoints;
    DesPts = Aircraft.Settings.DesPoints;
    
    % number of points in the main mission
    npt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);
        
    ground = seq.GROUND_TIME(i);
    
    % get desired values
    t = Aircraft.Mission.History.SI.Performance.Time(1:npt)./60;
    disp(t(37))
    disp(t(73))
    fuel = Aircraft.Mission.History.SI.Weight.Fburn(1:npt);
    ef = Aircraft.Mission.History.SI.Energy.E_ES(1:npt,1)./1000./3600;
    if i > 1
    t = t +time(end)+ground;
    fuel = fuel + fburn(end);
    ef = ef + fuele(end);
    end
    a = Aircraft.Mission.History.SI.Performance.Alt(1:npt);
    a(end) = 0;
    v = Aircraft.Mission.History.SI.Performance.TAS(1:npt);
    v(end) = 0;
    GT = Aircraft.Mission.History.SI.Power.PC(1:npt, 1);
    GT(end) = 0;

    % only hea catergories
    if Aircraft.Specs.Weight.Batt > 0
        EM =  Aircraft.Mission.History.SI.Power.PC(1:npt, 3);
         E = Aircraft.Mission.History.SI.Energy.E_ES(1:npt, 2)./3600./1000;
         if i >1
         E = E + battE(end);
         end
         c =  Aircraft.Mission.History.SI.Power.SOC(1:npt,2);
    else
        EM =[];
        E = [];
        c = [];
    end

    time = [time; t];
    alt = [alt; a];
    TAS = [TAS; v];
    fburn = [fburn; fuel];
    fuele = [fuele; ef];
    GTPC = [GTPC; GT];
    EMPC = [EMPC;EM];
    battE = [battE; E];
    SOC = [SOC; c];

end

time = time./60;

result = struct('Time', time, 'Alt', alt,'TAS', TAS, 'fburn', fburn, 'GTPC', GTPC, 'EMPC', EMPC, "FuelE", fuele,'BattE', battE, 'SOC', SOC);
end


function [History] = MakeTTable(OptACs)
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);

fburn1 = OptACs.Aircraft1.Mission.History.SI.Weight.Fburn(1:73);
fburn2 = OptACs.Aircraft2.Mission.History.SI.Weight.Fburn(1:73) + fburn1(end);
fburn3 = OptACs.Aircraft3.Mission.History.SI.Weight.Fburn(1:73) + fburn2(end);
fburn4 = OptACs.Aircraft4.Mission.History.SI.Weight.Fburn(1:73) + fburn3(end);
fburn = [fburn1; fburn2; fburn3; fburn4;];

fuele1 = OptACs.Aircraft1.Mission.History.SI.Energy.E_ES(1:73,1);
fuele2 = OptACs.Aircraft2.Mission.History.SI.Energy.E_ES(1:73,1) + fuele1(end);
fuele3 = OptACs.Aircraft3.Mission.History.SI.Energy.E_ES(1:73,1) + fuele2(end);
fuele4 = OptACs.Aircraft4.Mission.History.SI.Energy.E_ES(1:73,1) + fuele3(end);
fuele = [fuele1; fuele2; fuele3; fuele4;]./3600./1000;

GTPC1 = OptACs.Aircraft1.Mission.History.SI.Power.PC(1:73, 1);
GTPC1(end) = 0;
GTPC2 = OptACs.Aircraft2.Mission.History.SI.Power.PC(1:73, 1);
GTPC2(end) = 0;
GTPC3 = OptACs.Aircraft3.Mission.History.SI.Power.PC(1:73, 1);
GTPC3(end) = 0;
GTPC4 = OptACs.Aircraft4.Mission.History.SI.Power.PC(1:73, 1);
GTPC4(end) = 0;
GTPC = [GTPC1; GTPC2; GTPC3; GTPC4;];

if OptACs.Aircraft1.Settings.DetailedBatt == 1
e1 = OptACs.Aircraft1.Mission.History.SI.Energy.E_ES(1:73, 2);
e2 = OptACs.Aircraft2.Mission.History.SI.Energy.E_ES(1:73, 2) + e1(end);
e3 = OptACs.Aircraft3.Mission.History.SI.Energy.E_ES(1:73, 2) + e2(end);
e4 = OptACs.Aircraft4.Mission.History.SI.Energy.E_ES(1:73, 2) + e3(end);
e = [e1; e2; e3; e4;]./3600./1000;%kWh

EMPC1 = OptACs.Aircraft1.Mission.History.SI.Power.PC(1:73, 3);
EMPC2 = OptACs.Aircraft2.Mission.History.SI.Power.PC(1:73, 3);
EMPC3 = OptACs.Aircraft3.Mission.History.SI.Power.PC(1:73, 3);
EMPC4 = OptACs.Aircraft4.Mission.History.SI.Power.PC(1:73, 3);
EMPC = [EMPC1; EMPC2; EMPC3; EMPC4;];
SOC1 = OptACs.Aircraft1.Mission.History.SI.Power.SOC(1:73, 2);
SOC2 = OptACs.Aircraft2.Mission.History.SI.Power.SOC(1:73, 2);
SOC3 = OptACs.Aircraft3.Mission.History.SI.Power.SOC(1:73, 2);
SOC4 = OptACs.Aircraft4.Mission.History.SI.Power.SOC(1:73, 2);
SOC = [SOC1; SOC2; SOC3; SOC4;];
end
alt1 = OptACs.Aircraft1.Mission.History.SI.Performance.Alt(1:73);
alt1(end) = 0;
t1 = OptACs.Aircraft1.Mission.History.SI.Performance.Time(1:73);

alt2 = OptACs.Aircraft2.Mission.History.SI.Performance.Alt(1:73);
alt2(end) = 0;
t2 = OptACs.Aircraft2.Mission.History.SI.Performance.Time(1:73) + t1(end) + 46*60;

alt3 = OptACs.Aircraft3.Mission.History.SI.Performance.Alt(1:73);
t3 = OptACs.Aircraft3.Mission.History.SI.Performance.Time(1:73) + t2(end) + 32*60;
alt3(end) = 0;
alt4 = OptACs.Aircraft4.Mission.History.SI.Performance.Alt(1:73);
t4 = OptACs.Aircraft4.Mission.History.SI.Performance.Time(1:73)+t3(end)+ 27*60;
alt4(end) = 0;
alt = [alt1; alt2; alt3; alt4;];
t = [t1; t2; t3; t4]./60;

% make miss hist table
time = minutes(t);
mytable = table(time, alt, fburn, fuele, e, SOC, GTPC, EMPC);
mytable.Properties.VariableNames = string(["Time (min)", "Altitude (m)", "Fuel Burn (kg)", "Efuel (kwh)", "Ebatt (kWh)", "SOC", "GT PC", "EM PC"]);

History = table2timetable(mytable);
end
