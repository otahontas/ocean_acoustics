# Presentation guide for ocean acoustics results

**Your section: Slides 7-11 (Comparing with Bellhop + Results)**
**Time: 2-4 minutes**
**Date: December 2, 2025**

---

## Presentation script

### Slide 7: "Comparing with Bellhop" (~15 seconds)

"Now let's look at how our models compared to Bellhop, which is a professional beam tracing program. We focused on two main things: ray tracing with eigenray detection, and calculating the impulse response at the receiver."

---

### Slide 8: Eigenray comparison (~45 seconds)

- single case: source and receiver at 1000m (1km), then range between 100km
- also similar sound speed profile (munk profile)
- "The Munk profile is an idealized sound speed profile for deep ocean water. It has that characteristic sound channel where speed is minimum around 1300 meters depth, then increases both upward and downward. We used it because it's a standard benchmark in ocean acoustics—it captures the key features of real deep-water propagation without the complexity of real-world variability. 
- and also 

"Here's something interesting we found. Our c-linear model detected 54 eigenrays—these are the sound paths that actually reach the receiver. The geometric ray tracing model also found 54. But Bellhop only identified 24.

This difference isn't about accuracy—it's about detection philosophy. Our models scan through many rays and report anything passing near the receiver. 

-  "Bellhop uses a more sophisticated selection approach—it identifies rays based on beam
  convergence criteria rather than just geometric proximity. So while we detected 54 paths
  within our 5-meter tolerance, Bellhop identified 24 that are more significant from a
  beam-tracing perspective."
- Bellhop uses Gaussian beam tracing where each ray has a finite width, rather than treating rays as infinitely thin lines like we did. This means Bellhop can evaluate whether a path actually delivers significant acoustic energy to the receiver, not just whether it geometrically passes nearby. That's why it identifies fewer eigenrays—it's being more selective about what counts as a meaningful arrival

Bellhop is smarter—it only picks the energetically dominant paths, the ones that actually carry most of the acoustic energy.

You can see the ray paths look quite similar across all three models, which tells us our implementations captured the right physics."

---

### Slide 9: Impulse response (~60 seconds)

"Looking at the impulse response—this shows when sound arrives and how strong it is. Both our models show the first ray arrives around 66.6 seconds.

Here's something cool about ocean acoustics: 

the first ray to reach the receiver was actually launched at a steeper angle, not straight ahead. 

Why? Because even though it travels a longer path, it spends more time in regions where sound travels faster—near the edges of the sound channel axis. This is a classic deep-water acoustics phenomenon.

The c-linear model on the left shows very consistent amplitudes around -128 dB for most arrivals. 

The geometric ray tracing on the right shows more variation, from -116 to -167 dB, because it uses Jacobian-based spreading which captures focusing and defocusing effects—basically, where rays converge and diverge."

---

### Slide 10: Conclusions (~45 seconds)

"So what did we learn?

First, the high eigenray count in our models—54 versus Bellhop's 24—comes down to our detection tolerance. We're basically being less selective about what counts as an eigenray.

Second, the ray path characteristics match Bellhop quite well, which I think validates our implementation.

Third, the Jacobian-based geometric spreading in our second model actually captures realistic spreading loss—you saw that amplitude variation in the impulse response.

And finally, at our signal frequency of 100 Hz, absorption loss from the seawater itself was basically negligible. At higher frequencies, this would matter more."

---

### Slide 11: Thank you (~5 seconds)

"Thanks for listening—happy to answer questions!"

---

## Quick Bellhop explanation

### Simple version (20 seconds)

"Bellhop is an industry-standard underwater acoustics program developed by Michael Porter. Instead of treating sound as infinitely thin rays like we did, it uses *Gaussian beam tracing*—each ray has a finite width. This helps avoid mathematical problems at caustics, where rays converge. It's basically a more sophisticated approach that's widely used in real ocean acoustics applications."

### If they want more detail

"The key difference is that Bellhop tracks not just the ray path, but also how the 'beam width' evolves. This lets it handle interference patterns and wave effects that pure ray tracing misses. It's computationally more expensive, but more physically accurate."

---

## Anticipated questions & answers

### 1. "Why did you get 54 eigenrays while Bellhop got 24?"

**Answer:**
"It comes down to detection criteria. Our models scan through 10,001 rays and flag anything passing within 5 meters of the receiver depth. Bellhop uses beam convergence criteria and energy thresholds—it only reports paths that contribute significantly to the acoustic field. So our 54 includes many weak paths that Bellhop filtered out. For practical applications, Bellhop's approach is probably more useful since those extra 30 paths don't carry much energy."

---

### 2. "Which spreading loss method is better?"

**Answer:**
"It depends on what you need. The hybrid spherical-cylindrical spreading we used in c-linear is computationally simple and gives stable results—you saw those consistent amplitudes around -128 dB. But it assumes an idealized waveguide and can't capture focusing effects.

The Jacobian-based spreading in geometric ray tracing is more physically realistic—it captures how rays converge and diverge. That's why you see that big amplitude variation. But it can become numerically unstable near caustics. So: simple and stable versus realistic but trickier."

---

### 3. "What are the main limitations of your models?"

**Answer:**
"Several things. First, we assume simple specular reflection at boundaries—real sediments have layered structure that causes frequency-dependent losses. Second, we don't model volume scattering from marine life, which matters for some applications. Third, we're doing incoherent summation—we're not tracking phase, so we can't capture interference patterns. Bellhop does coherent summation properly. And finally, ray theory breaks down at low frequencies or near shadow zones where diffraction matters."

---

### 4. "Why is absorption loss negligible at 100 Hz?"

**Answer:**
"Underwater sound absorption increases dramatically with frequency—it's in that formula we showed with all the frequency-squared terms. 

At 100 Hz, even over 100 kilometers, you only lose about 0.5 dB from absorption. But if we were working at, say, 10 kHz, absorption would dominate. 

That's why submarines use low frequencies for long-range communication—the ocean is incredibly transparent to low-frequency sound."

---

### 5. "What's the Munk profile and why did you use it?"

**Answer:**
"The Munk profile is an idealized sound speed profile for deep ocean water. It has that characteristic sound channel where speed is minimum around 1300 meters depth, then increases both upward and downward. We used it because it's a standard benchmark in ocean acoustics—it captures the key features of real deep-water propagation without the complexity of real-world variability. Basically, it's the 'spherical cow' of ocean acoustics."

---

### 6. "How did you verify your results were correct?"

**Answer:**
"That was actually my main role in the team—running the Bellhop verification. We set up identical environmental parameters in all three models: same Munk profile, same source and receiver positions, same bottom properties. Then we compared ray paths, eigenray counts, and arrival times. The fact that our ray paths matched Bellhop's geometry closely, and arrival times were consistent, gave us confidence the physics was right. The amplitude differences reflect different spreading models, which is expected."

---

### 7. "What would you do differently if you did this again?"

**Answer:**
"A few things. First, I'd implement proper caustic handling in the Jacobian method—maybe using a hybrid approach that switches methods near singularities. Second, I'd add coherent summation capability to compare pressure fields, not just ray arrivals. Third, testing with range-dependent environments would be interesting—our models assume the ocean is horizontally stratified, but real oceans vary with range too. And finally, validating against measured data, not just another model, would be the gold standard."

---

### 8. "What's an eigenray exactly?"

**Answer:**
"An eigenray is simply a ray path that connects the source to the receiver. In our setup, we launch thousands of rays at different angles from the source. Most of them miss the receiver. The ones that happen to pass through the receiver location—those are eigenrays. Each one represents a possible propagation path, and they arrive at different times depending on their path length and the sound speed along that path."

---

### 9. "Why does the first arrival come from a steeper angle?"

**Answer:**
"The general principle is that in a sound channel, rays traveling at steeper angles spend more time in regions where sound travels faster—away from the channel axis. So even though they travel a longer geometric path, they can arrive earlier because they're moving through faster water. It's like taking a highway that's longer in distance but faster than a shorter route through city streets. The exact angle depends on the specific profile and geometry."

**Note:** Be conservative about citing exact angle values since those are scenario-specific and might not be precise.

---

### 10. "How long did these simulations take to run?"

**Answer:**
"The custom models were very fast—under a second for the geometric ray tracing, slightly longer for c-linear because of the circular arc calculations. Bellhop was slower because of its adaptive step sizing and beam tracking, but still quite reasonable. Ray-based methods are generally very computationally efficient, which is why they're popular for real-time applications. Methods like parabolic equation or normal modes would be much more expensive, especially at higher frequencies."

---

## General strategy for tough questions

### Buying time techniques
1. **"That's a great question"** — buys you 2 seconds to think
2. **Admit what you don't know**: "I'd have to check the exact numbers, but the principle is..."
3. **Redirect to what you know**: "What I can tell you is..."
4. **Reference the paper**: "We discuss this more in section X of the paper"
5. **Defer to teammates**: "Hocine/Atte implemented that part—they could give you more detail"

### Red flags to avoid
- Don't invent numbers you're not sure about
- Don't oversell the accuracy ("perfect match" → "good agreement")
- Don't dismiss Bellhop's lower eigenray count as wrong—it's a design choice

---

## Practice drill

Try answering these out loud (15 seconds each):

1. **"So which model is best?"**
   - Focus on: depends on application, tradeoffs between simplicity and realism

2. **"Why use ray tracing at all?"**
   - Focus on: computational efficiency, good for high frequencies and long ranges, geometric intuition

3. **"What did you personally contribute?"**
   - Focus on: Bellhop verification, comparison analysis, maintaining the paper

---

## Key technical terms to be comfortable with

- **Eigenray**: ray path connecting source to receiver
- **Caustic**: region where rays converge (amplitude singularity in pure ray theory)
- **Jacobian**: mathematical term for how ray tube area changes
- **Spreading loss**: amplitude decrease due to geometric divergence
- **Sound channel**: depth where sound speed reaches minimum
- **Munk profile**: idealized deep-water sound speed profile
- **Gaussian beam tracing**: ray method with finite beam width
- **Coherent vs incoherent summation**: phase-preserving vs intensity-only

---

## Timing breakdown

- Slide 7: 15s
- Slide 8: 45s
- Slide 9: 60s
- Slide 10: 45s
- Slide 11: 5s

**Total: ~2 minutes 50 seconds**

If you need to shorten: reduce slide 9 impulse response explanation
If you have more time: expand on practical applications or Jacobian spreading

---

## Final checklist before presenting

- [ ] Read through script once out loud
- [ ] Practice the Bellhop explanation
- [ ] Review the 3 practice drill questions
- [ ] Glance at the paper's results section
- [ ] Take a deep breath—you got this!

---

Good luck! 🎯
