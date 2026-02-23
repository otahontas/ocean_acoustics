# Ocean acoustics model comparison

Two custom ray-tracing models are compared against Bellhop in a deep-water Munk profile scenario:

- `clinear_curvature.m` (c-linear cell method)
- `ray_parameter.m` (geometric ray tracing)
- `run_bellhop.m` (Bellhop reference)

## Requirements

- MATLAB
- `make`
- `gfortran` (macOS: `brew install gfortran`)

## Setup

Install Acoustics Toolbox (Bellhop dependency):

```bash
./install_acoustics_toolbox.sh
```

## Run

Run full comparison:

```matlab
compare
```

Run one model at a time:

```matlab
clinear_curvature
ray_parameter
run_bellhop
```

## Outputs

Generated when you run the scripts:

- `comparison_results.txt` (text summary)
- `figures/*.png` and `figures/*.pdf` (plots)

These outputs are ignored by git.

## Deliverables

- `deliverables/paper/ARP_Paper/` (paper source)
- `deliverables/paper/ARP_Paper - FINAL VERSION.pdf`
- `deliverables/slides/Modeling underwater Sound Propagation - FINAL PRESENTATION.pdf`


## Scenario parameters

`shared_params.m` and `scenario.env` must stay in sync.

Current defaults:

- Source depth: `1000 m`
- Receiver depth: `1000 m`
- Receiver range: `100000 m` (`100 km`)
- Ray fan: `10001` rays from `-30°` to `30°`
- Eigenray tolerance: `5 m`

If you change either file, clear Bellhop scenario files in `at/` before rerunning.

If you change SSP parameters in `shared_params.m`, regenerate the SSP block with:

```matlab
generate_munk_ssp
```

Then paste the generated SSP table into `scenario.env`.
