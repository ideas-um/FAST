% Production launcher for all 864 daily sequences on emmacoolPC.
% The run is parallel across sequences and fully resumable by checkpoint.

clearvars;
clc;
OutputDir = fullfile("output", "all_sequences_full_comparison");
if ~isfolder(OutputDir), mkdir(OutputDir); end
diary(fullfile(OutputDir, "AllSequences_Production.log"));
DiaryCleanup = onCleanup(@() diary("off")); %#ok<NASGU>

NumWorkers = 6;
MaxIterations = 500;
Aggregate = RunAllSequencesFullComparisonParallel( ...
    NumWorkers, MaxIterations);
