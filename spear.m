function spear(inputPath, outputDir, params)
% SPEAR   Spectral Peak Elimination and Amplitude Regulation
%   SPEAR(inputPath, outputDir, params) processes a noisy audio file
%   (typically fMRI scanner recordings) by removing prominent spectral
%   peaks (e.g., gradient coil noise) and applying dynamic range control
%   to improve vocal intelligibility while preserving the original performance.
%
%   Author:     Evan Szypulski
%   University: Georgia State University
%   Date:       April 9 2026
%   Version:    1.0
%   Project:    GSURC 2026 (Automated Removal of Acoustic Noise from fMRI-Acquired Jazz Scat Singing)
%
%   Input Arguments
%     inputPath   - Full path to the input audio file (mono or stereo .wav, .mp3, etc.)
%     outputDir   - Directory where the processed audio and QC report will be saved
%     params      - Structure containing processing parameters:
%                     .compThresh, .compRat, .compAttack, .compRelease
%                     .limThresh, .limAttack, .limRelease
%                     .crest          (target crest factor for RMS-based gain staging)
%                     .targetPeak     (final peak normalization level, e.g. 0.99)
%                     .threshFreq     (minimum frequency to consider for peak removal, Hz)
%                     .Q              (quality factor for notch filters)
%                     .nfft, .noverlap, .minDist, .minProm   (PSD peak detection)
%                     .dispRange      (seconds of waveform shown in QC report)
%
%   Output Arguments
%     Saves the processed file as <originalName>_SPEARed.mp3 in outputDir.
%     Generates and saves a QC report figure (<originalName>_QC_Report.png)
%     showing input vs. output PSD and waveform, with notched peaks marked.
%
%   Processing Chain:
%     1. Gain staging using RMS and target crest factor
%     2. Detection and removal of spectral peaks above threshFreq using IIR notch filters
%     3. Dynamic range compression
%     4. Brickwall limiting
%     5. Final peak normalization

% Check toolboxes
if isempty(ver('audio')) || isempty(ver('signal'))
    error('SPEAR requires the Audio Toolbox and the Signal Processing Toolbox.');
end

% Default parameters if not fully provided
defaultParams = struct(...
    'compThresh', -15, 'compRat', 4, 'compAttack', 0.005, 'compRelease', 0.1, ...
    'limThresh', -8, 'limAttack', 0.0001, 'limRelease', 0.05, ...
    'crest', 8, 'targetPeak', 0.98, 'threshFreq', 1000, ...
    'Q', 25, 'nfft', 2048, 'noverlap', 1024, 'minDist', 100, 'minProm', 8.5, ...
    'dispRange', 10);

% Merge user params with defaults
if nargin < 3, params = struct(); end
flds = fieldnames(defaultParams);
for i = 1:length(flds)
    if ~isfield(params, flds{i})
        params.(flds{i}) = defaultParams.(flds{i});
    end
end

% Initialization
[data, fs] = audioread(inputPath);
if size(data, 2) == 2
    % Convert to mono
    audio = mean(data, 2);
elseif size(data, 2) == 1
    % Already mono
    audio = data;
else
    error('Unsupported audio format: expected 1 or 2 channels.');
end
[~, name, ~] = fileparts(inputPath);

% Ensure output exists
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Compressor config
drc = compressor('Threshold', params.compThresh, 'Ratio', params.compRat, 'AttackTime', ...
    params.compAttack, 'ReleaseTime', params.compRelease, 'SampleRate', fs);

% Limiter config
drl = limiter(params.limThresh, 'AttackTime', params.limAttack, 'ReleaseTime', ...
    params.limRelease, 'SampleRate', fs);

% Gain stage
rmsScaledAudio = audio / (rms(audio) * params.crest);

% Detect spectral peaks
[f, psd_db, pks, locs] = getpsdpeaks( ...
    rmsScaledAudio, fs, params.nfft, params.noverlap, params.minDist, params.minProm);
mask = locs > params.threshFreq;
filteredLocs = locs(mask);
filteredPks  = pks(mask);

% Notch peaks
filtAudio = rmsScaledAudio;
for freq = filteredLocs'
    wo = freq / (fs/2);
    bw = wo / params.Q;
    [b, a] = iirnotch(wo, bw);
    filtAudio = filtfilt(b, a, filtAudio);
end

% Compress audio
compAudio = drc(filtAudio);

% Limit audio
limAudio = drl(compAudio);

% Normalize peaks
outAudio = limAudio;
peakCurrent = max(abs(limAudio));
if peakCurrent > 0
    outAudio = limAudio * (params.targetPeak / peakCurrent);
end

% Visualization
[fC, psd_dbC, ~, ~] = getpsdpeaks( ...
    outAudio, fs, params.nfft, params.noverlap, params.minDist, params.minProm);

figure('Visible', 'off', 'Color', 'w', 'Name', "QC Report: " + name, 'Units', ...
    'normalized');
tiledlayout(2, 1, 'TileSpacing', 'Compact');

% Display frequency domain
nexttile;
semilogx(f, psd_db, 'Color', [0 0 1 0.5], 'DisplayName', 'Input x[n]');
hold on;
semilogx(fC, psd_dbC, 'Color', [1 0 0 0.5], 'DisplayName', 'Output y[n]');
semilogx(filteredLocs, filteredPks, 'rv', 'MarkerSize', 6, 'DisplayName', 'Notched Peaks');
grid on; set(gca, 'XMinorGrid', 'on', 'YMinorGrid', 'on');
title('Power Spectral Density');
xlabel('Frequency (Hz)'); ylabel('PSD (dB/Hz)'); legend;
xlim([params.threshFreq, fs/2]);

% Display time domain
nexttile;
maxIdx = min(length(outAudio), params.dispRange * fs);
timeVec = (0:maxIdx-1)/fs; % Real time in seconds for the x-axis
plot(timeVec, audio(1:maxIdx), 'Color', 'b', 'DisplayName', 'Input x[n]');
hold on;
plot(timeVec, outAudio(1:maxIdx), 'Color', 'r', 'DisplayName', 'Output y[n]');
grid on;
title('Waveform');
xlabel('Time (seconds)'); ylabel('Amplitude (Normalized)'); legend;

% Final stats
fprintf('Analysis Complete.\nRemoved %d harmonics.\nFinal RMS: %.4f\n', length(filteredLocs), rms(outAudio));

% Save audio
fullAudioPath = fullfile(outputDir, name + "_SPEARed.mp3");
audiowrite(fullAudioPath, outAudio, fs);
fprintf('File saved to: %s\n', fullAudioPath);

% Save figure
fig = gcf;
fullFigPath = fullfile(outputDir, name + "_QC_Report.png");
exportgraphics(fig, fullFigPath, 'Resolution', 300);
close(fig);
fprintf('QC Report saved to: %s\n', fullFigPath);
end

function [f, psd_db, pks, locs] = getpsdpeaks(signal, fs, nfft, overlap, minDist, minProm)
[ppx, f] = pwelch(signal, nfft, overlap, nfft, fs);
psd_db = 10*log10(ppx);
[pks, locs] = findpeaks(psd_db, f, 'MinPeakDistance', minDist, 'MinPeakProminence', minProm);
end
