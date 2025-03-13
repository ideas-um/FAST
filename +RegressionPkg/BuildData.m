function  [DataMatrix,HyperParams] = BuildData(DataStruct,IOSpace,Weights)
%
% [DataMatrix,HyperParams] = BuildData(Datastruct,IOspace,Weights)
%
% Written by Maxfield Arnson, marnson@umich.edu
% last updated: 13 March 2025
%
% This function is used by the RegProcessing() function to create the relevant data
% matrix depending on which parameters are known. It also tunes the length 
% scales in the squared exponential covariance kernel using the IDEAS 
% Aerobase, applying any user specified weights.
%
%
% INPUTS:
%     DataStruct    - variable passed into the function by NLGPR(). It
%                     contains a historical database structure.
%                     size/type/units: 1-by-1 / structure / []
%
%     IOSpace       - cell array where each entry is a string array carrying
%                     the structure path to each of the inputs. These
%                     structure paths are listed in the read me for this
%                     package: RegressionPkg.NLGPR. The last entry in this
%                     cell array is the path for the desired output. N is
%                     the number of inputs
%                     size/type/units: 1-by-N+1 / cell array / []
%
%
%     Weights       - tuning parameters which can be used to
%                     change the impact each input has on the output. The
%                     default is that each input is weighted equally. The
%                     entered weights do not need to sum to a specific
%                     number. They are all normalized by the sum of the
%                     weights. Entering [2, 1] is the same as  entering [1,
%                     0.5] for a regression using two inputs.
%                     size/type/units: 1-by-N / double / []
%
%
%
% OUTPUTS:
%     DataMatrix    - This is a large matrix which holds all of the
%                     recorded data relevant to the input and output
%                     parameters. Its size will vary depending on how much
%                     data is stored in the historical database.
%                     size/type/units: variable / double / []
%
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

% Initialize to an empty matrix
DataMatrix = [];

% for each parameter, build a column in the matrix with the values from
% every aircraft in the FAST Aerobase
for i = 1:length(IOSpace)
    
    % Pull out the parameter cell array
    [~,IOiMat] = RegressionPkg.SearchDB(DataStruct,IOSpace{i});

    % add a column, make sure to convert returned cell to a double
    % first column of IOiMat is AC name, we want the parameter value
    DataMatrix = [DataMatrix,cell2mat(IOiMat(:,2))];
end


% The following nested for loop goes through the matrix and notes the row
% index of every where that h
c = 1;
for i = 1:size(DataMatrix,1)
    for j = 1:size(DataMatrix,2)
        if isnan(DataMatrix(i,j))
            indexc(c) = i; c = c+1;
        end
    end
end


% in the case that there were no NaN entries, this try statement just
% ensures an error is not thrown. otherwise this sets all the rows with NaN
% entries to empty, removing them from the data matrix
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

% initialize the hyperparemeters
HyperParams = zeros(1,length(IOSpace));

% loop through each parameter and get the variance for hyperparameters. the
% reason we dont just take the variance of each column of datamatrix is
% because that calculation eliminates every row that has empty values, so
% there may be some cross-elimination that is undesirable for individual
% parameters
for i = 1:length(IOSpace)
    [~,ParameterI] = RegressionPkg.SearchDB(DataStruct,IOSpace{i});
    ParameterI = cell2mat(ParameterI(:,2));
    ParameterI=(ParameterI(~isnan(ParameterI))); % Exclude NaNs
    HyperParams(i) = var(ParameterI);
end

% Augment weights such that they are always scaled by the sum of their
% total. This enforces that they cannot affect the absolute scale of the
% regresison prediction. i.e. weights of [1, 2] are the same as [2, 4] for
% a two input regression
Weights = Weights./sum(Weights)*length(Weights);

% Weight the hyperparameters 
HyperParams(1:end-1) = HyperParams(1:end-1)./Weights;

end








