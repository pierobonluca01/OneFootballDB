-- TABLES

-- Eliminazione tabelle preliminare
DROP TABLE IF EXISTS Arbitraggio;
DROP TYPE IF EXISTS ruoloA;
DROP TABLE IF EXISTS Arbitro;
DROP TABLE IF EXISTS Partita CASCADE;
DROP TABLE IF EXISTS Competizione;
DROP TYPE IF EXISTS comp;
DROP TABLE IF EXISTS Trasferimento;
DROP TYPE IF EXISTS ver;
DROP TABLE IF EXISTS Statistica;
DROP TABLE IF EXISTS Calciatore;
DROP TYPE IF EXISTS ruoloC;
DROP TABLE IF EXISTS Articolo;
DROP TABLE IF EXISTS Squadra;
DROP TABLE IF EXISTS Allenatore;
DROP TABLE IF EXISTS Stadio;


-- Creazione tabella Stadio
CREATE TABLE Stadio(
    Nome varchar(50) NOT NULL,
    Citta varchar(40) NOT NULL,
    Capienza int NOT NULL,
    PRIMARY KEY(Nome, Citta)
);

-- Creazione della tabella Allenatore
CREATE TABLE Allenatore(
    CF char(16) PRIMARY KEY NOT NULL,
    Nome varchar(20) NOT NULL,
    Cognome varchar(20) NOT NULL,
    DataNascita date NOT NULL,
    Nazionalita varchar(30) NOT NULL,
	CHECK(DataNascita < CURRENT_DATE)
);

-- Creazione della tabella Squadra
CREATE TABLE Squadra(
    Nome varchar(30) PRIMARY KEY NOT NULL,
    Fondazione date,
    Stadio varchar(50) NOT NULL,
    Citta varchar(40) NOT NULL,
    Allenatore char(16),
    FOREIGN KEY (Stadio, Citta) REFERENCES Stadio(Nome, Citta)
		ON UPDATE cascade,
    FOREIGN KEY (Allenatore) REFERENCES Allenatore(CF)
		ON DELETE set null
);

-- Creazione della tabella Articolo
CREATE TABLE Articolo(
    ID int PRIMARY KEY NOT NULL,
    Data date NOT NULL,
    Testo text NOT NULL,
    Autore varchar(40) NOT NULL,
	Squadra varchar(30) NOT NULL,
    FOREIGN KEY (Squadra) REFERENCES Squadra(Nome)
		ON DELETE no action
);

-- Definizione ENUM ruoloC
CREATE TYPE ruoloC AS ENUM('POR', 'DIF', 'CEN', 'ATT');

-- Creazione della tabella Calciatore
CREATE TABLE Calciatore(
    CF char(16) PRIMARY KEY NOT NULL,
    Nome varchar(20) NOT NULL,
    Cognome varchar(20) NOT NULL,
    DataNascita date NOT NULL,
    Nazionalita varchar(30) NOT NULL,
    Numero smallint NOT NULL,
    Ruolo ruoloC NOT NULL,
    Cartellino smallint,
    Squadra varchar(30),
    DataInizio date,
    DataFine date,
    FOREIGN KEY (Squadra) REFERENCES Squadra(Nome)
		ON DELETE cascade,
	CHECK(DataInizio < DataFine),
	CHECK(Cartellino > 0),
	CHECK(DataNascita < CURRENT_DATE)
);

-- Creazione della tabella Statistica
CREATE TABLE Statistica(
    DataInizio date NOT NULL,
    Calciatore char(16) NOT NULL,
    DataFine date NOT NULL,
    Gol smallint NOT NULL,
    Assist smallint NOT NULL,
    Gialli smallint NOT NULL,
    Rossi smallint NOT NULL,
    GolSubiti smallint,
    PRIMARY KEY(DataInizio, Calciatore),
    FOREIGN KEY (Calciatore) REFERENCES Calciatore(CF),
	CHECK(DataInizio < DataFine)
);

-- Definizione ENUM ver

CREATE TYPE ver AS ENUM('SALTATO', 'FAKE', 'POSSIBILE', 'EFFETTUATO'); 

-- Creazione della tabella Trasfrimento
CREATE TABLE Trasferimento(
    Calciatore char(16) NOT NULL,
    Squadra varchar(30) NOT NULL,
    Veridicita ver NOT NULL,
    Offerta smallint NOT NULL,
    PRIMARY KEY(Calciatore, Squadra),
    FOREIGN KEY (Calciatore) REFERENCES Calciatore(CF),
    FOREIGN KEY (Squadra) REFERENCES Squadra(Nome)    
);

-- Definizione ENUM comp
CREATE TYPE comp AS ENUM('LEGA', 'COPPA', 'TORNEOINT');

-- Creazione della tabella Competizione
CREATE TABLE Competizione (
    Zona varchar(30) NOT NULL,
    Divisione smallint NOT NULL,
    Tipologia comp NOT NULL,
    InizioStagione date NOT NULL,
    FineStagione date NOT NULL,
	Nome varchar(20) NOT NULL,
	PRIMARY KEY(Zona, Divisione),
	CHECK(InizioStagione < FineStagione)
);

-- Creazione della tabella Partita
CREATE TABLE Partita(
    Data date NOT NULL,
    SquadraCasa varchar(30) NOT NULL,
    SquadraOspite varchar(30) NOT NULL,
    PunteggioCasa smallint NOT NULL,
    PunteggioOspite smallint NOT NULL,
    Zona varchar(30) NOT NULL,
    Divisione smallint NOT NULL,
    PRIMARY KEY(Data, SquadraCasa),
    FOREIGN KEY (SquadraCasa) REFERENCES Squadra(Nome),
    FOREIGN KEY (SquadraOspite) REFERENCES Squadra(Nome),
    FOREIGN KEY (Zona, Divisione) REFERENCES Competizione(Zona, Divisione),
	CHECK(SquadraCasa <> SquadraOspite)
);

-- Creazione della tabella Arbitro
CREATE TABLE Arbitro(
    CF char(16) PRIMARY KEY NOT NULL,
    Nome varchar(20) NOT NULL,
    Cognome varchar(20) NOT NULL,
    DataNascita date NOT NULL,
    Nazionalita varchar(30) NOT NULL,
    LivelloLicenza smallint NOT NULL,
	CHECK(DataNascita < CURRENT_DATE)
);

-- Definizione ENUM ruoloA
CREATE TYPE ruoloA AS ENUM('DIR', 'GL', 'VAR', 'QUARTO');

-- Creazione della tabella Arbitraggio
CREATE TABLE Arbitraggio(
    Arbitro char(16) NOT NULL,
    DataPartita date NOT NULL,
    SquadraCasa varchar(30) NOT NULL,
    Ruolo ruoloA NOT NULL,
    PRIMARY KEY(Arbitro, DataPartita, SquadraCasa),
    FOREIGN KEY (Arbitro) REFERENCES Arbitro(CF),
    FOREIGN KEY (DataPartita, SquadraCasa) REFERENCES Partita(Data, SquadraCasa) 
);

-- Definizione indice
CREATE INDEX punteggi ON Partita(PunteggioCasa, PunteggioOspite);