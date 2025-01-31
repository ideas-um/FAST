
% goal optimize off design power code for one flight
load("SizedHEA.mat")

% lets try not design range

n1= SizedHEA.Mission.Profile.SegBeg(2);
n2= SizedHEA.Mission.Profile.SegEnd(4)-1;

PC0 = SizedHEA.Mission.History.SI.Power.PC(n1:n2, 4);
b = length(PC0);
A = ones(1,b);
lb = zeros(1, b);
ub = ones(1, b);

fburnOG = PCvFburn(PC0);

options = optimoptions('fmincon','MaxIterations', 50 ,'Display','iter','Algorithm','interior-point');
options.OptimalityTolerance = 10^-3;
options.StepTolerance = 10^-6;
tic
PCbest = fmincon(@PCvFburn, PC0, [], [], [], [], lb, ub, @Con_ebatt, options);
t = toc 

fburnOpt = PCvFburn(PCbest);
fdiff = (fburnOpt - fburnOG)/fburnOG


%% functions
function [fburn] = PCvFburn(PC)
    
    load("SizedHEA.mat")
    Aircraft = SizedHEA;
    Aircraft.Specs.Performance.Range = UnitConversionPkg.ConvLength(1000, "naut mi", "m");

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
    load("SizedHEA.mat")
    Aircraft = SizedHEA;
    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    npts = length(Aircraft.Mission.History.SI.Performance.Alt);

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
    c = Ebatt - .96*Ebattmax;
    
    ceq = [];

end

