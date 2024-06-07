function [Aircraft] = Tutorial007()
%
% [Aircraft] = Tutorial007()
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 07 jun 2024
%
% This is a tutorial for creating a new propulsion architecture and storing
% it in an aircraft structure. Hard-coded power splits are provided for
% instructional purposes. See the following variables to specify the power
% splits as a function of segment (takeoff, climb, cruise, descent landing)
% and for sizing (SLS):
% 
%     a) Specs.Power.LamTS
%     b) Specs.Power.LamTSPS
%     c) Specs.Power.LamPSPS
%     d) Specs.Power.LamPSES
%
% INPUTS:
%     none
%
% OUTPUTS:
%     Aircraft - aircraft structure with updated propulsion architecture.
%                type/size/units: 1-by-1 / struct / []
%


%% SETUP %%
%%%%%%%%%%%

% initial cleanup
clc, close all

% load an arbitrary aircraft
Aircraft = AircraftSpecsPkg.Example();


%% CREATE THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% define the component       %
% efficiencies               %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% turboshaft efficiency
EtaTS = 0.45;

% electric machine efficiencies
EtaPC = 0.95;
EtaEM = 0.96;
EtaEG = 0.96;

% gearbox efficiency
EtaGB = 0.90;

% propeller efficiency
EtaProp = 0.80;

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% assemble the propulsion    %
% architecture matrices      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ** REQUIRED ** propulsion system architecture, either:
%     (1) "C"  = conventional
%     (2) "E"   = fully electric
%     (3) "TE"  = fully turboelectric
%     (4) "PE"  = partially turboelectric
%     (5) "PHE" = parallel hybrid electric
%     (6) "SHE" = series hybrid electric
%     (7) "O"   = other architecture (specified by the user)
Aircraft.Specs.Propulsion.Arch.Type = "O";

% thrust-power source matrix
Aircraft.Specs.Propulsion.PropArch.TSPS = [1, 1];

% power-power source matrix
Aircraft.Specs.Propulsion.PropArch.PSPS = [1, 0; 1, 1];

% power-energy source matrix
Aircraft.Specs.Propulsion.PropArch.PSES = [1, 0; 0, 1];

% thrust      source operation
Aircraft.Specs.Propulsion.Oper.TS   = @() 1;

% thrust-power source operation
Aircraft.Specs.Propulsion.Oper.TSPS = @() [0.8, 0.2];

% power-power  source operation
Aircraft.Specs.Propulsion.Oper.PSPS = @() [1.0, 0.0; 0.4, 1.0];

% power-energy source operation
Aircraft.Specs.Propulsion.Oper.PSES = @() [1.0, 0.0; 0.0, 0.6];

% thrust-power  source efficiency
Aircraft.Specs.Propulsion.Eta.TSPS  = [EtaGB * EtaProp, EtaGB * EtaProp];

% power -power  source efficiency
Aircraft.Specs.Propulsion.Eta.PSPS  = [1, 1; EtaEG * EtaEM, 1];

% power -energy source efficiency
Aircraft.Specs.Propulsion.Eta.PSES  = [EtaTS, 1; 1, EtaPC * EtaEM];

% energy source type (1 = fuel, 0 = battery)
Aircraft.Specs.Propulsion.PropArch.ESType = [1, 0];

% power source type (1 = engine, 0 = electric motor)
Aircraft.Specs.Propulsion.PropArch.PSType = [1, 0];


end