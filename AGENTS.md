# Overview

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

Ocean acoustics ray tracing comparison: custom c-linear implementation vs Bellhop (industry standard). See README.md for setup and basic usage.

## Files

- `scenario.env`: Bellhop environment file (source, receiver, SSP, boundaries)
- `compare.m`: Runs both models, generates comparison outputs
- `run_clinear.m`: Simple wrapper for the C-linear model
- `run_bellhop.m`: Simple wrapper for the Bellhop model
- `clinear/`: Folder for the C-linear model implementation
  - `clinear.m`: Main function for the C-linear model
  - `trace_ray.m`: Ray tracing logic
  - `plot_results.m`: Plotting logic
- `utils/`: Folder for utility functions
  - `read_scenario.m`: Reads the `scenario.env` file
  - `generate_munk_env.m`: Generates Bellhop .env files with Munk profile
- `at/`: Acoustics Toolbox

## Architecture

`compare.m` calls `run_clinear` and `run_bellhop`.

`run_clinear.m`: Adds `clinear` and `utils` to the path, then calls the main `clinear` function.

`clinear.m`: Reads the scenario, traces rays to find eigenrays, and plots the results.

`run_bellhop.m`: Initializes the Acoustics Toolbox, copies the env file, runs Bellhop, plots the rays, and cleans up.

## Notes

- `at/bin/*.exe` are native macOS executables (`.exe` is just naming convention used by AT on all platforms)
- Install script uncomments bin path in `at/at_init_matlab.m`
