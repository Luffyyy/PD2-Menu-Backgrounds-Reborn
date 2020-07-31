local TEXTURE_IDS = Idstring("texture")
local MOVIE_IDS = Idstring("movie")
local BG_TYPES = {
	["png"] = true,
	["dds"] = true,
	["texture"] = true,
	["tag"] = true,
	["movie"] = true,
	["bik"] = true,
}

function MenuBGs:Init()
	self.sets = {}
	self.default_set = Path:CombineDir(self.ModPath, "Backgrounds")
	self.files = {}
	self.updaters = {}

	Hooks:Add("BeardLibFrameworksFoldersLoop", "LoadCustomBackgrounds", function(framework, folder)
		local path = Path:CombineDir(framework._directory, folder, "menu_backgrounds")
		local FileManager = BeardLib.Managers.File
		if FileIO:Exists(backgrounds) then
			self.sets[folder] = path
		end
	end)
end


function MenuBGs:LoadSets()
	self.Sets = {}
	for _, set in pairs(SystemFS:list(self.AssetsPath, true)) do
		table.insert(self.Sets, set)
	end
end

function MenuBGs:LoadTextures()
	self._files = {}

	local current_set = self.sets[self.Options:GetValue("set")] or self.default_set

	for _, file in pairs(FileIO:GetFiles(current_set)) do
		local file_split = string.split(file, "[.]")
		local file_name = file_split[1]
		local typ = file_split[2]
		if (BG_TYPES[typ]) then
			local ingame_path = Path:Combine("menu_backgrounds", file_name)
			self._files[file_name] = ingame_path
			FileManager:AddFile((typ == "movie" or type == "bik") and MOVIE_IDS or TEXTURE_IDS, Idstring(ingame_path), Path:Combine(backgrounds, file))
		end
	end

	if managers.menu_scene then
		managers.menu_scene:RefreshBackground()
	end
end

function MenuBGs:AddUpdate(pnl, bg)
	self.Updaters[pnl] = bg
end

function MenuBGs:Add(pnl, bg)
	if not alive(pnl) then
		return false
	end
	if alive(pnl:child("bg_mod")) then
		pnl:remove(pnl:child("bg_mod"))
	end
	local _bg = bg
	bg = "guis/textures/backgrounds/" .. (self.Options:GetValue("UseStandard") and "standard" or bg)
	if not SystemFS:exists(self._files[bg]) then
		bg = "guis/textures/backgrounds/standard"
	end
	local f = self._files
	if f and f[bg] and f[bg]:match(".movie") and SystemFS:exists(f[bg]) then
		pnl:video({
			name = "bg_mod",
			video = bg,
			valign = "scale",
			halign = "scale",
			loop = true,
			layer = 1
		})
	else
		pnl:bitmap({
		    name = "bg_mod",
			valign = "scale",
			halign = "scale",
		    texture = bg,
		    layer = 1
		})
    end

	self:AddUpdate(pnl, _bg)
	return true
end

function MenuBGs:UpdateSetsItem()
	local item = managers.menu:active_menu().logic:get_item("BGsSet")
	if item then
		item:clear_options()
		for k, set in pairs(self.Sets) do
			table.insert(item._all_options, CoreMenuItemOption.ItemOption:new({value = set, text_id = set, localize = false}))
		end
		item._options = item._all_options

		local set = self.Options:GetValue("Set")

		if not table.contains(self.Sets, set) then
			item:set_value(self.Sets[1])
			MenuCallbackHandler:MenuBgsClbk(item)
		else
			item:set_value(set)
		end
	end
end

function MenuBGs:Update()
	self:LoadSets()
	self:UpdateSetsItem()
	self:LoadTextures()
	for pnl, bg in pairs(self.Updaters) do
		if not self:AddBackground(pnl, bg) then
			table.delete(self.Updaters, bg)
		end
	end
end

Hooks:PostHook(MenuManager, "_node_selected1", "MenuBGsNodeSelected", function(this, name, node)
	if node and node:parameters().menu_id == self.OptMenuId then
		self:UpdateSetsItem()
	end
end)

Hooks:Add("MenuManagerPopulateCustomMenus1", "MenuManagerPopulateCustomMenusMenuBGs", function(this, nodes)
	World:effect_manager():set_rendering_enabled(Global.load_level)
	self:Load()
	self:load_sets()
	self:load_textures()
 	function MenuCallbackHandler:MenuBgsClbk(item)
		MenuBGs.Options.BGsSet = item:value()
		MenuBGs:Save()
		MenuBGs:Update()
    end
	function MenuCallbackHandler:MenuBgsToggleClbk(item)
		MenuBGs.Options[item._parameters.name] = item:value() == "on"
		MenuBGs:Save()
	end
	function MenuCallbackHandler:MenuBgsRefresh(item) MenuBGs:Update() end
	local menus = {
		"standard",
		"inventory",
		"blackmarket",
		"blackmarket_crafting",
		"blackmarket_mask",
		"blackmarket_item",
		"blackmarket_customize",
		"blackmarket_screenshot",
		"blackmarket_armor",
		"crime_spree_lobby",
		"lobby",
		"safe",
		"crimenet",
		"briefing",
		"blackscreen",
		"endscreen",
		"loot"
	}
	local options = {
		{id = "BGsSet", type = "MultipleChoice", items = self.Sets, callback = "MenuBgsClbk"},
		{id = "UseStandard", type = "Toggle", callback = "MenuBgsToggleClbk"},
		{id = "FadeToBlack", type = "Toggle", callback = "MenuBgsToggleClbk"},
		{id = "Refresh", type = "Button", callback = "MenuBgsRefresh"},
	}
	for _, menu in pairs(menus) do
		if self.Options[menu] == nil then self.Options[menu] = true end
		LocalizationManager:add_localized_strings({
			["MenuBgs/"..menu] = menu,
			["MenuBgs/"..menu.."Desc"] = string.format("If enabled this will set the background of the menu '%s' to the selected background set", menu)
		})
		table.insert(options, {id = menu, type = "Toggle", callback = "MenuBgsToggleClbk"})
	end
	for k, v in pairs(options) do
	    MenuHelper["Add" .. v.type](MenuHelper, {
	        id = v.id,
	        title = "MenuBgs/" .. v.id,
	        desc = "MenuBgs/" .. v.id .. "Desc",
	        callback = v.callback,
	        items = v.items,
	        priority = 999 - k,
	        value = self.Options[v.id],
	        menu_id = self.OptMenuId,
	    })
	end
	self:Save()
end)

--Test