

time = linspace(1,60,200);

for i = 1: length(time)
    SizedERJ.Specs.Power.Battery.BegSOC = 20;
    SOCf = BatteryPkg.GroundCharge(SizedERJ, time(i)*60, -150000, 2);

    if SOCf >= 100
        break
    end

end

disp(time(i))