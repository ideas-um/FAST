clc;
clear all;
close all;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  Input the T0 and fuel flow from ICAO database
%  Input the SFC for cruise and SLS from literature review
%  Input the cruise altitude from literature review
%  
%  Output the coefficient, Cf3, Cf2, Cf1 and Cff, ch into SimpleOffDesign
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Data from the table
throttle_settings = [100, 85, 30, 7]; % in percentage

fuel_flow = [0.861, 0.710, 0.244, 0.091];

% Set constant T0 value
%%%%%%%%%%%%%% Change T0 for the specific engine from ICAO data %%%%%%%%%%%%%%%%
T0 = 120.6; % SLS thrust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TT = throttle_settings*T0/100;

% Convert throttle settings to thrust values
thrust = (throttle_settings / 100) * T0;

% Normalize thrust values by T0 for the polynomial fitting
CONS = thrust / T0;

% Prepare the design matrix for the polynomial fit without the constant term
X = [CONS'.^3 CONS'.^2 CONS']; % Note: X is transposed for fitting purposes

% Fit the model using the least-squares solution
coeffs = X \ fuel_flow'; % This solves for the coefficients without the constant term

Cf3 = coeffs(1)
Cf2 = coeffs(2)
Cf1 = coeffs(3)

% SFC for cruise and takeoff or SLS [lb/(lbf⋅hr)]
%%%%%%%%%%%%%% Change SFC for the specific engine from literature %%%%%%%%%%%%%%
SFC_cruise = 0.51;
SFC_takeoff = 0.38; % 0.255?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Cruise Altitude
%%%%%%%%%%%%%% Change cruise alt for the specific engine from literature %%%%%%%
hcr = 11280; % m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Cff_ch = (SFC_cruise - SFC_takeoff)/ hcr*2.8325e-02 

% You can use these coefficients to calculate fuel flow at other thrust values if needed.
T = T0;
h = 0;

fuelflow = Cf3*(T / T0)^3 + Cf2*(T / T0)^2 + Cf1*(T / T0) + Cff_ch * T *h 


% % % Original polynomial coefficients (provided)
% % Cf3_orj = 0.299;
% % Cf2_orj = -0.346;
% % Cf1_orj = 0.701;
% % 
% % fprintf('The polynomial coefficients are:\nCf3: %f\nCf2: %f\nCf1: %f\n', Cf3, Cf2, Cf1);
% % 
% Define range for T (Thrust values)
T_range = linspace(0, 120.6, 60); % Vary T from 0 to 60

% Calculate PL1 and PL2 for different T values
PL1 = Cf3*(T_range / T0).^3 + Cf2*(T_range / T0).^2 + Cf1*(T_range / T0);
% PL2 = Cf3_orj*(T_range / T0).^3 + Cf2_orj*(T_range / T0).^2 + Cf1_orj*(T_range / T0);

% Plot the results
figure;
plot(T_range, PL1, 'r-', 'LineWidth', 2);
hold on;
% plot(T_range, PL2, 'b--', 'LineWidth', 2);
scatter(TT, fuel_flow, 'bo', 'filled'); % Scatter plot for original data points
xlabel('Thrust (T)');
ylabel('Fuel flow (kg/s)');
title(['LEAP1A26 Comparison of PL1 and Original Data for T0 = ', num2str(T0)]);
legend('PL1 (Fitted)', 'Original Data', 'Location', 'Best');
grid on;

