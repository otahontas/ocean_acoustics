
# `scenario.env` Variable Usage in `clinear` vs. `bellhop`

This document outlines how variables from the `scenario.env` file are utilized by the custom `clinear` MATLAB model and the industry-standard `bellhop` model.

### 1. Title
*   **clinear**: The title is read from the `.env` file but is **not used** in the current implementation.
*   **bellhop**: Bellhop uses the title directly from the `.env` file to **label the output plots** it generates. In the example `scenario.env`, this is 'Munk eigenrays'.

### 2. Frequency
*   **clinear**: This value is read but **not used**. The `clinear` model is a purely geometric ray tracing model that does not account for frequency-dependent effects like attenuation or scattering.
*   **bellhop**: Frequency is a **fundamental input** for Bellhop. It uses it to calculate wave properties like phase, and to model frequency-dependent acoustic effects such as volume and boundary attenuation.

### 3. Options
*   **clinear**: The options string (e.g., `'CVW'`) is parsed to identify the bottom type. The model uses this to determine how to handle ray reflections at the seafloor.
*   **bellhop**: This string is a **critical set of instructions** for Bellhop that controls the core of its simulation. For example, `'CVW'` typically means:
    *   `C`: Use **C**urvilinear coordinates for the ray trace.
    *   `V`: The medium is described by a sound **V**elocity profile.
    *   `W`: **W**rite the ray coordinates to a `.ray` file for plotting.

### 4. SSP (Sound Speed Profile) Points
*   **clinear**: This is the **most critical environmental input**. The model creates a continuous function for sound speed vs. depth (`c(z)`) by linearly interpolating between these points. This function is then used to calculate the ray paths.
*   **bellhop**: Bellhop also uses these points directly to define the sound speed environment, which is essential for its calculations, whether it's running in ray mode or a more advanced wave theory mode.

### 5. Max Depth
*   **clinear**: The maximum depth is used to define the **bottom of the ocean**. The model detects when a ray's depth exceeds this value to trigger a bottom reflection.
*   **bellhop**: Similarly, Bellhop uses this value to define the depth of the seafloor boundary in its environmental model.

### 6. Bottom Type
*   **clinear**: The model identifies the bottom type (e.g., `'A'` for an acousto-elastic half-space) but the current `trace_ray.m` implementation treats it as a **simple perfectly reflective surface**. It does not model the more complex physics associated with different bottom types.
*   **bellhop**: Bellhop has a sophisticated physics engine for bottom interaction. The `'A'` flag tells it to model the bottom as an **acousto-elastic half-space**, using the detailed properties (P-wave speed, S-wave speed, density, attenuation) provided in the lines that follow. This allows for realistic modeling of energy loss and phase changes upon reflection.

### 7. Bottom Roughness
*   **clinear**: This is **not used**. The model assumes a perfectly smooth, flat bottom.
*   **bellhop**: The `scenario.env` file does not appear to specify bottom roughness. While Bellhop *can* model bottom roughness, it requires a specific option flag (like `'R'`) and associated parameters, which are not present in the current configuration. The parameters seen after the `'A'` line define the material properties of the bottom sediment, not its surface roughness.

### 8. Bottom Properties
This refers to the line: `8000.0 1600.0 0.0 1.5 0.0 0.0 /`
*   **clinear**: These values are read but **not used**. The model treats the bottom as a simple, perfectly reflective boundary.
*   **bellhop**: These are the **parameters for the acousto-elastic half-space** (`'A'`). They typically represent:
    *   Top P-wave speed (1600 m/s)
    *   Bottom P-wave speed (if different)
    *   Top S-wave speed (0.0 m/s, indicating a fluid bottom)
    *   Bottom S-wave speed (if different)
    *   Density (1.5 g/cm³)
    *   P-wave attenuation (0.0 dB/wavelength)
    *   S-wave attenuation (0.0 dB/wavelength)

### 9. Source Depth(s)
*   **clinear**: This is used as the **initial depth (`z_src`)** from which all rays are launched.
*   **bellhop**: This sets the **depth of the acoustic source**. Bellhop can handle multiple source depths, but here only one is specified (1000.0 m).

### 10. Receiver Depth(s)
*   **clinear**: This is the **target depth (`z_rec`)** for eigenray detection. The model checks which of the traced rays cross the receiver range at this specific depth (within a certain tolerance).
*   **bellhop**: This specifies the depth(s) of the receiver(s) for which the acoustic field is calculated.

### 11. Receiver Range(s)
*   **clinear**: This is the **target range (`r_rec`)** for eigenray detection.
*   **bellhop**: This specifies the range(s) of the receiver(s). In this case, it's just one receiver at 100 km.

### 12. Run Type & Beams
This refers to `'E'` and `501`.
*   **clinear**: The run type is not explicitly used, but the number of beams (`501` in the file, but hardcoded to `1001` in `clinear.m`) is used to determine how many initial rays to trace when searching for eigenrays.
*   **bellhop**: The `'E'` specifies the run-type, telling Bellhop to perform an **Eigenray calculation**. The `501` is the number of beams it will trace between the specified launch angles.

### 13. Launch Angles
This refers to `-60.0 60.0 /`.
*   **clinear**: These values (`angle_min`, `angle_max`) define the **angular fan of rays** to be launched from the source. The `linspace` function generates a set of evenly spaced angles between these two bounds.
*   **bellhop**: These are the minimum and maximum launch angles (in degrees) that Bellhop will use for its ray trace.

### 14. Plotting / Calculation Grid
This refers to the final line: `30.0 9000.0 120.0`
*   **clinear**: These values are **not used**. Plotting limits are determined dynamically or are hardcoded in `plot_results.m`.
*   **bellhop**: This line is often used to define the **calculation grid** for certain run types (like transmission loss), but for an eigenray (`'E'`) run, these values are typically ignored as the calculation is tied to the specific receiver locations.
