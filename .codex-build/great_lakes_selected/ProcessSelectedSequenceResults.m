function Results = ProcessSelectedSequenceResults()
%PROCESSSELECTEDSEQUENCERESULTS Build combined and paper-ready run outputs.

Combined = CollectSelectedSequenceResults();
ResultsRoot = string(getenv("FAST_GL_RESULTS_DIR"));
if strlength(ResultsRoot) == 0
    error("GreatLakes:MissingEnvironment", ...
        "Required environment variable FAST_GL_RESULTS_DIR is not set.");
end
MaxIterations = str2double(getenv("FAST_GL_MAX_ITERATIONS"));
if ~isfinite(MaxIterations) || MaxIterations < 1
    MaxIterations = 500;
end
Paper = HEAOpsPaperResults(char(ResultsRoot), ...
    "ExpectedIndices", Combined.SelectedSequenceIndices, ...
    "MaxIterations", MaxIterations);
Results = struct("Combined", Combined, "Paper", Paper, ...
    "Generated", string(datetime("now")));
save(fullfile(char(ResultsRoot), "combined", ...
    "SelectedSequences_ProcessedResults.mat"), "Results", "-v7.3");
end
