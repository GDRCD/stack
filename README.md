# GDRCD Stack

Ambiente Docker per sviluppare [GDRCD](https://github.com/GDRCD/GDRCD) in
locale. Richiede Docker, Docker Compose, Bash 3.2 o successivo, `wget`, `curl`
e `tar`; su Windows va usato tramite WSL.

## Installazione rapida

L'installer pubblicato sulla landing di GDRCD scarica l'ultima release nella
directory `stack`:

```bash
eval "$(wget -qO- https://gdrcd.org/stack)"
```

Poi configura e avvia l'ambiente:

```bash
cd stack
cp sample.env .env
rm -f www/.gitkeep
git clone https://github.com/GDRCD/GDRCD.git www
./stack install
./stack build
```

Il comando globale usa il valore `PROJECT` definito in `.env`; se non è
impostato, usa `stack`. Apri una nuova shell dopo `./stack install` per
attivare `PATH`, completion e `cd`.

## Uso essenziale

```bash
./stack start
./stack stop
./stack help
```

## Documentazione

La guida completa in italiano è nel capitolo **Stack di sviluppo** della
[documentazione GDRCD](https://docs.gdrcd.org/stack/panoramica). Comprende installazione,
configurazione, comandi, database, completion, integrazione shell,
aggiornamento, migrazione e sviluppo.

## Segnalazione bug e richieste di aiuto

Prima di aprire una segnalazione bug o una richiesta di aiuto, assicurati che il tuo problema non sia già stato trattato
tra le varie [issues](https://github.com/GDRCD/stack/issues). Se non trovi nulla, puoi aprirne una nuova
[qui](https://github.com/GDRCD/stack/issues/new).

## Licenza

[MIT](LICENSE)
