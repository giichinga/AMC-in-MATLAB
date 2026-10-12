# Adaptive Modulation and Coding (AMC) Simulation in MATLAB

This repository contains a self-contained MATLAB script that simulates a closed-loop **Adaptive Modulation and Coding (AMC)** system over an Additive White Gaussian Noise (AWGN) channel. The system dynamically adjusts its modulation tier based on the instantaneous Signal-to-Noise Ratio (SNR) to optimize throughput while maintaining target link reliability.

---

## System Architecture

The simulation transitions through four distinct Modulation and Coding Schemes (MCS) depending on the channel quality:

*   **SNR <= 7 dB**: BPSK (1 bit/symbol) — Maximum robustness for poor channel conditions.
*   **7 dB < SNR <= 13 dB**: QPSK (2 bits/symbol with Gray Mapping) — Balanced robustness.
*   **13 dB < SNR <= 21 dB**: 16-QAM (4 bits/symbol) — Higher throughput for moderate channel conditions.
*   **21 dB < SNR <= 30 dB**: 64-QAM (6 bits/symbol) — Maximum data rate for clean channel conditions.

---

## Source Code

```matlab
clc;
clear all;
close all;

% --- Simulation Configuration ---
in = randi([0,1], 1, 120000); % 120,000 bits ensuring perfect divisibility by 2, 4, and 6
len = length(in);
out = zeros(5, len); 

% Generate 5 random channel quality indicators (SNR in dB)
Snr = randi([5,30], 1, 5);

% --- Core Simulation Loop ---
for i=1:5
    if (Snr(i) <= 7)
        % BPSK Tier
        mod2(i,:) = pskmod(in, 2, 'InputType', 'bit');
        y1 = awgn(mod2(i,:), Snr(i), 'measured');
        out(i,:) = pskdemod(y1, 2, 'OutputType', 'bit');

    elseif (Snr(i) <= 13)
        % QPSK Tier
        x1 = reshape(in, 2, []);
        x2 = char(x1' + '0');
        x3 = bin2dec(x2);
        mod4(i,:) = pskmod(x3, 4, 0, 'gray'); 
        y2 = awgn(mod4(i,:), Snr(i), 'measured');
        z = pskdemod(y2, 4, 0, 'gray');
        z1 = dec2bin(z, 2);
        z2 = z1 - '0';
        out(i,:) = reshape(z2', 1, []);

    elseif (Snr(i) <= 21)
        % 16-QAM Tier
        a1 = reshape(in, 4, []);
        a2 = char(a1' + '0');
        a3 = bin2dec(a2);
        mod16(i,:) = qammod(a3, 16, 'UnitAveragePower', true); 
        y3 = awgn(mod16(i,:), Snr(i), 'measured');
        l = qamdemod(y3, 16, 'UnitAveragePower', true);
        l1 = dec2bin(l, 4);
        l2 = l1 - '0';
        out(i,:) = reshape(l2', 1, []);

    elseif (Snr(i) >= 22 && Snr(i) <= 30)
        % 64-QAM Tier
        m1 = reshape(in, 6, []);
        m2 = char(m1' + '0');
        m3 = bin2dec(m2);
        mod64(i,:) = qammod(m3, 64, 'UnitAveragePower', true);
        y4 = awgn(mod64(i,:), Snr(i), 'measured');
        n = qamdemod(y4, 64, 'UnitAveragePower', true);
        n1 = dec2bin(n, 6);
        n2 = n1 - '0';
        out(i,:) = reshape(n2', 1, []);
    end
end

% --- BER Metrics Calculation ---
num = zeros(1,5);
ratio = zeros(1,5);
for i = 1:5
    [num(i), ratio(i)] = biterr(in, out(i,:));
    if (ratio(i) == 0)
        ratio(i) = 1e-6; % Logarithmic plot floor for zero-error runs
    end
end

% --- Data Sorting & Visualization ---
[sortedSnr, sortIdx] = sort(Snr);

% Figure 1: Bit Error Rate Curve
figure;
semilogy(sortedSnr, ratio(sortIdx), 'o-', 'LineWidth', 1.5);
grid on;
xlabel('SNR in dB');
ylabel('BER');
title('SNR vs BER (With QAM Corrections)');

% Figure 2: Theoretical Maximum Throughput Steps
th = zeros(1,30);
th(1:7) = 1; th(8:13) = 2; th(14:21) = 4; th(22:30) = 6;

figure;
plot(1:30, th, 'LineWidth', 1.5)
grid on;
title('SNR vs Throughput');
xlabel('SNR in dB');
ylabel('Throughput (bits/symbol)');
```

---

## Output Metrics & Key Visualizations

The script evaluates system behavior via two dependent performance profiles:

*   **SNR vs. BER Curve (Figure 1):** Illustrates the waterfall drop-off of bit error performance under optimized 2D grid spacing (QAM) layouts. Points are automatically sorted by channel quality for smooth representation.
*   **SNR vs. Throughput Curve (Figure 2):** Tracks the link capability metrics scaling from 1 bit/symbol up to 6 bits/symbol based on strict hardware switching thresholds.
