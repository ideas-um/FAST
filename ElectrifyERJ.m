function [SizedERJ] = ElectrifyERJ(RunCases)
%
% [] = ElectrifyERJ(RunCases)
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 18 jul 2024
%
% Given an ERJ175LR model, electrify takeoff using different power splits
% to determine the overall aircraft size and fuel burn trends.
%
% INPUTS:
%     RunCases - flag to size the aircraft (1) or just load results (0)
%
% OUTPUTS:
%     none
%

% initial cleanup
clc, close all

% assume cases must be run
if (nargin < 1)
    RunCases = 1;
end


%% INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%

% get the ERJ
ERJ = AircraftSpecsPkg.ERJ175LR;

% number of power splits
%nsplit = 13;

% assume a set of takeoff power splits
LambdaTko = 9;
LambdaClb = [.5, 1, 1.5, 3, 5];
nsplit = length(LambdaTko);
nclb = length(LambdaClb);

% remember the results
MTOW  = zeros(nsplit, nclb);
Wbatt = zeros(nsplit, nclb);
Wfuel = zeros(nsplit, nclb);
Wem   = zeros(nsplit, nclb);
Weng  = zeros(nsplit, nclb);
E_em  = zeros(nsplit, nclb);
E_gt  = zeros(nsplit, nclb);

%check if the sizing converged
conv = zeros(nsplit, nclb);

tkoname = 10*LambdaTko;
clbname = 10*LambdaClb;

%% SIZE THE AIRCRAFT %%
%%%%%%%%%%%%%%%%%%%%%%%

% loop through all power splits
for csplit =1:nclb
    for tsplit = 1:nsplit
    
    % filename for a .mat file
    MyMat = sprintf("ERJ_tko0%d_clb0%d.mat", tkoname(tsplit), clbname(csplit));
    
    % remember the new power split
    ERJ.Specs.Power.LamTSPS.Tko = LambdaTko(tsplit) / 100;
    ERJ.Specs.Power.LamTSPS.Clb = LambdaClb(csplit) / 100;
    ERJ.Specs.Power.LamTSPS.SLS = LambdaTko(tsplit) / 100;

    ERJ.Specs.Propulsion.Engine.HEcoeff = 1 +  ERJ.Specs.Power.LamTSPS.SLS;
    
    % check if cases must be run
    if (RunCases == 1)
        
        % size the aircraft
        SizedERJ = Main(ERJ, @MissionProfilesPkg.ERJ_ClimbThenAccel);

        conv(tsplit, csplit) = SizedERJ.Settings.Converged;

        % save the aircraft
        save(MyMat, "SizedERJ");
        
    else
        
        % get the .mat file
        foo = load(MyMat);
        
        % get the sized aircraft
        SizedERJ = foo.SizedERJ;
        
    end
            % remember the weights
        MTOW( tsplit, csplit) = SizedERJ.Specs.Weight.MTOW   ;
        Wfuel(tsplit, csplit) = SizedERJ.Specs.Weight.Fuel   ;
        Wbatt(tsplit, csplit) = SizedERJ.Specs.Weight.Batt   ;
        Wem(  tsplit, csplit) = SizedERJ.Specs.Weight.EM     ;
        Weng( tsplit, csplit) = SizedERJ.Specs.Weight.Engines;
        E_em( tsplit, csplit) = SizedERJ.Mission.History.SI.Energy.E_ES(end,2);
        E_gt( tsplit, csplit) = SizedERJ.Mission.History.SI.Energy.E_ES(end,1);
    end
end


%% POST-PROCESS %%
%%%%%%%%%%%%%%%%%%

% turn climb % to 
labels = cellstr(arrayfun(@(x) sprintf('%.1f%%', x), LambdaClb, 'UniformOutput', false));

num = length(Wfuel);
% plot the fuel burn results
figure;
cmap = jet(num);
hold on
yyaxis left
for i = 1:num
    plot(LambdaTko, Wfuel(:,i), '-o', 'Color', cmap(i,:),"LineWidth", 2);
end
ylabel("Block Fuel (kg)");
% format plot
title("Electrified ERJ - Block Fuel");
xlabel("Power Split (%)");
legend(labels)
set(gca, "FontSize", 18);
grid on

% ----------------------------------------------------------

end