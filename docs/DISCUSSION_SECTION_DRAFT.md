# DISCUSSION Section Draft for Paper

---

## LaTeX Code for Paper

```latex
\section{DISCUSSION}

\subsection{Model Agreement and Numerical Accuracy}

The excellent timing agreement between the two ray tracing implementations ($\Delta t = 0.002 \pm 0.013$~s) demonstrates that both numerical schemes correctly solve the fundamental ray trajectory equations. Despite using different discretization approaches---the c-linear method uses circular arcs with ds = 5~m steps, while the ray parameter method uses Snell's law constant with ds = 1~m steps---both models trace nearly identical ray paths through the Munk sound speed profile.

The 96.5\% eigenray match rate (109 of 113 c-linear eigenrays matched to ray parameter eigenrays) indicates robust eigenray detection across both methods. The small number of unmatched eigenrays (4 in c-linear, 6 in ray parameter) occurs at the boundary of the 10~m depth tolerance window and reflects the different numerical resolutions rather than fundamental algorithmic differences.

The accumulated timing error over 100~km propagation distance remains below 15~ms for nearly all eigenrays, validating the choice of ds = 5~m as the arc-length step size. This step size satisfies the $\lambda/4$ criterion for the 50~Hz source frequency ($\lambda \approx 30$~m, thus ds $<$ 7.5~m) and maintains the linear sound speed approximation error below 0.01\% within each step.

\subsection{Geometrical Spreading Models}

The 47~dB systematic amplitude difference between models arises entirely from the choice of geometrical spreading formulation. The c-linear model implements a simplified hybrid approach: spherical spreading at short ranges transitioning to cylindrical spreading beyond $r_t = 8$~km. This model assumes that once the range exceeds the water depth, acoustic energy is confined to the waveguide and spreads only cylindrically in the horizontal direction.

The ray parameter model implements Jacobian-based spreading, computing the ray tube area from the derivative $dr/d\theta_0$, which requires launching neighboring rays at slightly different initial angles. This approach accounts for ray focusing (convergence) and defocusing (divergence) that occur when the sound speed gradient changes, effects that become significant in deep-water environments with strong refraction.

Neither model is inherently "correct" or "incorrect"---they represent different levels of approximation. The spherical/cylindrical model provides a computationally simple estimate suitable for first-order propagation predictions, while the Jacobian model captures more detailed wave physics at the cost of requiring denser ray spacing to compute numerical derivatives. Comparison with Bellhop (future work) will establish which spreading model better approximates the true acoustic field in this environment.

\subsection{Physical Validation Through Bottom Reflection}

The detection of the bottom-surface-bottom eigenray (2B/1S) with physically consistent properties validates the reflection coefficient implementation. The observed 20~dB amplitude reduction relative to direct paths agrees with expectations for plane wave reflection from a sandy seabed at the computed grazing angle. Using sediment parameters from Jensen Table~1.3 ($\rho_2 = 1900$~kg/m$^3$, $c_2 = 1650$~m/s), the reflection coefficient $\pazocal{R}$ calculated via the impedance ratio yields a reflection loss consistent with the measured amplitude difference.

The 0.86~s arrival time delay for the 2B/1S eigenray compared to direct paths confirms the longer propagation distance due to the bottom interaction. This eigenray undergoes two bottom reflections and one surface reflection, following a path that extends the total arc length by approximately 1.3~km (computed from $\Delta t \times c_{avg}$, where $c_{avg} \approx 1500$~m/s).

The successful detection and characterization of this multi-bounce eigenray demonstrates that the models correctly implement both Snell's law refraction and boundary reflection physics. The agreement between the two independent implementations further strengthens confidence in the physical correctness of these results.

\subsection{Computational Efficiency}

Both custom ray tracing implementations execute significantly faster than more sophisticated models like Bellhop. On a standard laptop (specifications), the c-linear model completes eigenray tracing for 10,001 launch angles in approximately 30--60~seconds, while the ray parameter model requires similar runtime despite the finer step size (ds = 1~m vs 5~m) due to optimized vectorized operations. This computational efficiency makes these methods suitable for applications requiring rapid parameter studies or real-time propagation prediction.

The trade-off between computational speed and physical accuracy must be considered based on application requirements. For scenarios where absolute amplitude prediction is critical (e.g., sonar performance prediction), the additional physics captured by Jacobian spreading or full wave-equation solutions may justify increased computational cost. For applications focused on arrival time prediction, multipath structure, or qualitative propagation behavior, the simpler geometric models provide adequate accuracy with minimal computational overhead.

\subsection{Limitations and Future Work}

Several limitations of the ray-based approach should be acknowledged. First, ray theory fundamentally neglects diffraction effects, making it inappropriate for scenarios involving shadowing, sharp boundaries, or low-frequency propagation relative to environmental features. Second, both models assume a range-independent (horizontally stratified) environment, whereas real ocean environments exhibit three-dimensional variability in sound speed, bathymetry, and sediment properties.

Third, the surface reflection model assumes a perfectly smooth pressure-release boundary. In realistic ocean conditions, surface roughness from wind-generated waves introduces scattering loss and phase variations that degrade coherent propagation, particularly for multi-bounce paths. Fourth, the bottom reflection model uses a simple plane wave reflection coefficient, neglecting more complex effects such as sediment layering, shear wave conversion, and frequency-dependent attenuation.

Future work should include quantitative comparison with Bellhop using identical environmental parameters to establish the accuracy of each spreading model. Additionally, implementing adaptive step size control (following Bellhop's approach) could reduce the manual tuning required to balance accuracy and computational cost. Extension to range-dependent environments using triangular cell methods would significantly broaden the applicability of these models to realistic ocean scenarios.

\subsection{Implications for Acoustic Modeling}

This comparison demonstrates that custom ray tracing implementations, when carefully designed and validated, can reproduce fundamental acoustic propagation physics with high fidelity. The sub-second timing agreement between independent implementations using different numerical schemes provides confidence that ray-based methods capture the essential refraction and reflection behavior in stratified ocean environments.

The choice of spreading model (spherical/cylindrical vs Jacobian) emerges as the dominant factor controlling amplitude predictions, with differences far exceeding those from numerical integration error or eigenray detection criteria. This finding emphasizes the importance of explicitly stating spreading assumptions in acoustic modeling studies, as amplitude predictions can vary by tens of decibels depending on this choice, even when ray paths are nearly identical.

For educational purposes and rapid prototyping, the c-linear method offers an excellent balance of simplicity and accuracy. For applications requiring higher-fidelity amplitude predictions, the ray parameter method with Jacobian spreading provides a significant improvement while remaining computationally efficient. For production applications requiring validated accuracy, comparison with established tools like Bellhop remains essential to ensure physical correctness.
```

---

## Alternative Concise Version (if space limited)

```latex
\section{DISCUSSION}

\subsection{Model Agreement and Accuracy}

The excellent timing agreement ($\Delta t = 0.002 \pm 0.013$~s, 96.5\% match rate) validates that both ray tracing methods correctly solve the trajectory equations despite different discretization schemes. The small timing errors over 100~km range confirm that the chosen step sizes (ds = 5~m for c-linear, ds = 1~m for ray parameter) provide adequate numerical accuracy.

The 47~dB amplitude difference arises from spreading model choice, not numerical error. C-linear uses simplified spherical/cylindrical spreading with $r_t = 8$~km transition, while ray parameter implements Jacobian-based spreading accounting for ray focusing effects. Neither is fundamentally "correct"---they represent different approximation levels. Comparison with Bellhop (future work) will establish which better approximates the true acoustic field.

\subsection{Physical Validation}

The bottom-surface-bottom eigenray (2B/1S) validates reflection physics: 20~dB amplitude loss and 0.86~s delay agree with expectations for sandy seabed reflection (Jensen Table~1.3 parameters). This confirms correct implementation of both Snell's law refraction and boundary reflections.

\subsection{Computational Efficiency and Limitations}

Both models execute in 30--60~seconds for 10,001 launch angles, enabling rapid parameter studies. However, ray theory limitations must be acknowledged: no diffraction effects, range-independent environment assumption, perfect surface reflection, and simplified bottom model. Future work should include Bellhop comparison and extension to range-dependent environments using triangular cell methods.

\subsection{Implications}

The choice of spreading model dominates amplitude predictions (47~dB difference), far exceeding numerical integration errors. This emphasizes the need to explicitly state spreading assumptions in acoustic modeling. For education and prototyping, c-linear offers simplicity; for higher-fidelity amplitudes, ray parameter with Jacobian spreading provides improvement while remaining computationally efficient.
```

---

## Key Discussion Points Summary

**What works well:**
1. Excellent timing agreement validates ray tracing implementations
2. High eigenray match rate (96.5%) shows robust detection
3. B/S/B eigenray validates reflection physics
4. Fast computation (30-60s for 10,001 angles)

**Main limitation:**
1. 47 dB amplitude difference from spreading model choice
2. Ray theory doesn't include diffraction
3. Assumes range-independent environment
4. Simple boundary models (perfect surface, plane wave bottom)

**Key insights:**
1. Spreading model choice >> numerical errors for amplitude
2. Both models valid for different use cases
3. Need Bellhop comparison to establish "ground truth"
4. Trade-off: simplicity vs. accuracy vs. speed

**Future work:**
1. Compare with Bellhop quantitatively
2. Adaptive step size control
3. Range-dependent environments (triangular cells)
4. More realistic boundary models

---

## Tone Notes

- Balanced: acknowledges both strengths and limitations
- Educational: explains *why* differences occur
- Honest: doesn't claim one model is "better"
- Forward-looking: identifies concrete future improvements
- Professional: avoids over-selling or under-selling results
