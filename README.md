# Verification of FIFO — Constrained Random Testing + SVA

## Overview

Verified a synchronous FIFO design using a structured SystemVerilog testbench with constrained random stimulus, functional coverage, SystemVerilog Assertions (SVA), and an automatic queue-based scoreboard. Simulation performed using QuestaSim 10.7c.

## Specifications

* FIFO Depth: 8
* Data Width: 8-bit
* Design: Synchronous (single clock)
* Read Output: Registered

## Tools Used

* SystemVerilog / Verilog
* QuestaSim 10.7c
* QuestaSim Coverage Analysis
* Waveform Viewer

## Verification Features

| **Feature**                 | **Implementation**                                                     |
| --------------------------- | ---------------------------------------------------------------------- |
| Constrained Random Stimulus | Randomized read/write operations and 8-bit data                        |
| Functional Coverage         | Coverpoints for FIFO status and read/write signals with cross coverage |
| SVA Assertions              | Checks for write when full, read when empty, and invalid FIFO status   |
| Scoreboard                  | Queue-based expected vs actual data comparison                         |
| Directed Testing            | FIFO fill, drain, and normal read/write verification                   |
| Corner Cases                | Write when Full, Read when Empty, Idle, and Simultaneous Read/Write    |

## Test Phases

| **Phase** | **Description**                      | **Result** |
| --------- | ------------------------------------ | ---------- |
| Phase 1   | Directed Tests — fill and drain FIFO | PASS       |
| Phase 2   | Full/Empty Boundary Testing          | PASS       |
| Phase 3   | Simultaneous Read/Write Testing      | PASS       |
| Phase 4   | 50 Constrained Random Transactions   | PASS       |
| Phase 5   | Functional Coverage Closure          | 100%       |

## Results

* Total PASS: **37**
* Total FAIL: **0**
* Functional Coverage: **100.00% (20/20 bins)**
* Scoreboard Failures: **0**
* SVA Assertion Failures: **0**

## Coverage

Functional coverage includes:

* `full` status
* `empty` status
* `wr_en`
* `rd_en`
* `write × full`
* `read × empty`
* `write × read`

All defined coverage bins were exercised successfully.

## Key Observations

* Constrained random stimulus exercised normal, boundary, idle, and simultaneous read/write scenarios.
* Queue-based scoreboard verified FIFO data ordering and read data correctness.
* SVA assertions verified protection against writes when full and reads when empty.
* Simultaneous read/write transactions were explicitly verified and included in cross coverage.
* **100% functional coverage** was achieved across all defined coverpoints and cross coverage bins.

## Waveform

[FIFO Random Waveform](https://github.com/sashwanthr/fifo-sv-constrained-random-verification/blob/main/waveform_random.png)

## File Structure

* `fifo_sync.sv` — Synchronous FIFO RTL design
* `fifo_tb.sv` — Constrained random SystemVerilog testbench
* `waveform_random.png` — Simulation waveform output

## Skills Demonstrated

**SystemVerilog | Constrained Random Verification | Functional Coverage | SVA Assertions | Scoreboard | Directed Testing | Corner Case Verification | Waveform Analysis**

