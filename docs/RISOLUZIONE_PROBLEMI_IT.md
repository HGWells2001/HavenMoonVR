# Risoluzione dei problemi

## Il reticolo centrale è sparito ma non vedo i due raggi

Avvia il gioco esclusivamente dalla voce Steam **Haven Moon VR Experimental**. Il vecchio collegamento stabile non trasmette le pose dei controller. Nella finestra del bridge devono apparire i messaggi `Both VR controllers are ready` e `Experimental dual-pointer shared tracking is ready`.

Se non appaiono, riattiva e muovi entrambi i controller, controlla che SteamVR li mostri e riavvia la voce sperimentale.

## La telecamera è troppo alta o troppo bassa

Premi `F8` oppure `Y` per ricentrare. Usa `F7` per abbassare e `F9` per alzare in passi di 5 cm; la scelta viene memorizzata. La 1.1.1 corregge anche il doppio conteggio dell'offset originale di 0,683 m.

## I raggi esistono ma puntano nella direzione sbagliata

Annota modello del visore, modello dei controller e direzione dell'errore. I driver OpenVR legacy possono usare assi di puntamento leggermente diversi; queste informazioni servono per aggiungere una correzione specifica.

## Un oggetto non si illumina

Devi essere entro 1,8 m, non essere in movimento e colpire direttamente il collider dell'oggetto. I menu 2D mantengono il comportamento originale e possono richiedere mouse o tastiera.

## L'installer si ferma

Chiudi completamente Haven Moon, SteamVR e Steam. Non forzare l'installazione su una build del gioco con checksum diverso: verifica i file di Haven Moon tramite Steam e riprova.

## Controllo installazione

Esegui `Verify_Experimental_Installation.cmd`. Se segnala `WRONG BUILD`, reinstalla la 1.1.1 usando l'intero contenuto dello ZIP.
