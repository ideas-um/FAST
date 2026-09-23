Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");

SizedHEA.Specs.Performance.Range = Range;
SizedHEA.Settings.Analysis.Type = -2;
SizedHEA.Settings.ConSOC = 0;
SizedHEA = Main(SizedHEA, @MissionProfilesPkg.ERJ_ClimbThenAccel);

Aircraft = SizedHEA;
Aircraft.Specs.Performance.Range = Range;

n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;
npts = length(Aircraft.Mission.History.SI.Performance.Alt);
% number of points in main
nmain = 73;
PC0 = zeros(npts,1);
PC0(1:(n1-1)) = ones(n1-1,1);
PC0(n1:n2) = PCbest;
Aircraft.Settings.Analysis.Type = -2;
Aircraft.Settings.PrintOut = 0;
Aircraft.Settings.ConSOC = 0;
Aircraft.Specs.Power.PC(:, [3,4]) = repmat(PC0,1,2);
Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);

% extract time vector
t = Aircraft.Mission.History.SI.Performance.Time(1:nmain) / 60;
t2 = SizedHEA.Mission.History.SI.Performance.Time(1:nmain) / 60;

tclbOpt = t(n2) - 1;
tclbOG = t2(n2) - 1;
dtclb = (tclbOpt - tclbOG)/tclbOG;

% spec difference values
fburnOG = SizedHEA.Specs.Weight.Fuel;
fburnOpt = Aircraft.Specs.Weight.Fuel;
dfuel = (fburnOpt - fburnOG)/fburnOG;

eOG = SizedHEA.Mission.History.SI.Energy.E_ES(end, :);
eOpt= Aircraft.Mission.History.SI.Energy.E_ES(end, :);
dE = (eOpt - eOG)./eOG;


% pts 
pts = (1:nmain)';

figure;
plot(t2, SizedHEA.Mission.History.SI.Power.Pout_PS((1:nmain),3), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Power.Pout_PS((1:nmain),3), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Time (min)")
ylabel("Power")
legend("OG", "Optimized")


figure;
plot(t2, SizedHEA.Mission.History.SI.Energy.E_ES((1:nmain),2), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Energy.E_ES((1:nmain),2), "LineWidth",2)
set(gca,"FontSize", 12)
xlabel("Time (min)")
ylabel("Battery Energy")
legend("OG", "Optimized")

figure;
plot(t2, SizedHEA.Mission.History.SI.Energy.E_ES((1:nmain),1), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Energy.E_ES((1:nmain),1), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Time (min)")
ylabel("Fuel Energy")
legend("OG", "Optimized")

figure;
plot(t2, SizedHEA.Mission.History.SI.Weight.Fburn((1:nmain)), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Weight.Fburn((1:nmain)), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Time (min)")
ylabel("Fuel Burn")
legend("OG", "Optimized")


figure;
plot(t2, SizedHEA.Mission.History.SI.Performance.Alt(1:nmain), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Performance.Alt(1:nmain), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Time (min)")
ylabel("Alt")
legend("OG", "Optimized")

figure;
plot(pts, SizedHEA.Mission.History.SI.Power.PC((1:nmain),1), "LineWidth",2)
hold on
plot(pts, SizedHEA.Mission.History.SI.Power.PC((1:nmain),3), "LineWidth",2)
plot(pts, Aircraft.Mission.History.SI.Power.PC((1:nmain),1), "LineWidth",2)
plot(pts, Aircraft.Mission.History.SI.Power.PC((1:nmain),3), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Mission Control Point")
ylabel("PC")
legend("OG GT", "OG EM", "Opt GT", "Opt EM")

figure;
plot(t2, SizedHEA.Mission.History.SI.Power.SOC((1:nmain),2), "LineWidth",2)
hold on
plot(t, Aircraft.Mission.History.SI.Power.SOC((1:nmain),2), "LineWidth",2)
set(gca, "FontSize", 12)
xlabel("Time (min)")
ylabel("SOC")
legend("OG", "Optimized")