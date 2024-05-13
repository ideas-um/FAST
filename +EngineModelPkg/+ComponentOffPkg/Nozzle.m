function [M2] = Nozzle(A1,A2,M1,g)


% find exit mach

Astar = EngineModelPkg.IsenRelPkg.Astar_A(A1,M1,g);

M2 = 0.5;
A2guess = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M2,g);

while abs(A2guess - A2)/A2 > 1e-3

    M2 = M2*(1 + (A2guess - A2)/A2);

    A2guess = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M2,g);

end

if M2 > 1
    M2 = 1;
end

end

