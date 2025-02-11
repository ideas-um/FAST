function [DataMatrix,HyperParams,InverseTerm] =...
    RegProcessing(datastruct,IOspace,Prior,Weights)


[DataMatrix,HyperParams] = ...
    RegressionPkg.BuildData(datastruct,IOspace,Weights);


sig2_prior = (mean(Prior)*5e-2)^2;

% INVERSE DATA MATRIX
PS = size(DataMatrix,1);
Kbarbar = zeros(PS);
for i = 1:PS
    for j = 1:PS
        Kbarbar(i,j) = RegressionPkg.SquareExKernel(DataMatrix(i,1:end-1),...
            DataMatrix(j,1:end-1),HyperParams);
    end
end

InverseTerm = inv(Kbarbar + sig2_prior.*eye(PS));




end