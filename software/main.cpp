#include <iostream>
#include <string>
#include "dependencies/include/libpq-fe.h"
using std::cin;
using std::cout;
using std::endl;
using std::string;

#define PG_host "localhost"
#define PG_user "postgres"
#define PG_psw "postgres"
#define PG_db "PROGETTO"
#define PG_port 5432

PGconn* connect(const char*, const char*, const char*, const char*, const int);
void print(PGresult*);
void printMenu();
void checkResults(PGresult*, const PGconn*);
void initQueries(string*);
PGresult* params(PGconn*, string*, int);

int main() {
    PGconn* conn = connect(PG_host, PG_user, PG_db, PG_psw, PG_port);

    string* queries=new string[6];
    initQueries(queries);

    int sel=0;
    do {
        printMenu();
        cout<<" |> Seleziona query.\n |< ";
        cin>>sel;
        PGresult* res=NULL;
        if(sel!=0) {
            switch(sel) {
            case 1:
                cout<<" |> Parametro \"DIVISIONE\" (Disponibili: 1, 2)"<<endl<<" |< ";
                res=params(conn, queries, sel);
                break;
            case 2: case 3:
                res=PQexec(conn, queries[sel-1].c_str());
                break;
            case 4:
                cout<<" |> Parametro \"NUMERO TRASFERIMENTI\""<<endl<<" |< ";
                res=params(conn, queries, sel);
                break;
            case 5:
                cout<<" |> Parametro \"GOL\""<<endl<<" |< ";
                res=params(conn, queries, sel);
                break;
            case 6:
                cout<<" |> Parametro \"MOLTIPLICATORE\" (usa il . per il separatore decimale)"<<endl<<" |< ";
                res=params(conn, queries, sel);
                break;
            default:
                cout<<"\n\t[!] Invalido.\n";
            }
            checkResults(res, conn);
            print(res);
            PQclear(res);
        }
    } while(sel);

    return 0;
}



PGresult* params(PGconn* conn, string queries[], int nq) {
    char name[7];
    sprintf(name, "Query %d", nq);
    PQprepare(conn, name, queries[nq-1].c_str(), 1, NULL);
    string par;
    cin>>par;
    const char* param=par.c_str();
    return PQexecPrepared(conn, name, 1, &param, NULL, 0, 0);
}

PGconn* connect(const char* host, const char* user, const char* db, const char* psw, const int port) {
    char conninfo[256];
    sprintf(conninfo, "host=%s user=%s dbname=%s password=%s port=%d", host, user, db, psw, port);

    PGconn* conn = PQconnectdb(conninfo);

    if(PQstatus(conn) != CONNECTION_OK) {
        cout<<"\t[!] Errore: "<<PQerrorMessage(conn);
        PQfinish(conn);
        // Arresta il programma in caso di mancata connessione.
        exit(1);
    }

    cout<<"\t[!] Connesso a '"<<db<<"'"<<endl;

    return conn;
}



void checkResults(PGresult* res, const PGconn* conn) {
    if(PQresultStatus(res) != PGRES_TUPLES_OK) {
        cout<<"\t[!] Errore: "<<PQerrorMessage(conn)<<endl;
        PQclear(res);
        // Arresta il programma se riscontra errori.
        exit(1);
    }
}

void printLine(int campi, const int* maxLen) {
    for(int i=0; i<campi; i++) {
        cout<<'*';
        for(int j=0; j<maxLen[i]+2; j++)
            cout<<'-';
    }
    cout<<'*'<< endl;
}

void print(PGresult* res) {
    // Prelevo il numero di campi (colonne) e di tuple.
    const int tuple=PQntuples(res), campi=PQnfields(res);
    string data[tuple+1][campi];

    // Imposta il nome dei campi.
    for(int i=0; i<campi; ++i) {
        string s=PQfname(res, i);
        data[0][i]=s;
    }

    // Inserisce i valori.
    for(int i=0; i<tuple; ++i)
        for(int j=0; j<campi; ++j)
            data[i+1][j]=PQgetvalue(res, i, j);

    // Calcola la massima lunghezza per distanziare in modo ottimale i dati.
    int maxChar[campi];
    for(int i=0; i<campi; ++i) {
        maxChar[i]=0;
        for(int j=0; j<tuple+1; ++j) {
            int size=data[j][i].size();
            maxChar[i]=size>maxChar[i] ? size : maxChar[i];
        }
    }

    // Stampa dei nomi dei campi
    printLine(campi, maxChar);
    for(int j=0; j<campi; ++j) {
        cout<<"| ";
        cout<<data[0][j];
        for(int k=0; k<maxChar[j]-data[0][j].size()+1; ++k)
            cout<<' ';
        if(j==(campi-1))
            cout<<"|";
    }
    cout<<endl;
    printLine(campi, maxChar);

    // Stampa dei dati delle tuple
    for(int i=1; i<(tuple+1); ++i) {
        for(int j=0; j<campi; ++j) {
            cout<<"| ";
            cout<<data[i][j];
            for(int k=0; k<maxChar[j]-data[i][j].size()+1; ++k)
                cout<<' ';
            if(j==(campi-1))
                cout<<"|";
        }
        cout<<endl;
    }
    printLine(campi, maxChar);
}

void printMenu() {
    cout<<endl<<" 1) Calendario stagionale con risultati."
        <<endl<<" 2) Classifica della Stagione 21-22 di Serie A."
        <<endl<<" 3) Squadre vincitrici di una coppa per anno."
        <<endl<<" 4) Ricerca trasferimenti."
        <<endl<<" 5) Allenatori che allenano una squadra che ha almeno un giocatore con N gol in tutta la carriera."
        <<endl<<" 6) Allenatori delle squadre che hanno una media gol casalinga superiore alla complessiva."
        <<endl<<endl<<" 0) ESCI"<<endl<<endl;
}

void initQueries(string* q) {
    q[0]=  "SELECT p.Data, p.SquadraCasa AS Casa, p.PunteggioCasa, p.PunteggioOspite, p.SquadraOspite AS Ospite\n"
           "FROM Competizione AS c join Partita AS p on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)\n"
           "WHERE \t(EXTRACT(YEAR FROM p.Data) = 2021 and TO_CHAR(p.Data, 'MM DD') >= TO_CHAR(c.InizioStagione, 'MM DD')\n"
           "\t\tor EXTRACT(YEAR FROM p.Data) = 2022 and TO_CHAR(p.Data, 'MM DD') <= TO_CHAR(c.FineStagione, 'MM DD'))\n"
           "\t\tand c.Zona = 'Italia' and c.Divisione = $1::integer\n"
           "ORDER BY p.Data\n";
    q[1]=  "DROP VIEW IF EXISTS Vittorie;\n"
           "DROP VIEW IF EXISTS Pareggi;\n"
           "DROP VIEW IF EXISTS Stagione2122;\n"
           "CREATE VIEW Stagione2122 AS\n"
           "SELECT p.Data, p.SquadraCasa, p.PunteggioCasa, p.PunteggioOspite, p.SquadraOspite\n"
           "FROM Competizione AS c join Partita AS p on (c.Zona, c.Divisione) = (p.Zona, p.Divisione)\n"
           "WHERE \t(EXTRACT(YEAR FROM p.Data) = 2021 and TO_CHAR(p.Data, 'MM DD') >= TO_CHAR(c.InizioStagione, 'MM DD')\n"
           "\t\tor EXTRACT(YEAR FROM p.Data) = 2022 and TO_CHAR(p.Data, 'MM DD') <= TO_CHAR(c.FineStagione, 'MM DD'))\n"
           "\t\tand c.Zona = 'Italia' and c.Divisione = 1\n"
           "ORDER BY p.Data;\n\n"
           "CREATE VIEW Vittorie AS\n"
           "SELECT vc.Squadra, (COALESCE(VittorieCasa, 0)+COALESCE(VittorieOspite, 0)) AS Vittorie\n"
           "FROM (\n"
           "\tSELECT SquadraCasa AS Squadra, COUNT(*) AS VittorieCasa\n"
           "\tFROM Stagione2122\n"
           "\tWHERE PunteggioCasa > PunteggioOspite\n"
           "\tGROUP BY SquadraCasa\n"
           "\t) AS vc FULL JOIN (\n"
           "\tSELECT SquadraOspite AS Squadra, COUNT(*) AS VittorieOspite\n"
           "\tFROM Stagione2122\n"
           "\tWHERE PunteggioCasa < PunteggioOspite\n"
           "\tGROUP BY SquadraOspite\n"
           "\t) AS vo ON vc.Squadra = vo.Squadra\n"
           "ORDER BY Vittorie DESC;\n\n"
           "CREATE VIEW Pareggi AS\n"
           "SELECT pc.Squadra, (COALESCE(PareggiCasa, 0)+COALESCE(PareggiOspite, 0)) AS Pareggi\n"
           "FROM (\n"
           "\tSELECT SquadraCasa AS Squadra, COUNT(*) AS PareggiCasa\n"
           "\tFROM Stagione2122\n"
           "\tWHERE PunteggioCasa = PunteggioOspite\n"
           "\tGROUP BY SquadraCasa\n"
           "\t) AS pc FULL JOIN (\n"
           "\tSELECT SquadraOspite AS Squadra, COUNT(*) AS PareggiOspite\n"
           "\tFROM Stagione2122\n"
           "\tWHERE PunteggioCasa = PunteggioOspite\n"
           "\tGROUP BY SquadraOspite\n"
           "\t) AS po ON pc.Squadra=po.Squadra\n"
           "ORDER BY Pareggi DESC;\n\n"
           "SELECT \tv.Squadra, (COALESCE(Vittorie, 0)*3 + COALESCE(Pareggi, 0)) AS Punti,\n"
           "\t\tCOALESCE(Vittorie, 0) AS Vittorie,\n"
           "\t\tCOALESCE(Pareggi, 0) AS Pareggi,\n"
           "\t\t((SELECT COUNT(*) FROM Stagione2122)/(SELECT COUNT(DISTINCT(SquadraCasa)) FROM Stagione2122)*2\n"
           "\t\t -COALESCE(Vittorie, 0)-COALESCE(Pareggi, 0)) AS Sconfitte\n"
           "FROM \tVittorie AS v FULL JOIN Pareggi AS p\n"
           "\t\t\ton v.Squadra = p.Squadra\n"
           "ORDER BY Punti DESC";
    q[2]=  "SELECT \t(case\n"
           "\t\t\twhen p.PunteggioCasa > p.punteggioospite then p.SquadraCasa \n"
           "    \t\twhen p.PunteggioCasa < p.punteggioospite then p.SquadraOspite \n"
           "\t\t end) as Vincitore,\n"
           "\t\t (TO_CHAR(p.Data, 'YYYY')) as Anno\n"
           "FROM Competizione as c JOIN Partita as p\n"
           "\ton (c.Zona, c.Divisione) = (p.Zona, p.Divisione)\n"
           "WHERE c.Zona = 'Italia' and c.Divisione = 0\n"
           "ORDER BY (TO_CHAR(p.Data, 'MM')) DESC, (TO_CHAR(p.Data, 'YYYY')) DESC, (TO_CHAR(p.Data, 'DD'))\n"
           "LIMIT (\n"
           "SELECT COUNT(DISTINCT((TO_CHAR(p.Data, 'YYYY'))))\n"
           "FROM Competizione as c JOIN Partita as p\n"
           "\ton (c.Zona, c.Divisione) = (p.Zona, p.Divisione)\n"
           "WHERE c.Zona = 'Italia' and c.Divisione = 0\n"
           ")";
    q[3]=  "SELECT t.Calciatore, c.Nome, c.Cognome, COUNT(*) AS Numero\n"
           "FROM Trasferimento AS t JOIN Calciatore AS c ON t.Calciatore = c.CF\n"
           "WHERE t.Veridicita = 'POSSIBILE'\n"
           "GROUP BY t.Calciatore, c.Nome, c.Cognome\n"
           "HAVING COUNT(*) >= $1::integer";
    q[4]=  "SELECT DISTINCT a.Nome, a.Cognome, s.Nome as Allena\n"
           "FROM (Allenatore AS a JOIN Squadra AS s on a.CF = s.Allenatore) JOIN Calciatore AS c on s.Nome = c.Squadra\n"
           "WHERE c.CF in (SELECT c.CF\n"
           "               FROM Statistica as s JOIN Calciatore AS c ON s.Calciatore = c.CF\n"
           "               GROUP BY c.CF\n"
           "               HAVING SUM(s.Gol) > $1::integer)";
    q[5]=  "SELECT A.Nome, A.Cognome, S.Nome AS Squadra\n"
           "FROM Allenatore AS a JOIN Squadra as s ON a.CF = s.Allenatore\n"
           "WHERE s.Nome in (SELECT p.SquadraCasa\n"
           "                    FROM Partita AS p \n"
           "                    WHERE p.PunteggioCasa > p.PunteggioOspite \n"
           "                    GROUP BY p.SquadraCasa\n"
           "                    HAVING AVG(p.PunteggioCasa) > $1::decimal * (SELECT AVG(p.PunteggioCasa)\n"
           "                                                   FROM Partita AS p))";
}