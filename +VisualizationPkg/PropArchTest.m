function [] = PropArchTest(iarch)
%
% PropArchTest.m
% written by Nawa Khailany, nawakhai@umich
% modified by Paul Mokotoff, prmoko@umich.edu
% last updated: 29 feb 2024
%
% given a propulsion architecture, plot a schematic of it. multiple
% propulsion architectures are provided. uncomment the one to be used, or
% create your own.
%
% inputs : iarch - the architecture to be drawn
% outputs: none
%

%% PARALLEL HYRBID %%
%%%%%%%%%%%%%%%%%%%%%

% energy-power  sources
% B_PSES = [1 0 ; 0 1];
% 
% power -power  sources
% B_PSPS = [1 0; 0 1];
% 
% power -thrust sources
% B_TSPS = [1 1];


%% SERIES HYBRID %%
%%%%%%%%%%%%%%%%%%%

% energy-power  sources
% B_PSES = [1 0 ; 0 1];
% 
% power -power  sources
% B_PSPS = [1 0 ; 1 1];
% 
% power -thrust sources
% B_TSPS = [0 1];


%% SERIES HYBRID WITH MULTIPLE ENGINES %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% energy-power  sources
% B_PSES = [1 0 0 0 ;
%           1 0 0 0 ;
%           0 1 1 0 ;
%           0 0 1 1] ;
% 
% power -power  sources
% B_PSPS = [1 0 1 0 ;
%           0 1 0 1 ;
%           0 0 1 0 ;
%           0 0 0 1];
% 
% power -thrust sources
% B_TSPS = [1 0 0 0;
%           0 1 0 0];


%% ADDITIONAL ARCHITECTURES CREATED %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% get the architecture from the input argument
if     (iarch == 0)
    
    % gas-turbine engines only
    B_PSES = [1; 1; 1; 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);
    
elseif (iarch == 1)
    
    % independent parallel hybrid
    B_PSES = [1 0;
              0 1;
              0 1;
              0 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);

elseif (iarch == 2)

    % new LM100J architecture
    B_PSES = [1 0 0; 0 1 0; 0 1 1; 0 0 1];
    B_PSPS = eye(4);
    B_TSPS = eye(4);

elseif (iarch == 3)
    
    % conventional, multiple fuel tanks
    B_PSES = [1 1 0; 0 1 1];
    B_PSPS = [1 0; 0 1];
    B_TSPS = [1 0; 0 1];

elseif (iarch == 4)

    % stress test
    B_PSES = eye(2);
    B_PSPS = [1 0; 1 1];
    B_TSPS = [1 1];
    
elseif (iarch == 5)

    B_PSES = [1 0; 0 0];
    B_PSPS = [1 0; 1 1];
    B_TSPS = [1 1];

elseif (iarch == 6)

    % SERIES HYBRID

    % energy-power  sources
    B_PSES = [1 0 ; 0 1];

    %power -power  sources
    B_PSPS = [1 0 ; 1 1];

    %power -thrust sources
    B_TSPS = [0 1];

elseif (iarch == 7)

    % PARALLEL HYBRID

    % energy-power  sources
    B_PSES = [1 0 ; 0 1];

    % power -power  sources
    B_PSPS = [1 0; 0 1];

    % power -thrust sources
    B_TSPS = [1 1];

elseif (iarch == 8)

    %energy-power  sources
    B_PSES = [1 0 0 0 ;
              1 0 0 0 ;
              0 1 1 0 ;
              0 0 1 1] ;

    %power -power  sources
    B_PSPS = [1 0 1 0 ;
              0 1 0 1 ;
              0 0 1 0 ;
              0 0 0 1];

    %power -thrust sources
    B_TSPS = [1 0 0 0;
              0 1 0 0];

end


%% PLOT THE PROPULSION ARCHITECTURE %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% get the propulsion architecture in a graphical form
architecture = VisualizationPkg.PropulsionArchitecture(B_PSES, B_PSPS, B_TSPS);

% plot the architecture
VisualizationPkg.PlotArchitecture(architecture);

% enlarge the figure
set(gcf, 'Position', get(0, 'Screensize'));

% ----------------------------------------------------------

end