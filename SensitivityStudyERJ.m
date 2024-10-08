function Results =SensitivityStudyERJ()



ERJ = AircraftSpecsPkg.ERJ175LR;

% size baseline model
Conv = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

% initizalize takeoff power splits and climb power code
tko_split = (1:.5:9.5)/100;
PC_EM = [5, 10, 15, 20, 25, 30]/100;
PC_Alt = [20000, 36000]; % altitude for climb boost
ERJ.Specs.Power.PC.EM.Alt = PC_Alt;

% initialize result vectors
wFuel = zeros(length(tko_split)+1, length(PC_EM)+1);
MTOW = zeros(length(tko_split)+1, length(PC_EM)+1);
wBatt = zeros(length(tko_split)+1, length(PC_EM)+1);

wFuel(1,1) = Conv.Specs.Weight.Fuel;
MTOW(1,1) = Conv.Specs.Weight.MTOW;
wBatt(1,1) = Conv.Specs.Weight.Batt;

% iterate through split and PC
for PC = 1:6
    for tk = 1: length(tko_split)
        ERJ.Specs.Power.LamTSPS.SLS = tko_split(tk);
        ERJ.Specs.Power.PC.EM.Split = PC_EM(PC);
        % size HEA
        Aircraft = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        % get results
        wFuel(tk+1, PC+1) = Aircraft.Specs.Weight.Fuel;
        MTOW(tk+1, PC+1) = Aircraft.Specs.Weight.MTOW;
        wBatt(tk+1, PC+1) = Aircraft.Specs.Weight.Batt;
    end 
end

figure(1)
plot(tko_split', wFuel)
title('Fuel Burn Comparison')
xlabel('SLS Tko Split')
ylabel('Fuel Burn (kg)')
legend(PC_EM)

figure(2)
plot(tko_split', MTOW)
title('MTOW Comparison')
xlabel('SLS Tko Split')
ylabel('MTOW (kg)')
legend(PC_EM)

figure(3)
plot(tko_split', wBatt)
title('Battery Size Comparison')
xlabel('SLS Tko Split')
ylabel('Battery (kg)')
legend(PC_EM)



end