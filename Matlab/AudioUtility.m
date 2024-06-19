    
   
    disp('Leggenda delle scelte:');
    disp('1: Taglia audio');
    disp('2: Unisci dei suoni in una cartella in un unico file audio');
    disp('3: Unisci due file audio sequenzialmente ');
    disp('4: sovrapponi degli audio ');
    disp('5:dividi il file audio in 10 pezzi, mischiali e crea un nuovo file audio');
    disp('6 rendi soffusi i primi secondi');
    inputValue=input('Fai la tua scelta: ');
    % Implementazione dello switch-case
    switch inputValue
        case 1
            disp('Hai scelto di tagliare un audio');
            
% Chiedi all'utente di selezionare il file audio di input tramite una finestra di dialogo
[input_file, input_path] = uigetfile({'*.wav;*.mp3;*.ogg;*.flac','File audio supportati (*.wav, *.mp3, *.ogg, *.flac)'}, 'Seleziona il file audio di input');

% Verifica se l'utente ha selezionato un file
if isequal(input_file, 0)
    disp('Nessun file selezionato. Uscita dal programma.');
    return;
end

% Costruisci il percorso completo del file audio di input
input_file = fullfile(input_path, input_file);

% Chiedi all'utente il file audio di output
output_file = input('Inserisci il nome del file audio di output (formato: nome_file.wav): ', 's');

% Chiedi all'utente il tempo di inizio del taglio
start_time = input('Inserisci il tempo di inizio del taglio in secondi: ');

% Chiedi all'utente il tempo di fine del taglio
end_time = input('Inserisci il tempo di fine del taglio in secondi: ');

% Leggi il file audio
[audio, fs] = audioread(input_file);

% Converti il tempo in campioni
start_sample = round(start_time * fs);
end_sample = round(end_time * fs);

% Esegui il taglio
audio_tagliato = audio(start_sample:end_sample, :);

% Scrivi il file audio tagliato
audiowrite(output_file, audio_tagliato, fs);

disp('Audio tagliato con successo.');

        case 2
            disp('Hai scelto di unire dei suoni in una cartella');
           % Chiedi all'utente di selezionare la cartella con i file audio
audioFolder = uigetdir('', 'Seleziona la cartella contenente i file audio');
if audioFolder == 0
    error('Nessuna cartella selezionata. Il programma terminerà.');
end

% Definisci il file di output
outputFile = fullfile(audioFolder, 'combined_audio.wav');

% Leggi i nomi dei file audio nella cartella
audioFiles = dir(fullfile(audioFolder, '*.*'));
audioFiles = audioFiles(~[audioFiles.isdir]);

% Filtra i file audio supportati (wav, mp3, etc.)
supportedFormats = {'.wav', '.mp3', '.flac', '.ogg', '.m4a'};
audioFiles = audioFiles(contains({audioFiles.name}, supportedFormats));

% Controlla se ci sono file audio nella cartella
if isempty(audioFiles)
    error('Nessun file audio supportato trovato nella cartella selezionata.');
end

% Frequenza di campionamento (assunta 44.1 kHz)
Fs = 44100;

% Durata finale in secondi
totalDuration = 6 * 60;

% Inizializza l'audio combinato
combinedAudio = [];

% Tempo corrente in secondi
currentTime = 0;

% Riproduci i file audio casualmente fino a raggiungere la durata finale
while currentTime < totalDuration
    % Seleziona casualmente un file audio
    fileIndex = randi(length(audioFiles));
    audioFile = fullfile(audioFolder, audioFiles(fileIndex).name);
    
    % Leggi il file audio selezionato
    [y, fs] = audioread(audioFile);
    
    % Se necessario, cambia la frequenza di campionamento per uniformare a Fs
    if fs ~= Fs
        y = resample(y, Fs, fs);
    end
    
    % Assicura che y sia un vettore colonna
    y = y(:);
    
    % Concatena verticalmente l'audio selezionato al file combinato
    combinedAudio = [combinedAudio; y];
    
    % Aggiorna il tempo corrente
    currentTime = currentTime + length(y) / Fs;
end

% Taglia l'audio combinato alla durata finale desiderata
combinedAudio = combinedAudio(1:min(length(combinedAudio), totalDuration * Fs));

% Normalizza l'audio combinato per evitare il clipping
combinedAudio = combinedAudio / max(abs(combinedAudio(:)));

% Salva il file audio combinato
audiowrite(outputFile, combinedAudio, Fs);

disp(['File audio combinato creato con successo! Salvato come: ', outputFile]);


        case 3
            disp('Hai scelto di unire due file sequenzialmente');
            % Apri una finestra di dialogo per selezionare il primo file audio
[filename1, path1] = uigetfile({'*.wav;*.ogg;*.flac;*.mp3','File audio supportati (*.wav, *.ogg, *.flac, *.mp3)'},'Seleziona il primo file audio');
if filename1 == 0
    error('Nessun file selezionato.');
end

% Apri una finestra di dialogo per selezionare il secondo file audio
[filename2, path2] = uigetfile({'*.wav;*.ogg;*.flac;*.mp3','File audio supportati (*.wav, *.ogg, *.flac, *.mp3)'},'Seleziona il secondo file audio');
if filename2 == 0
    error('Nessun file selezionato.');
end

% Leggi i due file audio
[audio1, fs1] = audioread(fullfile(path1, filename1));
[audio2, fs2] = audioread(fullfile(path2, filename2));

% Standardizza le frequenze di campionamento
fs = max(fs1, fs2);
audio1_resampled = resample(audio1, fs, fs1);
audio2_resampled = resample(audio2, fs, fs2);

% Converti entrambi i file audio in stereo
if size(audio1_resampled, 2) == 1
    audio1_resampled = [audio1_resampled, audio1_resampled]; % Converti in stereo
end
if size(audio2_resampled, 2) == 1
    audio2_resampled = [audio2_resampled, audio2_resampled]; % Converti in stereo
end

% Unisci i due file audio
audio_completo = [audio1_resampled; audio2_resampled];

% Salva il file audio risultante
[output_filename, output_path] = uiputfile({'*.wav','File audio WAV (*.wav)'},'Salva file audio completo come');
if output_filename == 0
    error('Nessun percorso di output selezionato.');
end

output_full_path = fullfile(output_path, output_filename);
audiowrite(output_full_path, audio_completo, fs);

disp(['File audio completo salvato con successo come ', output_full_path]);

        case 4
            disp('Hai scelto di sovrappore degli audio ')
            % Permette all'utente di selezionare una cartella contenente i file audio
folderPath = uigetdir('', 'Seleziona la cartella contenente i file audio');
if folderPath == 0
    disp('Nessuna cartella selezionata. Terminazione dello script.');
    return;
end

% Legge tutti i file audio presenti nella cartella selezionata
audioFiles = dir(fullfile(folderPath, '*.wav'));

if isempty(audioFiles)
    disp('Nessun file audio (.wav) trovato nella cartella selezionata.');
    return;
end

% Estrae i nomi dei file audio
fileNames = {audioFiles.name};

% Legge e sovrappone i file audio
numFiles = numel(audioFiles);
audioData = cell(1, numFiles);
sampleRates = zeros(1, numFiles);

for i = 1:numFiles
    filePath = fullfile(folderPath, fileNames{i});
    [audioData{i}, sampleRates(i)] = audioread(filePath);
end

% Trova la lunghezza massima tra i file audio
maxLength = max(cellfun(@length, audioData));

% Normalizza le lunghezze dei file audio
for i = 1:numFiles
    if length(audioData{i}) < maxLength
        audioData{i} = [audioData{i}; zeros(maxLength - length(audioData{i}), 1)];
    end
end

% Sovrappone i file audio
outputData = sum(cat(3, audioData{:}), 3) / numFiles;

% Salva il file audio di output
outputFile = fullfile(folderPath, 'output.wav');
audiowrite(outputFile, outputData, max(sampleRates));

disp('Sovrapposizione completata. Il file audio di output è stato salvato in:');
disp(outputFile);


    case 5

            disp('Hai scelto di mescolare il segnale');
           % Chiedi all'utente di selezionare l'audio
[filename, filepath] = uigetfile({'*.wav', 'File audio WAV (*.wav)'}, 'Seleziona l''audio da mescolare');

% Controlla se l'utente ha annullato la selezione
if isequal(filename, 0) || isequal(filepath, 0)
    disp('Selezione annullata.');
    return;
end

% Carica l'audio selezionato
[audio, Fs] = audioread(fullfile(filepath, filename));

% Dividi l'audio in 10 segmenti
num_segments = 10;
segment_length = floor(length(audio) / num_segments);

segments = cell(1, num_segments);
for i = 1:num_segments
    start_index = (i - 1) * segment_length + 1;
    end_index = min(i * segment_length, length(audio));
    segments{i} = audio(start_index:end_index);
end

% Mescola i segmenti
shuffled_segments = segments(randperm(num_segments));

% Crea l'audio mescolato
mixed_audio = cat(1, shuffled_segments{:});

% Salva l'audio mescolato
[~, name, ~] = fileparts(filename);
output_filename = fullfile(filepath, [name '_mescolato.wav']);
audiowrite(output_filename, mixed_audio, Fs);

disp(['Audio mescolato salvato come ' output_filename]);
case 6
    disp('hai scelto di rendere soffuso i primi seocndi di un audio')
% Selezione del file audio
[file, path] = uigetfile({'*.wav;*.mp3', 'Audio Files (*.wav, *.mp3)'}, 'Seleziona un file audio');
if isequal(file, 0)
    disp('Nessun file selezionato');
    return;
else
    audioFile = fullfile(path, file);
end

% Leggi il file audio
[audioData, fs] = audioread(audioFile);

% Chiedi all'utente quanti secondi rendere soffusi
prompt = 'Quanti secondi rendere soffusi? ';
fadeSeconds = input(prompt);

% Numero di campioni da rendere soffusi
numFadeSamples = round(fadeSeconds * fs);

% Genera il vettore di dissolvenza
fadeIn = linspace(0, 1, numFadeSamples)';

% Applica la dissolvenza all'audio
if size(audioData, 2) == 1  % Mono
    audioData(1:numFadeSamples) = audioData(1:numFadeSamples) .* fadeIn;
else  % Stereo o più canali
    for ch = 1:size(audioData, 2)
        audioData(1:numFadeSamples, ch) = audioData(1:numFadeSamples, ch) .* fadeIn;
    end
end

% Salva il nuovo file audio
[filepath, name, ext] = fileparts(audioFile);
outputFile = fullfile(filepath, [name '_fadein' ext]);
audiowrite(outputFile, audioData, fs);

disp(['File audio con dissolvenza salvato come: ' outputFile]);



        otherwise
            disp('Input non valido.');
    end

