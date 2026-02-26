SHELL := /bin/bash

TOP      ?= tb_async_fifo_smoke
SIM_DIR  ?= sim
OUT_DIR  ?= $(SIM_DIR)/out
FILELIST ?= $(SIM_DIR)/filelist.f
SEED     ?= 1

VCS      ?= vcs
VCS_FLAGS := -full64 -sverilog -timescale=1ns/1ps -debug_access+all \
             -kdb -lca -f $(FILELIST) -top $(TOP) \
             +lint=TFIPC-L +v2k +warn=noTFIPC +define+DUMP_FSDB +ntb_random_seed=$(SEED)
VERDI    ?= verdi
BSUB_RUN ?= bsub -q normal -Is

SIMV     := $(OUT_DIR)/simv
CMP_LOG  := $(OUT_DIR)/compile.log
RUN_LOG  := $(OUT_DIR)/run.log

.DEFAULT_GOAL := all

.PHONY: help all smoke compile run verdi clean

help:
	@echo "Usage:"
	@echo "  make smoke      # compile + run smoke test"
	@echo "  make compile    # compile only"
	@echo "  make run        # run compiled simv"
	@echo "  make verdi      # open Verdi with FSDB"
	@echo "  make clean      # clean simulation outputs"

all: smoke

smoke: compile run

compile:
	@mkdir -p $(OUT_DIR)
	$(BSUB_RUN) $(VCS) $(VCS_FLAGS) -o $(SIMV) -l $(CMP_LOG)

run:
	@if [ ! -x $(SIMV) ]; then echo "[ERR] $(SIMV) not found, run 'make compile' first"; exit 1; fi
	cd $(OUT_DIR) && ./simv -l run.log
	@echo "[INFO] run log: $(RUN_LOG)"
	@echo "[INFO] fsdb   : $(OUT_DIR)/wave.fsdb"

verdi:
	@if [ ! -f $(OUT_DIR)/wave.fsdb ]; then echo "[ERR] FSDB not found, run 'make run' first"; exit 1; fi
	$(BSUB_RUN) $(VERDI) -sv -f $(FILELIST) -ssf $(OUT_DIR)/wave.fsdb &

clean:
	rm -rf $(OUT_DIR) csrc ucli.key novas* verdiLog *.log
