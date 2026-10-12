clc;
clear all;
close all;

in = randi([0,1],1,120000); % Multiple of 12 to prevent reshape errors
len = length(in);

out = zeros(5, len); 
Snr = randi([5,30],1,5);

for i=1:5
    if (Snr(i)<=7)
        % BPSK (Keep PSK since M=2)
        mod2(i,:)= pskmod(in, 2, 'InputType', 'bit');
        y1 = awgn(mod2(i,:), Snr(i), 'measured');
        out(i,:)=pskdemod(y1, 2, 'OutputType', 'bit');

    elseif (Snr(i) <= 13)
        % QPSK (Keep PSK since M=4)
        x1 = reshape(in, 2, []);
        x2 = char(x1' + '0');
        x3 = bin2dec(x2);
        mod4(i,:) = pskmod(x3, 4, 0, 'gray'); % Added Gray coding optimization
        y2 = awgn(mod4(i,:), Snr(i), 'measured');
        z = pskdemod(y2, 4, 0, 'gray');
        z1 = dec2bin(z, 2);
        z2 = z1 - '0';
        out(i,:) = reshape(z2', 1, []);

    elseif (Snr(i) <= 21)
        % --- FIX: Upgrade to 16-QAM ---
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
        % --- FIX: Upgrade to 64-QAM ---
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

% --- BER Calculation ---
num = zeros(1,5);
ratio = zeros(1,5);
for i = 1:5
    [num(i), ratio(i)] = biterr(in, out(i,:));
    if (ratio(i) == 0)
        ratio(i) = 1e-6; % Visual floor for log scale
    end
end

% --- Plotting ---
[sortedSnr, sortIdx] = sort(Snr);

figure;
semilogy(sortedSnr, ratio(sortIdx), 'o-', 'LineWidth', 1.5);
grid on;
xlabel('SNR in dB');
ylabel('BER');
title('SNR vs BER (With QAM for 16 and 64)');

% Throughput Curve Setup
th = zeros(1,30);
th(1:7) = 1; th(8:13) = 2; th(14:21) = 4; th(22:30) = 6;

figure;
plot(1:30, th, 'LineWidth', 1.5)
grid on;
title('SNR vs Throughput');
xlabel('SNR in dB');
ylabel('Throughput (bits/symbol)');
