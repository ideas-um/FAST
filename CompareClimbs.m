
n = 37;
plot(Aircraft3.Mission.History.SI.Performance.Time(1:n), Aircraft3.Mission.History.SI.Performance.Alt(1:n), '-o')
hold on
plot(Aircraft1.Mission.History.SI.Performance.Time(1:n), Aircraft1.Mission.History.SI.Performance.Alt(1:n), '-o')
plot(Aircraft2.Mission.History.SI.Performance.Time(1:n), Aircraft2.Mission.History.SI.Performance.Alt(1:n), '-o')
xlabel("Time")
ylabel("Altitude")
legend("Conventional", "HEA with Boost", "HEA no boost")