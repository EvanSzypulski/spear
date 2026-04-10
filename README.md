# SPEAR – Spectral Peak Elimination and Amplitude Regulation

[![MATLAB](https://img.shields.io/badge/MATLAB-R2023a+-orange.svg)](https://www.mathworks.com/products/matlab.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**SPEAR** is a MATLAB function designed to clean noisy audio recordings, particularly vocal performances captured inside an MRI scanner (e.g., gradient coil and cold head noise). It automatically detects and removes aggressive spectral peaks using notch filters, then applies compression, limiting, and normalization to improve intelligibility while preserving the musical performance.

Developed for **GSURC 2026**: *Automated Removal of Acoustic Noise from fMRI-Acquired Jazz Scat Singing.*

## Features
- Automatic spectral peak detection and surgical notch filtering
- RMS-based gain staging + dynamic range compression + brickwall limiting
- Generates a professional QC report (before/after PSD + waveform plot)
- Includes sensible default parameters for fMRI vocal audio
- Requires **Audio Toolbox** and **Signal Processing Toolbox**

## Requirements
- MATLAB R2021a or newer
- Audio Toolbox
- Signal Processing Toolbox

### Notes on Reproducibility:
This function uses MATLAB Audio Toolbox dynamic range processors (compressor, limiter) and peak detection (findpeaks), whose internal implementations may vary slightly across MATLAB versions. As a result, output may not be numerically identical across different releases.

Tested in: MATLAB R2025b

## Installation
1. Download or clone this repository.
2. Add the folder to your MATLAB path:
   ```matlab
   addpath('path/to/spear'); 

## Usage

### Basic usage with default parameters
```matlab
% Process one audio file
params = struct();                    % Use built-in defaults
spear('raw_audio/noisy_recording.mp3', 'processed_audio', params);
````
### Customizing parameters
```matlab
params = struct(...
    'compThresh', -18, ...
    'threshFreq', 800, ...
    'targetPeak', 0.99);

spear('input_file.wav', 'output_folder', params);

````
After running, SPEAR saves two files in the output folder:

- `<filename>_SPEARed.mp3` — cleaned audio
- `<filename>_QC_Report.png` — quality control report (before/after plots)

For full parameter details, type:
```matlab
help spear
````

## Usage
MIT License - see the LICENSE file for details.

## Author
Evan Szypulksi

Georgia State University
