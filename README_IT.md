# HavenMoonVR 1.2.1 Community Patch

**HavenMoonVR è stato realizzato da Massimo Giannelli tramite ChatGPT a Firenze, Italia.**

[English](README.md) · [Scarica](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.2.1/HavenMoonVR_1.2.1_CommunityPatch.zip) · [SHA-256](https://github.com/HGWells2001/HavenMoonVR/releases/download/v1.2.1/HavenMoonVR_1.2.1_CommunityPatch_SHA256.txt) · [Risoluzione problemi](docs/RISOLUZIONE_PROBLEMI_IT.md)

> **Importante:** questa è una patch artigianale e non ufficiale, realizzata tramite prove pratiche. Viene fornita **così com'è**, senza garanzia che ogni scena, controller o configurazione PC funzioni perfettamente. Conserva il backup pulito creato dall'installer.

HavenMoonVR aggiunge il supporto PC VR alla versione Steam di Haven Moon. La versione 1.2.1 usa due puntatori indipendenti, la posa nativa Quest 2, locomozione relativa alla testa, collisioni corrette, ricentraggio dell'altezza e rendering di oceano e orizzonte sicuro in stereo.

## Compatibilità con il gioco base

L'installer è progettato per funzionare direttamente sulla **build Steam originale e non modificata di Haven Moon**. Non serve installare una versione precedente di HavenMoonVR né un'altra patch.

Prima di modificare qualsiasi cosa, controlla tramite SHA-256 `HavenMoon.exe`, scene e `Assembly-CSharp.dll`. Se la build non è riconosciuta o risulta già modificata senza un backup pulito verificato, l'installazione si interrompe senza applicare la patch. I file originali vengono copiati in `HavenMoonVR_Backup` per il ripristino.

## Funzioni principali

- Puntatori SteamVR indipendenti per controller sinistro e destro.
- Posa Quest 2 `openxr_aim` ottenuta dai percorsi SteamVR separati delle due mani.
- Ogni trigger attiva l'oggetto indicato dalla rispettiva mano.
- Rimosso il puntatore fisso centrale durante il gioco.
- Movimento relativo alla testa e rotazione con stick destro.
- Collisione simmetrica del personaggio centrata sotto il visore.
- Ricentraggio automatico dell'altezza, regolazione F7/F9 e reset Y/F8.
- Orizzonte e Water4 sicuri in stereo, senza riflessione planare o GrabPass legacy.
- Profilo originale di Haven Moon per post-processing, anti-aliasing e qualità grafica.
- Installer incrementale: i file già corretti non vengono riscritti.
- Registrazione Steam/SteamVR automatica facoltativa e grafica personalizzata.

## Installazione

1. Installa o verifica Haven Moon originale tramite Steam.
2. Chiudi Haven Moon e SteamVR.
3. Estrai tutto lo ZIP in un percorso normale e corto, per esempio `C:\HavenMoonVR`.
4. Esegui `Install_HavenMoonVR.cmd`.
5. Scegli la registrazione Steam:
   - **Automatica:** Steam viene chiuso, `Haven Moon VR Community Patch` viene registrato nella Libreria VR con la grafica personalizzata, poi Steam viene riaperto.
   - **Manuale:** Steam rimane aperto e il database dei collegamenti non viene modificato. Aggiungi personalmente `Haven Moon VR.exe` e abilita **Includi nella Libreria VR**.
6. Avvia `Haven Moon VR Community Patch` da Steam/SteamVR oppure esegui `Haven Moon VR.exe`.

## Controlli

| Controllo | Azione |
|---|---|
| Stick sinistro | Movimento relativo alla testa |
| Stick destro | Rotazione |
| Trigger sinistro | Attiva bersaglio sinistro / Fire2 |
| Trigger destro | Attiva bersaglio destro / Fire1 |
| X | Azione opposta / decrementa |
| A | Azione principale / incrementa |
| Y oppure F8 | Ricentra l'altezza |
| F7 / F9 | Abbassa / alza la telecamera di 5 cm |

La risoluzione per applicazione di SteamVR non viene modificata. Nei test Quest 2, 100% a 90 Hz è risultato il punto iniziale più sicuro; valori superiori dipendono dal PC.

## Verifica e rimozione

- `Verify_Installation.cmd` esegue un controllo SHA-256 completo.
- `Configure_Display.cmd` modifica soltanto la finestra specchio sul monitor, non la risoluzione del visore.
- `Uninstall_HavenMoonVR.cmd` ripristina i file originali verificati e rimuove il runtime gestito. Il backup pulito viene conservato.

Il repository contiene sorgenti modificabili e script dell'installer, ma non include file originali di Haven Moon né `openvr_api.dll` di Valve. Il pacchetto completo viene distribuito tramite GitHub Releases.

HavenMoonVR non è affiliato con l'autore o il publisher di Haven Moon, Valve, Meta o OpenAI.
