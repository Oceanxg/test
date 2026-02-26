# Async FIFO Local Smoke Simulation Project (VCS + Verdi)

This project is a lightweight local sanity-check flow you can run before handing RTL to verification:
- Compile and simulate with **VCS**
- Open FSDB waveforms with **Verdi**
- Use one **Makefile** for compile, run, waveform viewing, and cleanup

## Directory Layout

```text
.
├── Makefile
├── rtl/
│   └── async_fifo.sv
├── tb/
│   └── tb_async_fifo_smoke.sv
└── sim/
    └── filelist.f
```

## Dependencies

Make sure your environment provides:
- `vcs`
- `verdi`
- FSDB dump PLI support (typically provided by the Verdi setup)

## One-Command Smoke Run

```bash
make smoke
```

Execution flow:
1. `make compile`: invoke VCS and generate `sim/out/simv`
2. `make run`: run simulation and produce `sim/out/run.log` and `sim/out/wave.fsdb`

What this smoke test checks:
- Asynchronous write clock (`wr_clk=100MHz`) and read clock (`rd_clk≈71MHz`)
- Continuous writes for `TEST_NUM=DEPTH*4` transactions
- Scoreboard-style comparison on the read side (`expected` vs `dout`)
- Immediate `$fatal` on mismatch

## Common Commands

```bash
make help      # show help
make compile   # compile only
make run       # run only (requires compile first)
make verdi     # open Verdi and load FSDB
make clean     # remove simulation artifacts
```

## Optional Arguments

```bash
make smoke SEED=123
```

## Suggested Handoff Notes for Verification

You can pass the following information to verification engineers:
- DUT: `rtl/async_fifo.sv`
- TB: `tb/tb_async_fifo_smoke.sv`
- filelist: `sim/filelist.f`
- smoke command: `make smoke`
- waveform viewer: `make verdi`

---

If you later expand this into a regression flow (multiple tests, configs, and coverage), you can extend the existing Makefile with:
- `TEST=<case_name>`
- `COV=1` switch (VCS coverage)
- Regression scripts (batch run + PASS/FAIL summary)
