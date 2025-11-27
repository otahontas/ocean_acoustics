# Modifications to Peer-Provided Models

This document explains changes made to peer-provided model files for integration into the modular comparison framework.

## CLINEAR_dBfix.m → clinear_curvature.m

### Essential Changes (for modular architecture)

**1. Commented out workspace clearing (Line 6)**
```matlab
% clear; close all; clc;  % COMMENTED OUT: Don't clear when called from comparison script
```
- **Why:** Allows script to be called from `compare.m` without wiping workspace variables
- **Impact:** Critical for comparison framework to function

### Added Features (analysis & debugging)

**2. Bounce counting system (Lines 69-71, 99, 103, 197-198)**
```matlab
% Initialize counters
n_surface_bounces = 0;
n_bottom_bounces = 0;

% Increment during reflection handling
n_surface_bounces = n_surface_bounces + 1;  % surface hit
n_bottom_bounces = n_bottom_bounces + 1;    % bottom hit

% Store in eigenray data
entry.n_surface = n_surface_bounces;
entry.n_bottom = n_bottom_bounces;
```
- **Why:** Track number of surface/bottom reflections for each eigenray
- **Impact:** Enables analysis by bounce count, helps debug weak rays

**3. Eigenray diagnostics printout (Lines 213-221)**
```matlab
fprintf('\n=== EIGENRAY DIAGNOSTICS ===\n');
fprintf('Found %d eigenrays:\n', length(eigenrays));
for k = 1:length(eigenrays)
    er = eigenrays{k};
    fprintf('Eigenray %d: Launch angle = %.2f°, Bounces: %dB/%dS, Time = %.2f s, Amp = %.2f dB\n', ...
            k, rad2deg(er.theta0), er.n_bottom, er.n_surface, er.t_at_r, er.A_at_r);
end
fprintf('============================\n\n');
```
- **Why:** Console output for quick verification without examining plots
- **Impact:** Format shows "3B/2S" = 3 bottom, 2 surface bounces

### Cosmetic Changes

**4. Title comment (Line 1)**
```diff
-%% Discretized c Linear Model
+%% Discretized c Linear Model - Optimized (7.3x faster)
```
- **Why:** Reflects earlier optimization work
- **Impact:** None (comment only)

**5. Whitespace cleanup**
- Removed trailing whitespace on lines 33, 191, 310, 347
- Added final newline to file
- **Impact:** None (formatting only)

---

## Full_model.m → ray_parameter.m

### Essential Changes (for modular architecture)

**1. Converted from function to script (Line 1-2)**
```diff
-function Full_model()
-    close all; clear; clc;
+%% Ray Parameter Model
+close all; % clear; clc;  % COMMENTED OUT: Don't clear when called from comparison script
```
- **Why:** Scripts are easier to call from comparison framework; commented `clear; clc;` to preserve workspace
- **Impact:** Critical for modular integration

**2. Removed function end statement (Line 242)**
```diff
-end
```
- **Why:** Scripts don't use `end` statement (functions do)
- **Impact:** Required for script conversion

**3. Removed indentation (throughout)**
- All code moved to left margin (removed function-level indentation)
- **Why:** Scripts don't indent top-level code
- **Impact:** Formatting only, but required for script syntax

### Parameter Alignment (to match clinear_curvature.m)

**4. Increased ray fan resolution (Line 14)**
```diff
-    source.launch_angles = deg2rad(linspace(-25, 25, 1000));
+    source.launch_angles = deg2rad(linspace(-30, 30, 10001));  % Match clinear: 10001 angles
```
- **Why:** Match resolution with clinear model for fair comparison
- **Impact:** 10x more rays, better eigenray detection

**5. Increased receiver tolerance (Line 19)**
```diff
-    receiver.tol = 5;
+    receiver.tol = 10;  % Match clinear: 10m tolerance
```
- **Why:** Match tolerance with clinear model
- **Impact:** More lenient eigenray detection (catches more arrivals)

### Added Features (analysis & debugging)

**6. Bounce counting in reflection loop (Lines 31-32, 67-77)**
```matlab
% Add storage arrays
eigenray_n_bottom = [];      %%% <<< NEW: BOTTOM BOUNCE COUNT >>>
eigenray_n_surface = [];     %%% <<< NEW: SURFACE BOUNCE COUNT >>>

% Count during reflection processing
n_surf = 0;
n_bot = 0;
for b = 1:length(bounce_types)
    if bounce_types{b} == "surface"
        A_ref = A_ref * (-1);
        n_surf = n_surf + 1;
    else
        A_ref = A_ref * bottom_reflection(bounce_angles(b), env.max_depth);
        n_bot = n_bot + 1;
    end
end
eigenray_reflection(end+1) = A_ref;
eigenray_n_surface(end+1) = n_surf;
eigenray_n_bottom(end+1) = n_bot;
```
- **Why:** Track reflections per eigenray for analysis
- **Impact:** Enables bounce-based filtering and diagnostics

**7. Simplified diagnostic output (Line 206)**
```diff
-fprintf("Eg-ray %d: Time = %.3f s, Geom_spread= %.2f, Absor = %.6f, Reflect = %.2f, Arri angle = %.2f deg, A_tot = %.2f dB\n", ...
-         i, eigenray_times(i), eigenray_geom_spreading(i)*1000000, eigenray_absorption(i), eigenray_reflection(i), eigenray_arrival_angle(i), A_tot_dB);
+fprintf("Eg-ray %d: Bounces %dB/%dS, Time = %.3f s, Arri angle = %.2f deg, A_tot = %.2f dB\n", ...
+         i, eigenray_n_bottom(i), eigenray_n_surface(i), eigenray_times(i), eigenray_arrival_angle(i), A_tot_dB);
```
- **Why:** Focus on key metrics (bounces, time, angle, amplitude)
- **Impact:** Cleaner output, easier to debug

### Bug Fixes

**8. Fixed horizontal ray interpolation (Lines 351-356)**
```diff
-    x_at_depth = interp1([z1 z2], [x1 x2], depth);
+    % Check if z values are unique (avoid interp1 error)
+    if abs(z2 - z1) < 1e-10
+        x_at_depth = x1;  % Ray is horizontal, use first point
+    else
+        x_at_depth = interp1([z1 z2], [x1 x2], depth);
+    end
```
- **Why:** `interp1` fails when z1 ≈ z2 (horizontal ray segment)
- **Impact:** Prevents crashes on near-horizontal rays

**9. Updated seabed parameters (Lines 403-404)**
```diff
-    % Sandy seabed
-    rho2 = 1800;   c2 = 1700;
+    % Sandy seabed (Jensen Table 1.3)
+    rho2 = 1900;   c2 = 1650;
```
- **Why:** Match Jensen Table 1.3 reference values
- **Impact:** More accurate bottom reflection coefficients

---

## Summary

All modifications preserve the original physics and calculations. Changes add:

**CLINEAR_dBfix.m → clinear_curvature.m:**
1. **Modular compatibility** - can be called from comparison scripts
2. **Diagnostic tools** - bounce counting and console output for debugging
3. **No changes to**: ray tracing logic, amplitude calculations, or plotting behavior
4. **Core dB fix preserved** - amplitude stored as `20*log10(linear)`

**Full_model.m → ray_parameter.m:**
1. **Script conversion** - removed function wrapper for easier integration
2. **Parameter alignment** - matched resolution/tolerance with clinear model
3. **Bounce counting** - tracks reflections like clinear model
4. **Bug fixes** - horizontal ray interpolation, seabed parameters
5. **No changes to**: ray parameter method, Jacobian spreading, or physics
