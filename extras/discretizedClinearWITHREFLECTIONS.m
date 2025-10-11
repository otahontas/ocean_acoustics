%% Discretized c Linear Model
% Based on the c linear method described by Jensen on p. 209-211
% Uses local curvature R = c(z) / ( g_local * cos(theta) )
% Integrates dx/ds = cos(theta), dz/ds = sin(theta), dtheta/ds = g_local*cos(theta)/c

clear; close all; clc;

%% ----------------- User parameters -----------------

% Source/receiver
z_s = 1000;    % source depth (m)
r_s = 0;       % source range (m)
r_rec = 100000; % receiver range (m)
z_rec = 1000;  % receiver depth (m)

% Ray fan
angles_deg = linspace(-60,60,1001);
angles = deg2rad(angles_deg);
depth_tol = 10; % eigenray hit tolerance (m)

% Numerical stepping
ds = 30.0; % arc-length step (m)
max_steps = 5e6;
max_range = r_rec * 1.2;

% Boundaries
z_min = 0; % surface (m)
z_max = 8000; % bottom (m)

%% ----------------- Sound speed and derivative (Munk) -----------------
% Munk SSP
c0 = 1450;           % reference speed (m/s)
z0_munk = 1300;      % reference depth (m)
eps_munk = 0.01;     % scale epsilon
B = 800;             % scale depth (m)

c_of_z = @(z) c0 .* ( 1 + eps_munk .* ( ((z - z0_munk)./B) - 1 + exp(-(z - z0_munk)./B) ) );
% analytic derivative of Munk
dc_dz = @(z) c0 .* eps_munk .* (1./B) .* ( 1 - exp( -(z - z0_munk)./B ) );

figure()
zplot = linspace(0, z_max);
cplot = c_of_z(zplot);
plot(cplot, -zplot, 'LineWidth',1.6);
title('Sound speed profile');
xlabel('Speed of sound (m/s)'); ylabel('Depth (m)');

%% ----------------- Ray tracing (discretized curvature) -----------------
eigenrays = {};

% FOR EACH RAY IN FAN
for ia = 1:length(angles)
    theta = angles(ia); % launch angle (rad)
    x = r_s; z = z_s; t = 0; % x-coordinate (m), z-coordinate(m), time of travel (s)
    rpath = x; zpath = z; tpath = t;
    step = 0;
    found = false;

    % COMPUTING C LINEAR CURVATURE FOR EACH DISCRETIZED STEP
    while x <= max_range && step < max_steps
        step = step + 1;
        
        % C LINEAR METHOD CALCULATIONS BASED ON DERIVATIVE OF C(z) AT START
        % OF STEP, CALCULATES THE ARC
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa1 = -(g_local .* cos(theta)) ./ c_curr;
        
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
            else % bottom hit
                alpha = (z_max - z) / (z_new - z);
                z_hit = z_max; 
            end   
            alpha = max(0,min(1,alpha)); 

            % compute hit point (linear along this ds)
            x_hit = x + alpha * (x_new - x); 
            t_hit = t + alpha * (t_new - t);

            % append hit point and NaN separator so plotting starts a new segment
            rpath(end+1) = x_hit; zpath(end+1) = z_hit; tpath(end+1) = t_hit;
            rpath(end+1) = NaN; zpath(end+1) = NaN; tpath(end+1) = NaN;

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
                rpath(end+1) = x; zpath(end+1) = z; tpath(end+1) = t;
            else
                x = x_hit; z = z_hit; t = t_hit; 
            end  
        else
            x = x_new; z = z_new; theta = theta_new; t = t_new;
            rpath(end+1) = x; zpath(end+1) = z; tpath(end+1) = t; 
        end

        % CHECK FOR EIGENRAYS ONLY AT LAST TWO FINITE POINTS
        if length(rpath) >= 2
            finiteIdx = find(isfinite(rpath));
            if numel(finiteIdx) >= 2
                i2 = finiteIdx(end);
                i1 = finiteIdx(end-1);
                r1 = rpath(i1); z1 = zpath(i1); t1 = tpath(i1);
                r2 = rpath(i2); z2 = zpath(i2); t2 = tpath(i2);

                % see if the ray crossed r_rec between r1 and r2
                if ( (r1 <= r_rec && r2 >= r_rec) || (r1 >= r_rec && r2 <= r_rec) ) && abs(r2-r1) > 1e-12
                    alpha = (r_rec - r1) / (r2 - r1);
                    z_at_r = z1 + alpha*(z2 - z1);
                    t_at_r = t1 + alpha*(t2 - t1);
                    if abs(z_at_r - z_rec) <= depth_tol
                        entry.theta0 = angles(ia);
                        entry.rpath = rpath;
                        entry.zpath = zpath;
                        entry.tt = tpath;
                        entry.z_at_r = z_at_r;
                        entry.t_at_r = t_at_r;
                        eigenrays{end+1} = entry;
                        found = true;
                        break;
                    end
                end
            end
        end
        
        % stop if ray goes far beyond receiver range
        if x > r_rec + 1000
            break;
        end
    end
end
%% ----------------- Plotting (fan + eigenrays) -----------------
figure('Color','w','Position',[200 200 1000 600]); hold on; box on;
nfan = 101;
angles_plot = linspace(-30,30,nfan);
for i = 1:length(angles_plot)
    th = deg2rad(angles_plot(i));
    theta = th; x = r_s; z = z_s;
    r_plot = x; z_plot = z;
    for kk = 1:5000
        if x > r_rec*1.05 || z < 0 || z > 10000, break; end
        c_curr = c_of_z(z);
        g_local = dc_dz(z);
        kappa = -(g_local * cos(theta)) / c_curr;
        theta_new = theta + ds * kappa;
        x_new = x + ( sin(theta_new) - sin(theta) ) / kappa;
        z_new = z + ( cos(theta) - cos(theta_new) ) / kappa;

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