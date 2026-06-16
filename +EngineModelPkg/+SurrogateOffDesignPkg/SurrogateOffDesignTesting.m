%% Header and Initialization
% This script uses the ICAO databases to generate graphs comparing the FAST
% regression package to the previously used method of taking the average
% cff if it is unknown for an engine

clc; clear; close all;

% Load databases
load(fullfile("+EngineModelPkg", "+SurrogateOffDesignPkg","ICAO_DATA.mat"))

%% Computation for Cffch


% Load Known Cffch from the database
[~,KnownCffch] = RegressionPkg.SearchDB(ICAO_Known_Cffch,["Cffch"]);

% Convert to vector of doubles
KnownCffch = cell2mat(KnownCffch(:,2));

% Compute average Cffch for later use
AvgCffch = ones(32,1).*mean(KnownCffch);

% Initialize Predicted Cffch values
PredictedCffch = zeros(32,1);


tic
for ii = 1:length(KnownCffch)

    % Remove current value from database such that it is not used to train
    % the model
    [CurStruct,Target] = RemoveN(ICAO_Known_Cffch,ii);

    % Set Input output space according to database convention
    IOSpace = {["Thrust"],["OPR"],["BPR"],["Cffch"]};

    % Set weighting of regression parameters
    w = [1 1 1];

    % Run Regression
    PredictedCffch(ii) = RegressionPkg.NLGPR(CurStruct,IOSpace,Target,"Weights",w);


end
toc

% Calculate Regression error
ErrorReg = (PredictedCffch - KnownCffch)./ KnownCffch*100;

% Calculate the Error Using the mean Cffch method
ErrorMean = (AvgCffch - KnownCffch)./KnownCffch.*100;



%% Plotting for Cffch

figure(1) % The Cffch Regression

subplot(1,2,1)
scatter(KnownCffch,ErrorMean,'b')
grid on
axis([4e-7 8e-7 -100 100])
hold on 
yline(0)
legend('C_{ff,ch} = Average from Data')
ylabel('Error [%]')
xlabel('True C_{ff,ch}')

subplot(1,2,2)
scatter(KnownCffch,ErrorReg,'r')
grid on
axis([4e-7 8e-7 -100 100])
hold on 
yline(0)
legend('C_{ff,ch} = Regression')
xlabel('True C_{ff,ch}')


%% Create and display error table

% Set names of the variables
VarNames = ["Regression","Mean","Median","Std. Dev.","Skew","Kurtosis"];

% Set names of the regressions
Regnames = ["Avg Cffch";"Regression"];

% Assign error metrics
Emeans = [mean(ErrorMean);mean(ErrorReg)];
Emeds = [median(ErrorMean);median(ErrorReg)];
Estds =  [ std(ErrorMean);std(ErrorReg)];
Eskew =  [ skewness(ErrorMean);skewness(ErrorReg)];
Ekurt =  [ kurtosis(ErrorMean);kurtosis(ErrorReg)];

% Create table
L2Tab = table(Regnames,Emeans,Emeds,Estds,Eskew,Ekurt,'VariableNames',VarNames);

% display the table
L2Tab

%% Computation for Cff1,2,3

% remove N points from database for testing
rng(3132025)
N = 40;
TestIndex = randi(462,1,40);
names_total = fieldnames(ICAO_Unknown_Cffch);
names_test = names_total(TestIndex);

DataStruct = rmfield(ICAO_Unknown_Cffch,names_test);




% Convert to vectors of doubles
KnownCff1 = zeros(N,1);
KnownCff2 = zeros(N,1);
KnownCff3 = zeros(N,1);


% Initialize targets
Target = zeros(N,3);

% Loop through testing data and assign target points as well as the true Y
% value to compare to our regression output
for ii = 1:N
    Target(ii,:) = [ICAO_Unknown_Cffch.(names_test{ii}).Thrust,...
        ICAO_Unknown_Cffch.(names_test{ii}).OPR,...
        ICAO_Unknown_Cffch.(names_test{ii}).BPR];

    KnownCff1(ii) = ICAO_Unknown_Cffch.(names_test{ii}).Cff1;
    KnownCff2(ii) = ICAO_Unknown_Cffch.(names_test{ii}).Cff2;
    KnownCff3(ii) = ICAO_Unknown_Cffch.(names_test{ii}).Cff3;

end

% Compute average Cff123 for later use
AvgCff1 = ones(N,1).*mean(KnownCff1);
AvgCff2 = ones(N,1).*mean(KnownCff2);
AvgCff3 = ones(N,1).*mean(KnownCff3);


% Set Input output space and run regression for Cff1
IOSpace = {["Thrust"],["OPR"],["BPR"],["Cff1"]};
PredictedCff1 = RegressionPkg.NLGPR(DataStruct,IOSpace,Target);

% Set Input output space and run regression for Cff1
IOSpace = {["Thrust"],["OPR"],["BPR"],["Cff2"]};
PredictedCff2 = RegressionPkg.NLGPR(DataStruct,IOSpace,Target);

% Set Input output space and run regression for Cff1
IOSpace = {["Thrust"],["OPR"],["BPR"],["Cff3"]};
PredictedCff3 = RegressionPkg.NLGPR(DataStruct,IOSpace,Target);



% Calculate Regression error
ErrorReg1 = (PredictedCff1 - KnownCff1)./ KnownCff1*100;
ErrorReg2 = (PredictedCff2 - KnownCff2)./ KnownCff2*100;
ErrorReg3 = (PredictedCff3 - KnownCff3)./ KnownCff3*100;

% Calculate the Error Using the mean Cff123 method
ErrorMean1 = (AvgCff1 - KnownCff1)./KnownCff1.*100;
ErrorMean2 = (AvgCff2 - KnownCff2)./KnownCff2.*100;
ErrorMean3 = (AvgCff3 - KnownCff3)./KnownCff3.*100;

%% Plotting for Cff123

figure(2)

FS = 16

subplot(1,3,1)
scatter(KnownCff1,ErrorMean1,'r')
hold on
scatter(KnownCff1,ErrorReg1,'k')
grid on
%axis([4e-7 8e-7 -100 100])
hold on 
yline(0)
legend('C_{ff,123} = Average from Data','C_{ff,123} = Regression')
ylabel('Error [%]')
xlabel('True C_{ff,1}')
ylim([-100 450])
ax = gca;
ax.FontSize = FS;

subplot(1,3,2)
scatter(KnownCff2,ErrorMean2,'r')
hold on
scatter(KnownCff2,ErrorReg2,'k')
grid on
hold on 
yline(0)
xlabel('True C_{ff,2}')
ylim([-100 450])
ax = gca;
ax.FontSize = FS;

subplot(1,3,3)
scatter(KnownCff3,ErrorMean3,'r')
hold on
scatter(KnownCff3,ErrorReg3,'k')
grid on
hold on 
yline(0)
xlabel('True C_{ff,3}')
ylim([-100 450])

ax = gca;
ax.FontSize = FS;



%% Helper functions


function [NewStruct,Target] = RemoveN(Struct,N)
% Helper function which 
%  1) Removes field N from a struct
%  2) Sets up the regression input using field N


% Get field names of structure
names = fieldnames(Struct);

% Create structure without field N
NewStruct = rmfield(Struct,names{N});

% Create target using field N's values
Target = [Struct.(names{N}).Thrust,Struct.(names{N}).OPR,Struct.(names{N}).BPR];

end % end RemoveN(Struct,N)





