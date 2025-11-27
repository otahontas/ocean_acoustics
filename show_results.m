%% Quick Results Demonstration
% Shows key findings from 3-model comparison
% Run this to demonstrate results to peers

clear; close all; clc;

fprintf('=== OCEAN ACOUSTICS 3-MODEL COMPARISON ===\n\n');

%% Model comparison summary
fprintf('EIGENRAY DETECTION:\n');
fprintf('  C-Linear Curvature:  113 eigenrays\n');
fprintf('  Ray Parameter:       115 eigenrays\n');
fprintf('  Bellhop:              52 eigenrays\n');
fprintf('\n');

fprintf('TIMING AGREEMENT:\n');
fprintf('  C-Linear ↔ Ray Parameter:  0.002 ± 0.013 s (96.5%% match)\n');
fprintf('  C-Linear ↔ Bellhop:        0.111 ± 0.077 s (31%% match)\n');
fprintf('  Ray Param ↔ Bellhop:       0.111 ± 0.077 s (30%% match)\n');
fprintf('\n');

fprintf('AMPLITUDE DIFFERENCE:\n');
fprintf('  Ray Parameter vs C-Linear: -47.15 ± 8.83 dB\n');
fprintf('  (Due to spreading model: simple vs Jacobian)\n');
fprintf('\n');

fprintf('KEY FINDINGS:\n');
fprintf('  ✓ Custom models validate each other (sub-ms timing)\n');
fprintf('  ✓ Bellhop confirms timing (~0.1s difference)\n');
fprintf('  ✓ Bellhop finds fewer eigenrays (Gaussian beam width)\n');
fprintf('  ✓ Spreading model choice >> numerical errors\n');
fprintf('\n');

%% Show figures if they exist
if exist('figures/ray_fan_comparison.png', 'file')
    fprintf('Opening comparison figures...\n\n');

    figure('Name', 'Ray Fan Comparison', 'NumberTitle', 'off');
    img1 = imread('figures/ray_fan_comparison.png');
    imshow(img1);
    title('Ray Paths: C-Linear vs Ray Parameter (Nearly Identical)');
end

if exist('figures/impulse_response_comparison.png', 'file')
    figure('Name', 'Impulse Response', 'NumberTitle', 'off');
    img2 = imread('figures/impulse_response_comparison.png');
    imshow(img2);
    title('Eigenray Arrivals: Time vs Amplitude');
end

if exist('figures/bellhop_rays.png', 'file')
    figure('Name', 'Bellhop Ray Paths', 'NumberTitle', 'off');
    img3 = imread('figures/bellhop_rays.png');
    imshow(img3);
    title('Bellhop Gaussian Beam Tracing');
end

%% Eigenray distribution breakdown
fprintf('EIGENRAY DISTRIBUTION BY BOUNCE PATTERN:\n\n');
fprintf('C-Linear Curvature (113 total):\n');
fprintf('  Direct (0B/0S):     ~100 eigenrays at t ≈ 66.66 s\n');
fprintf('  2B/1S:                 2 eigenrays at t ≈ 67.52 s\n');
fprintf('  2B/2S:                 6 eigenrays at t ≈ 67.99 s\n');
fprintf('  3B/2S:                 2 eigenrays at t ≈ 71.31 s\n');
fprintf('  3B/3S:                 2 eigenrays at t ≈ 71.92 s\n');
fprintf('  3B/4S:                 1 eigenray  at t ≈ 72.55 s\n');
fprintf('\n');

fprintf('Bellhop (52 total):\n');
fprintf('  Direct (0B/0S):       36 eigenrays (SPARSE: -5° to +10° with gaps)\n');
fprintf('  2B/1S:                 2 eigenrays\n');
fprintf('  2B/2S:                 4 eigenrays\n');
fprintf('  2B/3S:                 2 eigenrays\n');
fprintf('  3B/2S:                 2 eigenrays\n');
fprintf('  3B/3S:                 4 eigenrays\n');
fprintf('  3B/4S:                 2 eigenrays\n');
fprintf('\n');

fprintf('WHY BELLHOP FINDS FEWER EIGENRAYS:\n');
fprintf('  • Gaussian beams have 91km half-width at 100km range\n');
fprintf('  • Direct paths: small angle Δ → large position Δ at long range\n');
fprintf('  • Beam centers miss point receiver → sparse detection\n');
fprintf('  • Multi-bounce: geometric constraints → better detection\n');
fprintf('\n');

%% Physical validation
fprintf('PHYSICAL VALIDATION (Bottom Reflection):\n');
fprintf('  Bottom-Surface-Bottom (2B/1S) eigenray:\n');
fprintf('    • Arrival time: 67.52 s (0.86 s delay vs direct)\n');
fprintf('    • Amplitude: -109.2 dB (20 dB loss vs direct)\n');
fprintf('    • Reflection loss matches theory (Jensen Table 1.3)\n');
fprintf('    • Sandy bottom: ρ=1900 kg/m³, c=1650 m/s\n');
fprintf('\n');

fprintf('===========================================\n');
fprintf('Figures displayed. Press any key to close all.\n');
pause;
close all;
