clc; clear; close all;


N = 10;
M = linspace(0.75,0.855,N);
AvgLD = zeros(1,N);
STDs = zeros(1,N);



for ii = 1:N
DatabasePkg.InitializeDatabase(M(ii))
load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

[~,LD] = RegressionPkg.SearchDB(TurbofanAC,["Specs","Aero","L_D","CrsMAC"]);
LD = cell2mat(LD(:,2));

ind = [];

for jj = 1:length(LD)
    if isnan(LD(jj))
        ind = [ind,jj];
    end
end
LD(ind) = [];


AvgLD(ii) = mean(LD);
STDs(ii) = sqrt(var(LD));
end

%%
close all
plot(M,AvgLD,'b')
hold on
scatter(M,AvgLD,'bo','filled')
grid on
xlabel('Assumed Cruise Mach Number')
ylabel('Average L/D at Cruise')

top = AvgLD + 2*STDs;
bottom = AvgLD - 2*STDs;

fill([M, fliplr(M)],[bottom, fliplr(top)],'r','FaceAlpha',0.2,'EdgeColor','none')
legend('Mean','','\pm 2\sigma')


%%

load(fullfile("+DatabasePkg", "IDEAS_DB.mat"))

[~,LD] = RegressionPkg.SearchDB(TurbofanAC,["Specs","Aero","L_D","CrsMAC"]);