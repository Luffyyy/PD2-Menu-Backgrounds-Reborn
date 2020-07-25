local r = table.remove(string.split(RequiredScript, '/'))
local disabled = MenuBGs.Options:GetValue("DisabledMenus")

if r == "hudblackscreen" then
    Hooks:PostHook(HUDBlackScreen, "init", "MenuBgsInit", function(self)
        MenuBGs:Add(self._blackscreen_panel, "blackscreen")
    end)
elseif r == "crimenetmanager" then
    if disabled["crimenet"] then
        return
    end
    Hooks:PostHook(CrimeNetGui, "init", "MenuBgsInit", function(self)
        MenuBGs:Add(self._fullscreen_panel:panel({valign = "scale", halign = "scale"}), "crimenet")
        self._fullscreen_panel:child("vignette"):hide()
        self._fullscreen_panel:child("bd_light"):hide()
        self._fullscreen_panel:child("blur_top"):hide()
        self._fullscreen_panel:child("blur_right"):hide()
        self._fullscreen_panel:child("blur_bottom"):hide()
        self._fullscreen_panel:child("blur_left"):hide()
        self._map_panel:child("map"):set_alpha(0)
        for _, child in pairs(self._panel:children()) do
            if CoreClass.type_name(child) == "Rect" and child:color() == tweak_data.screen_colors.crimenet_lines then
                child:hide()
            end
        end
    end)

    Hooks:PostHook(CrimeNetGui, "_create_polylines", "MenuBgsRemovePolyLines", function(self, o, x, y)
        if self._region_panel then
            for _, child in pairs(self._region_panel:children()) do
                child:hide()
            end
        end
    end)
elseif r == "ingamewaitingforplayers" then
    if disabled["blackscreen"] then
        Hooks:PreHook(IngameWaitingForPlayersState, "at_enter", "MenuBgsAtEnter", function(self)
            if not managers.hud:exists(self.LEVEL_INTRO_GUI) then
                managers.hud:load_hud(self.LEVEL_INTRO_GUI, false, false, false, {})
            end
        end)
    end
elseif r == "menumanager" then
    local plt = MenuComponentManager.play_transition
    function MenuComponentManager:play_transition(...)
        if MenuBGs.Options:GetValue("FadeToBlack") then
            plt(self, ...)
        end
    end
elseif r == "menubackdropgui" then
    function MenuBackdropGUI:set_background(menu)
        if disabled[menu] then
            return
        end
        for _, child in pairs(self._panel:children()) do
            child:hide()
            child:set_alpha(0)
        end
        self._panel:child("item_background_layer"):show()
        self._panel:child("item_background_layer"):set_alpha(1)
        self._panel:child("item_foreground_layer"):show()
        self._panel:child("item_foreground_layer"):set_alpha(1)
        MenuBGs:Add(self._panel, menu)
    end
elseif r == "hudstageendscreen" then
    if disabled["endscreen"] then
        return
    end

    Hooks:PostHook(HUDStageEndScreen, "init", "MenuBGsInit", function(self)
        self._backdrop:set_background("endscreen")
    end)

    function HUDStageEndScreen:spawn_animation()
        self:_wait_for_video()
    end

    function HUDStageEndScreen:_wait_for_video()
        local video = self._background_layer_full:child("money_video")
        video:parent():remove(video)
    end
elseif r == "hudmissionbriefing" then
    if disabled["briefing"] then
        return
    end

    Hooks:PostHook(HUDMissionBriefing, "init", "MenuBGsInit", function(self)
        self._backdrop:set_background("briefing")
        if alive(self._background_layer_two) and alive(self._background_layer_two:child("panel")) then
            self._background_layer_two:child("panel"):hide()
        end
    end)
elseif r == "hudlootscreen" then
    if disabled["loot"] then
        return
    end
    Hooks:PostHook(HUDLootScreen, "init", "MenuBGsInit", function(self)
        self._backdrop:set_background("loot")
    end)

    Hooks:PostHook(HUDLootScreen, "show", "MenuBGsShow", function(self)
        if alive(self._video) then
            self._video:hide()
        end
    end)
elseif r == "menuscenemanager" then
    Hooks:PostHook(MenuSceneManager, "update", "MenuBGsUpdate", function(self)
        if self._camera_object then
            self._camera_object:set_fov(50 + math.min(0, self._fov_mod or 0))
        end
        local cam = managers.viewport:get_current_camera()
        if type(cam) == "boolean" then
            return
        end
        local w,h = 1600, 900
        local a,b,c = cam:position() - Vector3(0, -486.5, 449.5):rotate_with(cam:rotation()) , Vector3(0, w, 0):rotate_with(cam:rotation()) , Vector3(0, 0, h):rotate_with(cam:rotation())
        if alive(self._menu_bg_ws) then
            self._menu_bg_ws:set_world(w,h,a,b,c)
            if self._shaker then
                self._shaker:stop_all()
            end
            managers.environment_controller:set_default_color_grading("color_off") --Remove this line if you wish the mod to not remove color grading.
            managers.environment_controller:refresh_render_settings()
        else
            self._menu_bg_ws = World:newgui():create_world_workspace(w,h,a,b,c)
            self._menu_bg_ws:set_billboard(Workspace.BILLBOARD_BOTH)
            self._bg_unit:effect_spawner(Idstring("e_money")):set_enabled(false)
            managers.environment_controller._vp:vp():set_post_processor_effect("World", Idstring("bloom_combine_post_processor"), Idstring("bloom_combine_empty"))
        end
        self:SetBackground()
    end)

    function MenuSceneManager:SetUnwantedVisible(visible)
        local unwanted = {
            "units/menu/menu_scene/menu_cylinder",
            "units/menu/menu_scene/menu_smokecylinder1",
            "units/menu/menu_scene/menu_smokecylinder2",
            "units/menu/menu_scene/menu_smokecylinder3",
            "units/menu/menu_scene/menu_cylinder_pattern",
            "units/menu/menu_scene/menu_cylinder_pattern",
            "units/menu/menu_scene/menu_logo",
            "units/pd2_dlc_shiny/menu_showcase/menu_showcase",
            "units/payday2_cash/safe_room/cash_int_safehouse_saferoom",
        }
        for k, unit in pairs(World:find_units_quick("all")) do
            for _, unit_name in pairs(unwanted) do
                if unit:name() == Idstring(unit_name) then
                    unit:set_visible(visible)
                end
            end
        end
    end

    function MenuSceneManager:RefreshBackground()
        self._last_bg = nil
    end

    function MenuSceneManager:SetBackground()
        if self._last_bg == self._current_scene_template then
            return
        end
        if alive(self._menu_bg_ws:panel():child("bg")) then
            self._menu_bg_ws:panel():remove(self._menu_bg_ws:panel():child("bg"))
        end
        self._last_bg = self._current_scene_template
        local enabled = MenuBGs.Options[self._last_bg]
        self:SetUnwantedVisible(not enabled)
        if enabled then
            local panel = self._menu_bg_ws:panel():panel({
                name = "bg",
                w = 1600,
                h = 900,
                layer = 2000000
            })
            MenuBGs:Add(panel, self._last_bg)
        end
    end
end