# GDRCD > Stack

Lo scopo di questo strumento è di fornire un basilare ambiente di sviluppo per [GDRCD](https://github.com/GDRCD/GDRCD), lo Script per la creazione di Giochi di Ruolo "Play by Chat" su browser, e dotare l'utilizzatore di tutti gli strumenti necessari per la sua realizzazione.

Questa soluzione è stata pensata prevalentemente per lo sviluppo in locale, si sconsiglia l'uso in ambienti di produzione se non si hanno le capacità necessarie per comprenderne il funzionamento.

## Requisiti

Per utilizzare lo **_stack_** presente in questa repository, occorre aver installato sul proprio terminale Docker e GIT.
Di seguito, gli indirizzi con i riferimenti per l'installazione di questi strumenti:

- [Docker Desktop (o Docker Toolbox)](https://www.docker.com/products/docker-desktop)
- [GIT](https://git-scm.com/downloads)

Occorre avere un minimo di dimestichezza con il terminale per poter utilizzare lo **_stack_**.

> N.B.: Su sistemi Linux e macOS si utilizza la shell Bash, mentre su Windows è necessario utilizzare WSL (Windows Subsystem for Linux), poiché **lo stack non è compatibile con PowerShell**.

## Installazione

Per utilizzare **_stack_**, clona il progetto in una qualsiasi cartella sul tuo PC. Puoi farlo scaricando l'intero progetto compresso in una cartella zip oppure utilizzando GIT ed eseguendo il seguente comando:

```shell
git clone https://github.com/GDRCD/stack.git
```

Il comando salverà in una cartella `stack` l'intera struttura. Puoi inserirlo in una cartella a tuo piacimento, aggiungendo in fondo al comando sopra indicato il nome della cartella desiderata (qualora non sia presente, la crea in automatico).

Una volta terminato il salvataggio dei file dello stack, occorre inserire il proprio progetto dentro la cartella [`www`](www). Può essere fatto manualmente, così come attraverso `git`.
Per chi sta iniziando con un nuovo progetto di GDRCD, sarà sufficiente eseguire i seguenti comandi:

```shell
cd www
git clone https://github.com/GDRCD/GDRCD.git
```

> N.B.: potrebbe accadere che questo passaggio dia errore per via della presenza del file `.gitkeep`. Nel caso si può tranquillamente rimuovere quest'ultimo e ritentare lo scarico del progetto.

A questo punto, copiare il file [`sample.env`](sample.env) in un nuovo file [`.env`](.env) e compilare le varie variabili presenti.
È molto importante specificare quale versione di PHP si desidera utilizzare, popolando la variabile `PHP_VERSION` con il numero di versione desiderato tra quelle disponibili.

Di seguito le versioni attualmente supportate, con i relativi riferimenti:

- PHP 5.6 (php56)
- PHP 7.3 (php73)
- PHP 8.0 (php80)
- PHP 8.4 (php84)

> N.B.: Puoi cambiare la versione PHP utilizzata in qualsiasi momento, cambiando la variabile nel file [`.env`](.env) e ricostruendo lo stack.

Per proseguire con l'installazione, occorre eseguire il comando di installazione con i permessi di amministratore:

```shell
sudo ./run install
```

> N.B.: è possibile configurare il percorso in cui installare il comando globale aggiungendo l'opzione `-t` dopo [`bin/commands/install`](bin/commands/install) seguito dal percorso desiderato. Di default, il comando viene installato in [`/usr/local/bin/`](/usr/local/bin/).

Il comando di installazione configura l'ambiente di sviluppo e crea un alias di sistema per il progetto.
L'alias sarà uguale al nome specificato nella variabile PROJECT del file `.env`.

Ad esempio, se nel file `.env` è stato impostato:

```shell
PROJECT=mygdrcd
```

Una volta completata l'installazione, sarà possibile utilizzare il comando:

```shell
mygdrcd <comando>
```

al posto di:

```shell
./run <comando>
```

Ora il tuo **_stack_** è pronto e funzionante!

## Configurazione GDRCD

Affinché GDRCD possa funzionare correttamente con lo **_stack_** occorre modificare il file di configurazione dell'engine affinchè possa utilizzare i servizi forniti da questo strumento.

Ad esempio, per la connessione al database vanno utilizzati i seguenti parametri di connessione:

| Variabile      | Descrizione                                                     | Valore                                                           |
| -------------- | --------------------------------------------------------------- | ---------------------------------------------------------------- |
| `host` o `url` | Nome o url dell'host che fornisce il servizio database          | `${PROJECT}_database`, quindi ad esempio: `gdrcd_database`       |
| `username`     | Nome dell'utente con cui si effettua la connessione al database | `root` o `$MYSQL_USER`, quindi ad esempio: `gdrcd`               |
| `password`     | Password dell'utente                                            | `$MYSQL_ROOT_PASSWORD` se si è scelto `root` o `$MYSQL_PASSWORD` |
| `database`     | Nome del database                                               | `$MYSQL_DATABASE`, quindi ad esempio: `gdrcd`                    |

Molti di questi esempi fanno riferimento ai valori associati alle variabili presenti nel file `.env` e che verranno spiegate nel prossimo paragrafo.

## Variabili

Le seguenti variabili possono essere configurate nel file `.env`:

### Configurazione Progetto

| Variabile | Descrizione                                                               | Valore Esempio |
| --------- | ------------------------------------------------------------------------- | -------------- |
| `PROJECT` | Nome del progetto usato per identificare il comando globale e i container | `gdrcd`        |

### Configurazione Servizi

| Variabile      | Descrizione                               | Valore Esempio |
| -------------- | ----------------------------------------- | -------------- |
| `SERVICE_PORT` | Porta per il server web                   | `80`           |
| `PMA_PORT`     | Porta per accedere a phpMyAdmin           | `8080`         |
| `MAILHOG_PORT` | Porta per accedere al pannello di MailHog | `8025`         |
| `DB_PORT`      | Porta per il server MySQL                 | `3306`         |

### Configurazione PHP

| Variabile     | Descrizione                             | Valore Esempio |
| ------------- | --------------------------------------- | -------------- |
| `PHP_VERSION` | Versione di PHP da utilizzare           | `php73`        |
| `PHP_UID`     | ID utente per i processi PHP (www-data) | `1000`         |

#### Configurazione Database

| Variabile             | Descrizione                       | Valore Esempio |
| --------------------- | --------------------------------- | -------------- |
| `MYSQL_ROOT_PASSWORD` | Password utente root MySQL        | `root`         |
| `MYSQL_USER`          | Nome utente applicativo MySQL     | `gdrcd`        |
| `MYSQL_PASSWORD`      | Password utente applicativo MySQL | `gdrcd`        |
| `MYSQL_DATABASE`      | Nome del database predefinito     | `gdrcd`        |

Copia il file `sample.env` in `.env` e modifica i valori secondo le tue necessità. I valori di esempio sono forniti solo come riferimento.

## Utilizzo

Per facilitare l'utilizzo dello strumento, è stato predisposto il comando `run` che raccoglie una serie di comandi utili all'esecuzione delle funzioni primarie dello stack.
Il comando non è altro che un file eseguibile da terminale, motivo per il quale è necessario usare la formula:

```shell
./run <comando>
```

Per avviare l'esecuzione dei servizi dello **_stack_**, sarà sufficiente eseguire il seguente comando:

```shell
./run start
```

In automatico avverrà la compilazione dello **_stack_**, processo che si occuperà di costruire i singoli servizi e di istanziarli in appositi container di docker, e l'avvio dei servizi.

La compilazione dello stack può essere effettuata manualmente in qualsiasi momento, attraverso il comando:

```shell
./run build
```

Ciò può essere utile qualora vengono apportate modifiche allo **_stack_**, come ad esempio una modifica alla versione PHP utilizzata, o se si desidera aggiungere nuovi servizi.

Per fermare i servizi dello **_stack_**, è sufficiente eseguire il seguente comando:

```shell
./run stop
```

Assieme a questi comandi, è stato predisposto anche un comando per rimuovere compleatamente lo **_stack_**, in modo da poterne ricominciare da capo:

```shell
./run clean
```

## Comandi Utili

Di seguito i comandi a disposizione:

```shell
./run start # avvia lo stack
./run stop # ferma lo stack
./run restart # riavvia lo stack
./run build # compila lo stack
./run clean # rimuove tutti tutti i servizi generati dallo stack
./run help # mostra i comandi a disposizione
```

## Dettaglio dei Comandi

`./run start`

Avvia tutti i container dello stack.

`./run stop`

Ferma tutti i container dello stack.

`./run restart`

Riavvia tutti i container dello stack.

`./run build`

Compila tutti i container dello stack.

Opzioni disponibili:

- `-f, --force`: Forza la ricompilazione dei container

`./run clean`

Rimuove tutti i container dello stack.

Opzioni disponibili:

- `-v, --volumes`: Rimuove anche i volumi associati ai container

`./run logs`

Mostra i log di tutti i container dello stack.

Opzioni disponibili:

- `-f, --follow`: Segue i log in tempo reale

`./run recreate`

Ricrea tutti i container e le reti dello stack.

Opzioni disponibili:

- `-f, --force`: Forza la ricreazione dei container

`sudo ./run install`

Installa lo stack e crea un alias di sistema per il progetto.

Opzioni disponibili:

- `-t, --target <path>`: Specifica il percorso di installazione del comando globale (default: [`/usr/local/bin/`](/usr/local/bin/))
- `-f, --force`: Forza la reinstallazione del comando globale

`./run service list`

Elenca tutti i servizi opzionali disponibili.

`./run service enable <service>`

Abilita un servizio opzionale.

`./run service disable <service>`

Disabilita un servizio opzionale.

`./run database logs`

Mostra i log del container `database`.

Opzioni disponibili:

- `-f, --follow`: Segue i log in tempo reale

`./run database start`

Avvia il container `database`.

`./run database stop`

Ferma il container `database`.

`./run database restart`

Riavvia il container `database`.

`./run database build`

Compila il container `database`.

Opzioni disponibili:

- `-f, --force`: Forza la ricompilazione del container

`./run database attach`

Accede alla shell del container `database`.

`run database export <database_name> [file]`

Esporta un database in un file di dump.

Opzioni disponibili:

- `-c, --compress`: Esporta un file di dump compresso

`run database import <database_name> <file>`

Importa un file di dump (.sql, .sql.gz).

Opzioni disponibili:

- `-fd, --force-drop`: Elimina lo schema prima dell'importazione

`run database refresh <database_name>`

Pulisce tutte le tabelle nel database.

`./run webserver logs`

Mostra i log del container `webserver`.

Opzioni disponibili:

- `-f, --follow`: Segue i log in tempo reale

`./run webserver start`

Avvia il container `webserver`.

`./run webserver stop`

Ferma il container `webserver`.

`./run webserver restart`

Riavvia il container `webserver`.

`./run webserver build`

Compila il container `webserver`.

Opzioni disponibili:

- `-f, --force`: Forza la ricompilazione del container

`./run webserver attach`

Accede alla shell del container `webserver`.

`./run phpmyadmin logs`

Mostra i log del container `phpmyadmin`.

Opzioni disponibili:

- `-f, --follow`: Segue i log in tempo reale

`./run phpmyadmin start`

Avvia il container `phpmyadmin`.

`./run phpmyadmin stop`

Ferma il container `phpmyadmin`.

`./run phpmyadmin restart`

Riavvia il container `phpmyadmin`.

`./run phpmyadmin build`

Compila il container `phpmyadmin`.

Opzioni disponibili:

- `-f, --force`: Forza la ricompilazione del container

`./run phpmyadmin attach`

Accede alla shell del container `phpmyadmin`.

`./run mailhog logs`

Mostra i log del container `mailhog`.

Opzioni disponibili:

- `-f, --follow`: Segue i log in tempo reale

`./run mailhog start`

Avvia il container `mailhog`.

`./run mailhog stop`

Ferma il container `mailhog`.

`./run mailhog restart`

Riavvia il container `mailhog`.

`./run mailhog build`

Compila il container `mailhog`.

Opzioni disponibili:

- `-f, --force`: Forza la ricompilazione del container

`./run mailhog attach`

Accede alla shell del container `mailhog`.

> N.B.: Se utilizzi l'installazione, non è necessario eseguire ogni volta il comando da eseguibile, ma direttamente dalla shortcut globale.

> N.B.: Ogni comando dispone di un'opzione `-h` per visualizzare le opzioni disponibili.

## Servizi Disponibili

Lo stack mette a disposizione una serie di servizi, che sono:

- Web Server (nginx)
- PHP (php56, php73, php80, php84)
- MySQL (mysql5.7)
- PhpMyAdmin (phpmyadmin)
- Mailhog (mailhog)

> N.B.: Il servizio `mailhog` è un servizio di test che permette di visualizzare le email inviate dal sistema e funziona solo in ambiente `dev`.

## Segnalazione bug e richieste di aiuto

Prima di aprire una segnalazione bug o una richiesta di aiuto, assicurati che il tuo problema non sia già stato trattato
tra le varie [issues](https://github.com/GDRCD/stack/issues). Se non trovi nulla, puoi aprirne una nuova
[qui](https://github.com/GDRCD/stack/issues/new).

## Riferimenti

Di seguito le versioni di riferimento dell'engine OS GDRCD:

- [GDRCD](https://github.com/GDRCD/GDRCD) © GDRCD Organization, licenza CC

## Licenza

[MIT](https://choosealicense.com/licenses/mit/)
