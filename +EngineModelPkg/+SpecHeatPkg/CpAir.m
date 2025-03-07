function [heat] = CpAir(T_low,T_high)
%
% [heat] = CpAir(T_low,T_high)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function does one of two things depending on the inputs. If one
% input, it returns the specific heat at constant pressure (Cp) of air. if two
% inputs, it integrates the Cp between the two temperatures to return the
% amount of heat required to raise the air from T_low to T_high. Cp(Temp)
% was created by fitting an S-curve to data from Ohio university. See the
% end of this file for reference information regarding the S curve and the
% data.
%
%
% INPUTS:
%
% T_low = if one input, temperature at which Cp would like to be known. 
%           If two inputs, temperature of air before heat addition
%       size: scalar double
%
% T_high = [OPTIONAL] desired temp of air after heat addition
%       size: scalar double
%
%
% OUTPUTS:
%
% heat = if one input, Cp(T_low) specific heat at T_low
%           if two inputs, int(Cp(Temp),T_low -> T_high) total specific heat
%           required to raise temp from T_low to T_high
%       size: scalar double

%% Compute
L = 233.0000;
k = 1/210;
y = 875;
C = 993;
switch nargin
    case 1
        heat = L./(1+exp(-k*(T_low-y)))+ C;
    case 2
        heat = (T_high*(C+L) + L*log(exp(k*(y-T_high))+1)/k) -(T_low*(C+L) + L*log(exp(k*(y-T_low))+1)/k);
end


%% Info used to create S-curve (Included for Reference Only)
% https://www.ohio.edu/mechanical/thermo...
% /property_tables/air/air_Cp_Cv.html

% 
% clc
% data = [
%     250
%     1.003
%     0.716
%     1.401
%     300
%     1.005
%     0.718
%     1.400
%     350
%     1.008
%     0.721
%     1.398
%     400
%     1.013
%     0.726
%     1.395
%     450
%     1.020
%     0.733
%     1.391
%     500
%     1.029
%     0.742
%     1.387
%     550
%     1.040
%     0.753
%     1.381
%     600
%     1.051
%     0.764
%     1.376
%     650
%     1.063
%     0.776
%     1.370
%     700
%     1.075
%     0.788
%     1.364
%     750
%     1.087
%     0.800
%     1.359
%     800
%     1.099
%     0.812
%     1.354
%     900
%     1.121
%     0.834
%     1.344
%     1000
%     1.142
%     0.855
%     1.336
%     1100
%     1.155
%     0.868
%     1.331
%     1200
%     1.173
%     0.886
%     1.324
%     1300
%     1.190
%     0.903
%     1.318
%     1400
%     1.204
%     0.917
%     1.313
%     1500
%     1.216
%     0.929
%     1.309];
% 
% temp = data(1:4:76); % K
% cp = data(2:4:76).*1e3; % kJ/kg-K to J/kg-K
% 
% p = polyfit(temp,cp,3);
% 
% 
% 
% 
% L = 233.0000;
% k = 1/210;
% yp = 875;
% C = 993;
% 
% 
% % end
% Tin = linspace(0,3000,3000);
% 
% 
% 
% y = cp;
% ybar = mean(cp);
% f = L./(1+exp(-k*(temp-yp)))+ C;
% 
% R2 = 1 - sum((y - f).^2)/sum((y - ybar).^2)
% 
% 
% close all
% figure(3)
% scatter(temp,cp);
% hold on
% plot(Tin,L./(1+exp(-k*(Tin-yp)))+ C)
% grid on
% xlabel('Temperature [K]')
% ylabel('Specific Heat at Constant Pressure (C_p) [J/kgK]')
% legend('Raw Data','Fitted Curve','location','southeast')
% text(300,1200,"R^2 = " + R2,'FontName','Times','FontSize',16)
% 
% ax = gca;
% ax.FontName = 'Times';
% ax.FontSize = 16;
% 
% f = gcf;
% f.Position = [100 500 600 500];
% 
% print(f, '../EAP/DB_Paper_Scripts/cpcurve','-dpdf')




end

