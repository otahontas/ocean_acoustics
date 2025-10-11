# Ocean Acoustics Ray Tracing

Compare c-linear ray tracing against Bellhop.


## Requirements & installation

## Install acoustics toolbox (on mac)

Make sure you have installed required deps: `make` (should be installed automatically) & `gfortran` (install with `brew install gfortran`).

To install the toolbox itself, run the installer script: `./install_acoustics_toolbox.sh`. It downloads the acoustics toolbox and installs it to folder `at/`. Script should be idempotent so you can run it again if needed.

## Usage

**Command line:**
```bash
matlab -batch "compare"          # Run comparison
matlab -batch "run_clinear"      # C-linear only
matlab -batch "run_bellhop"      # Bellhop only
```

**MATLAB GUI:**
```matlab
compare          # Run comparison
run_clinear      # C-linear only
run_bellhop      # Bellhop only
```

Generates `clinear_output.png` and `bellhop_output.png` showing ray traces.

## Files

- `scenario.env` - Bellhop configuration (Munk profile, 1000m source/receiver, 100km range)
- `compare.m` - Runs both models and generates comparison outputs
- `run_clinear.m` - C-linear ray tracer reading from `scenario.env`
- `run_bellhop.m` - Bellhop wrapper
- `at/` - Acoustics Toolbox (Bellhop and other models, installed via script)

## Method

C-linear ray tracing (Jensen p.209-211):
- Discretized curvature with Euler integration
- Specular reflections at boundaries
- Eigenray detection at receiver location
