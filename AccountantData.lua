--[[
	AccountantData.lua

	Declare the global namespace, data, and constants
--]]

-- Reserve the naamespace
Accountant = {}
-- Saved by WoW so leave in global namespace
Accountant_SaveData = nil;

-- Create a short cut
local SC = Accountant

SC.Version = tostring(GetAddOnMetadata("Accountant", "Version")) or "Unknown" -- "3.4.02";
SC.AUTHOR = GetAddOnMetadata("Accountant", "Author") or "Unknown" --"urnati";
SC.CREDAUTHOR = GetAddOnMetadata("Accountant", "AuthorCredit") or "Unknown" --"tfmonk";
SCOUNTANT_OPTIONS_TITLE = "Accountant Options";
SCOUNTANT_BUTTON_TOOLTIP = "Toggle Accountant";

SC.artwork_path = "Interface\\AddOns\\Accountant\\Artwork\\"

SC.log_modes = {"Session","Day","Week","Total"};
SC.log_modes_short = {"Sess","Day","Week","Tot"};

-- Store the list of characters to be displayed.
-- Same realm and faction
SC.Toons = {}
SC.Faction = ""
SC.ShowAlliance = nil
SC.ShowHorde = nil
-- Store the list of all characters, regardless of realm or faction
SC.AllToons = {}

SC.GOLD_COLOR = "|cFFFFFF00"
SC.GREEN_COLOR = GREEN_FONT_COLOR_CODE
SC.TITLE = "Accountant"
SC.DIVIDER = "-"
