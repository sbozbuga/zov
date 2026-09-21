*&---------------------------------------------------------------------*
*& Report  /CELLAG/ORDERVIEW
*&
*&---------------------------------------------------------------------*
*&
*& 14.08.2012 CAGGERWAS Bearbeiten mehrerer Zeilen beim Kommando 'YMOD'
*&            'Kommentare bearbeiten'  - deaktiviert Herm 26.01.2013
*&                                       da nicht getestet / unfertig
*& 26.01.2014 Herm, B. Korrektur Fehler Kommentare
*&---------------------------------------------------------------------*
*& 11.07.2013 Herm, B. Ergänzung Feld QMART, Selektion
*&---------------------------------------------------------------------*
*& 26.10.2013 Herm, B. Ergänzung Feld QMART, Selektion
*&---------------------------------------------------------------------*
*& 12.12.2013 Herm, B. Selektion nach PSP-Element
*&---------------------------------------------------------------------*
*& 04.02.2014 Koch, M. Selektion nach Wertkontraktnummer
*&---------------------------------------------------------------------*
*& 04.02.2014 Herm, neues Gesamtfeld QMNUMPOSCNT
*&---------------------------------------------------------------------*
*& HERMB 06.05.2014  VTTK-TKNUM, VTTK-EXTI1 und QMFE-USR08.
*                    USR08 auch als Suchkriterium
*&---------------------------------------------------------------------*
*& HERMB 29.05.2014  Doppelklick auf Z2 Meldung: IW53
*                    Doppelklick auf Vendorlieferung: VL03N
*&---------------------------------------------------------------------*
*& HERMB 14.07.2014 1407-421 Selektion Orderview Auftragssolltermin falsch
*&---------------------------------------------------------------------*
*& HERMB 18.01.2015 1501-354 Problem in Orderview - Kommentare falsch zugeordnet
*                   Betraff nur OC Ordercontrol ZROC01, falls mehr als
*                   eine Position Z2 Kommentar
*&---------------------------------------------------------------------*
*& HERMB 16.07.2015 1507-363 Orderview Selektion nach PartIn und Vendor
*&---------------------------------------------------------------------*
*& HERMB 19.01.2016 1601-505 Fehler  OrderviewSelektion auf Datum Versand zum Vendor
*&---------------------------------------------------------------------*
*& HERMB 23.01.2016 1601-632 Sortierung beibehalten bei Angabe QMELPOS
*                   komplett neue Routinen
*                   Neues persistentes Feld QMELPOS; nicht mehr bestimmen
*----------------------------------------------------------------------*
*  HERMB 03.04.2016 1603-579 Kommentare nicht angezeigt bei Sel QMELPOS
*----------------------------------------------------------------------*
*  HERMB 05.06.2016 1603-579 1605-008 Kommentierung  Zeilen doppelt
*----------------------------------------------------------------------*
*  MKoch 28.11.2016 1610-730 Fakturastatus in Selektion
*----------------------------------------------------------------------*
*  HERMB 21.12.2016 1612-488 Unschärfe  Selektion über Meldungsnummer in Orderview
*----------------------------------------------------------------------*
*  HERMB 05.02.2017 1702-094 Fehler bei Selektion über Auftragsanlagedatum
*----------------------------------------------------------------------*
*  HERMB 18.04.2018 1804-433 Unschärfen in Orderview PA1 bei „Menge > 1“ und „Vereinzelung
*        23.04.2018          Sortierung beibehalten, keine Doppelten anzeigen
*----------------------------------------------------------------------*
*  HERMB 03.10.2018 1809-651 Anpassung Selektionsfeld purchase order proforma Inv
*----------------------------------------------------------------------*
*  HERMB 07.03.2019 1809-651 1903-127 Orderview Erweiterung Selektionsfeld FASTART
*----------------------------------------------------------------------*
*  HERMB 25.10.2019 1909-676  Erweiterung Orderview mit dem Feld "MDS" als Selektionsfeld
*----------------------------------------------------------------------*
*  MKoch 25.06.2020 2006-649  Statistik: Daten kleiner 01.01.2018 selektiert
*----------------------------------------------------------------------*
*  KKullmann 09.04.2021 2104-012  Highlighten von Indexfeldern im Selektionsbild
*----------------------------------------------------------------------*
*  HERMB 07.10.2021 2110-152 Orderview New Design Archivtabelle
*                            optionaler Zugriff auf die Archivtabellen
*                            Doku s.a. report ZORDVIEW_ARCHIV
*        26.10.2021          BeroBj Z_ORDVIEWA = Zugriff auf ZORDVIEW_ARCHIV Daten
*        31.01.2022          keine Dubletten anzeigen
*----------------------------------------------------------------------*
*  HERMB 23.05.2022 2205-235 Infotext zur Checkbox Zugriff auf Archiv
*----------------------------------------------------------------------*
*  HERMB 12.10.2023 2309-768 Orderview Splitt Werk 1620 falls Aufruf aus
*                   Transaktion ZORDERVIEW_FR1
*----------------------------------------------------------------------*
*  HERMB 02.11.2023 2309-867 Kommentare auf Meldungsposebene Z1
*----------------------------------------------------------------------*
*  HERMB 04.03.2024 2404-151 Kommentierung Orderview  Kundengruppe 0CD ( CTDI UK )
*                   bei vorhandenem /CELLAG/ORD_ADD Eintrag keine Z2-Meldung
*                   anlegbar
*----------------------------------------------------------------------*
*  HERMB 10.04.2024 2404-218 Abbruch in Orderview - archivierte Meldung
*=====================================================================
REPORT  /cellag/orderview NO STANDARD PAGE HEADING LINE-SIZE 200
MESSAGE-ID /cellag/messages_sd.

INCLUDE /cellag/orderview_top.
INCLUDE /cellag/orderview_sel.
INCLUDE /cellag/orderview_eve.
INCLUDE /cellag/orderview_sub.
INCLUDE /cellag/orderview_mod.

INCLUDE /cellag/orderview_f02.