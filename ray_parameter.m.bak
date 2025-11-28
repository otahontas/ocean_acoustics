%% Ray Parameter Model
close all; % clear; clc;  % COMMENTED OUT: Don't clear when called from comparison script

%% ----------------- Load shared parameters -----------------
shared_params;

use_simple_spreading = false;   % FLAG TO CHOOSE GEOMETRICAL SPREADING MODEL
    % true  = A = 1/(4πR)
    % false = Jensen Jacobian model (complex spreading)

    % Map shared parameters to local variables
    source.launch_angles = deg2rad(linspace(ray_fan.angle_min, ray_fan.angle_max, ray_fan.num_angles));
    receiver.rng = receiver.range;
    receiver.tol = receiver.tolerance;
    freq = acoustic.frequency;

    % Pre-allocate storage (worst case: all rays are eigenrays)
    max_eigenrays = length(source.launch_angles);
    eigenrays = cell(1, max_eigenrays);
    eigenray_times = zeros(1, max_eigenrays);
    eigenray_absorption = zeros(1, max_eigenrays);
    eigenray_reflection = zeros(1, max_eigenrays);
    eigenray_arrival_angle = zeros(1, max_eigenrays);
    eigenray_geom_spreading = zeros(1, max_eigenrays);
    eigenray_indices = zeros(1, max_eigenrays);
    eigenray_n_bottom = zeros(1, max_eigenrays);
    eigenray_n_surface = zeros(1, max_eigenrays);
    eigenray_path_length = zeros(1, max_eigenrays);
    eigenray_count = 0;  % Track actual count

    normal_rays = cell(1, ceil(max_eigenrays/20));  % Pre-allocate for 1/20 of rays
    normal_ray_count = 0;

    % Store only Jacobian-needed data per ray (not full paths)
    % For each ray: [r_at_receiver_depth, theta_at_receiver_depth, success_flag]
    ray_receiver_data = zeros(length(source.launch_angles), 3);

    % Main loop
    for i = 1:length(source.launch_angles)
        theta0 = source.launch_angles(i);
        [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] = ...
            trace_ray(env, source, theta0);

        % Store only receiver-crossing data for Jacobian (not full path)
        [r_at_depth, theta_at_depth, success] = range_at_depth(ray_path, receiver.depth);
        ray_receiver_data(i, 1) = r_at_depth;
        ray_receiver_data(i, 2) = theta_at_depth;
        ray_receiver_data(i, 3) = success;

        % Check receiver hit
        if abs(ray_path(end,2) - receiver.depth) <= receiver.tol
            eigenray_count = eigenray_count + 1;
            eigenrays{eigenray_count} = ray_path;
            eigenray_indices(eigenray_count) = i;  % remember which launch angle produced this eigenray

            % Travel time
            total_time = sum(segment_times);
            eigenray_times(eigenray_count) = total_time;

            % === ABSORPTION ===
            total_length_m = sum(segment_lengths);
            eigenray_path_length(eigenray_count) = total_length_m;
            total_length_km = total_length_m / 1000; % switch to km units
            alpha_dB_per_km = thorp_absorption(freq/1000); % alpha is in dB/km
            TL_abs_dB = alpha_dB_per_km * total_length_km;
            A_abs = 10^(-TL_abs_dB / 20);
            eigenray_absorption(eigenray_count) = A_abs;

            % === REFLECTION LOSSES ===
            A_ref = 1;
            n_surf = 0;
            n_bot = 0;
            for b = 1:length(bounce_types) % multiply all the reflections together
                if bounce_types{b} == "surface"
                    A_ref = A_ref * (-1);   % perfect pressure-release
                    n_surf = n_surf + 1;
                else
                    A_ref = A_ref * bottom_reflection(bounce_angles(b), env.max_depth);
                    n_bot = n_bot + 1;
                end
            end
            eigenray_reflection(eigenray_count) = A_ref;
            eigenray_n_surface(eigenray_count) = n_surf;
            eigenray_n_bottom(eigenray_count) = n_bot;

            % === ARRIVAL ANGLE ESTIMATION ===
            dx = ray_path(end,1) - ray_path(end-1,1);
            dz = ray_path(end,2) - ray_path(end-1,2);
            theta_arrival = atan2(dz, dx);   % radians
            eigenray_arrival_angle(eigenray_count) = rad2deg(theta_arrival);  % store in degrees
        end

        % Store 1/20 of normal rays (sparse fan)
        if mod(i,20) == 0
            normal_ray_count = normal_ray_count + 1;
            normal_rays{normal_ray_count} = ray_path;
        end
    end

    % Trim arrays to actual size
    eigenrays = eigenrays(1:eigenray_count);
    eigenray_times = eigenray_times(1:eigenray_count);
    eigenray_absorption = eigenray_absorption(1:eigenray_count);
    eigenray_reflection = eigenray_reflection(1:eigenray_count);
    eigenray_arrival_angle = eigenray_arrival_angle(1:eigenray_count);
    eigenray_geom_spreading = eigenray_geom_spreading(1:eigenray_count);
    eigenray_indices = eigenray_indices(1:eigenray_count);
    eigenray_n_bottom = eigenray_n_bottom(1:eigenray_count);
    eigenray_n_surface = eigenray_n_surface(1:eigenray_count);
    eigenray_path_length = eigenray_path_length(1:eigenray_count);
    normal_rays = normal_rays(1:normal_ray_count);

    fprintf('Total eigenrays found: %d\n', eigenray_count);

    % =============================================
    % GEOMETRICAL SPREADING VIA JACOBIAN (from the Jensen ref book)
    % =============================================

    % These parameters are the same for all the eigenrays
    dtheta0 = source.launch_angles(2) - source.launch_angles(1);  % uniform spacing
    c_src = sound_speed(source.depth);     % c(0) at source depth
    c_rec = sound_speed(receiver.depth);   % c(s) at receiver depth

    eigenray_geom_spreading = zeros(size(eigenrays));

    for k = 1:numel(eigenrays)                   % For each eigenray
        idx = eigenray_indices(k);               % index of launch angle
        theta0 = source.launch_angles(idx);      % launch angle at source

        % Get pre-computed receiver-crossing data
        r_main = ray_receiver_data(idx, 1);
        theta_receiver = ray_receiver_data(idx, 2);
        success_main = ray_receiver_data(idx, 3);

        if ~success_main || isnan(r_main)
            % Fallback: use eigenray path length
            ray_main = eigenrays{k};
            s_fallback = arc_length(ray_main);
            A_geom = 1 / (4 * pi * s_fallback);
            eigenray_geom_spreading(k) = A_geom;
            continue;
        end

        % =====================================================================
        % SIMPLE SPHERICAL SPREADING OPTION: A = 1/(4*pi*R)
        % =====================================================================
        if use_simple_spreading
            % 3D distance from source to (r_main, receiver.depth)
            dx = r_main - 0;
            dz = receiver.depth - source.depth;
            R3D = sqrt(dx^2 + dz^2);

            A_geom = 1 / (4*pi*R3D);
            eigenray_geom_spreading(k) = A_geom;
            continue;   % <<<<<<<<<<<<<<<< skip Jacobian, go to next eigenray
        end
        % =====================================================================

        % ---- JENSEN JACOBIAN MODEL (original) ----

        % Choose neighboring rays to approximate dr/dtheta0
        idx_neigh_candidates = [];
        if idx < length(source.launch_angles)
            idx_neigh_candidates(end+1) = idx + 1;
        end
        if idx > 1
            idx_neigh_candidates(end+1) = idx - 1;
        end

        dr_dtheta = NaN;
        for nn = 1:length(idx_neigh_candidates)
            j = idx_neigh_candidates(nn);
            r_neigh = ray_receiver_data(j, 1);
            success_neigh = ray_receiver_data(j, 3);
            if success_neigh && ~isnan(r_neigh)
                dtheta = source.launch_angles(j) - theta0;
                dr_dtheta = (r_neigh - r_main) / dtheta;
                break;
            end
        end

        if isnan(dr_dtheta) || abs(sin(theta_receiver)) < 1e-6
            % Fallback: use eigenray path length
            ray_main = eigenrays{k};
            s_fallback = arc_length(ray_main);
            A_geom = 1 / (4 * pi * s_fallback);
            eigenray_geom_spreading(k) = A_geom;
            continue;
        end

        % Jacobian-based J(s) at receiver
        J = abs( (r_main / sin(theta_receiver)) * dr_dtheta );

        % Amplitude along the ray using eq. (3.56)
        A_geom = (1 / (4 * pi)) * sqrt( abs( c_rec * cos(theta0) / (c_src * J) ) );

        eigenray_geom_spreading(k) = A_geom;
    end

    % ==================================================
    % ASSIGN UNIQUE COLORS TO EACH EIGENRAY
    % ==================================================
    num_eigs = length(eigenrays);
    eig_colors = jet(num_eigs);

    % ============================
    % Plot Rays and Print Data
    % ============================

    figure('Position', [100 100 800 500]); hold on;

    for i = 1:length(normal_rays)
        plot(normal_rays{i}(:,1)/1000, normal_rays{i}(:,2), 'Color', [0.8 0.8 0.8], ...
             'LineWidth', 0.8, 'HandleVisibility', 'off');
    end

    % ==== EIGENRAYS WITH UNIQUE COLORS ====
    for i = 1:num_eigs
        ray_path = eigenrays{i};

        plot(ray_path(:,1)/1000, ray_path(:,2), ...
             'Color', eig_colors(i,:), ...
             'LineWidth', 1.2, ...
             'HandleVisibility', 'off');
        A_tot = eigenray_geom_spreading(i) * eigenray_absorption(i) * eigenray_reflection(i);
        A_tot_dB = 20*log10(abs(A_tot));
        fprintf("Eigenray %d: Launch angle = %.2f°, Arrival angle = %.2f°, Bounces: %dB/%dS, Path length = %.2f m, Time = %.3f s, Amp = %.2f dB\n", ...
                 i, rad2deg(source.launch_angles(eigenray_indices(i))), eigenray_arrival_angle(i), ...
                 eigenray_n_bottom(i), eigenray_n_surface(i), eigenray_path_length(i), eigenray_times(i), A_tot_dB);
    end

    plot(0, source.depth, 'bs', 'MarkerFaceColor','b');
    plot(receiver.rng/1000, receiver.depth, 'ro', 'MarkerFaceColor','r');

    set(gca, 'YDir', 'reverse');
    xlabel('Range (km)');
    ylabel('Depth (m)');
    title('Ray Tracing with Simple or Jacobian Geometrical Spreading');
    grid on;
    saveas(gcf, 'figures/ray_parameter_rays.png');
    fprintf('Saved: figures/ray_parameter_rays.png\n');

    % ===============================
    %  IMPULSE RESPONSE —
    % ===============================
    
    figure('Position', [100 650 800 300]); hold on;
    
    A_total = eigenray_geom_spreading .* eigenray_absorption .* eigenray_reflection;

    % Convert to dB
    A_dB = 20 * log10(abs(A_total));
    Amax = max(A_dB); % to plot the angle

    for k = 1:length(eigenray_times)
        t0 = eigenray_times(k);
        h0 = A_dB(k);

        % Stem in same color
        plot([t0 t0], [Amax-80 h0], 'Color', eig_colors(k,:), 'LineWidth', 2);

        % Text label
        text(t0, h0 + 1, sprintf('%.1f°', eigenray_arrival_angle(k)), ...
             'FontSize',8,'Color',eig_colors(k,:), ...
             'HorizontalAlignment','center');
    end

    xlabel('Time (s)');
    ylabel('Amplitude (dB)');
    title('Impulse Response at Receiver (dB scale)');
    grid on;
    ylim([Amax-80 Amax+3]);   % 80 dB dynamic range
    saveas(gcf, 'figures/ray_parameter_arrivals.png');
    fprintf('Saved: figures/ray_parameter_arrivals.png\n');


%% ======================================================
% trace_ray returns ray_path, segment_times, segment_lengths, bounce info
%% ======================================================
function [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] ...
         = trace_ray(env, source, theta0)

    ds = 5.0;  % Increased from 1.0 for 5x speedup
    max_steps = 100000;  % Reduced proportionally (was 500000)

    x = 0.0; 
    z = source.depth;
    c0 = sound_speed(z);
    p = cos(theta0) / c0;   
    dz = sign(sin(theta0)) * 1e-3;  

    path = zeros(max_steps, 2);
    time_segments = zeros(max_steps,1);
    len_segments  = zeros(max_steps,1);

    bounce_types = {};          %%% <<< NEW REFLECTION >>>
    bounce_angles = [];         %%% <<< NEW REFLECTION >>>

    path(1,:) = [x, z];
    n = 1;

    for step = 1:max_steps
        c = sound_speed(z);
        arg = p * c;

        if abs(arg) >= 1.0
            dz = -dz;
            arg = 2 - arg;
        end

        theta = sign(dz) * acos(arg);

        dx = ds * cos(theta);
        dz_step = ds * sin(theta);

        x_new = x + dx;
        z_new = z + dz_step;

        % Check reflections
        if z_new <= 0
            bounce_types{end+1} = "surface";       %%% <<< NEW REFLECTION >>>
            bounce_angles(end+1) = abs(theta);

            z_new = -z_new;  
            dz = -dz;

        elseif z_new >= env.max_depth
            bounce_types{end+1} = "bottom";        %%% <<< NEW REFLECTION >>>
            bounce_angles(end+1) = abs(theta);

            z_new = 2*env.max_depth - z_new;  
            dz = -dz;
        end

        % Travel time + length
        c_local = sound_speed(0.5*(z + z_new)); % approximate the actual speed
        time_segments(n) = ds / c_local;
        len_segments(n)  = ds;

        x = x_new;  
        z = z_new;

        n = n + 1;
        path(n,:) = [x, z];

        if x >= env.max_range
            break;
        end
    end

    ray_path = path(1:n,:);
    segment_times = time_segments(1:n);
    segment_lengths = len_segments(1:n);
end


%% Interpolation= find the range where a path reaches a certain depth
function [x_at_depth, theta_at_depth, success] = range_at_depth(ray_path, depth)
    z = ray_path(:,2);
    x = ray_path(:,1);

    success = false;
    x_at_depth = NaN;
    theta_at_depth = NaN;

    % look for segment that brackets the desired depth (last crossing)
    idx = find((z(1:end-1)-depth).*(z(2:end)-depth) <= 0, 1, 'last');
    if isempty(idx)
        return;
    end

    % Endpoints of the segment
    z1 = z(idx);   z2 = z(idx+1);
    x1 = x(idx);   x2 = x(idx+1);

    % Linear interpolation in z to find x at the exact depth
    % Check if z values are unique (avoid interp1 error)
    if abs(z2 - z1) < 1e-10
        x_at_depth = x1;  % Ray is horizontal, use first point
    else
        x_at_depth = interp1([z1 z2], [x1 x2], depth);
    end

    % Local ray angle (propagation direction) on this segment
    dz = z2 - z1;
    dx = x2 - x1;
    theta_at_depth = atan2(dz, dx);   % radians

    success = true;
end


%% compute arclength of a ray path
function s = arc_length(ray_path)
    x = ray_path(:,1);
    z = ray_path(:,2);
    dx = diff(x);
    dz = diff(z);
    s = sum( sqrt(dx.^2 + dz.^2) );
end


%% Sound speed profile
function c = sound_speed(z)
    % Cache SSP parameters to avoid repeated shared_params loads
    persistent z0 c0 eps
    if isempty(z0)
        shared_params;
        z0 = ssp.z0;
        c0 = ssp.c0;
        eps = ssp.epsilon;
    end
    zbar = 2 * (z - z0) / z0;
    c = c0 * (1 + eps * (zbar - 1 + exp(-zbar)));
end


%% Thorp absorption formula % 1.47 in the book p36
function alpha = thorp_absorption(f_kHz) %% frequency has to be in kHz and result is in dB/km
    f2 = f_kHz.^2;
    alpha = 0.11 * f2 ./ (1 + f2) ...
          + 44 * f2 ./ (4100 + f2) ...
          + 2.75e-4 * f2 ...
          + 0.003;
end


%% Bottom reflection coefficient  %%% <<< NEW REFLECTION >>>
function R = bottom_reflection(theta_i, depth)

    % Use shared seabed parameters
    shared_params;
    rho1 = seabed.rho_water;
    c1 = sound_speed(depth);
    rho2 = seabed.rho_bottom;
    c2 = seabed.c_bottom; 

    Z1 = rho1 * c1;
    Z2 = rho2 * c2;

    % Snell's law
    sin_theta_t = (c1/c2) * sin(theta_i);

    % Critical angle => total reflection
    if abs(sin_theta_t) > 1
        R = -1;
        return;
    end

    theta_t = asin(sin_theta_t);

    R = (Z2*cos(theta_i) - Z1*cos(theta_t)) / ... % 1.58 page 41
        (Z2*cos(theta_i) + Z1*cos(theta_t));
end
