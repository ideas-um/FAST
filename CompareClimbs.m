Aircraft1 = Conventional;
Aircraft2 = AC_tko_09;


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
time1 = Aircraft1.Mission.History.SI.Performance.Time(1:n);
time2 = Aircraft2.Mission.History.SI.Performance.Time(1:n);
vel1 = Aircraft1.Mission.History.SI.Performance.EAS(1:n);
vel2 = Aircraft2.Mission.History.SI.Performance.EAS(1:n);
roc1 = Aircraft1.Mission.History.SI.Performance.RC(1:n);
roc2 = Aircraft2.Mission.History.SI.Performance.RC(1:n);
plot(time1 , roc1, '-o')
hold on
plot(time2, roc2, '-o')
%plot(Aircraft2.Mission.History.SI.Performance.Time(1:n), Aircraft2.Mission.History.SI.Performance.Alt(1:n), '-o')
xlabel("Time (s)")
ylabel("Rate of Climb (m/s)")
title("Mission Profile")
legend("Conventional", "Optimal Hybridized Takeoff")
%axis([0, 3000, -10, 40000])