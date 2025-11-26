# Paper Finalization TODO List
**Created**: 2025-11-26
**Based on**: Elouan's feedback + current paper state

---

## Current Paper Status

### ✅ COMPLETE Sections
- **Introduction**: Sound propagation, SSP, Snell's law, Munk profile
- **Reflections**: Surface and bottom reflection physics
- **Volume scattering**: Fish effects (may not be needed for final paper - discuss)
- **Sound propagation models**: Ray theory, normal modes, PE methods overview
- **Methods - Geometric Ray Tracing**: Basic ray parameter method (Section 2.1)
- **Methods - C-linear**: Cell method implementation (Section 2.2)
- **Methods - Bellhop**: Beam tracing description (Section 2.3)

### ❌ MISSING Sections
- **Abstract** (100-200 words)
- **Results** section (entire section!)
- **Discussion** section (entire section!)
- **Summary/Conclusions** section

### ⚠️ NEEDS UPDATES (based on Elouan's feedback)
- **Section 1.3 "Transfer loss"** → Change title to **"Transmission Loss"**
- **Methods Section 2.1-2.2**: Add transmission loss implementation details
- **Methods Section 2.2**: Add step size justification
- **Methods Sections**: Update reflection parameters to Jensen Table 1.3

---

## TODO LIST (Prioritized)

### CRITICAL - Must Do Before Submission

#### 1. **Fix Terminology: "Transfer loss" → "Transmission Loss"**
**File**: `ARP_Paper/main.tex`, line 118
**Action**:
```latex
% CHANGE THIS:
\subsection{Transfer loss}

% TO THIS:
\subsection{Transmission Loss}
```
**Then update section text** to clarify components:
```latex
Transmission loss (TL) represents the total amplitude reduction from
source to receiver, comprising three components:
\begin{itemize}
    \item \textbf{Geometrical spreading loss}: Amplitude decay from
          wavefront expansion (spherical or cylindrical)
    \item \textbf{Absorption loss}: Frequency-dependent volume
          attenuation described by the Thorp formula (Eq. \ref{eq:attenuationfrequency})
    \item \textbf{Reflection loss}: Energy lost at boundary interactions
\end{itemize}
The total transmission loss in decibels is:
TL_{\text{total}} = TL_{\text{spreading}} + TL_{\text{absorption}} + TL_{\text{reflection}}
```

**Source**: Can copy from `docs/plans/2025-11-26-elouan-feedback-implementation.md` lines 12-18

---

#### 2. **Update Methods: Add Transmission Loss Implementation**

**Location**: After Section 2.2 (c-linear), add new subsection

**Action**: Add this subsection to Methods:

```latex
\subsection{Amplitude Calculation and Transmission Loss}

Both ray tracing models compute eigenray amplitudes by accounting for
geometrical spreading, absorption, and reflection losses.

\subsubsection{Geometrical Spreading}

Two spreading models were implemented for comparison:

\textbf{Simple model (clinear\_curvature):} Uses spherical spreading
up to a transition range $r_t$, then cylindrical spreading beyond:
\begin{equation}
TL_{\text{spreading}} = \begin{cases}
20 \log_{10}(r) & r < r_t \\
20 \log_{10}(r_t) + 10 \log_{10}(r/r_t) & r \geq r_t
\end{cases}
\end{equation}
where $r_t = 8000$ m (equal to water depth $H$) marks the transition
from near-field spherical to far-field waveguide propagation.

\textbf{Jacobian model (ray\_parameter):} Uses ray-tube spreading based
on Jensen Eq. 3.56:
\begin{equation}
A_{\text{geom}} = \frac{1}{4\pi} \sqrt{\left|\frac{c_r \cos\theta_0}{c_s J(s)}\right|}
\end{equation}
where $J(s) = |r/\sin\theta \cdot dr/d\theta_0|$ is the Jacobian
measuring ray tube divergence at the receiver.

\subsubsection{Absorption Loss}

Volume absorption follows the Thorp formula (Eq. \ref{eq:attenuationfrequency})
at $f = 50$ Hz. The absorption loss over path length $L$ (in km) is:
\begin{equation}
TL_{\text{absorption}} = \alpha(f) \times L
\end{equation}
where $\alpha$ is in dB/km.

\subsubsection{Reflection Loss}

Bottom reflection uses the plane wave reflection coefficient (Jensen Eq. 1.58):
\begin{equation}
R = \frac{Z_2\cos\theta_i - Z_1\cos\theta_t}{Z_2\cos\theta_i + Z_1\cos\theta_t}
\end{equation}
where $Z_i = \rho_i c_i$ are acoustic impedances, and $\theta_t$ follows
from Snell's law. Parameters from Jensen Table 1.3 for sandy sediment:
\begin{itemize}
    \item Water: $\rho_1 = 1000$ kg/m³, $c_1 = c(z)$
    \item Sand: $\rho_2 = 1900$ kg/m³, $c_2 = 1650$ m/s
\end{itemize}
Surface reflections are treated as perfect pressure-release boundaries ($R = -1$).
```

**Source**: Copy from `docs/plans/2025-11-26-elouan-feedback-implementation.md`

---

#### 3. **Update Methods: Add Step Size Justification**

**Location**: In Section 2.2 "Implementation" subsection, add paragraph

**Action**: Add after line 236:

```latex
The arc-length step size was set to $\Delta s = 5$ m, which is less than
$\lambda/4$ for the 50 Hz source frequency ($\lambda \approx 30$ m).
This choice ensures that (1) the linear sound speed approximation within
each step remains accurate ($\Delta c/c < 0.01\%$), and (2) numerical
integration error is minimized over the 100 km propagation range. Empirical
testing showed that larger step sizes ($\Delta s > 10$ m) introduced noticeable
variations in eigenray arrival times due to accumulated discretization errors.
```

**Source**: Copy from `docs/step-size-justification.md` lines 43-46

---

#### 4. **Write RESULTS Section** (ENTIRELY NEW)

**Location**: After Methods section, before Bibliography

**Structure**:
```latex
\section{RESULTS}

\subsection{Eigenray Detection}

All three models successfully identified eigenrays connecting the source
(depth 1000 m, range 0 km) to the receiver (depth 1000 m, range 100 km)
in the Munk sound speed environment.

[INSERT TABLE HERE comparing eigenrays found by each model]

The c-linear curvature model identified 115 eigenrays, including:
- Direct/refracted paths (0 bounces): ~100 eigenrays
- Bottom-Surface-Bottom (2B/1S): 1 eigenray
- Multiple bounce patterns: up to 3B/4S

[DISCUSS which eigenrays each model found, compare to Bellhop]

\subsection{Impulse Response Comparison}

Figure X shows the impulse response (arrival time vs amplitude) for all
three models.

[INSERT FIGURE: 3-panel or overlay plot of impulse responses]

Key observations:
- Direct path eigenrays arrive at ~66.6 s with amplitude -89.5 dB
- B/S/B eigenray (#110) arrives at 67.5 s with amplitude -109.3 dB
  (0.9 s delay, 20 dB weaker due to bottom reflection loss)
- [Compare timing and amplitudes across models]

\subsection{Ray Fan Diagrams}

Figure Y shows ray fan diagrams for all three models.

[INSERT FIGURE: Side-by-side ray fans]

[Describe similarities and differences in ray paths]

\subsection{Geometrical Spreading Comparison}

[Compare simple spherical/cylindrical vs Jacobian spreading]
[Which matches Bellhop better?]
```

**Action needed**:
1. Run all 3 models with ds=5m
2. Generate comparison plots
3. Fill in results with actual numbers
4. Create figures and add to paper

---

#### 5. **Write DISCUSSION Section** (ENTIRELY NEW)

**Structure**:
```latex
\section{DISCUSSION}

\subsection{Model Accuracy}

[Discuss how well each model matches Bellhop]
[Explain why differences occur]

\subsection{Computational Efficiency}

[Compare runtime: clinear vs ray_parameter vs Bellhop]
[Discuss trade-offs between accuracy and speed]

\subsection{Physical Insights}

The B/S/B eigenray (2B/1S) demonstrates the importance of bottom
reflection modeling. This eigenray arrives 0.9 s later than direct
paths and is 20 dB weaker, validating the implementation of Jensen's
reflection coefficient with sandy seabed parameters.

[Discuss other physical insights from results]

\subsection{Limitations}

- Ray theory limitations (no diffraction, no interference)
- Assumption of range-independent environment
- Perfect specular surface reflection (no sea-state effects)
- [Other limitations]
```

---

#### 6. **Write ABSTRACT** (LAST - after Results/Discussion are done)

**Requirements**: 100-200 words covering:
- Motivation (1-2 sentences)
- Problem statement (1 sentence)
- Approach (2-3 sentences)
- Results (2-3 sentences)
- Implications (1-2 sentences)

**Template**:
```latex
\abstract{%
Ocean acoustic propagation is essential for [motivation: sonar, marine
mammal protection, etc.]. Accurate prediction requires models that balance
physical realism with computational efficiency. This study compares two
custom ray-tracing implementations—a c-linear method and a ray-parameter
method—against the industry-standard Bellhop beam tracer. Both models
incorporate geometrical spreading (spherical/cylindrical and Jacobian),
frequency-dependent absorption (Thorp formula), and angle-dependent bottom
reflections (sandy sediment). [State key results: eigenray detection,
amplitude accuracy, etc.]. The comparison demonstrates [key findings:
which model is more accurate, computational trade-offs, etc.]. These
results provide [implications: guidance for model selection, validation
of physics implementations, etc.].
}
```

---

### IMPORTANT - Before Running Final Models

#### 7. **Verify Model Parameters Match**

**Check these files are consistent**:

| Parameter | File | Current Value | Should Be |
|-----------|------|---------------|-----------|
| Frequency | `clinear_curvature.m` line 32 | 50 Hz | 50 Hz ✓ |
| Frequency | `ray_parameter.m` line 22 | 50 Hz | 50 Hz ✓ |
| Step size | `clinear_curvature.m` line 22 | 30 m | **Change to 5 m** |
| Step size | `ray_parameter.m` line 251 | 1 m | **OK (already fine)** |
| Sand ρ₂ | `clinear_curvature.m` line 330 | 1900 kg/m³ | 1900 ✓ |
| Sand c₂ | `clinear_curvature.m` line 330 | 1650 m/s | 1650 ✓ |
| Sand ρ₂ | `ray_parameter.m` line 393 | 1900 kg/m³ | 1900 ✓ |
| Sand c₂ | `ray_parameter.m` line 393 | 1650 m/s | 1650 ✓ |

**CRITICAL**: Change `clinear_curvature.m` line 22:
```matlab
ds = 5.0; % arc-length step (m) - CHANGE FROM 30.0 to 5.0
```

---

### NICE TO HAVE (If Time Permits)

#### 8. **Remove Volume Scattering Section?**
**Consideration**: Section 1.4 "Volume scattering (fish)" is interesting
but not directly used in your models. Discuss with team if it should stay
or be removed to keep paper focused.

#### 9. **Add More Figures**
- Ray fan comparison (3 panels side-by-side)
- Impulse response overlay (all 3 models)
- Sound speed profile with eigenray paths highlighted
- Reflection coefficient vs grazing angle (validate against Jensen Fig 1.24)

#### 10. **Add Acknowledgments**
Thank Elouan Even for feedback and supervision.

---

## Execution Plan (Suggested Order)

### Day 1 (Wednesday meeting prep):
1. ✅ Fix terminology (transfer → transmission loss) **[15 min]**
2. ✅ Update step size in clinear_curvature.m to 5m **[1 min]**
3. ✅ Run all 3 models with final parameters **[10 min total]**
4. ✅ Generate comparison figures **[30 min]**

### Day 2-3 (After meeting, before submission):
5. ✅ Add transmission loss subsection to Methods **[1 hour]**
6. ✅ Add step size justification to Methods **[15 min]**
7. ✅ Write Results section **[2-3 hours]**
8. ✅ Write Discussion section **[1-2 hours]**
9. ✅ Write Abstract **[30 min]**
10. ✅ Final proofread and formatting **[1 hour]**

**Total estimated time**: ~8-10 hours of focused writing

---

## Files You Have Ready to Use

All these files have copy-pasteable text:

1. **`docs/ANSWERS_TO_YOUR_QUESTIONS.md`** - All question answers
2. **`docs/step-size-justification.md`** - Step size text for Methods
3. **`docs/plans/2025-11-26-elouan-feedback-implementation.md`** - All technical details
4. **Your model output** - Eigenray data already generated!

---

## Summary Checklist

### Content Completeness:
- [ ] Abstract written
- [ ] Introduction complete (already done ✓)
- [ ] Methods complete with TL details
- [ ] Results section written
- [ ] Discussion section written
- [ ] Conclusions/Summary written
- [ ] Bibliography complete

### Technical Accuracy (Elouan's Feedback):
- [ ] Terminology: "Transmission Loss" not "Transfer Loss"
- [ ] Reflection params: Jensen Table 1.3 (ρ₂=1900, c₂=1650) ✓ (in code)
- [ ] Transition range: r_t = 8 km ✓ (in code)
- [ ] Plots: dB scale, 80 dB dynamic range ✓ (in code)
- [ ] B/S/B eigenray: Found ✓
- [ ] Step size: ds=5m for final results

### Code Ready:
- [ ] clinear_curvature.m: ds=5m (currently 30m - **CHANGE THIS**)
- [x] ray_parameter.m: All parameters correct
- [x] Both models: f=50Hz, Jensen sand params

### Figures Needed:
- [ ] Ray fan comparison (3 models)
- [ ] Impulse response comparison
- [ ] (Optional) Reflection coefficient validation plot

**When this checklist is complete → Paper is ready for submission!** ✓

