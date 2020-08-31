% Scalability experiment for MoDE
disp('Running...');
num_points = [];
iters = [];
errors = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Options
options.knn = 20; %# NNs for kNNG
options.MaxIter = 1000000; % Max # iterations for gradient method
options.use_same_LB_UB = 0; % Use midpoint as both lb/ub
options.Rseval = 'angle';
options.data = "eeg.mat";
options.num_run_per_experiment = 1;
disp('Experiment for the following options:');
disp(options)

dataframe = load(join(["data/", options.data], ""));

% load distance and correlation matrices
DM_LB_full = load("compressed_dist_matrices/eeg_DM_LB.mat", "DM_LB");
DM_UB_full = load("compressed_dist_matrices/eeg_DM_UB.mat", "DM_UB");
CM_LB_full = load("compressed_dist_matrices/eeg_CM_LB.mat", "CM_LB");
CM_UB_full = load("compressed_dist_matrices/eeg_CM_UB.mat", "CM_UB");

for N = 1000:1000:11000
    options.num_data_points = N;
    options.Precision = 10^(-4); % Tolerance for gradient method
    fprintf("number of data points: %d", N);
    num_iterations = 0;
    for k = 1:options.num_run_per_experiment
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        data = dataframe.StockData(1:options.num_data_points, :);
        score = dataframe.Score(1:options.num_data_points, :);

        % addpath('./distances') % processing
        % addpath('./waterfill') % bounds
        % addpath('./cv') % our algo
        % addpath(genpath('./baselines')) %isomap, lle, etc
        % addpath('./data') % datasets

        % keep num data points
        DM_LB = DM_LB_full.DM_LB(1:options.num_data_points, 1:options.num_data_points);
        DM_UB = DM_UB_full.DM_UB(1:options.num_data_points, 1:options.num_data_points);
        CM_LB = CM_LB_full.CM_LB(1:options.num_data_points, 1:options.num_data_points);
        CM_UB = CM_UB_full.CM_UB(1:options.num_data_points, 1:options.num_data_points);

        tStart = tic; % start timer


        D_orig = L2_distance2(data', data',1); % use L2_distance in absence of
                                               % statistics toolbox (pdist)


        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% MoDE
        [X_2d, error_progression, DM_average] =  modified_CV(data,score,options.knn, ...
                                                            options.MaxIter, ...
                                                            options.Precision, ...
                                                            DM_LB, DM_UB, CM_LB, CM_UB);


        [Rs, Rd, Rc, Rd_full, R_order] = MetricResultCalculation(data,X_2d,score,options.knn,'Gd', D_orig, options.Rseval);

        % Definition of function
        % plot_metrics(Rc, Rd, Rd_full, Rs, R_order, method_name)
        plot_metrics(Rc, Rd, Rd_full, Rs, R_order, 'CV');

        s = size(error_progression);
        num_iterations = num_iterations +  s(2); % number of iterations of DLS gradient algorithm
    end
num_points = [num_points, N];
iters = [iters, num_iterations / options.num_run_per_experiment];
errors = [errors, error_progression(end)];
% save the results
save("num_points", "num_points");
save("iterations", "iters");
save("errors", "errors");
end
