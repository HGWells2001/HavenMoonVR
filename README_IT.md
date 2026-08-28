# HavenMoonVR 1.2.6 Community Patch

**HavenMoonVR è stato realizzato da Massimo Giannelli tramite ChatGPT a Firenze, Italia.**

[English](README.md) · [Repository](https://github.com/HGWells2001/HavenMoonVR) · [Risoluzione problemi](Docs/RISOLUZIONE_PROBLEMI_IT.md)

> **Importante:** questa è una patch artigianale e non ufficiale, realizzata tramite prove pratiche. Viene fornita **così com'è**, senza garanzia che ogni scena, controller o configurazione PC funzioni perfettamente. Conserva il backup pulito creato dall'installer.

HavenMoonVR aggiunge il supporto PC VR alla versione Steam di Haven Moon. La versione 1.2.6 usa due puntatori indipendenti, la posa nativa Quest 2, locomozione relativa alla testa, collisioni corrette e ricentraggio dell'altezza. Mantiene disattivata la riflessione planare dell'oceano e introduce il profilo mirato **Water Enhanced VR**, che valorizza l'acqua senza ripristinare i riflessi problematici di cielo, nuvole e oggetti.

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
- Percorso Water4, GrabPass, fusione della riva, GlobalFog, post-processing e anti-aliasing originali conservati.
- La riflessione planare dell'oceano viene disattivata completamente, eliminando cielo, nuvole e oggetti riflessi senza abbassare la qualità degli altri effetti dell'acqua.
- Water Enhanced VR migliora Fresnel, riflesso cromatico, luce speculare e schiuma e applica il filtraggio trilineare/anisotropico soltanto alle texture dell'oceano.
- Nessun tasto grafico e nessuna modalità acqua VR-safe applicata automaticamente.
- Installer incrementale: i file già corretti non vengono riscritti.
- Registrazione Steam/SteamVR automatica facoltativa e grafica personalizzata.

## Installazione

1. Installa o verifica Haven Moon originale tramite Steam.
2. Salva la partita prima di continuare. La modalità Automatica chiude Haven Moon, SteamVR e Steam; con la modalità Manuale devi chiudere personalmente Haven Moon e SteamVR.
3. Estrai tutto lo ZIP in un percorso normale e corto, per esempio `C:\HavenMoonVR`.
4. Esegui `Install_HavenMoonVR.cmd`.
5. Scegli la registrazione Steam:
   - **Automatica:** Haven Moon, SteamVR e Steam vengono chiusi; `Haven Moon VR Community Patch` viene registrato nella Libreria VR con la grafica personalizzata, poi Steam viene riaperto.
   - **Manuale:** Steam rimane aperto e il database dei collegamenti non viene modificato. Haven Moon e SteamVR devono essere già chiusi. Aggiungi personalmente `Haven Moon VR.exe` e abilita **Includi nella Libreria VR**.
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

La 1.2.6 non riattiva la telecamera di riflessione e non modifica la geometria delle onde. Conserva però gli altri effetti originali, quindi su alcune configurazioni può ancora comparire un difetto stereo dell'acqua o dell'orizzonte. La 1.2.5 offre la stessa esclusione della riflessione senza la nuova regolazione cromatica; la 1.2.2 resta l'alternativa VR-safe più prudente.

## Verifica e rimozione

- Riapri l'installer grafico dopo l'installazione: quando rileva HavenMoonVR nella cartella selezionata, il pulsante **Disinstalla** diventa disponibile e ripristina i file originali verificati.
- `Verify_Installation.cmd` esegue un controllo SHA-256 completo.
- `Configure_Display.cmd` modifica soltanto la finestra specchio sul monitor, non la risoluzione del visore.
- `Uninstall_HavenMoonVR.cmd` ripristina i file originali verificati e rimuove il runtime gestito. Il backup pulito viene conservato.

Il repository contiene sorgenti modificabili e script dell'installer, ma non include file originali di Haven Moon né `openvr_api.dll` di Valve. Il pacchetto completo viene distribuito tramite GitHub Releases.

HavenMoonVR non è affiliato con l'autore o il publisher di Haven Moon, Valve, Meta o OpenAI.
