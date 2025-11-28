% Ray Parameter Model - converted to script for compare.m
% Only clear if not being called from compare.m
if ~exist('fid', 'var')
    close all; clear; clc;
else
    % Save fid to file, clear, then restore
    save('.rayparam_fid_temp.mat', 'fid');
    close all; clear; clc;
    load('.rayparam_fid_temp.mat');
    delete('.rayparam_fid_temp.mat');
end

    shared_params;

    % ============================================================
    % FLAG TO CHOOSE GEOMETRICAL SPREADING MODEL
    % 0 = Jensen Jacobian model (complex spreading)
    % 1 = Simple spherical spreading A = 1/(4πR)
    % 2 = Hybrid: 1 km spherical, then cylindrical
    % ============================================================
    spreading_mode = 0;
    % ============================================================

    % Map shared params to local variables
    source.launch_angles = deg2rad(linspace(ray_fan.angle_min, ray_fan.angle_max, ray_fan.num_angles));
    receiver.rng = receiver.range;
    receiver.tol = receiver.tolerance;
    freq = acoustic.frequency;

    % Storage
    eigenrays = {};
    eigenray_times = [];
    eigenray_absorption = [];
    eigenray_reflection = [];   %%% <<< NEW REFLECTION >>>
    eigenray_arrival_angle = []; %%% <<< NEW: ARRIVAL ANGLE >>>
    eigenray_geom_spreading = []; %%% <<< NEW: GEOMETRICAL SPREADING >>>
    eigenray_indices = [];       %%% <<< NEW: INDEX OF LAUNCH ANGLE >>>
    eigenray_n_bottom = [];      %%% <<< NEW: BOTTOM BOUNCE COUNT >>>
    eigenray_n_surface = [];     %%% <<< NEW: SURFACE BOUNCE COUNT >>>
    eigenray_path_length = [];   %%% <<< NEW: PATH LENGTH >>>
    eigenray_count = 0;          %%% <<< NEW: TOTAL COUNT >>>
    normal_rays = {};
    
    % === ALWAYS SELECT EXACTLY 100 NORMAL RAYS FOR PLOTTING ===
    num_normals = 100;
    normal_ray_indices = round(linspace(1, length(source.launch_angles), num_normals));


    % Store all rays to compute Jacobian-based spreading later
    all_rays = cell(length(source.launch_angles), 1);

    % Main loop
    for i = 1:length(source.launch_angles)
        theta0 = source.launch_angles(i);
        [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] = ...
            trace_ray(env, source, theta0);

        % Store full ray path for later Jacobian computation
        all_rays{i} = ray_path;

        % Check receiver hit
        if abs(ray_path(end,2) - receiver.depth) <= receiver.tol
            eigenray_count = eigenray_count + 1;
            eigenrays{end+1} = ray_path;
            eigenray_indices(end+1) = i;  % remember which launch angle produced this eigenray

            % Travel time
            total_time = sum(segment_times);
            eigenray_times(end+1) = total_time;

            % === ABSORPTION ===
            total_length_m = sum(segment_lengths);
            eigenray_path_length(end+1) = total_length_m;
            total_length_km = total_length_m / 1000; % switch to km units
            alpha_dB_per_km = thorp_absorption(freq/1000); % alpha is in dB/km
            TL_abs_dB = alpha_dB_per_km * total_length_km;
            A_abs = 10^(-TL_abs_dB / 20);
            eigenray_absorption(end+1) = A_abs;

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
            eigenray_reflection(end+1) = A_ref;
            eigenray_n_surface(end+1) = n_surf;
            eigenray_n_bottom(end+1) = n_bot;

            % === ARRIVAL ANGLE ESTIMATION ===
            dx = ray_path(end,1) - ray_path(end-1,1);
            dz = ray_path(end,2) - ray_path(end-1,2);
            theta_arrival = atan2(dz, dx);   % radians
            eigenray_arrival_angle(end+1) = rad2deg(theta_arrival);  % store in degrees
        end

        % Store exactly 100 evenly-spaced normal rays
        if ismember(i, normal_ray_indices)
            normal_rays{end+1} = ray_path;
        end
    end

    fprintf('Total eigenrays found: %d\n', numel(eigenrays));

    % =============================================
    % GEOMETRICAL SPREADING MODELS
    % =============================================

    dtheta0 = source.launch_angles(2) - source.launch_angles(1);  % uniform spacing
    c_src = sound_speed(source.depth);    
    c_rec = sound_speed(receiver.depth);   

    eigenray_geom_spreading = zeros(size(eigenrays));

    for k = 1:numel(eigenrays)
        idx = eigenray_indices(k);
        theta0 = source.launch_angles(idx);
        ray_main = all_rays{idx};

        % Intersection at receiver
        [r_main, theta_receiver, success_main] = range_at_depth(ray_main, receiver.depth);

        if ~success_main
            s_fallback = arc_length(ray_main);
            eigenray_geom_spreading(k) = 1/(4*pi*s_fallback);
            continue;
        end

        % ------------------------------------------------------------
        % SPREADING MODEL SELECTION
        % ------------------------------------------------------------

        % === 1) SIMPLE SPHERICAL SPREADING: A = 1/(4πR)
        if spreading_mode == 1
            dx = r_main - 0;
            dz = receiver.depth - source.depth;
            R3D = sqrt(dx^2 + dz^2);
            A_geom = 1/(4*pi*R3D);
            eigenray_geom_spreading(k) = A_geom;
            continue;
        end

        % === 2) HYBRID: 1 km spherical, then cylindrical ============
        if spreading_mode == 2

            % Total 3D ray path length for this eigenray
            path_len = arc_length(ray_main);

            if path_len <= 1000
                % Pure spherical
                TL_dB = 20*log10(path_len);
            else
                % 1 km spherical + cylindrical remainder
                TL_dB = 20*log10(1000) + 10*log10(path_len - 1000);
            end

            TL_amp = 10^(-TL_dB/20);   % Convert TL_dB → amplitude
            eigenray_geom_spreading(k) = TL_amp;
            continue;
        end

        % ------------------------------------------------------------
        % 3) DEFAULT: JENSEN JACOBIAN MODEL
        % ------------------------------------------------------------

        % Neighbor rays → dr/dtheta
        idx_neigh = [];
        if idx < length(source.launch_angles), idx_neigh(end+1) = idx+1; end
        if idx > 1,                       idx_neigh(end+1) = idx-1; end

        dr_dtheta = NaN;
        for j = idx_neigh
            rayN = all_rays{j};
            [rN, ~, ok] = range_at_depth(rayN, receiver.depth);
            if ok
                dth = source.launch_angles(j) - theta0;
                dr_dtheta = (rN - r_main)/dth;
                break;
            end
        end

        if isnan(dr_dtheta) || abs(sin(theta_receiver)) < 1e-6
            s_fallback = arc_length(ray_main);
            A_geom = 1 / (4 * pi * s_fallback);
            eigenray_geom_spreading(k) = A_geom;
            continue;
        end

        J = abs((r_main / sin(theta_receiver)) * dr_dtheta);

        A_geom = (1/(4*pi)) * sqrt(abs(c_rec*cos(theta0)/(c_src*J)));
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

    % --------- NEW PLOTTING STYLE TO MATCH YOUR FRIEND ----------
    z_min = 0;
    z_max = env.max_depth;
    r_rec = receiver.rng;
    z_rec = receiver.depth;
    r_s   = 0;
    z_s   = source.depth;

    figure('Color','w','Position',[200 200 1000 600]); hold on; box on;

    % Bottom (brown) rectangle
    rectangle('Position',[0 z_max r_rec/1000 z_max+500], ...
         'FaceColor',[0.6 0.3 0],'EdgeColor','black','LineWidth', 1);

    % Surface / water above (blue) rectangle
    rectangle('Position',[0 (-500) r_rec/1000 500], ...
        'FaceColor',[0.5 0.7 1], 'EdgeColor','blue','LineWidth',1);

    % Plot normal ray fan (gray)
    for i = 1:length(normal_rays)
        ray = normal_rays{i};
        r_plot = ray(:,1);   % in m
        z_plot = ray(:,2);   % in m
        plot(r_plot/1000, z_plot, 'Color', [0.8 0.8 0.8], 'LineWidth', 0.8);
    end

    % Plot eigenrays (colored, thicker), and print info
    for i = 1:num_eigs
        ray_path = eigenrays{i};
        er_z = ray_path(:,2);
        er_z(er_z < z_min) = z_min;
        er_z(er_z > z_max) = z_max;

        plot(ray_path(:,1)/1000, er_z, 'Color', eig_colors(i,:), 'LineWidth', 2);

        % Mark eigenray receiver point approximately at (receiver.rng, receiver.depth)
        plot(r_rec/1000, receiver.depth, 'o', 'MarkerFaceColor','r', ...
             'MarkerEdgeColor','k', 'MarkerSize',6);

        A_tot = eigenray_geom_spreading(i) * eigenray_absorption(i) * eigenray_reflection(i);
        A_tot_dB = 20*log10(abs(A_tot));

        fprintf("Eg-ray %d: Time = %.3f s, Geom_spread= %.4f, Absor = %.6f, Reflect = %.2f, Arri angle = %.2f deg, A_tot = %.2f dB\n", ...
            i, eigenray_times(i), eigenray_geom_spreading(i), eigenray_absorption(i), ...
            eigenray_reflection(i), eigenray_arrival_angle(i), A_tot_dB);
    end

    % mark source and receiver (match friend's style)
    plot(r_s/1000, z_s, 'kp', 'MarkerFaceColor','k', 'MarkerSize',10);  % source
    plot(r_rec/1000, z_rec, 'mo', 'MarkerFaceColor','m', 'MarkerSize',8); % receiver

    xlabel('Range (km)'); 
    ylabel('Depth (m)');
    set(gca,'YDir','reverse');
    title('Ray fan and eigenrays');
    xlim([0 r_rec/1000]); 
    ylim([z_min - 200 z_max+400]); 
    grid on;

    % ===============================
    %  IMPULSE RESPONSE —
    % ===============================
    
    figure('Position', [100 650 800 300]); hold on;
    
    A_total = eigenray_geom_spreading .* eigenray_absorption .* eigenray_reflection;

    % Convert to dB
    A_dB = 20 * log10(abs(A_total));
    Amax = max(A_dB);

    for k = 1:length(eigenray_times)
        t0 = eigenray_times(k);
        h0 = A_dB(k);

        plot([t0 t0], [Amax-80 h0], 'Color', eig_colors(k,:), 'LineWidth', 2);

        text(t0, h0 + 1, sprintf('%.1f°', eigenray_arrival_angle(k)), ...
             'FontSize',8,'Color',eig_colors(k,:), 'HorizontalAlignment','center');
    end

    xlabel('Time (s)');
    ylabel('Amplitude (dB)');
    title('Impulse Response at Receiver (dB scale)');
    grid on;
    ylim([Amax-80 Amax+3]);

%% ======================================================
% trace_ray returns ray_path, segment_times, segment_lengths, bounce info
%% ======================================================
function [ray_path, segment_times, segment_lengths, bounce_types, bounce_angles] ...
         = trace_ray(env, source, theta0)

    ds = 10.0;
    max_steps = 500000;

    x = 0.0; 
    z = source.depth;
    c0 = sound_speed(z);
    p = cos(theta0) / c0;   
    dz = sign(sin(theta0)) * 1e-3;  

    path = zeros(max_steps, 2);
    time_segments = zeros(max_steps,1);
    len_segments  = zeros(max_steps,1);

    bounce_types = {};          
    bounce_angles = [];         

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

        if z_new <= 0
            bounce_types{end+1} = "surface";      
            bounce_angles(end+1) = abs(theta);

            z_new = -z_new;  
            dz = -dz;

        elseif z_new >= env.max_depth
            bounce_types{end+1} = "bottom";       
            bounce_angles(end+1) = abs(theta);

            z_new = 2*env.max_depth - z_new;  
            dz = -dz;
        end

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


%% Interpolation = find the range where a path reaches a certain depth
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

    % FIX: avoid division by zero when z1 == z2
    if z1 == z2
        x_at_depth = (x1 + x2)/2;
    else
        x_at_depth = x1 + (depth - z1) * (x2 - x1) / (z2 - z1);
    end

    dz_loc = z2 - z1;
    dx_loc = x2 - x1;

    if dx_loc == 0 && dz_loc == 0
        theta_at_depth = 0;
    else
        theta_at_depth = atan2(dz_loc, dx_loc);
    end

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
    shared_params;
    z0 = ssp.z0;
    c0 = ssp.c0;
    eps = ssp.epsilon;
    zbar = 2 * (z - z0) / z0;
    c = c0 * (1 + eps * (zbar - 1 + exp(-zbar)));
end


%% Thorp absorption formula % 1.47 in the book p36
function alpha = thorp_absorption(f_kHz)
    f2 = f_kHz.^2;
    alpha = 0.11 * f2 ./ (1 + f2) ...
          + 44 * f2 ./ (4100 + f2) ...
          + 2.75e-4 * f2 ...
          + 0.003;
end


%% Bottom reflection coefficient
function R = bottom_reflection(theta_i, depth)

    shared_params;
    rho1 = seabed.rho_water;
    c1 = sound_speed(depth);
    rho2 = seabed.rho_bottom;
    c2 = seabed.c_bottom; 

    Z1 = rho1 * c1;
    Z2 = rho2 * c2;

    sin_theta_t = (c1/c2) * sin(theta_i);

    if abs(sin_theta_t) > 1
        R = -1;
        return;
    end

    theta_t = asin(sin_theta_t);

    R = (Z2*cos(theta_i) - Z1*cos(theta_t)) / ...
        (Z2*cos(theta_i) + Z1*cos(theta_t));
end
