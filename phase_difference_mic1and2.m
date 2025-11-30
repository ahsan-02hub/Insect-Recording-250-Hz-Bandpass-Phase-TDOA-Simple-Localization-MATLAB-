%% Load CSV/TXT data
data = readmatrix('insect_recording.txt');   % or .csv

% Remove any rows that contain NaN or Inf (header, footer, bad lines)
data = data(all(isfinite(data), 2), :);

time_us = data(:,1);
x1_raw  = data(:,2);
x2_raw  = data(:,3);

% Convert time to seconds
t = time_us * 1e-6;

% Estimate sampling frequency
dt = mean(diff(t));
fs = 1/dt;
fprintf('Estimated sampling frequency: %.2f Hz\n', fs);

%% Remove DC offset
x1 = x1_raw - mean(x1_raw);
x2 = x2_raw - mean(x2_raw);

%% Band-pass filter around 250 Hz
f_center = 250;
bw = 40;
f1 = f_center - bw/2;
f2 = f_center + bw/2;

x1_filt = bandpass(x1, [f1 f2], fs);
x2_filt = bandpass(x2, [f1 f2], fs);


%% Save filtered data to CSV
% Columns: time_s, mic1_filt, mic2_filt
filteredData = [t, x1_filt, x2_filt];
writematrix(filteredData, 'filtered_250Hz.csv');
disp('Filtered data saved to filtered_250Hz.csv');

%% Quick plots (optional)
figure;
subplot(2,1,1);
plot(t, x1_raw); grid on;
title('Mic 1 - Raw'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot(t, x1_filt); grid on;
title('Mic 1 - Filtered around 250 Hz'); xlabel('Time (s)'); ylabel('Amplitude');

figure;
subplot(2,1,1);
plot(t, x2_raw); grid on;
title('Mic 2 - Raw'); xlabel('Time (s)'); ylabel('Amplitude');

subplot(2,1,2);
plot(t, x2_filt); grid on;
title('Mic 2 - Filtered around 250 Hz'); xlabel('Time (s)'); ylabel('Amplitude');

%% Phase difference at ~250 Hz using FFT

N = length(x1_filt);
X1 = fft(x1_filt);
X2 = fft(x2_filt);

% Frequency vector
f = (0:N-1)*(fs/N);

% Find index closest to 250 Hz
[~, idx250] = min(abs(f - f_center));

phase1 = angle(X1(idx250));
phase2 = angle(X2(idx250));
phaseDiff = angle(exp(1j*(phase2 - phase1)));  % wrapped to [-pi, pi]

fprintf('Phase at %.1f Hz: mic1 = %.3f rad, mic2 = %.3f rad, diff = %.3f rad\n', ...
    f(idx250), phase1, phase2, phaseDiff);

%% TDOA using cross-correlation (time-domain)
[c, lags] = xcorr(x2_filt, x1_filt);  % x2 relative to x1
[~, I] = max(c);
lag_samples = lags(I);
tau = lag_samples / fs;  % TDOA (seconds)

fprintf('TDOA tau = %.6e s (mic2 relative to mic1)\n', tau);

% Phase-based TDOA check (for 250 Hz)
tau_phase = phaseDiff / (2*pi*f_center);  % approximate
fprintf('Phase-based TDOA at %.1f Hz: %.6e s\n', f_center, tau_phase);

%% Simple 1D localization example (along line between mics)
% two mics separated by distance d, sound speed 343 m/s.
d = 0.20;      % mic spacing in meters (example: 20 cm)
c_sound = 343; % speed of sound m/s (approx at room temp)

delta_d = c_sound * tau; % distance difference from source to each mic

fprintf('Distance difference (mic2 - mic1) = %.4f m\n', delta_d);

% If source lies somewhere along the perpendicular bisector line,
% for 1D angle estimation:
% sin(theta) = delta_d / d, where theta is angle from array broadside.
val = delta_d / d;
if abs(val) <= 1
    theta = asind(val);
    fprintf('Estimated angle of arrival (AoA) ≈ %.2f degrees from broadside\n', theta);
else
    fprintf('Warning: |delta_d/d| > 1, geometry inconsistent (check data or assumptions).\n');
end

%% Phase difference vs time (optional visualization)
% Use a sliding window FFT if you want a phase-difference over time plot.
% Simple example (coarse):%% Phase difference vs time (sliding window)

windowSize = round(0.1 * fs);  % 0.1 s window
step       = round(0.05 * fs); % 50% overlap
N          = length(x1_filt);

idxStart = 1:step:(N - windowSize + 1);

phaseDiffTime = zeros(size(idxStart));
timeCenter    = zeros(size(idxStart));

for k = 1:length(idxStart)
    idxRange = idxStart(k):(idxStart(k) + windowSize - 1);

    seg1 = x1_filt(idxRange);
    seg2 = x2_filt(idxRange);

    % Make sure they are column vectors
    seg1 = seg1(:);
    seg2 = seg2(:);

    L = length(seg1);

    % Frequency vector for THIS segment
    f_seg = (0:L-1) * (fs / L);

    % Find index closest to 250 Hz for THIS segment
    [~, idx250_seg] = min(abs(f_seg - f_center));

    % FFT of the segment
    X1_seg = fft(seg1);
    X2_seg = fft(seg2);

    % Phases at ~250 Hz
    ph1 = angle(X1_seg(idx250_seg));
    ph2 = angle(X2_seg(idx250_seg));

    % Wrapped phase difference in [-pi, pi]
    phaseDiffTime(k) = angle(exp(1j*(ph2 - ph1)));

    % Time at center of this window
    timeCenter(k) = mean(t(idxRange));
end

figure;
plot(timeCenter, phaseDiffTime);
xlabel('Time (s)');
ylabel('Phase difference (rad)');
title('Phase difference between Mic 2 and Mic 1 at ~250 Hz');
grid on;
