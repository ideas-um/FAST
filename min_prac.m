
% fmincon practice
% goal optimize off design power code for one flight
n1= SizedHEA.Mission.Profile.SegBeg(2);
n2= SizedHEA.Mission.Profile.SegEnd(4)-1;

PC0 = SizedHEA.Mission.History.SI.Power.PC(n1:n2, 4);
b = length(PC0);
A = ones(1,b);
lb = zeros(1, b);
ub = ones(1, b);

PC1 = .01 * ones(b,1);
fburn = PCvFburn(PC1)

options = optimoptions('fmincon','MaxIterations', 50 ,'Display','iter','Algorithm','sqp');
PCbest = fmincon(@PCvFburn, PC0, [], [], [], [], lb, ub, @Con_ebatt, options);




%% functions
function [fburn] = PCvFburn(PC)

    load("SizedHea2.mat")
    Aircraft = SizedHEA;

    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    npts = length(Aircraft.Mission.History.SI.Performance.Alt);
    PC0 = zeros(npts,1);
    PC0(1:(n1-1)) = ones(n1-1,1);
    PC0(n1:n2) = PC;

    Aircraft.Settings.Analysis.Type = -2;
    Aircraft.Specs.Power.PC.EM = PC0;
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    fburn = Aircraft.Specs.Weight.Fuel;
end

function [c, ceq] = Con_ebatt(PC)

    % get aircraft
    load("SizedHea2.mat")
    Aircraft = SizedHEA;
    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;

    SOC = Aircraft.Mission.History.SI.Power.SOC(n2, 2);
    SOCMax = 20;
    %{
    PC0 = zeros(npts,1);
    PC0(1:(n1-1)) = ones(n1-1,1);
    PC0(n1:n2) = PC;
    Pem = Aircraft.Specs.Weight.EM * 10^3;
    Pout = PC0 * Pem;
    % time differentiation
    dt = diff(Aircraft.Mission.History.SI.Performance.Time);
    Ebatt = sum(Pout(1:end-1).*dt);

    % get battery max energy
    Ebattmax = Aircraft.Specs.Weight.Batt * Aircraft.Specs.Power.SpecEnergy.Batt;
    c = Ebatt - .9*Ebattmax;
    
    %}
    c = SOC - SOCMax;
    ceq = [];

end

