# Risoluzione dei problemi

## Il reticolo centrale è sparito ma non vedo i due raggi

Avvia il gioco esclusivamente dalla voce Steam **Haven Moon VR Experimental**. Il vecchio collegamento stabile non trasmette le pose dei controller. Nella finestra del bridge devono apparire i messaggi `Both VR controllers are ready` e `Experimental dual-pointer shared tracking is ready`.

Se non appaiono, riattiva e muovi entrambi i controller, controlla che SteamVR li mostri e riavvia la voce sperimentale.

## La telecamera è troppo alta o troppo bassa

Premi `F8` oppure `Y` per ricentrare. Usa `F7` per abbassare e `F9` per alzare in passi di 5 cm; la scelta viene memorizzata. La 1.1.1 corregge anche il doppio conteggio dell'offset originale di 0,683 m.

## Compare un cuneo nero tra oceano e cielo inclinando la testa

Installa la build pubblica Incremental Installer v4, che include Horizon Fix v2. Questa revisione elimina la riflessione planare e la fusione screen-space incompatibili con il rollio VR, mantenendo oceano e onde con lo shader Water4 semplificato.

## I raggi esistono ma puntano nella direzione sbagliata

Annota modello del visore, modello dei controller e direzione dell'errore. I driver OpenVR legacy possono usare assi di puntamento leggermente diversi; queste informazioni servono per aggiungere una correzione specifica.

## Un oggetto non si illumina

Devi essere entro 1,8 m, non essere in movimento e colpire direttamente il collider dell'oggetto. I menu 2D mantengono il comportamento originale e possono richiedere mouse o tastiera.

## Devo premere il trigger più volte

La build v4 include Trigger Fix v3: il bridge mantiene il bersaglio attivo fino al vero rilascio di Fire1/Fire2 e il runtime conserva brevemente l'ultimo bersaglio valido.

## L'installer si ferma

Chiudi completamente Haven Moon, SteamVR e Steam. Non forzare l'installazione su una build del gioco con checksum diverso: verifica i file di Haven Moon tramite Steam e riprova.

Se compare `Package file missing`, non usare **Code → Download ZIP** e non avviare file direttamente dentro un archivio compresso. Scarica l'allegato installabile dalla release, usa **Estrai tutto** e avvia `Install_HavenMoonVR.cmd` dalla cartella estratta.

## L'installer mostra `Already current`

È normale: il controllo SHA-256 ha confermato che quel file è già corretto, quindi non viene riscritto. `Game/runtime files updated: 0` significa che tutti i file erano già aggiornati; se un solo file è diverso, viene riparato soltanto quello.

## Controllo installazione

Esegui `Verify_Experimental_Installation.cmd`. Se segnala `WRONG BUILD`, reinstalla la 1.1.1 usando l'intero contenuto dello ZIP.
