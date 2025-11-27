# Paper Integration Checklist - Results & Discussion

**Goal**: Add Results and Discussion sections to your paper
**Time needed**: ~30 minutes for basic integration

---

## Quick Start (3 Steps)

### Step 1: Open the paper
```bash
cd /Users/otahontas/Code/studying/ocean_acoustics/ARP_Paper
# Open main.tex in your editor
```

### Step 2: Find insertion point
Look for line ~277 in `main.tex` (just before `\bibliographystyle{jaes}`):
```latex
... (end of Methods section)

%Bibliography   ← YOU'LL INSERT BEFORE THIS LINE
\bibliographystyle{jaes}
\bibliography{jaes}
```

### Step 3: Copy-paste sections
Open `docs/RESULTS_SECTION_DRAFT.md` and `docs/DISCUSSION_SECTION_DRAFT.md`

Copy the LaTeX code blocks into your paper between Methods and Bibliography.

**Done!** Build the paper and see how it looks.

---

## Detailed Integration Steps

### A. Choose Your Version

**For each section**, pick based on space constraints:

| Section | Full Version | Concise Version | When to Use |
|---------|--------------|-----------------|-------------|
| **Results** | ~400 words | ~200 words | Full: detailed analysis needed<br>Concise: page limit tight |
| **Discussion** | ~1000 words | ~400 words | Full: comprehensive treatment<br>Concise: conference paper |

**Recommendation**: Start with **full versions**, then trim if needed.

---

### B. Add Results Section

**Location**: After Section 2 (METHODS), before Bibliography

**Copy this from** `docs/RESULTS_SECTION_DRAFT.md`:

```latex
\section{RESULTS}

\subsection{Eigenray Detection}

Both ray tracing models successfully identified eigenrays connecting the source (depth 1000~m, range 0~km) to the receiver (depth 1000~m, range 100~km) in the Munk sound speed environment. Table~\ref{tab:eigenrays} summarizes the eigenray detection results and quantitative comparison between the two models.

\begin{table}[h]
\centering
\caption{Eigenray Detection and Comparison}
\label{tab:eigenrays}
\begin{tabular}{lccc}
\hline
Model & N Eigenrays & $\Delta$Time vs C-Linear (s) & $\Delta$Amplitude vs C-Linear (dB) \\
\hline
C-Linear Curvature & 113 & --- & --- \\
Ray Parameter & 115 & $0.002 \pm 0.013$ & $-47.15 \pm 8.83$ \\
\hline
\end{tabular}
\end{table}

... (continue with rest of Results section)
```

**Paste into `main.tex`** after line ~277.

---

### C. Add Discussion Section

**Copy this from** `docs/DISCUSSION_SECTION_DRAFT.md`:

```latex
\section{DISCUSSION}

\subsection{Model Agreement and Numerical Accuracy}

The excellent timing agreement between the two ray tracing implementations ($\Delta t = 0.002 \pm 0.013$~s) demonstrates that both numerical schemes correctly solve the fundamental ray trajectory equations...

... (continue with rest of Discussion section)
```

**Paste into `main.tex`** after Results section.

---

### D. Build and Check

```bash
cd ARP_Paper
./build.sh
# Or manually:
pdflatex main.tex
bibtex main
pdflatex main.tex
pdflatex main.tex
```

**Check**:
- [ ] PDF compiles without errors
- [ ] Table renders correctly
- [ ] Equation references work (Eq. 1.58, Eq. 3.56, etc.)
- [ ] Citation placeholders are OK (update if needed)
- [ ] Sections flow logically: Intro → Methods → Results → Discussion

---

## Customization Options

### Option 1: Add Figure Placeholders (if figures not ready)

In Results section, add:

```latex
\subsection{Ray Path Visualization}

Figure~\ref{fig:rayfan} shows the ray fan comparison between the two models
(figure generation in progress).

% \begin{figure}[h]
% \centering
% % \includegraphics[width=0.8\textwidth]{figures/ray_fan_comparison.png}
% \caption{Ray fan comparison: c-linear (left) vs ray parameter (right)}
% \label{fig:rayfan}
% \end{figure}
```

Comment out figure commands, add note "(figure generation in progress)".

### Option 2: Remove Figure References (minimal version)

Simply delete any mentions of "Figure~\ref{...}" and keep text-only descriptions.

### Option 3: Add Bellhop Row (when available)

In the table, add third row:

```latex
\hline
C-Linear Curvature & 113 & --- & --- \\
Ray Parameter & 115 & $0.002 \pm 0.013$ & $-47.15 \pm 8.83$ \\
Bellhop & XXX & $YYY \pm ZZZ$ & $AAA \pm BBB$ \\  % ← ADD THIS
\hline
```

Fill in XXX, YYY, ZZZ, AAA, BBB when Bellhop results are available.

---

## Common Issues and Fixes

### Issue 1: "Undefined control sequence \pazocal"

**Cause**: \pazocal used in Discussion for reflection coefficient

**Fix**: Already defined in paper header (line 10):
```latex
\newcommand{\pazocal}{\mathcal}
```

Should work fine. If not, replace `\pazocal{R}` with `\mathcal{R}`.

### Issue 2: Missing references (Eq. X.XX)

**Cause**: Discussion references equations from Methods section

**Fix**: Check equation labels in Methods:
- `\label{eq:snellslaw}` - Snell's law
- `\label{eq:attenuationfrequency}` - Thorp absorption formula

Update references if label names differ.

### Issue 3: Table too wide

**Cause**: Long column headers

**Fix**: Use `\small` or abbreviate headers:
```latex
\begin{table}[h]
\centering
\small  % ← ADD THIS
\caption{Eigenray Detection and Comparison}
...
```

Or abbreviate: "$\Delta$Time (s)" instead of "$\Delta$Time vs C-Linear (s)"

### Issue 4: Discussion too long

**Cause**: Full version is ~1000 words

**Fix**: Use concise version from `DISCUSSION_SECTION_DRAFT.md`
Or remove subsections:
- Keep: Model Agreement, Spreading Models, Limitations
- Remove: Computational Efficiency, Implications (move to Conclusions)

---

## Validation Checklist

After integration, verify:

### Content ✓
- [ ] Results section present (eigenrays, timing, amplitude, B/S/B)
- [ ] Discussion section present (agreement, spreading, validation, limitations)
- [ ] Table with correct numbers (113, 115, 0.002 ± 0.013, -47.15 ± 8.83)
- [ ] Physical interpretation of 47 dB difference
- [ ] B/S/B eigenray mentioned (67.52 s, -109.2 dB, 20 dB loss)

### Formatting ✓
- [ ] Section numbering correct (\section{RESULTS}, \section{DISCUSSION})
- [ ] Table formatted properly (caption, label, columns aligned)
- [ ] Equation references work (\ref{eq:snellslaw}, etc.)
- [ ] Math mode correct ($...$, $$...$$)
- [ ] Units consistent (m, s, dB, Hz)

### Flow ✓
- [ ] Results presents findings objectively
- [ ] Discussion interprets findings
- [ ] Limitations acknowledged
- [ ] Future work mentioned
- [ ] Transitions smooth between subsections

### References ✓
- [ ] Citations to Jensen book (`\cite{Jensen}`)
- [ ] Table references (`Table~\ref{tab:eigenrays}`)
- [ ] Equation references correct
- [ ] Figure references (if figures added)

---

## What Success Looks Like

**After integration**, your paper should have:

1. **Complete structure**:
   - Introduction ✓ (existing)
   - Methods ✓ (existing)
   - Results ✓ (newly added)
   - Discussion ✓ (newly added)
   - Bibliography ✓ (existing)

2. **Coherent narrative**:
   - Methods → describes what you did
   - Results → presents what you found
   - Discussion → explains what it means

3. **Quantitative evidence**:
   - Table with comparison metrics
   - Clear numbers (113 eigenrays, 0.002 s agreement, etc.)
   - Physical validation (B/S/B eigenray)

4. **Balanced tone**:
   - Acknowledges strengths (timing agreement)
   - Explains differences (spreading models)
   - Notes limitations (ray theory assumptions)

---

## Time Estimates

| Task | Time | Cumulative |
|------|------|------------|
| Open files and locate insertion point | 2 min | 2 min |
| Copy-paste Results section | 5 min | 7 min |
| Copy-paste Discussion section | 5 min | 12 min |
| Build PDF and check compilation | 3 min | 15 min |
| Read through and verify content | 10 min | 25 min |
| Fix any formatting issues | 5 min | 30 min |

**Total: ~30 minutes** for basic integration.

**With customization**: Add 15-30 minutes for:
- Adding figure placeholders
- Adjusting for page limits
- Updating references
- Fine-tuning formatting

---

## After Integration

### Next immediate steps:

1. **Proofread**: Read Results and Discussion in context of full paper
2. **Ask for feedback**: Share PDF with team/advisor
3. **Iterate**: Adjust based on feedback

### Later (if time permits):

4. **Generate figures**: Run `generate_comparisons.m` to create plots
5. **Add figures**: Insert ray fan and impulse response figures
6. **Write Abstract**: Use template from `PAPER_FINALIZATION_TODO.md`
7. **Add Bellhop**: When Bellhop results available, extend comparison

### Before submission:

8. **Final proofread**: Check grammar, spelling, formatting
9. **Verify references**: All citations correct and complete
10. **Check guidelines**: Journal style requirements met

---

## Need Help?

If you encounter issues:

1. **LaTeX compilation errors**: Check line numbers, fix syntax
2. **Content questions**: Refer to `RESULTS_AND_DISCUSSION_SUMMARY.md`
3. **Physics interpretation**: See `model_differences_explained.md`
4. **Technical details**: Check `SESSION_STATUS.md`

**All documentation is in `docs/` folder!**

---

## Summary

**What you have**:
✅ Complete Results section (ready to paste)
✅ Complete Discussion section (ready to paste)
✅ Supporting data and figures (eigenray table)
✅ Full documentation (summaries, explanations)

**What to do**:
1. Open `main.tex`
2. Find insertion point (before Bibliography)
3. Copy sections from draft files
4. Build PDF
5. Check and proofread

**Time needed**: ~30 minutes

**You're ready to finalize the paper!** 🚀
