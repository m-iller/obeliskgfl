ix.configs = ix.configs or {}

ix.configs.models = { -- АЙЗ СЮДА ВОТ МОДЕЛИ СОВАЙ
    "models/player/alyx.mdl",
    "models/player/barney.mdl",
}

for k,v in pairs(ix.configs.models) do
    ix.anim.SetModelClass(v, "player")
end