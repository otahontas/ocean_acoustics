# Results Section Draft

## Structure

### 3.1 Computational Performance

Compare runtime for the same scenario (Munk profile, 100km range, 1000m source/receiver):

**Setup:**
- Environment: macOS ARM64 (M2), MATLAB R2024
- Scenario: Munk SSP, 501 beams (-60° to +60°), 100km range
- Measurements: Average of 10 runs

**Expected Results Table:**

| Method | Runtime (s) | Relative Speed | Beams Traced |
|--------|-------------|----------------|--------------|
| Dumb Euler | X.XX | 1.0x | 501 |
| C-linear | X.XX | X.Xx | 501 |
| Bellhop | X.XX | X.Xx | 501 |

**Discussion points:**
- C-linear should be faster than Euler (better integration scheme)
- Bellhop likely slower due to Gaussian beam calculations
- Trade-off: Bellhop's extra computation buys accuracy near caustics

### 3.2 Eigenray Detection

Compare number and quality of eigenrays found:

**Metrics:**
- Number of eigenrays detected
- Depth accuracy at receiver (within tolerance)
- Visual comparison of ray paths

**Results:**
- Show side-by-side plots (already have: `clinear_output.png`, `bellhop_output.png`)
- Count eigenrays: "C-linear detected N eigenrays, Bellhop detected M eigenrays"
- Explain differences: Bellhop's Gaussian beams can detect arrivals C-linear misses near boundaries

### 3.3 Coherent vs Incoherent Fields (Bellhop only)

Run Bellhop in different modes to show interference patterns:

**Experiment:**
1. Run Bellhop with 'C' (coherent) mode
2. Run Bellhop with 'I' (incoherent) mode
3. Compare transmission loss plots

**Expected observations:**
- Coherent: shows interference fringes, constructive/destructive patterns
- Incoherent: smoother field, no interference structure
- Note: C-linear and Euler implicitly do something like incoherent (no phase tracking)

**Figure:** Two TL plots side by side showing coherent vs incoherent

### 3.4 Boundary Interaction Comparison

Compare how methods handle reflections:

**Test scenarios:**
- Perfect reflection (both should match)
- Realistic seabed parameters (only Bellhop can model acoustic halfspace)

**Observations:**
- C-linear and Euler: specular reflection only
- Bellhop with acoustic halfspace: includes transmission/reflection coefficients, frequency dependence

### 3.5 Accuracy vs Computational Cost

**Summary comparison:**

| Aspect | Dumb Euler | C-linear | Bellhop |
|--------|------------|----------|---------|
| Speed | Fast | Faster | Slower |
| Caustic handling | Poor | Poor | Good |
| Boundary interaction | Simple | Simple | Realistic |
| Phase information | No | No | Yes (coherent mode) |
| Use case | Learning/debug | Fast eigenrays | Production/research |

## Code snippets for generating results

### Timing test:
```matlab
% Run timing comparison
n_runs = 10;
times = struct('euler', [], 'clinear', [], 'bellhop', []);

for i = 1:n_runs
    tic; run_euler; times.euler(i) = toc;
    tic; run_clinear; times.clinear(i) = toc;
    tic; run_bellhop; times.bellhop(i) = toc;
end

mean_times = structfun(@mean, times);
```

### Coherent vs Incoherent test:
```matlab
% Modify scenario.env for coherent
% Line 56: 'C' instead of 'E'
% Run Bellhop and save plot

% Modify scenario.env for incoherent
% Line 56: 'I' instead of 'E'
% Run Bellhop and save plot

% Compare plots
```

## Notes for writing

- Keep results factual, minimize interpretation (save for Discussion)
- Use consistent terminology throughout
- Reference all figures and tables in text
- Highlight unexpected results or interesting observations
- Each subsection should answer: "What did we measure?" and "What did we find?"
