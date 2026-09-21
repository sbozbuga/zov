*&---------------------------------------------------------------------*
*& Report  /CELLAG/ORDER_DATA_FETCH
*&
*&---------------------------------------------------------------------*
*& HERMB 19.10.2013 Ermittlung Rechnungsdaten
*&---------------------------------------------------------------------*
*& HERMB 02.02.2013 Lagerort/Werk Auslieferung, zuächst aus Kuauftrag
*&                  Nach Belieferung aus Lieferposition
*&---------------------------------------------------------------------*
*& HERMB 17.02.2013 Korrektur: FAUF nicht gefunden, gelesen aus VBEP
*&  2. Lagerort/Werk Auslieferung bei Tauschvorgängen aus Pos mit Typ
*&     ZDNS (=VKGRU 106) nehmen lt. Marius Zaharia
*      (bei S4D bisher noch nicht definiert)
*&---------------------------------------------------------------------*
*& HERMB 10.06.2013 WKTNR befüllt; WKTPS hinzugefügt (-> F. Schmidt)
*&   HB100613       wegen Überholer dynamische Sortierung repdau-Tabelle
*&   Rückbau auch in FORM build_calculated_fields.
*&---------------------------------------------------------------------*
*& HERMB 11.06.2013 FORM build_calculated_fields; passend für beide Strukturen
*&---------------------------------------------------------------------*
*& HERMB 27.06.2013 REPDAU: Korrektur für Ermittlung Daten mit Kontrakt
*                   Kontraktnummer direkt aus orderview-Liste nehmen
*&---------------------------------------------------------------------*
*& HERMB 08.07.2013 Meldungsart ZX  Intercompany
*        11.07.2013 Feld QMART ergänzt
*&---------------------------------------------------------------------*
*& HERMB 04.08.2013 1307-977 Vendorbestellung fehlt  HB040813
*&---------------------------------------------------------------------*
*& HERMB 26.10.2013 Erweiterung um Partnerrolle ZB/TElekom  HB261013
*&---------------------------------------------------------------------*
*& HERMB 30.10.2013 Korrektur wegen Kundengruppe WE
*&                  Hohe Fehleranfälligkeit durch fehlende Kapselung
*&                  und arbeiten mit globalen Daten!!!
*&---------------------------------------------------------------------*
*& HERMB 19.11.2013 Versorgen der 3 Felder RESSORT, EXTKOSTLE, KDSACHBE
*&---------------------------------------------------------------------*
*& HERMB 10.12.2013 1. TRACKDATE aus VTRKH-TRACKSTMP
*                   2. PS_PSP_PNR statt Eigentum
*                   3. TRACKNVEND und TRACKDATEVEND
*&---------------------------------------------------------------------*
*& HERMB 12.12.2013  1312-167  Abgesagte Retourenpositionen
*&---------------------------------------------------------------------*
*& HERMB 28.01.2014  1401-872  Serialnummer und Lieferung bei Vereinz.
*                    gesonderte Implementierung für diesen Sonderfall
*                    Einige Zeitstempel eingebaut
*&---------------------------------------------------------------------*
*& HERMB 14.02.2014  1401-973 Orderview Kundenmatnr aus KMI
*                    Auftraggeber als Selektionskrit
*&---------------------------------------------------------------------*
*& HERMB 23.02.2014  1401-872 Vereinzelung Felder Lieferscheindruck,
*                    Paketdienst, Trackingnummer und RepDauer
*&---------------------------------------------------------------------*
*& HERMB 26.02.2014  QMFE_USR05 in QMFE_USR02 und QMFE_USR06 in QMFE_USR03
*                    umbenannt (Quellfelder sind qmfe-usr02 / qmfe-usr03
*&---------------------------------------------------------------------*
*& HERMB 21.03.2014  1403-605 Fehlertexte in Orderview fehlen
*                    Texte jetzt in Textsprache lesen (KZMLA der Z2-Meldung)
*                    'ZFL'.  "reiner Vorwärtslogistikprozess Status CLOSED
*&---------------------------------------------------------------------*
*& HERMB 26.03.2014  Archivkennzeichen setzen + Steuertabelle mit Kontrakt
*        26.03.2014  Geänderte Def. für CLOSED: Scrap ä Labelprint + AKZ A
*&---------------------------------------------------------------------*
*& NTA   01.04.2014  Bei Modify table DB-Buffer = Itab-Buffer verwenden
*&---------------------------------------------------------------------*
*& HERMB 02.04.2014  Neue Update-Form wegen Abbruch Produktivproblem
*&---------------------------------------------------------------------*
*& HERMB 07.04.2015  Korr Selektion ZX; Anzahl Selektiert
*                    Fehlerbehandlung Datenbankverbuchung
*&---------------------------------------------------------------------*
*& HERMB 13.04.2015  Kurzdump wegen Arithmetic Overflow bei TAT
*                    Abfangen mit CATCH (auch Overdue)
*&---------------------------------------------------------------------*
*& HERMB 06.05.2015  VTTK-TKNUM, VTTK-EXTI1 und QMFE-USR08.
*                    USR08 auch als Suchkriterium
*&---------------------------------------------------------------------*
*& HERMB 17.05.2015  1405-361 Matnr_in: SAP Material der Retourenanlieferung
*&---------------------------------------------------------------------*
*& HERMB 18.05.2015  1405-360  Orderview  neue Berech.g Auftragsende-Soll bei ZX
*                    1405-407 ZFL Berechnung Liefertermin Soll
*        19.05.2015  ZFL: Auftragsendesoll = Liefertermin Soll + Vereinz
*                    ZRL4L: Liefertermin soll = Receivedate
*&---------------------------------------------------------------------*
*& HERMB 20.05.2015  1405-359 Darstellung ZX-Details in der Zeile mit der Z1-Meldung
*&       21.05.2015  1405-583 Korr. Nebenwirkung bei ZX; keine RTA-Termin
*&----------------------------------------------------------------------
* modus aendern ohne Aenderung comment kann geloescht werden.
*----------------------------------------------------------------------*
*  HERMB 27.06.2014  1. 1406-545 Änderung Berechnung OVERDUE für ZX
*                       Falls AUFTRAGSENDESOLL nicht leer:
*                         Falls Closed: OVERDUE= DATECLOSED - AUFTRAGSENDESOLL
*                         Falls offen:  OVERDUE= Tagesdatum - AUFTRAGSENDESOLL
*                    2. 1406-377 Erweiterung Orderview - Route
*                       Wenn eine Lieferung existiert, dann aus der Lieferung ausgeben. (LIKP-ROUTE)
*                       Wenn keine Lieferung existieit, dann aus Kundenauftrag ausgeben (VBAP-ROUTE zur Hauptposition).
*----------------------------------------------------------------------*
*  HERMB 30.07.2014  1. 1407-592 Erweiterung ZX Felder
*                       ZX_REMARKSRS, ZX_REMARKSVM
*----------------------------------------------------------------------*
*  HERMB 03.08.2014 1408-037 Unterpositionen in Vendorbestellung
*                   Datum vendorrueck aus Wareneingang Unterpos
*----------------------------------------------------------------------*
*  HERMB 27.09.2014 1409-624 Optimierung Laufzeit
*                   Zugriff auf AFRU war Performance-Killer
*----------------------------------------------------------------------*
*  HERMB 30.09.2014 1409-664 Orderview Erweiterung Codegruppe ZIL
*                   PERFORM get_retoure_zil
*                   Versorgen Felder Retoure, Dockdate, RECEIVEDATE
*----------------------------------------------------------------------*
*  HERMB 03.10.2014 1409-664 Orderview Codegruppe ZIL Closed
*----------------------------------------------------------------------*
*  HERMB 14.10.2014 1410-401 Lagerort für ZFL iwird nicht ausgegeben
*----------------------------------------------------------------------*
*  HERMB 18.11.2014 1411-480 Status Deleted in orderview: wird überschrieben
*----------------------------------------------------------------------*
*  HERMB 11.12.2014 1412-121 Anpassung Orderview SERIALREC
*----------------------------------------------------------------------*
*  HERMB 13.12.2014 1412-056 ZFL und Lieferterminsoll INITCOMMITDATE
*        14.12.2014 16:00 korrigiert - Abfrage >= 160000
*        16.12.2014 Aktionen in eigene Form am Schluss speziell ZFL
*-----------------------------------------------------------------------*
*  HERMB 09.01.2015 ZFL Archivkennzeichen nicht gesetzt
*-----------------------------------------------------------------------*
*  HERMB 17.01.2015 1501-223 Unschärfe in Orderview - Faktura bei Vereinzelung
*        18.01.2014 Ergänzung für ZFL Menge 1
*        19.01.2014 Archivstatus für ZFL mit Faktura
*-----------------------------------------------------------------------*
*  HERMB 26.01.2015 Vereinzelung Performance-Optimierung bei einz. Meldungen
*-----------------------------------------------------------------------*
*  HERMB 09.02.2015 1502-085 Erweiterung Orderview - weitere Merkmale aus KMI Daten
*-----------------------------------------------------------------------*
*  HERMB 05.06.2015 1502-085 1506-132 Erweiterung Orderview - Ablieferdatum
*-----------------------------------------------------------------------*
*  HERMB 29.06.2015 1506-781 Orderview PA1 CutOff Zeit
*                   Lesen aus Customizing ZORDVIEW_CUTOFFT (SM30)
*-----------------------------------------------------------------------*
*  HERMB 26.07.2015 1507-744 Erw Orderview mehrere Aufträge pro Meldung
*                   Lesen der Zeilen ohne Auftragsnummer
*                   fehlende Auftragsnummer
*                   vor Weiterverarbeitung in gt_qmfe eintragen
*                   Zwischenspeicherung der Sätze ohne Auftragsnummer in
*                   Tablle ZTORDVIEW_ORD_MI
*        28.07.2015 Auch neue Daten Problemfälle erkennen: Meldungen mit
*                   mehr als eine unterschiedl. OTGRP; immer die Daten
*                   ab Vortag prüfen.
*-----------------------------------------------------------------------*
*  HERMB 17.09.2015 1509-398 Anpassung Orderview auf PA1 Closed-Def
*                   Prüfung auf nicht abgesagte Lieferpositionen
*        19.08.2015 1506-781 Cutoff-Zeit bei ZFL
*-----------------------------------------------------------------------*
*  HERMB 18.12.2015 1510-320 Fakturastatus "C" nicht erkannt Orderview
*-----------------------------------------------------------------------*
*  HERMB 23.12.2015 1511-375  Erweiterung Orderview Einlagerung
*        02.01.2016 auch nicht quittierte TA anzeigen
*        07.02.2016 Closed setzen
*-----------------------------------------------------------------------*
*  HERMB 19.01.2016 1601-360  Orderview auf PA1 Feld Price
*-----------------------------------------------------------------------*
*  HERMB 23.01.2016 1601-632 Neue Felder QMEL-BSTNK. Meldpos
*-----------------------------------------------------------------------*
*  HERMB 06.02.2016 1601-819 Orderview Anlagedatum Vendorlieferung
*-----------------------------------------------------------------------*
*  HERMB 16.04.2016 1604-216  Anpassung Orderview mehrere Vendorbestellungen
*-----------------------------------------------------------------------*
*  HERMB 27.04.2016 1604-706 Erweiterung Orderview neuer Tauschprozess ZRREF
*                   Neuer Hauptpositionstyp im Sales Order ZADE  (wie ZADR)
*                   Neuer Lieferpositionstyp im Sales Order ZDND (wie  ZDNS)
*-----------------------------------------------------------------------*
*  HERMB 28.06.2016 1606-641 Anpassung Orderview Ablieferdatum nach ArchivKZ
*        02.07.2016          Vereinzelung: Ablieferdatum
*-----------------------------------------------------------------------*
*  HERMB 23.07.2016 1607-362 STRABAG - Orderview - Vereinzelung
*                   neues Feld SERNP Serialnrprofil: Quelle  MARC-SERNP
*                   ggf. alle Lesen mit SERNP > leer (falls mehr als 1000 MARA)
*                   nur Vereinzeln, wenn SERNP nicht leer
*-----------------------------------------------------------------------*
*  HERMB 22.08.2016 1607-759 Feld TRACKTIME in Orderview PA1
*        18.09.2016 1607-759 Feld TRACKTIME: Vereinzelung
*-----------------------------------------------------------------------*
*  HERMB 01.12.2016 1611-772 Orderview PA1 Archivkennzeichen
*                   Selektion erweitern + Zeitstempel
*  HERMB 03.12.2016 Protokoll ergänzt; Beschränkung weg: neue Daten lesen
*-----------------------------------------------------------------------*
*  HERMB 09.04.2017 1702-846  Bestellung ohne BANF Vendorlieferung Orderview
*                   analog YLE01; Vendorbestellungen kontiert auf Auftrag
*-----------------------------------------------------------------------*
*  HERMB 19.05.2017 1705-137 Matkost. in Orderview
*                   Ermittlung über MSEG; neues Feld befüllen
*-----------------------------------------------------------------------*
*  HERMB 20.05.2017 1705-321 Erweiterung Orderview neuer Tauschprozess = ZRREFRS
*                   Neuer Hauptpositionstyp im Sales Order ZARS  (wie ZADE)
*                   Neuer Lieferpositionstyp im Sales Order ZDND (wie  ZDNS)
*  HERMB 24.05.2017 1705-137 Matkost. in Orderview: lesen aus AUFM
*  HERMB 31.05.2017 1705-137 Matkost. in Orderview: MATPREIS2 weg
*-----------------------------------------------------------------------*
*  HERMB 09.06.2017 1706-096 Codegruppe ZIL bekommt kein Archivkennzeichen
*-----------------------------------------------------------------------*
*  HERMB 07.07.2017 1707-153 Anpassung "Datum Closed" Orderview PA1 bei Absage der  Retoure
*-----------------------------------------------------------------------*
*  HERMB 13.07.2017 1705-007 Anpassung Orderview wegen "Tag 1"
*                   Verwendung Methode ZCL_SCHEDULING=>GET_1_DAY_OFFSET
*                   mit Zugriff auf Cust ZORDVIEW_CUST2
*-----------------------------------------------------------------------*
*  HERMB 31.08.2017 1707-609 Anpassung Orderview FETCH Programm PA1
*                   EKPO-LOEKZ abfragen mit L  (Gesperrt = S)
*                   1708-755 Ermittlung der vereinnahmten Baugr bei ZIL
*-----------------------------------------------------------------------*
*  HERMB 20.10.2017 1710-456 Axa mit Unterpositionen in der Lieferung
*-----------------------------------------------------------------------*
*  HERMB 15.12.2017 1710-456_2 Orderview Serialnummern fehlen
*-----------------------------------------------------------------------*
*  HERMB 22.01.2018 1801-526 Orderview PA1 Ermittlung Werkstattauftragsnummer
*-----------------------------------------------------------------------*
*  HERMB 11.03.2018 1802-679 Anpassung Repdauer für Kundengruppe 0DN HB110318
*                   IF AKZ_NEU=WK/WM und AKZ_ALT <> GM
*                     Repdauer aktualisieren basierend auf den Wert AKZ_NEU
*                   ELSE
*                     Repdauer aktualisieren basierend auf den Wert AKZ_ALT
*                   Neues Feld AKZ_WE
*-----------------------------------------------------------------------*
*  HERMB 11.03.2018 1802-679 Anpassung Repdauer für Kundengruppe 0DN HB110318
*-----------------------------------------------------------------------*
*  HERMB 17.04.2018 1804-433 Unschärfen in Orderview PA1 bei „Menge > 1“ und „Vereinzelung
*        24.04.2018          Closed unsw bei ZFL
*-----------------------------------------------------------------------*
*  HERMB 01.05.2018 1804-541 Erweiterung Orderview PA1 Closed Ausnahmen Tabelle
*                   Tabelle ZORDVIEW_CLOS_EX Pflege über SM30
*                   Kennzeichnung in Feld CLOSED_EXCEPTION
*-----------------------------------------------------------------------*
*  HERMB 04.06.2018 1805-687 Neue Spalte Verantwortliche Kostenstelle
*                   Da nicht alle Aufträge versorgt werden, am Schluss
*                   nochmals Versorgung für Aufträge ohne Kostenstelle
*-----------------------------------------------------------------------*
*  HERMB 02.07.2018 1806-759 Unschärfe AKZ_WE in Orderview PA1
*                   Korrektur zu 1802-679 (?)
*-----------------------------------------------------------------------*
*  HERMB 14.07.2018 1807-332 Orderview Berechnungsmotiv ZMIR-Pos
*-----------------------------------------------------------------------*
*  HERMB 25.07.2018 1807-584 Orderview falsche Trackzeit
*-----------------------------------------------------------------------*
*  HERMB 21.08.2018 1808-376 Feld Servicekennzeichen in Orderview
*-----------------------------------------------------------------------*
*  HERMB 23.08.2018 1808-372 Unschärfe bei Trackingnummer Vendorlieferung
*-----------------------------------------------------------------------*
*  HERMB 23.09.2018 1808-360 Feld KUNDEWUNSCHTERM immer qmfe-usr18
*-----------------------------------------------------------------------*
*  HERMB 24.09.2018 1809-408 Anpassung Orderview PA1 Feld PRCTR (Profitcenter)
*                   PRCTR_UMSATZ
*-----------------------------------------------------------------------*
*  HERMB 03.10.2018 1809-642 Unschärfe Orderview PA1 Aussonderungsdatum
*-----------------------------------------------------------------------*
*  HERMB 08.10.2018 1809-408 Anpassung Orderview PA1 Feld PRCTR (Profitcenter)
*                   tw Wert aus MARC nehmen, falls OTGRP in Cust ZORDVIEW_PRCTR
*                   PRCTR_UMSATZ durchgängig aus VBAP-PRCTR
*-----------------------------------------------------------------------*
*  HERMB 17.10.2018 11810-280 Unschärfe Orderview Ablieferdatum (Vereinzelung)
*-----------------------------------------------------------------------*
*  HERMB 23.10.2018 1810-312 Unschärfe Orderview Feld FASTART wird geleert
*-----------------------------------------------------------------------*
*  HERMB 25.10.2018 1810-435 Anpassung Orderview Neuer Prozess Fast Good Parts
*                   Neues Feld FAST_GOOD_PARTS
*                   Retoure ermitteln
*                   Laberlprint = receivedate, falls FAST_GOOD_PARTS
*-----------------------------------------------------------------------*
*  HERMB 11.12.2018 1811-735 Neues Feld Workshop_rate
*                   Summe Persoanlkosten aus PMCO mit VORGA RKL
*                   RKL = CO Ist Leistungsverrechnung
*-----------------------------------------------------------------------*
*  HERMB 26.01.2019 1901-415 Unschärfe Orderview Fakturastatus
*-----------------------------------------------------------------------*
*  HERMB 22.02.2019  1902-579 Materialkosten in Orderview
*-----------------------------------------------------------------------*
*  HERMB 30.04.2019  1904-026 Orderdate leer
*-----------------------------------------------------------------------*
*  HERMB 14.06.2019  1811-059 Feld YYMDS: QMFE erweitert
*-----------------------------------------------------------------------*
*  HERMB 15.08.2019  1908-109 Orderview Befüllung der 3 ZX  Felder
*-----------------------------------------------------------------------*
*  HERMB 28.10.2019  1910-863 /CELLAG/ORDER_DATA_FETCH Abbruch wenn keine Daten
*-----------------------------------------------------------------------*
*  HERMB 13.01.2020  1910-863 2001-250 Orderview - Rechnunganzeige Inkorrekt bei Stornos
*-----------------------------------------------------------------------*
*  HERMB 05.04.2020  2003-1052 Feld PRICE in Orderview
*                    2004-299 Orderview Tabelle ZORDVIEW_CLOS_
*-----------------------------------------------------------------------*
*  HERMB 11.05.2020  2004-280 Anpassung Orderview - Gesamtwert aller Fakturen
*-----------------------------------------------------------------------*
*  HERMB 13.07.2020  2007-147 Orderview Performance
*-----------------------------------------------------------------------*
*  HERMB 28.07.2020  2007-580 Fakturastatus wird nicht angezeigt
*-----------------------------------------------------------------------*
*  HERMB 29.07.2020 2007-208 Positionstyp ZMIR in Orderview
*                   Korrektur JOIN Selektion Rechnungspositionen
*-----------------------------------------------------------------------*
*  HERMB 26.09.2020 2009-878  Orderview FETCH -Trackingnummer
*                   Sonderregel Deutsche Bahn, falls mehrere Träckingnr
*        30.09.2020 Performance wegen vttp
*-----------------------------------------------------------------------*
*  HERMB 20.10.2020 2008-278 Teil 2 Anpassung Programm /CELLAG/ORDER_DATA_FETCH
*                   GBSTK = C, falls alles abgesagt, dann Archivkz
*-----------------------------------------------------------------------*
*  HERMB 12.12.2020 2011-984 Erweiterung Orderview Fetch  Aktionstext ZRSP01
*-----------------------------------------------------------------------*
*  HERMB 06.01.2021 2101-084 Unschärfe in Orderview Archivkennzeichen Ablieferdatum
*-----------------------------------------------------------------------*
*  HERMB 15.02.2021 2102-363  Unschärfe in Orderview Rechnungsnummer
*-----------------------------------------------------------------------*
*  HERMB 16.03.2021 2103-465 Unschärfe in Orderview Archivkennzeichen
*-----------------------------------------------------------------------*
*  HERMB 22.04.2021 2104-627 Erweiterung Orderview QMFE-FETXT
*-----------------------------------------------------------------------*
*  HERMB 16.05.2021 2105-324 Unschärfe bei ZIL Meldungen Archivkz
*-----------------------------------------------------------------------*
*  HERMB 16.06.2021 2010-1008 ORDERVIEW New process type ZMTO_ZMT1
*-----------------------------------------------------------------------*
*  HERMB 07.10.2021 2110-152 Orderview New Design Archivtabelle
*                            optionaler Zugriff auf die Archivtabellen
*                            Doku s.a. report ZORDVIEW_ARCHIV
*  HERMB 15.12.2021 2110-152 Orderview Protokollierung Löschung
*  HERMB 22.12.2021 2110-152 Orderview Neue Daten lesen Selektion Muss
*  HERMB 29.12.2021 2110-152 Orderview Korrektur Selektion, falls keine
*                            neu angelegten Meldungen ermittelt
*  HERMB 27.01.2022 2110-152 Prüfung auf Archivierte Optional
*                            Berechtigung Option eingeschränkt NHS060015 und
*                            NHS050248
*-----------------------------------------------------------------------*
*  HERMB 04.02.2022 2202-137 Orderview FETCH abgesagte ZMIR Positionen
*                   2202-164 ORDERVIEW FETCH Vereinzelung Transp, ReadytoShip
*                            Korrektur, falls Auftragsmenge geändert! Counter löschen
*-----------------------------------------------------------------------*
*  HERMB 21.06.2022 2205-938 Orderview FETCH Retoure ZIL ohne Sernr
*-----------------------------------------------------------------------*
*  HERMB 17.07.2022 2205-938 Referenzdatum Umsetzung
*                            Start vor Mitternacht wird ermöglicht
*                            Normaluser max 100 Meldungen aktualisierbar
*-----------------------------------------------------------------------*
*  HERMB 14.10.2022 2203-936 GSI-Status - Änderung auf 1 möglich/mit Cust
*-----------------------------------------------------------------------*
*  HERMB 05.11.2022 2211-139 Performance Orderview FETCH (Zugriff EKKN)
*        09.11.2022          Zugriff vtrkh in get_trackdata_vendor
*        14.11.2022 2211-468 Zugriff vtrkh Ergänzung Typ 8 Transport
*-----------------------------------------------------------------------*
*  HERMB 10.05.2023 2305-354  Orderview Rückmeld ohne Bemot
*-----------------------------------------------------------------------*
*  HERMB 01.11.2023 2309-867 Kommentare auf Meldungsposebene Z1
*                            vorhandenen Langtext als eigenes Objekt mit
*                            Zeitstempel langtext betrachten
*                            bei Z2 zunächst in gt_qmma kurz und Langtext
*                            in einem Satz führen mit eigenen Zeitstempel für LTXT
*  HERMB 23.02.2024 2309-867 NOMAT-Kommentare Workaround direkt anlegen
*-----------------------------------------------------------------------*
*  HERMB 04.04.2024 2404-151 Kommentare GSI neu bauen
*-----------------------------------------------------------------------*
*  HERMB 09.04.2024 2404-170 Closed_exception ans Ende verlagert
*  HERMB 12.04.2024 2403-977 Vendorbestellung ermitteln LOEKZ = L
*-----------------------------------------------------------------------*
*  HERMB 07.05.2024 2405-180 RL Orderview Fetch Kommentare / am Ende
*        17.05.2024 2405-180 Korrekturen
*        06.06.2024 2406-072 Aktionen Kommentare LOEKZ
*-----------------------------------------------------------------------*
*  HERMB 17.01.2025 2501-751 RL Orderview Performance Zeitstempel und Opt
*-----------------------------------------------------------------------*
*  HERMB 10.03.2025 2501-751 RL Orderview Performance Zeitstempel und Opt
*-----------------------------------------------------------------------*
*  HERMB 17.07.2025 2507-721 Workaround: Serialnr in SD-Auftrag nicht korrekt
*                            Labelprint, SERNRAUFNR fehlen
*-----------------------------------------------------------------------*


REPORT  /cellag/order_fetch_new NO STANDARD PAGE HEADING LINE-SIZE 200
MESSAGE-ID /cellag/messages_sd.

INCLUDE /cellag/order_data_fetch_top.
INCLUDE /cellag/order_data_fetch_sel.
INCLUDE /cellag/order_data_fetch_eve.
INCLUDE /cellag/order_data_fetch_sub.
INCLUDE /cellag/order_data_fetch_mod.
INCLUDE /cellag/order_data_fetch_f01.

INCLUDE /cellag/order_data_fetch_f02.