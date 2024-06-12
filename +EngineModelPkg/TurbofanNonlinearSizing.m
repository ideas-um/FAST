function [SizedEngine] = TurbofanNonlinearSizing(EngSpecFun,ElecPower)
%
% [SizedEngine] = TurbofanNonlinearSizing(EngSpecFun,Graphing)
% Written by Maxfield Arnson
% Updated 10/5/2023
%
% This function iterates on the design of a turbofan until the desired
% thrust (specified in EngSpecFun) is reached. The iteration varies mass
% flow rate of air in the stream tube to produce different thrusts.
%
% INPUTS:
%
% EngSpecFun = Structure defined by a specification file created by a user.
%       size: 1x1 struct
%
% Graphing = flag telling the program whether to visualize the engine
%           after it has been sized.
%       size: 1x1 boolean
%
% OUTPUTS:
%
% SizedEngine = Structure describing all information about the engine.
%           Stores flow states, turbomachinery details, and on-design
%           performance metrics
%       size: 1x1 struct

%% Function Body

switch nargin
    case 1
        % Initial Guess
        InitialGuess = EngineModelPkg.TurbofanLinearSizing(EngSpecFun);
        MDot0 = InitialGuess.MDot0;
        MDot1 = MDot0*1.005;

        Engine0 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot0);
        Engine1 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot1);

        Thrust0 = Engine0.Thrust.Net;
        Thrust1 = Engine1.Thrust.Net;

        tol = 1e-3;
        i = 1;
        imax = EngSpecFun.MaxIter;

        while abs(real(Thrust1)-EngSpecFun.DesignThrust)/EngSpecFun.DesignThrust > tol && i < imax
            w = (1/i);
            MDot2 = MDot1 - w*(Thrust1-EngSpecFun.DesignThrust)*(MDot1 - MDot0)/(Thrust1-Thrust0);
            Engine2 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot2);

            MDot0 = MDot1;
            MDot1 = MDot2;

            Thrust0 = Thrust1;
            Thrust1 = Engine2.Thrust.Net;
            i = i+1;
        end

        if i == imax
            warning('Maximum iterations (%d) reached without design convergence. Results are likely incorrect.',imax)
        end

        try
            SizedEngine = Engine2;
        catch
            SizedEngine = Engine1;
        end

    case 2
        % Initial Guess
        InitialGuess = EngineModelPkg.TurbofanLinearSizing(EngSpecFun);
        MDot0 = InitialGuess.MDot0;
        MDot1 = MDot0*1.005;

        Engine0 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot0,ElecPower);
        Engine1 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot1,ElecPower);

        Thrust0 = Engine0.Thrust.Net;
        Thrust1 = Engine1.Thrust.Net;

        tol = 1e-3;
        i = 1;
        imax = EngSpecFun.MaxIter;

        while abs(Thrust1-EngSpecFun.DesignThrust)/EngSpecFun.DesignThrust > tol && i < imax
            w = (1/i);
            MDot2 = MDot1 - w*(Thrust1-EngSpecFun.DesignThrust)*(MDot1 - MDot0)/(Thrust1-Thrust0);
            Engine2 = EngineModelPkg.CycleModelPkg.TurbofanOnDesignCycle(EngSpecFun,MDot2,ElecPower);

            MDot0 = MDot1;
            MDot1 = MDot2;

            Thrust0 = Thrust1;
            Thrust1 = Engine2.Thrust.Net;
            i = i+1;
        end

        if i == imax
            warning('Maximum iterations (%d) reached without design convergence. Results are likely incorrect.',imax)
        end

        try
            SizedEngine = Engine2;
        catch
            SizedEngine = Engine1;
        end
end

if SizedEngine.States.Station9.Mach > 1
    %warning('Core exhaust is supersonic')
end

if ~isfield(EngSpecFun,'Sizing')
elseif EngSpecFun.Sizing == 1
SizedEngine.OffDesignMap = EngineModelPkg.TF_OD_MapMaker(SizedEngine);
SizedEngine.Specs.Sizing = 0;
end


%% Graphing

if ~isfield(EngSpecFun,'Visualize')
elseif EngSpecFun.Visualize == 1
    figure(1)

    load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
    Data = TurbofanEngines;

    if EngSpecFun.Mach > 0.2
        target = 5*EngSpecFun.DesignThrust;
    else 
        target = EngSpecFun.DesignThrust;
    end

    [LengthScale,~] = RegressionPkg.NLGPR(Data,{["Thrust_SLS"],["Length"]},target);



    t = [
        SizedEngine.States.Station21.Ri
        SizedEngine.States.Station25.Ri
        SizedEngine.States.Station26.Ri
        SizedEngine.States.Station3.Ri
        SizedEngine.States.Station31.Ri
        SizedEngine.States.Station39.Ri
        SizedEngine.States.Station4.Ri
        SizedEngine.States.Station41.Ri
        SizedEngine.States.Station5.Ri
        SizedEngine.States.Station55.Ri
        SizedEngine.States.Station6.Ri
        SizedEngine.States.Station9.Ri
        ];

    [Y,Z,X] = cylinder(t,50);

    surf(LengthScale.*X,Y,Z,'FaceColor','r','EdgeColor','r','FaceAlpha',0.1,'EdgeAlpha',0.2)

    hold on

    t = [
        SizedEngine.States.Station21.Ro
        SizedEngine.States.Station25.Ro
        SizedEngine.States.Station26.Ro
        SizedEngine.States.Station3.Ro
        SizedEngine.States.Station31.Ro
        SizedEngine.States.Station39.Ro
        SizedEngine.States.Station4.Ro
        SizedEngine.States.Station41.Ro
        SizedEngine.States.Station5.Ro
        SizedEngine.States.Station55.Ro
        SizedEngine.States.Station6.Ro
        SizedEngine.States.Station9.Ro
        ];

    [Y,Z,X] = cylinder(t,50);

    surf(LengthScale.*X,Y,Z,'FaceColor','k','EdgeColor','k','FaceAlpha',0.1,'EdgeAlpha',0.2)

    t = [
        SizedEngine.States.Station13.Ro
        SizedEngine.States.Station19.Ro];

    [Y,Z,X] = cylinder(t,50);

    surf(LengthScale./2.*X,Y,Z,'FaceColor','b','EdgeColor','b','FaceAlpha',0.1,'EdgeAlpha',0.2)

    axis equal
    grid on
    ylabel('Width [m] ')
    xtext = "Total Length = " + num2str(LengthScale) + "m";
    xlabel(xtext)
    zlabel('Height [m] ')
    x = linspace(0,LengthScale,12);
    xticks(x)
    xticklabels({'Core Enterance','Post Boosters/LPC','Post IPC','Post HPC','Post Bleed','Post Combustion','Post Turbine Diffuser','Post Cooling','Post HPT','Post IPT','Post LPT','Core Nozzle'})
    view(-45,25)
    drawnow
    hold off


end
end