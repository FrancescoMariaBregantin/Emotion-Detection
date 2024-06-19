% Permetti all'utente di selezionare il file .mat da caricare
[fileName, filePath] = uigetfile('*.mat', 'Seleziona il file .mat da caricare');

% Controlla se l'utente ha cliccato "Annulla"
if isequal(fileName, 0) || isequal(filePath, 0)
    disp('Nessun file selezionato. Fine del programma.');
    return;
end

% Variabile per i dati
data = [];

% Costruisci il percorso completo del file
fullFilePath = fullfile(filePath, fileName);

% Carica i dati dal file .mat
fileData = load(fullFilePath);

% Supponiamo che i dati siano contenuti in una variabile di nome 'data'
if isfield(fileData, 'data')
    data = fileData.data;
else
    error('Il file %s non contiene la variabile "data".', fileName);
end

% Controlla il numero di colonne nei dati
numCols = size(data, 2);

% Estrarre le colonne, considerando che ci possono essere solo due o tre colonne
y1 = data(:, 1);
y2 = data(:, 2);
y3 = [];
if numCols == 3
    y3 = data(:, 3);
end

% Plotta i dati originali senza nessun preprocessing
figure;
t = 1:size(data, 1);
plot(t, y1, 'k-');
xlabel('Tempo');
ylabel('Segnale GSR');
title([fileName ' - Segnale GSR Originale Senza Preprocessing']);
grid on; % Aggiunge la griglia al plot
hold on; % Mantieni il plot attuale

% Traccia una linea verticale quando y3 è uguale a 1 (se esiste la terza colonna)
if numCols == 3
    plot(t(y3 == 1), y1(y3 == 1), 'r|', 'MarkerSize', 20); 
end

% Sostituisci i valori molto più grandi della soglia con il valore precedente
threshold = 20000;
for i = 2:length(y1) % Inizia da 2 per poter accedere al valore precedente
    if y1(i) > threshold
        y1(i) = y1(i - 1);
    end
end

% Parametri del filtro per GSR
fs = 100 % Frequenza di campionamento (cambia con il valore appropriato)
fc_gsr = 1 % Frequenza di taglio (cambia con il valore appropriato)
[b_gsr, a_gsr] = butter(4, fc_gsr / (fs / 2)); % Filtro Butterworth di ordine 4

% Applica il filtro alla prima colonna (GSR)
y1_filtered = filtfilt(b_gsr, a_gsr, y1);

% Plotta il segnale GSR filtrato
figure;
plot(t, y1_filtered, 'r-');
xlabel('Tempo');
ylabel('Segnale GSR');
title([fileName ' - Segnale GSR Filtrato']);
grid on; % Aggiunge la griglia al plot
hold on; % Mantieni il plot attuale

% Traccia una linea verticale sull'asse delle ascisse quando y3 è uguale a 1 (se esiste la terza colonna)
if numCols == 3
    for i = 1:length(t)
        if y3(i) == 1
            line([t(i) t(i)], ylim, 'Color', 'g', 'LineStyle', '--'); % Linea verticale verde tratteggiata
        end
    end
end

% Chiedi all'utente se vuole salvare il segnale GSR filtrato in un file .mat
saveGSR = questdlg('Vuoi salvare il segnale GSR filtrato in un file .mat?', ...
    'Salva Segnale GSR', 'Sì', 'No', 'No');
if strcmp(saveGSR, 'Sì')
    [saveFileName, saveFilePath] = uiputfile('*.mat', 'Salva il segnale GSR filtrato come');
    if isequal(saveFileName, 0) || isequal(saveFilePath, 0)
        disp('Salvataggio annullato.');
    else
        saveFullPath = fullfile(saveFilePath, saveFileName);
        filteredGSR = y1_filtered; % Salva il segnale filtrato in una variabile
        save(saveFullPath, 'filteredGSR');
        disp(['Segnale GSR filtrato salvato in ', saveFullPath]);
    end
end

% Parametri del filtro per PPG
fc_low_ppg = 0.5; % Frequenza di taglio bassa (cambia con il valore appropriato)
fc_high_ppg = 5; % Frequenza di taglio alta (cambia con il valore appropriato)
[b_ppg, a_ppg] = butter(4, [fc_low_ppg, fc_high_ppg] / (fs / 2), 'bandpass'); % Filtro Butterworth di ordine 4

% Applica il filtro alla seconda colonna (PPG)
y2_filtered = filtfilt(b_ppg, a_ppg, y2);

% Plotta il segnale PPG filtrato
figure;
plot(t, y2_filtered, 'b-');
xlabel('Tempo');
ylabel('Segnale PPG');
title([fileName ' - Segnale PPG Filtrato']);
grid on; % Aggiunge la griglia al plot
hold on; % Mantieni il plot attuale

% Calcolo dei BPM e della Trasformata di Fourier per ogni intervallo
if numCols == 3
    intervalIndices = [1; find(y3 == 1); length(y3)+1]; % Include il primo e l'ultimo indice
    numIntervals = length(intervalIndices) - 1;
else
    % Se non c'è la terza colonna, chiedi all'utente se vuole ipotizzare gli intervalli
    answer = questdlg('Il file non contiene la terza colonna. Vuoi ipotizzare gli intervalli ogni 3262 campioni?', ...
        'Intervalli ipotizzati', 'Sì', 'No', 'No');
    if strcmp(answer, 'Sì')
        intervalLength = 3262;
        intervalIndices = 1:intervalLength:size(y2, 1);
        intervalIndices = [intervalIndices'; size(y2, 1) + 1]; % Include il primo e l'ultimo indice
        numIntervals = length(intervalIndices) - 1;
    else
        disp('Calcolo dei BPM annullato.');
        return;
    end
end

bpm = zeros(numIntervals, 1);
for i = 1:numIntervals
    startIdx = intervalIndices(i);
    endIdx = intervalIndices(i + 1) - 1;
    segment = y2_filtered(startIdx:endIdx);
    
    % Calcolo BPM usando la trasformata di Fourier
    L = length(segment);
    Y = fft(segment);
    P2 = abs(Y / L);
    P1 = P2(1:L/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);
    f = fs * (0:(L/2)) / L;
    [~, idx] = max(P1);
    freq = f(idx);
    bpm(i) = freq * 60;
    
    % Plot della Trasformata di Fourier
    figure;
    plot(f, P1);
    title(['Spettro di Frequenza - Intervallo ' num2str(i)]);
    xlabel('Frequenza (Hz)');
    ylabel('Amplitude');
    grid on;
end

% Stampa i BPM per ciascun intervallo
disp('BPM per intervallo:');
for i = 1:numIntervals
    disp(['Intervallo ' num2str(i) ': ' num2str(bpm(i)) ' BPM']);
end

% Traccia un grafico dei BPM per ciascun intervallo
figure;
bar(1:numIntervals, bpm);
xlabel('Intervallo');
ylabel('BPM');
title('BPM per Intervallo');
grid on;
