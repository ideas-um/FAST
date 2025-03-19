


figure;
plot(Aircraft.Mission.History.SI.Performance.Alt(10:36),Aircraft.Specs.Power.PC(10:36,1)*100, LineWidth=2)
hold on
plot(Aircraft.Mission.History.SI.Performance.Alt(10:36),Aircraft.Specs.Power.PC(10:36,3)*100, LineWidth=2)
xlabel("Climb Altitude (m)")
ylabel("Design Variable (%)")
title("HEA Design Mission PC")
legend("GT PC", "EM PC")
set(gca, "FontSize", 12)
axis([0,10100,0,100])

figure;
plot(optac.Mission.History.SI.Performance.Alt(10:36),optac.Specs.Power.PC(10:36,1)*100, LineWidth=2)
hold on
plot(optac.Mission.History.SI.Performance.Alt(10:36),optac.Specs.Power.PC(10:36,3)*100, LineWidth=2)
xlabel("Climb Altitude (m)")
ylabel("Design Variable (%)")
title("Optimized HEA PC for 1000 nmi")
legend("GT PC", "EM PC")
set(gca, "FontSize", 12)
axis([0,10100,0,100])