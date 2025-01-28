
% goal optimize off design power code for one flight
n1= Aircraft.Mission.Profile.SegBeg(2);
n2= Aircraft.Mission.Profile.SegEnd(4)-1;
PC0 = SizedHEA.Mission.History.SI.Power.PC(n1:n2, 4);
b = length(PC0);
A = ones(1,b);
lb = zeros(1, b);
ub = ones(1, b);

PC1 = .5 * ones(b,1);
%fburn = PCvFburn(PC1);

%{
Step Size Study
h= [10^-1, 10^-2, 10^-3, 10^-4, 10^-6, 10^-8, 10^-10];
hh = zeros(b,7);
hh(3,:) =h;
for i = 1:length(h)
    [df(i), cf(i)] = FiniteDif(@PCvFburn , PC1, hh(:,i), h(i));
end
%}

[x,fburn] = ConjGrad(@fuelFunc, PC1, 10^-3, @bracket, Aircraft)

%% functions
function [f, df] = fuelFunc(PC, Aircraft)
f = PCvFburn(PC, Aircraft);
df = FiniteDif(@PCvFburn, PC, Aircraft);
% implement interior point method
[c, ceq] = Con_ebatt(PC, Aircraft);
df = df+c;
end

function fburn = PCvFburn(PC, Aircraft)
    ineg = find(PC<0);
    if ~isempty(ineg)
        PC(ineg) = 0;
    end
    n1= Aircraft.Mission.Profile.SegBeg(2);
    n2= Aircraft.Mission.Profile.SegEnd(4)-1;
    npts = length(Aircraft.Mission.History.SI.Performance.Alt);
    PC0 = zeros(npts,1);
    PC0(1:(n1-1)) = ones(n1-1,1);
    PC0(n1:n2) = PC;
    Aircraft.Settings.Analysis.Type = -2;
    Aircraft.Specs.Power.PC.EM = PC0;
    % evaluate aircraft
    Aircraft = Main(Aircraft, @MissionProfilesPkg.ERJ_ClimbThenAccel);
    fburn = Aircraft.Specs.Weight.Fuel;
end

function [c, ceq] = Con_ebatt(PC, Aircraft)
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
    c = Ebatt - .9*Ebattmax;
    ceq = [];
end



%% finite dif 
function df = FiniteDif(f, x, Aircraft)
h =10^(-3);
n = length(x);
df = zeros(n,1);
for i = 1:n
    a = f(x+h, Aircraft);
    b = f(x-h, Aircraft);
    df(i) = (a-b)/(2*h);
end
end

%% bracket linesearch
function alpha = bracket(xk, a0, pk, phi, Aircraft)
    mu1 = 10^-4;
    mu2 = 0.5;

    a1 = 0;
    a2 = a0;
    sig = 1.1;
    lam = 0.5;

    [phi0, dphi0] = phi(xk, Aircraft);
    dphi0 = dot(dphi0, pk);
    first = true;

    while true
        [phi2, dphi2] = phi(xk + a2 * pk, Aircraft);
        dphi2 = dot(dphi2, pk);
        [phi1, dphi1] = phi(xk + a1 * pk, Aircraft);
        dphi1 = dot(dphi1, pk);

        tol = phi0 + mu1 * a2 * dphi0;

        if isnan(phi2)
            a2 = lam * a2;
            continue;
        end

        if (phi2 > tol) || (~first && (phi2 > phi1))
            a2 = pinpoint(pk, xk, a1, a2, phi0, dphi0, phi1, dphi1, phi2, mu1, mu2, phi, mu);
            alpha = a2;
            return;
        end

        if abs(dphi2) <= mu2 * abs(dphi0)
            alpha = a2;
            return;
        elseif dphi2 >= 0
            a2 = pinpoint(pk, xk, a1, a2, phi0, dphi0, phi1, dphi1, phi2, mu1, mu2, phi, mu);
            alpha = a2;
            return;
        else
            a1 = a2;
            a2 = sig * a2;
        end

        first = false;
    end
end

function ap = pinpoint(pk, xk, a1, a2, phi0, dphi0, phi1, dphi1, phi2, mu1, mu2, phi)
    k = 0;
    while k < 100
        ap = interpol(a1, a2, phi1, dphi1, phi2);
        [phip, dphip] = phi(xk + ap * pk, Aircraft);
        tol = phi0 + mu1 * ap * dphi0;

        if abs(a2 - a1) <= 0.001
            ap = a2;
            return;
        elseif phip > tol || phip > phi1
            a2 = ap;
            phi2 = phip;
        else
            dphip = dot(dphip, pk);

            if abs(dphip) <= -mu2 * dphi0
                ap = ap;
                return;
            elseif (dphip * (a2 - a1)) >= 0
                a2 = a1;
                phi2 = phi1;
            end

            a1 = ap;
            phi1 = phip;
            dphi1 = dphip;
        end

        k = k + 1;
        if k == 100
            ap = a2;
            return;
        end
    end
end

function ap = interpol(a1, a2, phi1, dphi1, phi2)
    top = 2 * a1 * (phi2 - phi1) + dphi1 * (a1^2 - a2^2);
    bot = 2 * (phi2 - phi1 + dphi1 * (a1 - a2));
    ap = top / bot;
end

%% Conj Grad

function [xk, fk] = ConjGrad(f, x0, epsilon_g, step, Aircraft)
    % initialize output arrays
    xk = x0;
    x = xk;
    [fk, g] = f(xk, Aircraft);
    F = fk;
    ginf = max(abs(g));

    pk_1 = g;
    g_1 = g;
    ginf1 = ginf;
    ak = 1;

    % initialize iteration
    k = 1;
    reset = 0;

    while ginf > epsilon_g

        if k == 1 || reset == 1
            % get search direction
            pk = -g / sqrt(dot(g, g));
        else
            Bk = dot(g, g) / dot(g_1, g_1);
            pk = -g / sqrt(dot(g, g)) + Bk * pk_1;
        end

        % find initial step size guess
        if abs(ginf - ginf1) > 20
            aint = 0.1;
        else
            aint = abs(ak * dot(g_1, pk_1) / dot(g, pk));
        end

        % perform the line search
        ak = step(xk, aint, pk, f, Aircraft);

        % update x
        xk = xk + pk * ak;

        % store i-1 values to use in aint calc
        g_1 = g;
        pk_1 = pk;
        k = k + 1;
        ginf1 = ginf;

        % get new function and gradient values
        [fk, g] = f(xk, Aircraft);

        % get |gradF_inf|
        ginf = max(abs(g));

        fprintf('iteration %d: x = [%f, %f], f = %f\n', k, xk(1), xk(2), fk);

        resetCheck = abs(dot(g, g_1)) / abs(dot(g, g));
        if resetCheck >= 0.1
            reset = 1;
        else
            reset = 0;
        end
    end
end