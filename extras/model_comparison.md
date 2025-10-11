# Model Comparison: `clinear` vs. `discretizedClinearWITHREFLECTIONS.m`

This document outlines the key differences in application logic and structure between the current `clinear` model and the original `discretizedClinearWITHREFLECTIONS.m` script.

While both versions share the same core physics (the c-linear ray tracing method), the current setup is a significant architectural improvement.

### 1. Configuration and Data Source

*   **`discretizedClinearWITHREFLECTIONS.m` (Old Version):**
    *   **Hardcoded Parameters**: All parameters, including the source/receiver geometry and the sound speed profile (a mathematical Munk profile), are defined directly in the "User parameters" section of the script. To change the scenario, you have to edit the code.

*   **Current `clinear` Model:**
    *   **External Configuration**: The model is completely decoupled from the scenario. It reads all its parameters from the `scenario.env` file via the `utils/read_scenario.m` function. This is far more flexible, as you can run completely different scenarios without touching the model's code.

### 2. Application Structure

*   **Old Version:**
    *   **Monolithic Script**: Everything is in a single `.m` file. The script defines parameters, runs the ray trace, finds eigenrays, and then runs a *second, duplicated* ray tracing loop just to plot the background ray fan.

*   **Current Model:**
    *   **Modular and Reusable**: The logic is broken into distinct, single-purpose functions organized in folders (`clinear/`, `utils/`).
    *   `run_clinear.m` is a simple top-level script.
    *   `clinear/clinear.m` orchestrates the core logic.
    *   `clinear/trace_ray.m` contains the ray tracing algorithm, which is **reused** by both the eigenray search and the plotting function, eliminating the major code duplication of the old version.

### 3. Sound Speed Profile (SSP) Handling

*   **Old Version:**
    *   **Analytic SSP**: Uses a specific, hardcoded mathematical formula for the Munk sound speed profile and its analytical derivative. It is not designed to work with other sound speed profiles.

*   **Current Model:**
    *   **Generic Tabulated SSP**: It reads a table of depth/sound-speed points from `scenario.env`. It then uses interpolation (`interp1`) to handle the SSP. The gradient (`dc_dz`) is calculated numerically, which means this model can work with **any** tabulated sound speed profile you provide in the `.env` file, not just the Munk profile.

### 4. Efficiency and Implementation Details

*   **Old Version:**
    *   **Dynamic Arrays**: The ray path arrays (`rpath`, `zpath`) grow dynamically inside the main loop (`rpath(end+1) = ...`), which can be inefficient in MATLAB for large arrays.
    *   **Complex Eigenray Check**: The logic to find the last two valid points for checking an eigenray crossing is more complex (`find(isfinite(rpath))`).

*   **Current Model:**
    *   **Pre-allocation**: The `trace_ray` function pre-allocates memory for the path arrays, which is more performant.
    *   **Simplified Eigenray Check**: The logic is simpler and more direct, as it just needs to check the last two valid points that were tracked during the ray trace.

---

In summary, the current `clinear` model is more **flexible**, **maintainable**, and **efficient** than the original monolithic script.
