Aircraft1 = Conventional;
Aircraft2 = AC_tko_09;


% get the number of points in each segment
TkoPts = Aircraft.Settings.TkoPoints;
ClbPts = Aircraft.Settings.ClbPoints;
CrsPts = Aircraft.Settings.CrsPoints;
DesPts = Aircraft.Settings.DesPoints;

% number of points in the main mission
npnt = TkoPts + 3 * (ClbPts - 1) + CrsPts - 1 + 3 * (DesPts - 1);
n = 37;
dist2 = convlength(Aircraft2.Mission.History.SI.Performance.Dist(1:n), 'm', 'naut mi');
dist1 = convlength(Aircraft1.Mission.History.SI.Performance.Dist(1:n), 'm', 'naut mi');
alt2 = convlength(Aircraft2.Mission.History.SI.Performance.Alt(1:n), 'm', 'ft');
alt1 = convlength(Aircraft1.Mission.History.SI.Performance.Alt(1:n), 'm', 'ft');
time1 = Aircraft1.Mission.History.SI.Performance.Time(1:n);
time2 = Aircraft2.Mission.History.SI.Performance.Time(1:n);
plot(time1 , alt1, '-o')
hold on
plot(time2, alt2, '-o')
%plot(Aircraft2.Mission.History.SI.Performance.Time(1:n), Aircraft2.Mission.History.SI.Performance.Alt(1:n), '-o')
xlabel("Time (s)")
ylabel("Altitude (ft)")
title("Mission Profile")
legend("Conventional", "Optimal Hybridized Takeoff")
%axis([0, 3000, -10, 40000])