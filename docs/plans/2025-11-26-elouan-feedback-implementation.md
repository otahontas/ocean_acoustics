# Implementation of Elouan's Feedback
Date: 2025-11-26

## Overview
This document summarizes the changes made to both ray tracing models based on feedback from Elouan Even regarding the final ARP paper.

## Changes Made

### 1. Terminology Clarification
**Issue**: Confusing use of "transfer loss" and "transmission loss"

**Resolution**:
- Follow Jensen's terminology strictly
- **Transmission Loss (TL)** = total amplitude reduction from all mechanisms
- Components:
  - TL_spreading: Geometrical spreading loss
  - TL_absorption: Frequency-dependent volume attenuation (Thorp formula)
  - TL_reflection: Boundary interaction losses

**Formula**: `TL_total = TL_spreading + TL_absorption + TL_reflection` (in dB)

### 2. Bottom Reflection Parameters
**Issue**: Sediment properties didn't match Jensen's published values

**Resolution**:
- Updated to Jensen Table 1.3 (p. 46) exact sand parameters:
  - Water: ρ₁ = 1000 kg/m³, c₁ = sound_speed(z)
  - Sand: ρ₂ = 1900 kg/m³, c₂ = 1650 m/s
- Formula verified against Fig 1.24: `R = (Z₂cosθᵢ - Z₁cosθₜ)/(Z₂cosθᵢ + Z₁cosθₜ)`
- Files modified:
  - `clinear_curvature.m` line 330
  - `ray_parameter.m` line 393

### 3. Geometrical Spreading - Transition Range
**Issue**: Transition range r_t = 1 km was too small for 8 km water depth

**Resolution** (clinear_curvature.m):
- Set r_t = 8000 m (equal to water depth H)
- Physics:
  - Spherical spreading (TL = 20log₁₀(r)) for r < r_t
  - Cylindrical spreading (TL = 10log₁₀(r)) for r > r_t
  - Combined formula: TL = 20log₁₀(r_t) + 10log₁₀(r/r_t) for r > r_t
- **Critical bug fix**: Previous formula used `20*log(path_len-1000)` for cylindrical region - completely wrong!
- Elouan's guidance: r_t should be between H and 3H (we chose H as conservative)

**Note**: ray_parameter.m uses Jacobian-based spreading (more sophisticated) - no change needed

### 4. Plot Improvements
**Issue**: Amplitude in linear scale, poor y-axis, unreadable angle labels

**Resolutions**:

#### Amplitude Scale (both models)
- Convert to dB: `A_dB = 20*log₁₀(|A|)`
- Y-axis: 80 dB dynamic range `ylim([Amax-80, Amax+5])`
- Title: "Impulse Response" for clarity

#### Angle Labels (clinear_curvature.m)
- Removed cluttered launch angle text overlays
- Kept markers and stems for clean visualization
- Note: ray_parameter.m uses color-coded eigenrays with arrival angles - kept as is

### 5. Missing Eigenray Investigation
**Issue**: Missing B/S/B (bottom-surface-bottom) eigenray

**Resolutions** (clinear_curvature.m):
1. **Increased depth tolerance**: 5m → 10m (Elouan's suggestion)
2. **Extended angle range**: ±25° → ±30° (to catch steeper eigenrays)
3. **Added bounce diagnostics**:
   - Track surface bounces: `n_surface_bounces`
   - Track bottom bounces: `n_bottom_bounces`
   - Store with each eigenray
   - Print diagnostic summary:
     ```
     Eigenray 1: Launch angle = -5.23°, Bounces: 2B/1S, Time = 67.45 s, Amp = -87.34 dB
     ```
   - Format: `XB/YS` means X bottom bounces, Y surface bounces

**Expected patterns**:
- Direct: 0B/0S
- Bottom bounce: 1B/0S or 2B/0S
- Surface bounce: 0B/1S
- **B/S/B**: 2B/1S (the missing one we're looking for)

## Model Comparison Strategy

### clinear_curvature.m
- C-linear method (Jensen p. 209-211)
- Simple spreading model: spherical→cylindrical at r_t=8km
- Pedagogical value: clear, straightforward physics
- Good for understanding basic ray tracing

### ray_parameter.m
- Ray parameter method (Snell's constant p)
- Jacobian-based spreading (Jensen Eq. 3.56)
- Most realistic physics
- Closest to Bellhop's internal calculations
- Can toggle between simple spherical and Jacobian

### Bellhop
- Industry standard (ground truth)
- Gaussian beam tracing
- Full-featured acoustic propagation model

## Paper Structure Recommendations

### Methods Section
1. Describe both ray tracing algorithms (c-linear vs ray parameter)
2. Explain transmission loss components:
   - Geometrical spreading (spherical/cylindrical vs Jacobian)
   - Absorption (Thorp formula at f=50 Hz or 100 Hz - verify which!)
   - Reflection (plane wave coefficient, Jensen Eq 1.58)
3. Reference Jensen Table 1.3 for sand parameters

### Results Section
1. Compare eigenray detection: Which model finds all eigenrays?
2. Impulse response comparison: Amplitude and arrival time accuracy
3. Discuss B/S/B eigenray if found: Why does it arrive later but with higher amplitude?
4. Validate against Bellhop as ground truth

## Next Steps

1. **Run models** and verify all eigenrays are found (especially B/S/B)
2. **Generate comparison plots**:
   - Ray fan diagrams (all 3 models side-by-side)
   - Impulse response plots (overlay all 3)
3. **Update paper text**:
   - Fix terminology (transfer→transmission loss)
   - Add r_t justification (why 8 km)
   - Reference Jensen Fig 1.24 and Table 1.3 for reflection
4. **Verify source frequency**: Code shows f=100 Hz (clinear_curvature) and f=50 Hz (ray_parameter) - make consistent!
5. **Compare to Bellhop**: Run all three and analyze differences

## Questions for Discussion

1. What source frequency should we use? (50 Hz or 100 Hz - needs consistency)
2. Should we also test r_t = 3H (24 km) as upper bound?
3. For paper: Show both spreading models or just pick one?
4. Does Bellhop output arrival angles for comparison with ray_parameter.m?
