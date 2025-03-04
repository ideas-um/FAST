figure('Name','PS Comparison of Old and New Branches');
tiledlayout(3,3);  % 2x2 grid of subplots

% 1) Pav_PS
nexttile;
plot(old.Mission.History.SI.Power.Pav_PS(:,1)+old.Mission.History.SI.Power.Pav_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Pav_PS(:,1)+new.Mission.History.SI.Power.Pav_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Pav\_PS');
grid on;

% 2) Preq_PS
nexttile;
plot(old.Mission.History.SI.Power.Preq_PS(:,1)+old.Mission.History.SI.Power.Preq_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Preq_PS(:,1)+new.Mission.History.SI.Power.Preq_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Preq\_PS');
grid on;

% 3) Pout_PS
nexttile;
plot(old.Mission.History.SI.Power.Pout_PS(:,1)+old.Mission.History.SI.Power.Pout_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Pout_PS(:,1)+new.Mission.History.SI.Power.Pout_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Pout\_PS');
grid on;

% 4) Tout_PS
nexttile;
plot(old.Mission.History.SI.Power.Tout_PS(:,1)+old.Mission.History.SI.Power.Tout_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Tout_PS(:,1)+new.Mission.History.SI.Power.Tout_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Tout\_PS');
grid on;

% 5) Tav_PS
nexttile;
plot(old.Mission.History.SI.Power.Tav_PS(:,1)+old.Mission.History.SI.Power.Tav_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Tav_PS(:,1)+new.Mission.History.SI.Power.Tav_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Tav\_PS');
grid on;

% 6) Treq_PS
nexttile;
plot(old.Mission.History.SI.Power.Treq_PS(:,1)+old.Mission.History.SI.Power.Treq_PS(:,3), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Treq_PS(:,1)+new.Mission.History.SI.Power.Treq_PS(:,3), '--', 'LineWidth', 2);
hold off;
title('Treq\_PS');
grid on;

% 7) P_ES
nexttile;
plot(old.Mission.History.SI.Power.P_ES(:,1)+old.Mission.History.SI.Power.P_ES(:,2), 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.P_ES(:,1)+new.Mission.History.SI.Power.P_ES(:,2), '--', 'LineWidth', 2);
hold off;
title('P\_ES');
legend('Old Branch (a)','New Branch (b)','Location','best');
grid on;

% 8) TV
nexttile;
plot(old.Mission.History.SI.Power.TV, 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.TV, '--', 'LineWidth', 2);
hold off;
title('TV');
grid on;

% 9) Req
nexttile;
plot(old.Mission.History.SI.Power.Req, 'LineWidth', 2);
hold on;
plot(new.Mission.History.SI.Power.Req, '--', 'LineWidth', 2);
hold off;
title('Req');
grid on;



%%
% Define parameters
x0 = 0;         % Mean horizontal position
y0 = 0;         % Mean vertical position
A = 1;          % Amplitude factor (adjust as needed)
omega = 1;      % Angular frequency
h = 1;          % Water depth
k = 1;          % Wavenumber
theta = k*x0;   % Phase shift

% Calculate U0 and V0 using the finite depth formulas
U0 = A * omega * cosh(k*(y0+h)) / sinh(k*h);
V0 = A * omega * sinh(k*(y0+h)) / sinh(k*h);

% Define time vector
t = linspace(0, 2*pi, 200);

% Compute particle path (ellipse)
x = x0 + (U0/omega) * sin(theta - omega*t);
y = y0 - (V0/omega) * cos(theta - omega*t);

% Plot the particle path
figure;
plot(x, y, 'b', 'LineWidth', 2);
axis equal; grid on;
xlabel('x'); ylabel('y');
title('Elliptical Particle Path');

% Optionally, mark the initial position
hold on;
plot(x0, y0, 'ro', 'MarkerFaceColor', 'r');
legend('Particle Path', 'Mean Position');
