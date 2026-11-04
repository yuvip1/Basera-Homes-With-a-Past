# Basera Research Workspace

Independent academic workspace for the research track (R0–R6 in [docs/roadmap/BASERA-ROADMAP.md](../docs/roadmap/BASERA-ROADMAP.md)): image-based property condition verification for heritage homes.

This directory is **not** part of the pnpm/Turborepo graph. It has no JavaScript dependencies and must not be added to `pnpm-workspace.yaml` or `turbo.json`. Production code lives in `apps/`; experimental code lives here. The two are never mixed.

## Purpose

- Literature review and paper notes (R0)
- Dataset design, consent protocols, annotation (R1)
- Classical alignment/change-detection baselines (R2)
- Learned model experiments (R3)
- Calibration, abstention and evaluation (R4–R5)
- IEEE paper drafts and reproducibility artifacts (R6)

## Directory conventions

Subdirectories are created when work begins, not before. The intended layout:

```
research/
  literature-review/   papers/, references/, notes/
  datasets/            raw/, processed/, sample/   (see storage rules below)
  experiments/         notebooks/, scripts/, results/
  computer-vision/     methodology/, model-evaluation/, image-comparison/
  ieee-paper/          drafts/, figures/, tables/, references/
```

## Python environment

Isolated per project area; never install research dependencies into the root Node workspace.

```bash
cd research
python -m venv .venv
# Windows: .venv\Scripts\activate    Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt      # create requirements.txt when the first experiment needs one
```

Jupyter, PyTorch, OpenCV, Kornia and other research libraries are declared in `requirements.txt` files inside `research/`, pinned to exact versions for reproducibility.

## Dataset storage rules

- `datasets/raw/` and `datasets/processed/` are **gitignored** — never commit large raw captures or private property images.
- `datasets/sample/` may hold small, reproducible sample data under an appropriate license.
- Every dataset source gets a provenance record: licence, permission, and any use restriction. Synthesized edits and licensed-public sources stay clearly separate from any later heritage-interior capture.
- Private-capture data requires documented property-controller permission and consent, faces and personal documents excluded, before it enters this workspace.
- Train/val/test splits are frozen and hashed **before** any model training. Split by room or house, never by image. The held-out manifest never changes after freezing.

## Experiment conventions

- Naming: `YYYY-MM-DD_<short-description>` for experiment directories and result files.
- Every experiment records: date, config (seeded), result, and what it taught you — in `experiments/results/` and the roadmap's research log.
- Notebooks stay in `experiments/notebooks/`; promotable logic lives in `experiments/scripts/`.
- Model artifacts (`.pt`, `.pth`, `.onnx`, `.h5`) are gitignored; track them by hash in the experiment record instead.

## Promotion to production

Research output becomes production code in `apps/vision/` only through a deliberate, reviewed integration:

1. The model is selected and validated in `research/` with frozen, hashed splits and a written evaluation (R4–R5).
2. A phase handoff and ADR record the promotion decision.
3. The implementation is rebuilt in `apps/vision/` with production tests, service-to-service auth, and recommendation-only output — never an automated accusation.
4. Reviewer feedback collected in production never re-enters held-out evaluation data.

No code is auto-promoted. An experiment that works in a notebook is not a production service.