

SizedHEA.Specs.Performance.Range = 1852000;
SizedHEA.Settings.Analysis.Type = -2;
SizedHEA = Main(SizedHEA, @MissionProfilesPkg.ERJ_ClimbThenAccel);

Aircraft = SizedHEA;
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");

n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;
npts = length(Aircraft.Mission.History.SI.Performance.Alt);
PC0 = zeros(npts,1);
PC0(1:(n1-1)) = ones(n1-1,1);
PC0(n1:n2) = PCbest;

Aircraft.Settings.Analysis.Type = -2;
Aircraft.Specs.Power.PC.EM = PC0;
Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
%optimzationlot comparison

t = Aircraft.Mission.History.SI.Performance.Time;

t2 = SizedHEA.Mission.History.SI.Performance.Time;

figure;
plot(t2, SizedHEA.Mission.History.SI.Power.Pout_PS(:,3))
hold on
plot(t, Aircraft.Mission.History.SI.Power.Pout_PS(:,3))
xlabel("Time")
ylabel("Power")
legend("OG", "Optimized")


figure;
plot(t2, SizedHEA.Mission.History.SI.Energy.E_ES(:,2))
hold on
plot(t, Aircraft.Mission.History.SI.Energy.E_ES(:,2))
xlabel("Time")
ylabel("Battery Energy")
legend("OG", "Optimized")

figure;
plot(t2, SizedHEA.Mission.History.SI.Energy.E_ES(:,1))
hold on
plot(t, Aircraft.Mission.History.SI.Energy.E_ES(:,1))
xlabel("Time")
ylabel("Fuel Energy")
legend("OG", "Optimized")

figure;
plot(t2, SizedHEA.Mission.History.SI.Performance.Alt)
hold on
plot(t, Aircraft.Mission.History.SI.Performance.Alt)
xlabel("Time")
ylabel("Alt")
legend("OG", "Optimized")