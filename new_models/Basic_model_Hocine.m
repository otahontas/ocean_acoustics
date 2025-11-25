function Basic_model_Hocine()
    close all; clear; clc;

    % Environment parameters
    env.max_depth = 8000;     
    env.max_range = 100000;   

    % Source parameters
    source.depth = 1000;                         
    source.launch_angles = deg2rad(linspace(-25, 25, 1000));

    % Receiver parameters
    receiver.depth = 1000;    
    receiver.rng = 100000;    
    receiver.tol = 5; 

    % Acoustic parameters
    freq = 50;   % Hz

    % Storage
    eigenrays = {};
    eigenray_times = [];
    eigenray_absorption = [];
    eigenray_reflection = [];   %%% <<< NEW REFLECTION >>>
    eigenray_arrival_angle = []; %%% <<< NEW: ARRIVAL ANGLE >>>
    eigenray_geom_spreading = []; %%% <<< NEW: GEOMETRICAL SPREADING >>>
    eigenray_indices = [];       %%% <<< NEW: INDEX OF LAUNCH ANGLE >>>
    normal_rays = {};

    % Store all rays to compute Jacobian-based spreading later
    all_rays = cell(length(source.launch_angles), 1);

    % Main loop
    for i = 1:length(source.launch_angles)
        theta0 = source.launch_angles(i);

        % Ray trace now returns bounce info as well
        [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] = ...
            trace_ray(env, source, theta0);

        % Store full ray path for later Jacobian computation
        all_rays{i} = ray_path;

        % Check receiver hit
        if abs(ray_path(end,2) - receiver.depth) <= receiver.tol
            eigenrays{end+1} = ray_path;
            eigenray_indices(end+1) = i;  % remember which launch angle produced this eigenray

            % Travel time
            total_time = sum(segment_times);
            eigenray_times(end+1) = total_time;

            % === ABSORPTION ===
            total_length_m = sum(segment_lengths);
            total_length_km = total_length_m / 1000; % switch to km units
            alpha_dB_per_km = thorp_absorption(freq/1000); % alpha is in dB/km
            TL_abs_dB = alpha_dB_per_km * total_length_km;
            A_abs = 10^(-TL_abs_dB / 20);
            eigenray_absorption(end+1) = A_abs;

            % === REFLECTION LOSSES ===
            A_ref = 1;
            for b = 1:length(bounce_types)
                if bounce_types{b} == "surface"
                    A_ref = A_ref * (-1);   % perfect pressure-release
                else
                    A_ref = A_ref * bottom_reflection(bounce_angles(b), env.max_depth);
                end
            end
            eigenray_reflection(end+1) = A_ref;

            % === ARRIVAL ANGLE ESTIMATION ===
            dx = ray_path(end,1) - ray_path(end-1,1);
            dz = ray_path(end,2) - ray_path(end-1,2);
            theta_arrival = atan2(dz, dx);   % radians
            eigenray_arrival_angle(end+1) = rad2deg(theta_arrival);  % store in degrees
        end

        % Store 1/20 of normal rays (sparse fan)
        if mod(i,20) == 0
            normal_rays{end+1} = ray_path;
        end
    end

    fprintf('Total eigenrays found: %d\n', numel(eigenrays));

    % =============================================
    % GEOMETRICAL SPREADING VIA JACOBIAN (from the Jensen ref book)
    % =============================================

    % These parameters are the same for all the eigenrays
    dtheta0 = source.launch_angles(2) - source.launch_angles(1);  % uniform spacing
    c_src = sound_speed(source.depth);     % c(0)
    c_rec = sound_speed(receiver.depth);   % c(s) at receiver depth

    eigenray_geom_spreading = zeros(size(eigenrays));

    for k = 1:numel(eigenrays)                   % For each eigenray
        idx = eigenray_indices(k);               % index of launch angle
        theta0 = source.launch_angles(idx);      % launch angle at source

        % Main eigenray path
        ray_main = all_rays{idx};

        % Find intersection range r_main at receiver depth by linear interpolation
        [r_main, success_main] = range_at_depth(ray_main, receiver.depth);

        % Arrival angle at receiver (already in degrees), convert to radians
        theta_receiver = deg2rad(eigenray_arrival_angle(k));

        % Choose neighboring rays in launch-angle space to approximate ∂r/∂theta0
        idx_neigh_candidates = [];
        if idx < length(source.launch_angles) % following ray
            idx_neigh_candidates(end+1) = idx + 1;
        end
        if idx > 1                              % previous ray
            idx_neigh_candidates(end+1) = idx - 1;
        end

        dr_dtheta = NaN;
        for nn = 1:length(idx_neigh_candidates) % for both neighbouring rays, check if they cross the depth at receiver
            j = idx_neigh_candidates(nn);
            ray_neigh = all_rays{j};
            [r_neigh, success_neigh] = range_at_depth(ray_neigh, receiver.depth);
            if success_neigh
                dtheta = source.launch_angles(j) - theta0;
                dr_dtheta = (r_neigh - r_main) / dtheta; % finite difference approximation
                break; %if one of the rays work, then take this value and continue
            end
        end

        % Jacobian-based J(s) at receiver (eqs. 3.39–3.41)
        J = abs(r_main / sin(theta_receiver) * dr_dtheta);

        % Amplitude along the ray using eq. (3.56):
        A_geom = (1 / (4 * pi)) * sqrt( abs( c_rec * cos(theta0) / (c_src * J) ) );

        eigenray_geom_spreading(k) = A_geom;
    end

    % ============================
    % Plot Rays and Print Data
    % ============================

    figure('Position', [100 100 800 500]); hold on;

    % Plot sparse normal rays (gray)
    for i = 1:length(normal_rays)
        plot(normal_rays{i}(:,1)/1000, normal_rays{i}(:,2), 'Color', [0.8 0.8 0.8], ...
             'LineWidth', 0.8, 'HandleVisibility', 'off');
    end

    % Plot eigenrays (blue)
    for i = 1:length(eigenrays)
        ray_path = eigenrays{i};
        plot(ray_path(:,1)/1000, ray_path(:,2), 'b-', 'LineWidth', 1.2, ...
             'HandleVisibility', 'off');

        % PRINT: time, absorption, reflection coefficient, arrival angle
        fprintf("Eigenray %d: Time = %.3f s, Absorption = %.6f, Reflection = %.4f, Arrival angle = %.2f deg\n", ...
                 i, eigenray_times(i), eigenray_absorption(i), eigenray_reflection(i), eigenray_arrival_angle(i));
    end

    % Mark source and receiver
    plot(0, source.depth, 'bs', 'MarkerFaceColor','b');
    plot(receiver.rng/1000, receiver.depth, 'ro', 'MarkerFaceColor','r');

    % Axes formatting
    set(gca, 'YDir', 'reverse');
    xlabel('Range (km)');
    ylabel('Depth (m)');
    title('Ray Tracing with Absorption + Reflection + Arrival Angles');
    grid on;

    % ===============================
    %  IMPULSE RESPONSE AT RECEIVER
    % ===============================
    
    figure('Position', [100 650 800 300]); hold on;
    
    if ~isempty(eigenray_times)
    
        % Combine amplitudes (geometrical spreading × absorption × reflection)
        % Here A_geom is from the Jacobian/J-ray-tube formulation (eq. 3.56).
        A_total = eigenray_geom_spreading .* eigenray_absorption .* eigenray_reflection;
    
        % Centered impulse response
        for k = 1:length(eigenray_times)
            t0 = eigenray_times(k);
            h0 = A_total(k);
    
            % Plot small vertical stem at the arrival time
            plot([t0 t0], [0 h0], 'b', 'LineWidth', 2);
    
            % Optional: add arrival angle text above the stem
            text(t0, h0 + 0.02*max(A_total), sprintf('%.1f°', eigenray_arrival_angle(k)), ...
                 'FontSize',8,'Color','k','HorizontalAlignment','center');
        end
    
        xlabel('Time (s)');
        ylabel('Amplitude');
        title('Impulse Response at Receiver');
        grid on;
    
    else
        title('No eigenrays → no impulse response');
    end

end


%% ======================================================
% trace_ray returns ray_path, segment_times, segment_lengths, bounce info
%% ======================================================
function [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] ...
         = trace_ray(env, source, theta0)

    ds = 30.0;
    max_steps = 100000;

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
        c_local = sound_speed(0.5*(z + z_new));
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
function [x_at_depth, success] = range_at_depth(ray_path, depth)
    z = ray_path(:,2);
    x = ray_path(:,1);

    success = false;
    x_at_depth = NaN;

    idx = find((z(1:end-1)-depth).*(z(2:end)-depth) <= 0, 1, 'last');
    if isempty(idx)
        return;
    end

    x_at_depth = interp1(z(idx:idx+1), x(idx:idx+1), depth);
    success = true;
end


%% Sound speed profile
function c = sound_speed(z)
    z0 = 1300.0;   
    c0 = 1500.0;   
    eps = 0.00737; 
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

    % Water
    rho1 = 1000;   c1 = sound_speed(depth);

    % Sandy seabed
    rho2 = 1800;   c2 = 1700; 

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
