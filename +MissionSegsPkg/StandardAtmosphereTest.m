function [] = StandardAtmosphereTest()
%
% StandardAtmosphereTest.m
% written by Paul Mokotoff, prmoko@umich.edu
% last updated: 22 dec 2023
%
% compare matlab's "atmosisa" function with other lab-written functions to
% ensure that they are viable replacements for matlab's version.
%
% inputs : none
% outputs: none
%

% initial cleanup
clc, close all


%% ARRAY INITIALIZATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% number of altitudes
nalt = 1e+6;

% array of altitudes [m]
Alt = linspace(0, 20e+3, nalt)';


%% COMPARE THE FUNCTIONS %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% matlab's atmosisa function %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% matlab's version
[MatT, ~, MatP, MatRho] = atmosisa(Alt);

% transpose matlab's results
MatT   = MatT'  ;
MatP   = MatP'  ;
MatRho = MatRho';

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% max's verison with the US  %
% standard atmosphere model  %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max's version
[MaxT, MaxP, MaxRho] = MissionSegsPkg.StdAtmMax(Alt);

% compute the maximum relative error for each array element
MaxRelErrT   = abs(MatT   - MaxT  ) ./ MatT  ;
MaxRelErrP   = abs(MatP   - MaxP  ) ./ MatP  ;
MaxRelErrRho = abs(MatRho - MaxRho) ./ MatRho;

% print the maximum relative error from each quantity
fprintf(1, "Maximum Relative Errors (Max): \n"             );
fprintf(1, "    Temperature: %.6e%%  \n", max(MaxRelErrT  ));
fprintf(1, "       Pressure: %.6e%%  \n", max(MaxRelErrP  ));
fprintf(1, "        Density: %.6e%%\n\n", max(MaxRelErrRho));

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% paul's version with the    %
% standard atmosphere from   %
% anderson's intro to flight %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% paul's version
[PrmT, PrmP, PrmRho] = MissionSegsPkg.StdAtmPRM(Alt);

% compute the maximum relative error for each array element
PrmRelErrT   = abs(MatT   - PrmT  ) ./ MatT  ;
PrmRelErrP   = abs(MatP   - PrmP  ) ./ MatP  ;
PrmRelErrRho = abs(MatRho - PrmRho) ./ MatRho;

% print the maximum relative error from each quantity
fprintf(1, "Maximum Relative Errors (PRM): \n"             );
fprintf(1, "    Temperature: %.6e%%  \n", max(PrmRelErrT  ));
fprintf(1, "       Pressure: %.6e%%  \n", max(PrmRelErrP  ));
fprintf(1, "        Density: %.6e%%\n\n", max(PrmRelErrRho));

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% vectorized version with    %
% max's standard atmosphere  %
% model & paul's vectorizing %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% vectorized version
[VecT, VecP, VecRho] = MissionSegsPkg.StdAtm(Alt);

% compute the maximum relative error for each array element
VecRelErrT   = abs(MatT   - VecT  ) ./ MatT  ;
VecRelErrP   = abs(MatP   - VecP  ) ./ MatP  ;
VecRelErrRho = abs(MatRho - VecRho) ./ MatRho;

% print the maximum relative error from each quantity
fprintf(1, "Maximum Relative Errors (Vec): \n"             );
fprintf(1, "    Temperature: %.6e%%  \n", max(VecRelErrT  ));
fprintf(1, "       Pressure: %.6e%%  \n", max(VecRelErrP  ));
fprintf(1, "        Density: %.6e%%\n\n", max(VecRelErrRho));


%% PLOT THE relative error %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% figure initialization      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% create a figure
figure;

% maximize it
set(gcf, 'Position', get(0, 'Screensize'));

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% temperature distribution   %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize the subplot
subplot(2, 2, 1);

% allow for multiple plots
hold on

% format the plot
title("Temperature Distribution");
xlabel("Altitude (m)");
ylabel("Common Log of Relative Error");
grid on

% plot the temperature distribution
plot(Alt, log10(MaxRelErrT), '-' , 'LineWidth', 4, 'Color', 'black');
plot(Alt, log10(PrmRelErrT), ':' , 'LineWidth', 4, 'Color', 'blue' );
plot(Alt, log10(VecRelErrT), '--', 'LineWidth', 4, 'Color', 'red'  );

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% pressure distribution      %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize the subplot
subplot(2, 2, 3);

% allow for multiple plots
hold on

% format the plot
title("Pressure Distribution");
xlabel("Altitude (m)");
ylabel("Common Log of Relative Error");
grid on

% plot the temperature distribution
plot(Alt, log10(MaxRelErrP), '-' , 'LineWidth', 4, 'Color', 'black');
plot(Alt, log10(PrmRelErrP), ':' , 'LineWidth', 4, 'Color', 'blue' );
plot(Alt, log10(VecRelErrP), '--', 'LineWidth', 4, 'Color', 'red'  );

% ----------------------------------------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                            %
% density distribution       %
%                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize the subplot
subplot(2, 2, 4);

% allow for multiple plots
hold on

% format the plot
title("Density Distribution");
xlabel("Altitude (m)");
ylabel("Common Log of Relative Error");
grid on

% plot the temperature distribution
plot(Alt, log10(MaxRelErrRho), '-' , 'LineWidth', 4, 'Color', 'black');
plot(Alt, log10(PrmRelErrRho), ':' , 'LineWidth', 4, 'Color', 'blue' );
plot(Alt, log10(VecRelErrRho), '--', 'LineWidth', 4, 'Color', 'red'  );

% ----------------------------------------------------------

end