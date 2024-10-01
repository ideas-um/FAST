% Model Testing Script
% Written by Max Arnson
% Last updated 11/20/2023
%
% This scipt is used to test both the turbofan and turboprop engine models
% on test cases, visualize them, and graph various performance metrics
% throughout the engine to catch bugs.

%% Compressor Map
clear; clc; close all;
Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.PW_1919G,0);
Comp = Eng.HPCObject;
%Comp = Eng.FanSysObject.LPCObject;
Map = EngineModelPkg.MapPkg.CreateMap(Comp);

figure(1)
contourf(Map.Mass,Map.PR,Map.Eta,20)
xlabel('Corected Mass Flow (% Nominal)')
ylabel('Pressure Ratio')
title('Compressor Map: Efficiency')
colorbar
colormap jet
grid on
hold on
scatter(100,Comp.Pi,'ko','filled')

figure(2)
contourf(Map.Mass,Map.PR,Map.Rot,20)
xlabel('Corrected MassFlow (% Nominal)')
ylabel('Pressure Ratio')
title('Compressor Map: Rotational Speed (% Nominal)')
colorbar
colormap jet
grid on
hold on
scatter(100,Comp.Pi,'ko','filled')

figure(3)
contourf(Map.Rot,Map.Mass,Map.PR,20)
ylabel('Corrected Mass Flow  (% Nominal)')
xlabel('Corected Rotational Speed (% Nominal)')
title('Compressor Map: Pressure Ratio')
colorbar
colormap jet
grid on
hold on
scatter(100,100,'ko','filled')

figure(4)
contour(Map.Mass,Map.Eta,Map.Rot)
xlabel('Corrected Mass Flow  (% Nominal)')
ylabel('Isentropic Efficiency')
title('Compressor Map: Efficiency')

figure(5)
contourf(Map.Rot,Map.Mass,Map.Eta)
ylabel('Corected MassFlow (% Nominal)')
xlabel('Corrected Rotational Speed (% Nominal)')
title('Compressor Map')
colorbar
colormap jet
grid on



%% viewing engine outputs for a full mission profile

SizedAC = Main(AircraftSpecsPkg.LM100J_Conventional,@MissionProfilesPkg.LM100J);



t = SizedAC.Mission.History.SI.Performance.Time;

figure(5)

subplot(2,2,1)
plot(t/60, SizedAC.Mission.History.SI.Propulsion.ExitMach ,'k')
grid on
title('Engine Core Mach Number')
ylabel('Exit Mach')
xlabel('Flight Time (min)')

subplot(2,2,2)
plot(t/60, SizedAC.Mission.History.SI.Propulsion.MDotAir ,'k')
title('Engine Air Mass Flow')
ylabel('MDot (kg/s)')
xlabel('Flight Time (min)')
grid on

subplot(2,2,3)
plot(t/60, SizedAC.Mission.History.SI.Propulsion.FanDiam ,'k')
title('Engine Fan Diameter')
ylabel('Fan Diameter (m)')
xlabel('Flight Time (min)')
grid on

%% Fans: syntax and bugs
clear
close all
clc
R = 287;

tic
%Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.PW_1919G,1)
%Specs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
Specs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;
Specs.Visualize = true;
Eng = EngineModelPkg.TurbofanNonlinearSizing(Specs)
%Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.RB211_22B_02,1)
%Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.CF6_80C2_B7F,1)
%Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.Trent_970B_84,1)
%Eng = EngineModelPkg.TurbofanNonlinearSizing(EngineModelPkg.EngineSpecsPkg.PW_2037,1)




toc
Temps = [
    Eng.States.Station1.Tt
    Eng.States.Station2.Tt
    Eng.States.Station21.Tt
    Eng.States.Station25.Tt
    Eng.States.Station26.Tt
    Eng.States.Station3.Tt
    Eng.States.Station31.Tt
    Eng.States.Station39.Tt
    Eng.States.Station4.Tt
    Eng.States.Station41.Tt
    Eng.States.Station5.Tt
    Eng.States.Station55.Tt
    Eng.States.Station6.Tt
    Eng.States.Station9.Tt
    ];

StaticTemps = [
    Eng.States.Station1.Ts
    Eng.States.Station2.Ts
    Eng.States.Station21.Ts
    Eng.States.Station25.Ts
    Eng.States.Station26.Ts
    Eng.States.Station3.Ts
    Eng.States.Station31.Ts
    Eng.States.Station39.Ts
    Eng.States.Station4.Ts
    Eng.States.Station41.Ts
    Eng.States.Station5.Ts
    Eng.States.Station55.Ts
    Eng.States.Station6.Ts
    Eng.States.Station9.Ts
    ];


Pressures = [
    Eng.States.Station1.Pt
    Eng.States.Station2.Pt
    Eng.States.Station21.Pt
    Eng.States.Station25.Pt
    Eng.States.Station26.Pt
    Eng.States.Station3.Pt
    Eng.States.Station31.Pt
    Eng.States.Station39.Pt
    Eng.States.Station4.Pt
    Eng.States.Station41.Pt
    Eng.States.Station5.Pt
    Eng.States.Station55.Pt
    Eng.States.Station6.Pt
    Eng.States.Station9.Pt
    ];

StaticPressures = [
    Eng.States.Station1.Ps
    Eng.States.Station2.Ps
    Eng.States.Station21.Ps
    Eng.States.Station25.Ps
    Eng.States.Station26.Ps
    Eng.States.Station3.Ps
    Eng.States.Station31.Ps
    Eng.States.Station39.Ps
    Eng.States.Station4.Ps
    Eng.States.Station41.Ps
    Eng.States.Station5.Ps
    Eng.States.Station55.Ps
    Eng.States.Station6.Ps
    Eng.States.Station9.Ps
    ];

Machs = [
    Eng.States.Station1.Mach
    Eng.States.Station2.Mach
    Eng.States.Station21.Mach
    Eng.States.Station25.Mach
    Eng.States.Station26.Mach
    Eng.States.Station3.Mach
    Eng.States.Station31.Mach
    Eng.States.Station39.Mach
    Eng.States.Station4.Mach
    Eng.States.Station41.Mach
    Eng.States.Station5.Mach
    Eng.States.Station55.Mach
    Eng.States.Station6.Mach
    Eng.States.Station9.Mach
    ];

Vels = [
    Eng.States.Station1.Mach*sqrt(R*Eng.States.Station1.Gam*Eng.States.Station1.Ts)
    Eng.States.Station2.Mach*sqrt(R*Eng.States.Station2.Gam*Eng.States.Station2.Ts)
    Eng.States.Station21.Mach*sqrt(R*Eng.States.Station21.Gam*Eng.States.Station21.Ts)
    Eng.States.Station25.Mach*sqrt(R*Eng.States.Station25.Gam*Eng.States.Station25.Ts)
    Eng.States.Station26.Mach*sqrt(R*Eng.States.Station26.Gam*Eng.States.Station26.Ts)
    Eng.States.Station3.Mach*sqrt(R*Eng.States.Station3.Gam*Eng.States.Station3.Ts)
    Eng.States.Station31.Mach*sqrt(R*Eng.States.Station31.Gam*Eng.States.Station31.Ts)
    Eng.States.Station39.Mach*sqrt(R*Eng.States.Station39.Gam*Eng.States.Station39.Ts)
    Eng.States.Station4.Mach*sqrt(R*Eng.States.Station4.Gam*Eng.States.Station4.Ts)
    Eng.States.Station41.Mach*sqrt(R*Eng.States.Station41.Gam*Eng.States.Station41.Ts)
    Eng.States.Station5.Mach*sqrt(R*Eng.States.Station5.Gam*Eng.States.Station5.Ts)
    Eng.States.Station55.Mach*sqrt(R*Eng.States.Station55.Gam*Eng.States.Station55.Ts)
    Eng.States.Station6.Mach*sqrt(R*Eng.States.Station6.Gam*Eng.States.Station6.Ts)
    Eng.States.Station9.Mach*sqrt(R*Eng.States.Station9.Gam*Eng.States.Station9.Ts)
    ];

Temps = Temps-273;
StaticTemps = StaticTemps - 273;

Pressures = Pressures/101e3;
StaticPressures = StaticPressures/101e3;

index = 1:1:length(Temps);

figure(2)

subplot(2,2,1)
plot(index,Temps)
title('Temp [C]')
hold on
plot(index,StaticTemps)
legend('Total','Static','Location','northwest')
hold off
grid on

subplot(2,2,2)
plot(index,Pressures)
title('Pressure [atm]')
hold on
plot(index,StaticPressures)
legend('Total','Static','Location','northwest')
hold off
grid on

subplot(2,2,3)
plot(index,Machs)
title('Mach')
grid on

subplot(2,2,4)
plot(index,Vels)
title('Velocity [m/s]')
grid on

%%
clear; clc; close all

Fxns = [EngineModelPkg.EngineSpecsPkg.ValCase1,EngineModelPkg.EngineSpecsPkg.ValCase2,EngineModelPkg.EngineSpecsPkg.ValCase3,EngineModelPkg.EngineSpecsPkg.ValCase4,EngineModelPkg.EngineSpecsPkg.ValCase5,EngineModelPkg.EngineSpecsPkg.ValCase6,EngineModelPkg.EngineSpecsPkg.ValCase7,EngineModelPkg.EngineSpecsPkg.ValCase8,EngineModelPkg.EngineSpecsPkg.ValCase9,EngineModelPkg.EngineSpecsPkg.ValCase10];


Status = ["","","","","","","","","",""]';
Mass_Error = zeros(1,10)';
TSFC_Error = zeros(1,10)';
FAR = zeros(1,10)';


True_Mass = [825, 588, 500, 637, 867, 640.5, 498.75, 609, 604, 598.5]';
True_TSFC = 1e-6.*[6.01, 6.98, 6.63, 6.98, 6.18, 9.31, 7.57, 9.31, 7.54, 5.14]';


for ii = 1:length(Fxns)

    try
        Engii = EngineModelPkg.TurbofanNonlinearSizing(Fxns(ii),0);
        Status(ii) = "Passed";
        TSFC_Error(ii) = round((Engii.TSFC - True_TSFC(ii))/True_TSFC(ii)*100,3);
        Mass_Error(ii) = round((Engii.MDot - True_Mass(ii))/True_Mass(ii)*100,3);
        FAR(ii) = round(Engii.Fuel.FAR*100,3);
    catch
        Status(ii) = "Failed";
        Mass_Error(ii) = NaN;
        TSFC_Error(ii) = NaN;

    end

end


Case_Number = [1:1:10]';

Results = table(Case_Number,Status,TSFC_Error,Mass_Error,FAR)

%% Props: syntax tests
clc; clear; close all;
%tic
%Eng = EngineModelPkg.TurbopropNonlinearSizing(EngineModelPkg.EngineSpecsPkg.Allison_250_C30G,1)
SetSpecs = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
%Specs.Visualize = true;

%Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs)
%Eng = EngineModelPkg.TurbopropNonlinearSizing(EngineModelPkg.EngineSpecsPkg.TPE331_14GR_805H,1)
%toc

N = 100;

% loop through compressor efficiencies

Specs = SetSpecs;
competas = linspace(0.8,1,N);
BSFC_comp = zeros(1,N);

for ii = 1:N
    Specs.EtaPoly.Compressors = competas(ii);
    Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs);
    BSFC_comp(ii) = Eng.BSFC_Imp;
end

figure(1)
subplot(1,2,1)
plot(competas,BSFC_comp)
grid on
xlabel('Compressor Efficiency')
ylabel('BSFC [lb/hp/hr]')

%
Specs = SetSpecs;
turbetas = linspace(0.8,1,N);
BSFC_turb = zeros(1,N);

for ii = 1:N
    Specs.EtaPoly.Compressors = turbetas(ii);
    Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs);
    BSFC_turb(ii) = Eng.BSFC_Imp;
end

subplot(1,2,2)
plot(turbetas,BSFC_turb)
grid on
xlabel('Turbine Efficiency')
ylabel('BSFC [lb/hp/hr]')


figure(2)
%
Specs = SetSpecs;
tt4 = linspace(11e3,3e3,N);
BSFC_tt = zeros(1,N);

for ii = 1:N
    Specs.Tt4Max = tt4(ii);
    Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs);
    BSFC_tt(ii) = Eng.BSFC_Imp;
    FAR(ii) = Eng.Fuel.FAR;
end

subplot(1,2,1)
plot(tt4,BSFC_tt)
grid on
ylabel('BSFC [lb/hp/hr]')
xlabel('Tt4 [k]')

subplot(1,2,2)
plot(tt4,FAR)
grid on
ylabel('FAR')
xlabel('Tt4 [k]')

%%

clc; clear; close all;
Specs = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
Specs.Visualize = true;

Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs)

%% PW 123 for Yi-Chih

clc; clear; close all;

Specs = EngineModelPkg.EngineSpecsPkg.PW_123;

N = 50;
Alts = linspace(0,7000,N);
Machs = linspace(0.05,0.6,N);

[ALTS,MACHS] = meshgrid(Alts,Machs);

BSFCs_SI = zeros(N);
BSFCs_Imp = zeros(N);

for ii = 1:N
    for jj = 1:N
        Specs.Alt = ALTS(ii,jj);
        Specs.Mach = MACHS(ii,jj);
        Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs,0);
        BSFCs_SI(ii,jj) = Eng.BSFC;
        BSFCs_Imp(ii,jj) = Eng.BSFC_Imp;
    end
end

figure(1)
contourf(ALTS,MACHS,BSFCs_Imp)
colorbar
xlabel('Altitude [m]')
ylabel('Mach Number')
title('BSFC [lb/lb/hr]')

save(fullfile("+EngineModelPkg", "PW_123_Trade.mat"),'ALTS','MACHS','BSFCs_SI','BSFCs_Imp')



%% FAST: testing database and user aircraft using an engine model
clc; clear; close all;


PlaneSpec = AircraftSpecsPkg.ERJ190_E2;
PlaneSpec = MissionSegsPkg.SpecProcessing(PlaneSpec)


load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
PlaneDatabase = TurbofanAC.ERJ_190_300;
PlaneDatabase = MissionSegsPkg.SpecProcessing(PlaneDatabase)


%%
clc; clear; close all
Eng = EngineModelPkg.EngineSpecsPkg.AE2100_D3;

N = 7;

alts = UnitConversionPkg.ConvLength(1000*[0 2 5 10 15 20 25],'ft','m');
Powers = 3458e3/1.828e3*[1.828 1.783 1.666 1.475 1.205 0.957 0.753]*1000;
machs = linspace(0.05,0.59,N);


sfcs = alts.*0;
fb = sfcs;

for i = 1:N
    Eng.ReqPower = Powers(i);
    Eng.Mach = 0.3;%machs(i);
    Eng.Alt = alts(i);

    Sized = EngineModelPkg.TurbopropNonlinearSizing(Eng,0);

    sfcs(i) = Sized.BSFC_Imp;
    fb(i) = Sized.Fuel.MDot;
end

figure(1)

subplot(1,2,1)
plot(Powers,sfcs)
title({'Engine Model',"AE 2100D3, M = 0.3"})
xlabel('Alt [ft]')
ylabel('BSFC [lbm/hp/hr')

% subplot(1,2,2)
% plot(alts,fb)
% title('Fuel Burn vs Alt')


for i = 1:2
    % Check epass data PW 127M
    epass = [
        % MN       Alt      PC     FgEng       Ram       SHP      Fuel      TSFC
        0.00       0.0  110.00    1084.1       0.0   2701.07    1826.4   0.21814
        0.00       0.0  100.00    1084.1       0.0   2701.07    1826.4   0.21814
        0.00       0.0   88.13     806.9       0.0   1979.66    1395.4   0.18912
        0.00       0.0   80.21     660.4       0.0   1566.38    1160.0   0.17273
        0.00       0.0   72.29     554.0       0.0   1250.79     983.6   0.16250
        0.00       0.0   64.38     472.3       0.0    999.23     843.7   0.15653
        0.00       0.0   56.46     410.5       0.0    803.78     734.8   0.15544
        0.00       0.0   40.62     318.0       0.0    507.55     567.7   0.16690
        0.00       0.0   32.71     286.0       0.0    403.97     508.2   0.18557
        0.00       0.0   24.79     257.0       0.0    310.51     453.3   0.21836
        0.00       0.0   16.88     228.7       0.0    220.14     398.3   0.28191
        0.00       0.0    8.96     196.5       0.0    117.65     334.3   0.44570
        0.00       0.0    5.00     176.6       0.0     56.27     293.4   0.70076
        0.10       0.0  110.00    1089.5      83.3   2712.05    1830.5   0.24592
        0.10       0.0  100.00    1089.6      83.3   2712.02    1830.5   0.24592
        0.10       0.0   88.13     865.0      76.0   2135.32    1483.4   0.22614
        0.10       0.0   80.21     757.5      72.2   1841.34    1312.7   0.21987
        0.10       0.0   72.29     665.4      68.6   1579.47    1164.7   0.21645
        0.10       0.0   64.38     585.9      65.3   1346.07    1034.0   0.21578
        0.10       0.0   56.46     516.3      62.2   1134.64     916.4   0.21807
        0.10       0.0   40.62     402.9      56.6    778.81     718.7   0.23766
        0.10       0.0   32.71     351.9      53.8    616.37     627.1   0.25757
        0.10       0.0   24.79     302.3      50.9    456.13     536.3   0.29062
        0.10       0.0   16.88     253.2      47.7    298.29     443.8   0.35330
        0.10       0.0    8.96     204.5      44.2    142.70     348.2   0.52216
        0.10       0.0    5.00     179.7      42.2     65.88     297.8   0.80009
        0.20       0.0  110.00    1105.6     168.1   2745.72    1842.6   0.30046
        0.20       0.0  100.00    1105.5     168.1   2745.89    1842.6   0.30045
        0.20       0.0   88.13     947.8     158.1   2349.15    1601.2   0.29627
        0.20       0.0   80.21     852.9     151.7   2098.08    1453.4   0.29547
        0.20       0.0   72.29     768.6     145.6   1868.33    1320.1   0.29775
        0.20       0.0   64.38     693.2     139.9   1655.35    1199.8   0.30389
        0.20       0.0   56.46     619.8     133.9   1443.63    1081.0   0.31219
        0.20       0.0   40.62     481.1     121.5   1022.98     847.5   0.34017
        0.20       0.0   32.71     418.0     115.2    824.27     737.1   0.36747
        0.20       0.0   24.79     366.2     109.7    660.19     645.2   0.42434
        0.20       0.0   16.88     308.9     102.9    475.49     541.0   0.52275
        0.20       0.0    8.96     241.7      94.2    260.25     414.6   0.75465
        0.20       0.0    5.00     199.1      87.9    124.93     330.9   1.07905
        0.25       0.0  110.00    1107.8     210.8   2747.01    1836.3   0.33722
        0.25       0.0  100.00    1107.8     210.8   2747.01    1836.3   0.33722
        0.25       0.0   88.13     969.4     199.9   2400.55    1625.3   0.33871
        0.25       0.0   80.21     882.8     192.6   2173.95    1491.4   0.34145
        0.25       0.0   72.29     799.3     185.3   1949.07    1360.4   0.34557
        0.25       0.0   64.38     719.1     177.8   1725.65    1233.4   0.35185
        0.25       0.0   56.46     641.5     170.0   1504.04    1109.0   0.36071
        0.25       0.0   40.62     513.5     156.1   1120.91     896.5   0.40523
        0.25       0.0   32.71     461.6     149.9    959.74     807.3   0.45327
        0.25       0.0   24.79     404.8     142.7    780.58     707.7   0.52423
        0.25       0.0   16.88     340.4     133.8    575.95     592.9   0.64517
        0.25       0.0    8.96     263.7     121.8    330.02     451.7   0.92590
        0.25       0.0    5.00     217.0     113.7    180.89     361.5   1.32787
        0.30       0.0  110.00    1110.0     253.7   2747.01    1828.4   0.38226
        0.30       0.0  100.00    1109.7     253.7   2747.01    1828.2   0.38223
        0.30       0.0   88.13     973.7     240.9   2406.69    1621.3   0.38466
        0.30       0.0   80.21     887.5     232.3   2181.31    1488.1   0.38791
        0.30       0.0   72.29     804.0     223.5   1957.67    1357.8   0.39268
        0.30       0.0   64.38     732.0     215.4   1758.07    1244.5   0.40420
        0.30       0.0   56.46     675.5     208.7   1598.34    1154.8   0.42763
        0.30       0.0   40.62     556.3     193.7   1248.52     960.5   0.49430
        0.30       0.0   32.71     492.6     184.9   1053.77     852.9   0.54516
        0.30       0.0   24.79     424.7     174.9    841.20     735.2   0.62004
        0.30       0.0   16.88     350.1     162.8    605.28     603.3   0.74745
        0.30       0.0    8.96     265.9     147.1    335.76     449.3   1.04862
        0.30       0.0    5.00     219.0     137.4    186.33     359.4   1.50279
        0.35       0.0  110.00    1112.3     297.2   2747.01    1818.7   0.42424
        0.35       0.0  100.00    1112.2     297.2   2747.01    1818.6   0.42424
        0.35       0.0   88.13    1001.6     285.1   2472.44    1651.2   0.43708
        0.35       0.0   80.21     928.7     276.7   2284.66    1539.4   0.44773
        0.35       0.0   72.29     855.5     268.0   2091.90    1426.4   0.46028
        0.35       0.0   64.38     782.3     258.8   1893.41    1312.3   0.47553
        0.35       0.0   56.46     709.0     249.0   1688.79    1197.1   0.49461
        0.35       0.0   40.62     561.0     227.5   1259.04     958.4   0.55030
        0.35       0.0   32.71     486.7     215.5   1032.03     833.3   0.59431
        0.35       0.0   24.79     411.3     202.4    796.12     702.7   0.66121
        0.35       0.0   16.88     342.8     189.2    579.15     581.8   0.80421
        0.35       0.0    8.96     272.7     174.0    355.95     454.2   1.18271
        0.35       0.0    5.00     228.9     163.6    216.58     371.1   1.73152
        0.00    2000.0  110.00    1050.4       0.0   2598.84    1748.2   0.21945
        0.00    2000.0  100.00    1050.4       0.0   2598.84    1748.2   0.21945
        0.00    2000.0   88.13     778.3       0.0   1905.04    1331.0   0.18959
        0.00    2000.0   80.21     635.8       0.0   1508.65    1104.1   0.17280
        0.00    2000.0   72.29     530.5       0.0   1201.11     932.3   0.16189
        0.00    2000.0   64.38     450.6       0.0    957.63     797.3   0.15546
        0.00    2000.0   56.46     390.5       0.0    769.36     693.4   0.15418
        0.00    2000.0   40.62     300.7       0.0    483.96     533.2   0.16474
        0.00    2000.0   32.71     269.7       0.0    384.41     476.1   0.18271
        0.00    2000.0   24.79     241.8       0.0    295.48     423.7   0.21452
        0.00    2000.0   16.88     214.8       0.0    209.45     371.8   0.27658
        0.00    2000.0    8.96     184.2       0.0    112.30     311.5   0.43651
        0.00    2000.0    5.00     165.1       0.0     54.12     272.8   0.68489
        0.10    2000.0  110.00    1055.5      78.9   2609.15    1752.0   0.24704
        0.10    2000.0  100.00    1055.5      78.9   2609.11    1752.0   0.24704
        0.10    2000.0   88.13     830.5      71.7   2042.15    1408.8   0.22541
        0.10    2000.0   80.21     725.1      68.0   1758.17    1243.4   0.21859
        0.10    2000.0   72.29     635.5      64.6   1506.60    1100.5   0.21465
        0.10    2000.0   64.38     558.4      61.4   1282.50     975.3   0.21362
        0.10    2000.0   56.46     490.9      58.5   1080.29     863.0   0.21553
        0.10    2000.0   40.62     381.5      53.1    740.34     675.1   0.23432
        0.10    2000.0   32.71     332.6      50.4    585.93     588.4   0.25365
        0.10    2000.0   24.79     285.3      47.6    433.67     502.5   0.28579
        0.10    2000.0   16.88     238.3      44.6    283.77     414.9   0.34665
        0.10    2000.0    8.96     191.9      41.3    136.05     324.8   0.51121
        0.10    2000.0    5.00     168.1      39.5     63.17     277.0   0.78108
        0.20    2000.0  110.00    1070.7     159.2   2640.41    1763.4   0.29875
        0.20    2000.0  100.00    1070.7     159.2   2640.41    1763.4   0.29875
        0.20    2000.0   88.13     915.2     149.5   2257.12    1528.6   0.29386
        0.20    2000.0   80.21     821.9     143.3   2014.91    1385.1   0.29255
        0.20    2000.0   72.29     738.5     137.4   1791.31    1255.0   0.29410
        0.20    2000.0   64.38     664.8     131.9   1585.74    1138.4   0.29959
        0.20    2000.0   56.46     593.3     126.2   1381.75    1023.8   0.30719
        0.20    2000.0   40.62     458.3     114.3    977.78     799.9   0.33355
        0.20    2000.0   32.71     397.8     108.3    789.39     695.9   0.36045
        0.20    2000.0   24.79     347.8     103.0    632.23     608.1   0.41557
        0.20    2000.0   16.88     292.6      96.6    455.42     509.0   0.51098
        0.20    2000.0    8.96     227.9      88.2    249.66     388.7   0.73499
        0.20    2000.0    5.00     185.4      82.0    115.54     305.8   1.03626
        0.25    2000.0  110.00    1083.2     200.3   2665.98    1773.0   0.33497
        0.25    2000.0  100.00    1083.2     200.3   2665.96    1773.0   0.33497
        0.25    2000.0   88.13     943.3     189.5   2324.26    1562.9   0.33505
        0.25    2000.0   80.21     857.1     182.5   2103.69    1431.4   0.33715
        0.25    2000.0   72.29     774.4     175.4   1885.11    1303.3   0.34061
        0.25    2000.0   64.38     695.3     168.1   1668.16    1179.4   0.34613
        0.25    2000.0   56.46     618.9     160.7   1453.29    1058.4   0.35417
        0.25    2000.0   40.62     492.9     147.2   1081.86     852.3   0.39636
        0.25    2000.0   32.71     442.1     141.2    925.45     766.2   0.44256
        0.25    2000.0   24.79     386.4     134.2    751.87     670.4   0.51089
        0.25    2000.0   16.88     323.7     125.7    553.88     560.0   0.62696
        0.25    2000.0    8.96     249.3     114.2    316.93     424.5   0.89525
        0.25    2000.0    5.00     204.4     106.4    173.99     338.7   1.27978
        0.30    2000.0  110.00    1096.7     242.1   2693.42    1782.8   0.37836
        0.30    2000.0  100.00    1096.7     242.1   2693.30    1782.8   0.37837
        0.30    2000.0   88.13     958.9     229.5   2358.75    1576.5   0.37966
        0.30    2000.0   80.21     871.8     221.0   2137.31    1444.2   0.38212
        0.30    2000.0   72.29     788.1     212.5   1917.46    1315.2   0.38609
        0.30    2000.0   64.38     712.9     204.3   1713.31    1198.2   0.39503
        0.30    2000.0   56.46     656.2     197.8   1555.67    1109.3   0.41700
        0.30    2000.0   40.62     537.1     183.1   1211.14     917.7   0.47940
        0.30    2000.0   32.71     473.6     174.5   1020.03     812.4   0.52710
        0.30    2000.0   24.79     406.4     164.7    812.06     697.8   0.59730
        0.30    2000.0   16.88     333.1     152.9    582.26     570.2   0.71712
        0.30    2000.0    8.96     251.2     137.9    321.71     422.0   0.99986
        0.30    2000.0    5.00     207.7     128.9    183.64     339.5   1.44110
        0.35    2000.0  110.00    1113.2     285.0   2726.56    1794.9   0.41941
        0.35    2000.0  100.00    1113.3     285.0   2726.46    1794.9   0.41942
        0.35    2000.0   88.13     991.8     272.2   2434.80    1613.9   0.42794
        0.35    2000.0   80.21     916.7     263.8   2247.09    1500.8   0.43722
        0.35    2000.0   72.29     841.9     255.1   2054.60    1386.7   0.44822
        0.35    2000.0   64.38     767.3     246.1   1856.86    1271.7   0.46161
        0.35    2000.0   56.46     692.9     236.5   1653.45    1156.6   0.47869
        0.35    2000.0   40.62     543.9     215.4   1228.10     919.6   0.52897
        0.35    2000.0   32.71     469.6     203.6   1004.61     796.8   0.56924
        0.35    2000.0   24.79     394.7     190.8    773.18     669.3   0.63086
        0.35    2000.0   16.88     330.3     178.6    570.55     557.2   0.77157
        0.35    2000.0    8.96     261.2     163.9    352.24     433.4   1.13044
        0.35    2000.0    5.00     218.1     153.7    215.46     352.6   1.64765
        0.40    2000.0  110.00    1124.9     328.2   2747.01    1797.1   0.46941
        0.40    2000.0  100.00    1125.0     328.2   2747.01    1797.2   0.46942
        0.40    2000.0   88.13     994.5     312.5   2434.65    1603.5   0.47528
        0.40    2000.0   80.21     910.3     301.8   2224.39    1476.9   0.48095
        0.40    2000.0   72.29     828.1     290.9   2012.53    1351.9   0.48848
        0.40    2000.0   64.38     748.0     279.5   1798.88    1229.2   0.49877
        0.40    2000.0   56.46     669.5     267.7   1583.86    1108.0   0.51262
        0.40    2000.0   40.62     553.6     248.8   1252.46     924.4   0.59437
        0.40    2000.0   32.71     496.9     238.8   1083.73     831.7   0.66419
        0.40    2000.0   24.79     435.4     227.2    895.90     728.5   0.76758
        0.40    2000.0   16.88     366.1     213.0    681.09     610.1   0.94437
        0.40    2000.0    8.96     283.8     194.0    422.26     465.8   1.35809
        0.40    2000.0    5.00     234.0     181.1    264.49     374.4   1.95589
        0.00    5000.0  110.00    1000.9       0.0   2447.19    1635.2   0.22167
        0.00    5000.0  100.00    1000.9       0.0   2447.19    1635.2   0.22167
        0.00    5000.0   88.13     736.3       0.0   1793.53    1237.4   0.19036
        0.00    5000.0   80.21     599.5       0.0   1421.71    1023.4   0.17298
        0.00    5000.0   72.29     496.6       0.0   1127.32     859.1   0.16110
        0.00    5000.0   64.38     419.3       0.0    896.35     732.0   0.15415
        0.00    5000.0   56.46     361.5       0.0    718.27     634.1   0.15227
        0.00    5000.0   40.62     276.1       0.0    449.68     484.5   0.16166
        0.00    5000.0   32.71     246.6       0.0    356.02     430.5   0.17845
        0.00    5000.0   24.79     220.6       0.0    273.63     382.6   0.20923
        0.00    5000.0   16.88     195.4       0.0    193.91     334.9   0.26904
        0.00    5000.0    8.96     166.7       0.0    104.48     279.4   0.42279
        0.00    5000.0    5.00     149.3       0.0     50.83     244.6   0.66318
        0.10    5000.0  110.00    1005.6      72.6   2456.70    1638.7   0.24906
        0.10    5000.0  100.00    1005.6      72.6   2456.68    1638.7   0.24906
        0.10    5000.0   88.13     779.8      65.6   1904.86    1301.0   0.22438
        0.10    5000.0   80.21     678.0      62.1   1635.88    1143.6   0.21670
        0.10    5000.0   72.29     592.1      59.0   1399.84    1008.7   0.21207
        0.10    5000.0   64.38     518.4      56.0   1189.74     891.6   0.21051
        0.10    5000.0   56.46     454.1      53.2   1001.14     787.2   0.21191
        0.10    5000.0   40.62     350.9      48.2    684.73     613.7   0.22959
        0.10    5000.0   32.71     305.2      45.7    541.79     534.0   0.24815
        0.10    5000.0   24.79     260.9      43.1    401.04     454.8   0.27885
        0.10    5000.0   16.88     217.3      40.4    262.57     374.4   0.33721
        0.10    5000.0    8.96     174.0      37.3    126.28     291.8   0.49514
        0.10    5000.0    5.00     152.0      35.6     59.05     248.3   0.75479
        0.20    5000.0  110.00    1019.9     146.5   2484.82    1649.3   0.29681
        0.20    5000.0  100.00    1019.9     146.5   2484.83    1649.3   0.29681
        0.20    5000.0   88.13     867.0     137.2   2120.06    1423.3   0.29066
        0.20    5000.0   80.21     776.0     131.4   1890.77    1285.8   0.28849
        0.20    5000.0   72.29     694.5     125.8   1676.92    1160.7   0.28895
        0.20    5000.0   64.38     623.3     120.6   1482.96    1049.7   0.29346
        0.20    5000.0   56.46     554.7     115.3   1290.92     941.8   0.30022
        0.20    5000.0   40.62     425.7     104.1    912.00     732.8   0.32464
        0.20    5000.0   32.71     368.8      98.5    737.91     637.3   0.35066
        0.20    5000.0   24.79     321.4      93.6    590.84     555.8   0.40343
        0.20    5000.0   16.88     269.1      87.6    425.62     463.5   0.49432
        0.20    5000.0    8.96     208.4      79.9    233.71     352.1   0.70737
        0.20    5000.0    5.00     166.7      73.8    103.77     272.1   0.97947
        0.25    5000.0  110.00    1031.5     184.3   2507.75    1658.1   0.33175
        0.25    5000.0  100.00    1031.6     184.3   2507.72    1658.1   0.33175
        0.25    5000.0   88.13     893.4     174.0   2181.08    1454.8   0.33031
        0.25    5000.0   80.21     809.5     167.3   1972.58    1329.0   0.33151
        0.25    5000.0   72.29     729.4     160.6   1766.15    1207.5   0.33419
        0.25    5000.0   64.38     653.1     153.9   1561.64    1089.7   0.33868
        0.25    5000.0   56.46     579.8     146.9   1359.43     975.3   0.34562
        0.25    5000.0   40.62     460.0     134.4   1013.91     783.8   0.38604
        0.25    5000.0   32.71     411.0     128.7    865.76     703.1   0.43010
        0.25    5000.0   24.79     357.5     122.1    701.76     613.2   0.49483
        0.25    5000.0   16.88     298.0     114.0    515.22     510.1   0.60473
        0.25    5000.0    8.96     227.6     103.3    293.58     383.8   0.85722
        0.25    5000.0    5.00     185.6      96.1    161.20     304.9   1.22004
        0.30    5000.0  110.00    1043.8     222.7   2531.80    1666.9   0.37328
        0.30    5000.0  100.00    1043.9     222.7   2531.68    1666.9   0.37328
        0.30    5000.0   88.13     909.5     210.8   2216.38    1469.9   0.37353
        0.30    5000.0   80.21     825.0     202.8   2007.82    1343.7   0.37515
        0.30    5000.0   72.29     744.1     194.8   1800.76    1221.4   0.37837
        0.30    5000.0   64.38     672.2     187.2   1609.83    1111.3   0.38659
        0.30    5000.0   56.46     616.3     181.0   1458.02    1024.8   0.40647
        0.30    5000.0   40.62     499.7     166.9   1127.78     841.2   0.46368
        0.30    5000.0   32.71     438.3     158.7    945.66     741.5   0.50764
        0.30    5000.0   24.79     373.5     149.4    748.79     633.8   0.57253
        0.30    5000.0   16.88     304.2     138.3    533.03     515.0   0.68341
        0.30    5000.0    8.96     227.5     124.4    291.97     378.2   0.94534
        0.30    5000.0    5.00     189.9     116.7    174.13     308.2   1.38028
        0.35    5000.0  110.00    1059.2     262.0   2559.98    1677.7   0.41324
        0.35    5000.0  100.00    1059.2     262.1   2560.11    1677.7   0.41324
        0.35    5000.0   88.13     938.6     249.7   2281.08    1502.0   0.41980
        0.35    5000.0   80.21     864.0     241.7   2100.15    1391.5   0.42732
        0.35    5000.0   72.29     790.1     233.4   1915.28    1281.0   0.43647
        0.35    5000.0   64.38     717.3     224.7   1725.99    1170.7   0.44793
        0.35    5000.0   56.46     644.9     215.6   1532.31    1059.8   0.46238
        0.35    5000.0   40.62     501.7     195.7   1130.38     835.9   0.50682
        0.35    5000.0   32.71     431.1     184.7    921.05     721.5   0.54336
        0.35    5000.0   24.79     360.3     172.6    706.10     603.9   0.59997
        0.35    5000.0   16.88     306.2     162.5    537.52     511.5   0.74666
        0.35    5000.0    8.96     240.8     148.8    332.79     396.1   1.08923
        0.35    5000.0    5.00     200.0     139.3    204.33     320.9   1.58078
        0.40    5000.0  110.00    1078.2     302.6   2594.82    1691.2   0.46062
        0.40    5000.0  100.00    1078.2     302.6   2594.78    1691.1   0.46062
        0.40    5000.0   88.13     948.8     287.6   2299.08    1503.9   0.46482
        0.40    5000.0   80.21     866.2     277.5   2099.70    1382.0   0.46931
        0.40    5000.0   72.29     786.0     267.2   1898.58    1262.4   0.47564
        0.40    5000.0   64.38     708.2     256.5   1696.24    1144.9   0.48443
        0.40    5000.0   56.46     632.0     245.4   1492.74    1029.3   0.49655
        0.40    5000.0   40.62     524.9     228.5   1193.29     862.9   0.57854
        0.40    5000.0   32.71     469.1     218.9   1031.48     774.2   0.64472
        0.40    5000.0   24.79     409.0     207.8    851.45     676.0   0.74267
        0.40    5000.0   16.88     341.6     194.3    645.79     563.7   0.90984
        0.40    5000.0    8.96     262.3     176.3    398.70     426.8   1.29774
        0.40    5000.0    5.00     214.6     164.1    248.70     340.7   1.85585
        0.45    5000.0  110.00    1099.9     344.4   2633.97    1706.3   0.50005
        0.45    5000.0  100.00    1099.9     344.4   2633.72    1706.3   0.50009
        0.45    5000.0   88.13    1000.8     331.8   2413.79    1564.6   0.52036
        0.45    5000.0   80.21     935.2     323.0   2259.26    1469.0   0.53680
        0.45    5000.0   72.29     868.3     313.7   2098.67    1371.1   0.55587
        0.45    5000.0   64.38     800.9     304.0   1930.47    1271.1   0.57872
        0.45    5000.0   56.46     732.3     293.6   1753.89    1168.5   0.60661
        0.45    5000.0   40.62     589.4     269.8   1370.42     952.3   0.68704
        0.45    5000.0   32.71     514.5     256.1   1159.41     835.6   0.74875
        0.45    5000.0   24.79     436.7     240.8    931.04     710.9   0.84040
        0.45    5000.0   16.88     354.1     222.6    680.88     574.8   0.99834
        0.45    5000.0    8.96     263.9     199.8    401.56     420.9   1.37706
        0.45    5000.0    5.00     215.3     185.9    249.58     333.7   1.95621
        0.10   10000.0  110.00     893.3      61.9   2138.82    1419.7   0.24907
        0.10   10000.0  100.00     893.3      61.9   2138.82    1419.7   0.24907
        0.10   10000.0   88.13     683.8      55.7   1648.21    1113.5   0.22168
        0.10   10000.0   80.21     592.0      52.7   1413.17     975.9   0.21345
        0.10   10000.0   72.29     514.7      49.9   1207.63     858.4   0.20831
        0.10   10000.0   64.38     449.0      47.3   1024.97     756.6   0.20621
        0.10   10000.0   56.46     392.0      44.9    861.68     666.9   0.20723
        0.10   10000.0   40.62     300.9      40.5    589.29     517.9   0.22368
        0.10   10000.0   32.71     261.2      38.4    465.95     450.3   0.24154
        0.10   10000.0   24.79     222.1      36.2    344.91     381.9   0.27026
        0.10   10000.0   16.88     184.2      33.8    225.87     313.8   0.32621
        0.10   10000.0    8.96     146.5      31.2    109.03     242.9   0.47577
        0.10   10000.0    5.00     127.6      29.7     51.37     206.4   0.72407
        0.20   10000.0  110.00     922.1     125.8   2195.33    1451.5   0.29450
        0.20   10000.0  100.00     922.1     125.8   2195.36    1451.5   0.29450
        0.20   10000.0   88.13     776.5     117.5   1868.58    1242.1   0.28598
        0.20   10000.0   80.21     691.8     112.3   1663.84    1117.5   0.28269
        0.20   10000.0   72.29     616.1     107.3   1472.27    1004.7   0.28199
        0.20   10000.0   64.38     550.0     102.7   1299.44     905.0   0.28523
        0.20   10000.0   56.46     487.2      97.9   1128.89     809.3   0.29083
        0.20   10000.0   40.62     370.1      88.0    794.78     625.6   0.31246
        0.20   10000.0   32.71     321.0      83.4    648.29     545.7   0.33852
        0.20   10000.0   24.79     278.5      79.0    518.34     474.6   0.38840
        0.20   10000.0   16.88     231.5      73.8    372.92     393.5   0.47307
        0.20   10000.0    8.96     177.8      67.1    204.67     297.3   0.67332
        0.20   10000.0    5.00     138.9      61.5     85.44     224.2   0.90976
        0.25   10000.0  110.00     938.8     158.7   2226.29    1467.4   0.32754
        0.25   10000.0  100.00     938.8     158.7   2226.29    1467.4   0.32754
        0.25   10000.0   88.13     805.3     149.3   1932.98    1277.6   0.32358
        0.25   10000.0   80.21     726.3     143.4   1746.29    1162.5   0.32349
        0.25   10000.0   72.29     652.0     137.4   1561.57    1052.6   0.32500
        0.25   10000.0   64.38     581.2     131.4   1379.37     946.8   0.32828
        0.25   10000.0   56.46     513.8     125.2   1199.51     844.7   0.33393
        0.25   10000.0   40.62     406.2     114.3    898.57     678.6   0.37285
        0.25   10000.0   32.71     360.2     109.2    764.18     605.3   0.41305
        0.25   10000.0   24.79     310.8     103.2    616.02     524.6   0.47232
        0.25   10000.0   16.88     256.4      96.0    448.81     433.1   0.57283
        0.25   10000.0    8.96     193.5      86.7    252.95     322.3   0.80313
        0.25   10000.0    5.00     156.2      80.3    138.00     254.1   1.13444
        0.30   10000.0  110.00     950.1     191.7   2245.93    1475.3   0.36689
        0.30   10000.0  100.00     950.1     191.7   2245.92    1475.3   0.36689
        0.30   10000.0   88.13     821.1     181.0   1966.15    1293.3   0.36497
        0.30   10000.0   80.21     741.9     173.9   1780.17    1178.1   0.36528
        0.30   10000.0   72.29     666.8     166.8   1595.51    1067.6   0.36727
        0.30   10000.0   64.38     602.1     160.3   1430.82     971.6   0.37532
        0.30   10000.0   56.46     548.0     154.5   1289.11     890.1   0.39208
        0.30   10000.0   40.62     436.8     141.5    983.94     720.6   0.44110
        0.30   10000.0   32.71     379.1     134.0    818.08     630.2   0.47914
        0.30   10000.0   24.79     319.6     125.5    640.96     534.0   0.53563
        0.30   10000.0   16.88     257.3     115.8    450.24     429.7   0.63330
        0.30   10000.0    8.96     195.9     104.8    259.61     322.4   0.89487
        0.30   10000.0    5.00     162.5      98.1    156.63     261.9   1.30235
        0.35   10000.0  110.00     963.4     225.5   2268.67    1484.4   0.40457
        0.35   10000.0  100.00     963.4     225.5   2268.64    1484.4   0.40457
        0.35   10000.0   88.13     845.2     214.2   2017.64    1319.4   0.40804
        0.35   10000.0   80.21     772.6     206.7   1849.91    1214.6   0.41270
        0.35   10000.0   72.29     702.1     199.1   1679.16    1111.4   0.41900
        0.35   10000.0   64.38     632.9     191.2   1506.04    1009.3   0.42731
        0.35   10000.0   56.46     564.9     183.0   1330.39     907.8   0.43821
        0.35   10000.0   40.62     433.1     165.1    970.55     707.9   0.47493
        0.35   10000.0   32.71     369.2     155.3    786.25     607.6   0.50630
        0.35   10000.0   24.79     317.5     146.6    632.25     524.1   0.57621
        0.35   10000.0   16.88     268.5     137.7    483.01     443.0   0.71540
        0.35   10000.0    8.96     209.2     125.8    299.81     340.7   1.03664
        0.35   10000.0    5.00     171.9     117.3    184.88     274.2   1.49450
        0.40   10000.0  110.00     979.9     260.3   2296.73    1495.9   0.44967
        0.40   10000.0  100.00     979.9     260.3   2296.65    1495.9   0.44967
        0.40   10000.0   88.13     855.4     246.7   2035.81    1323.3   0.45137
        0.40   10000.0   80.21     778.3     237.7   1858.13    1212.4   0.45438
        0.40   10000.0   72.29     703.9     228.6   1679.15    1104.2   0.45913
        0.40   10000.0   64.38     632.0     219.2   1499.02     998.3   0.46616
        0.40   10000.0   56.46     570.0     210.7   1339.85     906.2   0.48248
        0.40   10000.0   40.62     471.8     195.8   1075.55     758.9   0.56155
        0.40   10000.0   32.71     418.7     187.0    926.42     677.6   0.62274
        0.40   10000.0   24.79     361.6     176.8    761.18     587.9   0.71285
        0.40   10000.0   16.88     298.8     164.6    572.95     486.2   0.86614
        0.40   10000.0    8.96     225.6     148.4    349.21     363.0   1.21810
        0.40   10000.0    5.00     182.2     137.5    215.43     286.8   1.72419
        0.45   10000.0  110.00     999.1     296.1   2328.33    1509.0   0.49309
        0.45   10000.0  100.00     999.1     296.1   2328.49    1509.1   0.49307
        0.45   10000.0   88.13     898.6     284.0   2123.35    1371.2   0.50842
        0.45   10000.0   80.21     833.2     275.7   1979.41    1279.2   0.52113
        0.45   10000.0   72.29     768.4     267.1   1829.52    1186.5   0.53626
        0.45   10000.0   64.38     703.6     258.1   1673.28    1092.7   0.55459
        0.45   10000.0   56.46     638.1     248.5   1510.47     996.8   0.57690
        0.45   10000.0   40.62     504.5     226.9   1160.85     798.9   0.64255
        0.45   10000.0   32.71     435.9     214.5    971.40     695.1   0.69434
        0.45   10000.0   24.79     365.5     200.6    769.79     585.7   0.77196
        0.45   10000.0   16.88     293.0     184.7    553.05     468.9   0.90789
        0.45   10000.0    8.96     221.0     166.7    333.07     347.9   1.26897
        0.45   10000.0    5.00     183.9     156.1    219.58     283.1   1.85011
        0.50   10000.0  110.00    1021.3     333.2   2364.93    1524.3   0.53870
        0.50   10000.0  100.00    1021.3     333.2   2364.97    1524.3   0.53869
        0.50   10000.0   88.13     897.2     316.8   2113.22    1354.9   0.54338
        0.50   10000.0   80.21     818.9     305.6   1940.37    1245.0   0.54855
        0.50   10000.0   72.29     743.6     294.3   1763.84    1137.6   0.55615
        0.50   10000.0   64.38     670.2     282.7   1584.91    1031.4   0.56624
        0.50   10000.0   56.46     600.2     270.9   1408.65     929.2   0.58167
        0.50   10000.0   40.62     502.5     253.0   1151.31     785.4   0.68321
        0.50   10000.0   32.71     449.5     242.4   1005.51     705.6   0.76238
        0.50   10000.0   24.79     392.1     230.2    843.46     617.6   0.88044
        0.50   10000.0   16.88     328.8     215.4    657.40     517.6   1.08409
        0.50   10000.0    8.96     254.3     196.0    433.26     396.0   1.56221
        0.50   10000.0    5.00     209.6     182.9    296.33     320.0   2.26195
        0.55   10000.0  110.00    1047.1     371.9   2406.45    1541.9   0.61333
        0.55   10000.0  100.00    1047.1     371.9   2406.56    1541.9   0.61331
        0.55   10000.0   88.13     945.4     357.4   2205.17    1404.3   0.63387
        0.55   10000.0   80.21     877.8     347.2   2064.41    1311.9   0.65063
        0.55   10000.0   72.29     811.6     336.7   1916.50    1219.2   0.67083
        0.55   10000.0   64.38     745.6     325.7   1761.42    1125.5   0.69547
        0.55   10000.0   56.46     678.6     314.1   1599.59    1029.6   0.72540
        0.55   10000.0   40.62     541.5     287.8   1249.96     831.0   0.81365
        0.55   10000.0   32.71     470.8     272.9   1059.40     725.8   0.88268
        0.55   10000.0   24.79     397.7     256.0    855.45     615.2   0.98701
        0.55   10000.0   16.88     322.1     236.6    634.07     496.6   1.17061
        0.55   10000.0    8.96     241.6     213.0    391.30     365.3   1.62202
        0.55   10000.0    5.00     198.2     198.7    259.83     291.6   2.31993
        0.20   15000.0  110.00     752.8     103.5   1764.04    1161.5   0.28597
        0.20   15000.0  100.00     752.9     103.5   1763.99    1161.5   0.28597
        0.20   15000.0   88.13     636.2      96.9   1505.63     997.0   0.27855
        0.20   15000.0   80.21     568.0      92.6   1342.49     899.4   0.27609
        0.20   15000.0   72.29     508.2      88.6   1194.88     813.0   0.27687
        0.20   15000.0   64.38     453.0      84.7   1052.02     731.7   0.27983
        0.20   15000.0   56.46     400.5      80.8    911.98     653.0   0.28479
        0.20   15000.0   40.62     303.5      72.6    639.42     504.2   0.30558
        0.20   15000.0   32.71     268.2      69.3    535.50     448.0   0.33723
        0.20   15000.0   24.79     232.0      65.6    426.33     388.5   0.38583
        0.20   15000.0   16.88     192.1      61.2    304.90     321.1   0.46845
        0.20   15000.0    8.96     146.8      55.6    165.89     241.3   0.66321
        0.20   15000.0    5.00     113.5      50.8     64.36     180.1   0.88695
        0.30   15000.0  110.00     793.2     159.1   1840.71    1205.1   0.35859
        0.30   15000.0  100.00     793.2     159.1   1840.81    1205.1   0.35858
        0.30   15000.0   80.21     618.1     144.3   1457.19     960.3   0.35622
        0.30   15000.0   72.29     557.0     138.5   1311.28     873.3   0.35942
        0.30   15000.0   64.38     508.2     133.6   1189.82     802.8   0.37105
        0.30   15000.0   56.46     459.3     128.4   1064.07     731.3   0.38541
        0.30   15000.0   40.62     360.4     116.9    797.83     583.9   0.42763
        0.30   15000.0   32.71     310.2     110.4    656.09     506.8   0.46104
        0.30   15000.0   24.79     259.7     103.2    507.28     426.6   0.51202
        0.30   15000.0   16.88     208.6      95.2    353.80     342.5   0.60385
        0.30   15000.0    8.96     164.2      87.3    217.80     266.0   0.88365
        0.30   15000.0    5.00     135.8      81.7    131.25     215.4   1.28161
        0.35   15000.0  110.00     819.2     188.4   1889.09    1233.1   0.39685
        0.35   15000.0  100.00     819.2     188.4   1889.14    1233.1   0.39684
        0.35   15000.0   88.13     716.8     179.0   1679.38    1092.5   0.39896
        0.35   15000.0   80.21     653.1     172.5   1535.88    1003.2   0.40249
        0.35   15000.0   72.29     591.4     165.9   1390.66     915.4   0.40750
        0.35   15000.0   64.38     531.0     159.0   1244.12     829.1   0.41449
        0.35   15000.0   56.46     472.6     152.0   1095.78     744.5   0.42435
        0.35   15000.0   40.62     360.1     136.8    794.75     577.8   0.45768
        0.35   15000.0   32.71     312.3     129.6    660.49     504.9   0.49678
        0.35   15000.0   24.79     273.9     123.3    547.76     444.4   0.57688
        0.35   15000.0   16.88     230.2     115.6    417.79     373.6   0.71253
        0.35   15000.0    8.96     177.9     105.2    258.45     285.6   1.02605
        0.35   15000.0    5.00     145.1      97.9    158.93     228.3   1.46943
        0.40   15000.0  110.00     850.5     219.2   1946.23    1266.6   0.43931
        0.40   15000.0  100.00     850.5     219.2   1946.13    1266.6   0.43932
        0.40   15000.0   88.13     740.0     207.7   1724.00    1115.7   0.43913
        0.40   15000.0   80.21     671.0     199.9   1573.39    1020.2   0.44115
        0.40   15000.0   72.29     605.6     192.0   1420.87     927.5   0.44503
        0.40   15000.0   64.38     545.2     184.3   1275.77     841.7   0.45349
        0.40   15000.0   56.46     502.0     178.5   1167.69     779.6   0.47895
        0.40   15000.0   40.62     410.6     165.1    929.65     646.2   0.55171
        0.40   15000.0   32.71     361.5     157.2    796.09     573.3   0.60798
        0.40   15000.0   24.79     309.3     148.1    648.99     493.9   0.69103
        0.40   15000.0   16.88     252.7     137.3    482.86     404.6   0.83156
        0.40   15000.0    8.96     188.3     123.3    288.62     298.4   1.15525
        0.40   15000.0    5.00     150.8     114.0    175.33     233.8   1.62161
        0.45   15000.0  110.00     887.1     251.5   2009.67    1305.0   0.48546
        0.45   15000.0  100.00     887.0     251.5   2009.82    1305.0   0.48544
        0.45   15000.0   88.13     789.9     240.5   1821.15    1173.5   0.49534
        0.45   15000.0   80.21     726.1     232.8   1690.25    1087.0   0.50409
        0.45   15000.0   72.29     664.7     224.9   1553.63    1001.6   0.51537
        0.45   15000.0   64.38     603.8     216.6   1412.33     915.9   0.52921
        0.45   15000.0   56.46     543.2     207.9   1265.95     829.7   0.54668
        0.45   15000.0   40.62     421.9     188.5    956.58     655.2   0.59989
        0.45   15000.0   32.71     361.1     177.5    792.07     565.5   0.64308
        0.45   15000.0   24.79     300.1     165.5    619.72     472.9   0.70948
        0.45   15000.0   16.88     242.3     152.8    450.24     381.4   0.84062
        0.45   15000.0    8.96     189.0     139.6    289.54     293.8   1.21979
        0.45   15000.0    5.00     156.2     130.6    190.62     237.9   1.76961
        0.50   15000.0  110.00     925.0     285.2   2072.63    1342.4   0.52255
        0.50   15000.0  100.00     924.9     285.2   2072.84    1342.5   0.52253
        0.50   15000.0   88.13     807.7     270.6   1851.10    1186.1   0.52386
        0.50   15000.0   80.21     733.2     260.7   1699.67    1085.4   0.52674
        0.50   15000.0   72.29     662.8     250.7   1544.26     988.1   0.53203
        0.50   15000.0   64.38     594.6     240.3   1386.46     892.7   0.53977
        0.50   15000.0   56.46     549.4     233.1   1277.03     828.8   0.57136
        0.50   15000.0   40.62     455.4     216.7   1040.64     694.9   0.66580
        0.50   15000.0   32.71     404.7     207.1    906.87     621.4   0.73954
        0.50   15000.0   24.79     350.0     195.9    758.32     540.8   0.84904
        0.50   15000.0   16.88     290.1     182.5    588.12     449.6   1.03710
        0.50   15000.0    8.96     220.8     165.1    383.39     339.5   1.47497
        0.50   15000.0    5.00     179.3     153.2    259.27     271.1   2.11039
        0.55   15000.0  110.00     948.9     318.5   2108.55    1358.8   0.59676
        0.55   15000.0  100.00     948.9     318.5   2108.41    1358.8   0.59679
        0.55   15000.0   88.13     848.7     304.9   1924.09    1227.1   0.61155
        0.55   15000.0   80.21     782.9     295.5   1795.36    1139.5   0.62397
        0.55   15000.0   72.29     718.0     285.9   1661.18    1052.1   0.63921
        0.55   15000.0   64.38     654.8     275.8   1520.25     964.8   0.65822
        0.55   15000.0   56.46     591.6     265.1   1373.29     876.8   0.68205
        0.55   15000.0   40.62     464.2     241.4   1058.93     697.3   0.75390
        0.55   15000.0   32.71     399.7     227.9    889.52     604.6   0.81184
        0.55   15000.0   24.79     334.2     213.0    710.33     508.1   0.90011
        0.55   15000.0   16.88     267.4     196.0    519.16     405.8   1.05621
        0.55   15000.0    8.96     205.2     178.1    334.64     306.4   1.50216
        0.55   15000.0    5.00     172.2     167.3    235.93     252.0   2.21351
        0.30   20000.0  110.00     643.3     130.1   1468.03     957.0   0.34923
        0.30   20000.0  100.00     643.3     130.1   1467.90     957.0   0.34923
        0.30   20000.0   88.13     555.2     122.9   1283.50     837.9   0.34697
        0.30   20000.0   80.21     502.9     118.1   1165.18     765.9   0.34847
        0.30   20000.0   72.29     459.2     114.0   1061.62     704.7   0.35575
        0.30   20000.0   64.38     416.0     109.7    955.73     643.8   0.36495
        0.30   20000.0   56.46     373.0     105.1    847.60     582.3   0.37639
        0.30   20000.0   40.62     288.5      95.2    623.19     458.9   0.41227
        0.30   20000.0   32.71     247.1      89.8    506.55     396.2   0.44202
        0.30   20000.0   24.79     205.7      83.9    386.82     331.2   0.48749
        0.30   20000.0   16.88     173.8      78.8    291.45     279.5   0.60444
        0.30   20000.0    8.96     136.0      72.2    178.74     216.8   0.88315
        0.30   20000.0    5.00     112.3      67.5    107.14     175.6   1.28161
        0.40   20000.0  110.00     690.5     179.3   1552.82    1006.1   0.42799
        0.40   20000.0  100.00     690.5     179.4   1552.89    1006.2   0.42798
        0.40   20000.0   88.13     600.6     170.0   1374.40     886.4   0.42785
        0.40   20000.0   80.21     544.3     163.5   1253.71     810.7   0.42991
        0.40   20000.0   72.29     498.8     158.0   1149.73     748.1   0.44017
        0.40   20000.0   64.38     460.8     153.2   1059.88     695.3   0.45944
        0.40   20000.0   56.46     422.0     148.0    965.36     640.9   0.48284
        0.40   20000.0   40.62     340.7     136.3    758.65     525.1   0.54981
        0.40   20000.0   32.71     297.6     129.4    643.87     462.6   0.60165
        0.40   20000.0   24.79     252.4     121.6    518.62     395.4   0.67841
        0.40   20000.0   16.88     204.2     112.4    379.60     320.5   0.80793
        0.40   20000.0    8.96     150.8     100.8    221.33     233.9   1.11075
        0.40   20000.0    5.00     120.9      93.2    131.80     183.7   1.56271
        0.45   20000.0  110.00     720.6     205.8   1604.88    1037.1   0.47756
        0.45   20000.0  100.00     720.6     205.9   1605.00    1037.1   0.47754
        0.45   20000.0   88.13     636.9     196.4   1443.79     926.1   0.48390
        0.45   20000.0   80.21     582.4     189.6   1332.88     854.3   0.49044
        0.45   20000.0   72.29     530.2     182.7   1218.04     783.7   0.49914
        0.45   20000.0   64.38     479.2     175.6   1100.06     713.6   0.51044
        0.45   20000.0   56.46     428.9     168.3    979.21     643.7   0.52499
        0.45   20000.0   40.62     330.0     152.1    728.11     503.8   0.57101
        0.45   20000.0   32.71     281.4     143.1    597.33     433.4   0.61008
        0.45   20000.0   24.79     240.5     134.9    482.61     371.9   0.69068
        0.45   20000.0   16.88     202.4     126.6    372.33     312.6   0.85297
        0.45   20000.0    8.96     157.1     115.6    238.97     239.7   1.23196
        0.45   20000.0    5.00     129.6     108.0    156.94     194.1   1.78789
        0.50   20000.0  110.00     755.8     233.9   1663.87    1072.9   0.50858
        0.50   20000.0  100.00     755.8     233.9   1663.91    1072.9   0.50858
        0.50   20000.0   88.13     659.7     222.1   1484.27     946.8   0.50932
        0.50   20000.0   80.21     598.5     213.8   1361.86     866.6   0.51215
        0.50   20000.0   72.29     550.9     207.0   1260.43     803.1   0.52663
        0.50   20000.0   64.38     512.0     201.2   1172.25     750.3   0.55249
        0.50   20000.0   56.46     472.0     194.9   1078.97     695.5   0.58395
        0.50   20000.0   40.62     387.5     180.6    872.98     577.9   0.67438
        0.50   20000.0   32.71     342.1     172.1    756.83     514.2   0.74528
        0.50   20000.0   24.79     293.8     162.4    628.28     445.0   0.85082
        0.50   20000.0   16.88     241.1     150.8    482.34     366.7   1.03019
        0.50   20000.0    8.96     181.4     136.0    308.91     273.7   1.44838
        0.50   20000.0    5.00     146.5     126.1    205.71     217.1   2.05858
        0.55   20000.0  110.00     796.5     263.8   1729.47    1113.7   0.58361
        0.55   20000.0  100.00     796.5     263.8   1729.55    1113.7   0.58360
        0.55   20000.0   88.13     707.1     252.1   1569.14     997.5   0.59317
        0.55   20000.0   80.21     648.7     243.8   1457.52     922.0   0.60235
        0.55   20000.0   72.29     591.3     235.3   1342.17     846.8   0.61380
        0.55   20000.0   64.38     535.8     226.4   1221.54     772.9   0.62910
        0.55   20000.0   56.46     481.3     217.1   1096.25     699.0   0.64877
        0.55   20000.0   40.62     373.0     196.7    832.63     549.8   0.70913
        0.55   20000.0   32.71     319.1     185.4    693.04     473.9   0.75919
        0.55   20000.0   24.79     265.4     172.9    547.66     396.0   0.83708
        0.55   20000.0   16.88     223.9     162.4    430.39     333.6   1.03598
        0.55   20000.0    8.96     175.4     148.8    289.90     257.9   1.50851
        0.55   20000.0    5.00     146.6     139.7    204.53     211.5   2.21670
        0.30   25000.0  110.00     517.1     105.6   1158.96     753.9   0.34013
        0.30   25000.0  100.00     517.0     105.6   1159.08     753.9   0.34012
        0.30   25000.0   88.13     448.4     100.0   1017.03     662.2   0.33902
        0.30   25000.0   80.21     409.8      96.5    930.60     610.3   0.34326
        0.30   25000.0   72.29     372.2      92.9    843.07     558.9   0.34881
        0.30   25000.0   64.38     335.1      89.2    754.61     508.0   0.35600
        0.30   25000.0   56.46     299.2      85.4    664.86     457.8   0.36587
        0.30   25000.0   40.62     229.7      77.3    482.14     357.3   0.39685
        0.30   25000.0   32.71     196.0      72.8    389.05     307.3   0.42387
        0.30   25000.0   24.79     170.0      69.0    314.76     267.9   0.48747
        0.30   25000.0   16.88     143.8      64.9    239.00     227.2   0.60739
        0.30   25000.0    8.96     112.2      59.4    145.71     175.8   0.88524
        0.30   25000.0    5.00      92.1      55.4     86.92     142.0   1.28143
        0.40   25000.0  110.00     555.4     145.5   1227.34     792.7   0.41715
        0.40   25000.0  100.00     555.4     145.5   1227.38     792.7   0.41715
        0.40   25000.0   88.13     483.3     138.0   1086.18     698.5   0.41708
        0.40   25000.0   80.21     449.5     134.2   1014.26     653.9   0.42901
        0.40   25000.0   72.29     415.7     130.1    939.29     608.7   0.44311
        0.40   25000.0   64.38     381.6     125.9    861.10     562.6   0.45989
        0.40   25000.0   56.46     347.0     121.3    779.24     515.4   0.48040
        0.40   25000.0   40.62     276.2     111.2    602.04     416.6   0.53966
        0.40   25000.0   32.71     239.4     105.4    505.15     364.0   0.58563
        0.40   25000.0   24.79     201.3      98.8    401.15     308.2   0.65424
        0.40   25000.0   16.88     161.5      91.0    288.07     248.2   0.77402
        0.40   25000.0    8.96     118.7      81.5    163.56     180.7   1.06124
        0.40   25000.0    5.00      97.9      76.2    102.75     146.2   1.53910
        0.45   25000.0  110.00     579.9     167.1   1269.18     817.1   0.46465
        0.45   25000.0  100.00     579.9     167.1   1269.28     817.1   0.46463
        0.45   25000.0   88.13     509.5     159.1   1135.39     726.0   0.46848
        0.45   25000.0   80.21     464.4     153.5   1043.74     667.7   0.47334
        0.45   25000.0   72.29     421.6     147.8    949.35     610.7   0.48033
        0.45   25000.0   64.38     379.5     141.9    853.64     554.1   0.48946
        0.45   25000.0   56.46     338.6     135.8    756.08     498.5   0.50207
        0.45   25000.0   40.62     259.8     122.7    557.35     388.9   0.54433
        0.45   25000.0   32.71     232.4     117.7    484.55     349.5   0.60756
        0.45   25000.0   24.79     202.7     111.9    403.50     306.2   0.70222
        0.45   25000.0   16.88     169.9     104.8    310.51     256.8   0.86542
        0.45   25000.0    8.96     131.0      95.4    198.40     196.7   1.24845
        0.45   25000.0    5.00     107.5      89.0    129.94     158.7   1.80482
        0.50   25000.0  110.00     608.6     190.0   1316.66     845.3   0.49619
        0.50   25000.0  100.00     608.6     190.0   1316.63     845.3   0.49620
        0.50   25000.0   88.13     538.7     181.4   1187.88     755.8   0.50340
        0.50   25000.0   80.21     503.1     176.6   1119.01     710.5   0.51997
        0.50   25000.0   72.29     467.5     171.7   1046.75     664.7   0.53969
        0.50   25000.0   64.38     432.3     166.5    970.15     618.2   0.56370
        0.50   25000.0   56.46     396.3     161.0    889.35     570.2   0.59287
        0.50   25000.0   40.62     321.6     148.6    711.35     469.0   0.67772
        0.50   25000.0   32.71     281.8     141.2    611.87     414.4   0.74367
        0.50   25000.0   24.79     239.9     133.0    502.64     355.3   0.84131
        0.50   25000.0   16.88     195.0     123.2    380.01     289.9   1.00847
        0.50   25000.0    8.96     144.9     110.5    237.66     214.1   1.40300
        0.50   25000.0    5.00     116.5     102.4    155.32     169.3   1.98718
        0.55   25000.0  110.00     641.9     214.4   1369.04     877.5   0.56427
        0.55   25000.0  100.00     641.9     214.4   1369.12     877.6   0.56426
        0.55   25000.0   88.13     566.1     204.3   1234.59     781.6   0.57031
        0.55   25000.0   80.21     516.8     197.2   1141.79     719.7   0.57692
        0.55   25000.0   72.29     469.2     190.0   1046.02     658.8   0.58592
        0.55   25000.0   64.38     423.5     182.6    946.68     598.7   0.59804
        0.55   25000.0   56.46     378.6     174.9    844.82     539.2   0.61410
        0.55   25000.0   40.62     291.2     158.1    633.06     421.2   0.66657
        0.55   25000.0   32.71     258.6     151.2    549.66     376.2   0.73948
        0.55   25000.0   24.79     225.9     143.8    463.05     329.7   0.85505
        0.55   25000.0   16.88     190.0     135.0    363.93     277.1   1.05599
        0.55   25000.0    8.96     148.0     123.3    245.15     214.0   1.53618
        0.55   25000.0    5.00     123.1     115.6    173.21     175.1   2.25207];
end


% extract 100 power code
pc100 = [];
for i = 1:610
    pc = epass(i,3);
    if pc == 100
        pc100 = [pc100;epass(i,:)];
    end
end

m3 = [];
for ii = 1:47
    m = pc100(ii,1);
    if m == 0.3
        m3 = [m3;pc100(ii,:)];
    end
end

subplot(1,2,2)
plot(m3(:,6),m3(:,8))
title({'NPSS Deck','PW 127M M = 0.3'})
ylabel('BSFC [lb/hp/hr]')
xlabel('Alt [ft]')


epassVaryPower = [
    0.20    2000.0  110.00    1070.7     159.2   2640.41    1763.4   0.29875
    0.20    2000.0  100.00    1070.7     159.2   2640.41    1763.4   0.29875
    0.20    2000.0   88.13     915.2     149.5   2257.12    1528.6   0.29386
    0.20    2000.0   80.21     821.9     143.3   2014.91    1385.1   0.29255
    0.20    2000.0   72.29     738.5     137.4   1791.31    1255.0   0.29410
    0.20    2000.0   64.38     664.8     131.9   1585.74    1138.4   0.29959
    0.20    2000.0   56.46     593.3     126.2   1381.75    1023.8   0.30719
    0.20    2000.0   40.62     458.3     114.3    977.78     799.9   0.33355
    0.20    2000.0   32.71     397.8     108.3    789.39     695.9   0.36045
    0.20    2000.0   24.79     347.8     103.0    632.23     608.1   0.41557
    0.20    2000.0   16.88     292.6      96.6    455.42     509.0   0.51098
    0.20    2000.0    8.96     227.9      88.2    249.66     388.7   0.73499
    0.20    2000.0    5.00     185.4      82.0    115.54     305.8   1.03626];


Eng = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
N = 7;
Powers = linspace(1800,300,N)*1.3e3;

sfcs = alts.*0;
fb = sfcs;

for i = 1:N
    Eng.ReqPower = Powers(i);
    Eng.Mach = 0.2;%machs(i);
    Eng.Alt = 700;

    Sized = EngineModelPkg.TurbopropNonlinearSizing(Eng,0);

    sfcs(i) = Sized.BSFC_Imp;
    fb(i) = Sized.Fuel.MDot;
end




figure(2)

subplot(1,2,1)
plot(Powers,sfcs)
title({'Engine Model',"AE 2100D3"})
xlabel('Power [W]')
ylabel('BSFC [lbm/hp/hr]')
axis([0 3000e3 0.2 1.1])


subplot(1,2,2)
subplot(1,2,2)
plot(epassVaryPower(:,6),epassVaryPower(:,8))
title({'NPSS Deck','PW 127M'})
ylabel('BSFC [lb/hp/hr]')
xlabel('Power [HP]')

sgtitle('Fixed Mach = 0.2 and Altitude = 2000 ft')

pow2000 = [];
for i = 1:610
    pc = epass(i,6);
    if pc > 1900 && pc < 2100
        pow2000 = [pow2000;epass(i,:)];
    end
end

m3 = [];
for ii = 1:33
    m = pow2000(ii,1);
    if m == 0.3
        m3 = [m3;pow2000(ii,:)];
    end
end


figure(3)

Eng = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
alts = UnitConversionPkg.ConvLength(1000*[0 2 5 10 15 20 25],'ft','m');
N = 7;

sfcs = alts.*0;
fb = sfcs;

for i = 1:N
    Eng.ReqPower = 2500e3;
    Eng.Mach = 0.3;%machs(i);
    Eng.Alt = alts(i);

    Sized = EngineModelPkg.TurbopropNonlinearSizing(Eng,0);

    sfcs(i) = Sized.BSFC_Imp;
    fb(i) = Sized.Fuel.MDot;
end

subplot(1,2,1)
plot(alts,sfcs)
title({'Engine Model',"AE 2100D3, P = 2500 kW"})
xlabel('Altitude [m]')
ylabel('BSFC [lbm/hp/hr]')
%axis([0 8000 0.2 1.1])


subplot(1,2,2)
plot(m3(:,2),m3(:,8))
title({'NPSS Deck','PW 127M, P = 2000 hp'})
ylabel('BSFC [lb/hp/hr]')
xlabel('Altitude [ft]')

sgtitle('Fixed Mach = 0.3 and Power')


alt2000 = [];
for ii = 1:33
    alt = pow2000(ii,2);
    if alt == 2000
        alt2000 = [alt2000;pow2000(ii,:)];
    end
end

figure(4)

Eng = EngineModelPkg.EngineSpecsPkg.AE2100_D3;
machs = linspace(0.05,0.4,7);


sfcs = machs.*0;
fb = sfcs;

for i = 1:N
    Eng.ReqPower = 2500e3;
    Eng.Mach = machs(i);
    Eng.Alt = UnitConversionPkg.ConvLength(2000,'ft','m');

    Sized = EngineModelPkg.TurbopropNonlinearSizing(Eng,0);

    sfcs(i) = Sized.BSFC_Imp;
    fb(i) = Sized.Fuel.MDot;
end


subplot(1,2,1)
plot(machs,sfcs)
title({'Engine Model',"AE 2100D3, P = 2500 kW"})
xlabel('Mach Number')
ylabel('BSFC [lbm/hp/hr]')
axis([0 0.4 0.15 0.5])


subplot(1,2,2)
plot(alt2000(:,1),alt2000(:,8))
title({'NPSS Deck','PW 127M, P = 2000 hp'})
ylabel('BSFC [lb/hp/hr]')
xlabel('Mach Number')

sgtitle('Fixed Altitude = 2000 ft and Power')


%%
clc; clear; close all;
load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

IO = {["Power_SLS_Eq"],["DryWeight"]};

target = linspace(0,4000);

for i = 1:length(target)
    [weights(i)] = RegressionPkg.NLGPR(TurbopropEngines,IO,target(i));
end

plot(target,weights)

%% trade study L/D and propeller efficiency
clear; clc; close all;
N = 15;
LD = linspace(12,20,N);
eff = linspace(0.7,0.9,N);

AC = AircraftSpecsPkg.LM100J_Conventional;
Wfuel = zeros(N,N);
yr = zeros(N,N);
OEWrat = zeros(N,N);

for ii = 1:N
    for jj = 1:N
        fprintf('Iteration ii = %d, jj = %d',ii,jj)
        AC.Specs.Aero.L_D.Crs = LD(ii);
        AC.Specs.Aero.L_D.Clb = AC.Specs.Aero.L_D.Crs - 2;
        AC.Specs.Power.Eta.Propeller = eff(jj);
        SizedAC = Main(AC,@MissionProfilesPkg.LM100J);
        Wfuel(ii,jj) = SizedAC.Mission.History.SI.Weight.Fburn(end);
        yr(ii,jj) = SizedAC.Mission.History.SI.Weight.CurWeight(1);
        OEWrat(ii,jj) = SizedAC.Specs.Weight.OEW;
    end
end

%%
clc;
clear; close all;
load('LM_Trade_Study.mat')
OEWrat = UnitConversionPkg.ConvMass(OEW,'kg','lbm');
MTOW = UnitConversionPkg.ConvMass(MTOW,'kg','lbm');
Wfuel = UnitConversionPkg.ConvMass(Wfuel,'kg','lbm');

OEWrat =    abs(OEWrat - 80350)./80350*100;
MTOW =   abs(MTOW-164e3)./164e3*100;
Wfuel =  abs(Wfuel-38000)./38000*100;

[X,Y] = meshgrid(eff,LD);

figure(1)
surf(X,Y,MTOW,'FaceColor',[1 0 0],'FaceAlpha',0.2,'Linestyle','none')
hold on
surf(X,Y,OEWrat,'FaceColor',[0 1 0],'FaceAlpha',0.2,'Linestyle','none')
surf(X,Y,Wfuel,'FaceColor',[0 0 1],'FaceAlpha',0.2,'Linestyle','none')
xlabel('Propeller Efficiency')
ylabel('L/D at Cruise')
zlabel('% Error (absolute value)')
view(-115,23)
legend('MTOW','OEW','Fuel Burn')

figure(2)
subplot(1,3,1)
contour(eff,LD,Wfuel)
title('Fuel Burn')
xlabel('\eta_{propeller}')
ylabel('L/D')
colorbar

subplot(1,3,2)
contour(eff,LD,MTOW)
title('MTOW')
xlabel('\eta_{propeller}')
ylabel('L/D')
colorbar

subplot(1,3,3)
contour(eff,LD,OEWrat)
title('OEW')
xlabel('\eta_{propeller}')
ylabel('L/D')
colorbar

err = MTOW+OEWrat+Wfuel;

ii = 5;
jj = 8;

err(ii,jj)

Opteff = eff(jj)
OptLD = LD(ii)


%% Show linear imnformed gpr
clear; clc; close all;
load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

[~,OEWrat] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","OEW"]);
OEWrat = cell2mat(OEWrat(:,2));
[~,yr] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","MTOW"]);
yr = cell2mat(yr(:,2));

c = [];
for ii = 1:length(yr)
    if isnan(yr(ii)) || isnan(OEWrat(ii))
        c = [c,ii];
    end
end

OEWrat(c) = [];
yr(c) = [];


scatter(yr,OEWrat)

MTOWReg = linspace(-20000*5,18e4,300)';
P = polyfit(yr,OEWrat,1);
OEWLinear = polyval(P,MTOWReg);

hold on
plot(MTOWReg,OEWLinear)


[OEWNL,~] = RegressionPkg.NLGPR(TurbopropAC,{["Specs","Weight","MTOW"],["Specs","Weight","OEW"]},MTOWReg);

plot(MTOWReg,OEWNL)

[OEWCombo,~] = RegressionPkg.NLGPR(TurbopropAC,{["Specs","Weight","MTOW"],["Specs","Weight","OEW"]},MTOWReg,1,polyval(P,MTOWReg));

plot(MTOWReg,OEWCombo)
legend('Raw Data','Linear Fit','GP Average Prior','GP Linear Prior','location','best')
grid on
xlabel('MTOW [kg]')
ylabel('OEW [kg]')
title('Turboprop OEW Predictions')
%plot(MTOWReg,(OEWNL+OEWCombo)./2)

%% Test OEW_MTOW vs year for turboprops
clear; clc; close all;
load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

figure(1)
hold on

[~,OEWrat] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","OEW_MTOW"]);
OEWrat = cell2mat(OEWrat(:,2));
[~,yr] = RegressionPkg.SearchDB(TurbopropAC,["Specs","TLAR","EIS"]);
yr = cell2mat(yr(:,2));
c = [];
for ii = 1:length(yr)
    if isnan(yr(ii)) || isnan(OEWrat(ii))
        c = [c,ii];
    end
end
OEWrat(c) = [];
yr(c) = [];
subplot(2,2,1)
scatter(yr,OEWrat)
axis([0.99*min(yr) 1.01*max(yr) 0.9*min(OEWrat) 1.1*max(OEWrat)])
xlabel('EIS [year]')
ylabel('OEW / MTOW')
grid on

[~,OEWrat] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","OEW_MTOW"]);
OEWrat = cell2mat(OEWrat(:,2));
[~,mtow] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","MTOW"]);
mtow = cell2mat(mtow(:,2));

c = [];
for ii = 1:length(mtow)
    if isnan(mtow(ii)) || isnan(OEWrat(ii))
        c = [c,ii];
    end
end

OEWrat(c) = [];
mtow(c) = [];
subplot(2,2,2)
scatter(mtow,OEWrat)
axis([0.1*min(mtow) 1.1*max(mtow) 0.9*min(OEWrat) 1.1*max(OEWrat)])
xlabel('MTOW [kg]')
ylabel('OEW / MTOW')
grid on

[~,OEWrat] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","OEW_MTOW"]);
OEWrat = cell2mat(OEWrat(:,2));
[~,rg] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Performance","Range"]);
rg = cell2mat(rg(:,2));

c = [];
for ii = 1:length(rg)
    if isnan(rg(ii)) || isnan(OEWrat(ii))
        c = [c,ii];
    end
end

OEWrat(c) = [];
rg(c) = [];
subplot(2,2,3)
scatter(rg,OEWrat)
axis([0.7*min(rg) 1.1*max(rg) 0.9*min(OEWrat) 1.1*max(OEWrat)])
xlabel('Design Range [km]')
ylabel('OEW / MTOW')
grid on


[~,OEWrat] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Weight","OEW_MTOW"]);
OEWrat = cell2mat(OEWrat(:,2));
[~,pow] = RegressionPkg.SearchDB(TurbopropAC,["Specs","Power","SLS"]);
pow = cell2mat(pow(:,2));

c = [];
for ii = 1:length(pow)
    if isnan(pow(ii)) || isnan(OEWrat(ii))
        c = [c,ii];
    end
end

OEWrat(c) = [];
pow(c) = [];
subplot(2,2,4)
scatter(pow,OEWrat)
axis([0.7*min(pow) 1.1*max(pow) 0.9*min(OEWrat) 1.1*max(OEWrat)])
xlabel('SLS Power [W]')
ylabel('OEW / MTOW')
grid on


%%
clc; clear; close all;
load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

[~,y] = RegressionPkg.SearchDB(TurbopropEngines,["DryWeight"]);
y = cell2mat(y(:,2));
[~,x] = RegressionPkg.SearchDB(TurbopropEngines,["Power_SLS"]);
x = cell2mat(x(:,2));
cind = [];
for ii = 1:length(x)
    if isnan(x(ii)) || isnan(y(ii))
        cind = [cind,ii];
    end
end
y(cind) = [];
x(cind) = [];

P = polyfit(x,y,1);

scatter(x,y)

hold on

x = linspace(0,max(x))*1.5;
y = polyval(P,x);
plot(x,y)

xlabel(PropUnitsReference.Specs.Propulsion.Engine.Power_SLS)
ylabel(PropUnitsReference.Specs.Propulsion.Engine.DryWeight)


%% Parallel Testing for turboprops
clear; clc; close all;

Specs = EngineModelPkg.EngineSpecsPkg.AE2100_D3;

Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs);

N = 100;

Powers = linspace(0,3.3e6,N);
BSFC = zeros(1,N);
Fuel = zeros(1,N);
Thrust = zeros(1,N);

for ii = 1:N

    Eng = EngineModelPkg.TurbopropNonlinearSizing(Specs,Powers(ii));
    BSFC(ii) = Eng.BSFC_Imp;
    Fuel(ii) = Eng.Fuel.MDot;
    Thrust(ii) = Eng.JetThrust;
end

figure(1)

subplot(1,3,1)
plot(Powers,BSFC)
grid on
xlabel('Electric Power [W]')
ylabel('BSFC [lbm/hp/hr]')

subplot(1,3,2)
plot(Powers,Fuel)
grid on
xlabel('Electric Power [W]')
ylabel('Fuel Flow [kg/s]')

subplot(1,3,3)
plot(Powers,Thrust)
grid on
xlabel('Electric Power [W]')
ylabel('Jet Thrust [N]')


%% testing pre spec processing

clc; clear; close all;

Aircraft.Specs.TLAR.MaxPax = 150;
Aircraft.Specs.TLAR.Class = 'Turbofan';
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150,'naut mi','m');
Aircraft.Specs.Propulsion.Arch.Type = "C";

Aircraft = PreSpecProcessing(Aircraft);

Main(Aircraft,@MissionProfilesPkg.NotionalMission02)




%% Testing turboprop spec processing

clc; clear; close all;

Aircraft.Specs.TLAR.MaxPax = 150;
Aircraft.Specs.TLAR.Class = 'Turboprop';
Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(2150,'naut mi','m');
Aircraft.Specs.Propulsion.Arch.Type = "C";


Aircraft = DataStructPkg.SpecProcessing(Aircraft);

specs = Aircraft.Specs.Propulsion.Engine;

specs.Visualize = 1;
Eng = EngineModelPkg.TurbopropNonlinearSizing(specs)


%% Testing engine model gradient calc

clc; close all; clear;


h = 1e-1;

specs = EngineModelPkg.EngineSpecsPkg.PW_1919G;
% specs.Tt4Max = specs.Tt4Max + h*1i;
% Eng = EngineModelPkg.TurbofanNonlinearSizing(specs);
% derivative = imag(Eng.TSFC_Imperial)/h;


N = 50;
Tt4s = linspace(1900,3000,N);
TSFC = zeros(1,N);
DerTSFC = zeros(1,N);

for ii = 1:N
    specs.Tt4Max = Tt4s(ii);
    Eng = EngineModelPkg.TurbofanNonlinearSizing(specs);
    TSFC(ii) = Eng.TSFC_Imperial;
    specs.Tt4Max = specs.Tt4Max + h*1i;
    Eng = EngineModelPkg.TurbofanNonlinearSizing(specs);
    DerTSFC(ii) = imag(Eng.TSFC_Imperial)/h;
end



figure(1)
subplot(1,2,1)
plot(Tt4s,TSFC)
grid on
xlabel('Tt4 [K]')
ylabel('TSFC')



subplot(1,2,2)
plot(Tt4s,DerTSFC)
grid on
xlabel('Tt4 [K]')
ylabel('Partial TSFC')


Slope = (TSFC(end) - TSFC(1)) / (Tt4s(end) - Tt4s(1))

hold on
yline(Slope)





%% PW127M testing
clear; clc; close all;
EngSpecs = EngineModelPkg.EngineSpecsPkg.PW_127M;
EngSpecs.Visualize = 1;

PW_127 = EngineModelPkg.TurbopropNonlinearSizing(EngSpecs);


BSFC_Error = (PW_127.BSFC_Imp - 0.459) /0.459 * 100;

fprintf("BSFC Error: %.3f%%  \n",BSFC_Error)



%% ERJ testing

Unsized = AircraftSpecsPkg.ERJ175LR;
Unsized.Specs.Power.Battery.ParCells = NaN;
Unsized.Specs.Power.Battery.SerCells =  NaN;
Unsized.Specs.Power.Battery.BegSOC = NaN;

Conv = Main(Unsized,@MissionProfilesPkg.ERJ_ClimbThenAccel);

Unsized.Specs.Power.LamTSPS.SLS = 0.01;
Unsized.Specs.Power.LamTSPS.Tko = 0.01;
Unsized.Specs.Power.Battery.ParCells = 100;
Unsized.Specs.Power.Battery.SerCells =  62;
Unsized.Specs.Power.Battery.BegSOC = 100;

Hybrid = Main(Unsized,@MissionProfilesPkg.ERJ_ClimbThenAccel);


%% Hybrid TSFC
clc; clear; close all;

%EngSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngSpecs = EngineModelPkg.EngineSpecsPkg.PW_1919G;



Conv = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs)


N = 100;
Powers = linspace(8e2,8e5,N);

for ii = 1:N

    Hybrid = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs,Powers(ii));

    TSFC(ii) = Hybrid.TSFC_Imperial;
    TSFC_AdjLam(ii) = Hybrid.TSFC_Adj_Lam;
    TSFC_AdjThrust(ii) = Hybrid.TSFC_Adj_Thrust;

end

plot(Powers,TSFC)
hold on
plot(Powers,TSFC_AdjLam)
plot(Powers,TSFC_AdjThrust)

grid on
legend("Unaltered","Normalized by \lambda","Normalized by Thrust","location","northwest")
title("Pratt & Whitney 1919 Geared Fan")
xlabel("\lambda")
ylabel("TSFC [lbm/hr/lbf]")

%% Hybrid Thrust
clc; clear; close all;

%EngSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngSpecs = EngineModelPkg.EngineSpecsPkg.PW_1919G;



Conv = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs)


N = 100;
Powers = linspace(8e2,8e5,N);

for ii = 1:N

    Hybrid = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs,Powers(ii));

    Core(ii) = Hybrid.Thrust.Core;
    Fan(ii) = Hybrid.Thrust.Bypass;
    Net(ii) = Hybrid.Thrust.Net;
    Ram(ii) = Hybrid.Thrust.RamDrag;

end

plot(Powers,Core)
hold on
plot(Powers,Fan)
plot(Powers,Net)
plot(Powers,Ram)

grid on
legend("Core","Bypass","Net","Ram Drag")
title("Pratt & Whitney 1919 Geared Fan")
xlabel("Elec Power [W]")
ylabel("Thrust, N")

%% CF34 Testing
clc; clear; close all;

EngSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngSpecs.Visualize = 1;
Cruise = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs)


EngSpecs.Mach = 0.05;
EngSpecs.Alt = 0;
EngSpecs.DesignThrust = 61320;
Takeoff = EngineModelPkg.TurbofanNonlinearSizing(EngSpecs)

%% ATR 42

Un = AircraftSpecsPkg.ATR42;

Un.Settings.Plotting = 1;
Un.Settings.VisualizeAircraft = 1;
Un.Specs.TLAR.MaxPax = 60;
Un.Specs.Propulsion.Arch.Type = "PHE";
Un.Specs.Power.LamTS.SLS = 0.1;
Un.Specs.Power.LamTS.Tko = 0.1;

Sized = Main(Un)











%% Jenkinson regression comparison

clear; clc; close all; clearvars;

load("+DatabasePkg/IDEAS_DB.mat")
[TrainingStructure,~] = RegressionPkg.SearchDB(TurbofanAC,["Settings","DataTypeValidation"],"Training");

[ValidationStructure,~] = RegressionPkg.SearchDB(TurbofanAC,["Settings","DataTypeValidation"],"Validation");

[~,MTOWS] = RegressionPkg.SearchDB(ValidationStructure,["Specs","Weight","MTOW"]);
MTOWS = cell2mat(MTOWS(:,2));

[~,Ranges] = RegressionPkg.SearchDB(ValidationStructure,["Specs","Performance","Range"]);
Ranges = cell2mat(Ranges(:,2));

[~,NumberEngines] = RegressionPkg.SearchDB(ValidationStructure,["Specs","Propulsion","NumEngines"]);
NumberEngines = cell2mat(NumberEngines(:,2));
IO_Strings = {["Specs","Propulsion","NumEngines"],["Specs","Performance","Range"],["Specs","Weight","MTOW"],["Specs","Weight","OEW"]};

% IO_Strings = {["Specs","Performance","Range"],["Specs","Weight","MTOW"],["Specs","Weight","OEW"]};
[RegResponse,Variance] = RegressionPkg.NLGPR(TrainingStructure,IO_Strings,[NumberEngines,Ranges,MTOWS]);

[~,OEWS] = RegressionPkg.SearchDB(ValidationStructure,["Specs","Weight","OEW"])
OEWS = cell2mat(OEWS(:,2));



Error = (RegResponse - OEWS) ./ OEWS;

%
[j4,~] = RegressionPkg.SearchDB(ValidationStructure,["Specs", "Propulsion", "NumEngines"],4);
[j3,~] = RegressionPkg.SearchDB(ValidationStructure,["Specs", "Propulsion", "NumEngines"],3);
[j2,~] = RegressionPkg.SearchDB(ValidationStructure,["Specs", "Propulsion", "NumEngines"],2);


[~,j4OEWS] = RegressionPkg.SearchDB(j4,["Specs","Weight","OEW"]);
j4OEWS = cell2mat(j4OEWS(:,2));

[~,j3OEWS] = RegressionPkg.SearchDB(j3,["Specs","Weight","OEW"]);
j3OEWS = cell2mat(j3OEWS(:,2));

[~,j2OEWS] = RegressionPkg.SearchDB(j2,["Specs","Weight","OEW"]);
j2OEWS = cell2mat(j2OEWS(:,2));

[~,j4MTOWS] = RegressionPkg.SearchDB(j4,["Specs","Weight","MTOW"]);
j4MTOWS = cell2mat(j4MTOWS(:,2));

[~,j3MTOWS] = RegressionPkg.SearchDB(j3,["Specs","Weight","MTOW"]);
j3MTOWS = cell2mat(j3MTOWS(:,2));

[~,j2MTOWS] = RegressionPkg.SearchDB(j2,["Specs","Weight","MTOW"]);
j2MTOWS = cell2mat(j2MTOWS(:,2));

j4 = 0.47.*(j4MTOWS);
j3 = 0.47.*(j3MTOWS);
j2 = 0.55.*(j2MTOWS);

j4error = (0.47.*(j4MTOWS)-j4OEWS)./j4OEWS;
j3error = (0.47.*(j3MTOWS)-j3OEWS)./j3OEWS;
j2error = (0.55.*(j2MTOWS)-j2OEWS)./j2OEWS;

jerror = [j4error;j3error;j2error];
jerror = jerror(~isnan(jerror))
jL2 = sqrt(sum(jerror.^2))
Error2 = Error(~isnan(Error));
RL2 = sqrt(sum(Error2.^2))



%


figure(1)
subplot(1,2,1)
scatter(OEWS,RegResponse,'b','LineWidth',2)
title('Predicted vs Actual OEW')
xlabel('Actual Operating Empty Weight (kg)')
ylabel ('Predicted Operating Empty Weight (kg)')
grid on
hold on
scatter([j4OEWS;j3OEWS;j2OEWS],[j4;j3;j2],'r','LineWidth',2)
plot([0 2e5],[0,2e5],'g--')
legend('FAST','Jenkinson, 2003','Location','best','FontName','Times New Roman')
set(gca,'FontName','Times New Roman')


subplot(1,2,2)
% figure(2)
scatter(OEWS,Error.*100,'b','LineWidth', 2)
hold on
scatter(j4OEWS,j4error.*100,'r','LineWidth', 2)
scatter(j3OEWS,j3error.*100,'r','LineWidth', 2)
scatter(j2OEWS,j2error.*100,'r','LineWidth', 2)
legend('FAST','Jenkinson, 2003','Location','best','FontName','Times New Roman')
title('Residual vs Actual OEW'); 
xlabel('Operating Empty Weight (kg)','FontName','Times New Roman');
ylabel ('Error (%)','FontName','Times New Roman')
grid on
set(gca,'FontName','Times New Roman')






MTOW_Reg = linspace(0, 4.5e5, 20)';
[RegResponse,Variance] = RegressionPkg.NLGPR(TurbofanAC,{["Specs","Weight","MTOW"],["Specs","Weight","OEW"]},MTOW_Reg);

p = polyfit(MTOW_Reg, RegResponse, 2);
f1 = polyval(p, MTOW_Reg);

pj2 = polyfit(j2MTOWS, j2, 1);
f_j2 = polyval(pj2, j2MTOWS);

pj3 = polyfit(j3MTOWS, j3, 1);
f_j3 = polyval(pj3, j3MTOWS);

pj4 = polyfit(j4MTOWS, j4, 1);
f_j4 = polyval(pj4, j4MTOWS);

figure(2)
% scatter(MTOW_Reg, RegResponse,'LineWidth', 2)
%title('MTOW Regression (Constraints: Range, MTOW)');
ylabel('Operating Empty Weight (kg)','FontName','Times New Roman');
xlabel ('Maximum Takeoff Weight (kg)','FontName','Times New Roman');
hold on
plot(MTOW_Reg,f1,'LineWidth', 2)

% scatter(j2MTOWS,j2,'LineWidth', 2)
plot(j2MTOWS,f_j2,'LineWidth', 2)
% scatter(j3MTOWS,j3,'LineWidth', 2)
plot(j3MTOWS,f_j3,'LineWidth', 2)
% scatter(j4MTOWS,j4,'LineWidth', 2)
plot(j4MTOWS,f_j4,'LineWidth', 2)
grid on

legend('FAST Regression', 'Jenkinson 2 Engine','','Jenkinson 3 and 4 Engine','Location','southeast','FontName','Times New Roman')
set(gca,'FontName','Times New Roman')
hold off




%%
clear; clc; close all;
load("+DatabasePkg/IDEAS_DB.mat")

N = 50;

MTOW = linspace(0,4e5,N);
Range = linspace(0,14450000,N);
NumEngines = [2,3,4];


[Mgrid,Rgrid,Egrid] = meshgrid(MTOW,Range,NumEngines);

Mgrid = reshape(Mgrid,[N^2*3,1]);
Rgrid = reshape(Rgrid,[N^2*3,1]);
Egrid = reshape(Egrid,[N^2*3,1]);

Target = [Egrid,Rgrid,Mgrid];

IO_Strings = {["Specs","Propulsion","NumEngines"],["Specs","Performance","Range"],["Specs","Weight","MTOW"],["Specs","Weight","OEW"]};


[OEW,Variance] = RegressionPkg.NLGPR(TurbofanAC,IO_Strings,Target);

Terms = [
    0 0 0 0
    0 0 0 0
    0 1 0 0
    0 0 1 0
    0 1 0 0
    0 0 1 0
    0 1 1 0
    0 0 0 0
    0 2 0 0
    0 0 2 0
    0 3 0 0
    0 0 3 0
    ];

mdl = fitlm(Target,OEW,Terms)

plot(mdl)

figure(2)
subplot(2,2,1)
scatter(Mgrid,OEW)

subplot(2,2,2)
scatter(Rgrid,OEW)

subplot(2,2,3)
scatter(Egrid,OEW)


OEWpred = predict(mdl,Target);

figure(3)
scatter(OEW,OEWpred)

figure(4)

scatter3(Mgrid(1:2500)./1000,Rgrid(1:2500)./1000,OEW(1:2500)./1000,'r')
hold on

scatter3(Mgrid(2501:5000)./1000,Rgrid(2501:5000)./1000,OEW(2501:5000)./1000,'b')


scatter3(Mgrid(5001:end)./1000,Rgrid(5001:end)./1000,OEW(5001:end)./1000,'g')

legend('2 Engines','3 Engines','4 Engines','location','best','FontName','Times New Roman')

xlabel('MTOW [t]','FontName','Times New Roman')
ylabel('Range [km]','FontName','Times New Roman')
zlabel('OEW [t]','FontName','Times New Roman')
set(gca,'FontName','Times New Roman')




%% 3007 Testing
clear; clc; close all;

specs = EngineModelPkg.EngineSpecsPkg.AE3007A;
specs.Visualize = true;

Sized = EngineModelPkg.TurbofanNonlinearSizing(specs)



%% PT6A testing
clear; clc; close all;

specs = EngineModelPkg.EngineSpecsPkg.PT6A_114A;
specs.Visualize = false;

Sized = EngineModelPkg.TurbopropNonlinearSizing(specs)

% tt4 = linspace(1000,2000);
%
%
% for ii = 1:100
%     specs.Tt4Max = tt4(ii);
% Sized = EngineModelPkg.TurbopropNonlinearSizing(specs);
% bsfc(ii) = Sized.BSFC_Imp;
% end
%
% plot(tt4,bsfc)


% 
% load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
% Data = TurbopropEngines;
% 
% target = specs.ReqPower;
% 
% 
% [LengthScale,~] = RegressionPkg.NLGPR(Data,{["Power_SLS"],["DryWeight"]},target)


%% PW1919G
clear; clc; close all;

EngineSpecs = EngineModelPkg.EngineSpecsPkg.PW_1919G;
EngineSpecs.Visualize = true;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;

tic
OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle3(SizedEngine,OffParams);
toc

TSFC_Error = (OffDesign.TSFC_Imperial - SizedEngine.TSFC_Imperial)/SizedEngine.TSFC_Imperial

On = SizedEngine;
Off = OffDesign;



%% LEAP
clear; clc; close all;

EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;

tic
OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle3(SizedEngine,OffParams);
toc

TSFC_Error = (OffDesign.TSFC_Imperial - SizedEngine.TSFC_Imperial)/SizedEngine.TSFC_Imperial

On = SizedEngine;
Off = OffDesign;

%% CF34
clear; clc; close all;

EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
% EngineSpecs.Visualize = true;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;

tic
OffDesign = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle3(SizedEngine,OffParams);
toc

TSFC_Error = (OffDesign.TSFC_Imperial - SizedEngine.TSFC_Imperial)/SizedEngine.TSFC_Imperial


On = SizedEngine;
Off = OffDesign;

%% LEAP Trade Study
clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

tic
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
toc

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;


N = 10;
PCGrid = linspace(0.5,1,N);
AltGrid = linspace(0,10000,N);
MGrid = linspace(0.05,0.8,N);

for ii = 1:length(PCGrid)
OffParams.PC = 1;%PCGrid(ii);
OffParams.FlightCon.Alt = 0;
OffParams.FlightCon.Mach = MGrid(ii);
Off = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(SizedEngine,OffParams);
TSFC(ii) = Off.TSFC_Imperial;
Thrust(ii) = Off.Thrust.Net;
Fuel(ii) = Off.Fuel.MDot;
BSFC(ii) = Off.BSFC;
Tt21(ii) = NaN;%Off.States.Station2.Tt;
air(ii) = Off.MDotAir; 
power(ii) = NaN;%Off.FanPower;
picomp(ii) = Off.PiComp;

end

PCGrid = MGrid;

figure(1)
subplot(2,2,1)
plot(PCGrid,Thrust)
title('Thrust')

subplot(2,2,2)
plot(PCGrid,Fuel)
title('Fuel')


subplot(2,2,3)
plot(PCGrid,TSFC)
title('TSFC')

subplot(2,2,4)
plot(PCGrid,BSFC)
title('BSFC')

figure(2)
subplot(2,2,1)
plot(PCGrid,Tt21)
title('TtPostFan')

subplot(2,2,2)
plot(PCGrid,air)
title('Airflow')

subplot(2,2,3)
plot(PCGrid,power)
title('Fan Power')

for ii = 1:length(PCGrid)

   calcTt2(ii) = EngineModelPkg.SpecHeatPkg.NewtonRaphsonTt1(288,power(ii)/air(ii));
end




subplot(2,2,4)
plot(PCGrid,calcTt2)
title('Tt Post Fan (Calculated)')

figure(3)
subplot(2,2,1)
plot(PCGrid,power./air)
title('Power/kg Air')

subplot(2,2,2)
plot(PCGrid,picomp)
title('Compressor Pressure Ratio')

subplot(2,2,3)
plot(Thrust,Fuel)
title('Fuel Vs Thrust')

subplot(2,2,4)
plot(Thrust,TSFC)
title('TSFC Vs Thrust')


TSFC_Error = (Off.TSFC_Imperial - SizedEngine.TSFC_Imperial)/SizedEngine.TSFC_Imperial;
On = SizedEngine;


TSFC_Error


%% PW1919G
clear; clc; close all;

EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;


EngineModelPkg.TurbofanOffDesignDriver(SizedEngine,OffParams)





%% Massive Off Design Testing Script

clear; clc; close all;

EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

% Testing TSFC as a function of Mach Number
OffParams.FlightCon.Mach = [];
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = 1;

M = linspace(0.05,0.8);
for ii = 1:length(M)
    OffParams.FlightCon.Mach = M(ii);
    temp = EngineModelPkg.TurbofanOffDesignDriver(SizedEngine,OffParams);
    TSFC(ii) = temp.TSFC;

end

figure(1)

subplot(2,2,1)
plot(M,TSFC)
xlabel('Mach')
ylabel('TSFC')


% TSFC as a function of Altitude
OffParams.FlightCon.Mach = 0.05;
OffParams.FlightCon.Alt = [];
OffParams.PC = 1;

alt = linspace(0.05,0.8);
for ii = 1:length(alt)
    OffParams.FlightCon.Alt = alt(ii);
    temp = EngineModelPkg.TurbofanOffDesignDriver(SizedEngine,OffParams);
    TSFC(ii) = temp.TSFC;

end

figure(1)

subplot(2,2,2)
plot(alt,TSFC)
xlabel('Alt')
ylabel('TSFC')



% as a function of power code

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.PC = [];

PC = linspace(0.6,1.1);
for ii = 1:length(PC)
    OffParams.PC = PC(ii);
    temp = EngineModelPkg.TurbofanOffDesignDriver(SizedEngine,OffParams);
    TSFC(ii) = temp.TSFC;

end

figure(1)

subplot(2,2,3)
plot(PC,TSFC)
xlabel('Power Code')
ylabel('TSFC')



%% Testing offDesignDriver2


clear; clc; close all;
EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

Off = EngineModelPkg.TurbofanOffDesignDriver2(SizedEngine)

plot(smoothdata(Off.Thrusts),Off.BSFCs)

interp1(Off.Thrusts,Off.BSFCs,0.7)

%% Test maximum thrust trends

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;

tic
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
toc

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;


N = 10;
%PCGrid = linspace(0.5,1,N);
Alts = linspace(0,10000,N);
Ms = linspace(0.05,0.8,N);

[AltGrid,MGrid] = meshgrid(Alts,Ms);

for jj = 1:N
for ii = 1:N
OffParams.PC = 1;%PCGrid(ii);
OffParams.FlightCon.Alt = AltGrid(ii,jj);
OffParams.FlightCon.Mach = MGrid(ii,jj);
Off = EngineModelPkg.CycleModelPkg.TurbofanOffDesignCycle2(SizedEngine,OffParams);
TSFC(ii,jj) = Off.TSFC_Imperial;
Thrust(ii,jj) = Off.Thrust.Net;
Fuel(ii,jj) = Off.Fuel.MDot;
BSFC(ii,jj) = Off.BSFC;
Tt21(ii,jj) = NaN;%Off.States.Station2.Tt;
air(ii,jj) = Off.MDotAir; 
power(ii,jj) = NaN;%Off.FanPower;
picomp(ii,jj) = Off.PiComp;
end
end


figure(1)

contourf(AltGrid,MGrid,Thrust)
xlabel('Alt')
ylabel('Mach')
title('Thrust')

%% Testing OffDesign

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;


SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
True = SizedEngine.Fuel.MDot

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.Thrust = 1.0676e+05;%"max";

tic
OffFuel = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams)
toc


%% Testing OffDesign vs thrust

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngineSpecs.Sizing = 1;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
SizedEngine.Specs.Sizing = 0;

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.Thrust = "max";

% Grid = linspace(0,10000);
% Grid = linspace(0.05,0.8);
Grid = linspace(2e4,12e4);

setmach = 0.05;

for ii = 1:length(Grid)
    OffParams.FlightCon.Mach = setmach;%EngineSpecs.Mach;
%     OffParams.FlightCon.Mach = Grid(ii);
    OffParams.FlightCon.Alt = EngineSpecs.Alt;
%     OffParams.FlightCon.Alt = Grid(ii);
%     OffParams.Thrust = "max";
    OffParams.Thrust = Grid(ii);
    Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams);
    fuel(ii) = Off.Fuel;
    tsfc(ii) = Off.TSFC_Imperial;
    thrust(ii) = Off.Thrust;
end


figure(1)

subplot(1,3,1)
plot(Grid,fuel)
ylabel('Fuel [kg/s]')
hold on
xline(EngineSpecs.DesignThrust,'r--')


subplot(1,3,2)
plot(Grid,thrust./1e3)
ylabel('Thrust [kN]')
hold on
xline(EngineSpecs.DesignThrust,'r--')


subplot(1,3,3)
plot(Grid,tsfc)
ylabel('TSFC [lb/lbf/hr]')
hold on
xline(EngineSpecs.DesignThrust,'r--')

sgtitle({'SLS Condtions','Producing Thrust at Various Levels'})

%% Testing OffDesign vs altitude

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngineSpecs.Sizing = 1;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
SizedEngine.Specs.Sizing = 0;

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.Thrust = "max";

Grid = linspace(0,10000);
% Grid = linspace(0.05,0.8);
% Grid = linspace(2e4,12e4);

setmach = 0.75;

for ii = 1:length(Grid)
    OffParams.FlightCon.Mach = setmach;%EngineSpecs.Mach;
%     OffParams.FlightCon.Mach = Grid(ii);
%     OffParams.FlightCon.Alt = EngineSpecs.Alt;
    OffParams.FlightCon.Alt = Grid(ii);
    OffParams.Thrust = "max";
%     OffParams.Thrust = Grid(ii);
    Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams);
    fuel(ii) = Off.Fuel;
    tsfc(ii) = Off.TSFC_Imperial;
    thrust(ii) = Off.Thrust;
end


figure(1)

subplot(1,3,1)
plot(Grid,fuel)
ylabel('Fuel [kg/s]')


subplot(1,3,2)
plot(Grid,thrust./1e3)
ylabel('Thrust [kN]')


subplot(1,3,3)
plot(Grid,tsfc)
ylabel('TSFC [lb/lbf/hr]')

sgtitle({'Mach 0.75','Params vs Altitude'})


%%

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;


N = 20;
altgrid = linspace(0,1e4);
thrustgrid = linspace(1e5,1e5/5);


for ii = 1:length(altgrid)

    EngineSpecs.Alt = altgrid(ii);
    EngineSpecs.DesignThrust = thrustgrid(ii);

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
TSFCs(ii) = SizedEngine.TSFC_Imperial;

end

plot(altgrid,TSFCs)

%% Conventional

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

EngineSpecs.Sizing = 1;
SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);


SizedEngine.Specs.Sizing = 0;
OffParams.FlightCon.Mach = 0.5;
OffParams.FlightCon.Alt = 5000;
OffParams.Thrust = "maxthrust";
% OffParams.Thrust = 1e5;




Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams);




%%





%{
1) create a range of "power codes" eg [0.5:1.1]

2) outputs a thrust and a BSFC for the fan shaft

3) scale thrust and BSFC by thrust and BSFC at PowerCode = 1 (design
condition)

4) guess a maximum available thrust by scaling SLS thrust to an altitude

5) then we size an engine for the offdesign condition (Mach and Altitude)
but at that maximum thrust

6) take our desired thrust, use map from step 2 to scale our TSFC by the
BSFC scale 


7) for hybrid:
 

whole point: avoid usage of compressor maps and turbine maps because no one
will give us any and we dont want to use higher fidelity tools
%}

%% Hybrid

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

EngineSpecs.Sizing = 1;
SizedEngine = ...
    EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs,2e6);


SizedEngine.Specs.Sizing = 0;
OffParams.FlightCon.Mach = 0.05;
OffParams.FlightCon.Alt = 0;
% OffParams.Thrust = "maxthrust";
% OffParams.Thrust = 1e5;
OffParams.Thrust = EngineSpecs.DesignThrust;





tic
Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams,2e6);
toc

OnTSFC = SizedEngine.TSFC_Imperial
OffTSFC = Off.TSFC_Imperial

OnFuel = SizedEngine.Fuel.MDot
OffFuel = Off.Fuel



%% Hybrid: Range of ELectric Loads

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;

EngineSpecs.Sizing = 1;

% ON DESIGN
SizedEngine = ...
    EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs,-2e6);
% designed to be supplemented by 2 MW


SizedEngine.Specs.Sizing = 0;
OffParams.FlightCon.Mach = 0.05;
OffParams.FlightCon.Alt = 0;
% OffParams.Thrust = "maxthrust";
% OffParams.Thrust = 1e5;
OffParams.Thrust = EngineSpecs.DesignThrust;

%  range of electric loads supplied at off design
ElectricLoads = linspace(-5e6,11e6,200);

tic
for ii = 1:length(ElectricLoads)

% tic
Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams,ElectricLoads(ii));
% toc

% OnTSFC = SizedEngine.TSFC_Imperial
% OffTSFC = Off.TSFC_Imperial

% OnFuel = SizedEngine.Fuel.MDot
OffFuel(ii) = Off.Fuel;

end
toc


plot(ElectricLoads./1e6,OffFuel)
xlabel('Electric Load [MW]')
ylabel('Fuel Consumption [kg/s]')

hold on 
xline(-2,'r--')


%% Testing Missions for the ERJ against off design
clear; clc; close all;

Sized_A320Posterior = Main(AircraftSpecsPkg.A320Neo,@MissionProfilesPkg.A320);

save('EngineOffDesignValidationPOSTERIORtoModel.mat','Sized_A320Posterior')
% MTOW should be 85,000 lbf

% but our previous code sizes to about 65,000 as well. so the issue is
% likely outside of the engine model



%%
clc; clear; close all;
load('EngineOffDesignValidationPOSTERIORtoModel.mat')
load('EngineOffDesignValidationPRIORtoModel.mat')

OnW = Sized_A320.Specs.Weight;
OffW = Sized_A320Posterior.Specs.Weight;

OnW = [OnW.MTOW,OnW.Fuel,OnW.OEW];
OffW = [OffW.MTOW,OffW.Fuel,OffW.OEW];

diff = (OffW - OnW)./OnW.*100

ErrTab = table(["MTOW";"Fuel";"OEW"],OnW',OffW',diff');
ErrTab.Properties.VariableNames(1) = "Weight [kg]";

ErrTab.Properties.VariableNames(2) = "ON Design";
ErrTab.Properties.VariableNames(3) = "OFF Design";
ErrTab.Properties.VariableNames(4) = "% Difference";

ErrTab

%% Compare A320 using off design to literature
clear; clc; close all;

Sized_A320Posterior = Main(AircraftSpecsPkg.A320Neo,@MissionProfilesPkg.A320);

W = Sized_A320Posterior.Specs.Weight

%% A320 Data higher ld
clear; clc; close all;

Off.     WairfCF = 1;
Off.        MTOW = 7.8839e+04;
Off.          EG = 0;
Off.          EM = 0;
Off.        Fuel = 1.9504e+04;
Off.        Batt = 0;
Off.     Payload = 1.5309e+04;
Off.        Crew = 586.5517;
Off.     Engines = 5.3180e+03;
Off.         OEW = 4.3439e+04;
Off.    Airframe = 3.8096e+04;


 On.    WairfCF =  1;
 On.       MTOW =  7.2564e+04;
 On.         EG =  0;
 On.         EM =  0;
 On.       Fuel =  1.6127e+04;
 On.       Batt =  0;
 On.    Payload =  1.5309e+04;
 On.       Crew =  586.5517;
 On.    Engines =  5.0292e+03;
 On.        OEW =  4.0541e+04;
 On.   Airframe =  3.5495e+04;


 Old.    WairfCF = 1;
 Old.       MTOW = 7.6019e+04;
 Old.         EG = 0;
 Old.         EM = 0;
 Old.       Fuel = 1.7957e+04;
 Old.       Batt = 0;
 Old.    Payload = 1.5309e+04;
 Old.       Crew = 586.5517;
 Old.    Engines = 5.1737e+03;
 Old.        OEW = 4.2166e+04;
 Old.   Airframe = 3.6975e+04;



Off = [Off.MTOW,Off.OEW,Off.Fuel,Off.Engines]';
On = [On.MTOW,On.OEW,On.Fuel,On.Engines]';
Old = [Old.MTOW,Old.OEW,Old.Fuel,Old.Engines]';
True = [79e3,79e3*0.57959,20e3,2990*2]';

err = @(val) (val - True)./True.*100;

Weight = ["MTOW","OEW","Fuel","Engines"]';

T = array2table([Weight, Off, err(Off), On, err(On), Old, err(Old), True]);

T = renamevars(T,1:8,["Weight","Off Design","OD % Error"," BADA Method","BM % Error","On Design Surrogate Model","ODSM % Error","True Value"])



%% A320 Data low LD
clear; clc; close all;

Off.     WairfCF =  1.0300;
Off.        MTOW =  8.8087e+04;
Off.          EG =  0;
Off.          EM =  0;
Off.        Fuel =  2.3919e+04;
Off.        Batt =  0;
Off.     Payload =  1.5309e+04;
Off.        Crew =  586.5517;
Off.     Engines =  5.7663e+03;
Off.         OEW =  4.8272e+04;
Off.    Airframe =  4.2478e+04;


  On.   WairfCF = 1.0300;
  On.      MTOW = 8.0157e+04;
  On.        EG = 0;
  On.        EM = 0;
  On.      Fuel = 1.9048e+04;
  On.      Batt = 0;
  On.   Payload = 1.5309e+04;
  On.      Crew = 586.5517;
  On.   Engines = 5.4245e+03;
  On.       OEW = 4.5214e+04;
  On.  Airframe = 3.9753e+04;

 Old.    WairfCF =  1.0300;
 Old.       MTOW =  8.5695e+04;
 Old.         EG =  0;
 Old.         EM =  0;
 Old.       Fuel =  2.2457e+04;
 Old.       Batt =  0;
 Old.    Payload =  1.5309e+04;
 Old.       Crew =  586.5517;
 Old.    Engines =  5.6529e+03;
 Old.        OEW =  4.7343e+04;
 Old.   Airframe =  4.1718e+04;



Off = [Off.MTOW,Off.OEW,Off.Fuel,Off.Engines]';
On = [On.MTOW,On.OEW,On.Fuel,On.Engines]';
Old = [Old.MTOW,Old.OEW,Old.Fuel,Old.Engines]';
True = [79e3,79e3*0.57959,20e3,2990*2]';

err = @(val) (val - True)./True.*100;

Weight = ["MTOW","OEW","Fuel","Engines"]';

T = array2table([Weight, Off, err(Off), On, err(On), Old, err(Old), True]);

T = renamevars(T,1:8,["Weight","Off Design","OD % Error"," BADA Method","BM % Error","On Design Surrogate Model","ODSM % Error","True Value"])




  %% Compare ERJ using off design to literature
clear; clc; close all;

Sized_ERJPosterior = Main(AircraftSpecsPkg.ERJ175LR,@MissionProfilesPkg.NotionalMission02);

W = Sized_ERJPosterior.Specs.Weight


%% ERJ Data
close all; clc; clear;

%     On. WairfCF= 1.0180;
%     On.    MTOW= 2.9295e+04;
%     On.      EG= 0;
%     On.      EM= 0;
%     On.    Fuel= 6.1594e+03;
%     On. Payload= 7410;
%     On.    Crew= 283.9080;
%     On. Engines= 2.1688e+03;
%     On.     OEW= 1.5442e+04;
%     On.Airframe= 1.3261e+04;

True.         Cargo = 0;
True.           MRW = 38950;
True.          MTOW = 38790;
True.           MLW = 34000;
True.          MZFW = 31700;
True.           OEW = 21500;
True.          Fuel = 9428;
True.      Airframe = 18644;
True.      OEW_MTOW = 0.5543;
True.     MZFW_MTOW = 0.8172;
True.    EngineFrac = 0.0736;
True.      FuelFrac = 0.2431;
True.       Payload = 8360;
True.          Batt = NaN;
True.            EM = NaN;
True.            EG = NaN;


 Off.   WairfCF = 1.0180;
 Off.      MTOW = 4.0479e+04;
 Off.        EG = 0;
 Off.        EM = 0;
 Off.      Fuel = 9.9708e+03;
 Off.      Batt = 0;
 Off.   Payload = 7410;
 Off.      Crew = 283.9080;
 Off.   Engines = 3.0348e+03;
 Off.       OEW = 2.2814e+04;
 Off.  Airframe = 1.9762e+04;


 
 Old.  WairfCF = 1.0180;
 Old.     MTOW = 3.5504e+04;
 Old.       EG = 0;
 Old.       EM = 0;
 Old.     Fuel = 8.4319e+03;
 Old.  Payload = 7410;
 Old.     Crew = 283.9080;
 Old.  Engines = 2.6562e+03;
 Old.      OEW = 1.9378e+04;
 Old. Airframe = 1.6709e+04;





On.    WairfCF = 1.0180;
On.       MTOW = 3.5962e+04;
On.         EG = 0;
On.         EM = 0;
On.       Fuel = 8.5542e+03;
On.       Batt = 0;
On.    Payload = 7410;
On.       Crew = 283.9080;
On.    Engines = 2.7196e+03;
On.        OEW = 1.9714e+04;
On.   Airframe = 1.6982e+04;

%  Table = [[Off.MTOW ; Off.OEW ; Off.Fuel ;Off.Engines] ,[On.MTOW; On.OEW; On.Fuel; On.Engines]];
%  Table = [Table,(Table(:,1) - Table(:,2))./Table(:,2).*100]

Off = [Off.MTOW,Off.OEW,Off.Fuel,Off.Engines]';
On = [On.MTOW,On.OEW,On.Fuel,On.Engines]';
Old = [Old.MTOW,Old.OEW,Old.Fuel,Old.Engines]';
True = [True.MTOW,True.OEW,True.Fuel,1428*2]';

err = @(val) (val - True)./True.*100;

Weight = ["MTOW","OEW","Fuel","Engines"]';

T = array2table([Weight, Off, err(Off), On, err(On), Old, err(Old), True]);

T = renamevars(T,1:8,["Weight","Off Design","OD % Error"," BADA Method","BM % Error","On Design Surrogate Model","ODSM % Error","True Value"])




%% Comparison to boeing's model

clear; clc; close all;

N = 5;
mach = linspace(0.6,0.85,N);
alt = linspace(9e3,12e3,N);

[AltGrid,MachGrid] = meshgrid(alt,mach);


% On Design Engine
EngineSpecs = EngineModelPkg.EngineSpecsPkg.CF34_8E5;
EngineSpecs.Sizing = 1;
% ON DESIGN
SizedEngine = ...
    EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);

SizedEngine.Specs.Sizing = 0;
OffParams.Thrust = "m";




for ii = 1:N
    for jj = 1:N


OffParams.FlightCon.Mach = MachGrid(ii,jj);
OffParams.FlightCon.Alt = AltGrid(ii,jj);

Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams);
OffFuel(ii,jj) = Off.Fuel;

[BoeingFuel(ii,jj)] = BoeingOffDesign(SizedEngine.Fuel.MDot,MachGrid(ii,jj),AltGrid(ii,jj));

    end
end


contourf(AltGrid,MachGrid,(OffFuel - BoeingFuel)./BoeingFuel.*100)
xlabel('Altitude in meters')
ylabel('Mach')
colorbar
title({'Difference Between FAST and Boeing Model','Boeing considered as the truth'})








% 
% function [fuelcomp] = BoeingOffDesign(WFuel_SLS,Mach,Alt)
% 
% [Tamb,Pamb,~] = MissionSegsPkg.StdAtm(Alt);
% 
% theta = Tamb/288.15;
% 
% delta = Pamb/101e3;
% 
% bigterm = theta^0.38/delta*exp(0.2*Mach^2);
% 
% fuelcomp = WFuel_SLS*bigterm;
% 
% 
% end

% On fuel is 19000
% off fuel  is 21000
% literature reports between these two numbers

%%

clear; clc; close all;


EngineSpecs = EngineModelPkg.EngineSpecsPkg.LEAP_1A26;
EngineSpecs.Sizing = 1;

SizedEngine = EngineModelPkg.TurbofanNonlinearSizing(EngineSpecs);
SizedEngine.Specs.Sizing = 0;

OffParams.FlightCon.Mach = EngineSpecs.Mach;
OffParams.FlightCon.Alt = EngineSpecs.Alt;
OffParams.Thrust = "max";

Grid = linspace(2e4,15e4);

setmach = 0.05;

for ii = 1:length(Grid)
    OffParams.FlightCon.Mach = setmach;
    OffParams.FlightCon.Alt = EngineSpecs.Alt;
    OffParams.Thrust = Grid(ii);
    Off = EngineModelPkg.TurbofanOffDesign(SizedEngine,OffParams);
    fuel(ii) = Off.Fuel;
    tsfc(ii) = Off.TSFC_Imperial;
    thrust(ii) = Off.Thrust;
end


figure(1)

subplot(1,3,1)
plot(Grid,fuel)
ylabel('Fuel [kg/s]')
hold on
xline(EngineSpecs.DesignThrust,'r--')


subplot(1,3,2)
plot(Grid,thrust./1e3)
ylabel('Thrust [kN]')
hold on
xline(EngineSpecs.DesignThrust,'r--')


subplot(1,3,3)
plot(Grid,tsfc)
ylabel('TSFC [lb/lbf/hr]')
hold on
xline(EngineSpecs.DesignThrust,'r--')

sgtitle({'SLS Condtions','Producing Thrust at Various Levels'})


% BADA data
BADA.Specs.Propulsion.Engine.EtaPoly.Fan = 0.99;
BADA.Specs.Propulsion.SLSThrust = [EngineSpecs.DesignThrust, 0, 0];

BADA.OffParams.FlightCon.Alt = 0; 
BADA.OffParams.FlightCon.Mach = 0.05;

BADAfuel = zeros(1,length(Grid));
BADATSFC = BADAfuel;

for ii = 1:length(Grid)
BADA.OffParams.Thrust = Grid(ii);
[OffOutputs] = EngineModelPkg.SimpleOffDesign(BADA, BADA.OffParams, 0);
BADAfuel(ii) = OffOutputs.Fuel;
BADATSFC(ii) = OffOutputs.TSFC_Imperial;
end

figure(1)
subplot(1,3,1)
hold on
plot(Grid,BADAfuel)

subplot(1,3,3)
hold on
plot(Grid,BADATSFC)

% NPSS
NPSS = [
107.0232836e3	1.150183314	10.74703818
96.32309035e3	1.001959528	10.40207
85.61844892e3	0.8631225771	10.08103496
64.21361428e3	0.6166961233	9.603822029
42.8101141e3	0.401542318	9.379613356
21.40438982e3	0.2201181178	10.28378382
];

subplot(1,3,1)
hold on
scatter(NPSS(:,1),NPSS(:,2),'ko','filled')

subplot(1,3,2)
hold on
scatter(NPSS(:,1),NPSS(:,1)./1000,'ko','filled')

subplot(1,3,3)
hold on
scatter(NPSS(:,1),UnitConversionPkg.ConvTSFC(NPSS(:,3)./1e6,'SI','Imp'),'ko','filled')


both = [
107.0232836	0.471	-0.591	1.226	1.1060	10.33419984
96.32309035	0.471	-0.591	1.226	0.9681	10.05029081
85.61844892	0.471	-0.591	1.226	0.8437	9.854301743
64.21361428	0.471	-0.591	1.226	0.6246	9.726482418
42.8101141	0.471	-0.591	1.226	0.4260	9.950716911
21.40438982	0.471	-0.591	1.226	0.2253	10.52706445];

scatter(both(:,1).*1e3,UnitConversionPkg.ConvTSFC(both(:,6)./1e6,'SI','Imp'),'go','filled')




















