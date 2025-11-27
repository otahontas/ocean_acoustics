% Generate Munk profile SSP points for Bellhop scenario.env
% Outputs discrete depth/speed pairs matching shared_params.m formula

shared_params;

% Use same parameters as shared_params.m
c0 = ssp.c0;
z0 = ssp.z0;
epsilon = ssp.epsilon;
max_depth = env.max_depth;

% Generate depths (42 points to match current scenario.env)
depths = linspace(0, max_depth, 42);

% Calculate Munk profile at each depth
speeds = zeros(size(depths));
for i = 1:length(depths)
    z = depths(i);
    eta = 2 * (z - z0) / z0;
    speeds(i) = c0 * (1 + epsilon * (eta - 1 + exp(-eta)));
end

% Print in Bellhop format
fprintf('%d %.2f %.2f\n', length(depths), 0.0, max_depth);
for i = 1:length(depths)
    fprintf('   %.2f  %.2f  /\n', depths(i), speeds(i));
end
