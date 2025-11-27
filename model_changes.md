# Model changes

## CLINEAR_dBfix.m → clinear_curvature.m

- **Externalized configuration**: Replaced hard-coded parameters with `shared_params.m` script
- **Disabled auto-clear**: Commented out `clear; close all; clc;` to allow calling from comparison scripts
- **Added bounce tracking**: Count and store surface/bottom bounces for each eigenray
- **Added diagnostics**: Print eigenray launch angles, bounce counts, arrival times, and amplitudes
- **Shared seabed params**: `bottom_reflection()` now loads seabed properties from `shared_params` instead of hard-coding
- **Fixed time range calc**: Replaced `range(times)` with explicit `max(times) - min(times)`
- **Minor cleanup**: Improved comment formatting

## Full_model.m → ray_parameter.m

- **Externalized configuration**: Replaced hard-coded parameters with `shared_params.m` script
- **Pre-allocation optimization**: Pre-allocate all arrays to max size, trim at end (avoids dynamic growing)
- **Memory optimization**: Store only receiver-crossing data (`ray_receiver_data`) instead of full ray paths for Jacobian computation
- **Bounce counting**: Added `eigenray_n_bottom` and `eigenray_n_surface` tracking during reflection handling
- **Performance tuning**: Increased `ds` from 1.0 to 5.0, reduced `max_steps` from 500k to 100k (5x speedup)
- **Cached SSP parameters**: `sound_speed()` uses persistent variables to avoid repeated `shared_params` loads
- **Robustness**: Added horizontal ray check in `range_at_depth()` to avoid `interp1` errors when `z2 ≈ z1`
- **Output format**: Modified eigenray print to show bounce counts in compact format (e.g., "Bounces 2B/1S")
