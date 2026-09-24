# proov

A teaching project showing, step by step, how a Claude Code project is built.
The brief is in `a1.qmd`.

The study question: in simulated stroke patients, how does time to reach hospital
affect survival, with age and sex as confounders?

## Layout

| Folder              | Contents                                                    |
|---------------------|-------------------------------------------------------------|
| `R/`                | Reusable functions (e.g. the data simulation), sourced by scripts |
| `scripts/`          | Numbered pipeline scripts, run in order (`01_…`, `02_…`)    |
| `data/raw/`         | Simulated data as generated; never edited by hand           |
| `data/processed/`   | Analysis-ready data derived from `data/raw/`                |
| `reports/`          | Quarto documents: analysis plan, results                    |
| `output/figures/`   | Saved plots                                                 |
| `output/tables/`    | Saved tables                                                |
