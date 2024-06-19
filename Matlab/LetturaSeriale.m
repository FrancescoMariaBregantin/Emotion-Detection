% Ottieni le informazioni sulle porte seriali disponibili
serialInfo = instrhwinfo('serial');
availablePorts = serialInfo.AvailableSerialPorts;

% Controlla se ci sono porte seriali disponibili
if isempty(availablePorts)
    error('Nessuna porta seriale disponibile.');
end

% Chiedi all'utente di selezionare la porta seriale utilizzando una finestra di dialogo
[selectedPortIndex, ~] = listdlg('PromptString', 'Seleziona la porta seriale:', 'ListString', availablePorts);
if isempty(selectedPortIndex)
    error('Devi selezionare una porta seriale.');
end
selectedPort = availablePorts{selectedPortIndex};

% Chiedi all'utente di inserire il baud rate
prompt = {'Inserisci il baud rate:'};
dlgtitle = 'Baud Rate';
dims = [1 35];
definput = {'9600'};
baudRate = inputdlg(prompt, dlgtitle, dims, definput);

% Creazione della figura
fig = figure;

% Creazione dei pulsanti
startButton = uicontrol('Style', 'pushbutton', 'String', 'Avvia lettura', 'Callback', {@startReading, selectedPort, str2double(baudRate{1})}, 'Position', [20, 20, 100, 20]);
stopButton = uicontrol('Style', 'pushbutton', 'String', 'Ferma lettura', 'Callback', @stopReading, 'Position', [140, 20, 100, 20]);

% Inizializzazione variabili globali
isReading = false;
data = []; % Questa variabile sarà preallocata in startReading
s = []; % Oggetto seriale
maxRows = 1000000; % Numero massimo di righe (2 milioni di valori totali)
startTime = []; % Variabile per memorizzare il tempo di inizio della lettura

% Callback per avviare la lettura
function startReading(~, ~, selectedPort, baudRate)
    % Dichiarazione di s, data, maxRows e startTime come variabili globali
    global s data maxRows startTime
    
    % Creazione dell'oggetto seriale utilizzando la porta selezionata e il baud rate specificato
    s = serial(selectedPort);
    set(s, 'BaudRate', baudRate);
    fopen(s); % Apre la porta seriale
    
    % Preallocazione della matrice data
    data = zeros(maxRows, 3);
    rowIndex = 1;
    isReading = true;
    startTime = tic; % Inizia il timer
    
    while isReading
        if strcmp(s.Status, 'open') % Controlla se la porta seriale è aperta
            line = fgetl(s); % Legge una riga di testo dalla porta seriale
            values = str2num(line); % Converte la riga di testo in un array di numeri
            
            if numel(values) == 2 % Assicura che ci siano due valori
                data(rowIndex, 1:2) = values; % Aggiungi i nuovi dati alla matrice
                elapsedTime = toc(startTime); % Calcola il tempo trascorso
                
                if elapsedTime >= 360 % Se sono trascorsi 6 minuti
                    data(rowIndex, 3) = 1; % Segna con un uno
                    startTime = tic; % Resetta il timer
                else
                    data(rowIndex, 3) = 0; % Altrimenti segna con uno zero
                end
                
                rowIndex = rowIndex + 1;
                
                if rowIndex > maxRows
                    disp('Raggiunto il limite massimo di dati.');
                    break;
                end
            else
                disp('Dati incompleti ricevuti, saltato un ciclo.');
            end
            pause(0.1);
        else
            disp('La porta seriale non è stata aperta correttamente.');
            break;
        end
    end
    
    % Rimuovi le righe non utilizzate
    data = data(1:rowIndex-1, :);
    
    % Richiama la funzione per salvare i dati
    saveData(data);
end

% Callback per fermare la lettura
function stopReading(~, ~)
    % Dichiarazione di s e isReading come variabili globali
    global s isReading
    
    if ~isempty(s) && isvalid(s) && strcmp(s.Status, 'open')
        fclose(s);
    end
    isReading = false;
end

% Funzione per salvare i dati
function saveData(data)
    % Richiedi all'utente il nome e la posizione del file
    [fileName, filePath] = uiputfile('*.mat', 'Salva Dati');
    % Controlla se l'utente ha annullato il salvataggio
    if fileName == 0
        disp('Salvataggio annullato.');
    else
        % Salva i dati nel file selezionato
        save(fullfile(filePath, fileName), 'data');
        disp('Dati salvati con successo.');
    end
end
