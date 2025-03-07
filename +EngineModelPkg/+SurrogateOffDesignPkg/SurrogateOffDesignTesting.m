

clc; clear; close all;

load(fullfile("+EngineModelPkg", "+SurrogateOffDesignPkg","ICAO_DATA.mat"))

%% Create Targets



[~,KnownCffch] = RegressionPkg.SearchDB(ICAO_Known_Cffch,["Cffch"]);
KnownCffch = cell2mat(KnownCffch(:,2));
AvgCffch = ones(32,1).*mean(KnownCffch);
ErrorReg = zeros(1,32);

w = [2 1 1];

for ii = 1:32

    [CurStruct,Target] = RemoveN(ICAO_Known_Cffch,ii);


    IOSpace = {["Thrust"],["OPR"],["BPR"],["Cffch"]};

    PredictedCffch = RegressionPkg.NLGPR(CurStruct,IOSpace,Target,"Weights",w);
    ErrorReg(ii) = (PredictedCffch - KnownCffch(ii))./ KnownCffch(ii)*100;
end


ErrorMean = (AvgCffch - KnownCffch)./KnownCffch.*100;




figure(1)

subplot(1,2,1)
scatter(KnownCffch,ErrorMean,'b')
grid on
axis([4e-7 8e-7 -100 100])

subplot(1,2,2)
scatter(KnownCffch,ErrorReg,'r')
grid on
axis([4e-7 8e-7 -100 100])


%%
Regnames = ["Avg Cffch";"Regression"];
Emeans = [mean(ErrorMean);mean(ErrorReg)];
Emeds = [median(ErrorMean);median(ErrorReg)];
Estds =  [ std(ErrorMean);std(ErrorReg)];
Eskew =  [ skewness(ErrorMean);skewness(ErrorReg)];
Ekurt =  [ kurtosis(ErrorMean);kurtosis(ErrorReg)];
L2Tab = table(Regnames,Emeans,Emeds,Estds,Eskew,Ekurt,'VariableNames',["Regression","Mean","Median","Std. Dev.","Skew","Kurtosis"]);

L2Tab





function [NewStruct,Target] = RemoveN(Struct,N)

% Get field names of structure
names = fieldnames(Struct);
NewStruct = rmfield(Struct,names{N});

Target = [Struct.(names{N}).Thrust,Struct.(names{N}).OPR,Struct.(names{N}).BPR];



end





