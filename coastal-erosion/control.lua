--[[ Generated with https://github.com/TypeScriptToLua/TypeScriptToLua ]]
-- Lua Library inline imports
local function __TS__ArrayForEach(arr, callbackFn)
    do
        local i = 0
        while i < #arr do
            callbackFn(_G, arr[i + 1], i, arr)
            i = i + 1
        end
    end
end

local function __TS__ArrayIndexOf(arr, searchElement, fromIndex)
    local len = #arr
    if len == 0 then
        return -1
    end
    local n = 0
    if fromIndex then
        n = fromIndex
    end
    if n >= len then
        return -1
    end
    local k
    if n >= 0 then
        k = n
    else
        k = len + n
        if k < 0 then
            k = 0
        end
    end
    do
        local i = k
        while i < len do
            if arr[i + 1] == searchElement then
                return i
            end
            i = i + 1
        end
    end
    return -1
end

local function __TS__ObjectKeys(obj)
    local result = {}
    for key in pairs(obj) do
        result[#result + 1] = key
    end
    return result
end

local function __TS__ArrayPush(arr, ...)
    local items = ({...})
    for ____, item in ipairs(items) do
        arr[#arr + 1] = item
    end
    return #arr
end

global.coastMap = global.coastMap or {}
global.coastCount = global.coastCount or 0
local waterTileNames = {"water", "water-green"}
local deepWaterTileNames = {"deepwater", "deepwater-green"}
local allWaterTileNames = {"water", "water-green", "deepwater", "deepwater-green"}
local checkTiles = {"stone-path", "refined-concrete", "refined-hazard-concrete-left", "refined-hazard-concrete-right"}
local wildTileNames = {"dirt-1", "dirt-2", "dirt-3", "dirt-4", "dirt-5", "dirt-6", "dirt-7", "dry-dirt", "landfill", "grass-1", "grass-2", "grass-3", "grass-4", "lab-dark-1", "lab-dark-2", "lab-white", "red-desert-0", "red-desert-1", "red-desert-2", "red-desert-3", "sand-1", "sand-2", "sand-3"}
local debugMessage
debugMessage = function(message, color)
    if color == nil then
        color = {r = 255, g = 255, b = 255}
    end
    __TS__ArrayForEach(
        game.connected_players,
        function(____, player)
            local isDebug = settings.get_player_settings(player)["coastal-erosion-debug-output"].value
            if isDebug then
                player.print(message, color)
            end
        end
    )
end
local isInTileNames
isInTileNames = function(tileName, tileNames)
    return __TS__ArrayIndexOf(tileNames, tileName) >= 0
end
local isAnyWaterTile
isAnyWaterTile = function(tileName)
    return isInTileNames(tileName, allWaterTileNames)
end
local isAnyWildTile
isAnyWildTile = function(tileName)
    return isInTileNames(tileName, wildTileNames)
end
local findKeyByIndex
findKeyByIndex = function(tidx, map)
    local idx = 1
    local result = nil
    __TS__ArrayForEach(
        __TS__ObjectKeys(map),
        function(____, key)
            if idx == tidx then
                result = key
            end
            idx = idx + 1
        end
    )
    return result
end
local countLength
countLength = function(map)
    local n = 0
    __TS__ArrayForEach(
        __TS__ObjectKeys(map),
        function(____, k)
            n = n + 1
        end
    )
    return n
end
local findNeighbours
findNeighbours = function(surface, position, f)
    local x = position.x
    local y = position.y
    local diffs = {{x = 1, y = 0}, {x = -1, y = 0}, {x = 0, y = 1}, {x = 0, y = -1}}
    local r = {}
    __TS__ArrayForEach(
        diffs,
        function(____, diff)
            local ct = surface.get_tile(x + diff.x, y + diff.y)
            if ct and ct.valid and f(ct.name) then
                __TS__ArrayPush(r, ct.position)
            end
        end
    )
    return r
end
local updateCoastTilePoint
updateCoastTilePoint = function(position, point)
    local coastMap = global.coastMap
    local cosatCount = global.coastCount
    local x = position.x
    local y = position.y
    if point > 0 then
        coastMap[x] = coastMap[x] or {}
        local c = coastMap[x][y]
        if c == nil then
            global.coastCount = global.coastCount + 1
        end
        coastMap[x][y] = point
    else
        local c = coastMap[x] and coastMap[x][y]
        if (c ~= nil) and c > 0 then
            global.coastCount = global.coastCount - 1
            coastMap[x][y] = nil
            local ycnt = countLength(coastMap[x])
            if ycnt == 0 then
                coastMap[x] = nil
            end
        end
    end
end
local updateNeighboursCoastTilePoint
updateNeighboursCoastTilePoint = function(surface, position)
    local coastMap = global.coastMap
    __TS__ArrayForEach(
        findNeighbours(surface, position, isAnyWildTile),
        function(____, cp)
            local cc = #findNeighbours(surface, cp, isAnyWaterTile)
            updateCoastTilePoint(cp, cc)
        end
    )
end
local registerCoastTilesToCoastMapOnChunkGenerated
registerCoastTilesToCoastMapOnChunkGenerated = function(rawEvent)
    local event = rawEvent
    local coastMap = global.coastMap
    local s = event.surface
    local a = event.area
    __TS__ArrayForEach(
        s.find_tiles_filtered({area = a, name = waterTileNames}),
        function(____, tile)
            updateNeighboursCoastTilePoint(s, tile.position)
        end
    )
end
script.on_event(defines.events.on_chunk_generated, registerCoastTilesToCoastMapOnChunkGenerated)
local checkBuiltTilesOnPlayerBuiltTile
checkBuiltTilesOnPlayerBuiltTile = function(rawEvent)
    local event = rawEvent
    local coastMap = global.coastMap
    local s = game.surfaces[event.surface_index]
    local ts = event.tiles
    local item = event.item
    if item == nil then
        return
    end
    local placedTile = item.place_as_tile_result.result.name
    if isAnyWaterTile(placedTile) then
        __TS__ArrayForEach(
            ts,
            function(____, t)
                local p = t.position
                updateCoastTilePoint(p, 0)
                updateNeighboursCoastTilePoint(s, p)
            end
        )
        return
    end
    if isAnyWildTile(placedTile) then
        __TS__ArrayForEach(
            ts,
            function(____, t)
                local p = t.position
                local c = #findNeighbours(s, p, isAnyWaterTile)
                updateCoastTilePoint(p, c)
                updateNeighboursCoastTilePoint(s, p)
            end
        )
        return
    end
    __TS__ArrayForEach(
        ts,
        function(____, t)
            updateCoastTilePoint(t.position, 0)
        end
    )
end
local checkBuiltTilesOnRobotBuiltTile
checkBuiltTilesOnRobotBuiltTile = function(event)
    local coastMap = global.coastMap
    local s = game.surfaces[event.surface_index]
    local ts = event.tiles
    local item = event.item
    if item == nil then
        return
    end
    local placedTile = item.place_as_tile_result.result.name
    if isAnyWaterTile(placedTile) then
        __TS__ArrayForEach(
            ts,
            function(____, t)
                local p = t.position
                updateCoastTilePoint(p, 0)
                updateNeighboursCoastTilePoint(s, p)
            end
        )
        return
    end
    if isAnyWildTile(placedTile) then
        __TS__ArrayForEach(
            ts,
            function(____, t)
                local p = t.position
                local c = #findNeighbours(s, p, isAnyWaterTile)
                updateCoastTilePoint(p, c)
                updateNeighboursCoastTilePoint(s, p)
            end
        )
        return
    end
    __TS__ArrayForEach(
        ts,
        function(____, t)
            updateCoastTilePoint(t.position, 0)
        end
    )
end
local checkMinedTiles
checkMinedTiles = function(surface, tiles)
    local coastMap = global.coastMap
    __TS__ArrayForEach(
        tiles,
        function(____, t)
            local p = t.position
            local c = #findNeighbours(surface, p, isAnyWaterTile)
            updateCoastTilePoint(p, c)
        end
    )
end
local checkMinedTilesOnPlayerMinedTile
checkMinedTilesOnPlayerMinedTile = function(event)
    local s = game.surfaces[event.surface_index]
    local ts = event.tiles
    checkMinedTiles(s, ts)
end
local checkMinedTilesOnRobotMinedTile
checkMinedTilesOnRobotMinedTile = function(event)
    local s = game.surfaces[event.surface_index]
    local ts = event.tiles
    checkMinedTiles(s, ts)
end
script.on_event(defines.events.on_player_built_tile, checkBuiltTilesOnPlayerBuiltTile)
script.on_event(defines.events.on_robot_built_tile, checkBuiltTilesOnRobotBuiltTile)
script.on_event(defines.events.on_player_mined_tile, checkMinedTilesOnPlayerMinedTile)
script.on_event(defines.events.on_robot_mined_tile, checkMinedTilesOnRobotMinedTile)
local chooseTargetCoast
chooseTargetCoast = function(rg)
    local coastMap = global.coastMap
    local xcnt = countLength(coastMap)
    if xcnt > 0 then
        local x = findKeyByIndex(
            rg(1, xcnt),
            coastMap
        )
        if x == nil then
            return
        end
        local ys = coastMap[x]
        local ycnt = countLength(ys)
        if ycnt > 0 then
            local y = findKeyByIndex(
                rg(1, ycnt),
                ys
            )
            if y == nil then
                return
            end
            local c = ys[y]
            local threshold = ({4, 9, 16, 25})[c + 1] or 50
            local dice = rg(1, 100)
            debugMessage(
                "threshold: " .. tostring(threshold) .. ", dice: " .. tostring(dice)
            )
            if dice <= threshold then
                return {x = x, y = y}
            end
        end
    end
    return
end
local destroyCoastTile
destroyCoastTile = function(position)
    local x = position.x
    local y = position.y
    local s = game.surfaces[1]
    local a = {left_top = position, right_bottom = {x = x + 1, y = y + 1}}
    local es = s.find_entities(a)
    __TS__ArrayForEach(
        es,
        function(____, e)
            if e.valid then
                debugMessage(
                    "destroy_entity: " .. tostring(e.name)
                )
                if e.name == "character" then
                    return
                end
                if e.force.name == "player" then
                    __TS__ArrayForEach(
                        game.connected_players,
                        function(____, player)
                            player.add_alert(e, defines.alert_type.entity_destroyed)
                        end
                    )
                end
                e.destroy({do_cliff_correction = true, raise_destroy = false})
            end
        end
    )
    local coastMap = global.coastMap
    s.set_tiles({{name = "water", position = position}})
    updateCoastTilePoint(position, 0)
    updateNeighboursCoastTilePoint(s, position)
end
local erodeCoast
erodeCoast = function(event)
    local coastCount = global.coastCount
    debugMessage(
        "coastCount: " .. tostring(coastCount)
    )
    local rg = game.create_random_generator()
    rg.re_seed(event.tick)
    local maxErosionTiles = settings.startup["coastal-erosion-max-erosion-tiles"].value
    local erosionRate = settings.startup["coastal-erosion-erosion-tiles-rate"].value
    local n = math.max(
        math.min(maxErosionTiles, coastCount * erosionRate),
        1
    )
    do
        local i = 1
        while i <= n do
            do
                local p = chooseTargetCoast(rg)
                if p == nil then
                    goto __continue56
                end
                destroyCoastTile(p)
            end
            ::__continue56::
            i = i + 1
        end
    end
end
script.on_nth_tick(settings.startup["coastal-erosion-erosion-speed"].value, erodeCoast)
script.on_init(
    function()
        local coastMap = global.coastMap
        local s = game.surfaces[1]
        __TS__ArrayForEach(
            s.find_tiles_filtered({name = waterTileNames}),
            function(____, t)
                updateNeighboursCoastTilePoint(s, t.position)
            end
        )
    end
)
