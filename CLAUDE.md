# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Ocean acoustics ray tracing comparison: custom c-linear implementation vs Bellhop (industry standard). See README.md for setup and basic usage.

## Files

- `scenario.env`: Bellhop environment file (source, receiver, sound speed profile, boundaries)
- `compare.m`: Main script - runs both models and generates comparison outputs
- `run_clinear.m`: C-linear ray tracer reading from `scenario.env`
- `run_bellhop.m`: Bellhop wrapper (adds `at/Matlab/` to path, copies env file, runs Bellhop)
- `at/`: Acoustics Toolbox (Bellhop executable and MATLAB utilities)

## Usage

**Test individual models:**
```matlab
run_clinear    % Custom c-linear implementation
run_bellhop    % Bellhop (industry standard)
```

## Architecture

**Comparison workflow (`compare.m`):**
1. Calls `run_clinear` → saves `clinear_output.png`
2. Calls `run_bellhop` → saves `bellhop_output.png`

**C-linear tracer (`run_clinear.m`):**
- Parses `scenario.env` for SSP, source/receiver positions, ray angles, step size
- Traces rays using discretized c-linear method
- Detects eigenrays (rays passing within 10m depth tolerance at receiver range)
- Plots ray fan (background rays) + eigenrays (highlighted)

**Bellhop wrapper (`run_bellhop.m`):**
- Adds `at/Matlab/` and `at/Matlab/Plot/` to MATLAB path
- Copies `scenario.env` to `at/` directory
- Runs Bellhop from `at/` directory
- Uses `plotray()` to visualize results

## scenario.env Format

Standard Bellhop format. Key parameters:
- Line 1: Title
- Line 2: Frequency (Hz)
- Lines 4+: Sound speed profile (depth, speed pairs)
- Source depth, receiver range/depth
- Ray angles (min, max, number of beams)
- Step size for integration

Example: Munk profile, 1000m source/receiver depth, 100km range, -60° to +60° beams.
