# Parameter file comparison

## Format differences

- **scenario.env**: Bellhop's positional text format (line 2 = freq, line 5 = SSP points, etc.)
- **shared_params.m**: MATLAB structs with named fields for clarity

## Bellhop-specific parameters (scenario.env only)

- **SSP representation**: 42 discrete depth/speed pairs (lines 5-47) vs Munk profile formula in shared_params
  - Points generated from Munk formula with c₀=1500, z₀=1300, ε=0.00737 (matches shared_params)
  - Use `generate_munk_ssp.m` to regenerate if parameters change
- **Title**: Line 1 contains "Munk eigenrays" scenario name
- **Bottom properties**: Line 49 includes attenuation (1.9 dB/wavelength) not in shared_params
- **Geometry line**: Line 59 specifies "30.0 100000.0 120.0" (source depth, max range, bottom depth angles)

## Tolerance in shared_params only

- **receiver.tolerance = 5**: Eigenray hit tolerance (m) - not applicable to Bellhop's solver

## Aligned parameters (after fixes)

- Frequency: 100 Hz
- Source: 1000m depth, 0m range
- Receiver: 1000m depth, 100000m range
- Ray fan: -30° to 30°, 10001 rays
- Environment: 0-8000m depth
- Seabed: ρ_water=1000, ρ_bottom=1800, c_bottom=1700
