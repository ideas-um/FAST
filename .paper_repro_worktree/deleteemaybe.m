
[c, cr, Pdif] = AvgTSFC(SizedERJ, Conv)











%% functions


function [Clb, Crs, Pdif]= AvgTSFC(Aircraft, Conv)

    w = Aircraft.Specs.Weight;
    wc= Conv.Specs.Weight;
    
    T = Aircraft.Mission.History.SI.Propulsion.TSFC;
    Tc = Conv.Mission.History.SI.Propulsion.TSFC;

    Clb = T(10:28,1);
    Crs = T(28:46,1);

    Clbc = Tc(10:28,1);
    Crsc = Tc(28:46,1);

    Clb = sum(Clb)/length(Clb);
    Crs = sum(Crs)/length(Crs);
    Clbc = sum(Clbc)/length(Clbc);
    Crsc = sum(Crsc)/length(Crsc);
   
    w.TClb = Clb;
    wc.TClb = Clbc;
    w.TCrs = Crs;
    wc.TCrs = Crsc;

    w.SLST = Aircraft.Specs.Propulsion.Thrust.SLS/2/1000;
    wc.SLST = Conv.Specs.Propulsion.Thrust.SLS/2/1000;

    
    Spec = {"MTOW", "Fuel", "OEW", "Engines", "SLST", "TClb", "TCrs"};
    Pdif = zeros(7,1);
    for i = 1:7
        Pdif(i) = (w.(Spec{i})-wc.(Spec{i}))/w.(Spec{i})*100;
    end


end