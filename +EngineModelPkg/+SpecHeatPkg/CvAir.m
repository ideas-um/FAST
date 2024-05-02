function [cv_out] = CvAir(T_low)
%
% [cv_out] = CvAir(T_low)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function returns the specific heat at constant volume (Cp) of air.
% Cv(Temp) was created by fitting an S-curve to data from Ohio university.
% See the end of this file for reference information regarding the 
% S curve and the data.
%
%
% INPUTS:
%
% T_low = temperature at which Cv would like to be known.
%       size: scalar double
%
%
% OUTPUTS:
%
% cv_out = specific heat of air at constant volume at T_low
%           required to raise temp from T_low to T_high
%       size: scalar double

L = 233.0000;
k = 1/210;
y = 875;
C = 993-287;
cv_out = L./(1+exp(-k*(T_low-y)))+C;

%% Information used to create S-curve
% https://www.ohio.edu/mechanical/thermo...
% /property_tables/air/air_Cp_Cv.html
% data = [
% 250
% 1.003
% 0.716
% 1.401
% 300
% 1.005
% 0.718
% 1.400
% 350
% 1.008
% 0.721
% 1.398
% 400
% 1.013
% 0.726
% 1.395
% 450
% 1.020
% 0.733
% 1.391
% 500
% 1.029
% 0.742
% 1.387
% 550
% 1.040
% 0.753
% 1.381
% 600
% 1.051
% 0.764
% 1.376
% 650
% 1.063
% 0.776
% 1.370
% 700
% 1.075
% 0.788
% 1.364
% 750
% 1.087
% 0.800
% 1.359
% 800
% 1.099
% 0.812
% 1.354
% 900
% 1.121
% 0.834
% 1.344
% 1000
% 1.142
% 0.855
% 1.336
% 1100
% 1.155
% 0.868
% 1.331
% 1200
% 1.173
% 0.886
% 1.324
% 1300
% 1.190
% 0.903
% 1.318
% 1400
% 1.204
% 0.917
% 1.313
% 1500
% 1.216
% 0.929
% 1.309];

%temp = data(1:4:76); % K
%cv = data(3:4:76).*1e3; % kJ/kg-K to J/kg-K


%temp_cont = linspace(min(temp),max(temp));
%cp_cont = polyval(p,temp_cont);

%p = polyfit(temp,cv,4);
%cv_out = polyval(p,T_low);

end















