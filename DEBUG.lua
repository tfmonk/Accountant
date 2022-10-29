--[[
 Accountant
    Originally by Sabaki (sabaki@gmail.com)
    Redone by urnati - 3.0
	Mists of Pandaria updates by Thorismud 4.0
  
	Tracks your incoming / outgoing cash

	Thanks To:
	Jay for testing
	Atlas by Razark for the minimap icon code that was lifted
]]
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfig = LibStub("AceConfig-3.0")

-- Create a short cut
local SC = Accountant

SC.data = nil;
SC.MaxRows = 15 -- Per the rows implemented in the XML
SC.mode = "";
SC.refund_mode = "";
SC.sender = "";
SC.current_money = 0;
SC.last_money = 0;
SC.got_name = false;
SC.current_tab = 1;
Accountant.player = "";
SC.show_toons = ""
SC.could_repair = false;
SC.can_repair = "";
SC.repair_cost, SC.repair_money = 0,0;
local Accountant_RepairAllItems_old;
local Accountant_CursorHasItem_old;
local tmpstr = "";

SC.verbose = false;
SC.show_events = false -- could generate a lot of output!
SC.show_setup = false
SC.show_mode = false

function SC.TableContainsValue(table, value)
	if table and value then
		local i,v
		for i, v in pairs(table) do
			if v == value then
				return i;
			end
		end
	end
	return nil
end

local function MatchRealm(player, realm)
	local r = string.gsub (realm, "[%c%(%)%[%]%$%^]", "~")
	local p = string.gsub (player, "[%c%(%)%[%]%$%^]", "~")
--[[	
SC.Print("MatchRealm: "
	.."p: '"..p.."'"
	.."r: '"..r.."'"
	)
--]]
	if (string.find(p, r) == nil) then
		return nil
	else
		return true
	end
end

function SC.ClearData ()
--
-- Clear all data all modes
--
	for player in next,Accountant_SaveData do
	for key,value in next,SC.data do
		if Accountant_SaveData[player]["data"][key] == nil then
			Accountant_SaveData[player]["data"][key] = {}
		end
		for modekey,mode in next,SC.log_modes do
			Accountant_SaveData[player]["data"][key][mode] = {In=0,Out=0}
			SC.data[key][mode]  = {In=0,Out=0}
		end
	end
	end
end

function SC.UtilToonDropDownList (realm)
--
-- Initialize the toon dropdown
--
	local faction = ""
	local strtmp = ""
	local toon_table = {}
	for player in next,Accountant_SaveData do
		if realm then
			strtmp = player
		else
			local str_pos = strfind(player, SC.DIVIDER)
			strtmp = strsub(player, str_pos+1) -- remove the realm and dash
		end
			table.insert(toon_table, strtmp)
--DEFAULT_CHAT_FRAME:AddMessage("Acc ToonDropDownList- "..(strtmp or "?").." .. " ..(player or "?"))
	end
	table.sort(toon_table)
	
	SC.AllToons = toon_table
	return toon_table
end

function SC.ToonDelete (toon_value)
--
-- Remove the data of the selected toon
--
	local pop_str = ""

	for i = 1, #SC.AllToons do
		if i == toon_value then
			if SC.AllToons[i] == SC.player then
				DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "..ACCLOC_TOON_DELETE_SELF)
			else
				pop_str = SC.AllToons[i]
				-- delete the data
				Accountant_SaveData[SC.AllToons[i]] = nil;
				-- remove the toon from the options dropdown
				table.remove(SC.AllToons, i)
				-- just in case, rebuild Accountant
				SC.OnLoad()
				DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "..ACCLOC_TOON_DELETE_DONE
					..(pop_str or "?").." "..ACCLOC_DONE)
			end
		end
	end
end

function SC.ToonShow()
--
-- Show all the toons in the array.
--
	for i = 1, #SC.AllToons do
		SC.Print("Name: '"..(SC.AllToons[i] or "?").."'")
	end
end

function SC.ToonMerge (from, to)
--
-- Merge the data of the selected toons
--
	if from == to then
		DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "..ACCLOC_TOON_MERGE_ERR1)
	else
		for key,value in next,SC.data do
			for modekey,mode in next,SC.log_modes do
				if Accountant_SaveData[to]["data"][key][mode] == nil then
					Accountant_SaveData[to]["data"][key][mode] = {In=0,Out=0};
				end
				Accountant_SaveData[to]["data"][key][mode].In  = 
					(tonumber(Accountant_SaveData[to]["data"][key][mode].In) or 0)
				+	(tonumber(Accountant_SaveData[from]["data"][key][mode].In) or 0)
				Accountant_SaveData[to]["data"][key][mode].Out = 
					(tonumber(Accountant_SaveData[to]["data"][key][mode].Out) or 0)
				+	(tonumber(Accountant_SaveData[from]["data"][key][mode].Out) or 0)
			end
		end
		Accountant_SaveData[to]["options"]["totalcash"]  = 
			(tonumber(Accountant_SaveData[to]["options"]["totalcash"]) or 0)
		+	(tonumber(Accountant_SaveData[from]["options"]["totalcash"]) or 0)

		if to == SC.player then
			-- Reload the data for this toon
			SC.LoadSavedData()
		end
		DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "..ACCLOC_TOON_MERGE.." of "
			..(from or "?").." "..ACCLOC_TO.." "..(to or "?").." "..ACCLOC_DONE)
	end
end

--[[ AccountantButton.lua

	Declare the minimap button routines for Accountant
]]

function SC.Button_OnClick()
--
-- Toggle the Accountant window on click of the mini-map button
--
	if AccountantFrame:IsVisible() then
		HideUIPanel(AccountantFrame);
	else
		ShowUIPanel(AccountantFrame);
	end
	
end

function SC.Button_makename()
--
-- Create the name so the right data can be looked up.
--
	acc_realm = GetRealmName();
	acc_name = acc_realm..SC.DIVIDER..UnitName("player");
	return acc_name;
end

function SC.Button_Init()
--
-- On start, show or hide the mini-map button based on the user's selection
-- for that character.
--
	if(Accountant_SaveData[SC.Button_makename()]["options"].showbutton) then
		AccountantButtonFrame:Show();
	else
		AccountantButtonFrame:Hide();
	end
end

function SC.Button_Toggle()
--
-- Honor the user's selection to show or hide the mini-map button
-- for that character.
--
	if(AccountantButtonFrame:IsVisible()) then
		AccountantButtonFrame:Hide();
		Accountant_SaveData[SC.Button_makename()]["options"].showbutton = false;
	else
		AccountantButtonFrame:Show();
		Accountant_SaveData[SC.Button_makename()]["options"].showbutton = true;
	end
end

function SC.Button_UpdatePosition()
--
-- Place the mini-map button where the user selects for that character.
--
	AccountantButtonFrame:SetPoint(
		"TOPLEFT",
		"Minimap",
		"TOPLEFT",
		50 - (75 * cos(Accountant_SaveData[SC.Button_makename()]["options"].buttonpos)),
		(75 * sin(Accountant_SaveData[SC.Button_makename()]["options"].buttonpos)) - 50
--[[
 55 - (75 * cos(Accountant_SaveData[SC.Button_makename()]["options"].buttonpos)),
(75 * sin(Accountant_SaveData[SC.Button_makename()]["options"].buttonpos)) - 55
--]]
	);
end


--[[ AccountantButton.lua end
]]

--[[ AccountantOptions.lua begin
]]
local acc_main_options = {
	name = "Accountant",
	type = "group",
	args = 
	{
		confgendesc = 
		{
			order = 1,
			type = "description",
			name = ACCLOC_CONF_DESC.."\n\n",
			cmdHidden = true
		},
		nulloption1 = 
		{
			order = 2,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		confshowtotal =
		{
			name = "Show total on button (LDB)",
			--ACCLOC_TOG_MINIMAP,
			desc = "If checked the total will be shown on the LDB button",
				--ACCLOC_TOG_MINIMAP_DESC,
			order = 3, 
			type = "toggle", width = "full",
			get = function() return Accountant_SaveData[Accountant.player]["options"].showtotal end,
			set = function() SC.ShowTotalLDB() end,
		},
		nulloption2 = 
		{
			order = 3,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		nulloption3 = 
		{
			order = 4,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
		confinfodesc =
		{
			name = "About",
			order = 50,
			type = "group", inline = true,
			args =
			{
				confversiondesc =
				{
				order = 1,
				type = "description",			
				name = SC.GREEN_COLOR.."Version"..": "..SC.GOLD_COLOR..SC.Version, 
				cmdHidden = true
				},
				confauthordesc =
				{
				order = 2,
				type = "description",
				name = SC.GREEN_COLOR.."Version"..": "..SC.GOLD_COLOR..SC.AUTHOR, 
				cmdHidden = true
				},
			},
		},
	}
}

local acc_options_minimap = {
name = "Accountant_options_minimap",
	type = "group",
	args = {
	confdesc = {
			order = 1,
			type = "description",
			name = ACCLOC_CONF_GEN_DESC.."\n",
			cmdHidden = true
		},
		nulloption3 = {
		order = 2,
		type = "description",
		name = "   ",
		cmdHidden = true
		},
--[[
		toggleminimapbuttonheader = {
		order = 3,
		type = "header",
		name = ACCLOC_MINIMAP_BUT,
		},
--]]
		toggleminimapbutton =
		{
			name = ACCLOC_TOG_MINIMAP,
			desc = ACCLOC_TOG_MINIMAP_DESC,
			order = 4, type = "toggle", width = "full",
			get = function() return Accountant_SaveData[Accountant.player]["options"].showbutton end,
			set = function() SC.Button_Toggle() end,
		},
		minimapbuttonpos = {
			name = ACCLOC_POS_MINIMAP,
			desc = ACCLOC_POS_MINIMAP_DESC,
			order = 5, type = "range", width = "full",
			min = 0, max = 360, step = 1,
			get = function() return Accountant_SaveData[Accountant.player]["options"].buttonpos end,
			set = function(_, a)
				Accountant_SaveData[Accountant.player]["options"].buttonpos = a
				Accountant.Button_UpdatePosition()
				end,
						},
		nulloption4 = {
		order = 6,
		type = "description",
		name = "   ",
		cmdHidden = true
		},		
	}
}

local acc_options_start = {
name = "Accountant_options_start",
	type = "group",
	args = {
	confdesc = {
			order = 1,
			type = "description",
			name = ACCLOC_STARTWEEK_DESC.."\n",
			cmdHidden = true
		},
		nulloption3 = {
		order = 2,
		type = "description",
		name = "   ",
		cmdHidden = true
		},
--[[
		weekstartheader = {
		order = 3,
		type = "header",
		name = ACCLOC_STARTWEEK,
		},
--]]
		weekstartselect =
		{
			name = ACCLOC_WEEKDAY,
			desc = ACCLOC_WEEKDAY_DESC,
			order = 4, type = "select",
			get = function() return Accountant_SaveData[Accountant.player]["options"].weekstart end,
			set = function(_,v) 
				Accountant_SaveData[Accountant.player]["options"].weekstart = v
				DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "
					..ACCLOC_WEEKDAY_DONE.." "..(v or "?").." "..ACCLOC_DONE)
				for player in next,Accountant_SaveData do
					Accountant_SaveData[player]["options"].weekstart = v;
				end
				end,
			values = function()
				return {ACCLOC_WD_SUN,ACCLOC_WD_MON,ACCLOC_WD_TUE,
					ACCLOC_WD_WED,ACCLOC_WD_THU,ACCLOC_WD_FRI,ACCLOC_WD_SAT}
			end,
		},
		nulloption4 = {
		order = 6,
		type = "description",
		name = "   ",
		cmdHidden = true
		},		
	}
}

local acc_options_reset = {
name = "Accountant_options_reset",
	type = "group",
	args = {
	confdesc = {
			order = 1,
			type = "description",
			name = ACCLOC_RESET_DESC.."\n",
			cmdHidden = true
		},
		nulloption3 = {
		order = 2,
		type = "description",
		name = "   ",
		cmdHidden = true
		},
		reset = {
			order = 5, type = "execute",
			name = ACCLOC_RESET,
			desc = ACCLOC_RESET_DESC_SHORT,
			func = function()
				SC.ClearData ();
				DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TITLE..": "..ACCLOC_RESET.." "..ACCLOC_DONE)
			end,
		},
		nulloption4 = {
		order = 6,
		type = "description",
		name = "   ",
		cmdHidden = true
		},		
	}
}

local remove_toon = ""
local ignore_toon = ""
local merge_toon_from = ""
local merge_toon_from_name = ""
local merge_toon_to = ""
local merge_toon_to_name = ""
local acc_options_toons_remove = {
name = "Accountant_Toon_Remove",
	type = "group",
	args = {
		confdesc = {
			order = 1,
			type = "description",
			name = ACCLOC_TOON_MGMT_2,
			cmdHidden = true
		},
		-- delete / remove
		setskinheader = {
		order = 10,
		type = "header",
		name = ACCLOC_TOON_DELETE,
		},
		deltoonlist = {
			order = 11, type = "select", width = "full",
			name = ACCLOC_TOON,
			desc = ACCLOC_TOON_REMOVE_DESC,
			get = function() return remove_toon; end,
			set = function(_,v) remove_toon = v; end,
			values = function() return SC.AllToons end,
		},
		deltoon = {
			order = 12, type = "execute",
			name = ACCLOC_TOON_DELETE,
			desc = ACCLOC_TOON_DELETE_DESC,
			func = function()
				SC.ToonDelete (remove_toon);
				remove_toon = "";
			end,
		},
		delnotes = {
		order = 13,
		type = "description",
		name = ACCLOC_TOON_REMOVE_NOTES,
		cmdHidden = true
		},
--[[
		-- ignore
		nulloption01 = {
		order = 5,
		type = "description",
		name = "   ",
		cmdHidden = true
		},		
		setskinheaderignore = {
		order = 10,
		type = "header",
		name = ACCLOC_TOON_IGNORE,
		},
		ignoretoonlist = {
			order = 11, type = "select", width = "full",
			name = ACCLOC_TOON,
			desc = ACCLOC_TOON_IGNORE_DESC,
			get = function() return ignore_toon end,
			set = function(_,v) ignore_toon = v; end,
			values = function() return SC.AllToons; end,
		},
		ignoretoon = {
			order = 12, type = "execute",
			name = ACCLOC_TOON_IGNORE,
			desc = ACCLOC_TOON_IGNORE_DESC,
			func = function()
DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TOON_IGNORE.." "..(ignore_toon or "?").." ");
				--SC.ToonDelete (ignore_toon);
			end,
		},
--]]
		nulloption1 = {
			order = 50,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
	}
}

local acc_options_toons_merge = {
name = "Accountant_Toon_Merge",
	type = "group",
	args = {
		confdesc = {
			order = 1,
			type = "description",
			name = ACCLOC_TOON_MGMT_2,
			cmdHidden = true
		},
		-- merge
		nulloption02 = {
		order = 19,
		type = "description",
		name = "   ",
		cmdHidden = true
		},		
		setskinheadermerge = {
		order = 20,
		type = "header",
		name = ACCLOC_TOON_MERGE,
		},
		mergetoonfromlist = {
			order = 21, type = "select", width = "full",
			name = ACCLOC_TOON_FROM,
			desc = ACCLOC_TOON_FROM_DESC,
			get = function() return merge_toon_from end,
			set = function(info, value)
				merge_toon_from = value;
				for i = 1, #SC.AllToons do
					if i == value then
						-- save the name
						merge_toon_from_name = SC.AllToons[i]
					end
				end
--DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TOON_MERGE.." from "..(value or "?").." "..(merge_toon_from_name or "?"));
			end,
			values = function() return SC.AllToons; end,
		},
		mergetoontolist = {
			order = 22, type = "select", width = "full",
			name = ACCLOC_TOON_TO,
			desc = ACCLOC_TOON_TO_DESC,
			get = function() return merge_toon_to end,
			set = function(_,value)
				merge_toon_to = value;
				for i = 1, #SC.AllToons do
					if i == value then
						-- save the name
						merge_toon_to_name = SC.AllToons[i]
					end
				end
--DEFAULT_CHAT_FRAME:AddMessage(ACCLOC_TOON_MERGE.." to "..(value or "?").." "..(merge_toon_to_name or "?"));
			end,
			values = function() return SC.AllToons; end,
		},
		mergetoon = {
			order = 23, type = "execute",
			name = ACCLOC_TOON_MERGE,
			desc = ACCLOC_TOON_MERGE_NOTES1,
			func = function()
				SC.ToonMerge (merge_toon_from_name, merge_toon_to_name);
			end,
		},
		mergenotes2 = {
		order = 25,
		type = "description",
		name = ACCLOC_TOON_MERGE_NOTES2,
		cmdHidden = true
		},
		nulloption1 = {
			order = 50,
			type = "description",
			name = "   ",
			cmdHidden = true
		},
	}
}

local acc_options_transparency = {
name = "Accountant_options_transparency",
	type = "group",
	args = {
	confdesc = {
		order = 1,
		type = "description",
		name = ACCLOC_TRANSP_DESC.."\n",
		cmdHidden = true
		},
		bartrans = {
			name = ACCLOC_TRANSP,
			desc = ACCLOC_TRANSP_DESC,
			order = 2, type = "range", width = "full",
			min = 0, max = 1, step = 0.01,
			get = function() return (Accountant_SaveData[Accountant.player]["options"].transparancy or 1) end,
			set = function(_, trans)
				AccountantFrame.AccountantFrameBackdrop:SetAlpha(trans);
				Accountant_SaveData[Accountant.player]["options"].transparancy = trans;
			end,
		},
   }
}

--
-- Create the structures for the options screens
-- The Blizz options screens will be used
--
function SC.InitOptions()
	-- Create the dropdown used in the options
	SC.UtilToonDropDownList (true)
	
	AceConfig:RegisterOptionsTable("Accountant Main", acc_main_options)
	AceConfig:RegisterOptionsTable("Accountant Minimap", acc_options_minimap)
	AceConfig:RegisterOptionsTable("Accountant Transparancy", acc_options_transparency)
	AceConfig:RegisterOptionsTable("Accountant Week Start", acc_options_start)
	AceConfig:RegisterOptionsTable("Accountant Toon Remove", acc_options_toons_remove)
	AceConfig:RegisterOptionsTable("Accountant Toon Merge", acc_options_toons_merge)
	AceConfig:RegisterOptionsTable("Accountant Reset", acc_options_reset)
	AceConfigDialog:AddToBlizOptions("Accountant Main", ACCLOC_TITLE, nil)
	AceConfigDialog:AddToBlizOptions("Accountant Minimap", ACCLOC_MINIMAP_BUT, ACCLOC_TITLE)
--	AceConfigDialog:AddToBlizOptions("Accountant Transparancy", ACCLOC_TRANSPARANCY, ACCLOC_TITLE)
	AceConfigDialog:AddToBlizOptions("Accountant Week Start", ACCLOC_STARTWEEK, ACCLOC_TITLE)
	AceConfigDialog:AddToBlizOptions("Accountant Toon Remove", ACCLOC_TOON_REMOVE, ACCLOC_TITLE)
	AceConfigDialog:AddToBlizOptions("Accountant Toon Merge", ACCLOC_TOON_MERGE_T, ACCLOC_TITLE)
	AceConfigDialog:AddToBlizOptions("Accountant Reset", ACCLOC_RESET, ACCLOC_TITLE)
end

--[[ AccountantOptions.lua end
--]]


--[[ Data Broker section begin
]]

-- Set the LDB framework for the other LDB routines
SC.LDB_frame = CreateFrame("Frame")
SC.LDB_frame.obj = {}

function SC:LDB_Init()
--
-- Initialize the Data Broker 'button'
--
   SC.LDB_frame.obj = 
	LibStub("LibDataBroker-1.1"):NewDataObject("Accountant", {
		type = "data source",
		icon = SC.artwork_path.."AccountantButton.blp",
		label = "Accountant",
		text  = "nyl",
   
		OnClick = function(self, button)
			if ( button == "LeftButton" ) then
				Accountant.Button_OnClick();
			elseif ( button == "RightButton" ) then
			end
		end,

		OnTooltipShow = function(tooltip)
			SC.LDB_OnTooltipShow(tooltip)
		end,
	})
end

function SC:LDB_Update()
--
-- Update the Accountant Data Broker 'button'
--
	local TotalIn = 0
	local TotalOut = 0
	local mode = "<nyl>"
	local total = 0
	local total_str = ""
	
	if SC.current_tab ~= 5 then
		TotalIn, TotalOut = 
			SC.GetDetailForToons(SC.log_modes[SC.current_tab], false)
		cash = TotalIn-TotalOut
		mode = SC.log_modes_short[SC.current_tab]
		total = SC.GetCashForToons()
	else
		cash = SC.GetCashForAllToons(false)
		mode = ACCLOC_CHARS
	end
	
	if Accountant_SaveData[SC.Button_makename()]["options"].showtotal then
		total_str = SC.NiceCash(total, true, true).." : "
	end
	SC.LDB_frame.obj.text = 
		total_str -- rely on the text setup for spacing
		.."|cFFF5B800"..mode..FONT_COLOR_CODE_CLOSE
		.." "..SC.NiceCash(cash, true, true)
		
--[[
	if mode == SC.log_modes_short[1] then
		SC.LDB_frame.obj.icon = SC.artwork_path.."copper.tga"
	elseif mode == SC.log_modes_short[2] then
		SC.LDB_frame.obj.icon = SC.artwork_path.."silver.tga"
	elseif mode == SC.log_modes_short[3] then
		SC.LDB_frame.obj.icon = SC.artwork_path.."gold.tga"
	else
		SC.LDB_frame.obj.icon = SC.artwork_path.."AccountantButton.blp"
	end
	SC.Print(
		"icon: '"..SC.LDB_frame.obj.icon.."'"
		)
--SC.log_modes_short = {"Sess","Day","Week","Tot"};
--]]
end

function SC.LDB_OnTooltipShow(tooltip)
--
-- Display the Data Broker tooltip
-- A Data Broker display addon will use this routine
--
	tooltip = tooltip or GameTooltip
	local tt_str = ""
	local strtmp = ""
	if SC.show_toons == ACCLOC_CHARS then
		strtmp = ACCLOC_CHARS
	else
		local str_pos = strfind(SC.show_toons, SC.DIVIDER)
		strtmp = strsub(SC.show_toons, str_pos+1) -- remove the realm and dash
	end
	tt_str =
		GREEN_FONT_COLOR_CODE
		..strtmp
		.."\n"..FONT_COLOR_CODE_CLOSE
	tooltip:AddLine(tt_str)

	SC.LDB_GetTooltipDetail(tooltip)
		
	tt_str = " "
	tooltip:AddLine(tt_str)

	tt_str =
		GREEN_FONT_COLOR_CODE
		..ACCLOC_LCLICK
		.." "..BINDING_NAME_ACCOUNTANTTOG
		..FONT_COLOR_CODE_CLOSE;
	tooltip:AddLine(tt_str)
end

function SC.LDB_GetTooltipDetail(tooltip)
--
-- get the detail of user selected toons for the requested mode
--
	local TotalRowIn
	local TotalRowOut
	local TotalIn = 0
	local TotalOut = 0
	local mode = ""
	local tt_str = ""
	local tmpstr = ""

	if SC.current_tab == 5 then
		return;
	end
    mode = SC.log_modes[SC.current_tab];

    for key,value in next,SC.data do
        TotalRowIn = 0;
        TotalRowOut = 0;

        for player in next,Accountant_SaveData do
            -- Find the one player or all players of the faction(s) requested
            faction = Accountant_SaveData[player]["options"]["faction"]
			if (MatchRealm(player, SC.Realm) ~= nil)
				and (( (faction == ACCLOC_ALLIANCE) 
                     and (SC.ShowAlliance == true) )
                or ( (faction == ACCLOC_HORDE) 
                     and (SC.ShowHorde == true) ))
				and ( SC.show_toons == player
                  or SC.show_toons == SC.AllDropdown ) then

				TotalRowIn = TotalRowIn + Accountant_SaveData[player]["data"][key][mode].In;
				TotalRowOut = TotalRowOut + Accountant_SaveData[player]["data"][key][mode].Out;
            end
        end

        tmpstr = key
			
		tt_str = "|cFFF5B800"..tmpstr..FONT_COLOR_CODE_CLOSE
		tmpstr = SC.NiceCash((TotalRowIn - TotalRowOut), true, true)
        tooltip:AddDoubleLine(tt_str,tmpstr);
    end
end

--[[ Data Broker section end
]]

--[[ Accountant.lua begin
]]

function SC.RegisterEvents(self)
--
-- Register for all the events needed to track the flow of gold
--
	self:RegisterEvent("MERCHANT_SHOW");
	self:RegisterEvent("MERCHANT_CLOSED");
	self:RegisterEvent("MERCHANT_UPDATE");

	self:RegisterEvent("QUEST_COMPLETE");
	self:RegisterEvent("QUEST_FINISHED");
	
	self:RegisterEvent("LOOT_OPENED");
	self:RegisterEvent("LOOT_CLOSED");
	
	self:RegisterEvent("TAXIMAP_OPENED");
	self:RegisterEvent("TAXIMAP_CLOSED");

	self:RegisterEvent("TRADE_SHOW");
	self:RegisterEvent("TRADE_CLOSE");
	
	self:RegisterEvent("MAIL_SHOW");
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	self:RegisterEvent("MAIL_CLOSED");
--	self:RegisterEvent("MAIL_SEND_INFO_UPDATE");
--	self:RegisterEvent("MAIL_SEND_SUCCESS");

	self:RegisterEvent("TRAINER_SHOW");
	self:RegisterEvent("TRAINER_CLOSED");

	self:RegisterEvent("AUCTION_HOUSE_SHOW");
	self:RegisterEvent("AUCTION_HOUSE_CLOSED");
	self:RegisterEvent("BLACK_MARKET_OPEN");
	self:RegisterEvent("BLACK_MARKET_CLOSE");

	self:RegisterEvent("PLAYER_MONEY");

	self:RegisterEvent("UNIT_NAME_UPDATE");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("PLAYER_LEAVING_WORLD");
		
	self:RegisterEvent("UPDATE_INVENTORY_ALERTS");
	self:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
end

function SC.SetLabels()
--
-- Create the various labels and headers for the Accountant frame
--
	-- For those that add / delete toons, clear the all rows.
	for i = 1, SC.MaxRows, 1 do
		getglobal("AccountantFrameRow"..i.."Title"):SetText("");
		getglobal("AccountantFrameRow"..i.."In"):SetText("");
		getglobal("AccountantFrameRow"..i.."Out"):SetText("");
	end

	AccountantFrameAllianceToggleButtonText:SetText(ACCLOC_ALLIANCE);
	AccountantFrameAllianceToggleButton:SetChecked(Accountant_SaveData[Accountant.player]["options"].showAlliance);
	AccountantFrameHordeToggleButtonText:SetText(ACCLOC_HORDE);
	AccountantFrameHordeToggleButton:SetChecked(Accountant_SaveData[Accountant.player]["options"].showHorde);

	-- Set the header
	local header = getglobal("AccountantFrameTitleText");
	if ( header ) then 
		header:SetText(ACCLOC_TITLE.." "..SC.Version);
	end

	if SC.current_tab == 5 then
		AccountantFrameSource:SetText(ACCLOC_CHARCAP);
		AccountantFrameIn:SetText(ACCLOC_MONEY);
		AccountantFrameOut:SetText(ACCLOC_UPDATED);
		AccountantFrameTotalIn:SetText("");
		AccountantFrameTotalOut:SetText("");
		AccountantFrameTotalFlow:SetText("");
		AccountantFrameTotalInValue:SetText("");
		AccountantFrameTotalOutValue:SetText("");
		AccountantFrameTotalFlowValue:SetText("");
		--AccountantFrameResetButton:Hide();
		AccountantFrameCacheBox:Hide()
		AccountantFrameCacheAmount:Hide()
		
		Accountant_CharDropDown:Hide()
		return;
	end
	Accountant_CharDropDown:Show()
	
	AccountantFrameCacheBox:Show()
	AccountantFrameCacheAmount:Show()
	
	AccountantFrameMoneyTotal:SetText("")
	
	AccountantFrameSource:SetText(ACCLOC_SOURCE);
	AccountantFrameIn:SetText(ACCLOC_IN);
	AccountantFrameOut:SetText(ACCLOC_OUT);
	AccountantFrameTotalIn:SetText(ACCLOC_TOT_IN..":");
	AccountantFrameTotalOut:SetText(ACCLOC_TOT_OUT..":");
	AccountantFrameTotalFlow:SetText(ACCLOC_NET..":");

	-- Row Labels (auto generate)
	InPos = 1
	for key,value in next,SC.data do
		SC.data[key].InPos = InPos;
		getglobal("AccountantFrameRow"..InPos.."Title"):SetText(SC.data[key].Title);
		InPos = InPos + 1;
	end
end

function SC.OnLoad()	
--
-- Do all the setup needed on load of Accountant
--
	SC.Realm = GetRealmName();
	SC.Char = UnitName("player");
	SC.Faction = UnitFactionGroup("player")
	SC.player = SC.Realm..SC.DIVIDER..SC.Char;
	SC.AllDropdown = ACCLOC_CHARS
	
	-- default behaviour
	SC.show_toons = ACCLOC_CHARS

	-- shamelessly print a load message to chat window
	DEFAULT_CHAT_FRAME:AddMessage(
		GREEN_FONT_COLOR_CODE.."Accountant "
		..SC.Version
		.." by "
		..FONT_COLOR_CODE_CLOSE
		.."|cFFFFFF00"..SC.AUTHOR..FONT_COLOR_CODE_CLOSE
		.." for "
		.."'"..SC.player.."'"
	);

	-- Setup
	SC.LoadSavedData();
	SC.SetLabels();

	-- Current Cash
	SC.current_money = GetMoney();
	SC.last_money = SC.current_money;

	-- Register the slash Commands
	SlashCmdList["ACCOUNTANT"] = SC.Slash;
	SLASH_ACCOUNTANT1 = "/accountant";
	SLASH_ACCOUNTANT2 = "/acc";

	-- Add myAddOns support
	if myAddOnsList then
		myAddOnsList.Accountant = {name = "Accountant", 
		description = "Tracks your revenues / expenditures", 
		version = SC.Version, 
		frame = "AccountantFrame", 
		optionsframe = "AccountantFrame"};
	end
	
	-- Create the confirm box to use if needed
	StaticPopupDialogs["ACCOUNTANT_RESET"] = {
		text = TEXT("meh"),
		button1 = TEXT(OKAY),
		button2 = TEXT(CANCEL),
		OnAccept = function()
			SC.ResetConfirmed();
		end,
		showAlert = 1,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		interruptCinematic = 1
	};

	-- Set the tabs at the bottom of the Accountant window
	AccountantFrameTab1:SetText(ACCLOC_SESS);
	AccountantFrameTab2:SetText(ACCLOC_DAY);
	AccountantFrameTab3:SetText(ACCLOC_WEEK);
	AccountantFrameTab4:SetText(ACCLOC_TOTAL);
	AccountantFrameTab5:SetText(ACCLOC_CHARS);
	PanelTemplates_SetNumTabs(AccountantFrame, 5);
	PanelTemplates_SetTab(AccountantFrame, AccountantFrameTab1);
	PanelTemplates_UpdateTabs(AccountantFrame);

	AccountantFrameCacheBox:SetText("Cache Box"..":") --;ACCLOC_NET..":");
	AccountantFrameCacheUpdate:SetText("Update")
	SC:LDB_Update()
end

function SC.LoadSavedData()
--
-- Load the account data of the character that is being played
--
	local first_time = nil
	
	SC.data = {};
	SC.data["LOOT"] = {Title = ACCLOC_LOOT};
	SC.data["MERCH"] = {Title = ACCLOC_MERCH};
	SC.data["QUEST"] = {Title = ACCLOC_QUEST};
	SC.data["TRADE"] = {Title = ACCLOC_TRADE};
	SC.data["MAIL"] = {Title = ACCLOC_MAIL};
	SC.data["AH"] = {Title = ACCLOC_AUC};
	SC.data["TRAIN"] = {Title = ACCLOC_TRAIN};
	SC.data["TAXI"] = {Title = ACCLOC_TAXI};
	SC.data["REPAIRS"] = {Title = ACCLOC_REPAIR};
	SC.data["OTHER"] = {Title = ACCLOC_OTHER};
	SC.data["BMAH"] = {Title = ACCLOC_BMAH};
	SC.data["SYSTEM"] = {Title = ACCLOC_SYS};

	for key,value in next,SC.data do
		for modekey,mode in next,SC.log_modes do
			SC.data[key][mode] = {In=0,Out=0};
		end
	end

	-- If the data structure used does not exist, this is the first time Accountant
	-- has been run on this machine
	if(Accountant_SaveData == nil) then
		Accountant_SaveData = {};
	end

	-- If the player does not exist, this is the first time
	-- the player has been logged in on this machine.
	if (Accountant_SaveData[Accountant.player] == nil ) then
		first_time = true
		cdate = date();
		cdate = string.sub(cdate,0,8);
		cweek = "";
		Accountant_SaveData[Accountant.player] = {options
			={showbutton=true,
				buttonpos=0,
				version=SC.Version,
				date=cdate,
				weekdate=cweek,
				weekstart=3,
				totalcash=0,
				cachebox = 0,
				showtotal = nil,
				},
			data={},
			current_tab=1,
			show_toons = ACCLOC_CHARS,
			};
		
		-- Quel's mod: make sure introduction of a new character gets the same weekstart as
		-- existing chars, otherwise it will prematurely wipe out the weekly totals.
		for player in next,Accountant_SaveData do
			-- Quel's mod: only consider chars on the same server
			if (MatchRealm(player, SC.Realm) ~= nil) then
				if (Accountant_SaveData[player]["options"]["weekstart"] ~= nil) then
					SC.Print2("Adding a new account for new character, "
					..Accountant.player..", weekstart = "
					..Accountant_SaveData[player]["options"]["weekstart"]);
					Accountant_SaveData[Accountant.player]["options"]["weekstart"] 
					= Accountant_SaveData[player]["options"]["weekstart"];
				end
				if (Accountant_SaveData[player]["options"]["dateweek"] ~= nil) then
					SC.Print2("Adding a new account for new character, "
					..Accountant.player..", dateweek = "..Accountant_SaveData[player]["options"]["dateweek"]);
					Accountant_SaveData[Accountant.player]["options"]["dateweek"] 
					= Accountant_SaveData[player]["options"]["dateweek"];
				end
			end
		end
--		SC.Print(ACCLOC_NEWPROFILE.." "..Accountant.player);
	else
--		SC.Print(ACCLOC_LOADPROFILE.." "..Accountant.player);
	end

	-- If the faction does not exist, this is the first time the version 3.1
	-- has been run on this machine
	if (Accountant_SaveData[SC.Button_makename()]["options"].showAlliance == nil) then
		Accountant_SaveData[SC.Button_makename()]["options"].showAlliance = true;
	end
	if (Accountant_SaveData[SC.Button_makename()]["options"].showHorde == nil) then
		Accountant_SaveData[SC.Button_makename()]["options"].showHorde = true;
		SC.ShowHorde = true
	end
	SC.ShowAlliance = Accountant_SaveData[SC.Button_makename()]["options"].showAlliance
	SC.ShowHorde = Accountant_SaveData[SC.Button_makename()]["options"].showHorde

	order = 1;
	for key,value in next,SC.data do
		if Accountant_SaveData[Accountant.player]["data"][key] == nil then
			Accountant_SaveData[Accountant.player]["data"][key] = {}
		end
		for modekey,mode in next,SC.log_modes do
			if Accountant_SaveData[Accountant.player]["data"][key][mode] == nil then
				Accountant_SaveData[Accountant.player]["data"][key][mode] = {In=0,Out=0};
			end
			SC.data[key][mode].In  = Accountant_SaveData[Accountant.player]["data"][key][mode].In;
			SC.data[key][mode].Out = Accountant_SaveData[Accountant.player]["data"][key][mode].Out;
		end
		SC.data[key]["Session"].In = 0;
		SC.data[key]["Session"].Out = 0;

		-- Old Version Conversion
		if Accountant_SaveData[Accountant.player]["data"][key].TotalIn ~= nil then
			Accountant_SaveData[Accountant.player]["data"][key]["Total"].In 
			= Accountant_SaveData[Accountant.player]["data"][key].TotalIn;
			SC.data[key]["Total"].In = Accountant_SaveData[Accountant.player]["data"][key].TotalIn;
			Accountant_SaveData[Accountant.player]["data"][key].TotalIn = nil;
		end
		if Accountant_SaveData[Accountant.player]["data"][key].TotalOut ~= nil then
			Accountant_SaveData[Accountant.player]["data"][key]["Total"].Out 
			= Accountant_SaveData[Accountant.player]["data"][key].TotalOut;
			SC.data[key]["Total"].Out = Accountant_SaveData[Accountant.player]["data"][key].TotalOut;
			Accountant_SaveData[Accountant.player]["data"][key].TotalOut = nil;
		end
		if Accountant_SaveData[key] ~= nil then
			Accountant_SaveData[key] = nil;
		end
		-- End OVC
		SC.data[key].order = order;
		order = order + 1;

		-- Quel's modifications to track income/expense across all characters relies on the savedata structure,
		-- so we have to reset the session totals for all players each time we log in, only for chars on this server.
		for player in next,Accountant_SaveData do
			if (MatchRealm(player, SC.Realm) ~= nil) then
--				SC.Print2("Blanking session data for: "..player..", "..key);
				Accountant_SaveData[player]["data"][key]["Session"].In = 0;
				Accountant_SaveData[player]["data"][key]["Session"].Out = 0;
			end
		end

	end

	local old_gold = Accountant_SaveData[Accountant.player]["options"].totalcash
	if first_time then
		-- do not collect 'old' gold otherwise it will be counted twice...
	else
		SC.UpdateOther(old_gold, GetMoney())
	end
	Accountant_SaveData[Accountant.player]["options"].version = SC.Version;
	Accountant_SaveData[Accountant.player]["options"].totalcash = GetMoney();

	-- Always set the player's faction. 
	-- They could have deleted a character and remade it.
	Accountant_SaveData[Accountant.player]["options"]["faction"] = SC.Faction
--DEFAULT_CHAT_FRAME:AddMessage("Acc faction: "..
--Accountant_SaveData[Accountant.player]["options"]["faction"])
   if Accountant_SaveData[Accountant.player]["options"]["current_tab"] == nil then
	  Accountant_SaveData[Accountant.player]["options"]["current_tab"] = 1
   end
   SC.current_tab = Accountant_SaveData[Accountant.player]["options"]["current_tab"]
   if Accountant_SaveData[Accountant.player]["options"]["show_toons"] == nil then
     Accountant_SaveData[Accountant.player]["options"]["show_toons"] = ACCLOC_CHARS
   end
   SC.show_toons = Accountant_SaveData[Accountant.player]["options"]["show_toons"]

	if Accountant_SaveData[Accountant.player]["options"]["weekstart"] == nil then
		Accountant_SaveData[Accountant.player]["options"]["weekstart"] = 3;
		-- Quel's mod: make sure introdudction of a new character gets the same cdate as
		-- existing chars on this realm, otherwise it will prematurely wipe out the daily totals
		for player in next,Accountant_SaveData do
			if (MatchRealm(player, SC.Realm) ~= nil) then
				if (Accountant_SaveData[player]["options"]["weekstart"] ~= nil) then
--					SC.Print2("Setting weekstart for "..AccountantPlayer.." to match "..player.." value: "..Accountant_SaveData[player]["options"]["weekstart"]);
					Accountant_SaveData[Accountant.player]["options"]["weekstart"] 
					= Accountant_SaveData[player]["options"]["weekstart"];
				end
			end
		end
	end
	if Accountant_SaveData[Accountant.player]["options"]["dateweek"] == nil then
		Accountant_SaveData[Accountant.player]["options"]["dateweek"] = SC.WeekStart();
		-- Quel's mod: make sure introdudction of a new character gets the same cdate as
		-- existing chars on this server, otherwise it will prematurely wipe out the daily totals.
		for player in next,Accountant_SaveData do
			if (MatchRealm(player, SC.Realm) ~= nil) then
				if (Accountant_SaveData[player]["options"]["dateweek"] ~= nil) then
--					SC.Print2("Setting dateweek for "..Accountant.player.." to match "..player.." value: "..Accountant_SaveData[player]["options"]["dateweek"]);
					Accountant_SaveData[Accountant.player]["options"]["dateweek"] 
					= Accountant_SaveData[player]["options"]["dateweek"];
				end
			end
		end
	end
	if Accountant_SaveData[Accountant.player]["options"]["date"] == nil then
		cdate = date();
		cdate = string.sub(cdate,0,8);
		Accountant_SaveData[Accountant.player]["options"]["date"] = cdate;

		-- Quel's mod: make sure introdudction of a new character gets the same cdate as
		-- existing chars on this server, otherwise it will prematurely wipe out the daily totals.
		for player in next,Accountant_SaveData do
			if (MatchRealm(player, SC.Realm) ~= nil) then
				if (Accountant_SaveData[player]["options"]["date"] ~= nil) then
--					SC.Print2("Setting date for "..AccountantPlayer.." to match "..player.." value: "..Accountant_SaveData[player]["options"]["date"]);
					Accountant_SaveData[Accountant.player]["options"]["date"] 
					= Accountant_SaveData[player]["options"]["date"];
				end
			end
		end
	end

	-- Quel's mod: the following code to check for a new day/week was originally in OnShow(), which had
	-- a serious flaw. If you collected money on the first day of the week, then opened Accountant, the
	-- OnShow function would see a new week, blank the weekly values, then show zeros (losing the income
	-- or expenses). The session totals remained correct since they weren't reset. I moved all initialization
	-- code here.

	-- Check to see if the day has rolled over
	cdate = date();
	cdate = string.sub(cdate,0,8);
	if Accountant_SaveData[Accountant.player]["options"]["date"] ~= cdate then
		-- Its a new day! clear out the day tab
--		SC.Print2("Found a new day!");
		for mode,value in next,SC.data do
			SC.data[mode]["Day"].In = 0;
			SC.data[mode]["Day"].Out = 0;

			-- Quel's mod: have to clear data for all chars on this server when it rolls over and update
			-- their date to match.
			for player in next,Accountant_SaveData do
				if (MatchRealm(player, SC.Realm) ~= nil) then
--					SC.Print2("	Setting Accountant_SaveData["..player.."][data]["..mode.."][date] = "..cdate);
					Accountant_SaveData[player]["data"][mode]["Day"].In = 0;
					Accountant_SaveData[player]["data"][mode]["Day"].Out = 0;
					Accountant_SaveData[player]["options"]["date"] = cdate;
				end
			end
		end
	end
	
	-- Check to see if the week has rolled over
	if Accountant_SaveData[Accountant.player]["options"]["dateweek"] ~= SC.WeekStart() then
--		SC.Print2("Found a new week!");
		-- Its a new week! clear out the week tab
		for mode,value in next,SC.data do
			SC.data[mode]["Week"].In = 0;
			SC.data[mode]["Week"].Out = 0;

			-- Quel's mod: have to clear data for all chars on this server when it rolls over and update
			-- their date to match.
			for player in next,Accountant_SaveData do
				if (MatchRealm(player, SC.Realm) ~= nil) then
--					SC.Print2("	Setting Accountant_SaveData["..player.."][data]["..mode.."][dateweek] = "..SC.WeekStart() );
					Accountant_SaveData[player]["data"][mode]["Week"].In = 0;
					Accountant_SaveData[player]["data"][mode]["Week"].Out = 0;
					Accountant_SaveData[player]["options"]["dateweek"] = SC.WeekStart();
				end
			end
		end
	end
	
	-- Create the list of characters to show in the drop down.
	SC.ToonDropDownList ()
end

function SC.CacheSetCopper(cash)
--
-- Set the cache box values on the frame
--
	local default = "?"
	local total_str, total, gold, silver, copper = SC.NiceCash(cash, false, false)

	if total > 0 then
	else
		-- assume it has not been set or was cleared
		gold = ""
		silver = ""
		copper = ""
	end
	AccountantFrameCacheAmountGold:SetText((gold or default))
	AccountantFrameCacheAmountSilver:SetText((silver or default))
	AccountantFrameCacheAmountCopper:SetText((copper or default))
end

function SC.CacheGetCopper()
--
-- Update the cache box if asked to
--
	local totalCopper = 0;
	local gold = AccountantFrameCacheAmountGold:GetText() --getglobal(moneyFrame:GetName().."Copper"):GetText();
	local silver = AccountantFrameCacheAmountSilver:GetText() --getglobal(moneyFrame:GetName().."Silver"):GetText();
	local copper = AccountantFrameCacheAmountCopper:GetText() --getglobal(moneyFrame:GetName().."Gold"):GetText();
	
	if ( copper ~= "" ) then
		totalCopper = totalCopper + copper;
	end
	if ( silver ~= "" ) then
		totalCopper = totalCopper + (silver * COPPER_PER_SILVER);
	end
	if ( gold ~= "" ) then
		totalCopper = totalCopper + (gold * COPPER_PER_GOLD);
	end
	return totalCopper;
end

function SC.CacheBoxUpdate()	
	--Get the values the user input
	local cache_copper = (SC.CacheGetCopper() or 0)
	Accountant_SaveData[SC.show_toons]["options"].cachebox = cache_copper;
	-- update appropriate values
	SC.ShowValues()
	
	SC:LDB_Update()
end

function SC.ToonDropDownList ()
--
-- Initialize the toon dropdown
--
	local faction = ""
	SC.Toons = {}
	for player in next,Accountant_SaveData do
		if MatchRealm(player, SC.Realm) then
			local str_pos = strfind(player, SC.DIVIDER)
			local strtmp = strsub(player, str_pos+1) -- remove the realm and dash
			faction = Accountant_SaveData[player]["options"]["faction"]
--SC.Print("ToonDropDownList: trim ".."'"..strtmp.."' faction '".."'"..faction.."'")
			if ( (faction == ACCLOC_ALLIANCE) 
				and (SC.ShowAlliance == true) )
			or ( (faction == ACCLOC_HORDE) 
				and (SC.ShowHorde == true) )
				then
				table.insert(SC.Toons, strtmp)
			end
		end
	end
	table.sort(SC.Toons)
end

function SC.CharDropDown_Init ()
--
-- Initialize the toon dropdown
--
	local info = {}
	SC.ToonDropDownList ()
	-- Initialize the dropdown of toons
	info.text = ACCLOC_CHARS
	info.func = SC.CharDropDown_OnClick
	info.checked = nil
	UIDropDownMenu_AddButton(info)
	for i = 1, #SC.Toons do
		info.text = SC.Toons[i]
		info.func = SC.CharDropDown_OnClick
		info.checked = nil
		UIDropDownMenu_AddButton(info)
	end
end

function SC.CharDropDown_Setup()
--
-- Setup the dropdown
-- Used outside the XML controller
--
	UIDropDownMenu_Initialize(Accountant_CharDropDown, SC.CharDropDown_Init);
	
	-- 
	local selected
	for i = 1, #SC.Toons do
		if SC.show_toons == SC.Realm..SC.DIVIDER..SC.Toons[i] then
			UIDropDownMenu_SetSelectedID(Accountant_CharDropDown, i+1)
			selected = true
		end
	end
	if selected == nil then
		UIDropDownMenu_SetSelectedID(Accountant_CharDropDown, 1)
		SC.show_toons = SC.AllDropdown
	end
--DEFAULT_CHAT_FRAME:AddMessage("Acc char drop _OnShow: ")
end

function SC.CharDropDown_OnShow()
--
-- Init and show the dropdown
--
	SC.CharDropDown_Setup()

	UIDropDownMenu_SetWidth(Accountant_CharDropDown, 100);
--DEFAULT_CHAT_FRAME:AddMessage("Acc char drop _OnShow: ")
end

function SC.CharDropDown_OnClick(self)
--
-- Handle a selection from the toons drop down
--
	local val = self:GetID();
	local id = self.value
	
	UIDropDownMenu_SetSelectedID(Accountant_CharDropDown, val);

	if( id == ACCLOC_CHARS) then
		searchChar = SC.AllDropdown;
	else
		searchChar = SC.Realm..SC.DIVIDER..id -- SC.Toons[id-1];
	end
--[[
	DEFAULT_CHAT_FRAME:AddMessage("Acc char drop _OnClick: "
..(searchChar or "?").." "
..(val or "?").." "
)
--]]
   -- Change the player to the one selected
	SC.show_toons = searchChar
	
	-- Show the new values
	SC.ShowValues()
	SC:LDB_Update()
end

function SC.Button_Alliance_Toggle(self)
--
-- Honor the user's selection to show or hide Alliance characters.
--
	if (self:GetChecked()) then
		Accountant_SaveData[SC.Button_makename()]["options"].showAlliance = true;
	else
		Accountant_SaveData[SC.Button_makename()]["options"].showAlliance = false;
	end
	SC.ShowAlliance = Accountant_SaveData[SC.Button_makename()]["options"].showAlliance
	SC.CharDropDown_Setup()
	SC.ShowValues()
	SC:LDB_Update()
end

function SC.Button_Horde_Toggle(self)
--
-- Honor the user's selection to show or hide Alliance characters.
--
	if (self:GetChecked()) then
		Accountant_SaveData[SC.Button_makename()]["options"].showHorde = true;
	else
		Accountant_SaveData[SC.Button_makename()]["options"].showHorde = false;
	end
	SC.ShowHorde = Accountant_SaveData[SC.Button_makename()]["options"].showHorde
	SC.CharDropDown_Setup()
	SC.ShowValues()
	SC:LDB_Update()
end

function SC.ShowUsage()
	SC.Print("/accountant log | verbose | week\n");
end

function SC.Slash(msg)
--
-- Consume and act on the Accountant slash commands
--
	if msg == nil or msg == "" then
		msg = "log";
	end
	local args = {n=0}
	local function helper(word) table.insert(args, word) end
	string.gsub(msg, "[_%w]+", helper);
	if args[1] == 'log'  then
		ShowUIPanel(AccountantFrame);
	elseif args[1] == 'verbose' then
		if SC.verbose == nil then
			SC.verbose = 1;
			SC.Print("Verbose Mode On");
		else
			SC.verbose = nil;
			SC.Print("Verbose Mode Off");
		end
	elseif args[1] == 'show_events' then
		if SC.show_events == nil then
			SC.show_events = 1;
			SC.Print("show_events Mode On");
		else
			SC.show_events = nil;
			SC.Print("show_events Mode Off");
		end
	elseif args[1] == 'show_setup' then
		if SC.show_setup == nil then
			SC.show_setup = 1;
			SC.Print("show_setup Mode On");
		else
			SC.show_setup = nil;
			SC.Print("show_setup Mode Off");
		end
	elseif args[1] == 'week' then
		SC.Print(SC.WeekStart());
	elseif args[1] == 'toons' then
		SC.ToonShow()
	else
		SC.ShowUsage();
	end
end

function SC.OnEvent(event, arg1)
--
-- Handle the events Accountant registered for
--
	local oldmode = SC.mode;
--[
	if SC.show_events then
		SC.Print(
         "show_events "
			..GREEN_FONT_COLOR_CODE.."ev: "
			..event
			.." arg: "
         ..(arg1 or "nyl")
			);
	end
	--]]
	if ( event == "UNIT_NAME_UPDATE" and arg1 == "player" ) 
		or (event=="PLAYER_ENTERING_WORLD") then
		if (SC.got_name) then
			return;
		end
		local playerName = UnitName("player");
		if ( playerName ~= UNKNOWNBEING 
			and playerName ~= UNKNOWNOBJECT 
			and playerName ~= nil ) then
			if SC.show_start then
				SC.Print("setup: init start"); 
			end
			SC.got_name = true;
			SC.OnLoad();
			SC.Button_Init();
			SC.Button_UpdatePosition();
			-- init the data broker 'button'
			SC:LDB_Init()
			SC:LDB_Update()
			-- Create the options structures
			SC.InitOptions()
			if SC.show_start then
				SC.Print("setup: init end"); 
			end
		end
		return;
	end
	if ( event == "PLAYER_LEAVING_WORLD") then
		-- save the current tab for next login
		Accountant_SaveData[Accountant.player]["options"]["current_tab"] = 
			SC.current_tab
		Accountant_SaveData[Accountant.player]["options"]["show_toons"] = 
			SC.show_toons
		return;
	end
	if event == "MERCHANT_SHOW" then
		SC.mode = "MERCH";
		SC.repair_money = GetMoney();
		SC.could_repair = CanMerchantRepair();
        -- if merchant can repair set up variables so we can track repairs
		if ( SC.could_repair ) then
			SC.repair_cost, SC.can_repair = GetRepairAllCost();
        else
        end
	elseif event == "MERCHANT_CLOSED" then
		SC.mode = "";
		Account_RepairCost = 0;
	elseif event == "MERCHANT_UPDATE" then
		-- Could have bought something before or after repair
		SC.repair_money = GetMoney();
	elseif event == "UPDATE_INVENTORY_DURABILITY" then
        if ( SC.could_repair and SC.repair_cost > 0 ) then
			local cash = GetMoney();
			if ( SC.repair_money > cash ) then
				-- most likely this is a repair bill
				local tmpMode = SC.mode;
				SC.mode = "REPAIRS";
				SC.UpdateLog();
				SC.mode = tmpMode;
				-- a single item could have been repaired
				SC.repair_money = cash;
				-- reset the repair cost for the next repair
				SC.repair_cost, SC.can_repair = GetRepairAllCost();
--				DEFAULT_CHAT_FRAME:AddMessage(" ACC dura-2: "
--					..SC.repair_cost.." : ");
			end				
		end
	elseif event == "TAXIMAP_OPENED" then
		SC.mode = "TAXI";
	elseif event == "TAXIMAP_CLOSED" then
		-- Commented out due to taximap closing before money transaction
		-- SC.mode = "";
	elseif event == "LOOT_OPENED" then
		SC.mode = "LOOT";
	elseif event == "LOOT_CLOSED" then
		-- Commented out due to loot window closing before money transaction
		-- SC.mode = "";
	elseif event == "TRADE_SHOW" then
		SC.mode = "TRADE";
	elseif event == "TRADE_CLOSE" then
		SC.mode = "";
	elseif event == "QUEST_COMPLETE" then
		SC.mode = "QUEST";
	elseif event == "QUEST_FINISHED" then
		-- Commented out due to quest window closing before money transaction
		-- SC.mode = "";
	elseif event == "MAIL_SHOW" then
		SC.mode = "MAIL";
--		SC.show_events = true
	elseif event == "MAIL_INBOX_UPDATE" then
--	SC.Print("Accountant: event"
--		..event
--		.." mode '"..SC.mode.."'"); 
		-- !! IMPORTANT - Still need to check if the BLack market sends different messages. yes/no
		-- !! Find out a way to keep Black market and AH refunds in different boxes.
		-- Quel's fix: when we open a mail message, see if this is a successfull Auction. 
		if (nil ~= InboxFrame.openMailID) then
			a, b, sender, subject, money = GetInboxHeaderInfo(InboxFrame.openMailID);
			if (nil ~= sender) then
				if (string.find(subject, ACCLOC_AUCTION_SUCC) ~= nil) then
					SC.mode="AH";
--					SC.Print("Accountant: Auction successful"); 
				elseif (string.find (subject, ACCLOC_AUCTION_OUTBID) ~= nil) then
					SC.mode="IGNORE";
					SC.refund_mode="AH";
					SC.sender = Accountant.player;
				end
			end
		end
	elseif event == "MAIL_CLOSED" then
		SC.mode = "";
--		SC.show_events = false
	elseif event == "TRAINER_SHOW" then
		SC.mode = "TRAIN";
	elseif event == "TRAINER_CLOSED" then
		SC.mode = "";
	elseif event == "AUCTION_HOUSE_SHOW" then
		SC.mode = "AH";
		
	elseif event == "AUCTION_HOUSE_CLOSED" then
		SC.mode = "";
	elseif event == "BLACK_MARKET_OPEN" then
		SC.mode = "BMAH";
		--debug
		--DEFAULT_CHAT_FRAME:AddMessage("Ding, something works!");
	elseif event == "BLACK_MARKET_CLOSE" then
		SC.mode = "";
		--debug
		--DEFAULT_CHAT_FRAME:AddMessage("Ding, something works again.!");
	elseif event == "PLAYER_MONEY" then
		SC.UpdateLog();
		SC:LDB_Update()
	end
	if SC.verbose and SC.mode ~= oldmode then 
        SC.Print("Accountant mode changed to '"..SC.mode.."'"); 
    end
end

function SC.NiceCash(value, show_zero, show_neg)
--
-- Take the 'amount' of gold and make it into a nice, colorful string
-- of g s c (gold silver copper)
--
	local neg1 = ""
	local neg2 = ""
	local agold = 10000;
	local asilver = 100;
	local outstr = "";
	local gold = 0;
	local gold_str = ""
	local gc = "|cFFFFFF00"
	local silver = 0;
	local silver_str = ""
	local sc = "|cFFCCCCCC"
	local copper = 0;
	local copper_str = ""
	local cc = "|cFFFF6600"
	local amount = (value or 0)
	local cash = (amount or 0)

	if show_neg then
		if amount < 0 then
			neg1 = "|cFFFF6600" .."("..FONT_COLOR_CODE_CLOSE
			neg2 = "|cFFFF6600" ..")"..FONT_COLOR_CODE_CLOSE
		else
			neg2 = " " -- need to pad for other negative numbers
		end
	end
	if amount < 0 then
		amount = amount * -1
	end
	
	if amount == 0 then
		if show_zero then
			copper_str = cc..(amount or "?").."c"..FONT_COLOR_CODE_CLOSE
		end
	elseif amount > 0 then
		-- figure out the gold - silver - copper components
		gold = (math.floor(amount / agold) or 0)
		amount = amount - (gold * agold);
		silver = (math.floor(amount / asilver) or 0)
		copper = amount - (silver * asilver)
		-- now make them line up in a column
		if gold > 0 then
			gold_str = gc..(gold or "?").."g "..FONT_COLOR_CODE_CLOSE
			silver_str = sc..(string.format("%02d", silver) or "?").."s "..FONT_COLOR_CODE_CLOSE
			copper_str = cc..(string.format("%02d", copper) or "?").."c"..FONT_COLOR_CODE_CLOSE
		elseif (silver > 0) then
			silver_str = sc..(silver or "?").."s "..FONT_COLOR_CODE_CLOSE
			copper_str = cc..(string.format("%02d", copper) or "?").."c"..FONT_COLOR_CODE_CLOSE
		elseif (copper > 0) then
			copper_str = cc..(copper or "?").."c"..FONT_COLOR_CODE_CLOSE
		end
	end
	
	-- build the return string
	outstr = outstr
		..neg1
		..gold_str
		..silver_str
		..copper_str
		..neg2
--[[
SC.Print("Acc cash:"
..(gold or "?").."g "
..(silver or "?").."s "
..(copper or "?").."c "
..(outstr or "?")
);
--]]
	return outstr, cash, gold, silver, copper
end

function SC.WeekStart()
--
-- Find and return the chosen week start
--
	oneday = 86400;
	ct = time();
	dt = date("*t",ct);
	thisDay = dt["wday"];
	while thisDay ~= Accountant_SaveData[Accountant.player]["options"].weekstart do
		ct = ct - oneday;
		dt = date("*t",ct);
		thisDay = dt["wday"];
	end
	cdate = date(nil,ct);
	return string.sub(cdate,0,8);
end

function SC.GetDetailForToons(mode, for_display)
--
-- get the detail of user selected toons for the requested mode
--
	local TotalRowIn
	local TotalRowOut
	local TotalIn = 0
	local TotalOut = 0

    for key,value in next,SC.data do
        TotalRowIn = 0;
        TotalRowOut = 0;

        for player in next,Accountant_SaveData do
            -- Find the one player or all players of the faction(s) requested
            faction = Accountant_SaveData[player]["options"]["faction"]
            if (MatchRealm(player, SC.Realm) ~= nil)
               and (( (faction == ACCLOC_ALLIANCE) 
                     and (SC.ShowAlliance == true) )
                  or ( (faction == ACCLOC_HORDE) 
                     and (SC.ShowHorde == true) ))
               and ( SC.show_toons == player
                  or SC.show_toons == SC.AllDropdown ) then
               TotalRowIn = TotalRowIn + Accountant_SaveData[player]["data"][key][mode].In;

               TotalRowOut = TotalRowOut + Accountant_SaveData[player]["data"][key][mode].Out;
            end
        end

        TotalIn = TotalIn + TotalRowIn;
        TotalOut = TotalOut + TotalRowOut;

        if for_display then
            row = getglobal("AccountantFrameRow" ..SC.data[key].InPos.."In");
            row:SetText(SC.NiceCash(TotalRowIn, false, false));

            row = getglobal("AccountantFrameRow" ..SC.data[key].InPos.."Out");
            row:SetText(SC.NiceCash(TotalRowOut, false, false));
        end
    end
    
    return TotalIn, TotalOut
end

function SC.GetCashForToons()
--
-- get the net balance of user selected toons
--
	local faction = ""
	local cachebox = 0
	local alltotal = 0

   -- collect the total for the toon(s) selected
    for player in next,Accountant_SaveData do
		faction = Accountant_SaveData[player]["options"]["faction"]
		if (MatchRealm(player, SC.Realm) ~= nil)
		and (( (faction == ACCLOC_ALLIANCE) 
            and (SC.ShowAlliance == true) )
        or ( (faction == ACCLOC_HORDE) 
            and (SC.ShowHorde == true) ))
		and ( SC.show_toons == player
         or SC.show_toons == SC.AllDropdown ) then
				-- cachebox may not exist if the user has not logged onto the toon yet
				cachebox = (Accountant_SaveData[player]["options"]["cachebox"] or 0) 
			alltotal = alltotal 
				+ Accountant_SaveData[player]["options"]["totalcash"] - cachebox
		end
	end
    
    return alltotal
end

function SC.GetCashForAllToons(for_display)
--
-- get the total cash for all toons
--
	local i=1;
	local alltotal = 0
	local total = 0
	local cachebox = 0
	
	for char,charvalue in next,Accountant_SaveData do
		-- Find all players of the faction(s) requested
		faction = Accountant_SaveData[char]["options"]["faction"]
		if faction then
		else
			faction = "not set"
		end
		if (MatchRealm(char, SC.Realm) ~= nil)
			and (( (faction == ACCLOC_ALLIANCE) 
					and (SC.ShowAlliance == true) )
				or ( (faction == ACCLOC_HORDE) 
					and (SC.ShowHorde == true) ))
		then
			str_pos = strfind(char, SC.DIVIDER)
			strtmp = strsub(char, str_pos+1) -- remove the realm and dash
			if for_display then
			   getglobal("AccountantFrameRow" ..i.."Title"):SetText(strtmp);
			end
			if Accountant_SaveData[char]["options"]["totalcash"] ~= nil then
					-- poss cachebox does not exist if the user has not logged onto the toon yet
					cachebox = (Accountant_SaveData[char]["options"]["cachebox"] or 0) 
				total = Accountant_SaveData[char]["options"]["totalcash"] - cachebox
				alltotal = alltotal + total
				if for_display then
					getglobal("AccountantFrameRow" ..i.."In"):SetText(
						SC.NiceCash(total, false, false));
					getglobal("AccountantFrameRow" ..i.."Out"):SetText(
						Accountant_SaveData[char]["options"]["date"]);
				end
			else
				if for_display then
					getglobal("AccountantFrameRow" ..i.."In"):SetText("Unknown");
				end
			end
			i=i+1;
			if i > SC.MaxRows then
				SC.Print("ERROR: Too many characters saved. Please delete some in options!! ")
				return 0 -- we really have no idea what the real values is...
			end
		end
	end
	   
	return alltotal
end

function SC.ShowValues()
--
-- Set the Accountant values based on the user selection
--
	local str_pos
	local strtmp = "<nyl>"
	local tmpstr1 = "<nyl>"
	local tmpstr2 = "<nyl>"
	local tmpstr3 = "<nyl>"
	local diff = 0
	
	-- charachter totals
	local alltotal;
	
	-- Make sure we start fresh
	alltotal = 0;

	SC.SetLabels();
	if SC.current_tab ~= 5 then
		TotalIn = 0;
		TotalOut = 0;
--		mode = SC.log_modes[SC.current_tab];

		TotalIn, TotalOut = SC.GetDetailForToons(SC.log_modes[SC.current_tab], true)
		diff = (TotalOut-TotalIn or 0);

		AccountantFrameTotalInValue:SetText(SC.NiceCash(TotalIn, true, false));
		AccountantFrameTotalOutValue:SetText(SC.NiceCash(TotalOut, true, false));
		AccountantFrameTotalFlowValue:SetText(SC.NiceCash(diff, true, false))
		
		if diff > 0 then
			AccountantFrameTotalFlow:SetText("|cFFFF3333"..ACCLOC_NETLOSS..":");
		elseif diff < 0 then
			AccountantFrameTotalFlow:SetText("|cFF00FF00"..ACCLOC_NETPROF..":");
		else
			AccountantFrameTotalFlow:SetText(ACCLOC_NET);
		end
		
		alltotal = SC.GetCashForToons()
	else
		alltotal = SC.GetCashForAllToons(true)
	end
--	SetPortraitTexture(AccountantFramePortrait, "player");

	if (SC.show_toons == SC.AllDropdown) or (SC.current_tab == 5) then
		SC.CacheSetCopper(0)
		AccountantFrameCacheAmount:Hide()
		AccountantFrameCacheUpdate:Hide()
	else
		SC.CacheSetCopper((Accountant_SaveData[SC.show_toons]["options"].cachebox or 0))
		AccountantFrameCacheAmount:Show()
		AccountantFrameCacheUpdate:Show()
	end

	if SC.current_tab == 3 then
		AccountantFrameExtra:SetText(ACCLOC_WEEKSTART..":");
		AccountantFrameExtraValue:SetText(Accountant_SaveData[Accountant.player]["options"]["dateweek"]);
	else
		AccountantFrameExtra:SetText("");
		AccountantFrameExtraValue:SetText("");
	end

	local cash = SC.NiceCash(alltotal, true, true)
	AccountantFrameMoneyTotal:SetText(cash);

	PanelTemplates_SetTab(AccountantFrame, SC.current_tab);
end

function SC.OnShow()
--
-- Show the Accountant window on request
--
	SC.ShowValues()
	SC.LDB_Update()
end

function SC.OnHide()
	if MYADDONS_ACTIVE_OPTIONSFRAME == this then
		ShowUIPanel(myAddOnsFrame);
	end
end

function SC.Print(msg)
--
-- Accountant print - debug or user requested info
--
--	DEFAULT_CHAT_FRAME:AddMessage(format("Accountant: "..msg));
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00".."Acc: "..FONT_COLOR_CODE_CLOSE..msg);
end

function SC.Print2(msg)
--
-- Accountant print used mainly for debug
--
	ChatFrame4:AddMessage(format("Accountant: "..msg));
end

function SC.UpdateLog()
--
-- Update the Accountant data based on the current Accountant mode
-- The mode sets the category of gold income or expense shown in 
-- the Accountant window
--
	SC.current_money = GetMoney();
	Accountant_SaveData[Accountant.player]["options"].totalcash = SC.current_money;
	diff = SC.current_money - SC.last_money;
	SC.last_money = SC.current_money;
	if diff == 0 or diff == nil then
		return;
	end		

	local mode = SC.mode;
	if mode == "" then mode = "OTHER"; end

	-- Quel's mod: ignore cash transfers between the player's characters
	if (SC.mode ~= "IGNORE") then
		if diff >0 then
			for key,logmode in next,SC.log_modes do
				SC.data[mode][logmode].In = SC.data[mode][logmode].In + diff;
				Accountant_SaveData[Accountant.player]["data"][mode][logmode].In = SC.data[mode][logmode].In;
			end
			if SC.verbose then SC.Print("Gained "..SC.NiceCash(diff, false, false).." from "..mode); end

		elseif diff < 0 then
			diff = diff * -1;
			for key,logmode in next,SC.log_modes do
				SC.data[mode][logmode].Out = SC.data[mode][logmode].Out + diff;
				Accountant_SaveData[Accountant.player]["data"][mode][logmode].Out = SC.data[mode][logmode].Out;
			end
			if SC.verbose then SC.Print("Lost "..SC.NiceCash(diff, false, false).." from "..mode); end
		end
	else
		if (SC.refund_mode == "AH") then
			postage = 0;
		else
			postage = 30;
		end

		-- if xfer between the player's chars or outbid auction back to the sender's totals
		for key,logmode in next,SC.log_modes do
			Accountant_SaveData[SC.sender]["data"][SC.refund_mode][logmode].Out = Accountant_SaveData[SC.sender]["data"][SC.refund_mode][logmode].Out - (diff - postage);
			if (Accountant_SaveData[SC.sender]["data"][SC.refund_mode][logmode].Out < 0) then
				Accountant_SaveData[SC.sender]["data"][SC.refund_mode][logmode].Out = 0;
			end
		end

			if SC.verbose then 
				SC.Print("IGNORE: "..SC.NiceCash(diff, false, false)
					.." mode = "..SC.refund_mode .." refundee = "..SC.sender);
			end
		end

	if AccountantFrame:IsVisible() then
		SC.OnShow();
	end
end

function SC.UpdateOther(old_gold, new_gold)
--
-- Update the Accountant data based on the current gold versus the last saved gold
--
	diff = new_gold - old_gold;
	if diff == 0 or diff == nil then
		return;
	end		

	local mode = "OTHER"
	local out_str = " since last session."
	if diff >0 then
		for key,logmode in next,SC.log_modes do
			if logmode ~= "Session" then
				SC.data[mode][logmode].In = SC.data[mode][logmode].In + diff;
				Accountant_SaveData[Accountant.player]["data"][mode][logmode].In = SC.data[mode][logmode].In;
			end
		end
		SC.Print(_G["GREEN_FONT_COLOR_CODE"].."Gained ".._G["FONT_COLOR_CODE_CLOSE"]
			..SC.NiceCash(diff, false, false)..out_str)

	elseif diff < 0 then
		diff = diff * -1;
		for key,logmode in next,SC.log_modes do
			if logmode ~= "Session" then
				SC.data[mode][logmode].Out = SC.data[mode][logmode].Out + diff;
				Accountant_SaveData[Accountant.player]["data"][mode][logmode].Out = SC.data[mode][logmode].Out;
			end
		end
		SC.Print(_G["RED_FONT_COLOR_CODE"].."Lost ".._G["FONT_COLOR_CODE_CLOSE"]
			..SC.NiceCash(diff, false, false)..out_str)
	end

	-- should only be on login but just in case we start using it elsewhere
	if AccountantFrame:IsVisible() then
		SC.OnShow();
	end
end

function SC.Tab_OnClick(self)
--
-- Switch tabs on the Accountant window on user request (click)
--
	PanelTemplates_SetTab(AccountantFrame, self:GetID());
	SC.current_tab = self:GetID();
	PlaySound("igCharacterInfoTab");
	SC.OnShow();
end

function SC.ShowTotalLDB()
--
-- show or hide the total on the LDB button based on the user selection
-- for that character.
--
	if(Accountant_SaveData[SC.Button_makename()]["options"].showtotal) then
		Accountant_SaveData[SC.Button_makename()]["options"].showtotal = false
	else
		Accountant_SaveData[SC.Button_makename()]["options"].showtotal = true
	end
	SC:LDB_Update()
end

--
-- This routime is used by Titan Panel Accountant.
-- Others are welcome to use it as well.
--
-- logmode = the mode from log_modes.
--   session, week, ...
-- all_t0ons = is a boolean to return the gold 
--   of the character being played
--   or all characters on the server the user is logged into
--
-- <return> = is a string consisting of
--    <logmode> - the shortened version from log_modes_short
--    <gold> - output of NiceNetCash
--
function Accountant_GetCurrentBal(logmode, all_toons)
   local TotalIn = 0
   local TotalOut = 0
   local mode = "<nyl>"
   
   if SC.current_tab ~= 5 then
      TotalIn, TotalOut = 
       SC.GetDetailForToons(SC.log_modes[SC.current_tab], false)
      cash = TotalIn-TotalOut
      mode = SC.log_modes_short[SC.current_tab]
   else
      cash = SC.GetCashForAllToons(false)
      mode = ACCLOC_CHARS
   end
	return  
	   "|cFFFFFF00"..mode..FONT_COLOR_CODE_CLOSE
      .." "..SC.NiceCash(cash, true, true)
end

