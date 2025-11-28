# Ocean acoustics comparisons

## Installation

Requires: `make`, `gfortran` (install for mac with `brew install gfortran`)

Run: `./install_acoustics_toolbox.sh` (needed for bellhop)

## Running models

Compare all three models:
```matlab
compare
```

Run individual models:
```matlab
clinear_curvature  % C-linear curvature model
ray_parameter      % Ray parameter model
run_bellhop        % Bellhop reference
```

Results saved to:
- `comparison_results.txt` - eigenray data
- `figures/` - ray diagrams and arrival plots

## Quick parameter changes

Edit `shared_params.m`:
```matlab
receiver.range = 50000;        % Distance to receiver (m)
receiver.depth = 1000;         % Receiver depth (m)
source.depth = 1000;           % Source depth (m)
ray_fan.num_angles = 501;      % Number of rays (more = slower but more accurate)
ray_fan.angle_min = -20;       % Min launch angle (degrees)
ray_fan.angle_max = 20;        % Max launch angle (degrees)
receiver.tolerance = 10;       % Eigenray depth tolerance (m)
```

Edit `scenario.env` for Bellhop (near bottom of file):
```
1
100.0 /                       ! Source depth (m)
1
2000.0 /                      ! Receiver depth (m)
1
15.0 /                        ! Receiver range (km) - Bellhop uses km for range
'E'
501                           # Number of rays
-20.0 20.0 /                  # Angle range (degrees)
30.0 50.0 120.0               # Step_size(km) max_range(km) max_depth(m)
```

**Important notes:**
- **Units in scenario.env:** Depths use **meters**, range uses **kilometers** (Bellhop convention)
- Range conversion: scenario.env uses km, shared_params.m uses meters (e.g., 15.0 km = 15000 m)
- After changing scenario.env, delete Bellhop cache: `rm scenario*.arr scenario*.ray at/scenario*`
- If you change SSP parameters in shared_params, regenerate scenario.env SSP section:
  ```matlab
  generate_munk_ssp  % Copy output into scenario.env sound speed profile section
  ```
