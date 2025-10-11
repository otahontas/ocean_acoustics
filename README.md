# Ocean Acoustics Ray Tracing

Compare c-linear ray tracing against Bellhop.


## Installation

Requires: `make`, `gfortran` (install with `brew install gfortran`)

Run: `./install_acoustics_toolbox.sh`

## Usage

Command line:
```bash
matlab -batch "compare"
matlab -batch "run_clinear"
matlab -batch "run_bellhop"
```

MATLAB GUI: `compare`, `run_clinear`, `run_bellhop`

Outputs: `clinear_output.png`, `bellhop_output.png`

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
