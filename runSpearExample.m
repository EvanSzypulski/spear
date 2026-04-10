%% Run SPEAR Example
%   Author:     Evan Szypulski
%   University: Georgia State University
%   Date:       April 9, 2026
%
%   This script demonstrates the Spectral Peak Elimination and Amplitude 
%   Regulation (SPEAR) tool using a sample recording from GSURC 2026.

clc; clear; close all;

% Setup paths
exampleFile = '01_A_01.mp3'; 
inputPath = fullfile('examples', exampleFile);
outputDir = 'processed_results';

% Check if file exists
if ~exist(inputPath, 'file')
    error('Example file not found. Please ensure %s is in the examples/ folder.', exampleFile);
end

% Define Parameters
% These are tuned for fMRI gradient noise (typically > 1000Hz)
params = struct();
params.threshFreq = 1000;    % Ignore low-frequency vocal content
params.minProm = 8;          % Sensitivity for detecting noise spikes
params.targetPeak = 0.98;    % Final normalization level
params.dispRange  = 5;       % Seconds of audio to display in the QC report

% Run SPEAR
try
    spear(inputPath, outputDir, params);
    fprintf('\nOpen the QC Report to see the spectral cleaning results.\n');
    
catch ME
    warning('SPEAR encountered an error: %s', ME.message);
end
