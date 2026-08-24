# HavenMoonVR 1.1.1 Experimental — Incremental Installer v4

**HavenMoonVR è stato realizzato da Massimo Giannelli tramite ChatGPT a Firenze, Italia.**

[English](README.md) · [Scarica lo ZIP v4](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.1.1-experimental/HavenMoonVR_1.1.1-Experimental.zip) · [Checksum](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.1.1-experimental/HavenMoonVR_1.1.1-Experimental_SHA256.txt) · [Risoluzione problemi](docs/RISOLUZIONE_PROBLEMI_IT.md)

> **Build pubblica attuale:** Incremental Installer v4 — SHA-256 `f4f64c8ef456f60ebfcd8151cab54497cd9fb0428e49d3b0f49616d99265439c`.
>
> Usa il collegamento **Scarica lo ZIP v4** qui sopra. Il pulsante GitHub **Code → Download ZIP** scarica i sorgenti del progetto e non il pacchetto installabile completo.

Prototipo PC VR non ufficiale per Haven Moon, derivato dalla linea stabile 1.0.2. Questa build sostituisce il puntamento centrale durante il gioco con due raggi indipendenti, uno per controller.

## Cosa cambia

- La mano sinistra e la mano destra ricevono posizione e orientamento reali da SteamVR/OpenVR.
- Ogni mano esegue il proprio raycast e può indicare un oggetto diverso.
- Due raggi sottili restano visibili quando i controller sono tracciati: azzurro a sinistra e arancione a destra.
- Il raggio si illumina e mostra un punto sulla superficie quando l'oggetto è realmente interagibile e abbastanza vicino.
- Il trigger sinistro attiva il bersaglio sinistro; il trigger destro attiva il bersaglio destro.
- Il rilascio dei trigger usa lo stesso stato con isteresi dei tasti Fire1/Fire2 e una breve tolleranza per non perdere l'attivazione.
- Il vecchio raycast fisso al centro viene bypassato durante l'interazione di gioco.
- L'oceano usa in VR lo shader Water4 semplificato senza riflessione planare né fusione screen-space, evitando il cuneo nero all'orizzonte quando si inclina la testa.

Locomozione relativa alla testa, rotazione con stick destro, FXAA, VR Origin, reset automatico dell'altezza, Y/F8 e configurazione della qualità SteamVR restano disponibili. Il reset ora compensa correttamente l'offset di 0,683 m già presente nella camera originale, evitando di sommarlo due volte. F7 e F9 permettono di rifinire l'altezza e la scelta viene memorizzata.

## Installazione

1. Chiudi completamente Haven Moon, SteamVR e Steam.
2. Estrai l'intero ZIP.
3. Esegui `Install_HavenMoonVR.cmd`.
4. Riapri Steam.
5. Avvia `Haven Moon VR Experimental` dalla Libreria Steam o SteamVR.

È essenziale usare la voce con **Experimental** nel nome: il vecchio collegamento stabile avvia il bridge 1.0.2, che non trasmette le pose necessarie ai due raggi.

L'installer:

- accetta soltanto la build Steam di Haven Moon già verificata;
- usa o crea un backup pulito verificato dei file originali;
- calcola l'hash SHA-256 di ogni file e aggiorna soltanto quelli mancanti, diversi o non aggiornati;
- lascia completamente intatti i file già corretti, compresa la data di ultima modifica;
- conserva la configurazione video sperimentale già scelta dall'utente;
- crea un backup di `shortcuts.vdf` prima di aggiornarlo;
- incorpora localmente nel launcher l'icona della copia installata di `HavenMoon.exe` e usa la stessa origine per l'icona mostrata da Steam;
- aggiunge o aggiorna il solo collegamento `Haven Moon VR Experimental` con `OpenVR = 1`;
- non include file originali di Haven Moon e copia `openvr_api.dll` dalla SteamVR locale.

## Controlli

| Controllo | Azione |
|---|---|
| Stick sinistro | Movimento relativo alla testa |
| Stick destro | Rotazione |
| Trigger sinistro | Attiva il bersaglio della mano sinistra / Fire2 |
| Trigger destro | Attiva il bersaglio della mano destra / Fire1 |
| X sinistro | Decrementa o direzione opposta sul puntatore sinistro |
| A destro | Incrementa o direzione principale sul puntatore destro |
| Y sinistro | Reset altezza |
| F8 | Reset altezza da tastiera |
| F7 | Abbassa la telecamera di 5 cm e memorizza l'altezza |
| F9 | Alza la telecamera di 5 cm e memorizza l'altezza |

## Separazione dalla stabile

Il pacchetto 1.0.2 stabile non viene modificato. L'installazione sperimentale cambia però i file attivi del gioco, quindi le due patch non possono essere usate contemporaneamente sulla stessa installazione di Haven Moon.

Per tornare alla stabile: esegui `Uninstall_HavenMoonVR.cmd` da questo pacchetto, poi reinstalla HavenMoonVR 1.0.2. La disinstallazione rimuove soltanto il collegamento Steam sperimentale e i suoi file runtime; conserva il backup pulito.

## Stato del prototipo

Il nuovo puntamento riguarda gli oggetti 3D interagibili. I menu Unity continuano a usare il comportamento UI originale e possono richiedere mouse o tastiera. Consulta le [limitazioni note](docs/KNOWN_LIMITATIONS.md) prima del test.

## Struttura del repository

- `src/`: sorgenti C# del runtime, patcher dell'assembly, strumento Steam e launcher.
- `installer/`: installer, bridge OpenVR e configurazione.
- `docs/`: controlli, risoluzione problemi, limitazioni e note di rilascio.
- GitHub Releases: ZIP completo pronto per il test e checksum SHA-256.

Il repository non contiene file originali di Haven Moon né `openvr_api.dll` di Valve. Consulta le [note di compilazione](build/BUILD.md), i [crediti](CREDITS.md) e le [licenze di terze parti](THIRD_PARTY_NOTICES.txt).

HavenMoonVR è una mod non ufficiale e non è affiliata con l'autore o il publisher di Haven Moon, Valve o OpenAI.
