# Model Comparison Framework Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create comprehensive comparison framework for clinear_curvature, ray_parameter, and Bellhop models, generating publication-quality comparison plots and quantitative analysis.

**Architecture:** Data normalization layer extracts eigenray data from each model into common format → Comparison engine computes metrics and differences → Visualization layer generates multi-panel comparison figures with explanatory annotations.

**Tech Stack:** MATLAB R2025b, Acoustics Toolbox (Bellhop), custom plotting functions

---

## Overview

### Problem Statement
Three models produce eigenray data in different formats:
- **clinear_curvature**: Cell array of structs with (rpath, zpath, tt, theta0, A_at_r, n_surface, n_bottom)
- **ray_parameter**: Arrays (eigenray_times, eigenray_absorption, eigenray_reflection, eigenray_geom_spreading, eigenray_arrival_angle)
- **Bellhop**: Binary output files (.ray, .arr) read via AT toolbox functions

### Comparison Goals
1. **Visual comparison**: Side-by-side ray fans, overlaid impulse responses
2. **Quantitative metrics**: Eigenray count, arrival time differences, amplitude differences
3. **Physical explanation**: Why do models differ? (numerical methods, physics approximations)

---

## Task 1: Data Normalization - Create Eigenray Extraction Functions

**Files:**
- Create: `utils/extract_eigenrays_clinear.m`
- Create: `utils/extract_eigenrays_rayparam.m`
- Create: `utils/extract_eigenrays_bellhop.m`
- Create: `utils/EigenrayData.m` (class definition)

### Step 1: Define common eigenray data structure

Create: `utils/EigenrayData.m`

```matlab
classdef EigenrayData
    % Common eigenray data format for all models
    properties
        model_name          % string: 'clinear', 'rayparam', 'bellhop'
        n_eigenrays         % int: number of eigenrays
        launch_angles       % array [n_eigenrays x 1]: degrees
        arrival_times       % array [n_eigenrays x 1]: seconds
        arrival_angles      % array [n_eigenrays x 1]: degrees (NaN if not available)
        amplitudes_dB       % array [n_eigenrays x 1]: dB
        path_lengths        % array [n_eigenrays x 1]: meters
        n_surface_bounces   % array [n_eigenrays x 1]: int
        n_bottom_bounces    % array [n_eigenrays x 1]: int
        ray_paths           % cell array [n_eigenrays x 1]: {[N x 2] matrices of (r,z)}

        % Metadata
        source_depth        % meters
        source_range        % meters
        receiver_depth      % meters
        receiver_range      % meters
        frequency           % Hz
    end

    methods
        function obj = EigenrayData(model_name)
            obj.model_name = model_name;
        end

        function summary(obj)
            fprintf('=== %s MODEL ===\n', upper(obj.model_name));
            fprintf('Eigenrays found: %d\n', obj.n_eigenrays);
            fprintf('Launch angles: %.2f° to %.2f°\n', min(obj.launch_angles), max(obj.launch_angles));
            fprintf('Arrival times: %.2f s to %.2f s\n', min(obj.arrival_times), max(obj.arrival_times));
            fprintf('Amplitudes: %.2f dB to %.2f dB\n', min(obj.amplitudes_dB), max(obj.amplitudes_dB));
            fprintf('Bounce patterns: %dB/%dS to %dB/%dS\n', ...
                min(obj.n_bottom_bounces), min(obj.n_surface_bounces), ...
                max(obj.n_bottom_bounces), max(obj.n_surface_bounces));
        end
    end
end
```

### Step 2: Implement clinear_curvature extractor

Create: `utils/extract_eigenrays_clinear.m`

```matlab
function eig_data = extract_eigenrays_clinear(eigenrays, params)
    % Extract eigenray data from clinear_curvature output
    %
    % Inputs:
    %   eigenrays: cell array from clinear_curvature
    %   params: struct with (z_s, r_s, z_rec, r_rec, f)
    %
    % Output:
    %   eig_data: EigenrayData object

    eig_data = EigenrayData('clinear_curvature');

    n = length(eigenrays);
    eig_data.n_eigenrays = n;

    % Preallocate arrays
    eig_data.launch_angles = zeros(n, 1);
    eig_data.arrival_times = zeros(n, 1);
    eig_data.arrival_angles = nan(n, 1); % not computed in clinear
    eig_data.amplitudes_dB = zeros(n, 1);
    eig_data.path_lengths = zeros(n, 1);
    eig_data.n_surface_bounces = zeros(n, 1);
    eig_data.n_bottom_bounces = zeros(n, 1);
    eig_data.ray_paths = cell(n, 1);

    % Extract data from each eigenray
    for i = 1:n
        er = eigenrays{i};
        eig_data.launch_angles(i) = rad2deg(er.theta0);
        eig_data.arrival_times(i) = er.t_at_r;
        eig_data.amplitudes_dB(i) = 20*log10(abs(er.A_at_r));
        eig_data.path_lengths(i) = er.path_len;
        eig_data.n_surface_bounces(i) = er.n_surface;
        eig_data.n_bottom_bounces(i) = er.n_bottom;

        % Extract ray path (remove NaNs)
        finite_idx = ~isnan(er.rpath);
        eig_data.ray_paths{i} = [er.rpath(finite_idx)', er.zpath(finite_idx)'];
    end

    % Metadata
    eig_data.source_depth = params.z_s;
    eig_data.source_range = params.r_s;
    eig_data.receiver_depth = params.z_rec;
    eig_data.receiver_range = params.r_rec;
    eig_data.frequency = params.f;
end
```

### Step 3: Implement ray_parameter extractor

Create: `utils/extract_eigenrays_rayparam.m`

```matlab
function eig_data = extract_eigenrays_rayparam(eigenrays, eigenray_times, ...
    eigenray_absorption, eigenray_reflection, eigenray_geom_spreading, ...
    eigenray_arrival_angle, source_angles, params)
    % Extract eigenray data from ray_parameter output

    eig_data = EigenrayData('ray_parameter');

    n = length(eigenrays);
    eig_data.n_eigenrays = n;

    % Direct assignment (already in arrays)
    eig_data.launch_angles = source_angles; % need to pass this in
    eig_data.arrival_times = eigenray_times';
    eig_data.arrival_angles = eigenray_arrival_angle';

    % Compute total amplitude in dB
    A_total = eigenray_geom_spreading .* eigenray_absorption .* eigenray_reflection;
    eig_data.amplitudes_dB = 20*log10(abs(A_total))';

    % Path lengths (need to compute from eigenrays)
    eig_data.path_lengths = zeros(n, 1);
    eig_data.ray_paths = cell(n, 1);
    for i = 1:n
        ray = eigenrays{i};
        eig_data.ray_paths{i} = ray; % already [N x 2]
        % Compute path length
        dr = diff(ray(:,1));
        dz = diff(ray(:,2));
        eig_data.path_lengths(i) = sum(sqrt(dr.^2 + dz.^2));
    end

    % Bounce counts (need to extract from trace_ray output)
    % This requires modifying ray_parameter.m to store bounce info
    % For now, set to NaN
    eig_data.n_surface_bounces = nan(n, 1);
    eig_data.n_bottom_bounces = nan(n, 1);

    % Metadata
    eig_data.source_depth = params.source_depth;
    eig_data.source_range = 0;
    eig_data.receiver_depth = params.receiver_depth;
    eig_data.receiver_range = params.receiver_rng;
    eig_data.frequency = params.freq;
end
```

### Step 4: Implement Bellhop extractor

Create: `utils/extract_eigenrays_bellhop.m`

```matlab
function eig_data = extract_eigenrays_bellhop(scenario_file, output_prefix)
    % Extract eigenray data from Bellhop output files
    %
    % Inputs:
    %   scenario_file: path to .env file
    %   output_prefix: e.g., 'scenario' (reads scenario.ray, scenario.arr)
    %
    % Output:
    %   eig_data: EigenrayData object

    eig_data = EigenrayData('bellhop');

    % Read Bellhop output using AT functions
    % Note: Bellhop eigenray output is in .ray file
    ray_file = [output_prefix '.ray'];

    if ~exist(ray_file, 'file')
        error('Bellhop output file not found: %s', ray_file);
    end

    % Use AT toolbox function to read rays
    % plotray expects global variables set by bellhop
    % We need to manually parse the .ray file

    % Read .ray file (binary format)
    fid = fopen(ray_file, 'r');

    % Header
    Title = fgetl(fid);
    freq = fscanf(fid, '%f', 1);
    Nsx = fscanf(fid, '%i', 1); % number of source depths
    Nsy = fscanf(fid, '%i', 1);
    Nsz = fscanf(fid, '%i', 1);

    % Read source positions
    fgetl(fid); % skip newline
    xs = fscanf(fid, '%f', Nsx);
    ys = fscanf(fid, '%f', Nsy);
    zs = fscanf(fid, '%f', Nsz);

    % Read receiver depth
    Nrd = fscanf(fid, '%i', 1);
    fgetl(fid);
    rd = fscanf(fid, '%f', Nrd);

    % Read number of rays
    Nrays = fscanf(fid, '%i', 1);

    % Preallocate
    eig_data.launch_angles = zeros(Nrays, 1);
    eig_data.arrival_times = [];
    eig_data.arrival_angles = [];
    eig_data.amplitudes_dB = [];
    eig_data.path_lengths = [];
    eig_data.ray_paths = {};
    eig_data.n_surface_bounces = [];
    eig_data.n_bottom_bounces = [];

    eigenray_count = 0;

    % Read each ray
    for iray = 1:Nrays
        alpha0 = fscanf(fid, '%f', 1); % launch angle
        NumTopBnc = fscanf(fid, '%i', 1);
        NumBotBnc = fscanf(fid, '%i', 1);
        Nsteps = fscanf(fid, '%i', 1);

        % Read ray points
        ray_data = fscanf(fid, '%f', [2, Nsteps]); % [r; z]
        ray_path = ray_data';

        % Check if this ray is an eigenray (passes near receiver)
        % In eigenray mode, Bellhop should only output eigenrays
        % So all rays in the file are eigenrays

        eigenray_count = eigenray_count + 1;
        eig_data.launch_angles(eigenray_count) = alpha0;
        eig_data.n_surface_bounces(eigenray_count) = NumTopBnc;
        eig_data.n_bottom_bounces(eigenray_count) = NumBotBnc;
        eig_data.ray_paths{eigenray_count} = ray_path;

        % Compute path length
        dr = diff(ray_path(:,1));
        dz = diff(ray_path(:,2));
        eig_data.path_lengths(eigenray_count) = sum(sqrt(dr.^2 + dz.^2));

        % Compute arrival time (need sound speed profile)
        % For now, approximate
        c_avg = 1500; % m/s
        eig_data.arrival_times(eigenray_count) = eig_data.path_lengths(eigenray_count) / c_avg;

        % Arrival angle (last segment)
        dx = ray_path(end,1) - ray_path(end-1,1);
        dz = ray_path(end,2) - ray_path(end-1,2);
        eig_data.arrival_angles(eigenray_count) = rad2deg(atan2(dz, dx));
    end

    fclose(fid);

    eig_data.n_eigenrays = eigenray_count;

    % Trim arrays
    eig_data.launch_angles = eig_data.launch_angles(1:eigenray_count);
    eig_data.arrival_times = eig_data.arrival_times';
    eig_data.arrival_angles = eig_data.arrival_angles';
    eig_data.path_lengths = eig_data.path_lengths';
    eig_data.n_surface_bounces = eig_data.n_surface_bounces';
    eig_data.n_bottom_bounces = eig_data.n_bottom_bounces';

    % Amplitude: Bellhop doesn't directly give amplitude per eigenray in .ray file
    % Need to read .arr file or use approximate TL
    eig_data.amplitudes_dB = nan(eigenray_count, 1);

    % Metadata from scenario file
    [params] = read_scenario_params(scenario_file);
    eig_data.source_depth = params.z_s;
    eig_data.source_range = params.r_s;
    eig_data.receiver_depth = params.z_rec;
    eig_data.receiver_range = params.r_rec;
    eig_data.frequency = params.freq;
end

function params = read_scenario_params(env_file)
    % Parse key parameters from .env file
    fid = fopen(env_file, 'r');
    fgetl(fid); % title
    params.freq = fscanf(fid, '%f', 1);
    fgetl(fid); fgetl(fid); fgetl(fid);

    % Skip SSP (read until 'A')
    while true
        line = fgetl(fid);
        if contains(line, '''A''')
            break;
        end
    end

    % Source depth
    params.z_s = fscanf(fid, '%f', 1);
    fgetl(fid);

    % Receiver depth
    params.z_rec = fscanf(fid, '%f', 1);
    fgetl(fid);

    % Receiver range
    params.r_rec = fscanf(fid, '%f', 1);
    fgetl(fid);

    params.r_s = 0;
    fclose(fid);
end
```

### Step 5: Test extraction functions

Run: Create test script `test_extraction.m`

```matlab
% Test eigenray extraction
clear; clc;

% Run clinear_curvature (assuming it outputs to workspace)
run('clinear_curvature.m');
params_clin.z_s = 1000; params_clin.r_s = 0;
params_clin.z_rec = 1000; params_clin.r_rec = 100000; params_clin.f = 50;
data_clinear = extract_eigenrays_clinear(eigenrays, params_clin);
data_clinear.summary();

% Run ray_parameter
run('ray_parameter.m');
% ... extract and test

% Run Bellhop
% ... extract and test
```

Expected: Summary output showing eigenray counts and ranges match model outputs

### Step 6: Commit extraction framework

```bash
git add utils/EigenrayData.m utils/extract_eigenrays_*.m
git commit -m "feat: add eigenray data normalization framework

- Common EigenrayData class for all models
- Extractors for clinear, ray_parameter, Bellhop
- Handles different output formats uniformly"
```

---

## Task 2: Comparison Metrics - Quantitative Analysis

**Files:**
- Create: `utils/compare_eigenrays.m`
- Create: `utils/match_eigenrays.m`

### Step 1: Implement eigenray matching algorithm

Create: `utils/match_eigenrays.m`

```matlab
function [matches, unmatched_A, unmatched_B] = match_eigenrays(data_A, data_B, tol_time, tol_bounces)
    % Match eigenrays between two models based on arrival time and bounce pattern
    %
    % Inputs:
    %   data_A, data_B: EigenrayData objects
    %   tol_time: tolerance for arrival time matching (seconds)
    %   tol_bounces: boolean, require exact bounce match
    %
    % Outputs:
    %   matches: struct array with fields (idx_A, idx_B, dt, dA_dB, bounces_A, bounces_B)
    %   unmatched_A: indices in A without match
    %   unmatched_B: indices in B without match

    n_A = data_A.n_eigenrays;
    n_B = data_B.n_eigenrays;

    matched_A = false(n_A, 1);
    matched_B = false(n_B, 1);
    matches = struct('idx_A', {}, 'idx_B', {}, 'dt', {}, 'dA_dB', {}, ...
        'bounces_A', {}, 'bounces_B', {});

    for i = 1:n_A
        t_A = data_A.arrival_times(i);
        b_A = [data_A.n_bottom_bounces(i), data_A.n_surface_bounces(i)];

        % Find candidates in B within time tolerance
        dt = abs(data_B.arrival_times - t_A);
        candidates = find(dt <= tol_time & ~matched_B);

        if tol_bounces
            % Filter by bounce pattern
            for j = candidates'
                b_B = [data_B.n_bottom_bounces(j), data_B.n_surface_bounces(j)];
                if all(b_A == b_B)
                    % Found match
                    match.idx_A = i;
                    match.idx_B = j;
                    match.dt = data_B.arrival_times(j) - t_A;
                    match.dA_dB = data_B.amplitudes_dB(j) - data_A.amplitudes_dB(i);
                    match.bounces_A = sprintf('%dB/%dS', b_A(1), b_A(2));
                    match.bounces_B = sprintf('%dB/%dS', b_B(1), b_B(2));
                    matches(end+1) = match;
                    matched_A(i) = true;
                    matched_B(j) = true;
                    break;
                end
            end
        else
            % Take closest in time
            if ~isempty(candidates)
                [~, best_idx] = min(dt(candidates));
                j = candidates(best_idx);
                b_B = [data_B.n_bottom_bounces(j), data_B.n_surface_bounces(j)];

                match.idx_A = i;
                match.idx_B = j;
                match.dt = data_B.arrival_times(j) - t_A;
                match.dA_dB = data_B.amplitudes_dB(j) - data_A.amplitudes_dB(i);
                match.bounces_A = sprintf('%dB/%dS', b_A(1), b_A(2));
                match.bounces_B = sprintf('%dB/%dS', b_B(1), b_B(2));
                matches(end+1) = match;
                matched_A(i) = true;
                matched_B(j) = true;
            end
        end
    end

    unmatched_A = find(~matched_A);
    unmatched_B = find(~matched_B);
end
```

### Step 2: Implement comparison metrics

Create: `utils/compare_eigenrays.m`

```matlab
function comparison = compare_eigenrays(data_A, data_B, options)
    % Compute comparison metrics between two eigenray datasets
    %
    % Inputs:
    %   data_A, data_B: EigenrayData objects
    %   options: struct with (time_tol, require_bounce_match)
    %
    % Output:
    %   comparison: struct with metrics and matched eigenrays

    arguments
        data_A EigenrayData
        data_B EigenrayData
        options.time_tol = 0.5; % seconds
        options.require_bounce_match = true;
    end

    fprintf('\n=== COMPARING %s vs %s ===\n', ...
        upper(data_A.model_name), upper(data_B.model_name));

    % Match eigenrays
    [matches, unmatched_A, unmatched_B] = match_eigenrays(...
        data_A, data_B, options.time_tol, options.require_bounce_match);

    comparison.data_A = data_A;
    comparison.data_B = data_B;
    comparison.matches = matches;
    comparison.unmatched_A = unmatched_A;
    comparison.unmatched_B = unmatched_B;

    % Summary statistics
    comparison.n_matched = length(matches);
    comparison.n_A_only = length(unmatched_A);
    comparison.n_B_only = length(unmatched_B);

    fprintf('Eigenrays in %s: %d\n', data_A.model_name, data_A.n_eigenrays);
    fprintf('Eigenrays in %s: %d\n', data_B.model_name, data_B.n_eigenrays);
    fprintf('Matched eigenrays: %d\n', comparison.n_matched);
    fprintf('%s only: %d\n', data_A.model_name, comparison.n_A_only);
    fprintf('%s only: %d\n', data_B.model_name, comparison.n_B_only);

    if comparison.n_matched > 0
        % Compute differences for matched eigenrays
        dt = [matches.dt];
        dA = [matches.dA_dB];

        comparison.mean_dt = mean(dt);
        comparison.std_dt = std(dt);
        comparison.max_dt = max(abs(dt));

        comparison.mean_dA = mean(dA);
        comparison.std_dA = std(dA);
        comparison.max_dA = max(abs(dA));

        fprintf('\nTiming differences:\n');
        fprintf('  Mean: %.3f s, Std: %.3f s, Max: %.3f s\n', ...
            comparison.mean_dt, comparison.std_dt, comparison.max_dt);

        fprintf('\nAmplitude differences:\n');
        fprintf('  Mean: %.2f dB, Std: %.2f dB, Max: %.2f dB\n', ...
            comparison.mean_dA, comparison.std_dA, comparison.max_dA);
    end

    fprintf('==============================\n\n');
end
```

### Step 3: Commit comparison functions

```bash
git add utils/match_eigenrays.m utils/compare_eigenrays.m
git commit -m "feat: add eigenray matching and comparison metrics

- Match eigenrays by arrival time and bounce pattern
- Compute quantitative differences (timing, amplitude)
- Summary statistics for matched/unmatched eigenrays"
```

---

## Task 3: Visualization - Comparison Plots

**Files:**
- Create: `utils/plot_ray_fan_comparison.m`
- Create: `utils/plot_impulse_response_comparison.m`
- Create: `utils/plot_eigenray_table.m`

### Step 1: Create ray fan comparison plot

Create: `utils/plot_ray_fan_comparison.m`

```matlab
function fig = plot_ray_fan_comparison(data_clinear, data_rayparam, data_bellhop)
    % Create 3-panel side-by-side ray fan comparison
    %
    % Inputs: EigenrayData objects for each model
    % Output: figure handle

    fig = figure('Position', [100 100 1800 600], 'Color', 'w');

    models = {data_clinear, data_rayparam, data_bellhop};
    titles = {'C-Linear Curvature', 'Ray Parameter (Jacobian)', 'Bellhop'};

    z_max = 8000;
    r_max = 100000;

    for i = 1:3
        subplot(1, 3, i);
        hold on; box on;

        data = models{i};

        % Plot eigenrays
        for j = 1:data.n_eigenrays
            ray = data.ray_paths{j};

            % Color by bounce pattern
            nb = data.n_bottom_bounces(j);
            ns = data.n_surface_bounces(j);
            total_bounces = nb + ns;

            if total_bounces == 0
                color = [0 0.4470 0.7410]; % blue (direct)
            elseif total_bounces == 1
                color = [0.8500 0.3250 0.0980]; % orange (1 bounce)
            elseif total_bounces == 2
                color = [0.9290 0.6940 0.1250]; % yellow (2 bounces)
            else
                color = [0.4940 0.1840 0.5560]; % purple (3+ bounces)
            end

            plot(ray(:,1)/1000, ray(:,2), 'Color', color, 'LineWidth', 1.2);
        end

        % Mark source and receiver
        plot(data.source_range/1000, data.source_depth, 'kp', ...
            'MarkerFaceColor', 'k', 'MarkerSize', 12, 'DisplayName', 'Source');
        plot(data.receiver_range/1000, data.receiver_depth, 'ro', ...
            'MarkerFaceColor', 'r', 'MarkerSize', 10, 'DisplayName', 'Receiver');

        % Boundaries
        plot([0 r_max/1000], [0 0], 'b-', 'LineWidth', 2); % surface
        plot([0 r_max/1000], [z_max z_max], 'Color', [0.6 0.3 0], 'LineWidth', 2); % bottom

        set(gca, 'YDir', 'reverse');
        xlabel('Range (km)');
        ylabel('Depth (m)');
        title(sprintf('%s\\newline%d eigenrays', titles{i}, data.n_eigenrays));
        xlim([0 r_max/1000]);
        ylim([0 z_max+500]);
        grid on;
    end

    sgtitle('Ray Fan Comparison: Three Models', 'FontSize', 14, 'FontWeight', 'bold');
end
```

### Step 2: Create impulse response comparison plot

Create: `utils/plot_impulse_response_comparison.m`

```matlab
function fig = plot_impulse_response_comparison(data_clinear, data_rayparam, data_bellhop)
    % Create overlaid impulse response comparison

    fig = figure('Position', [100 100 1000 600], 'Color', 'w');
    hold on; box on;

    models = {data_clinear, data_rayparam, data_bellhop};
    names = {'C-Linear', 'Ray Param', 'Bellhop'};
    colors = {[0 0.4470 0.7410], [0.8500 0.3250 0.0980], [0.4660 0.6740 0.1880]};
    markers = {'o', 's', '^'};

    % Find global amplitude range
    all_amps = [];
    for i = 1:3
        all_amps = [all_amps; models{i}.amplitudes_dB];
    end
    Amax = max(all_amps);
    Amin = Amax - 80; % 80 dB dynamic range

    % Plot each model
    for i = 1:3
        data = models{i};

        for j = 1:data.n_eigenrays
            t = data.arrival_times(j);
            A = data.amplitudes_dB(j);

            % Skip if below threshold
            if A < Amin
                continue;
            end

            % Stem
            plot([t t], [Amin A], 'Color', colors{i}, 'LineWidth', 1.5);

            % Marker
            plot(t, A, markers{i}, 'Color', colors{i}, ...
                'MarkerFaceColor', colors{i}, 'MarkerSize', 6);
        end
    end

    xlabel('Arrival Time (s)');
    ylabel('Amplitude (dB)');
    title('Impulse Response Comparison');
    legend(names, 'Location', 'best');
    ylim([Amin Amax+5]);
    grid on;
end
```

### Step 3: Create eigenray comparison table plot

Create: `utils/plot_eigenray_table.m`

```matlab
function fig = plot_eigenray_table(comparison_AB, comparison_AC)
    % Create visual table comparing eigenray matches
    %
    % Inputs: comparison structs from compare_eigenrays

    fig = figure('Position', [100 100 1200 800], 'Color', 'w');

    % Create table data
    model_A = comparison_AB.data_A.model_name;
    model_B = comparison_AB.data_B.model_name;
    model_C = comparison_AC.data_B.model_name;

    % Summary table
    data = {
        model_A, comparison_AB.data_A.n_eigenrays, '-', '-';
        model_B, comparison_AB.data_B.n_eigenrays, ...
            sprintf('%.3f ± %.3f s', comparison_AB.mean_dt, comparison_AB.std_dt), ...
            sprintf('%.2f ± %.2f dB', comparison_AB.mean_dA, comparison_AB.std_dA);
        model_C, comparison_AC.data_B.n_eigenrays, ...
            sprintf('%.3f ± %.3f s', comparison_AC.mean_dt, comparison_AC.std_dt), ...
            sprintf('%.2f ± %.2f dB', comparison_AC.mean_dA, comparison_AC.std_dA);
    };

    colNames = {'Model', 'N Eigenrays', sprintf('ΔTime vs %s', model_A), sprintf('ΔAmplitude vs %s', model_A)};

    uitable(fig, 'Data', data, 'ColumnName', colNames, ...
        'Units', 'normalized', 'Position', [0.1 0.5 0.8 0.4], ...
        'FontSize', 12);

    % Add text annotations
    annotation(fig, 'textbox', [0.1 0.85 0.8 0.1], ...
        'String', 'Eigenray Comparison Summary', ...
        'FontSize', 14, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', 'LineStyle', 'none');
end
```

### Step 4: Commit visualization functions

```bash
git add utils/plot_*.m
git commit -m "feat: add comparison visualization functions

- Ray fan side-by-side 3-panel plot
- Overlaid impulse response comparison
- Eigenray match summary table"
```

---

## Task 4: Master Comparison Script

**Files:**
- Create: `generate_comparisons.m`

### Step 1: Create master comparison script

Create: `generate_comparisons.m`

```matlab
%% Master Comparison Script
% Generates all comparison plots and metrics for paper
clear; close all; clc;

fprintf('=== OCEAN ACOUSTICS MODEL COMPARISON ===\n\n');

%% Step 1: Run all models and extract data

fprintf('Step 1: Running models and extracting eigenrays...\n');

% Run clinear_curvature
fprintf('  Running clinear_curvature...\n');
run('clinear_curvature.m');
params_clin.z_s = 1000; params_clin.r_s = 0;
params_clin.z_rec = 1000; params_clin.r_rec = 100000; params_clin.f = 50;
data_clinear = extract_eigenrays_clinear(eigenrays, params_clin);
close all; % close model plots

% Run ray_parameter
fprintf('  Running ray_parameter...\n');
run('ray_parameter.m');
% Extract data (need to modify ray_parameter to return workspace vars)
% For now, assume we can access eigenrays, eigenray_times, etc.
params_ray.source_depth = 1000;
params_ray.receiver_depth = 1000;
params_ray.receiver_rng = 100000;
params_ray.freq = 50;
data_rayparam = extract_eigenrays_rayparam(eigenrays, eigenray_times, ...
    eigenray_absorption, eigenray_reflection, eigenray_geom_spreading, ...
    eigenray_arrival_angle, source_launch_angles, params_ray);
close all;

% Run Bellhop
fprintf('  Running Bellhop...\n');
% Bellhop must be run separately via shell
% For now, assume output files exist
data_bellhop = extract_eigenrays_bellhop('scenario.env', 'scenario');

fprintf('Step 1 complete.\n\n');

%% Step 2: Compute comparisons

fprintf('Step 2: Computing pairwise comparisons...\n');

% Clinear vs Ray Parameter
comp_clin_ray = compare_eigenrays(data_clinear, data_rayparam, ...
    'time_tol', 0.5, 'require_bounce_match', true);

% Clinear vs Bellhop
comp_clin_bell = compare_eigenrays(data_clinear, data_bellhop, ...
    'time_tol', 0.5, 'require_bounce_match', true);

% Ray Parameter vs Bellhop
comp_ray_bell = compare_eigenrays(data_rayparam, data_bellhop, ...
    'time_tol', 0.5, 'require_bounce_match', true);

fprintf('Step 2 complete.\n\n');

%% Step 3: Generate visualizations

fprintf('Step 3: Generating comparison plots...\n');

% Ray fan comparison
fig1 = plot_ray_fan_comparison(data_clinear, data_rayparam, data_bellhop);
saveas(fig1, 'figures/ray_fan_comparison.png');
fprintf('  Saved: figures/ray_fan_comparison.png\n');

% Impulse response comparison
fig2 = plot_impulse_response_comparison(data_clinear, data_rayparam, data_bellhop);
saveas(fig2, 'figures/impulse_response_comparison.png');
fprintf('  Saved: figures/impulse_response_comparison.png\n');

% Eigenray table
fig3 = plot_eigenray_table(comp_clin_ray, comp_clin_bell);
saveas(fig3, 'figures/eigenray_comparison_table.png');
fprintf('  Saved: figures/eigenray_comparison_table.png\n');

fprintf('Step 3 complete.\n\n');

%% Step 4: Generate LaTeX table for paper

fprintf('Step 4: Generating LaTeX table...\n');

fid = fopen('figures/eigenray_table.tex', 'w');
fprintf(fid, '\\begin{table}[h]\n');
fprintf(fid, '\\centering\n');
fprintf(fid, '\\caption{Eigenray Detection and Comparison}\n');
fprintf(fid, '\\begin{tabular}{lccc}\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'Model & N Eigenrays & $\\Delta$Time vs C-Linear (s) & $\\Delta$Amplitude vs C-Linear (dB) \\\\\n');
fprintf(fid, '\\hline\n');
fprintf(fid, 'C-Linear Curvature & %d & --- & --- \\\\\n', data_clinear.n_eigenrays);
fprintf(fid, 'Ray Parameter & %d & $%.3f \\pm %.3f$ & $%.2f \\pm %.2f$ \\\\\n', ...
    data_rayparam.n_eigenrays, comp_clin_ray.mean_dt, comp_clin_ray.std_dt, ...
    comp_clin_ray.mean_dA, comp_clin_ray.std_dA);
fprintf(fid, 'Bellhop & %d & $%.3f \\pm %.3f$ & $%.2f \\pm %.2f$ \\\\\n', ...
    data_bellhop.n_eigenrays, comp_clin_bell.mean_dt, comp_clin_bell.std_dt, ...
    comp_clin_bell.mean_dA, comp_clin_bell.std_dA);
fprintf(fid, '\\hline\n');
fprintf(fid, '\\end{tabular}\n');
fprintf(fid, '\\end{table}\n');
fclose(fid);

fprintf('  Saved: figures/eigenray_table.tex\n');
fprintf('Step 4 complete.\n\n');

fprintf('=== ALL COMPARISONS COMPLETE ===\n');
fprintf('Figures saved to figures/ directory\n');
fprintf('LaTeX table: figures/eigenray_table.tex\n');
```

### Step 2: Create figures directory

```bash
mkdir -p figures
```

### Step 3: Run comparison and verify outputs

Run: `matlab -batch "generate_comparisons"`

Expected outputs:
- `figures/ray_fan_comparison.png`
- `figures/impulse_response_comparison.png`
- `figures/eigenray_comparison_table.png`
- `figures/eigenray_table.tex`

### Step 4: Commit master script

```bash
git add generate_comparisons.m figures/.gitkeep
git commit -m "feat: add master comparison generation script

- Orchestrates all three models
- Computes pairwise comparisons
- Generates publication-quality figures
- Exports LaTeX table for paper"
```

---

## Task 5: Explanation Documentation - Why Models Differ

**Files:**
- Create: `docs/model_differences_explained.md`

### Step 1: Write explanation document

Create: `docs/model_differences_explained.md`

```markdown
# Why the Models Differ: Physical and Numerical Explanations

## Overview
This document explains why clinear_curvature, ray_parameter, and Bellhop produce different eigenray results, even though all implement ray theory with the same physics.

## 1. Numerical Integration Method

### C-Linear Curvature
- **Method**: Euler integration with fixed arc-length step (ds = 5m)
- **Ray path**: Circular arcs (assumes linear sound speed gradient within each step)
- **Error**: O(ds) per step, accumulates over ~20,000 steps
- **Impact**:
  - Arrival times may differ by ~0.1-0.5s due to accumulated discretization error
  - Eigenray detection tolerance (10m depth) means some eigenrays near threshold may be missed/found differently

### Ray Parameter
- **Method**: Snell's law constant (p) with smaller step (ds = 1m)
- **Ray path**: Computed from p·c(z) = cos(θ), auto-detects turning points
- **Error**: Smaller per-step error due to finer discretization
- **Impact**:
  - More accurate arrival times (finer sampling)
  - Better resolution of eigenray depth at receiver

### Bellhop
- **Method**: Adaptive Runge-Kutta with variable step size
- **Ray path**: Gaussian beams (finite width, not infinitesimal rays)
- **Error**: Adaptive error control, typically < 0.01%
- **Impact**:
  - Most accurate timing and amplitudes
  - Beam spreading prevents caustic singularities

**Expected Difference**: Arrival time differences of 0.1-1.0s between models are normal and reflect different numerical schemes.

---

## 2. Eigenray Detection Criteria

### C-Linear & Ray Parameter
- **Criterion**: Ray passes within 10m depth tolerance at receiver range
- **Method**: Linear interpolation to find exact crossing point
- **Issue**: Steep-angle rays may "skip over" the tolerance window if step size is too large

### Bellhop
- **Criterion**: Beam center passes within specified tolerance
- **Method**: Adaptive integration ensures accurate boundary crossing
- **Advantage**: Beam width provides natural tolerance; less sensitive to step size

**Expected Difference**: Some eigenrays near grazing angles (θ ≈ 0° or θ ≈ ±90°) may be found by one model but not another.

---

## 3. Amplitude Calculation

### C-Linear Curvature
- **Geometrical spreading**: Spherical up to r_t=8km, then cylindrical
  - TL = 20log(r) for r < 8km
  - TL = 20log(8km) + 10log(r/8km) for r ≥ 8km
- **Limitation**: Doesn't account for ray focusing/defocusing (caustics)

### Ray Parameter
- **Geometrical spreading**: Jacobian-based (Jensen Eq. 3.56)
  - A = (1/4π)√(c_r·cos(θ₀)/(c_s·J))
  - J = |r/sin(θ) · dr/dθ₀|
- **Advantage**: Captures ray tube expansion/contraction
- **Limitation**: Requires neighboring ray data (numerical derivative)

### Bellhop
- **Geometrical spreading**: Beam amplitude evolution via coupled ODEs
- **Advantage**: Most accurate; handles caustics without singularities
- **Gold standard**: Bellhop amplitudes are considered ground truth

**Expected Difference**:
- C-Linear vs Bellhop: ±5-15 dB (especially near caustics)
- Ray Parameter vs Bellhop: ±2-8 dB (better but still approximate)
- Direct paths (0B/0S): Smallest differences (~2-5 dB)
- Multi-bounce paths: Larger differences (~10-20 dB) due to accumulated errors

---

## 4. Reflection Loss Implementation

### All Three Models
- **Surface**: Perfect pressure-release (R = -1, no loss)
- **Bottom**: Plane wave reflection coefficient
  - Z = ρ·c
  - R = (Z₂cos(θᵢ) - Z₁cos(θₜ))/(Z₂cos(θᵢ) + Z₁cos(θₜ))
  - Sandy seabed: ρ₂=1900 kg/m³, c₂=1650 m/s

**Expected Difference**: Minimal (< 1 dB) if using same parameters. Differences arise from:
- Slightly different bounce angles due to ray path discretization
- Bellhop may use more sophisticated boundary models (frequency-dependent)

---

## 5. Boundary Interaction Handling

### C-Linear & Ray Parameter
- **Method**: Linear interpolation to find hit point, then specular reflection
- **Assumption**: Perfect boundaries (instantaneous reflection)
- **Issue**: May miss grazing-angle interactions if step crosses boundary at shallow angle

### Bellhop
- **Method**: Beam interacts with boundaries using Gaussian beam theory
- **Advantage**: Smooth treatment of near-grazing rays
- **Boundary models**: Can use frequency-dependent impedance (acoustic halfspace)

**Expected Difference**: Eigenrays with grazing angles (θ < 5° or θ > 85° from horizontal) may differ significantly.

---

## 6. Sound Speed Profile Representation

### All Models Use Munk Profile
- C-Linear: Analytic formula with dc/dz computed via finite difference
- Ray Parameter: Same analytic formula
- Bellhop: Reads discretized SSP from .env file (42 depth points)

**Expected Difference**:
- Minimal at most depths
- Bellhop interpolates between SSP points, may have slight differences in regions of high curvature

---

## Summary: When to Expect Agreement

| Eigenray Type | Expected Agreement | Typical Differences |
|---------------|-------------------|---------------------|
| **Direct (0B/0S)** | Excellent | Δt < 0.2s, ΔA < 3 dB |
| **Single bounce (1B/0S or 0B/1S)** | Good | Δt < 0.5s, ΔA < 5 dB |
| **Multi-bounce (2B/1S, etc.)** | Moderate | Δt < 1.0s, ΔA < 10 dB |
| **Complex (3B/3S+)** | Poor | Δt > 1.0s, ΔA > 15 dB |

**Bellhop is the reference**: When models disagree, Bellhop is typically more accurate due to:
1. Adaptive integration (better numerics)
2. Gaussian beams (no caustic singularities)
3. Validated against analytical solutions

**For the paper**: Emphasize that differences are expected and quantify them. The goal is not perfect agreement, but understanding *why* they differ and *by how much*.
```

### Step 2: Commit documentation

```bash
git add docs/model_differences_explained.md
git commit -m "docs: explain why models differ

- Numerical integration differences
- Eigenray detection criteria
- Amplitude calculation methods
- Expected agreement levels by eigenray type"
```

---

## Final Integration

### Step 1: Update main README

Add to `README.md`:

```markdown
## Model Comparison

To generate comparison plots and metrics:

\`\`\`bash
matlab -batch "generate_comparisons"
\`\`\`

This will:
1. Run all three models (clinear_curvature, ray_parameter, Bellhop)
2. Extract and normalize eigenray data
3. Compute pairwise comparison metrics
4. Generate publication-quality figures in `figures/`
5. Export LaTeX table for paper

### Understanding Differences

See `docs/model_differences_explained.md` for detailed explanation of why models produce different results and what level of agreement to expect.
```

### Step 2: Commit README update

```bash
git add README.md
git commit -m "docs: add model comparison workflow to README"
```

### Step 3: Final verification

Run complete workflow:

```bash
matlab -batch "generate_comparisons"
```

Verify all outputs created:
- [ ] figures/ray_fan_comparison.png
- [ ] figures/impulse_response_comparison.png
- [ ] figures/eigenray_comparison_table.png
- [ ] figures/eigenray_table.tex

---

## Execution Plan Complete

**Plan saved to**: `docs/plans/2025-11-26-model-comparison-implementation.md`

**Two execution options:**

### Option 1: Subagent-Driven (this session)
Use superpowers:subagent-driven-development to execute tasks sequentially with code review between each task. Fast iteration, stays in current session.

### Option 2: Parallel Session (separate)
Open new session in main worktree, use superpowers:executing-plans for batch execution with checkpoints.

**Which approach would you like?**
