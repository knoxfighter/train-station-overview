-- print(serpent.block())

-- frames[player_index.index] = frame
local frames = {}
-- buttons[button.index] = train_stop
local buttons = {}

function create_gui(player_index)
    -- get player
    local player = game.get_player(player_index)

    -- create basic gui frame
    local frame = player.gui.center.add{type = "frame", direction = "vertical"}

    -- open frame (this is the gui shown to the player)
    player.opened = frame
    frames[player.index] = frame

    local titleFlow = frame.add{type = "flow", direction = "horizontal"}

    local title = titleFlow.add{type = "label", style = "heading_1_label", caption = {"train-stops"}}

    local fillerFlow = titleFlow.add{type = "flow", direction = "horizontal"}
    fillerFlow.style.horizontally_stretchable = true

    --TODO add search

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
        button.style.height = preview_size + 32 + 8
        button.style.width = preview_size + 8
        button.style.left_padding = 0
        button.style.right_padding = 0

        -- set flow to button (multiple elemts inside the button)
        local button_flow = button.add{type = "flow", direction = "vertical"} --ignored_by_interaction = true
        button_flow.style.vertically_stretchable = true
        button_flow.style.horizontally_stretchable = true
        button_flow.style.horizontal_align = "center"
        button_flow.ignored_by_interaction = true

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

        -- add label to the button
        local button_label = button_flow.add{type = "label", caption = train_stop.backer_name}
        button_label.style.horizontally_stretchable = true
        button_label.style.font_color = {} --black
        button_label.style.font  = "default-dialog-button"
        button_label.style.horizontally_stretchable = true
        button_label.style.maximal_width = preview_size

        buttons[button.index] = train_stop
    end
end

function refresh_gui()
    -- close and open all GUIs
    for player_index, frame in pairs(frames) do
        if frame and frame.valid then
            frame.destroy()
        end

        create_gui(player_index)
    end
end

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity},
    function(e)
        if type(global.train_stops) ~= "table" then
            global.train_stops = {}
        end

        if e.created_entity.name == "train-stop" then
            table.insert(global.train_stops, e.created_entity)

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
        create_gui(e.player_index)
    end
)

script.on_event(defines.events.on_gui_closed,
    function(e)
        local frame = frames[e.player_index]
        if frame and frame.valid then
            frame.destroy()
            frames[e.player_index] = nil
        end
    end
)

script.on_event(defines.events.on_gui_click,
    function(e)
        if not e.element or not e.element.valid then return end
        local train_stop = buttons[e.element.index]

        if not train_stop or not train_stop.valid then return end

        local player = game.get_player(e.player_index)
        player.opened = train_stop
    end
)

script.on_configuration_changed(function()
    if global.train_stops then
        for i, _ in ipairs(global.train_stops) do
            global.train_stops[i] = nil
        end
    else
        global.train_stops = {}
    end

    for _, trainstop in pairs(game.get_surface(1).find_entities_filtered{name="train-stop"}) do
        table.insert(global.train_stops, trainstop)
    end
end)
