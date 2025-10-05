# Ocean Acoustics Ray Tracing

Compare c-linear ray tracing against Bellhop.


## Requirements & installation

## Install at toolbox

Make sure you have installed needed dependencies: at least `make`, `gfortran`. You can install these with `brew` when using mac.

To install, run the installer script: `./install_acoustics_toolbox.sh`. It downloads the acoustics toolbox and installs it to folder `at/`. Script should be idempotent so you can run it again if needed.

## Usage

```matlab
compare
```

Generates `comparison.png` showing eigenrays from both models side-by-side.

## Files

- `scenario.env` - Bellhop configuration (Munk profile, 1000m source/receiver, 100km range)
- `compare.m` - Runs both models and creates comparison plot
- `discretizedClinearWITHREFLECTIONS.m` - Standalone c-linear tracer (hardcoded Munk)
- `at/` - Acoustics Toolbox (requires Bellhop compiled)

## Method

C-linear ray tracing (Jensen p.209-211):
- Discretized curvature with Euler integration
- Specular reflections at boundaries
- Eigenray detection at receiver location
