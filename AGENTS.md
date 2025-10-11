# Overview

This file provides guidance to AI coding agents when working with code in this repository.

## Overview

Ocean acoustics ray tracing comparison: custom c-linear implementation vs Bellhop (industry standard). See README.md for setup and basic usage.

## Files

- `scenario.env`: Bellhop environment file (source, receiver, SSP, boundaries)
- `compare.m`: Runs both models, generates comparison outputs
- `run_clinear.m`: C-linear ray tracer reading from `scenario.env`
- `run_bellhop.m`: Bellhop wrapper (uses `at/at_init_matlab.m` for paths)
- `at/`: Acoustics Toolbox

## Architecture

`compare.m` calls `run_clinear` → `clinear_output.png`, then `run_bellhop` → `bellhop_output.png`

`run_clinear.m`: Parses `scenario.env`, traces rays, detects eigenrays (10m depth tolerance), plots ray fan + eigenrays

`run_bellhop.m`: Init AT paths, copy env file to `at/`, run Bellhop, plot with `plotray()`, cleanup temp files

## Notes

- `at/bin/*.exe` are native macOS executables (`.exe` is just naming convention used by AT on all platforms)
- Install script uncomments bin path in `at/at_init_matlab.m`
