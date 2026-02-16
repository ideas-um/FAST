function [DataMatrix,HyperParams,InverseTerm] =...
    RegProcessing(Datastruct,IOSpace,Prior,Weights)
%
% [DataMatrix,HyperParams,InverseTerm] = RegProcessing(Datastruct,IOSpace,Prior,Weights)
%
% Written by Maxfield Arnson, marnson@umich.edu
% last updated: 13 March 2025
%
% This function is used by the NLGPR function to create the relevant data
% matrix depending on which parameters are known. Additionally, it creates
% a prior distribution to default to in the case the regression does not
% find relevant regression points. It also tunes the length scales in the
% squared exponential covariance kernel using the IDEAS aircraft database.
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
%     Prior         - value(s) to use as a guess for the desired output.
%                     For example, a physical model may be used to inform
%                     the output of the regression. Each row in target
%                     needs a guess. The default value for a prior is the
%                     average of the data for the output parameter.
%                     size/type/units: D-by-1 / double / []
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
%     InverseTerm   - This is a large matrix which has been created by
%                     inverting the noise augmented covariance matrix from
%                     the database. The point of this term is to allow it
%                     to be precomputed for known regressions outside of
%                     any sizing loops. It has k by k entries where k is
%                     the number of aircraft from the aerobase that do not
%                     have any NaN values for the variables in the IOSpace.
%                     size/type/units: k-by-k / double / []
%

% ----------------------------------------------------------

% call the build data function, which will neatly format our desired data
% and return our weighted hyperparameters too.
[DataMatrix,HyperParams] = ...
    RegressionPkg.BuildData(Datastruct,IOSpace,Weights);

% set a "noise variance"
% This is arbitrary and can be considered a tuning parameter. It represents
% the trust in the collected data. The value here is set to 5% of the mean
% of the data, meaning that we believe any data collected and used in the
% regressions has an error standard deviatio equal to 5% of the mean
NoiseVariance = (mean(Prior)*5e-2)^2;

% get size of non-NaN data
PS = size(DataMatrix,1);

% initialize the kbarbar term, which maps the data to itself
Kbarbar = zeros(PS);

% for each aircraft in the database, we compare it to every other aircraft.
% this is done with a basis function. FAST uses the radial basis function,
% also called the squared exponential kernel
for i = 1:PS
    for j = 1:PS
        Kbarbar(i,j) = RegressionPkg.SquareExKernel(DataMatrix(i,1:end-1),...
            DataMatrix(j,1:end-1),HyperParams);
    end
end

% Invert the data augmented with the noise variance. This prevents poor
% scaling and introduces our distrust of any data collection (as it may be
% noisy
InverseTerm = inv(Kbarbar + NoiseVariance.*eye(PS));


end