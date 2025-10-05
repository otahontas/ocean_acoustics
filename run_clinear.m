%% C-Linear Ray Tracer
% Reads scenario.env and traces rays using discretized c-linear method

clear; close all; clc;

%% Read scenario.env
fid = fopen('scenario.env', 'r');
fgetl(fid); fgetl(fid); fgetl(fid); fgetl(fid); % skip header

% SSP
line = strsplit(strtrim(fgetl(fid)));
n_ssp = str2double(line{1});
z_min = str2double(line{2});
z_max = str2double(line{3});

ssp_z = zeros(n_ssp, 1);
ssp_c = zeros(n_ssp, 1);
for i = 1:n_ssp
    line = strsplit(strtrim(fgetl(fid)));
    ssp_z(i) = str2double(line{1});
    ssp_c(i) = str2double(line{2});
end

fgetl(fid); fgetl(fid); % skip boundary lines
fgetl(fid); % skip source count
line = strsplit(strtrim(fgetl(fid)));
z_s = str2double(line{1});
fgetl(fid); % skip receiver depth count
line = strsplit(strtrim(fgetl(fid)));
z_rec = str2double(line{1});
fgetl(fid); % skip receiver range count
line = strsplit(strtrim(fgetl(fid)));
r_rec = str2double(line{1}) * 1000; % km to m
fgetl(fid); fgetl(fid); % skip beam type and count
line = strsplit(strtrim(fgetl(fid)));
angle_min = str2double(line{1});
angle_max = str2double(line{2});
line = strsplit(strtrim(fgetl(fid)));
ds = str2double(line{1});
fclose(fid);

%% Setup
c_of_z = @(z) interp1(ssp_z, ssp_c, z, 'linear', 'extrap');
dc_dz = @(z) (c_of_z(z+0.1) - c_of_z(z-0.1)) / 0.2;

angles = deg2rad(linspace(angle_min, angle_max, 1001));
max_range = r_rec * 1.2;
max_steps = 5e6;
depth_tol = 10;

%% Trace eigenrays
eigenrays = {};

for ia = 1:length(angles)
    theta = angles(ia);
    x = 0; z = z_s; t = 0;

    est_size = min(ceil(max_range/ds)*3, max_steps);
    rpath = zeros(1, est_size);
    zpath = zeros(1, est_size);
    tpath = zeros(1, est_size);
    rpath(1) = x; zpath(1) = z; tpath(1) = t;
    idx = 1;

    step = 0;
    found = false;
    last_finite_idx = 1;
    second_last_finite_idx = 0;

    while x <= max_range && step < max_steps
        step = step + 1;

        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa1 = -(g_local * cos(theta)) / c_curr;

        theta_new = theta + ds * kappa1;
        x_new = x + ds * cos(theta);
        z_new = z + ds * sin(theta);
        t_new = t + ds / c_curr;

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
            t_hit = t + alpha * (t_new - t);

            idx = idx + 1; rpath(idx) = x_hit; zpath(idx) = z_hit; tpath(idx) = t_hit;
            second_last_finite_idx = last_finite_idx;
            last_finite_idx = idx;

            idx = idx + 1; rpath(idx) = NaN; zpath(idx) = NaN; tpath(idx) = NaN;

            theta = -theta;

            ds_rem = ds * (1 - alpha);
            if ds_rem > 0
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

        if second_last_finite_idx > 0 && ~found
            i1 = second_last_finite_idx;
            i2 = last_finite_idx;
            r1 = rpath(i1); z1 = zpath(i1); t1 = tpath(i1);
            r2 = rpath(i2); z2 = zpath(i2); t2 = tpath(i2);

            if ( (r1 <= r_rec && r2 >= r_rec) || (r1 >= r_rec && r2 <= r_rec) ) && abs(r2-r1) > 1e-12
                alpha = (r_rec - r1) / (r2 - r1);
                z_at_r = z1 + alpha*(z2 - z1);
                t_at_r = t1 + alpha*(t2 - t1);
                if abs(z_at_r - z_rec) <= depth_tol
                    entry.theta0 = angles(ia);
                    entry.rpath = rpath(1:idx);
                    entry.zpath = zpath(1:idx);
                    entry.tt = tpath(1:idx);
                    entry.z_at_r = z_at_r;
                    entry.t_at_r = t_at_r;
                    eigenrays{end+1} = entry;
                    found = true;
                    break;
                end
            end
        end

        if x > r_rec + 1000, break; end
    end
end

%% Plot
figure('Color','w','Position',[200 200 1000 600]);
hold on; box on;

% Plot fan
nfan = 101;
angles_plot = linspace(-30,30,nfan);
for i = 1:length(angles_plot)
    th = deg2rad(angles_plot(i));
    theta = th; x = 0; z = z_s;
    r_plot = x; z_plot = z;
    for kk = 1:5000
        if x > r_rec*1.05 || z < 0 || z > 10000, break; end
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa = -(g_local * cos(theta)) / c_curr;
        theta_new = theta + ds * kappa;
        x_new = x + ( sin(theta_new) - sin(theta) ) / kappa;
        z_new = z + ( cos(theta) - cos(theta_new) ) / kappa;

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
            theta = theta_new;
            x = x_new; z = z_new;
            r_plot(end+1) = x; z_plot(end+1) = z;
        end
    end
    plot(r_plot/1000, z_plot, 'Color', [0.8 0.8 0.8]);
end

% Plot eigenrays
for k = 1:length(eigenrays)
    er = eigenrays{k};
    er_z = er.zpath;
    er_z(er_z < z_min) = z_min;
    er_z(er_z > z_max) = z_max;
    plot(er.rpath/1000, er_z, 'LineWidth',2);
    plot(r_rec/1000, er.z_at_r, 'ro', 'MarkerFaceColor','r');
end

% Boundaries
rectangle('Position',[0 z_max r_rec/1000 z_max+500], ...
         'FaceColor',[0.6 0.3 0],'EdgeColor','black','LineWidth', 1);
rectangle('Position',[0 (-500) r_rec/1000 500], ...
        'FaceColor',[0.5 0.7 1], 'EdgeColor','blue','LineWidth',1);

% Source and receiver
plot(0, z_s, 'kp', 'MarkerFaceColor','k', 'MarkerSize',10);
plot(r_rec/1000, z_rec, 'mo', 'MarkerFaceColor','m', 'MarkerSize',8);

xlabel('Range (km)');
ylabel('Depth (m)');
set(gca,'YDir','reverse');
title(sprintf('C-Linear: %d eigenrays', length(eigenrays)));
xlim([0 r_rec/1000]);
ylim([z_min - 200 z_max+400]);
grid on;
