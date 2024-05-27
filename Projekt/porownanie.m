close all; clear; clc;
[signal_wieczor, Fs] = audioread("wieczorem.m4a");
[signal_rano, Fs] = audioread("rano.m4a");
sig_len_wieczor = length(signal_wieczor);
czas_wieczor = (0:sig_len_wieczor - 1) / Fs;

sig_len_rano = length(signal_rano);
czas_rano = (0:sig_len_rano - 1) / Fs;
subplot(211), plot(czas_wieczor, signal_wieczor), title("Wieczór");
subplot(212), plot(czas_rano, signal_rano), title("Rano");

%%
wej_rano = 30.5 * Fs;
wyj_rano = 59.5 * Fs;
t_rano = czas_rano(wej_rano : wyj_rano);
sig_rano = signal_rano(wej_rano : wyj_rano);

wej_wieczor = 30 * Fs;
wyj_wieczor = 59 * Fs;
t_wieczor = czas_wieczor(wej_wieczor : wyj_wieczor);
sig_wieczor = signal_wieczor(wej_wieczor : wyj_wieczor);

subplot(211), plot(t_rano, sig_rano), title("Analizowany fragment - rano")
subplot(212), plot(t_wieczor, sig_wieczor), title("Analizowany fragment - wieczor")

%% Pobranie sieci
downloadFile = matlab.internal.examples.downloadSupportFile("audio","wav2vec2/wav2vec2-base-960.zip");
wav2vecLocation = fullfile(tempdir,"wav2vec");
unzip(downloadFile,wav2vecLocation)
addpath(wav2vecLocation)

%% Analiza
%siec = speechClient('wav2vec2.0');
%result_rano = transcribe(siec, sig_rano, Fs);
%result_wieczor = transcribe(siec, sig_wieczor, Fs);
%words_rano = result_rano.Transcript;
%words_rano
%words_wieczor = result_wieczor.Transcript;
%words_wieczor
load("rano_ls.mat");
slowa_rano = ls.Labels.slowa{1,1};

%%
load("wieczorem_ls.mat");
slowa_wieczorem = ls.Labels.slowa{1,1};

if istable(slowa_rano)
    slowa_rano = table2cell(slowa_rano);
end
if istable(slowa_wieczorem)
    slowa_wieczorem = table2cell(slowa_wieczorem);
end


slowa_rano(:, 2) = cellfun(@char, slowa_rano(:, 2), 'UniformOutput', false);
slowa_wieczorem(:, 2) = cellfun(@char, slowa_wieczorem(:, 2), 'UniformOutput', false);

[~, idx_rano] = sort(cellfun(@(x) x(1), slowa_rano(:, 1)));
slowa_rano = slowa_rano(idx_rano, :);

[~, idx_wieczorem] = sort(cellfun(@(x) x(1), slowa_wieczorem(:, 1)));
slowa_wieczorem = slowa_wieczorem(idx_wieczorem, :);

czasy_rano = cellfun(@(x) x(2) - x(1), slowa_rano(:, 1));
czasy_wieczorem = cellfun(@(x) x(2) - x(1), slowa_wieczorem(:, 1));

slowa_rano_tab = [slowa_rano(:, 2), num2cell(czasy_rano)];
slowa_wieczorem_tab = [slowa_wieczorem(:, 2), num2cell(czasy_wieczorem)];

unikalne_slowa = unique([slowa_rano(:, 2); slowa_wieczorem(:, 2)]);

wyniki = cell(length(unikalne_slowa), 4);
wyniki(:, 1) = unikalne_slowa;

for i = 1:length(unikalne_slowa)
    slowo = unikalne_slowa{i};
    
    czasy_rano_slowo = cell2mat(slowa_rano_tab(strcmp(slowa_rano_tab(:, 1), slowo), 2));
    
    czasy_wieczorem_slowo = cell2mat(slowa_wieczorem_tab(strcmp(slowa_wieczorem_tab(:, 1), slowo), 2));
    
    sredni_czas_rano = mean(czasy_rano_slowo);
    sredni_czas_wieczorem = mean(czasy_wieczorem_slowo);
    
    roznica = sredni_czas_wieczorem - sredni_czas_rano;
    
    wyniki{i, 2} = sredni_czas_rano;
    wyniki{i, 3} = sredni_czas_wieczorem;
    wyniki{i, 4} = roznica;
end

wyniki_tab = cell2table(wyniki, 'VariableNames', {'Slowo', 'SredniCzasRano', 'SredniCzasWieczorem', 'Roznica'});

disp(wyniki_tab);

%%
disp('Podsumowanie wyników:');
for i = 1:height(wyniki_tab)
    slowo = wyniki_tab.Slowo{i};
    roznica = wyniki_tab.Roznica(i);
    
    if roznica > 0
        fprintf('Słowo "%s" jest wypowiadane wolniej wieczorem (różnica: %.2f s).\n', slowo, roznica);
    elseif roznica < 0
        fprintf('Słowo "%s" jest wypowiadane szybciej wieczorem (różnica: %.2f s).\n', slowo, abs(roznica));
    else
        fprintf('Słowo "%s" jest wypowiadane w tym samym tempie rano i wieczorem.\n', slowo);
    end
end

%%
przerwy_rano = cellfun(@(x,y) x(1) - y(2), slowa_rano(2:end, 1), slowa_rano(1:end-1, 1));
przerwy_wieczorem = cellfun(@(x,y) x(1) - y(2), slowa_wieczorem(2:end, 1), slowa_wieczorem(1:end-1, 1));

srednia_przerwa_rano = mean(przerwy_rano);
srednia_przerwa_wieczorem = mean(przerwy_wieczorem);
roznica_przerwa = srednia_przerwa_wieczorem - srednia_przerwa_rano;

fprintf('Średnia przerwa między słowami rano: %.2f s\n', srednia_przerwa_rano);
fprintf('Średnia przerwa między słowami wieczorem: %.2f s\n', srednia_przerwa_wieczorem);