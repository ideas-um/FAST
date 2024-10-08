function [PostMu,PostVar] =...
    CreatePosterior(DataMatrix,prior,target,hypers)

PostMu = zeros(size(target,1),1);
PostVar = PostMu;


sig2_prior = (mean(prior)*7.5e-2)^2;

% INVERSE DATA MATRIX
PS = size(DataMatrix,1);
Kbarbar = zeros(PS);
for i = 1:PS
    for j = 1:PS
        Kbarbar(i,j) = RegressionPkg.SquareExKernel(DataMatrix(i,1:end-1),...
            DataMatrix(j,1:end-1),hypers);
    end
end

InverseTerm = inv(Kbarbar + sig2_prior.*eye(PS));




for i = 1:length(PostMu)
[PostMu(i),PostVar(i)] = ...
    RegressionPkg.BuildRegression(DataMatrix,prior(i),target(i,:),hypers,InverseTerm);
end
end