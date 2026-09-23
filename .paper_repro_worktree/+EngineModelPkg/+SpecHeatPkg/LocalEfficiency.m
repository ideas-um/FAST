function [Eta] = LocalEfficiency(Re)


high = 1;
low = 0.75;
gr = 1/2;
inflec = 7;


Eta =  low + ((high - low)./(1+exp((-gr).*(log10(Re) - inflec))));



end



