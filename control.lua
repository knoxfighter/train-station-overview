-- print(serpent.block())

script.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity},
    function(e)
        if type(global.train_stops) ~= "table" then
            global.train_stops = {}
        end

        print(e.created_entity.name)

        if e.created_entity.name == "train-stop" then
            table.insert(global.train_stops, e.created_entity)
            --print(e.created_entity.backer_name)
        end
    end
)

script.on_event({defines.events.on_entity_died, defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity},
    function(e)
        if e.entity.name == "train-stop" then
            local pos = find_train_stop(e.entity)
            if pos == 0 then
                print(serpent.block(global.train_stops))
                return
            end

            table.remove(global.train_stops, pos)
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

script.on_configuration_changed(function()
    if type(global.train_stops) ~= "table" then
        global.train_stops = {}
    end

    for _, trainstop in pairs(game.get_surface(1).find_entities_filtered{name="train-stop"}) do
        table.insert(global.train_stops, trainstop)
    end
end)
