clc; clear; close all;


years = [2023, 2026, 2030, 2035]';

bms_nm  = [2, 2.2, 3, 3.5]';  
bms_lfp = [2.2, 3.1, 3.5, 2.6]';  



coeffs_nm  = polyfit(years, bms_nm,  1);

coeffs_lfp = polyfit(years, bms_lfp, 2); 



BMS_nm = polyval(coeffs_nm, 2026);%   For Ni/Mn (NMC)   
BMS_lfp = polyval(coeffs_lfp, 2026);%   For LFP 


fprintf('\nNi/Mn (NMC) polynomial coefficients [a, b, c]:\n');
fprintf('  a = %g,   b = %g', coeffs_nm(1), coeffs_nm(2));
fprintf('\nLFP polynomial coefficients [a, b, c]:\n');
fprintf('  a = %g,   b = %g,   c = %g\n', coeffs_lfp(1), coeffs_lfp(2), coeffs_lfp(3));

fprintf('NMC BMS costs: %g\n', BMS_nm);
fprintf('LFP BMS costs: %g\n', BMS_lfp);


%%

pred_nm  = polyval(coeffs_nm,  years);
pred_lfp = polyval(coeffs_lfp, years);

year_grid = linspace(2023, 2035, 200)';


subplot(1,2,1);
hold on;
plot(years, bms_nm, 'bo', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(year_grid, polyval(coeffs_nm, year_grid), 'r-', 'LineWidth', 1.8);
hold off;
xlabel('Year', 'FontSize', 11);
ylabel('BMS % of Pack Cost', 'FontSize', 11);
title('NMC BMS % vs. Year', 'FontSize', 13);
legend({'Data (Ni/Mn)', '1^{nd}-degree fit'}, 'Location','NorthWest');
xlim([2022 2036]); ylim([1.8 3.6]);



subplot(1,2,2);
hold on;
plot(years, bms_lfp, 'bx', 'MarkerSize', 8, 'LineWidth', 1.5);
plot(year_grid, polyval(coeffs_lfp, year_grid), 'm-', 'LineWidth', 1.8);
hold off;
xlabel('Year', 'FontSize', 11);
ylabel('BMS % of Pack Cost', 'FontSize', 11);
title('LFP BMS % vs. Year', 'FontSize', 13);
legend({'Data (LFP)', '2^{nd}-degree fit'}, 'Location','NorthWest');
xlim([2022 2036]); ylim([1.8 3.6]);


