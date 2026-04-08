%% work
f  = 16;
figure;
subplot(3,1,1)
plot(SizedERJ.Mission.History.SI.Performance.Time/60/60, SizedERJ.Mission.History.SI.Performance.Alt, 'k-o', 'LineWidth', .75, 'MarkerSize', 5)
grid on
%xlabel('Flight Time (hr)', 'FontSize', 12)
ylabel('Altitude (m)', 'FontSize', f)
title('Mission Profile', 'FontSize', f)

subplot(3,1,2)
plot(SizedERJ.Mission.History.SI.Performance.Time/60/60, SizedERJ.Mission.History.SI.Performance.TAS, 'k-o', 'LineWidth', .75, 'MarkerSize', 5)
grid on
%xlabel('Flight Time (hr)', 'FontSize', 12)
ylabel('TAS (m/s)', 'FontSize', f)

subplot(3,1,3)
plot(SizedERJ.Mission.History.SI.Performance.Time/60/60, SizedERJ.Mission.History.SI.Performance.Ps, 'k-o', 'LineWidth', .75, 'MarkerSize', 5)
grid on
xlabel('Flight Time (hr)', 'FontSize', f)
ylabel('Specific Excess Power (m/s)', 'FontSize', f)