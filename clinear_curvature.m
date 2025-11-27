%% Discretized c linear model
% Based on the c linear method described by Jensen on p. 209-211
% Uses local curvature R = c(z) / ( g_local * cos(theta) )
% Integrates dx/ds = cos(theta), dz/ds = sin(theta), dtheta/ds = g_local*cos(theta)/c

% clear; close all; clc;  % COMMENTED OUT: Don't clear when called from comparison script

%% ----------------- Load shared parameters -----------------
shared_params;

% Map shared parameters to local variables for backward compatibility
z_s = source.depth;
r_s = source.range;
r_rec = receiver.range;
z_rec = receiver.depth;
depth_tol = receiver.tolerance;

angles_deg = linspace(ray_fan.angle_min, ray_fan.angle_max, ray_fan.num_angles);
angles = deg2rad(angles_deg);

% Numerical stepping (model-specific)
ds = 30.0; % arc-length step (m)
max_steps = 5e7;
max_range = receiver.range * 1.2;

z_min = env.z_min;
z_max = env.z_max;

A0 = 1.0; % initial amplitude at source
f = acoustic.frequency;
r_transition = receiver.range; % transition range from spherical spreading to cylindrical

%% ----------------- Sound speed and derivative (Munk) -----------------
c0 = ssp.c0;
z0_munk = ssp.z0;
eps_munk = ssp.epsilon; 

c_of_z = @(z) c0 .* ( 1 + eps_munk .* ((2*(z - z0_munk)./z0_munk) - 1 + exp(-2*(z - z0_munk)./z0_munk)));
% analytic derivative of Munk
dc_dz = @(z) (2 * c0 * eps_munk ./ z0_munk) .* (1 - exp(-2*(z - z0_munk)./z0_munk));
figure()
zplot = linspace(0, z_max);
cplot = c_of_z(zplot);
plot(cplot, -zplot, 'LineWidth',1.6);
title('Sound speed profile');
xlabel('Speed of sound (m/s)'); ylabel('Depth (m)');

%% ----------------- Ray tracing (optimized sequential) -----------------
eigenrays = {};

% FOR EACH RAY IN FAN
for ia = 1:length(angles)
    theta = angles(ia); % launch angle (rad)
    x = r_s; z = z_s; t = 0;

    % Preallocate with smart estimate
    est_size = min(ceil(max_range/ds)*3, max_steps);
    rpath = zeros(1, est_size);
    zpath = zeros(1, est_size);
    tpath = zeros(1, est_size);
    rpath(1) = x; zpath(1) = z; tpath(1) = t;
    idx = 1;
    A_reflection = 1; % reflection attenuation, initialize here so it can stack for many reflections
    step = 0;
    found = false;

    % Bounce counting
    n_surface_bounces = 0;
    n_bottom_bounces = 0;

    % Track last two finite indices to avoid find()
    last_finite_idx = 1;
    second_last_finite_idx = 0;

    % COMPUTING C LINEAR CURVATURE FOR EACH DISCRETIZED STEP
    while x <= max_range && step < max_steps
        step = step + 1;

        % C LINEAR METHOD CALCULATIONS BASED ON DERIVATIVE OF C(z) AT START
        % OF STEP, CALCULATES THE ARC
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa1 = -g_local.* cos(theta) ./ c_curr;

        % EULER TO ESTIMATE NEXT STEP
        theta_new = theta + ds * kappa1;
        x_new = x + ds * cos(theta);
        z_new = z + ds * sin(theta);
        t_new = t + ds / c_curr;

        % REFLECTION HANDLING
        if (z_new < z_min) || (z_new > z_max)
            % linear interpolation to find boundary hit fraction alpha
            if z_new < z_min  % surface hit
                alpha = (z_min - z) / (z_new - z);
                z_hit = z_min;
                n_surface_bounces = n_surface_bounces + 1;
            else % bottom hit
                alpha = (z_max - z) / (z_new - z);
                z_hit = z_max;
                n_bottom_bounces = n_bottom_bounces + 1;
                c_at_hit = c_of_z(z_hit);
                A_reflection = A_reflection * bottom_reflection(theta_new, c_at_hit);
            end
            alpha = max(0,min(1,alpha));
            % compute hit point (linear along this ds)
            x_hit = x + alpha * (x_new - x);
            t_hit = t + alpha * (t_new - t);

            % append hit point and NaN separator so plotting starts a new segment
            idx = idx + 1; rpath(idx) = x_hit; zpath(idx) = z_hit; tpath(idx) = t_hit;
            second_last_finite_idx = last_finite_idx;
            last_finite_idx = idx;

            idx = idx + 1; rpath(idx) = NaN; zpath(idx) = NaN; tpath(idx) = NaN;

            % perfect specular reflection
            theta = -theta;

            % advance the remaining fraction of the step linearly
            ds_rem = ds * (1 - alpha);  % remaining arc length
            if ds_rem > 0
                % use a single linear update for remainder
                x = x_hit + ds_rem * cos(theta);
                z = z_hit + ds_rem * sin(theta);
                c_at_hit = c_of_z(z_hit);
                t = t_hit + ds_rem / c_at_hit;
                idx = idx + 1; rpath(idx) = x; zpath(idx) = z; tpath(idx) = t;
                second_last_finite_idx = last_finite_idx;
                last_finite_idx = idx;
            else
                x = x_hit; z = z_hit; t = t_hit;
            end
        else
            x = x_new; z = z_new; theta = theta_new; t = t_new;
            idx = idx + 1; rpath(idx) = x; zpath(idx) = z; tpath(idx) = t;
            second_last_finite_idx = last_finite_idx;
            last_finite_idx = idx;
        end

        % CHECK FOR EIGENRAYS using tracked finite indices
        if second_last_finite_idx > 0 && ~found
            i1 = second_last_finite_idx;
            i2 = last_finite_idx;
            r1 = rpath(i1); z1 = zpath(i1); t1 = tpath(i1);
            r2 = rpath(i2); z2 = zpath(i2); t2 = tpath(i2);

            % see if the ray crossed r_rec between r1 and r2
            if ( (r1 <= r_rec && r2 >= r_rec) || (r1 >= r_rec && r2 <= r_rec) ) && abs(r2-r1) > 1e-12
                alpha = (r_rec - r1) / (r2 - r1);
                z_at_r = z1 + alpha*(z2 - z1);
                t_at_r = t1 + alpha*(t2 - t1);

                % EIGENRAY FOUND HERE
                if abs(z_at_r - z_rec) <= depth_tol
                    entry.theta0 = angles(ia);
                    entry.rpath = rpath(1:idx);
                    entry.zpath = zpath(1:idx);
                    entry.tt = tpath(1:idx);
                    entry.z_at_r = z_at_r;
                    entry.t_at_r = t_at_r;
                    
                    % CALCULATING EIGENRAY PATH LENGTH
                    finite_idx = find(~isnan(rpath(1:idx)));
                    pos_i1 = find(finite_idx == i1, 1);
                    path_len = 0;
                    if pos_i1 > 1
                        for kkf = 1:(pos_i1-1)
                            ind_a = finite_idx(kkf);
                            ind_b = finite_idx(kkf+1);
                            dr = rpath(ind_b) - rpath(ind_a);
                            dz = zpath(ind_b) - zpath(ind_a);
                            path_len = path_len + sqrt(dr.^2 + dz.^2);
                        end
                    end
                    seg_dist = sqrt( (r2 - r1)^2 + (z2 - z1)^2 );
                    path_len = path_len + alpha * seg_dist;

                    % ABSORPTION LOSS CALCULATION
                    path_len_km =path_len/1000;
                    alpha_dB_per_km = thorp_absorption(f/1000);
                    ABSORPTION_abs_dB = alpha_dB_per_km * path_len_km;
                    A_abs = 10^(-ABSORPTION_abs_dB / 20);
                    
                    % TRANSMISSION LOSS WITH 1 KM SPHERICAL ATTENUATION, REST
                    % CYLINDRICAL
                    if path_len > r_transition
                        TLdB = 20 * log10(r_transition) + 10*log10(path_len-r_transition);
                    else
                        TLdB = 20 * log10(path_len);
                    end
                    TL_abs = 10^(-TLdB / 20);
                    entry.path_len = path_len;
                    amplitudeLinear =  A0 * A_abs * TL_abs * A_reflection;
                    entry.A_at_r = 20*log10(amplitudeLinear);
                    entry.n_surface = n_surface_bounces;
                    entry.n_bottom = n_bottom_bounces;
                    eigenrays{end+1} = entry;
                    found = true;
                end
            end
        end

        % stop if ray goes far beyond receiver range
        if x > r_rec + 1000
            break;
        end
    end
end

%% ----------------- Print eigenray diagnostics -----------------
fprintf('\n=== EIGENRAY DIAGNOSTICS ===\n');
fprintf('Found %d eigenrays:\n', length(eigenrays));
for k = 1:length(eigenrays)
    er = eigenrays{k};
    fprintf('Eigenray %d: Launch angle = %.2f°, Bounces: %dB/%dS, Time = %.2f s, Amp = %.2f dB\n', ...
            k, rad2deg(er.theta0), er.n_bottom, er.n_surface, er.t_at_r, er.A_at_r);
end
fprintf('============================\n\n');

%% ----------------- Plotting (fan + eigenrays) -----------------
figure('Color','w','Position',[200 200 1000 600]); hold on; box on;
nfan = 101;
angles_plot = linspace(-25,25,nfan);
for i = 1:length(angles_plot)
    th = deg2rad(angles_plot(i));
    theta = th; x = r_s; z = z_s;
    r_plot = x; z_plot = z;
    for kk = 1:5000
        if x > r_rec*1.05 || z < 0 || z > 10000, break; end
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa = -g_local .* cos(theta) ./ c_curr;
        theta_new = theta + ds * kappa;
        x_new = x + ds * cos(theta);
        z_new = z + ds * sin(theta);

        % reflection handling for plotting rayfan as well
        if (z_new < z_min) || (z_new > z_max)
            if z_new < z_min
                alpha = (z_min - z) / (z_new - z);
                z_hit = z_min;
            else
                alpha = (z_max - z) / (z_new - z);
                z_hit = z_max;
            end
            alpha = max(0,min(1,alpha));
            x_hit = x + alpha * (x_new - x);
            r_plot(end+1) = x_hit; z_plot(end+1) = z_hit;
            r_plot(end+1) = NaN; z_plot(end+1) = NaN;
            theta = -theta;
            ds_rem = ds * (1 - alpha);
            if ds_rem > 0
                x = x_hit + ds_rem * cos(theta);
                z = z_hit + ds_rem * sin(theta);
                r_plot(end+1) = x; z_plot(end+1) = z;
            else
                x = x_hit; z = z_hit;
            end
        else
            % no reflection
            theta = theta_new;
            x = x_new; z = z_new;
            r_plot(end+1) = x; z_plot(end+1) = z;
        end
    end
    plot(r_plot/1000, z_plot, 'Color', [0.8 0.8 0.8]);
end

% plot eigenrays
for k = 1:length(eigenrays)
    er = eigenrays{k};
    er_z = er.zpath;
    er_z(er_z < z_min) = z_min;
    er_z(er_z > z_max) = z_max;
    plot(er.rpath/1000, er_z, 'LineWidth',2);
    plot(r_rec/1000, er.z_at_r, 'ro', 'MarkerFaceColor','r');
end

rectangle('Position',[0 z_max r_rec/1000 z_max+500], ...
         'FaceColor',[0.6 0.3 0],'EdgeColor','black','LineWidth', 1);

rectangle('Position',[0 (-500) r_rec/1000 500], ...
        'FaceColor',[0.5 0.7 1], 'EdgeColor','blue','LineWidth',1);

% mark source and receiver
plot(r_s/1000, z_s, 'kp', 'MarkerFaceColor','k', 'MarkerSize',10);
plot(r_rec/1000, z_rec, 'mo', 'MarkerFaceColor','m', 'MarkerSize',8);

xlabel('Range (km)'); ylabel('Depth (m)');
set(gca,'YDir','reverse');
title('Ray fan and eigenrays using discretized curvature');
xlim([0 r_rec/1000]); ylim([z_min - 200 z_max+400]); grid on;

%% ----------------- Arrival time vs Amplitude plot  -----------------

if ~isempty(eigenrays)
    times = zeros(1, length(eigenrays));
    amps  = zeros(1, length(eigenrays));
    angles0 = zeros(1, length(eigenrays));
    pathlens = zeros(1, length(eigenrays));
    for k = 1:length(eigenrays)
        times(k) = eigenrays{k}.t_at_r;    % arrival time (s)
        amps(k) = eigenrays{k}.A_at_r;     % amplitude (dB)
        angles0(k) = rad2deg(eigenrays{k}.theta0); % launch angle (degrees)
        pathlens(k) = eigenrays{k}.path_len;
    end

    valid = isfinite(times) & isfinite(amps);
    times = times(valid);
    amps  = amps(valid);
    angles0 = angles0(valid);

    [times, sortIdx] = sort(times);
    amps = amps(sortIdx);
    angles0 = angles0(sortIdx);

    figure('Color','w','Position',[300 300 750 450]); hold on; box on;
    minAmp = min(amps);
    maxAmp = max(amps);
    margin = 6;                      % dB margin below lowest bar
    baseline = minAmp - margin;

    for k = 1:length(times)
        line([times(k) times(k)], [baseline amps(k)], 'LineWidth',2);
        plot(times(k), amps(k), 'ko', 'MarkerFaceColor','k');
        text(times(k), amps(k), sprintf('  %.1f°', angles0(k)), 'FontSize',8);
    end
    xlabel('Arrival time (s)');
    ylabel('Amplitude (dB)');
    title('Eigenray Arrival Time vs Amplitude');
    time_range = max(times) - min(times);
    xlim([min(times)-0.05*time_range, max(times)+0.05*time_range]);
    topPad = 0.15 * (maxAmp - baseline + eps);
    bottomPad = 0.10 * (maxAmp - baseline + eps);
    ylim([baseline, maxAmp + topPad]);
    grid on;
else
    disp('No eigenrays found to plot arrival times/amplitudes.');
end

% Reflection and frequency absorption functions
function R = bottom_reflection(theta_i, c1)
    % Use shared seabed parameters
    shared_params;
    rho1 = seabed.rho_water;
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
    R = (Z2*cos(theta_i) - Z1*cos(theta_t)) / ... % 1.58 page 41
        (Z2*cos(theta_i) + Z1*cos(theta_t));
end

function alpha_loss = thorp_absorption(f_kHz) %% result is in dB/km
    f2 = f_kHz.^2;
    alpha_loss = 3.3e-3 + (0.11 * f2) ./ (1 + f2) ...
          + (44 * f2) ./ (4100 + f2) + 3.0e-4 * f2;
end
