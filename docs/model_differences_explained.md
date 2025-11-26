# Why the Models Differ: Physical and Numerical Explanations

## Overview
This document explains why clinear_curvature, ray_parameter, and Bellhop produce different eigenray results, even though all implement ray theory with the same physics.

## 1. Numerical Integration Method

### C-Linear Curvature
- **Method**: Euler integration with fixed arc-length step (ds = 5m)
- **Ray path**: Circular arcs (assumes linear sound speed gradient within each step)
- **Error**: O(ds) per step, accumulates over ~20,000 steps
- **Impact**:
  - Arrival times may differ by ~0.1-0.5s due to accumulated discretization error
  - Eigenray detection tolerance (10m depth) means some eigenrays near threshold may be missed/found differently

### Ray Parameter
- **Method**: Snell's law constant (p) with smaller step (ds = 1m)
- **Ray path**: Computed from p·c(z) = cos(θ), auto-detects turning points
- **Error**: Smaller per-step error due to finer discretization
- **Impact**:
  - More accurate arrival times (finer sampling)
  - Better resolution of eigenray depth at receiver

### Bellhop
- **Method**: Adaptive Runge-Kutta with variable step size
- **Ray path**: Gaussian beams (finite width, not infinitesimal rays)
- **Error**: Adaptive error control, typically < 0.01%
- **Impact**:
  - Most accurate timing and amplitudes
  - Beam spreading prevents caustic singularities

**Expected Difference**: Arrival time differences of 0.1-1.0s between models are normal and reflect different numerical schemes.

---

## 2. Eigenray Detection Criteria

### C-Linear & Ray Parameter
- **Criterion**: Ray passes within 10m depth tolerance at receiver range
- **Method**: Linear interpolation to find exact crossing point
- **Issue**: Steep-angle rays may "skip over" the tolerance window if step size is too large

### Bellhop
- **Criterion**: Beam center passes within specified tolerance
- **Method**: Adaptive integration ensures accurate boundary crossing
- **Advantage**: Beam width provides natural tolerance; less sensitive to step size

**Expected Difference**: Some eigenrays near grazing angles (θ ≈ 0° or θ ≈ ±90°) may be found by one model but not another.

---

## 3. Amplitude Calculation

### C-Linear Curvature
- **Geometrical spreading**: Spherical up to r_t=8km, then cylindrical
  - TL = 20log(r) for r < 8km
  - TL = 20log(8km) + 10log(r/8km) for r ≥ 8km
- **Limitation**: Doesn't account for ray focusing/defocusing (caustics)

### Ray Parameter
- **Geometrical spreading**: Jacobian-based (Jensen Eq. 3.56)
  - A = (1/4π)√(c_r·cos(θ₀)/(c_s·J))
  - J = |r/sin(θ) · dr/dθ₀|
- **Advantage**: Captures ray tube expansion/contraction
- **Limitation**: Requires neighboring ray data (numerical derivative)

### Bellhop
- **Geometrical spreading**: Beam amplitude evolution via coupled ODEs
- **Advantage**: Most accurate; handles caustics without singularities
- **Gold standard**: Bellhop amplitudes are considered ground truth

**Expected Difference**:
- C-Linear vs Bellhop: ±5-15 dB (especially near caustics)
- Ray Parameter vs Bellhop: ±2-8 dB (better but still approximate)
- Direct paths (0B/0S): Smallest differences (~2-5 dB)
- Multi-bounce paths: Larger differences (~10-20 dB) due to accumulated errors

---

## 4. Reflection Loss Implementation

### All Three Models
- **Surface**: Perfect pressure-release (R = -1, no loss)
- **Bottom**: Plane wave reflection coefficient
  - Z = ρ·c
  - R = (Z₂cos(θᵢ) - Z₁cos(θₜ))/(Z₂cos(θᵢ) + Z₁cos(θₜ))
  - Sandy seabed: ρ₂=1900 kg/m³, c₂=1650 m/s

**Expected Difference**: Minimal (< 1 dB) if using same parameters. Differences arise from:
- Slightly different bounce angles due to ray path discretization
- Bellhop may use more sophisticated boundary models (frequency-dependent)

---

## 5. Boundary Interaction Handling

### C-Linear & Ray Parameter
- **Method**: Linear interpolation to find hit point, then specular reflection
- **Assumption**: Perfect boundaries (instantaneous reflection)
- **Issue**: May miss grazing-angle interactions if step crosses boundary at shallow angle

### Bellhop
- **Method**: Beam interacts with boundaries using Gaussian beam theory
- **Advantage**: Smooth treatment of near-grazing rays
- **Boundary models**: Can use frequency-dependent impedance (acoustic halfspace)

**Expected Difference**: Eigenrays with grazing angles (θ < 5° or θ > 85° from horizontal) may differ significantly.

---

## 6. Sound Speed Profile Representation

### All Models Use Munk Profile
- C-Linear: Analytic formula with dc/dz computed via finite difference
- Ray Parameter: Same analytic formula
- Bellhop: Reads discretized SSP from .env file (42 depth points)

**Expected Difference**:
- Minimal at most depths
- Bellhop interpolates between SSP points, may have slight differences in regions of high curvature

---

## Summary: When to Expect Agreement

| Eigenray Type | Expected Agreement | Typical Differences |
|---------------|-------------------|---------------------|
| **Direct (0B/0S)** | Excellent | Δt < 0.2s, ΔA < 3 dB |
| **Single bounce (1B/0S or 0B/1S)** | Good | Δt < 0.5s, ΔA < 5 dB |
| **Multi-bounce (2B/1S, etc.)** | Moderate | Δt < 1.0s, ΔA < 10 dB |
| **Complex (3B/3S+)** | Poor | Δt > 1.0s, ΔA > 15 dB |

**Bellhop is the reference**: When models disagree, Bellhop is typically more accurate due to:
1. Adaptive integration (better numerics)
2. Gaussian beams (no caustic singularities)
3. Validated against analytical solutions

**For the paper**: Emphasize that differences are expected and quantify them. The goal is not perfect agreement, but understanding *why* they differ and *by how much*.
