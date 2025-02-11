function OptAircraft = MissionPowerOpt(Aircraft)

    
    Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");
    
    % lets try not design range
    
    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    
    PC0 = Aircraft.Mission.History.SI.Power.PC(n1:n2, 4);
    b = length(PC0);
    lb = zeros(1, b)';
    ub = ones(1, b)';
    
    fburnOG = PCvFburn(PC0, Aircraft);
    
    options = optimoptions('fmincon','MaxIterations', 50 ,'Display','iter','Algorithm','interior-point');
    options.OptimalityTolerance = 10^-3;
    options.StepTolerance = 10^-6;
    tic
    PCbest = fmincon(@(PC0) PCvFburn(PC0, Aircraft), PC0, [], [], [], [], lb, ub, @(PC) SOC_Constraint(PC, Aircraft), options);
    t = toc 
    
    fburnOpt = PCvFburn(PCbest, Aircraft);
    fdiff = (fburnOpt - fburnOG)/fburnOG;
    
    
    %% functions
    function [fburn] = PCvFburn(PC, Aircraft)

        n1= Aircraft.Mission.Profile.SegBeg(2);
        n2= Aircraft.Mission.Profile.SegEnd(4)-1;
        npts = length(Aircraft.Mission.History.SI.Performance.Alt);
        PC0 = zeros(npts,1);
        PC0(1:(n1-1)) = ones(n1-1,1);
        PC0(n1:n2) = PC;
        Aircraft.Settings.Analysis.Type = -2;
        Aircraft.Settings.PrintOut = 0;
        Aircraft.Settings.ConSOC = 0;
        Aircraft.Specs.Power.PC(:, [3,4]) = repmat(PC0,1,2);
        Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        
        fburn = Aircraft.Specs.Weight.Fuel;
        
    end
    
    function [c, ceq] = SOC_Constraint(PC, Aircraft)
        
        n1= Aircraft.Mission.Profile.SegBeg(2);
        n2= Aircraft.Mission.Profile.SegEnd(4)-1;
        npts = length(Aircraft.Mission.History.SI.Performance.Alt);
        PC0 = zeros(npts,1);
        PC0(1:(n1-1)) = ones(n1-1,1);
        PC0(n1:n2) = PC;
        Aircraft.Settings.Analysis.Type = -2;
        Aircraft.Settings.PrintOut = 0;
        Aircraft.Settings.ConSOC = 0;
        Aircraft.Specs.Power.PC(:, [3,4]) = repmat(PC0,1,2);
        Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
        
        SOC = Aircraft.Mission.History.SI.Power.SOC(:,2);
        c = 20 - SOC;
        ceq = [];
    end

end

