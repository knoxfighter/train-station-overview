-- print(serpent.block())

local util = require("util")

-- frames[player.index] = frame
local frames = {}
-- cards[player.index][card.index] = { card = card, train_stop_name = train_stop.backer_name }
local cards = {}
-- buttons[player.index][button.index] = train_stop
local buttons = {}
-- map_buttons[player.index][map_buttons.index] = train_stop
local map_buttons = {}
-- search_boxes[searchButton.index] = textfield
local search_boxes = {}
-- search_buttons[player.index] = search_button
local search_text_fields = {}
-- search_text[player.index] = text
local search_text = {}
-- reload_buttons[player.index] = reload_button
local reload_buttons = {}

function check_station(station)
    if station then
        if station.valid then
            return true
        else
            remove_station(station)
            return false
        end
    else
        return false
    end
end

function remove_station(station)
    local pos = find_train_stop(station)
    if pos == 0 then
        print("train_stop not found, just do nothing!")
        return
    end

    table.remove(global.train_stops, pos)
end

-- returns true if ALL keys are found
function filter_station(player_index, train_stop_name)
    if search_text[player_index] then
        local search_keys = util.split_whitespace(search_text[player_index])
        local backer_name = train_stop_name:lower()

        for _, search_key in pairs(search_keys) do
            if not backer_name:find(search_key:lower(), 1, true) then
                return false
            end
        end
    end
    return true
end

function create_gui(player_index)
    -- get player
    local player = game.get_player(player_index)

    -- define constants
    local preview_size = 160
    local preview_size_half = preview_size / 2

    local name_label_height = 24
    local stop_height = preview_size + name_label_height + 32 + 8 + 16
    local stop_width = preview_size + 152
    local list_width = 112

    local previous_backer_name = ""
    local station_amount_label
    local station_amount = 0
    local bottom_scroll

    local max_columns = ((player.display_resolution.width / player.display_scale) / (stop_width + 50))
    if max_columns < 1 then
        max_columns = 1
    end

    -- create basic gui frame
    local frame = player.gui.screen.add{type = "frame", direction = "vertical", auto_center = true}
    frame.auto_center = true
    local max_height = player.display_resolution.height * 0.8 / player.display_scale

    if max_height > player.display_resolution.height / player.display_scale then
        max_height = (player.display_resolution.height - 10) / player.display_scale
    end
    frame.style.maximal_height = max_height

    -- open frame (this is the gui shown to the player)
    player.opened = frame
    frames[player.index] = frame

    -- header
    local titleFlow = frame.add{type = "flow", direction = "horizontal"}
    titleFlow.drag_target = frame
    titleFlow.style.vertical_align = "center"
    local title = titleFlow.add{type = "label", style = "heading_1_label", caption = {"train-stops"}}
    title.ignored_by_interaction = true
    local amount_label = titleFlow.add{type = "label", caption = {"station-amount", #global.train_stops}}
    amount_label.ignored_by_interaction = true
    local fillerFlow = titleFlow.add{type = "empty-widget", style = "draggable_space_header"}
    fillerFlow.style.horizontally_stretchable = true
    fillerFlow.style.height = 24
    fillerFlow.ignored_by_interaction = true

    --local size_slider = titleFlow.add{type = "slider", minimum_value = 1, maximum_value = max_columns, value = max_columns, value_step = 1, discrete_slider = true, discrete_values = true}
    --size_slider.style.top_margin = 8

    -- search
    local search_text_field = titleFlow.add{ type = "textfield", visible = search_text[player_index] ~= nil, text = search_text[player_index]}
    local search_button = titleFlow.add{ type = "sprite-button", style = "tool_button", sprite = "utility/search_icon", tooltip = { "gui.search"}}
    search_boxes[search_button.index] = search_text_field
    search_text_fields[search_text_field.index] = search_text_field

    local reload_button = titleFlow.add{type = "sprite-button", style = "tool_button", sprite = "train-station-overview-refresh-sprite", tooltip = {"refresh-stations"}}
    reload_buttons[player.index] = reload_button

    if #global.train_stops < 1 then
        frame.add{type = "label", caption = {"no-train-stops"}}
        return
    end

    -- Inner Frame with scrollbar and tableview
    local scroll = frame.add{type = "scroll-pane", direction = "vertical"}
    local tableView = scroll.add{type = "table", column_count = max_columns}

    -- set table spacing
    tableView.style.horizontal_spacing = 4
    tableView.style.vertical_spacing = 4

    for _, train_stop in pairs(global.train_stops) do
        if check_station(train_stop) then
            local position = train_stop.position
            local area = {
                {
                    position.x - preview_size_half,
                    position.y - preview_size_half
                },
                {
                    position.x + preview_size_half,
                    position.y + preview_size_half
                }
            }

            -- create a chart of the area (has no return-value)
            player.force.chart(train_stop.surface, area)

            if previous_backer_name == train_stop.backer_name then
                -- update train amount
                station_amount = station_amount + 1
                station_amount_label.caption = {"station-amount", station_amount}
            else
                ---- Generate new card
                previous_backer_name = train_stop.backer_name
                station_amount = 1
                -- general design
                local card = tableView.add{ type = "frame"}
                card.style.height = stop_height
                card.style.width = stop_width
                card.style.top_padding = 0
                card.style.right_padding = 4
                card.style.bottom_padding = 0
                card.style.left_padding = 4
                card.visible = filter_station(player_index, train_stop.backer_name)

                -- add card to list
                if not cards[player_index] then
                    cards[player_index] = {}
                end
                cards[player_index][card.index] = {}
                cards[player_index][card.index] = { train_stop_name = train_stop.backer_name, card = card}

                -- item flow to control spacing
                local card_flow = card.add{ type = "flow", direction = "vertical"}
                card_flow.style.vertical_spacing = 0

                -- Station name
                local name_label = card_flow.add{ type = "label", caption = train_stop.backer_name}
                name_label.style.horizontally_stretchable = true
                name_label.style.font_color = { 255, 255, 255} --white
                name_label.style.font  = "default-dialog-button"
                name_label.style.horizontally_stretchable = true
                name_label.style.maximal_width = stop_width
                name_label.style.margin = 0
                name_label.style.padding = 0
                name_label.style.height = name_label_height

                -- amount of stations with this name
                station_amount_label = card_flow.add{ type = "label"}
                station_amount_label.caption = {"station-amount", station_amount}
                station_amount_label.style.margin = 0
                station_amount_label.style.padding = 0

                -- amount of trains, that stop at this station
                local train_amount_label = card_flow.add{type = "label"}
                train_amount_label.caption = {"train-amount", #train_stop.get_train_stop_trains()}
                train_amount_label.style.bottom_margin = 5

                local bottom_flow = card_flow.add{type = "flow", direction = "horizontal"}

                -- scroll-pane, when more than 5 stations with this name exist
                local bottom_scroll_pane = bottom_flow.add{type = "scroll-pane"}
                bottom_scroll_pane.style.width = list_width + 20 -- size of scrollbar
                bottom_scroll_pane.style.bottom_margin = 5
                bottom_scroll_pane.style.maximal_height = preview_size
                bottom_scroll_pane.style.extra_padding_when_activated = 0

                -- add flow control to the scroll-pane
                bottom_scroll = bottom_scroll_pane.add{type = "flow", direction = "vertical"}
                bottom_scroll.style.vertical_spacing = 0
                bottom_scroll.style.width = list_width

                -- add mini-map
                local map = bottom_flow.add{
                    type = "minimap",
                    position = position,
                    surface_index = train_stop.surface.index
                }
                map.style.height = preview_size
                map.style.width = preview_size
                map.style.horizontally_stretchable = true
                map.style.vertically_stretchable = true
            end

            -- add container to the scroll-pane
            local station_container = bottom_scroll.add{ type = "flow", direction = "horizontal"}

            -- add button that opens the station directly
            local station_button = station_container.add{ type = "button", direction = "horizontal"}
            station_button.style.width = 80
            station_button.tooltip = {"station-button-tooltip"}

            -- add station name on top of the button
            local station_button_label = station_button.add{ type = "label"}
            station_button_label.caption = {"station-name", station_amount}
            station_button_label.style.font_color = {} --black
            station_button_label.ignored_by_interaction = true

            -- add button that opens the map with the station centered
            local station_map_button = station_container.add{ type = "sprite-button"}
            station_map_button.sprite = "train-station-overview-map-sprite"
            station_map_button.style.width = 28
            station_map_button.style.height = 28
            station_map_button.style.padding = 0
            station_map_button.tooltip = {"open-on-map-tooltip"}

            -- add station button to the global array
            if not buttons[player_index] then
                buttons[player_index] = {}
            end
            buttons[player_index][station_button.index] = train_stop

            -- add map button to the global array
            if not map_buttons[player_index] then
                map_buttons[player_index] = {}
            end
            map_buttons[player_index][station_map_button.index] = train_stop
        end
    end
end

function close_gui(player_index)
    local frame = frames[player_index]
    if frame and frame.valid then
        frame.destroy()
        frames[player_index] = nil
    end

    -- reset data
    buttons[player_index] = nil
    map_buttons[player_index] = nil
end

function close_gui_clear(player_index)
    close_gui(player_index)
    search_text[player_index] = nil
    search_boxes[player_index] = nil
    search_text_fields[player_index] = nil
end

function refresh_gui(player_index)
    close_gui(player_index)
    create_gui(player_index)
end

function refresh_all_guis()
    -- close and open all GUIs
    for player_index, _ in pairs(frames) do
        refresh_gui(player_index)
    end
end

function insert_sorted(entity)
    local inserted = false
    for index, train_stop in pairs(global.train_stops) do
        if check_station(train_stop) and entity.backer_name:lower() < train_stop.backer_name:lower() then
            table.insert(global.train_stops, index, entity)
            return
        end
    end
    if inserted == false then
        table.insert(global.train_stops, entity)
    end
end

function gui_is_opened(player_index)
    if frames[player_index] and frames[player_index].valid then
        return true
    else
        return false
    end
end

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity},
    function(e)
        if type(global.train_stops) ~= "table" then
            global.train_stops = {}
        end

        if e.created_entity.prototype.type == "train-stop" then
            insert_sorted(e.created_entity)

            refresh_all_guis()
        end
    end
)

script.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity},
    function(e)
        if e.entity.prototype.type == "train-stop" then
            remove_station(e.entity)

            refresh_all_guis()
        end
    end
)

function find_train_stop(entity)
    for key, value in pairs(global.train_stops) do
        if value == entity then
            return key
        end
    end
    return 0
end

script.on_event("open-train-stop-overview",
    function(e)
        if gui_is_opened(e.player_index) then
            close_gui_clear(e.player_index)
        else
            create_gui(e.player_index)
        end
    end
)

script.on_event(defines.events.on_gui_closed,
    function(e)
        close_gui_clear(e.player_index)
    end
)

script.on_event(defines.events.on_gui_click,
    function(e)
        if not e.element or not e.element.valid then return end
        local player = game.get_player(e.player_index)

        -- toggle search field
        local search_field = search_boxes[e.element.index]
        if search_field and search_field.valid then
            if search_field.visible then
                search_field.visible = false
            else
                search_field.visible = true
                search_field.focus()
            end
            return
        end

        -- open train_stop GUI
        if buttons[e.player_index] and buttons[e.player_index][e.element.index] then
            local train_stop = buttons[e.player_index][e.element.index]
            if train_stop and train_stop.valid then
                player.opened = train_stop
                return
            end
        end

        -- open train_stop on map
        if map_buttons[e.player_index] and map_buttons[e.player_index][e.element.index] then
            local train_stop = map_buttons[e.player_index][e.element.index]
            if train_stop and train_stop.valid then
                player.open_map(train_stop.position, 0.4)
                close_gui_clear(e.player_index)
            end
        end

        -- reload train stops
        if reload_buttons[player.index] and reload_buttons[player.index].valid and reload_buttons[player.index].index == e.element.index then
            on_load()
            refresh_all_guis()
        end
    end
)

script.on_event(defines.events.on_gui_text_changed,
    function(e)
        local search_button = search_text_fields[e.element.index]
        if search_button and search_button.valid then
            search_text[e.player_index] = search_button.text

            if cards[e.player_index] then
                for _, card_data in pairs(cards[e.player_index]) do
                    if card_data.card and card_data.card.valid and card_data.train_stop_name then
                        card_data.card.visible = filter_station(e.player_index, card_data.train_stop_name)
                    end
                end

                frames[e.player_index].force_auto_center()
            end
        end
    end
)

script.on_event(defines.events.on_player_display_resolution_changed,
    function(e)
        if gui_is_opened(e.player_index) then
            refresh_gui(e.player_index)
        end
    end
)

script.on_event(defines.events.on_entity_renamed,
    function(e)
        if e.entity.prototype.type == "train-stop" then
            local pos = find_train_stop(e.entity)
            table.remove(global.train_stops, pos)
            insert_sorted(e.entity)

            refresh_all_guis()
        end
    end
)

--script.on_event(defines.events.on_gui_value_changed,
--    function(e)
--        print("value changed, new value: " .. e.element.slider_value)
--    end
--)

function on_load()
    if global.train_stops then
        for i, _ in pairs(global.train_stops) do
            global.train_stops[i] = nil
        end
    else
        global.train_stops = {}
    end

    for _, train_stop in pairs(game.get_surface(1).find_entities_filtered{type={"train-stop"}}) do
        insert_sorted(train_stop)
    end
end

-- on new setup and when mod changes, all stops will be added new
script.on_init(on_load)

-- If some mod is changed, so train-stops are not valid anymore ... also reload
script.on_configuration_changed(on_load)
