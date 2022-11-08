local L = LibStub("AceLocale-3.0"):NewLocale("Accountant", "deDE", false)
if not L then return end
--ACCLOC_TITLE
L["Accountant"]	= "Buchhalter"

L["Net Profit / Loss"] = "Gewinn / Verlust"
L["Net Loss"] = "Verlust"
L["Net Profit"] = "Gewinn"
L["Source"] = "Quelle"
L["Revenue"] = "Einnahmen"
L["Expenditures"] = "Ausgaben"
L["Week Start"] = "Wochenstart"
L["Sum Total"] = "Gesamt Summe"
L["Character"] = "Charakter"
L["character"] = "Charakter"
L["Money"] = "Geld"
L["Updated"] = "Aktualisiert"
L["Alliance"] = "Allianz"
L["Horde"] = "Horde"

--ACCLOC_LOOT
L["Loot"] = "Beute"
L["Quest Rewards"] = "Quest Belohnungen"
L["Merchants"] = "Händler"
L["Trade Window"] = "Handelsfenster"
L["Mail"] = "Post"
L["Training Costs"] = "Trainingskosten"
L["Taxi Fares"] = "Flugpunkt"
L["Unknown"] = "Unbekannt"
L["Repair Costs"] = "Reparatur Kosten"
L["Auction House"] = "Auktions Haus"
L["Other System"] = "Anderes System"
L["Black Market"] = "Schwarz Markt"
L["Reforging"] = "Umschmiedung"
L["Azerite Reforging"] = "Azerit-Umschmiedung"
L["Transmogrify"] = "Transmogrifizieren"
L["Garrison / Class Hall"] = "Garnison / Klassenhalle"

-- Buttons
L["Clear Data"] = "Daten zurücksetzen"
L["Exit"] = "Schließen"


-- Tabs
L["Session"] = "Sitzung"
L["Day"] = "Tag"
L["Week"] = "Woche"
L["Total"] = "Gesamt"
L["All Chars"] = "Alle Chraktere"

--ACCLOC_STARTWEEK
L["Start of Week"] = "Wochenstart"
L["Sunday"] = "Sonntag"
L["Monday"] = "Montag"
L["Tuesday"] = "Dienstag"
L["Wednesday"] = "Mittwoch"
L["Thursday"] = "Donnerstag"
L["Friday"] = "Freitag"
L["Saturday"] = "Samstag"
L["complete"] = "Vollständig"

-- Misc
L["Are you sure you want to reset the"] = true
L["New Accountant profile created for"] = "Neues Buchhalter Profil erstellt für"
L["Loaded Accountant profile for"] = true
L["Loaded"] = "Geladen"
L["Right-Click"] = "Rechtsklick"
L["Left-Click"] = "Linksklick"
L["Remove"] = "Entfernen"
L["Merge"] = true
L["Toggle"] = "Umschalten"
L["Minimap"] = "Minikarte"
L["Button"] = "Knopf"

-- Mail strings
L["Auction successful:"] = "Auktion erfolgreich"
L["Outbid"] = "Überbieten"

-- Key Bindings headers
--BINDING_NAME_ACCOUNTANTTOG
L["Toggle Accountant"] = "Buchhalter umschalten"

-- Config strings
L["Minimap button"] = "Minikarten Knopf"
L["Accountant allows you to track where your gold is going."]	= true
L["Configure minimap button"]	= "Minikarten Knopf einstellen"
L["Display minimap button"]	= "Zeige Minikarten Knopf"
L["Display the minimap button"]	= "Zeige den Minikarten Knopf"
L["Transparancy"] = "Transparenz"
L["Change the transparancy of the accountant window"] = "Änder die Transparenz vom Buchhalter Fenster"
L["Change transparancy"] = "Transparenz ändern"
L["Change the day of the week that accountant uses. This resets the start of week totals."] = true
L["Week Day"] = "Wochentag"
L["Select the day of the week."] = "Wähle einen Tag der Woche"
L["Change to week day"]	= "Zum Wochentag wechseln"
L["Character Management"] = "Charakter verwaltung"
L["It is recommended that you save your accountant data before proceeding, just in case."] = true
L["Manage the Accountant data of your character(s)."] = true
L["Remove Character"] = true
L["Remove Accountant data for the selected character"] = true
L["You can not remove yourself!"] = "Du kannst dich nicht selbst entfernen!"
L["Remove of "] = true
L["Remove Accountant data for this character"] = true
L["This will remove the Accountant data for the selected character. You must exit the game or log into another character to save the changes."] = true
L["Ignore"] = "Ignorieren"
L["Ignore Accountant data for this character. Do not collect data."] = true
L["Merge Character"] = true
L["Character Merge"] = true
L["From:"] = "Von:"
L["To:"] = "Zu:"
L["to"] = "zu"
L["Can not merge a character to itself!!"] = true
L["Merge Accountant data from this character"] = true
L["Merge Accountant data to this .character"] = true
L[" "] = true
L["NOTE: If you merge Accountant data to the character you are logged into session data will be lost. You should also log into the character you want to merge from. Otherwise week data may not be correct (depending on when you last logged into that character)"] = true
L["Clear the Accountant data for all characters"] = true
L["Clear data for all realms"] = true

--New Strings by Dajn 8.0.1
L["Minimap Options"] = "Minikarten Optionen"
L["Remove Toon"] = true
L["Merge Toon"] = true

L["%sLeft-Click%s to open the main window"] = "%sLinksklick%s zum öffnen des Hauptfensters"
L["%sRight-Click%s to open the config window"] = "%sRechtsklick%s zum öffnen des Konfigurationsfensters"
L["%sDrag%s to move this button"] = "%sZiehen%s zum bewegen"
L["Accountant: Clear data complete"] = true
L["Tracks your revenues / expenditures"] = true
L["Accountant: You can not remove yourself!"] = "Buchhalter: Du kannst dich nicht selbst entfernen!"
L["Accountant: Remove of "] = true
L["Accountant: Can not merge a character to itself!!"] = true
L["Accountant: Merge Character of "] = true
L["Accountant: Change to week day "] = true
L["Display money on minimap button"] = "Zeige Geld auf Minikarten Knopf"
L["Displays the above selected net profit/loss on the minimap button"] = "Zeige den oben ausgewählten Gewinn /Verlust auf den Minikarten Knopf"
L["Select minimap mode"] = "Wähle Minikarten Modus"
L["Select what mode you want the minimap to show (NOTE: Only works if the botton below is checked)"] = "Wähle welche Daten du bei der Minikarte angezeigt werden sollen. (BEACHTE: Dies funktioniert nur, wenn der Knopf hier drunter aktiviert ist)"
L["Total Gold "] = true
L["Are you sure you want to reset the data? This can't be undone"] = true
L["Yes"] = "Ja"
L["No"] = "Nein"
L["Cancel"] = "Absagen"
