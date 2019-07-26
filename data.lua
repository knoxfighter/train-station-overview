require("prototypes.input")

data:extend{
    {
        type = "sprite",
        name = "train-station-overview-map-sprite",
        filename = "__core__/graphics/icons/map.png",
        priority = "extra-high",
        width = 32,
        height = 32
    },
    {
        type = "sprite",
        name = "train-station-overview-refresh-sprite",
        filename = "__core__/graphics/icons/refresh.png",
        width = 32,
        height = 32
    }
}

data.raw["gui-style"]["default"]["train-station-overview-filler-style"] = {
    type = "frame_style",
    height = 32,
    graphical_set = data.raw["gui-style"]["default"]["draggable_space"].graphical_set,
    use_header_filler = false,
    horizontally_stretchable = "on",
    left_margin = data.raw["gui-style"]["default"]["draggable_space"].left_margin,
    right_margin = data.raw["gui-style"]["default"]["draggable_space"].right_margin,
}
