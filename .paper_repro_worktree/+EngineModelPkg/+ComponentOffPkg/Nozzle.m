function [M2] = Nozzle(A1,A2,M1,g)


% find exit mach

Astar = EngineModelPkg.IsenRelPkg.Astar_A(A1,M1,g);

M2 = M1;

prime = 1;

while abs(prime) > 1e-5

    A2guess = EngineModelPkg.IsenRelPkg.A_Astar(Astar,M2,g);
    fx = (A2guess - A2)^2;
    prime = 2*((Astar*((g/2 - 1/2)*M2^2 + 1)^((g + 1)/(2*g - 2)))/(M2^2*(g/2 + 1/2)^((g + 1)/(2*g - 2))) - (2*Astar*(g/2 - 1/2)*((g/2 - 1/2)*M2^2 + 1)^((g + 1)/(2*g - 2) - 1)*(g + 1))/((2*g - 2)*(g/2 + 1/2)^((g + 1)/(2*g - 2))))*(A2 - (Astar*((g/2 - 1/2)*M2^2 + 1)^((g + 1)/(2*g - 2)))/(M2*(g/2 + 1/2)^((g + 1)/(2*g - 2))));


    M2 = M2 - fx/prime;

end

if M2 > 1
    M2 = 1;
end


if M2 < 0
    M2 = M1;

end


end

