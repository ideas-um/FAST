Aircraft1 = Conventional;
Aircraft2 = AC_tko_09;
Aircraft3 = AC_boost;


% get the number of points in each segment
TkoPts = Aircraft1.Settings.TkoPoints;
ClbPts = Aircraft1.Settings.ClbPoints;
CrsPts = Aircraft1.Settings.CrsPoints;
DesPts = Aircraft1.Settings.DesPoints;

% number of points in the main mission
npnt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);
n = 37;
dist2 = convlength(Aircraft2.Mission.History.SI.Performance.Dist(1:n), 'm', 'naut mi');
dist1 = convlength(Aircraft1.Mission.History.SI.Performance.Dist(1:n), 'm', 'naut mi');
alt2 = convlength(Aircraft2.Mission.History.SI.Performance.Alt(1:n), 'm', 'ft');
alt1 = convlength(Aircraft1.Mission.History.SI.Performance.Alt(1:n), 'm', 'ft');
alt3 = convlength(Aircraft3.Mission.History.SI.Performance.Alt(1:n), 'm', 'ft');
time1 = Aircraft1.Mission.History.SI.Performance.Time(1:n)/60;
time2 = Aircraft2.Mission.History.SI.Performance.Time(1:n)/60;
time3 = Aircraft3.Mission.History.SI.Performance.Time(1:n)/60;
vel1 = Aircraft1.Mission.History.SI.Performance.EAS(1:n);
vel2 = Aircraft2.Mission.History.SI.Performance.EAS(1:n);
roc1 = Aircraft1.Mission.History.SI.Performance.RC(1:n);
roc2 = Aircraft2.Mission.History.SI.Performance.RC(1:n);
roc3 = Aircraft3.Mission.History.SI.Performance.RC(1:n);
fuel1 = Aircraft1.Mission.History.SI.Weight.Fburn(1:n);
fuel2 = Aircraft2.Mission.History.SI.Weight.Fburn(1:n);
fuel3 = Aircraft3.Mission.History.SI.Weight.Fburn(1:n);

plot(time1 , fuel1, '-o')
hold on
plot(time2, fuel2, '-o')
plot(time3, fuel3, '-o')
%plot(Aircraft2.Mission.History.SI.Performance.Time(1:n), Aircraft2.Mission.History.SI.Performance.Alt(1:n), '-o')
xlabel("Time (min)")
ylabel("Fuel Burn (kg)")
title("Mission Profile")
legend("Conventional", "Optimal Hybridized Tko", "Optimial Hybridized Tko w/ Clb Boost")
%axis([0, 3000, -10, 40000])