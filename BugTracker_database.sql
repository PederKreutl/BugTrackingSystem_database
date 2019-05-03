/******************************************************************************
 * Project:   2BIT IDS, Project                                               *
 *            Faculty of Information Technolgy                                *
 *            Brno University of Technology                                   *
 * File:      xkruty00_xmojzi08.sql                                           *
 * Date:      Task1 - 15.03.2019                                              *
 *            Task2 - 31.03.2019                                              *
 *            Task3 - 14.04.2019                                              *
 *            Task4/5 - 29.04.2019                                            *
 * Authors:   Peter Kruty, <xkruty00@stud.fit.vutrb.cz>                       *
 *            Tomas Mojzis, <xmojzi08@stud.fit.vutbr.cz>                      *
 ******************************************************************************/

/* Pre korektny vypis dbms_output.put_line() */
SET SERVEROUTPUT ON;

/************************** DROPING EXISTING TABLES ***************************/
DROP TABLE Programator CASCADE CONSTRAINTS;
DROP TABLE Uzivatel CASCADE CONSTRAINTS;
DROP TABLE Tiket CASCADE CONSTRAINTS;
DROP TABLE Bug CASCADE CONSTRAINTS;
DROP TABLE Patch CASCADE CONSTRAINTS;
DROP TABLE Modul CASCADE CONSTRAINTS;
DROP TABLE ProgJazyk CASCADE CONSTRAINTS;

DROP TABLE ProgramatorOvladaProgJazyk CASCADE CONSTRAINTS;
DROP TABLE UzivatelOvladaProgJazyk CASCADE CONSTRAINTS;
DROP TABLE TiketObsahujeBug CASCADE CONSTRAINTS;
DROP TABLE BugVModule CASCADE CONSTRAINTS;
DROP TABLE ModulVyuzivaProgJazyk CASCADE CONSTRAINTS;

DROP SEQUENCE programovaci_jazyk_seq;

/************************ VYTVARANIE NOVYCH TABULIEK **************************/
/*--------------------------------- Entity -----------------------------------*/
CREATE TABLE Programator (
prog_login CHAR(8) PRIMARY KEY,
meno VARCHAR(30) NOT NULL,
priezvisko VARCHAR(30) NOT NULL,
vek INTEGER NOT NULL,
mesto VARCHAR(20) NOT NULL,
ulica VARCHAR(20) NOT NULL,
psc INTEGER NOT NULL,
email VARCHAR(40) NOT NULL,
junior_hodnost VARCHAR(20),
pocet_juniorov INTEGER,
  CONSTRAINT check_prog_login CHECK (REGEXP_LIKE(prog_login, '^x.{5}[0-9][0-9]$')),
  CONSTRAINT check_prog_vek CHECK (vek BETWEEN 1 AND 150),
  CONSTRAINT check_prog_ulica CHECK (REGEXP_LIKE(ulica, '^.*\s[1-9]?[0-9]$')),
  CONSTRAINT check_prog_psc CHECK (REGEXP_LIKE(psc, '^[0-9]{5}$')),
  CONSTRAINT check_prog_email
    CHECK (REGEXP_LIKE(email, '[^@]+@[^.]+\..+')),
  CONSTRAINT check_prog_junior_hodnost
    CHECK ((junior_hodnost IN('Začiatočník', 'Pokročilý', 'Expert')) OR (junior_hodnost IS NULL)),
  CONSTRAINT check_prog_pocet_juniorov
    CHECK ((pocet_juniorov BETWEEN 0 AND 10) OR pocet_juniorov IS NULL),
  CONSTRAINT check_prog_sr_jr
    CHECK (((junior_hodnost IS NULL) AND (pocet_juniorov IS NOT NULL)) OR ((junior_hodnost IS NOT NULL) AND (pocet_juniorov IS NULL)))
);

CREATE TABLE Uzivatel (
uzivatel_login CHAR(8) PRIMARY KEY,
meno VARCHAR(30) NOT NULL,
priezvisko VARCHAR(30) NOT NULL,
vek INTEGER NOT NULL,
mesto VARCHAR(20) NOT NULL,
ulica VARCHAR(20) NOT NULL,
psc INTEGER NOT NULL,
email VARCHAR(40) NOT NULL,
cislo_uctu VARCHAR(24), -- v tvare MMMMMK-MMMMMMMKM/XXXXXXX (M - predcislie/cislo, K - kontrolne cislo, X - kod banky)
-- https://www.penize.cz/bezne-ucty/15470-tajemstvi-cisla-uctu
  CONSTRAINT check_uziv_login CHECK (REGEXP_LIKE(uzivatel_login, '^x.{5}[0-9][0-9]$')),
  CONSTRAINT check_uziv_vek CHECK (vek BETWEEN 1 AND 150),
  CONSTRAINT check_uziv_ulica CHECK (REGEXP_LIKE(ulica, '^.*\s[1-9]?[0-9]$')),
  CONSTRAINT check_uziv_psc CHECK (REGEXP_LIKE(psc, '^[0-9]{5}$')),
  CONSTRAINT check_uziv_email CHECK (REGEXP_LIKE(email, '[^@]+@[^.]+\..+')),
  CONSTRAINT check_cislo_uctu_tvar CHECK (
    REGEXP_LIKE(substr(cislo_uctu,1,6), '[0-9]*')
    AND
    REGEXP_LIKE(substr(cislo_uctu,8,16), '[0-9]*')
    AND
    REGEXP_LIKE(substr(cislo_uctu,18,7), '[0-9]*')
    AND
    substr(cislo_uctu,7,1) = '-'
    AND
    substr(cislo_uctu,17,1) = '/' ),
  CONSTRAINT  check_cislo_uctu_checksum CHECK (
    MOD(
    TO_NUMBER(substr(cislo_uctu,1,1)) * 10 +
    TO_NUMBER(substr(cislo_uctu,2,1)) * 5 +
    TO_NUMBER(substr(cislo_uctu,3,1)) * 8 +
    TO_NUMBER(substr(cislo_uctu,4,1)) * 4 +
    TO_NUMBER(substr(cislo_uctu,5,1)) * 2 +
    TO_NUMBER(substr(cislo_uctu,6,1)) * 1, 11) = 0
      AND
    MOD(
    TO_NUMBER(substr(cislo_uctu,8,1)) * 3 +
    TO_NUMBER(substr(cislo_uctu,9,1)) * 7 +
    TO_NUMBER(substr(cislo_uctu,10,1)) * 9 +
    TO_NUMBER(substr(cislo_uctu,11,1)) * 10 +
    TO_NUMBER(substr(cislo_uctu,12,1)) * 5 +
    TO_NUMBER(substr(cislo_uctu,13,1)) * 8 +
    TO_NUMBER(substr(cislo_uctu,14,1)) * 4 +
    TO_NUMBER(substr(cislo_uctu,15,1)) * 2 +
    TO_NUMBER(substr(cislo_uctu,16,1)) * 1, 11) = 0
    )

);

CREATE TABLE Modul (
id_modul INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
nazov VARCHAR(20) NOT NULL,
zodpovedny CHAR(8) NOT NULL,
  CONSTRAINT FK_modul_zodpovedny FOREIGN KEY (zodpovedny) REFERENCES Programator (prog_login)
);

CREATE TABLE Patch (
id_patch INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
predmet VARCHAR(50) NOT NULL,
datum_vytvorenia DATE NOT NULL,
datum_schvalenia DATE,
prog_tvorca CHAR(8),
uzivatel_login CHAR(8), -- Tvorca patchu
prog_zaviedol CHAR(8),
datum_zavedenia DATE,
  CONSTRAINT FK_patch_prog_tvorca FOREIGN KEY (prog_tvorca) REFERENCES Programator (prog_login),
  CONSTRAINT FK_patch_uziv_tvorca FOREIGN KEY (uzivatel_login) REFERENCES Uzivatel (uzivatel_login),
  CONSTRAINT FK_patch_prog_zaviedol FOREIGN KEY (prog_zaviedol) REFERENCES Programator (prog_login),
  CONSTRAINT check_patch_up
    CHECK (((prog_tvorca IS NULL) AND (uzivatel_login IS NOT NULL)) OR ((prog_tvorca IS NOT NULL) AND (uzivatel_login IS NULL))),
  CONSTRAINT check_datumy1 CHECK ((datum_vytvorenia <= datum_schvalenia) OR (datum_schvalenia IS NULL)),
  CONSTRAINT check_datumy2 CHECK ((datum_vytvorenia <= datum_zavedenia) OR (datum_zavedenia IS NULL)),
  CONSTRAINT check_datumy3 CHECK ((datum_schvalenia <= datum_zavedenia) OR (datum_schvalenia IS NULL) OR (datum_zavedenia IS NULL))
);

CREATE TABLE Tiket (
id_tiket INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
tiket_predmet VARCHAR(50) NOT NULL,
stav CHAR(15) NOT NULL CHECK (stav IN('Priradený', 'Nepriradený', 'Archivovaný')),
uzivatel_login CHAR(8) NOT NULL, -- Tvorca tiketu
prog_login CHAR(8), -- Riesitel tiketu
  CONSTRAINT FK_podal_uzivatel FOREIGN KEY (uzivatel_login) REFERENCES Uzivatel (uzivatel_login),
  CONSTRAINT FK_zabral_programator FOREIGN KEY (prog_login) REFERENCES Programator (prog_login),
  CONSTRAINT check_stav_tiketu CHECK (((prog_login IS NULL) AND (stav = 'Nepriradený'))
                                    OR ((prog_login IS NOT NULL) AND (stav = 'Priradený'))
                                    OR ((prog_login IS NOT NULL) AND (stav = 'Archivovaný')))
);

CREATE TABLE Bug (
id_bug INTEGER GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
bug_predmet VARCHAR(50) NOT NULL,
zavaznost0_10 INTEGER NOT NULL CHECK (zavaznost0_10 BETWEEN 0 AND 10),
zranitelnost INTEGER NOT NULL CHECK (zranitelnost IN(0, 1)),
riziko_zneuzitia VARCHAR(50),
rieseny_patchom INTEGER,
  CONSTRAINT FK_bug_rieseny_patchom FOREIGN KEY (rieseny_patchom) REFERENCES Patch (id_patch),
  CONSTRAINT check_zranitelnost CHECK (((zranitelnost = 0) AND (riziko_zneuzitia IS NULL))
                                    OR ((zranitelnost = 1) AND (riziko_zneuzitia IS NOT NULL))),
  CONSTRAINT check_riziko_zneuzitia CHECK (riziko_zneuzitia IN('Malé', 'Stredné', 'Veľké'))
);

CREATE TABLE ProgJazyk (
id_jazyk INTEGER NOT NULL PRIMARY KEY,
nazov VARCHAR(30) NOT NULL
);

/*---------------------------------- Relacie ---------------------------------*/
CREATE TABLE ProgramatorOvladaProgJazyk (
prog_login CHAR(8) NOT NULL,
id_jazyk INTEGER NOT NULL,
  CONSTRAINT PK_ProgProgJazyk PRIMARY KEY (prog_login, id_jazyk),
  CONSTRAINT FK_pop_prog_login FOREIGN KEY (prog_login) REFERENCES Programator (prog_login)
    ON DELETE CASCADE,
  CONSTRAINT FK_pop_id_jazyk FOREIGN KEY (id_jazyk) REFERENCES ProgJazyk (id_jazyk)
    ON DELETE CASCADE
);

CREATE TABLE UzivatelOvladaProgJazyk (
uzivatel_login CHAR(8) NOT NULL,
id_jazyk INTEGER NOT NULL,
  CONSTRAINT PK_UzivProgJazyk PRIMARY KEY (uzivatel_login, id_jazyk),
  CONSTRAINT FK_UzivProgJazyk_uzivatel_login FOREIGN KEY (uzivatel_login) REFERENCES Uzivatel (uzivatel_login)
    ON DELETE CASCADE,
  CONSTRAINT FK_UzivProgJazyk_id_jazyk FOREIGN KEY (id_jazyk) REFERENCES ProgJazyk (id_jazyk)
    ON DELETE CASCADE
);

CREATE TABLE ModulVyuzivaProgJazyk (
id_modul INTEGER NOT NULL,
id_jazyk INTEGER NOT NULL,
  CONSTRAINT PK_ModulProgJazyk PRIMARY KEY (id_modul, id_jazyk),
  CONSTRAINT FK_MVP_id_modul FOREIGN KEY (id_modul) REFERENCES Modul (id_modul)
    ON DELETE CASCADE,
  CONSTRAINT FK_MVP_id_jazyk FOREIGN KEY (id_jazyk) REFERENCES ProgJazyk (id_jazyk)
    ON DELETE CASCADE
);

CREATE TABLE TiketObsahujeBug (
id_tiket INTEGER NOT NULL,
id_bug INTEGER NOT NULL,
  CONSTRAINT PK_TiketBug PRIMARY KEY (id_tiket, id_bug),
  CONSTRAINT FK_TiketBug_id_tiket FOREIGN KEY (id_tiket) REFERENCES Tiket (id_tiket)
    ON DELETE CASCADE,
  CONSTRAINT FK_TiketBug_id_bug FOREIGN KEY (id_bug) REFERENCES Bug (id_bug)
    ON DELETE CASCADE
);

CREATE TABLE BugVModule (
id_bug INTEGER NOT NULL,
id_modul INTEGER NOT NULL,
  CONSTRAINT PK_BugModul PRIMARY KEY (id_bug, id_modul),
  CONSTRAINT FK_BugModul_id_bug FOREIGN KEY (id_bug) REFERENCES Bug (id_bug)
    ON DELETE CASCADE,
  CONSTRAINT FK_BugModul_id_modul FOREIGN KEY (id_modul) REFERENCES Modul(id_modul)
    ON DELETE CASCADE
);

/********************************** TRIGGERY **********************************/
-- Trigger 1 --
-- Popis: Trigger v pripade zavedenia noveho patchu vypise informacie o tom
-- kto ho zaviedol, pocet dni od vytvorenia a pocet dni od schvalenia patchu
CREATE OR REPLACE TRIGGER patch_zobraz_info_zavedenia
  AFTER INSERT OR UPDATE OF datum_zavedenia ON Patch
  FOR EACH ROW
DECLARE
  od_vytvorenia number;
  od_schvalenia number;
BEGIN
  od_vytvorenia := :NEW.datum_zavedenia - :NEW.datum_vytvorenia;
  od_schvalenia := :NEW.datum_zavedenia - :NEW.datum_schvalenia;

  DBMS_OUTPUT.PUT_LINE('Patch: ' || :NEW.predmet);
  DBMS_OUTPUT.PUT_LINE('Zaviedol: ' || :NEW.prog_zaviedol);
  DBMS_OUTPUT.PUT_LINE('Pocet dni od vytvorenia: ' || od_vytvorenia);
  DBMS_OUTPUT.PUT_LINE('Pocet dni od schvalenia: ' || od_schvalenia);
END;
/

-- Trigger 2 --
-- Popis: Automatické generovanie hodnôt primárneho kľúča pre tabuľku ProgJazyk,
-- ak je zadaná hodnota pri vlkladaní nedefinovaná (NULL).
CREATE SEQUENCE programovaci_jazyk_seq;
CREATE OR REPLACE TRIGGER inc_PJ_id BEFORE
  INSERT ON ProgJazyk
  FOR EACH ROW
  WHEN ( new.id_jazyk IS NULL )
BEGIN
  :new.id_jazyk := programovaci_jazyk_seq.nextval;
END;
/

/************************ VKLADANIE HODNOT DO TABULIEK ************************/
INSERT INTO Programator
VALUES ('xkruty00', 'Peter', 'Krutý', 20, 'Sliač', 'Tajovkého 1', 96531, 'xkruty00@stud.fit.vutbr.cz', NULL, 0);
INSERT INTO Programator
VALUES ('xmojzi08', 'Tomáš', 'Mojžiš', 21, 'Zvolen', 'P. Jilemnického 32', 96533, 'xmojzi08@stud.fit.vutbr.cz', 'Expert', NULL);
INSERT INTO Programator
VALUES ('xabate01', 'Dimitri', 'Abate', 50, 'Bacúch', 'Slizkého 2', 92345, 'xabate01@stud.fit.vutbr.cz', NULL, 10);


INSERT INTO Uzivatel
VALUES ('xjezko22', 'Ježimír', 'Záhradný', 43, 'Bratislava', 'Lazovná 1', 96251, 'jezino@zahrada.sk','000000-219377742/0300000');
INSERT INTO Uzivatel
VALUES ('xchlad16', 'Martin', 'Chládek', 20, 'Brno', 'Božetechova 2', 96532, 'xchlad16@stud.fit.vutbr.cz', NULL);
INSERT INTO Uzivatel
VALUES ('xmrkev42', 'Adam', 'Mrkevný', 18, 'Brno', 'Božetěchova 2', 61266, 'mamradmrkev@example.com', NULL);

INSERT INTO Modul
VALUES (2222, 'body.php', 'xmojzi08');
INSERT INTO Modul
VALUES (42, 'main-menu.py', 'xkruty00');

INSERT INTO Patch (id_patch ,predmet, datum_vytvorenia, datum_schvalenia, prog_tvorca, uzivatel_login, prog_zaviedol, datum_zavedenia)
VALUES (2, 'table-fix', TO_DATE('2018-03-24', 'YYYY-MM-DD'), TO_DATE('2018-03-25', 'YYYY-MM-DD'), NULL, 'xjezko22', 'xkruty00', TO_DATE('2018-07-26', 'YYYY-MM-DD'));
INSERT INTO Patch (predmet, datum_vytvorenia, datum_schvalenia, prog_tvorca, uzivatel_login, prog_zaviedol, datum_zavedenia)
VALUES ('link-fix', TO_DATE('23.03.2018', 'dd.mm.yyyy'), TO_DATE('23.03.2018', 'dd.mm.yyyy'), NULL, 'xchlad16', 'xmojzi08',  TO_DATE('16.06.2018', 'dd.mm.yyyy'));

INSERT INTO Tiket (id_tiket ,tiket_predmet, stav, uzivatel_login, prog_login)
VALUES (5, 'Nefunkčné tlačidlo v hlavnom menu', 'Priradený', 'xchlad16', 'xmojzi08');
INSERT INTO Tiket (tiket_predmet, stav, uzivatel_login, prog_login)
VALUES ('Nefunkčný odkaz v ponuke', 'Priradený', 'xchlad16', 'xkruty00');

INSERT INTO Bug (bug_predmet, zavaznost0_10, zranitelnost, riziko_zneuzitia, rieseny_patchom)
VALUES ('Hlavné menu - Nefunkčné tlačidlo', 1, 0, NULL, 2);
INSERT INTO Bug (id_bug ,bug_predmet, zavaznost0_10, zranitelnost, riziko_zneuzitia, rieseny_patchom)
VALUES (2, 'Ponuka - Nefunkčný odkaz', 10, 1, 'Malé', 1);
INSERT INTO Bug (id_bug, bug_predmet, zavaznost0_10, zranitelnost, riziko_zneuzitia, rieseny_patchom)
VALUES (3, 'Hlavné menu - Nedostupné nastavenia', 10, 1, 'Malé', NULL);
INSERT INTO Bug (id_bug, bug_predmet, zavaznost0_10, zranitelnost, riziko_zneuzitia, rieseny_patchom)
VALUES (4, 'Nastavenie - Bug so stredným rizikom', 7, 1, 'Stredné', NULL);

INSERT INTO ProgJazyk (nazov)
VALUES ('Python');
INSERT INTO ProgJazyk (nazov)
VALUES ('PHP');
INSERT INTO ProgJazyk (id_jazyk, nazov)
VALUES (NULL, 'ABAP');
INSERT INTO ProgJazyk (id_jazyk, nazov)
VALUES (NULL, 'Datalog');
INSERT INTO ProgJazyk (nazov)
VALUES ('C#');


INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xabate01', 4);

INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xmojzi08', 1);
INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xmojzi08', 2);

INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xkruty00', 1);
INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xkruty00', 2);
INSERT INTO ProgramatorOvladaProgJazyk
VALUES ('xkruty00', 3);

INSERT INTO UzivatelOvladaProgJazyk (uzivatel_login, id_jazyk)
VALUES ('xjezko22', 1);
INSERT INTO UzivatelOvladaProgJazyk (uzivatel_login, id_jazyk)
VALUES ('xjezko22', 2);

INSERT INTO UzivatelOvladaProgJazyk (uzivatel_login, id_jazyk)
VALUES ('xchlad16', 1);
INSERT INTO UzivatelOvladaProgJazyk (uzivatel_login, id_jazyk)
VALUES ('xchlad16', 2);
INSERT INTO UzivatelOvladaProgJazyk (uzivatel_login, id_jazyk)
VALUES ('xchlad16', 3);

INSERT INTO ModulVyuzivaProgJazyk
VALUES (2222, 2);
INSERT INTO ModulVyuzivaProgJazyk
VALUES (42, 1);

INSERT INTO TiketObsahujeBug (id_tiket, id_bug)
VALUES (5, 1);
INSERT INTO TiketObsahujeBug (id_tiket, id_bug)
VALUES (1, 2);

INSERT INTO BugVModule (id_bug, id_modul)
VALUES (1, 2222);
INSERT INTO BugVModule (id_bug, id_modul)
VALUES (2, 42);

/************************ COMMITNUTIE ZMIEN V DATABAZE ************************/
COMMIT;

/**************************** VYBER DAT Z TABULIEK ****************************/
/*SELECT * FROM Programator;
SELECT * FROM Uzivatel;
SELECT * FROM Tiket;
SELECT * FROM Bug;
SELECT * FROM Patch;
SELECT * FROM Modul;
SELECT * FROM ProgJazyk;

SELECT * FROM ProgramatorOvladaProgJazyk;
SELECT * FROM UzivatelOvladaProgJazyk;
SELECT * FROM TiketObsahujeBug;
SELECT * FROM BugVModule;
SELECT * FROM ModulVyuzivaProgJazyk;*/

--------------------------------------------------------------------------------
--                           Projekt (Cast 3)                                 --
--------------------------------------------------------------------------------
/* 1. dotaz vyuzivajuci spojenie 2 tabuliek */
-- Popis: Dotaz vyhlada patche, ktore vytvorili uzivatelia vo veku od 20 do 30 rokov
SELECT
  P.id_patch, P.predmet, P.datum_schvalenia, P.datum_vytvorenia, P.datum_zavedenia
FROM
  Patch P NATURAL JOIN Uzivatel U
WHERE
  U.vek BETWEEN 20 AND 30;

/* 2. dotaz vyuzivajuci spojenie 2 tabuliek */
-- Popis: Dotaz zobrazi vsetky predmety ticketov, ktore su pripradene nejakemu
--        programatorovi a zobrazi meno daneho programatora
SELECT
  T.tiket_predmet, P.meno || ' ' || P.priezvisko AS cele_meno
FROM
  Programator P NATURAL JOIN Tiket T
WHERE
  T.stav='Priradený';

/* Dotaz vyuzivajuci spojenie 3 tabuliek */
-- Popis: Dotaz vyhlad tikety, ktore obsahuju bugy s malym rizikom zneuzitia
SELECT DISTINCT
  id_tiket, tiket_predmet, stav
FROM
  Tiket NATURAL JOIN TiketObsahujeBug NATURAL JOIN Bug
WHERE
  riziko_zneuzitia = 'Malé';

/* 1. dotaz s klauzulou GROUP BY a agregacnou funkciou */
-- Popis: Dotaz vyhlada vsetkych programatorov, ktori zaviedli daky Patch
--        a vypise pocet vytvorenych patchov u kazdeho programatora
SELECT
  PR.prog_login, PR.meno || ' ' || PR.priezvisko AS cele_meno, count(id_patch) AS pocet_zavedenych_patchov
FROM
  Programator PR JOIN Patch PA ON PR.prog_login = PA.prog_zaviedol
GROUP BY
  PR.prog_login, PR.meno, PR.priezvisko;

/* 2. dotaz s klauzulou GROUP BY a agregacnou funkciou */
-- Popis: Dotaz zobrazi vsetky programovacie jazyky a pocet programatorov
--        ktori dany jazyk ovladaju
SELECT
  J.nazov, count(P.id_jazyk) AS pocet_programatorov_ovladajucich_jazyk
FROM
  ProgJazyk J LEFT JOIN ProgramatorOvladaProgJazyk P ON J.id_jazyk = P.id_jazyk
GROUP BY J.nazov;

/* Dotaz obsahujuci predikat EXISTS */
-- Popis: Dotaz vyhlada uzivatelov, ktori zatial nepodali ziadny tiket
SELECT DISTINCT
  U.uzivatel_login, U.meno, U.priezvisko
FROM
  Tiket T RIGHT JOIN Uzivatel U ON T.uzivatel_login = U.uzivatel_login
WHERE NOT EXISTS (
    SELECT
      uzivatel_login
    FROM
      Tiket
    WHERE U.uzivatel_login = T.uzivatel_login
);

/* Dotaz s predikatom IN s vnorenym selectom */
-- Popis --
-- Dotaz vyhlada programovacie jazyky, ktore ovladaju s pomedzi programatorov iba senior programatori.
SELECT
  id_jazyk, nazov
FROM
  ProgJazyk
  NATURAL JOIN ProgramatorOvladaProgJazyk
  NATURAL JOIN ProgJazyk
WHERE
  id_jazyk NOT IN (
    SELECT
      id_jazyk
    FROM
      Programator NATURAL JOIN ProgramatorOvladaProgJazyk NATURAL JOIN ProgJazyk
    WHERE junior_hodnost IS NOT NULL
  );

/******************************** BONUS SELECTS *******************************/
/* Dotaz spajajuci 5 tabuliek */
-- Popis --
-- Dotaz vyhlada bugy, ktore budu musiet byt opravene v programovacom jazyku Python
SELECT
  id_bug, bug_predmet
FROM
  Bug
  NATURAL JOIN BugVModule
  NATURAL JOIN Modul
  NATURAL JOIN ModulVyuzivaProgJazyk
  JOIN ProgJazyk ON ModulVyuzivaProgJazyk.id_jazyk = ProgJazyk.id_jazyk
WHERE ProgJazyk.nazov = 'Python';


-- Popis --
-- Dotaz vyhlada programatorov, ktori zaviedli patch vytvoreny uzivatelom
-- xchlad16 v den 16.06.2018.
SELECT PR.prog_login, PR.meno, PR.priezvisko
FROM
  Programator PR
  JOIN Patch PA ON PR.prog_login = PA.prog_zaviedol
  JOIN Uzivatel U ON U.uzivatel_login = PA.uzivatel_login
WHERE
  U.uzivatel_login = 'xchlad16'
  AND TO_CHAR(PA.datum_vytvorenia, 'yyyy-mm-dd') = '2018-06-16'
ORDER BY
  PR.priezvisko;

-- Popis --
-- Dotaz vyhlada uzivatelov, ktori ovladaju viac ako 1 programovaci jazyk
-- a zaroven vypise kolko programovacich jazykov ovlada.
SELECT uzivatel_login, meno, priezvisko, count(id_jazyk) AS pocet_jazykov
FROM
  Uzivatel
  NATURAL JOIN UzivatelOvladaProgJazyk
  NATURAL JOIN ProgJazyk
GROUP BY uzivatel_login, meno, priezvisko
HAVING count(id_jazyk) > 1
ORDER BY count(id_jazyk) DESC;

-- Popis --
-- Dotaz vyhlada programatorov, ktori neovladaju viac ako 1 programovaci jazyk
-- a zaroven vypise aky programovaci jazyk ovladaju.
SELECT prog_login, meno, priezvisko, nazov
FROM
  Programator
  NATURAL JOIN ProgramatorOvladaProgJazyk
  NATURAL JOIN ProgJazyk
WHERE prog_login IN (
  SELECT prog_login
  FROM
    Programator
    NATURAL JOIN ProgramatorOvladaProgJazyk
    NATURAL JOIN ProgJazyk
  GROUP BY prog_login
  HAVING count(id_jazyk) < 2
)
ORDER BY priezvisko;

-- Popis --
-- Dotaz vyhlada pocet zavedenych patchov v jednotlivych moduloch cez jednotlive dni v lete 2018,
-- tj. od 01.06.2018 do 31.08.2018.
SELECT
  P.datum_zavedenia, M.id_modul, M.nazov, count(M.id_modul) AS pocet_patchov
FROM
  Patch P
  JOIN Bug B ON P.id_patch = B.rieseny_patchom
  JOIN BugVModule BVM ON B.id_bug = BVM.id_bug
  JOIN Modul M ON BVM.id_modul = M.id_modul
WHERE
  TO_CHAR(P.datum_zavedenia, 'yyyy-mm-dd') BETWEEN '2018-06-01' AND '2018-08-31'
GROUP BY
  P.datum_zavedenia, M.id_modul, M.nazov
ORDER BY
  P.datum_zavedenia;

-- Popis --
-- Dotaz vyhlada programatorov + programovacie jazyky, ktori ovladaju vsetky druhy programovacich jazykov
-- ako Tomas Mojzis a aj tych, ktori ovladaju jazyky naviac.
SELECT
  P.prog_login, P.meno || ' ' || P.priezvisko AS cele_meno, PJ.nazov AS nazov_prog_jazyka
FROM
  Programator P
  LEFT JOIN ProgramatorOvladaProgJazyk POPJ ON P.prog_login = POPJ.prog_login
  JOIN ProgJazyk PJ ON POPJ.id_jazyk = PJ.id_jazyk
WHERE
  P.prog_login != 'xmojzi08'
  AND NOT EXISTS (
    SELECT
      PJ1.id_jazyk
    FROM
      Programator P1
      LEFT JOIN ProgramatorOvladaProgJazyk POPJ1 ON P1.prog_login = POPJ1.prog_login
      JOIN ProgJazyk PJ1 ON POPJ1.id_jazyk = PJ1.id_jazyk
    WHERE
      P1.prog_login = 'xmojzi08'
    MINUS
    SELECT
      PJ2.id_jazyk
    FROM
      Programator P2
      LEFT JOIN ProgramatorOvladaProgJazyk POPJ2 ON P2.prog_login = POPJ2.prog_login
      JOIN ProgJazyk PJ2 ON POPJ2.id_jazyk = PJ2.id_jazyk
    WHERE
      P2.prog_login = P.prog_login
  )
ORDER BY P.priezvisko;

--------------------------------------------------------------------------------
--                              Projekt (cast 4)                              --
--------------------------------------------------------------------------------
/********************************** TRIGGERY **********************************/
-- Definovane pred vkladanim hodnot do tabuliek

/********************************* PROCEDURY **********************************/
-- Procedura 1 --
-- Popis: Procedura vypise percentualne zastupenie patchov vytvorenych od uzivatelov,
-- senior programatorov a junior programatorov
CREATE OR REPLACE PROCEDURE PatchStatistiky AS
  pocet_patchov NUMBER;
  pocet_patchov_uzivatelov NUMBER;
  pocet_patchov_senior_programatorov NUMBER;
  pocet_patchov_junior_programatorov NUMBER;

  CURSOR PocetPatchov IS
    SELECT COUNT(*)
    FROM Patch;

  Cursor PocetPatchovSeniorProgramatorov IS
    SELECT COUNT(*)
    FROM Patch JOIN Programator ON prog_tvorca = prog_login
    WHERE junior_hodnost IS NULL;

  Cursor PocetPatchovJuniorProgramatorov IS
    SELECT COUNT(*)
    FROM Patch JOIN Programator ON prog_tvorca = prog_login
    WHERE pocet_juniorov IS NULL;

  Cursor PocetPatchovUzivatelov IS
    SELECT COUNT(*)
    FROM Patch NATURAL JOIN Uzivatel;

BEGIN
  OPEN PocetPatchov;
  OPEN PocetPatchovSeniorProgramatorov;
  OPEN PocetPatchovJuniorProgramatorov;
  OPEN PocetPatchovUzivatelov;
  FETCH PocetPatchov INTO pocet_patchov;
  FETCH PocetPatchovSeniorProgramatorov INTO pocet_patchov_senior_programatorov;
  FETCH PocetPatchovJuniorProgramatorov INTO pocet_patchov_junior_programatorov;
  FETCH PocetPatchovUzivatelov INTO pocet_patchov_uzivatelov;

  DBMS_OUTPUT.PUT_LINE('Patche vytvorene senior programatormi: '
    || pocet_patchov_senior_programatorov / pocet_patchov * 100
    || '%');
  DBMS_OUTPUT.PUT_LINE('Patche vytvorene junior programatormi: '
    || pocet_patchov_junior_programatorov / pocet_patchov * 100
    || '%');
  DBMS_OUTPUT.PUT_LINE('Patche vytvorene uzivatelmi: '
    || pocet_patchov_uzivatelov / pocet_patchov * 100
    || '%');

  CLOSE PocetPatchov;
  CLOSE PocetPatchovSeniorProgramatorov;
  CLOSE PocetPatchovJuniorProgramatorov;
  CLOSE PocetPatchovUzivatelov;
EXCEPTION
  WHEN ZERO_DIVIDE
    THEN DBMS_OUTPUT.PUT_LINE('Do tejto chvile neboli vytvorene ziadne patche!');
END;
/

EXEC PatchStatistiky();

-- Procedura 2 --
-- Popis: Vypíše predmet všetkých bugov, ktoré majú nastavené riziko zneužitia postupne od Malého rizika po Veľké.
-- Ak v danej kategórii žiadny bug nie je, vypíše sa o tom hláška.
CREATE OR REPLACE PROCEDURE BugySoZavaznostou AS
  bug_id Bug.id_bug%TYPE;
  bug_riziko Bug.riziko_zneuzitia%TYPE;
  bug_predmet Bug.bug_predmet%TYPE;
  output NVARCHAR2(300);
  riziko VARCHAR(50);
  count_of NUMBER;
  nenajdene NVARCHAR2(50);

  CURSOR bug_data IS SELECT Bug.id_bug, Bug.riziko_zneuzitia, Bug.bug_predmet FROM Bug
                      WHERE Bug.riziko_zneuzitia IS NOT NULL
                      ORDER BY Bug.riziko_zneuzitia;
  CURSOR patch_data IS SELECT Patch.uzivatel_login FROM Patch;
BEGIN
  nenajdene :='   Žiadne bugy s touto závažnosťou.';
  count_of := 0;
  FOR i IN 1..3 LOOP
    IF i = 1 THEN
      riziko := 'Malé';
    ELSIF i = 2 THEN
      riziko := 'Stredné';
    ELSIF i = 3 THEN
      riziko := 'Veľké';
    END IF;

    OPEN bug_data;
    OPEN patch_data;
    DBMS_OUTPUT.PUT_LINE(riziko || ' riziko: ');
    output := '';
    count_of := 0;
    LOOP
      FETCH bug_data INTO bug_id, bug_riziko, bug_predmet;
      EXIT WHEN bug_data%NOTFOUND;

      IF (bug_riziko LIKE riziko) THEN
            count_of := count_of + 1;
            output := output || '   ' || bug_predmet || chr(13);
      END IF;
    END LOOP;
    CLOSE bug_data;
    CLOSE patch_data;
    IF count_of > 0 THEN
      DBMS_OUTPUT.PUT_LINE(output);
    ELSE
      DBMS_OUTPUT.PUT_LINE(nenajdene);
    END IF;

  END LOOP ;
END;
/

EXEC BugySoZavaznostou();

/******************************** EXPLAIN PLAIN *******************************/
-- EXPLAIN PLAIN --
-- Popis --
-- Dotaz vyhlada uzivatelov, ktori ovladaju viac ako 1 programovaci jazyk
-- a zaroven vypise kolko programovacich jazykov ovlada.
EXPLAIN PLAN FOR
SELECT uzivatel_login, meno, priezvisko, count(id_jazyk) AS pocet_jazykov
FROM
  Uzivatel
  NATURAL JOIN UzivatelOvladaProgJazyk
  NATURAL JOIN ProgJazyk
GROUP BY uzivatel_login, meno, priezvisko
HAVING count(id_jazyk) > 1
ORDER BY count(id_jazyk) DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/************************************ INDEX ***********************************/
CREATE INDEX test_index ON Uzivatel(uzivatel_login, meno, priezvisko);

-- EXPLAIN PLAIN --
EXPLAIN PLAN FOR
SELECT uzivatel_login, meno, priezvisko, count(id_jazyk) AS pocet_jazykov
FROM
  Uzivatel
  NATURAL JOIN UzivatelOvladaProgJazyk
  NATURAL JOIN ProgJazyk
GROUP BY uzivatel_login, meno, priezvisko
HAVING count(id_jazyk) > 1
ORDER BY count(id_jazyk) DESC;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

DROP INDEX test_index;

/****************************** PRISTUPOVE PRAVA ******************************/
-- Pristupove prava (xmojzi08) --
GRANT ALL ON Programator TO xmojzi08;
GRANT ALL ON Uzivatel TO xmojzi08 ;
GRANT ALL ON Tiket TO xmojzi08;
GRANT ALL ON Bug TO xmojzi08;
GRANT ALL ON Patch TO xmojzi08;
GRANT ALL ON Modul TO xmojzi08;
GRANT ALL ON ProgJazyk TO xmojzi08;
GRANT ALL ON ProgramatorOvladaProgJazyk TO xmojzi08;
GRANT ALL ON UzivatelOvladaProgJazyk TO xmojzi08;
GRANT ALL ON TiketObsahujeBug TO xmojzi08;
GRANT ALL ON BugVModule TO xmojzi08;
GRANT ALL ON ModulVyuzivaProgJazyk TO xmojzi08;

GRANT EXECUTE ON PatchStatistiky TO xmojzi08;
GRANT EXECUTE ON BugySoZavaznostou TO xmojzi08;

-- Pristupove prava (xkruty00) --
GRANT ALL ON Programator TO xkruty00;
GRANT ALL ON Uzivatel TO xkruty00 ;
GRANT ALL ON Tiket TO xkruty00;
GRANT ALL ON Bug TO xkruty00;
GRANT ALL ON Patch TO xkruty00;
GRANT ALL ON Modul TO xkruty00;
GRANT ALL ON ProgJazyk TO xkruty00;
GRANT ALL ON ProgramatorOvladaProgJazyk TO xkruty00;
GRANT ALL ON UzivatelOvladaProgJazyk TO xkruty00;
GRANT ALL ON TiketObsahujeBug TO xkruty00;
GRANT ALL ON BugVModule TO xkruty00;
GRANT ALL ON ModulVyuzivaProgJazyk TO xkruty00;


GRANT EXECUTE ON PatchStatistiky TO xkruty00;
GRANT EXECUTE ON BugySoZavaznostou TO xkruty00;


/************************** MATERIALIZOVANE POHLADY ***************************/
-- Vytvořen alespoň jeden materializovaný pohled patřící druhému členu týmu
-- a používající tabulky definované prvním členem týmu (nutno mít již definována
-- přístupová práva), vč. SQL příkazů/dotazů ukazujících, jak materializovaný
-- pohled funguje.

DROP VIEW pohlad_zavazne_bugy;
DROP MATERIALIZED VIEW pohlad_zavazne_bugy_materialized;

-- Normnalny pohlad pre porovnanie
CREATE VIEW pohlad_zavazne_bugy AS
  SELECT * FROM XMOJZI08.BUG
  WHERE BUG.ZAVAZNOST0_10 > 4;


-- Materializovany pohlad
CREATE MATERIALIZED VIEW pohlad_zavazne_bugy_materialized AS
  SELECT * FROM XMOJZI08.BUG
  WHERE BUG.ZAVAZNOST0_10 > 4;

-- Pridanie novej polozky
INSERT INTO Bug (id_bug, bug_predmet, zavaznost0_10, zranitelnost, riziko_zneuzitia, rieseny_patchom)
VALUES (6, 'Program vypisuje chybu pri vyhľadávaní bugu.', 5, 0, NULL, NULL);

SELECT * FROM pohlad_zavazne_bugy; -- Normalny pohlad -> obsahuje novu polozku
SELECT * FROM pohlad_zavazne_bugy_materialized; -- Materializovany pohlad -> novu polozku neobsahuje

/* EOF */
