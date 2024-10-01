function [SurgeLimit, ChokeLimit] = MassFlowLimits(Nrot)
% see EngineModelPkg.MapPkg.MapCreationData
% Nrot is normalized rotation divided by reference normalized rotation, in
% percentage [0 100] NOT [0 1]
% outputs are of the same form
PolyChoke = [3.83715665954675e-08	-1.56751968688756e-05	0.00249340969472875	-0.194854267711026	8.64138152232149	-123.041829758267];
PolySurge = [2.23974655570896e-07	-7.64247321443166e-05	0.0102175841345538	-0.659463130294949	21.5791800156143	-283.671851127920];

ChokeLimit = polyval(PolyChoke,Nrot);
SurgeLimit = polyval(PolySurge,Nrot);

if Nrot < 45
    warning('ENGINE OFF DESIGN: Engine is sub-idle, results may be inaccurate. See +EngineModelPkg/+MapPkg/CreateMap.')
elseif Nrot > 100
    warning('ENGINE OFF DESIGN: Engine is near maximum operating speed and may choke or surge at these conditions. See +EngineModelPkg/+MapPkg/CreateMap.')
end

end % MassFlowLimits