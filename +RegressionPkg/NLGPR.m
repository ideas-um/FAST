function [PostMu,PostVar] = NLGPR(DataStruct,IOSpace,Target,varargin)
%
% [PostMu,PostVar] =  NLGPR(DataStruct,IOspace,Target,varargin)
% Non-Linear Gaussian Process Regression
% Written by Maxfield Arnson
%
% This function predicts aircraft or engine parameters using the IDEAS
% historical database. Given as many known (and relevant) parameters as
% possible, it will return a Gaussian distribution (mean and variance)
% of the queried parameter.
%
%
% INPUTS:
% datastruct = choice of database. ADD NOTES
%    size: 1x1 Struct
%    Common inputs are:
%         {TurbofanAC                  }
%         {TurbofanEngines             }
%         {TurbopropAC                 }
%         {TurbopropEngines            }
%    which are loaded into the workspace when loading the
%    +DatabasePkg/IDEAS_DB.mat file, however other data structures could be
%    used as well, such as the ones from
%    +EngineModelPkg/+SurrogateOffDesignPkg/ICAO_DB.mat
%
%
% IOSpace = OUT OF DATE Input/Output space. Cell array of string arrays with N known parameters
%   and 1 unknown parameter.
%   size: 1x(N+1) cell array
%   options: there are over 1e29 combinations that can be input for
%   IOspace. A tutorial is coming soon and will be available in
%   RegressionPkg.README
%
% Target = quantities of known values for the known parameters.
%    size: DxN array of doubles, where D is the number of sets of known
%    parameters that are being queried.
% varargin
%
%
% OUTPUTS:
% PostMu = Posterior mean estimates for each queried point.
%    size: Dx1 array of doubles
% PostVar = Posterior variance estimates for each queried point.
%    size: Dx1 array of doubles


% Default values for settings
Options.Weights = ones(1,length(IOSpace)-1);
Options.Prior = ones(length(Target),1) .* RegressionPkg.PriorCalculation(DataStruct,IOSpace);
Options.Preprocessing = [];

% Get all possible inputs
OptionNames = fieldnames(Options);

% Loop through optional inputs and overwrite the defaults if user provides
% them
for ii = 1:2:length(varargin)
    name = varargin{ii};
    value = varargin{ii+1};

    if any(strcmpi(name, OptionNames))
        Options.(name) = value;
    else
        error('Regression, unknown setting: %s', name);
    end
end

% Need to check that if iteration variable is set, information needed to
% run the regression is provided
if isempty(Options.Preprocessing)

    % Process the regressions
    % this line is computationally heavy, which is why functionality is
    % built into this file to avoid it being used inside a loop
    [DataMatrix,HyperParams,InverseTerm] =...
        RegressionPkg.RegProcessing(DataStruct,IOSpace, Options.Prior, Options.Weights);

elseif ~isstruct(Options.Preprocessing)

    % error handling if this input is not a structure with the required
    % fields

    error('Regression Settings: Preprocessing requires a structure with matrices defined for the DataMatrix, the HyperParams, and the InverseTerm.')


else % all is well and accept the input

    % assuming no error, pull the preprocessed variables from the input
    DataMatrix  = Options.Preprocessing.DataMatrix ;
    HyperParams = Options.Preprocessing.HyperParams;
    InverseTerm = Options.Preprocessing.InverseTerm;


end

% Initialize Posterior distribution(s)
PostMu = zeros(size(Target,1),1);
PostVar = PostMu;

% I believe there is a way to do this more efficiently but right now I just
% look through each target case. The math inside this is not that
% cumbersome so it goes by pretty quick
for ii = 1:length(PostMu)

    % Get size of data matrix
    NDat = size(DataMatrix,1);

    % replicate target because we want to compare it to every entry in
    % datamatrix
    RepTarget = repmat(Target(ii,:),[NDat,1]);

    % replicate the hyperparameters for the same reason
    RepHyper = repmat(HyperParams,[NDat,1]);

    % compute the covariance term between the data and the target
    Kbarstar = RegressionPkg.SquareExKernel(DataMatrix(:,1:end-1),...
        RepTarget,RepHyper)';

    % compute posterior mean
    PostMu(ii) = Options.Prior(ii) + Kbarstar*InverseTerm*(DataMatrix(:,end) - Options.Prior(ii));

    % compute posterior variance
    PostVar(ii) = RegressionPkg.SquareExKernel(Target(ii,:),Target(ii,:),HyperParams)...
        - Kbarstar*InverseTerm*Kbarstar';

end


end













