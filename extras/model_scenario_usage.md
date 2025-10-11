# How the C-Linear Model Uses scenario.env

This document breaks down how the C-Linear model uses the `scenario.env` file, showing the actual values from the file at each point in the code.

### Sound Speed Profile (`ssp_z`, `ssp_c`)

The 42 data points of depth (`ssp_z`) and sound speed (`ssp_c`) from `scenario.env` are used to create a function that can find the sound speed at any depth.

-   **File**: `clinear/clinear.m`
-   **L10**: `c_of_z = @(z) interp1(scenario.ssp_z, scenario.ssp_c, z, 'linear', 'extrap');`
    -   **Usage with values**: The `scenario.ssp_z` array (containing values from `0.00` to `8000.00`) and the `scenario.ssp_c` array (containing values from `1485.57` to `1556.94`) are used to build the `c_of_z` interpolation function.

### Depth Boundaries (`z_min` = 0.0, `z_max` = 8000.0)

The ocean surface is at `0.0` m and the seafloor is at `8000.0` m.

-   **File**: `clinear/trace_ray.m`
-   **L40**: `if (z_new < 0.0) || (z_new > 8000.0)`
    -   **Usage with values**: Checks if the ray has gone above the surface or below the seafloor.
-   **L43-L47**: These lines calculate the intersection point with either the `0.0` m surface or the `8000.0` m floor for a perfect reflection.
-   **File**: `clinear/plot_results.m`
-   **L35**: `er_z(er_z < 0.0) = 0.0;`
-   **L36**: `er_z(er_z > 8000.0) = 8000.0;`
    -   **Usage with values**: Ensures the plotted eigenrays don't go outside the `0.0` and `8000.0` meter boundaries.
-   **L57**: `ylim([0.0 - 200, 8000.0 + 400]);`
    -   **Usage with values**: Sets the plot's y-axis limits to `[-200, 8400]` to give some padding around the ocean boundaries.

### Source Depth (`z_s` = 1000.0)

The sound source is located at a depth of `1000.0` m.

-   **File**: `clinear/trace_ray.m`
-   **L13**: `x = 0; z = 1000.0; t = 0;`
    -   **Usage with values**: Initializes the starting depth `z` of every ray to `1000.0`.
-   **File**: `clinear/plot_results.m`
-   **L48**: `plot(0, 1000.0, 'kp', ...);`
    -   **Usage with values**: Plots the black source marker at a depth of `1000.0` m at range 0.

### Receiver Depth (`z_rec` = 1000.0) & Range (`r_rec` = 100000.0)

The receiver is at a depth of `1000.0` m and a range of `100.0` km (which is `100000.0` m in the code).

-   **File**: `clinear/clinear.m`
-   **L40**: `if ( (r_start <= 100000.0 && r_end >= 100000.0) || ...`
    -   **Usage with values**: Checks if a ray segment has crossed the `100,000` m receiver range.
-   **L42**: `alpha = (100000.0 - r_start) / (r_end - r_start);`
    -   **Usage with values**: Interpolates to find the ray's depth at exactly `100,000` m.
-   **L46**: `if abs(z_at_r - 1000.0) <= 10`
    -   **Usage with values**: Checks if the ray's depth is within 10 meters of the `1000.0` m receiver depth to be considered an eigenray.
-   **File**: `clinear/trace_ray.m`
-   **L9**: `max_range = 100000.0 * 1.2;`
    -   **Usage with values**: Sets the maximum tracing distance to `120,000` m.
-   **File**: `clinear/plot_results.m`
-   **L49**: `plot(100000.0/1000, 1000.0, 'mo', ...);`
    -   **Usage with values**: Plots the magenta receiver marker at `100` km range and `1000.0` m depth.

### Beam Angles (`angle_min` = -60.0, `angle_max` = 60.0)

The model searches for eigenrays by launching rays at angles from `-60.0` to `+60.0` degrees.

-   **File**: `clinear/clinear.m`
-   **L19**: `angles = deg2rad(linspace(-60.0, 60.0, 1001));`
    -   **Usage with values**: Creates an array of 1001 launch angles evenly spaced between `-60.0` and `+60.0` degrees.

### Step Size (`ds` = 30.0)

The ray path is calculated in discrete steps of `30.0` meters.

-   **File**: `clinear/trace_ray.m`
-   **L34**: `theta_new = theta + 30.0 * kappa1;`
-   **L35**: `x_new = x + 30.0 * cos(theta);`
-   **L36**: `z_new = z + 30.0 * sin(theta);`
-   **L37**: `t_new = t + 30.0 / c_curr;`
    -   **Usage with values**: The `30.0` m step size is used in every iteration of the ray tracing loop to calculate the ray's next position and travel time.
