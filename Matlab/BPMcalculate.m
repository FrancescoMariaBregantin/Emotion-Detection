% Permetti all'utente di selezionare un singolo file .mat
[file, path] = uigetfile('*.mat', 'Seleziona un singolo file .mat');
if isequal(file, 0)
    disp('Nessun file selezionato. Fine del programma.');
    return;
end

% Costruisci il percorso completo del file selezionato
filePath = fullfile(path, file);

% Carica i dati dal file .mat
fileData = load(filePath);

% Estrai il segnale PPG dalla seconda colonna
if isfield(fileData, 'data') && size(fileData.data, 2) >= 2
    ppg_signal = fileData.data(:, 2);
else
    disp('Il file selezionato non contiene dati sufficienti per il segnale PPG.');
    return;
end

% Definisci la frequenza di campionamento (Hz)
fs = 100; % Frequenza di campionamento (Hz), modificare se necessario

% Filtra il segnale PPG (ad esempio con un filtro passa basso)
fc = 10; % Frequenza di taglio del filtro (Hz)
[b, a] = butter(2, fc/(fs/2), 'low');
filtered_ppg_signal = filtfilt(b, a, ppg_signal);

% Lunghezza di ciascun intervallo (in campioni)
intervalLength = floor(length(filtered_ppg_signal) / 3); % Divisione in tre intervalli

% Calcola i battiti per minuto (BPM) per ogni intervallo
bpm = zeros(3, 1); % Tre intervalli
for i = 1:3
    startIdx = (i - 1) * intervalLength + 1;
    endIdx = i * intervalLength;

    % Assicurati che endIdx non superi la lunghezza dell'array
    if endIdx > length(filtered_ppg_signal)
        endIdx = length(filtered_ppg_signal);
    end

    segment = filtered_ppg_signal(startIdx:endIdx);

    % Calcola i battiti per minuto (BPM)
    bpm(i) = calculate_bpm(segment, fs);
end

% Plotta i valori dei BPM per ogni intervallo
figure;
bar(bpm);
xlabel('Intervallo');
ylabel('BPM');
title('BPM per Intervallo');
grid on;

% Funzione per calcolare i BPM da un segmento di segnale PPG
function bpm = calculate_bpm(signal, fs)
    % Trova i picchi nel segnale
    [peaks, locs] = findpeaks(signal, 'MinPeakHeight', mean(signal), 'MinPeakDistance', fs * 0.5);
    
    % Calcola gli intervalli tra i picchi
    intervals = diff(locs) / fs; % In secondi
    
    % Calcola i battiti per minuto (BPM)
    bpm = 60 / mean(intervals);
end
