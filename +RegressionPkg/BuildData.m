function  [DataMatrix,HyperParams] = ...
    BuildData(datastruct,IOspace,weights)
%
% [DataMatrix,Prior,HyperParams] = BuildData(datastruct,class,IOspace,target)
% [DataMatrix,Prior,HyperParams] = BuildData(datastruct,class,IOspace,target,weights)
% [DataMatrix,Prior,HyperParams] = BuildData(datastruct,class,IOspace,target,weights,givenprior)
%
% Written by Maxfield Arnson, marnson@umich.edu
% last updated: 3 May 2024
%
% This function is used by the NLGPR function to create the relevant data
% matrix depending on which parameters are known. Additionally, it creates
% a prior distribution to default to in the case the regression does not
% find relevant regression points. It also tunes the length scales in the
% squared exponential covariance kernel using the IDEAS aircraft database.
%
%
% INPUTS:
%     datastruct    - variable passed into the function by NLGPR(). It
%                     contains a historical database structure.
%                     size/type/units: 1-by-1 / structure / []
%
%     IOspace       - cell array where each entry is a string array carrying
%                     the structure path to each of the inputs. These
%                     structure paths are listed in the read me for this
%                     package: RegressionPkg.NLGPR. The last entry in this
%                     cell array is the path for the desired output. N is
%                     the number of inputs
%                     size/type/units: 1-by-N+1 / cell array / []
%
%     target        - values of each of the inputs. This is a matrix of
%                     doubles where N is still the number of inputs and D
%                     is the number of queried points the regression will
%                     estimate an output for. Each row of the matrix is a
%                     unique target point and each column in that row
%                     should hold a numerical value for the inputs listed
%                     in IOspace in the same order.
%                     size/type/units: D-by-N / double / []
%
%     weights       - [OPTIONAL] tuning parameters which can be used to
%                     change the impact each input has on the output. The
%                     default is that each input is weighted equally. The
%                     entered weights do not need to sum to a specific
%                     number. They are all normalized by the sum of the
%                     weights. Entering [2, 1] is the same as  entering [1,
%                     0.5] for a regression using two inputs.
%                     size/type/units: 1-by-N / double / []
%
%     given_prior   - [OPTIONAL] value(s) to use as a guess for the desired output.
%                     For example, a physical model may be used to inform
%                     the output of the regression. Each row in target
%                     needs a guess. The default value for a prior is the
%                     average of the data for the output parameter.
%                     size/type/units: D-by-1 / double / []
%
%
% OUTPUTS:
%     DataMatrix    - This is a large matrix which holds all of the
%                     recorded data relevant to the input and output
%                     parameters. Its size will vary depending on how much
%                     data is stored in the historical database.
%                     size/type/units: variable / double / []
%
%     Prior         - This is the prior guess for all queried target
%                     points. If a prior was provided as an input it simply
%                     returns the input, otherwise it returns its default
%                     value: the average of the data for the output
%                     parameter/
%                     size/type/units: D-by-1 / double / []
%
%     HyperParams   - These are tuning parameters for each of the inputs
%                     and the output, which are used in the regression. If
%                     weights were given as inputs, they modify the values
%                     in HyperParams.
%                     size/type/units: 1-by-N+1 / double / []
%

% ----------------------------------------------------------



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

HyperParams = zeros(1,length(IOspace));
for i = 1:length(IOspace)
    [~,ParameterI] = RegressionPkg.SearchDB(datastruct,IOspace{i});
    ParameterI = cell2mat(ParameterI(:,2));
    ParameterI=(ParameterI(~isnan(ParameterI))); % Exclude NaNs
    HyperParams(i) = var(ParameterI);
end


weights = weights./sum(weights)*length(weights);
HyperParams(1:end-1) = HyperParams(1:end-1)./weights;

end








