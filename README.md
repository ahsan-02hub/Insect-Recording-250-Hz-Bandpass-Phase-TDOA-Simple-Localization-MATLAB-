# Insect Recording: 250 Hz Bandpass + Phase / TDOA + Simple Localization (MATLAB)

This repository contains a MATLAB script that loads a 2-channel insect audio recording, filters both microphone signals around 250 Hz, and estimates phase difference, time difference of arrival (TDOA), and a simple angle of arrival (AoA) using a two-microphone array model.

---

## What this script does

1. **Loads data** from `insect_recording.txt` (or `.csv`) using `readmatrix`.
2. **Cleans rows** containing `NaN` or `Inf`.
3. Extracts:
   - Column 1: timestamp in **microseconds**
   - Column 2: microphone 1 signal
   - Column 3: microphone 2 signal
4. Converts time to **seconds** and estimates sampling frequency `fs`.
5. Removes DC offset from both channels.
6. Applies a **band-pass filter** around **250 Hz** (default bandwidth 40 Hz).
7. Saves the filtered output to `filtered_250Hz.csv`:
   - `time_s, mic1_filt, mic2_filt`
8. Produces optional plots:
   - raw vs filtered waveforms for each mic
   - sliding-window phase difference vs time
9. Estimates:
   - **Phase difference at ~250 Hz** using FFT
   - **TDOA** using cross-correlation
   - **Phase-based TDOA** check at 250 Hz
10. Uses a simple 2-mic geometry to estimate **AoA** (broadside model).

---

## Requirements

- MATLAB (recommended R2018b+)
- Signal Processing Toolbox (for `bandpass`, `xcorr`)

---

## Input data format

Your input file (e.g., `insect_recording.txt` or `insect_recording.csv`) must have **three numeric columns**:

| Column | Meaning |
|-------:|---------|
| 1 | time in **microseconds** |
| 2 | mic 1 raw amplitude |
| 3 | mic 2 raw amplitude |

If the file contains headers or bad rows, the script removes rows containing `NaN`/`Inf`.

Example (no header):
