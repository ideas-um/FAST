clear; clc; close all;


load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))


[Training,~] = RegressionPkg.SearchDB(TurbofanAC,["Settings","DataTypeValidation"],"Training");
[Validation,~] = RegressionPkg.SearchDB(TurbofanAC,["Settings","DataTypeValidation"],"Validation");




[~,X] = RegressionPkg.SearchDB(Validation,["Specs","Weight","MTOW"]);
X = cell2mat(X(:,2));

[~,Ytrue] = RegressionPkg.SearchDB(Validation,["Specs","Weight","OEW"]);
Ytrue = cell2mat(Ytrue(:,2));


[Ypredicted,~] = RegressionPkg.NLGPR(Training,{["Specs","Weight","MTOW"],["Specs","Weight","OEW"]},X)


figure(1)

subplot(1,2,1)
scatter(Ytrue,Ypredicted)
hold on
plot([0,2e5],[0,2e5])
grid on
axis square

subplot(1,2,2)
scatter(Ytrue,(Ypredicted-Ytrue)./Ytrue.*100)
grid on
axis square
%%
clc; clear; close all;

load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

X = linspace(0,3e5)';


[Ypredicted,~] = RegressionPkg.NLGPR(TurbofanAC,{["Specs","Weight","MTOW"],["Specs","Weight","OEW"]},X);


plot(X,Ypredicted)


p = polyfit(X,Ypredicted,1);

ypoly = polyval(p,X);
hold on
plot(X,ypoly)










