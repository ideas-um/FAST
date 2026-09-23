clc; clear; close all;

years    = [2023; 2026; 2030; 2035];
cost_nm  = [127.61; 112.42;  96.52;  76.35];
cost_lfp = [120.91;  97.56;  82.73;  76.62];


% Quadratic fits
coef_nm_q   = polyfit(years, cost_nm,  1);
coef_lfp_q  = polyfit(years, cost_lfp, 2);

% Linear fits
coef_nm_l   = polyfit(years, cost_nm,  2);
coef_lfp_l  = polyfit(years, cost_lfp, 3);

query_years = [2023; 2025; 2030; 2033; 2035];

pred_nm_q  = polyval(coef_nm_q,  query_years);
pred_lfp_q = polyval(coef_lfp_q, query_years);
pred_nm_l  = polyval(coef_nm_l,  query_years);
pred_lfp_l = polyval(coef_lfp_l, query_years);


figure('Units','normalized','Position',[.1 .2 .8 .6]);
year_grid = linspace(2023,2035,200);
% Ni/Mn
subplot(1,2,1); hold on; grid on;
plot(years, cost_nm, 'bo', 'MarkerSize',8,'LineWidth',1.5);
plot(year_grid, polyval(coef_nm_q,  year_grid), 'r-', 'LineWidth',1.6);
% plot(year_grid, polyval(coef_nm_l,  year_grid), 'r--','LineWidth',1.4);
xlabel('Year'); ylabel('Cost ($/kWh)');
title('NMC Pack Cost vs Year');
legend('Data','1','2','Location','NorthEast');
xlim([2022 2036]);

% LFP
subplot(1,2,2); hold on; grid on;
plot(years, cost_lfp, 'bx', 'MarkerSize',8,'LineWidth',1.5);
% plot(year_grid, polyval(coef_lfp_q, year_grid), 'm-', 'LineWidth',1.6);
plot(year_grid, polyval(coef_lfp_l, year_grid), 'm--','LineWidth',1.4);
xlabel('Year'); ylabel('Cost ($/kWh)');
title('LFP Pack Cost vs Year');
legend('Data','3','3','Location','NorthEast');
xlim([2022 2036]);
