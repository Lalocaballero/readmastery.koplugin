-- KOReader userpatch to show info in the file manager title bar
-- based on https://gist.github.com/hius07/c53bc1ed00e0490cb1a0709c5ed6e735#file-2-fm-title-info-lua
-- Menu added in the File browser menu (1st icon) to change all the settings and rearrange the items in the title bar
-- Items added: Custom text, Brightness Level, Warmth Level, Up time, Time spent awake, Time in suspend, ReadMastery
-- Settings added: Auto refresh clock, Custom separator, Number of spaces around separator, Show wifi when disabled, Show frontlight when off, Show path
-- Fix screen rotation (path was disappearing)
-- Arrange items reorders the items the menu

local BD = require("ui/bidi")
local DataStorage = require("datastorage")
local Device = require("device")
local FileManager = require("apps/filemanager/filemanager")
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local Font = require("ui/font")
local InputDialog = require("ui/widget/inputdialog")
local NetworkMgr = require("ui/network/manager")
local SortWidget = require("ui/widget/sortwidget")
local SpinWidget = require("ui/widget/spinwidget")
local UIManager = require("ui/uimanager")
local datetime = require("datetime")
local json = require("json")
local time = require("ui/time")
local T = require("ffi/util").template
local _ = require("gettext")
local Screen = Device.screen

local logger = require("logger")

-- Title bar config
local separators = {
    bar = "|",
    bullet = "•",
    dot = "·",
    en_dash = "-",
    em_dash = "—",
    none = "",
}

local config_default = {
    -- items
    show = {
        wifi = true,
        memory = false,
        storage = false,
        custom_text = false,
        clock = true,
        battery = true,
        frontlight = false,
        frontlight_warmth = false,
        up_time = false,
        awake_time = false,
        suspend_time = false,
        readmastery = false,
    },
    -- items order
    order = {
        "wifi",
        "memory",
        "storage",
        "custom_text",
        "clock",
        "battery",
        "frontlight",
        "frontlight_warmth",
        "up_time",
        "awake_time",
        "suspend_time",
        "readmastery",
    },
    -- settings
    custom_text = "KOReader",
    separator = "dot",
    separator_space = 1,
    separator_custom = "*",
    show_path = true,
    auto_refresh_clock = true,
    wifi_show_disabled = false,
    frontlight_show_off = true,
    bold = false,
}

local function load_and_update_config()
    local config = G_reader_settings:readSetting("filemanager_title_bar", config_default)
    local updated = false

    local function compare_and_update_config(config_to_browse, config_to_compare)
        for setting, setting_value in pairs(config_to_browse) do
            if type(setting_value) ~= "table" then -- only the settings
                if config_to_compare[setting] == nil then -- missing ?
                    updated = true
                    if config_to_compare == config then -- missing in config: add it
                        config[setting] = setting_value
                    else -- missing in config_default: remove it
                        config[setting] = nil
                    end
                end
            end
        end
        for item, item_value in pairs(config_to_browse.show) do
            if config_to_compare.show[item] == nil then -- missing ?
                updated = true
                if config_to_compare == config then -- missing in config: add it
                    config.show[item] = item_value
                    table.insert(config.order, item)
                else -- missing in config_default: remove it
                    config.show[item] = nil
                    for i, _item in ipairs(config.order) do
                        if _item == item then
                            table.remove(config.order, i)
                            break
                        end
                    end
                end
            end
        end
    end

    compare_and_update_config(config, config_default)
    compare_and_update_config(config_default, config)
    if updated then logger.info("Updated title bar config", config) end
    separators.custom = config.separator_custom
    return config
end

local config = load_and_update_config()

-- Title bar update
local genItemText = {
    custom_text = function() return config.custom_text end,
    clock = function()
        return datetime.secondsToHour(os.time(), G_reader_settings:isTrue("twelve_hour_clock"))
    end,
    wifi = function() return NetworkMgr:isWifiOn() and "" or (config.wifi_show_disabled and "") end,
    frontlight_warmth = function()
        if Device:hasNaturalLight() then
            local prefix = "💡"
            local powerd = Device:getPowerDevice()
            if powerd:isFrontlightOn() then
                local warmth = powerd:frontlightWarmth()
                if warmth then return (prefix .. "%d%%"):format(warmth) end
            else
                return config.frontlight_show_off and T(_("%1Off"), prefix)
            end
        end
    end,
    frontlight = function()
        if Device:hasFrontlight() then
            local prefix = "☼"
            local powerd = Device:getPowerDevice()
            if powerd:isFrontlightOn() then
                if Device:isCervantes() or Device:isKobo() then
                    return (prefix .. "%d%%"):format(powerd:frontlightIntensity())
                else
                    return (prefix .. "%d"):format(powerd:frontlightIntensity())
                end
            else
                return config.frontlight_show_off and T(_("%1Off"), prefix)
            end
        end
    end,
    battery = function()
        if Device:hasBattery() then
            local powerd = Device:getPowerDevice()
            local batt_lvl = powerd:getCapacity()
            local batt_symbol = powerd:getBatterySymbol(powerd:isCharged(), powerd:isCharging(), batt_lvl)
            local text = BD.wrap(batt_symbol) .. BD.wrap(batt_lvl .. "%")
            if Device:hasAuxBattery() and powerd:isAuxBatteryConnected() then
                local aux_batt_lvl = powerd:getAuxCapacity()
                local aux_batt_symbol =
                    powerd:getBatterySymbol(powerd:isAuxCharged(), powerd:isAuxCharging(), aux_batt_lvl)
                text = text .. " " .. BD.wrap("+") .. BD.wrap(aux_batt_symbol) .. BD.wrap(aux_batt_lvl .. "%")
            end
            return text
        end
    end,
    up_time = function(self)
        local SystemStat = self:_getSystemStat()
        if SystemStat then
            local uptime = time.boottime_or_realtime_coarse() - SystemStat.start_monotonic_time
            return "⏻" .. datetime.secondsToClockDuration("modern", time.to_s(uptime), true, false, true) -- ⏽
        end
    end,
    awake_time = function(self)
        local SystemStat = self:_getSystemStat()
        if SystemStat and (Device:canSuspend() or Device:canStandby()) then
            local uptime = time.boottime_or_realtime_coarse() - SystemStat.start_monotonic_time
            local suspend = Device:canSuspend() and Device.total_suspend_time or 0
            local standby = Device:canStandby() and Device.total_standby_time or 0
            local awake = uptime - suspend - standby
            return "☀️" .. datetime.secondsToClockDuration("modern", time.to_s(awake), true, false, true) -- ☀☉⚡☀️
        end
    end,
    suspend_time = function(self)
        local SystemStat = self:_getSystemStat()
        if SystemStat and Device:canSuspend() then
            local suspend = Device.total_suspend_time
            return "⏾" .. datetime.secondsToClockDuration("modern", time.to_s(suspend), true, false, true) -- ⏾💤😴⏸️
        end
    end,
    storage = function(self)
        local SystemStat = self:_getSystemStat()
        if SystemStat then
            SystemStat.kv_pairs = {}
            SystemStat:appendStorageInfo()
            return SystemStat.kv_pairs[3][2] -- available storage
        end
    end,
    memory = function()
        local statm = io.open("/proc/self/statm", "r")
        if statm then
            local _, rss = statm:read("*number", "*number")
            statm:close()
            return rss and ("%d"):format(math.floor(rss / 256))
        end
    end,

    readmastery = function()
        local ok, result = pcall(function()
            local data_file = DataStorage:getDataDir() .. "/readmastery/readmastery_data.json"
            local file = io.open(data_file, "r")
            if file then
                local content = file:read("*all")
                file:close()
                local data = json.decode(content)
                if data then
                    local streak = data.current_streak or 0
                    local level = data.level or 1
                    local format = data.tb_display_format or "streak_level"
                    
                    if format == "streak_only" then
                        return "~" .. streak
                    elseif format == "level_only" then
                        return "Lv" .. level
                    elseif format == "streak_level" then
                        return "~" .. streak .. " Lv" .. level
                    elseif format == "full" then
                        local today = os.date("%Y-%m-%d")
                        local pages = data.daily_pages and data.daily_pages[today] or 0
                        return "~" .. streak .. " Lv" .. level .. " " .. pages .. "pg"
                    else
                        return "~" .. streak .. " Lv" .. level
                    end
                end
            end
            return nil
        end)
        if ok and result then
            return result
        end
        return nil
    end,
}

-- get SystemStat
function FileManager:_getSystemStat()
    if self.systemstat then
        local userpatch = require("userpatch")
        return userpatch.getUpValue(self.systemstat.addToMainMenu, "SystemStat")
    end
end

-- handle close : need to remove schedule update for clock auto refresh
local orig_FileManager_onClose = FileManager.onClose

FileManager.onClose = function(self)
    orig_FileManager_onClose(self)
    UIManager:unschedule(self.updateTitleBarTitle)
end

-- handle screen rotation
local orig_FileManager_onSetRotationMode = FileManager.onSetRotationMode

FileManager.onSetRotationMode = function(self, mode)
    orig_FileManager_onSetRotationMode(self, mode)
    self:updateTitleBarTitle()
end

-- redraw the title bar
function FileManager:updateTitleBarTitle()
    if self.title_bar == nil or self._suspended then return end -- guard when suspended

    local titlebar_texts = {}
    for _, item in ipairs(config.order) do
        if config.show[item] then
            local text = genItemText[item](self)
            if text then table.insert(titlebar_texts, text) end
        end
    end

    -- logger.info("FileManager:updateTitleBarTitle CALLED")
    local font_has_changed
    local not_bold_font = self.title_bar.info_text_face
    if config.bold then
        font_has_changed = self.title_bar.title_face == not_bold_font
    else
        font_has_changed = self.title_bar.title_face ~= not_bold_font
    end
    if font_has_changed then
        if config.bold then
            self.title_bar.title_face = nil
            self.title_bar.bottom_v_padding = self._title_bar_bottom_v_padding_saved
        else
            self.title_bar.title_face = not_bold_font
            self.title_bar.bottom_v_padding = self._title_bar_bottom_v_padding_saved + Screen:scaleBySize(5)
        end
        self.title_bar:clear()
        self.title_bar:init()
    end
    local spaces = string.rep(" ", config.separator_space)
    local seperator = spaces .. (separators[config.separator] or "") .. spaces
    self.title_bar:setTitle(table.concat(titlebar_texts, seperator))

    self:updateTitleBarPath(config.show_path and self._title_bar_path_saved or "")

    -- autorefresh time
    UIManager:unschedule(self.updateTitleBarTitle)
    if config.show.clock and config.auto_refresh_clock then
        UIManager:scheduleIn(61 - tonumber(os.date("%S")), self.updateTitleBarTitle, self)
    end
end

local orig_FileManager_onResume = FileManager.onResume
function FileManager:onResume()
    self._suspended = false
    if orig_FileManager_onResume then orig_FileManager_onResume(self) end
    self:updateTitleBarTitle()
end

local orig_FileManager_onSuspend = FileManager.onSuspend
function FileManager:onSuspend()
    self._suspended = true
    UIManager:unschedule(self.updateTitleBarTitle)
    if orig_FileManager_onSuspend then orig_FileManager_onSuspend(self) end
end

FileManager.onNetworkConnected = FileManager.updateTitleBarTitle
FileManager.onNetworkDisconnected = FileManager.updateTitleBarTitle
FileManager.onCharging = FileManager.updateTitleBarTitle
FileManager.onNotCharging = FileManager.updateTitleBarTitle
FileManager.onTimeFormatChanged = FileManager.updateTitleBarTitle
FileManager.onFrontlightStateChanged = FileManager.updateTitleBarTitle

function FileManager:onPathChanged(path)
    -- logger.info("FileManager:onPathChanged CALLED")
    if not self._title_bar_bottom_v_padding_saved then
        self._title_bar_bottom_v_padding_saved = self.title_bar.bottom_v_padding
    end
    self._title_bar_path_saved = path
    self:updateTitleBarTitle() -- updateTitleBarPath done in updateTitleBarTitle
end

-- Title bar menu
function FileManagerMenu:_title_bar_input_text(touchmenu_instance, title, input, onChanged)
    local text_dialog
    text_dialog = InputDialog:new {
        title = title,
        input = input,
        buttons = {
            {
                {
                    text = _("Cancel"),
                    id = "close",
                    callback = function() UIManager:close(text_dialog) end,
                },
                {
                    text = _("Set"),
                    is_enter_default = true,
                    callback = function()
                        onChanged(text_dialog:getInputText())
                        UIManager:close(text_dialog)
                        touchmenu_instance:updateItems()
                        self.ui:updateTitleBarTitle()
                    end,
                },
            },
        },
    }
    UIManager:show(text_dialog)
    text_dialog:onShowKeyboard()
end

-- Separators
local setting_menu_texts

function FileManagerMenu:_set_title_bar_separator_space(touchmenu_instance)
    local spin_widget = SpinWidget:new {
        title_text = setting_menu_texts.separator_space(true),
        value = config.separator_space,
        value_min = 1,
        value_step = 1,
        value_max = 5,
        callback = function(spin)
            config.separator_space = spin.value
            touchmenu_instance:updateItems()
            self.ui:updateTitleBarTitle()
        end,
    }
    UIManager:show(spin_widget)
end

function FileManagerMenu:_set_title_bar_custom_separator_text(touchmenu_instance)
    self:_title_bar_input_text(
        touchmenu_instance,
        _("Enter a custom separator"),
        separators.custom,
        function(text)
            config.separator_custom = text
            separators.custom = text
        end
    )
end

local separator_menu_texts = {
    dot = _("Dot"),
    bullet = _("Bullet"),
    en_dash = _("En dash"),
    em_dash = _("Em dash"),
    bar = _("Vertical bar"),
    none = _("No separator"),
    custom = function(concise)
        return concise and _("Custom separator") or _("Custom separator (long-press to edit)")
    end,
}

local separators_menu_help_text_funcs = {
    custom = FileManagerMenu._set_title_bar_custom_separator_text,
}

local separators_order = {
    "dot",
    "bullet",
    "en_dash",
    "em_dash",
    "bar",
    "custom",
    "none",
}

local function get_separator_menu_texts(separator, concise)
    text = separator_menu_texts[separator]
    if type(text) == "function" then text = text(concise) end
    local spaces = string.rep(" ", config.separator_space)
    local seperator = separators[config.separator] or ""
    return T(text .. " '" .. spaces .. "%1" .. spaces .. "'", separators[separator])
end

function FileManagerMenu:_get_title_bar_separators_submenu()
    local items = {}
    for _, separator in ipairs(separators_order) do
        local help_text_func = separators_menu_help_text_funcs[separator]
        table.insert(items, {
            text_func = function() return get_separator_menu_texts(separator) end,
            help_text_func = help_text_func
                and function(touchmenu_instance) help_text_func(self, touchmenu_instance) end,
            checked_func = function() return config.separator == separator end,
            callback = function(touchmenu_instance)
                config.separator = separator
                touchmenu_instance:updateItems()
                self.ui:updateTitleBarTitle()
            end,
        })
    end
    items[#items].separator = true
    table.insert(items, {
        text_func = setting_menu_texts.separator_space,
        keep_menu_open = true,
        callback = function(touchmenu_instance) self:_set_title_bar_separator_space(touchmenu_instance) end,
    })
    return items
end

-- items
function FileManagerMenu:_set_title_bar_custom_text(touchmenu_instance)
    self:_title_bar_input_text(
        touchmenu_instance,
        _("Enter a custom text"),
        config.custom_text or "",
        function(text) config.custom_text = text end
    )
end

local item_menu_texts = {
    wifi = _("Wifi"),
    memory = _("Memory"),
    storage = _("Storage"),
    clock = _("Clock"),
    battery = _("Battery"),
    frontlight = _("Brightness level"),
    frontlight_warmth = _("Warmth level"),
    up_time = _("Up time"),
    awake_time = _("Time spent awake"),
    suspend_time = _("Time in suspend"),
    custom_text = function(concise)
        return concise and _("Custom text")
            or T(_("Custom text (long-press to edit): '%1'"), config.custom_text)
    end,
    readmastery = _("ReadMastery (Streak & Level)"),  -- ReadMastery integration
}

local item_menu_help_texts = {
    memory = _("RAM used, MiB"),
    storage = _("Free storage, requires SystemStat plugin"),
    custom_text = FileManagerMenu._set_title_bar_custom_text,
    readmastery = _("Shows streak and level from ReadMastery plugin"),  -- ReadMastery integration
}

function FileManagerMenu:_title_bar_arrange_items(item_table_rebuild)
    return {
        text = _("Arrange title bar items"),
        keep_menu_open = true,
        enabled_func = function()
            local show_count = 0 -- count shown items
            for _, item in ipairs(config.order) do
                show_count = show_count + (config.show[item] and 1 or 0)
                if show_count >= 1 then return true end
            end
            return false
        end,
        callback = function(touchmenu_instance)
            local item_table = {}
            for _, item in ipairs(config.order) do
                local text = item_menu_texts[item]
                table.insert(item_table, {
                    text = type(text) == "function" and text(true) or text,
                    orig_item = item,
                    dim = not config.show[item],
                })
            end
            local sort_item
            sort_item = SortWidget:new {
                title = _("Arrange title bar items"),
                item_table = item_table,
                callback = function()
                    for i, item in ipairs(item_table) do
                        config.order[i] = item.orig_item
                    end
                    if item_table_rebuild then -- rebuild the item_table, so the items in the menu are reordered
                        touchmenu_instance.item_table = item_table_rebuild()
                        touchmenu_instance:updateItems()
                    end
                    self.ui:updateTitleBarTitle()
                    UIManager:setDirty(nil, "ui")
                end,
            }
            UIManager:show(sort_item)
        end,
    }
end

function FileManagerMenu:_get_title_bar_item(item)
    local text = item_menu_texts[item]
    local help_text = item_menu_help_texts[item]
    return {
        text = type(text) == "string" and text,
        text_func = type(text) == "function" and function() return text() end,
        help_text = type(help_text) == "string" and help_text,
        help_text_func = type(help_text) == "function"
            and function(touchmenu_instance) help_text(self, touchmenu_instance) end,
        checked_func = function() return config.show[item] end,
        callback = function(touchmenu_instance)
            config.show[item] = not config.show[item]
            touchmenu_instance:updateItems()
            self.ui:updateTitleBarTitle()
        end,
    }
end

-- settings
setting_menu_texts = { -- already declared above
    auto_refresh_clock = _("Auto refresh clock"),
    show_path = _("Show file browser path"),
    wifi_show_disabled = _("Show wifi status even when disabled"),
    frontlight_show_off = _("Show frontlight when off"),
    bold = _("Bold font"),
    separator = function()
        return T(_("Item separator: %1"), get_separator_menu_texts(config.separator, true))
    end,
    custom_text = function() return T(_("Custom text: '%1'"), config.custom_text) end,
    separator_space = function(concise)
        return concise and _("Number of spaces around separator")
            or T(_("Number of spaces around separator: %1"), config.separator_space)
    end,
}

local setting_menu_callback = {
    custom_text = FileManagerMenu._set_title_bar_custom_text,
    separator_space = FileManagerMenu._set_title_bar_separator_space,
}

local setting_submenu_items = {
    separator = FileManagerMenu._get_title_bar_separators_submenu,
}

local setting_menu_enable_func = {
    auto_refresh_clock = function() return config.show.clock end,
    wifi_show_disabled = function() return config.show.wifi end,
    frontlight_show_off = function() return config.show.frontlight or config.show.frontlight_warmth end,
    custom_text = function() return config.show.custom_text end,
}

local setting_menu_order = {
    "bold",
    "wifi_show_disabled",
    "frontlight_show_off",
    "auto_refresh_clock",
    "show_path",
    "custom_text",
    "separator",
}

function FileManagerMenu:_get_title_bar_setting(setting)
    local text = setting_menu_texts[setting]
    local submenu = setting_submenu_items[setting]
    local enabled_func = setting_menu_enable_func[setting]
    local callback_func = setting_menu_callback[setting]
    return {
        text = type(text) == "string" and text,
        text_func = type(text) == "function" and function() return text() end,
        enabled_func = enabled_func and function() return enabled_func() end,
        checked_func = not (submenu or callback_func) and function() return config[setting] end,
        callback = not submenu and function(touchmenu_instance)
            if callback_func then
                callback_func(self, touchmenu_instance)
            else
                config[setting] = not config[setting]
                touchmenu_instance:updateItems()
            end
            self.ui:updateTitleBarTitle()
        end,
        keep_menu_open = callback_func ~= nil,
        sub_item_table = submenu and submenu(self),
    }
end

-- Patch title bar menu
local FileManagerMenu = require("apps/filemanager/filemanagermenu")
local FileManagerMenuOrder = require("ui/elements/filemanager_menu_order")
local orig_FileManagerMenu_setUpdateItemTable = FileManagerMenu.setUpdateItemTable

function FileManagerMenu:setUpdateItemTable()
    local setting_table = {}
    for _, setting in ipairs(setting_menu_order) do
        table.insert(setting_table, self:_get_title_bar_setting(setting))
    end

    local sub_item_table_func
    sub_item_table_func = function()
        local _table = {
            {
                text = _("Configure title bar"),
                sub_item_table = setting_table,
            },
            self:_title_bar_arrange_items(sub_item_table_func),
        }
        _table[#_table].separator = true
        for _, item in ipairs(config.order) do
            table.insert(_table, self:_get_title_bar_item(item))
        end
        return _table
    end

    table.insert(FileManagerMenuOrder.filemanager_settings, 1, "title_bar")
    self.menu_items.title_bar = {
        text = _("Title bar"),
        separator = true,
        sub_item_table_func = sub_item_table_func,
    }
    orig_FileManagerMenu_setUpdateItemTable(self)
end