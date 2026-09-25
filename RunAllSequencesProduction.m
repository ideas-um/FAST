% Production launcher for the resumable all-sequence optimization.

diary("AllSequences_FuelOpt_150kW.log");
DiaryCleanup = onCleanup(@() diary("off"));

NumWorkers = 8;
MaxIterations = 5;
AggregateMetrics = RunAllSequencePowerOptParallel( ...
    NumWorkers, MaxIterations);

