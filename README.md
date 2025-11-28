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

## Changing parameters

**CRITICAL: Keep `shared_params.m` and `scenario.env` in sync!**

Both files must have identical source/receiver positions and ray fan settings. After changing either file, you must clear the Bellhop cache.

### Step 1: Edit `shared_params.m`

```matlab
source.depth = 100;            % Source depth (m)
receiver.depth = 2000;         % Receiver depth (m)
receiver.range = 15000;        % Distance to receiver (m) - in METERS
ray_fan.num_angles = 501;      % Number of rays (more = slower but more accurate)
ray_fan.angle_min = -20;       % Min launch angle (degrees)
ray_fan.angle_max = 20;        % Max launch angle (degrees)
receiver.tolerance = 10;       % Eigenray depth tolerance (m)
```

### Step 2: Edit `scenario.env` (near bottom of file)

**Units matter:** Bellhop uses **meters** for depths but **kilometers** for range.

```
1
100.0 /                       ! Source depth (m) - must match shared_params.m
1
2000.0 /                      ! Receiver depth (m) - must match shared_params.m
1
15.0 /                        ! Receiver range (km) - must match shared_params.m / 1000
'E'
501                           ! Number of rays - must match shared_params.m
-20.0 20.0 /                  ! Angle range (degrees) - must match shared_params.m
30.0 50.0 120.0               ! Step_size(km) max_range(km) max_depth(m)
```

### Step 3: Clear Bellhop cache

**Required after any parameter change:**

```bash
rm -f at/scenario*
```

### Additional: Changing sound speed profile

If you change SSP parameters in `shared_params.m`, regenerate the SSP section in `scenario.env`:

```matlab
generate_munk_ssp  % Copy output into scenario.env sound speed profile section
```
