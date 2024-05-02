function  [DataMatrix,Prior,std] = ...
    BuildData(datastruct,IOspace,target,weights,given_prior)
% 
% [DataMatrix,Prior,std] = BuildData(datastruct,class,IOspace,target)
% [DataMatrix,Prior,std] = BuildData(datastruct,class,IOspace,target,weights)
% NLGRP Internal data matrix construction and hyperparameter tuning
% Written by Maxfield Arnson
%
% This function is used by the NLGPR function to create the relevant data
% matrix depending on which parameters are known. Additionally, it creates
% a prior distribution to default to in the case the regression does not
% find relevant regression points. It also tunes the length scales in the
% squared exponential covariance kernel using the IDEAS aircraft database.
%
%
% INPUTS:
%
%
% OUTPUTS:




%% Decide on which database to use
% first if statement chooses whether to load the aircraft or engine mat
% file. The if statement within the Aircraft option concatenates the
% subclasses into a single class that the regression can work with
% depending on whether we have a piston, TP, or TJ

% switch datastruct
%     case "ACDatabase"
%         try
%         load(fullfile("..", "+DatabasesPkg", "ACDatabase.mat"),'ACDatabase')
%         catch
%         load(fullfile("+DatabasesPkg", "ACDatabase.mat"),'ACDatabase')
%         end
%         switch class
%             case "TurboJet"
%                 [small,~] = RegressionPkg.SearchDB(ACDatabase,"Class","20-100 TJ");
%                 [med,~] = RegressionPkg.SearchDB(ACDatabase,"Class","100-250 TJ");
%                 [large,~] = RegressionPkg.SearchDB(ACDatabase,"Class","250-500 TJ");
%                 fsmall = fieldnames(small);
%                 fmed = fieldnames(med);
%                 flarge = fieldnames(large);
%                 for i = 1:length(fsmall)
%                     substruct.(fsmall{i}) = small.(fsmall{i});
%                 end
%                 for i = 1:length(fmed)
%                     substruct.(fmed{i}) = med.(fmed{i});
%                 end
%                 for i = 1:length(flarge)
%                     substruct.(flarge{i}) = large.(flarge{i});
%                 end
%             case "Piston"
%                 [substruct,~] = RegressionPkg.SearchDB(ACDatabase,"Class","Piston<19");
%             case"TurboProp"
%                 [small,~] = RegressionPkg.SearchDB(ACDatabase,"Class","TP<19");
%                 [large,~] = RegressionPkg.SearchDB(ACDatabase,"Class","TP>19");
%                 fsmall = fieldnames(small);
%                 flarge = fieldnames(large);
%                 for i = 1:length(fsmall)
%                     substruct.(fsmall{i}) = small.(fsmall{i});
%                 end
%                 for i = 1:length(flarge)
%                     substruct.(flarge{i}) = large.(flarge{i});
%                 end
%         end
%     case "Engine"
%         load(fullfile("..", "+DatabasesPkg", "Engdatabase.mat"),'Engines')
%         [substruct,~] = RegressionPkg.SearchDB(Engines,"Class",class);
%     otherwise
%         error("Enter valid database.")
% end


%% Calculate Prior
% This section creates prior distributions for each queried point. It
% simply finds the mean of the target parameter and assigns it to a Dx1
% array, (the same initial guess for every point). The for loop/if statement
% excludes NaN values.

[~,priordata] = RegressionPkg.SearchDB(datastruct,IOspace{end});
priordata = cell2mat(priordata(:,2));
c = 1;

if sum(isnan(priordata)) > 0
for i = 1:length(priordata)
        if isnan(priordata(i))
indexc(c) = i; c = c+1;
        end
end
priordata(indexc) = [];
end

Prior = ones(size(target,1),1).*mean(priordata);

%% Build Data Matrix (OG)
% This section builds a matrix of relevant data depending on the parameters
% that are known for the RegressionPkg.
DataMatrix = [];
for i = 1:length(IOspace)
    [~,IOiMat] = RegressionPkg.SearchDB(datastruct,IOspace{i});
    DataMatrix = [DataMatrix,cell2mat(IOiMat(:,2))];
end



c = 1;
for i = 1:size(DataMatrix,1)
    for j = 1:size(DataMatrix,2)
        if isnan(DataMatrix(i,j))
indexc(c) = i; c = c+1;
        end
    end
end

try
DataMatrix(indexc,:) = [];
catch
end



%% Calculate Parameters for Autotuning
% This section autotunes the length scales used in the squared exponential
% covariance kernel function. Since the function will use automatic
% relevance determination, each parameter will need to be custom tuned. The
% simplest implementation is to adjust each one by the standard deviation
% of its data. This makes sure that if parameter values are on different
% orders of magnitude, each one still contributes equally to the
% predictions
std = zeros(1,length(IOspace));
for i = 1:length(IOspace)
[~,ParameterI] = RegressionPkg.SearchDB(datastruct,IOspace{i});
ParameterI = cell2mat(ParameterI(:,2));
ParameterI=(ParameterI(~isnan(ParameterI))); % Exclude NaNs
std(i) = var(ParameterI);
end

% if weights were prescribed, add additional tuning to the hyperparameters.
switch nargin

    case 5
        weights = weights./sum(weights)*length(weights);
        std(1:end-1) = std(1:end-1)./weights;
        Prior = given_prior;
    case 4
        weights = weights./sum(weights)*length(weights);
        std(1:end-1) = std(1:end-1)./weights;
end
