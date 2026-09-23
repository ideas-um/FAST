function [SizedEngine] = TurbopropNonlinearSizing(EngSpecFun,ElecPower)
%
% [SizedEngine] = TurbopropNonlinearSizing(EngSpecFun,Graphing)
% Written by Maxfield Arnson
% Updated 11/20/2023
%
% This function iterates on the design of a turboprop until the desired
% power (specified in EngSpecFun) is reached. The iteration varies mass
% flow rate of air in the stream tube to produce different powers.
% 
% INPUTS:
%
% EngSpecFun = Structure defined by a specification file created by a user.
%       size: 1x1 struct
%
% EngSpecFun = flag telling the program whether to visualize the engine
%           after it has been sized.
%       size: 1x1 boolean
%
% OUTPUTS:
%
% SizedEngine = Structure describing all information about the engine.
%           Stores flow states, turbomachinery details, and on-design
%           performance metrics
%       size: 1x1 struct


%% Find Jet Power estimate

switch nargin
    case 1
DesPower = EngSpecFun.ReqPower;

InitialGuess = EngineModelPkg.TurbopropLinearSizing(EngSpecFun);
MDot0 = InitialGuess.MDot0;
MDot1 = MDot0*1.005;

Engine0 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot0);
Engine1 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot1);

Power0 = Engine0.Power;
Power1 = Engine1.Power;

tol = 1e-5;
w = 0.5;
i = 1;
while abs(Power1-DesPower)/DesPower > tol

    %MDot2 = MDot1 - w*(Power1-DesPower)*(MDot1 - MDot0)/(Power1-Power0);
    MDot2 = MDot1*(1 - (Power1-DesPower)/DesPower);

    if imag(MDot2) > 0 || MDot2 < 0
        error('Non-physical value for Mass flow')
    end

    Engine2 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot2);

    MDot0 = MDot1;
    MDot1 = MDot2;

    Power0 = Power1;
    Power1 = Engine2.Power;
    i = i+1;
end

try
    SizedEngine = Engine2;
catch
    SizedEngine = Engine1;
end
    case 2

DesPower = EngSpecFun.ReqPower;

InitialGuess = EngineModelPkg.TurbopropLinearSizing(EngSpecFun);
MDot0 = InitialGuess.MDot0;
MDot1 = MDot0*1.005;

Engine0 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot0,ElecPower);
Engine1 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot1,ElecPower);

Power0 = Engine0.Power;
Power1 = Engine1.Power;

tol = 1e-5;
w = 0.5;
i = 1;
while abs(Power1-DesPower)/DesPower > tol

    %MDot2 = MDot1 - w*(Power1-DesPower)*(MDot1 - MDot0)/(Power1-Power0);
    MDot2 = MDot1*(1 - (Power1-DesPower)/DesPower);

    if imag(MDot2) > 0 || MDot2 < 0
        error('Non-physical value for Mass flow')
%     elseif MDot2 < 0
%         MDot2 = 0.5*MDot1;
%         MDot0 = 0.5*MDot0;
    end

    Engine2 = EngineModelPkg.CycleModelPkg.TurbopropOnDesignCycle(EngSpecFun,MDot2,ElecPower);

    MDot0 = MDot1;
    MDot1 = MDot2;

    Power0 = Power1;
    Power1 = Engine2.Power;
    i = i+1;
end

try
    SizedEngine = Engine2;
catch
    SizedEngine = Engine1;
end
end

%% Graphing

if ~isfield(EngSpecFun,'Visualize')
elseif EngSpecFun.Visualize == 1
    figure(1)

        load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))
    Data = TurbopropEngines;

        target = EngSpecFun.ReqPower;


    [LengthScale,~] = RegressionPkg.NLGPR(Data,{["Power_SLS"],["Length"]},target);



    t = [
        SizedEngine.States.Station1.Ri
        SizedEngine.States.Station3.Ri
        SizedEngine.States.Station31.Ri
        SizedEngine.States.Station39.Ri
        SizedEngine.States.Station4.Ri
        SizedEngine.States.Station41.Ri
        SizedEngine.States.Station5.Ri
        %SizedEngine.States.Station55.Ri
        SizedEngine.States.Station7.Ri
        SizedEngine.States.Station9.Ri
        ];

    [X,Y,Z] = cylinder(t,50);

    surf(Y,Z.*LengthScale,X,'FaceColor','r','EdgeColor','r','FaceAlpha',0.1,'EdgeAlpha',0.2)

    hold on

    t = [
        SizedEngine.States.Station1.Ro
        SizedEngine.States.Station3.Ro
        SizedEngine.States.Station31.Ro
        SizedEngine.States.Station39.Ro
        SizedEngine.States.Station4.Ro
        SizedEngine.States.Station41.Ro
        SizedEngine.States.Station5.Ro
        %SizedEngine.States.Station55.Ro
        SizedEngine.States.Station7.Ro
        SizedEngine.States.Station9.Ro
        ];

    [X,Y,Z] = cylinder(t,50);

    surf(Y,Z.*LengthScale,X,'FaceColor','k','EdgeColor','k','FaceAlpha',0.1,'EdgeAlpha',0.2)


    axis equal
    grid on
    xlabel('Radial [m]')
    ytext = "Total Length = " + num2str(LengthScale) + "m";
    ylabel(ytext)
    zlabel('Radial [m]')

    t = [0 1];
    [X,Y,Z] = cylinder(t,50);
    surf(Y,Z*0.001 - 0.4,X, 'FaceColor', 'b','LineStyle','none','FaceAlpha',0.1)
    axis equal

    y = [-0.4,linspace(0,2,9)];
    yticks(y)
    yticklabels({'Propeller','Core Enterance','Post Compressor','Post Bleed','Post Combustion','Post Turbine Diffuser','Post Cooling','Post Comp. Turb.','Post Free Turb.','Exhaust'})
    view(48,14)

end

end


