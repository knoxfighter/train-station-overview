-- print(serpent.block())

local util = require("util")

-- frames[player.index] = frame
local frames = {}
-- buttons[player.index][button.index] = { button = button, train_stop = train_stop }
local buttons = {}
-- search_boxes[searchButton.index] = textfield
local search_boxes = {}
-- search_buttons[player.index] = search_button
local search_text_fields = {}
-- search_text[player.index] = text
local search_text = {}

-- returns true if ALL keys are found
function filter_station(player_index, train_stop)
    if search_text[player_index] then
        local search_keys = util.split_whitespace(search_text[player_index])
        local backer_name = train_stop.backer_name:lower()

        for _, search_key in pairs(search_keys) do
            if not backer_name:find(search_key:lower()) then
                return false
            end
        end
    end
    return true
end

function create_gui(player_index)
    -- get player
    local player = game.get_player(player_index)

    -- create basic gui frame
    local frame = player.gui.center.add{type = "frame", direction = "vertical"}
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
    local title = titleFlow.add{type = "label", style = "heading_1_label", caption = {"train-stops"}}
    local fillerFlow = titleFlow.add{type = "flow", direction = "horizontal"}
    fillerFlow.style.horizontally_stretchable = true

    -- search
    local search_text_field = titleFlow.add{ type = "textfield", visible = search_text[player_index] ~= nil, text = search_text[player_index]}
    local search_button = titleFlow.add{ type = "sprite-button", style = "tool_button", sprite = "utility/search_icon", tooltip = { "gui.search-with-focus", { "search"}}}
    search_boxes[search_button.index] = search_text_field
    search_text_fields[search_text_field.index] = search_text_field

    if #global.train_stops < 1 then
        frame.add{type = "label", caption = {"no-train-stops"}}
        return
    end

    -- Inner Frame with scrollbar and tableview
    local innerFrame = frame.add{type = "frame", style = "inside_deep_frame"}
    local scroll = innerFrame.add{type = "scroll-pane", direction = "vertical"}
    local tableView = scroll.add{type = "table", column_count = 7}

    -- set table spacing
    tableView.style.horizontal_spacing = 4
    tableView.style.vertical_spacing = 4

    local preview_size = 160
    local preview_size_half = preview_size / 2

    for _, train_stop in pairs(global.train_stops) do
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

        -- create button with text and chart
        local button = tableView.add{type = "button", name = train_stop.unit_number}
        button.style.height = preview_size + 32 + 32 + 8 --32 for each label
        button.style.width = preview_size + 8
        button.style.left_padding = 0
        button.style.right_padding = 0

        button.visible = filter_station(player_index, train_stop)

        -- set flow to button (multiple elements inside the button)
        local button_flow = button.add{type = "flow", direction = "vertical"}
        button_flow.style.vertically_stretchable = true
        button_flow.style.horizontally_stretchable = true
        button_flow.style.horizontal_align = "center"
        button_flow.ignored_by_interaction = true

        -- add label to the button
        local button_label = button_flow.add{type = "label", caption = train_stop.backer_name}
        button_label.style.horizontally_stretchable = true
        button_label.style.font_color = {} --black
        button_label.style.font  = "default-dialog-button"
        button_label.style.horizontally_stretchable = true
        button_label.style.maximal_width = preview_size

        -- add map to the button
        local button_map = button_flow.add{
            type = "minimap",
            position = position,
            surface_index = train_stop.surface.index
        }

        button_map.style.height = preview_size
        button_map.style.width = preview_size
        button_map.style.horizontally_stretchable = true
        button_map.style.vertically_stretchable = true
        button_map.ignored_by_interaction = true

        -- show amount of trains stopping here
        local train_amount_label = button_flow.add{type = "label", caption = {"train-amount", #train_stop.get_train_stop_trains()}}
        train_amount_label.style.horizontally_stretchable = true
        train_amount_label.style.font_color = {}
        train_amount_label.style.horizontally_stretchable = true
        train_amount_label.style.maximal_width = preview_size

        if not buttons[player_index] then
            buttons[player_index] = {}
        end
        buttons[player_index][button.index] = {}
        buttons[player_index][button.index] = {train_stop = train_stop, button = button}
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
end

function refresh_gui()
    -- close and open all GUIs
    for player_index, _ in pairs(frames) do
        close_gui(player_index)

        create_gui(player_index)
    end
end

function insert_sorted(entity)
    local inserted = false
    for index, train_stop in pairs(global.train_stops) do
        if entity.backer_name:lower() < train_stop.backer_name:lower() then
            table.insert(global.train_stops, index, entity)
            return
        end
    end
    if inserted == false then
        table.insert(global.train_stops, entity)
    end
end

function gui_is_opened(player_index)
    if frames[player_index] then
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

        if e.created_entity.name == "train-stop" then
            insert_sorted(e.created_entity)

            refresh_gui()
        end
    end
)

script.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity},
    function(e)
        if e.entity.name == "train-stop" then
            local pos = find_train_stop(e.entity)
            if pos == 0 then
                print("train_stop not found, just do nothing!")
                return
            end

            table.remove(global.train_stops, pos)

            refresh_gui()
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
        local player_frame = frames[e.player_index]
        if player_frame and player_frame.valid then
            close_gui(e.player_index)
        else
            create_gui(e.player_index)
        end
    end
)

script.on_event(defines.events.on_gui_closed,
    function(e)
        close_gui(e.player_index)
        search_text[e.player_index] = nil
        search_boxes[e.player_index] = nil
        search_text_fields[e.player_index] = nil
    end
)

script.on_event(defines.events.on_gui_click,
    function(e)
        if not e.element or not e.element.valid then return end
        local player = game.get_player(e.player_index)

        -- open train_stop GUI
        if buttons[e.player_index] and buttons[e.player_index][e.element.index] then
            local train_stop = buttons[e.player_index][e.element.index].train_stop
            if train_stop and train_stop.valid then
                player.opened = train_stop
                return
            end
        end

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
    end
)

script.on_event(defines.events.on_gui_text_changed,
    function(e)
        local search_button = search_text_fields[e.element.index]
        if search_button and search_button.valid then
            search_text[e.player_index] = search_button.text

            for _, button_data in pairs(buttons[e.player_index]) do
                if button_data.button and button_data.button.valid and button_data.train_stop and button_data.train_stop.valid then
                    button_data.button.visible = filter_station(e.player_index, button_data.train_stop)
                end
            end
        end
    end
)

script.on_event(defines.events.on_player_display_resolution_changed,
    function(e)
        if gui_is_opened(e.player_index) then
            close_gui(e.player_index)
            create_gui(e.player_index)
        end
    end
)

script.on_event(defines.events.on_entity_renamed,
    function(e)
        if e.entity.name == "train-stop" then
            local pos = find_train_stop(e.entity)
            table.remove(global.train_stops, pos)
            insert_sorted(e.entity)

            refresh_gui()
        end
    end
)

--script.on_configuration_changed(function()
script.on_init(function()
    if global.train_stops then
        for i, _ in pairs(global.train_stops) do
            global.train_stops[i] = nil
        end
    else
        global.train_stops = {}
    end

    for _, train_stop in pairs(game.get_surface(1).find_entities_filtered{name="train-stop"}) do
        insert_sorted(train_stop)
    end
end)
