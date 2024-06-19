% Fai scegliere all'utente la cartella contenente i file
cartella = uigetdir;

% Verifica se l'utente ha selezionato una cartella
if cartella == 0
    disp('Nessuna cartella selezionata. Il programma terminerà.');
    return;
end

% Ottieni una lista di tutti i file .mat nella cartella
fileList = dir(fullfile(cartella, '*.mat'));

% Prealloca una cella per contenere i segnali
segnali = {};

% Leggi i segnali dai file .mat e memorizzali nella cella
for i = 1:length(fileList)
    filename = fullfile(cartella, fileList(i).name);
    dataStruct = load(filename);
    % Estrarre il primo campo della struttura, che presumibilmente contiene i dati
    fieldNames = fieldnames(dataStruct);
    segnale = dataStruct.(fieldNames{1});
    % Assicurati che il segnale sia un vettore colonna
    if size(segnale, 1) < size(segnale, 2)
        segnale = segnale';
    end
    segnali{end+1} = segnale;
end

% Determina la lunghezza massima dei segnali
maxLength = max(cellfun(@length, segnali));

% Prealloca una matrice per contenere tutti i segnali
dataMatrix = nan(maxLength, length(segnali));

% Copia i segnali nella matrice
for i = 1:length(segnali)
    dataMatrix(1:length(segnali{i}), i) = segnali{i};
end

% Crea un array di etichette per le colonne
columnLabels = cell(1, length(segnali));
for i = 1:length(segnali)
    columnLabels{i} = sprintf('Segnale_%d', i);
end

% Scrivi la matrice in un file Excel con spazi tra le colonne
xlswrite(fullfile(cartella, 'segnali.xlsx'), columnLabels, 'Sheet1', 'A1');
xlswrite(fullfile(cartella, 'segnali.xlsx'), dataMatrix, 'Sheet1', 'A2');

disp('File Excel creato con successo.');
