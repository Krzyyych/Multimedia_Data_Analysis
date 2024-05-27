%% Wczytanie sygnału i wybranie najlepszej metody
close all; clear; clc;
[signal, Fs] = audioread("wieczorem.m4a");
sig_len = length(signal);
%czas = (0:sig_len - 1) / Fs;

clear sound
signal = signal(:, 1);
faza_dzielnik = 100;
phi = 1 / faza_dzielnik: 1 / faza_dzielnik: 8 * Fs / faza_dzielnik;
phi = phi / (2 * pi);
signal = [signal; (sin(2*pi*Fs + phi) * 0.01)'];
czas = (0:sig_len + 10 * Fs - 1) / Fs;
N = length(signal);
features = audioFeatureExtractor('SampleRate', Fs, 'SpectralDescriptorInput', 'linearSpectrum', 'spectralCentroid', true, 'spectralSkewness', true, 'spectralKurtosis', true, ...
    'spectralSpread', true, 'harmonicRatio', true, 'spectralCrest', true, 'spectralFlux', true, 'pitch', true);
wyniki = extract(features, signal);
krok = length(features.Window) - features.OverlapLength;
t = (1 : krok  : N-length(features.Window)+1) / Fs;
subplot(811), plot(t, wyniki(:, 1)); title("Centroid");
subplot(812), plot(t, wyniki(:, 2)); title("Crest");
subplot(813), plot(t, wyniki(:, 3)); title("Flux");
subplot(814), plot(t, wyniki(:, 4)); title("Kurt");
subplot(815), plot(t, wyniki(:, 5)); title("Skewness"); 
subplot(816), plot(t, wyniki(:, 6)); title("Spread");
subplot(817), plot(t, wyniki(:, 7)); title("Pitch"); 
subplot(818), plot(t, wyniki(:, 8)); title("Harmonic");

%% Wykrywanie początków moich wypowiedzi

median = medfilt1(wyniki(:, 7), 319);
med_rev = max(median) - median(:);
plot(t, med_rev); title("Pitch po odwroconym medianowym");

%koniec = length(med_rev);

[peaks, idx] = findpeaks(med_rev, "MinPeakHeight", 270);
tt_1 = t(idx);
wej_1 = tt_1(1);
tt_2 = tt_1(tt_1 > wej_1 + 30);
wej_2 = tt_2(1);
tt_3 = tt_2(tt_2 > wej_2 + 30);
wej_3 = tt_3(1);

%% Wykrywanie końców moich wypowiedzi
%plot(t, median); title("Pitch po medianowym");
med_rev_inverted = flipud(med_rev);
plot(t, med_rev_inverted); title("Pitch po odwroconym medianowym - inverted");

[peaks, idx] = findpeaks(med_rev_inverted, "MinPeakHeight", 270);
tt_1 = t(idx);
wyj_1 = tt_1(1);
tt_2 = tt_1(tt_1 > wyj_1 + 30);
wyj_2 = tt_2(1);
tt_3 = tt_2(tt_2 > wyj_2 + 30);
wyj_3 = tt_3(1);

probka_3 = (t(end) - wyj_1) * Fs;
probka_2 = (t(end) - wyj_2) * Fs;
probka_1 = (t(end) - wyj_3) * Fs;

wyj_3 = t(end) - wyj_3;
wyj_2 = t(end) - wyj_2;
wyj_1 = t(end) - wyj_1;

temp = wyj_1;
wyj_1 = wyj_3;
wyj_3 = temp;

signal = signal(1:sig_len);
czas = czas(1:sig_len);
%% Przedzialy na wykresie
y = ylim; 
plot(czas, signal, 'b', ...
    [wej_1 wej_1], [-0.5 y(2)], 'g', [wyj_1 wyj_1], [-0.5 y(2)], 'r', ...
    [wej_2 wej_2], [-0.5 y(2)], 'g', [wyj_2 wyj_2], [-0.5 y(2)], 'r', ...
    [wej_3 wej_3], [-0.5 y(2)], 'g', [wyj_3 wyj_3], [-0.5 y(2)], 'r' )

legend("sygnał", "wejścia", "wyjścia")
title("Wykres z podziałem sygnału na fragmenty")

%% Zliczanie slow

%plot(t, wyniki(:, 3)); title("Flux");

krzych_czas_1 = czas(find(czas == wej_1) : probka_1);
krzych_czas_2 = czas(find(czas == wej_2) : probka_2);
krzych_czas_3 = czas(find(czas == wej_3) : probka_3);

krzych_sygnal_1 = signal(find(czas == wej_1) : probka_1);
krzych_sygnal_2 = signal(find(czas == wej_2) : probka_2);
krzych_sygnal_3 = signal(find(czas == wej_3) : probka_3);

subplot(311), plot(krzych_czas_1, krzych_sygnal_1);
subplot(312), plot(krzych_czas_2, krzych_sygnal_2);
subplot(313), plot(krzych_czas_3, krzych_sygnal_3);
%%
wypowiedz = {krzych_sygnal_1, krzych_sygnal_2, krzych_sygnal_3}; 
czasy = {krzych_czas_1, krzych_czas_2, krzych_czas_3};

wykryte = [];
blad = [];
faktyczne = [67, 72, 71];
best_dist = [];
best_height = [];
%%
for i = 1 : length(czasy) 
    N = length(wypowiedz{i});
    features = audioFeatureExtractor('SampleRate', Fs, 'SpectralDescriptorInput', 'linearSpectrum', 'spectralFlux', true);
    wyniki = extract(features, wypowiedz{i});
    krok = length(features.Window) - features.OverlapLength;
    t = (1 : krok  : N-length(features.Window)+1) / Fs;
    blad(i) = 100;
    for dist = 15:1:25
        for height = 0.00035:0.00001:0.00065
            [peaks, idx] = findpeaks(wyniki, "MinPeakDistance", dist, "MinPeakHeight", height);
            if blad(i) >= 100 * abs((faktyczne(i) - length(peaks))) / faktyczne(i)
                wykryte(i) = length(peaks);
                blad(i) = 100 * abs((faktyczne(i) - wykryte(i))) / faktyczne(i);
                best_dist(i) = dist;
                best_height(i) = height;
            end
        end
    end
    %[piki, idx] = findpeaks(wyniki, "MinPeakDistance", 22, "MinPeakHeight", 0.00042);
end

%%
for i = 1 : length(czasy)
    N = length(wypowiedz{i});
    features = audioFeatureExtractor('SampleRate', Fs, 'SpectralDescriptorInput', 'linearSpectrum', 'spectralFlux', true);
    wyniki = extract(features, wypowiedz{i});
    krok = length(features.Window) - features.OverlapLength;
    t = (1 : krok  : N-length(features.Window)+1) / Fs;
    [peaks, idx] = findpeaks(wyniki, "MinPeakDistance", round(mean(best_dist)), "MinPeakHeight", mean(best_height));
    wykryte(i) = length(peaks);
    blad(i) = 100 * abs((faktyczne(i) - wykryte(i))) / faktyczne(i);
end

blad_sredni = sum(blad .* faktyczne) / sum(faktyczne);
blad
blad_sredni
wykryte