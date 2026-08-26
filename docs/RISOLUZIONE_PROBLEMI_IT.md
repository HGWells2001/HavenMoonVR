# Risoluzione dei problemi

## Il reticolo centrale è sparito ma non vedo i due raggi

Avvia il gioco esclusivamente dalla voce Steam **Haven Moon VR Community Patch**. Un altro collegamento non trasmette le pose dei controller. Nella finestra del bridge devono apparire i messaggi `Both VR controllers are ready` e `Community dual-pointer shared tracking is ready`.

Se non appaiono, riattiva e muovi entrambi i controller, controlla che SteamVR li mostri e riavvia la voce Community Patch.

## La telecamera è troppo alta o troppo bassa

Premi `F8` oppure `Y` per ricentrare. Usa `F7` per abbassare e `F9` per alzare in passi di 5 cm; la scelta viene memorizzata. La 1.2.1 corregge anche il doppio conteggio dell'offset originale di 0,683 m.

## Compare un cuneo nero tra oceano e cielo inclinando la testa

Horizon Fix v3 disattiva i vecchi filtri a schermo intero `GlobalFog` e `GlobalFogWATER`, che calcolano una sola telecamera piatta invece delle due proiezioni oculari SteamVR. Restano attivi la nebbia nativa della scena, l'oceano e le onde; Water4 usa il percorso conservativo LOD 200 mantenendo disattivati GrabPass a schermo, riflessione planare ed edge blend.

## La grafica trema o l'immagine si sdoppia a intermittenza

Controlla la risoluzione video per Haven Moon nelle impostazioni SteamVR e riportala al **100%**. Durante la prova con Quest 2 a 90 Hz, il 150% ha prodotto fotogrammi persi e sdoppiamento intermittente; al 100% l'immagine è risultata stabile. Il pacchetto non modifica più questa impostazione e non include più `Configure_VR_Quality.cmd`.

## Un corrimano blocca da un lato ma viene attraversato dall'altro

Installa la build con **Collision Fix v2**. La v1 era troppo prudente ed è stata ritirata. La v2 elimina il doppio movimento originale, conserva la stessa velocità complessiva e centra orizzontalmente la capsula del corpo sotto la posizione reale del visore. In questo modo la distanza che vedi dalla testa corrisponde alla collisione del personaggio.

## I raggi esistono ma puntano nella direzione sbagliata

Annota modello del visore, modello dei controller e direzione dell'errore. I driver OpenVR legacy possono usare assi di puntamento leggermente diversi; queste informazioni servono per aggiungere una correzione specifica.

## Un oggetto non si illumina

Devi essere entro 1,8 m, non essere in movimento e colpire direttamente il collider dell'oggetto. I menu 2D mantengono il comportamento originale e possono richiedere mouse o tastiera.

## Devo premere il trigger più volte

La build v4 include Trigger Fix v3: il bridge mantiene il bersaglio attivo fino al vero rilascio di Fire1/Fire2 e il runtime conserva brevemente l'ultimo bersaglio valido.

## L'installer si ferma

La prima esecuzione esegue volutamente tutti i controlli SHA-256 e può richiedere più tempo. Gli aggiornamenti successivi senza modifiche usano la cache rapida delle versioni. Se cambiano dimensione o date di un file, quel file viene nuovamente controllato con SHA-256 e riparato se necessario. Esegui `Verify_Installation.cmd` quando desideri una verifica completa senza cache.

Chiudi completamente Haven Moon e SteamVR. Steam può restare aperto se scegli la registrazione manuale; scegliendo quella automatica viene chiuso dall'installer, anche forzatamente se non risponde, e riaperto al termine. Non forzare l'installazione su una build del gioco con checksum diverso: verifica i file di Haven Moon tramite Steam e riprova.

## Registrazione Steam automatica o manuale

Con **Automatica**, l'installer chiude Steam, salva `shortcuts.vdf`, registra `Haven Moon VR Community Patch` nella Libreria VR e riapre Steam anche se l'installazione termina con un errore. Con **Manuale**, Steam può restare aperto e l'installer non tocca il database: aggiungi `Haven Moon VR.exe` come gioco non di Steam, rinominalo `Haven Moon VR Community Patch` e abilita **Includi nella Libreria VR**. La disinstallazione non rimuove un collegamento creato manualmente.

## La grafica personalizzata non compare in Steam o SteamVR

Con la registrazione automatica, chiudi e riapri anche SteamVR dopo l'installazione: l'interfaccia VR deve ricaricare la Libreria aggiornata. Con la registrazione manuale, usa le immagini nella cartella `HavenMoonVR_Artwork` installata accanto al gioco; consulta `docs/STEAM_ARTWORK_IT_EN.md` per associare Copertina, Intestazione, Hero e Logo alle rispettive schermate. Verifica sempre di modificare la voce **Haven Moon VR Community Patch**.

Se compare `Package file missing`, non usare **Code → Download ZIP** e non avviare file direttamente dentro un archivio compresso. Scarica l'allegato installabile dalla release, usa **Estrai tutto** e avvia `Install_HavenMoonVR.cmd` dalla cartella estratta.

## L'installer mostra `Already current`

È normale: SHA-256 oppure la cache dei file invariati ha confermato che quel file è già corretto, quindi non viene riscritto. `Game/runtime files updated: 0` significa che tutti i file erano già aggiornati; se un solo file è diverso, viene riparato soltanto quello.

## Controllo installazione

Esegui `Verify_Installation.cmd`. Se segnala `WRONG BUILD`, reinstalla la 1.2.1 usando l'intero contenuto dello ZIP.
