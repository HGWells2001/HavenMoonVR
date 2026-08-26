# Grafica Steam e SteamVR / Steam and SteamVR artwork

**Grafica fornita da Massimo Giannelli e adattata tramite ChatGPT a Firenze, Italia.**

## Italiano

Il pacchetto contiene immagini separate per le diverse schermate della Libreria:

- `HavenMoonVR_LibraryCapsule_600x900.png`: copertina verticale.
- `HavenMoonVR_LibraryHeader_920x430.png`: intestazione orizzontale e giochi recenti.
- `HavenMoonVR_LibraryHero_3840x1240.png`: sfondo panoramico senza testo.
- `HavenMoonVR_LibraryLogo_720x720.png`: logo con trasparenza reale, sovrapposto allo Hero.
- `HavenMoonVR_LauncherIcon_256x256.png`: icona trasparente per Steam e SteamVR.
- `HavenMoonVR_LauncherIcon.ico`: icona Windows incorporata nel launcher, con risoluzioni 16, 24, 32, 48, 64, 128 e 256 pixel.
- `HavenMoonVR_AppIcon_184x184.jpg`: variante applicazione richiesta dalle specifiche Steam.
- `HavenMoonVR_SteamVR_Background_1920x1080.png`: sfondo 16:9 alternativo per uso manuale.

Con la registrazione **Automatica**, l'installer chiude Steam, calcola l'AppID esatto del collegamento non-Steam e installa Copertina, Intestazione, Hero, Logo e Icona nella cartella `userdata` dell'utente attivo. Al riavvio, Steam e l'interfaccia SteamVR usano la stessa grafica della Libreria.

Con la registrazione **Manuale**, Steam resta aperto e tutte le immagini vengono copiate in `HavenMoonVR_Artwork` dentro la cartella di Haven Moon. Dopo aver aggiunto `Haven Moon VR.exe` come gioco non di Steam:

1. Nella Libreria, fai clic destro sulla copertina e scegli **Gestisci → Imposta grafica personalizzata**.
2. Apri la pagina del gioco, fai clic destro sullo sfondo e scegli **Imposta sfondo personalizzato**.
3. Fai nuovamente clic destro nell'area superiore e scegli **Imposta logo personalizzato**.
4. Se Steam mostra una tessera orizzontale nei giochi recenti, usa l'immagine `920x430`.
5. Riavvia SteamVR se la nuova grafica non compare immediatamente nel visore.

La disinstallazione automatica elimina soltanto le copie ancora identiche agli originali installati. Un'immagine sostituita o modificata dall'utente viene conservata.

## English

The package provides separate images for each Steam Library presentation:

- `HavenMoonVR_LibraryCapsule_600x900.png`: vertical cover.
- `HavenMoonVR_LibraryHeader_920x430.png`: landscape header and recent-games tile.
- `HavenMoonVR_LibraryHero_3840x1240.png`: text-free panoramic background.
- `HavenMoonVR_LibraryLogo_720x720.png`: genuine transparent logo overlaid on the Hero.
- `HavenMoonVR_LauncherIcon_256x256.png`: transparent Steam and SteamVR icon.
- `HavenMoonVR_LauncherIcon.ico`: Windows launcher icon containing 16, 24, 32, 48, 64, 128 and 256-pixel representations.
- `HavenMoonVR_AppIcon_184x184.jpg`: Steam specification application-icon variant.
- `HavenMoonVR_SteamVR_Background_1920x1080.png`: alternative 16:9 background for manual use.

With **Automatic** registration, the installer closes Steam, obtains the exact non-Steam shortcut AppID, and installs the Capsule, Header, Hero, Logo and Icon in the active user's `userdata` directory. After Steam restarts, Steam and the SteamVR interface use the same Library artwork.

With **Manual** registration, Steam remains open and every image is copied to `HavenMoonVR_Artwork` inside the Haven Moon directory. After adding `Haven Moon VR.exe` as a non-Steam game:

1. In the Library, right-click the cover and choose **Manage → Set custom artwork**.
2. Open the game details page, right-click its background and choose **Set custom background**.
3. Right-click the upper area again and choose **Set custom logo**.
4. If Steam displays a landscape recent-games tile, use the `920x430` image.
5. Restart SteamVR if the new Library artwork is not immediately visible in the headset.

Automatic uninstall removes only copies that still match the installed originals. Artwork replaced or edited by the user is preserved.

Dimensions follow Valve's current [Steam Library Assets documentation](https://partner.steamgames.com/doc/store/assets/libraryassets?l=english).
