function [NewState,TurbineObject] = FreeTurbine(OldState,Ambient,CompressorObject,EtaPoly)
% never called in the tool. defunct
PiTurb = Ambient.Pt/OldState.Pt;
g = OldState.Gam;
TauTurb = (PiTurb)^(EtaPoly.Turbines*(g-1)/g);

NewState.Tt = TauTurb*OldState.Tt;

TurbineObject.DelivWork = EngineModelPkg.SpecHeatPkg.CpAir(NewState.Tt,OldState.Tt)*OldState.MDot;



end

