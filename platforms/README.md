# Platform Adapters

Each host owns its wrapper and packaging inputs under `platforms/<host>/`.

Contract:

- inputs may read shared source from `src/`
- host-specific inputs must stay inside `platforms/<host>/`
- generated outputs must stay inside `build/<host>/`
- cross-host reads are not allowed

Every host directory should include a `manifest.sh` that lists the allowed inputs and outputs for validation.
