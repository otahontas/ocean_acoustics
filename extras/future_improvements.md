# Future Improvements for the C-Linear Model

Here is a plan for potential future improvements to the C-Linear model, ordered from easiest to hardest.

## Easy Improvements (Low-hanging fruit)

1.  **Formalize Function Comments**
    *   **What**: Update the comments in `read_scenario.m`, `trace_ray.m`, and `plot_results.m` to match MATLAB's official documentation format (e.g., using `arguments` blocks).
    *   **Why**: This improves the output of the `help` command and makes the functions easier to understand and reuse for others.

2.  **Consolidate Plotting Constants**
    *   **What**: Move the plotting-specific constants (colors, marker sizes, etc.) from `plot_results.m` into the main `clinear.m` function or a dedicated configuration script.
    *   **Why**: This centralizes all configuration in one place, making it easier to change the visual style of the plots.

3.  **Add Error Handling**
    *   **What**: Add a check in `read_scenario.m` to ensure the specified `.env` file exists before trying to open it. You could also add checks to ensure the file has the expected format.
    *   **Why**: This would make the model more robust and provide clearer error messages to the user if the input file is missing or malformed.

## Medium Improvements (Requires more logic)

1.  **Performance Profiling and Optimization**
    *   **What**: Use MATLAB's built-in profiler to analyze the performance of the `trace_ray` function. Look for bottlenecks and optimize them. For example, you could investigate if vectorizing any of the calculations is possible.
    *   **Why**: While the model is already more efficient, profiling is a good practice to find and fix any unexpected performance issues, especially before adding more complex features.

2.  **More Advanced Eigenray Finder**
    *   **What**: The current eigenray finder stops searching after finding the first crossing for a given launch angle. You could extend it to find *all* crossings (i.e., if a ray passes through the receiver depth multiple times).
    *   **Why**: This would provide a more complete picture of the eigenrays for a given scenario.

3.  **Basic Bottom Interaction Model**
    *   **What**: Implement a simple bottom loss model instead of the current perfect specular reflection. This would involve reading the bottom properties from the `scenario.env` file and attenuating the ray's amplitude at each bottom bounce.
    *   **Why**: This is the first step towards a more physically realistic model, as perfect reflection rarely occurs in the real ocean.

## Hard Improvements (Major undertakings)

1.  **Implement a Different Ray Tracing Method**
    *   **What**: Implement a more advanced numerical integration method for the ray equations, such as a 4th-order Runge-Kutta (RK4) integrator, instead of the current Euler method.
    *   **Why**: This would be a great learning exercise and would allow you to compare the accuracy and performance of different numerical methods for the same problem.

2.  **3D Ray Tracing**
    *   **What**: Extend the model from 2D (range and depth) to 3D by adding the cross-range dimension. This would require significant changes to the ray equations and the state variables.
    *   **Why**: This would make the model much more realistic, as it could handle horizontal refraction and other 3D propagation effects.

3.  **GUI for Scenario Editing**
    *   **What**: Create a simple MATLAB App Designer GUI that allows a user to edit the parameters of the `scenario.env` file (e.g., source/receiver depths, SSP points) and save the changes.
    *   **Why**: This would make the entire toolchain much more user-friendly and accessible to users who are not comfortable editing text files directly.
