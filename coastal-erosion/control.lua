global.coastMap = global.coastMap or {}
global.coastCount = global.coastCount or 0

local waterTileNames = { 'water', 'water-green' }
local deepWaterTileNames = { 'deepwater', 'deepwater-green' }
local allWaterTileNames = { 'water', 'water-green', 'deepwater', 'deepwater-green' }

local checkTiles = { 'stone-path', 'refined-concrete', 'refined-hazard-concrete-left', 'refined-hazard-concrete-right' }

local wildTileNames = {
  'dirt-1', 'dirt-2', 'dirt-3', 'dirt-4', 'dirt-5', 'dirt-6', 'dirt-7',
  'dry-dirt',
  'grass-1', 'grass-2', 'grass-3', 'grass-4',
  'lab-dark-1', 'lab-dark-2', 'lab-white',
  'red-desert-0', 'red-desert-1', 'red-desert-2', 'red-desert-3',
  'sand-1', 'sand-2', 'sand-3'
}

local isDebug = false

local log = function(arg)
  if isDebug then
    game.print(arg)
  end
end

local isInTileNames = function(tileName, tileNames)
  for __idx, name in ipairs(tileNames) do
    if name == tileName then return true end
  end
  return false
end

local isAnyWaterTile = function(tileName)
  return isInTileNames(tileName, allWaterTileNames)
end

local isAnyWildTile = function(tileName)
  return isInTileNames(tileName, wildTileNames)
end

local findKeyByIndex = function(tidx, map)
  local idx = 1
  for key, value in pairs(map) do
    if idx == tidx then return key end
    idx = idx + 1
  end
end

local countLength = function(map)
  local n = 0
  for key, value in pairs(map) do
    n = n + 1
  end
  return n
end

local findNeighbours = function(surface, position, f)
  local x = position.x
  local y = position.y
  local diffs = {
    { x =  1, y =  0 },
    { x = -1, y =  0 },
    { x =  0, y =  1 },
    { x =  0, y = -1 },
  }
  local r = {}
  for __idx, diff in ipairs(diffs) do
    local ct = surface.get_tile(x + diff.x, y + diff.y)
    if ct and ct.valid and f(ct.name) then
      table.insert(r, ct.position)
    end
  end
  return r
end

local updateCoastTilePoint = function(position, point)
  local coastMap = global.coastMap
  local coastCount = global.coastCount
  if point > 0 then
    coastMap[position.x] = (coastMap[position.x] or {})
    local c = coastMap[position.x][position.y]
    if c == nil then global.coastCount = global.coastCount + 1 end
    coastMap[position.x][position.y] = point
  else
    local c = coastMap[position.x] and coastMap[position.x][position.y]
    if c and c > 0 then
      global.coastCount = global.coastCount - 1
      coastMap[position.x][position.y] = nil
      local ycnt = countLength(coastMap[position.x])
      if ycnt == 0 then coastMap[position.x] = nil end
    end
  end
end

local updateNeighboursCoastTilePoint = function(surface, position)
  local coastMap = global.coastMap
  for __idx, cp in ipairs(findNeighbours(surface, position, isAnyWildTile)) do
    local cc = #findNeighbours(surface, cp, isAnyWaterTile)
    updateCoastTilePoint(cp, cc)
  end
end

local registerCoastTilesToCoastMapOnChunkGenerated = function(event)
  local coastMap = global.coastMap
  local s = event.surface
  local a = event.area
  for __idx, tile in ipairs(s.find_tiles_filtered({area = a, name = waterTileNames})) do
    updateNeighboursCoastTilePoint(s, tile.position)
  end
end
script.on_event(defines.events.on_chunk_generated, registerCoastTilesToCoastMapOnChunkGenerated)

local checkBuiltTilesOnPlayerBuiltTile = function(event)
  local coastMap = global.coastMap
  local s = game.surfaces[event.surface_index]
  local ts = event.tiles
  local placedTile = event.item.place_as_tile_result.result.name
  -- built tiles like water by using landmover MOD
  if isAnyWaterTile(placedTile) then
    for __idx, t in ipairs(ts) do
      updateCoastTilePoint(t.position, 0)
      updateNeighboursCoastTilePoint(s, t.position)
    end
    return
  end
  -- built tiles like grass-1 by using landfill
  if isAnyWildTile(placedTile) then
    for __idx, t in ipairs(ts) do
      local p = t.position
      local c = #findNeighbours(s, p, isAnyWaterTile)
      updateCoastTilePoint(p, c)
      updateNeighboursCoastTilePoint(s, p)
    end
    return
  end
  -- built tiles like concrete
  for __idx, t in ipairs(ts) do
    updateCoastTilePoint(t.position, 0)
  end
end

local checkBuiltTilesOnRobotBuiltTile = function(event)
  local ts = event.tiles
  -- built tiles like concrete
  for __idx, t in ipairs(ts) do
    updateCoastTilePoint(t.position, 0)
  end
end

local checkMinedTiles = function(surface, tiles)
  local coastMap = global.coastMap
  for __idx, t in ipairs(tiles) do
    local p = t.position
    local c = #findNeighbours(surface, p, isAnyWaterTile)
    updateCoastTilePoint(p, c)
  end
end

local checkMinedTilesOnPlayerMinedTile = function(event)
  local s = game.surfaces[event.surface_index]
  local ts = event.tiles
  checkMinedTiles(s, ts)
end

local checkMinedTilesOnRobotMinedTile = function(event)
  local s = event.robot.surface
  local ts = event.tiles
  checkMinedTiles(s, ts)
end

script.on_event(defines.events.on_player_built_tile, checkBuiltTilesOnPlayerBuiltTile)
script.on_event(defines.events.on_robot_built_tile, checkBuiltTilesOnRobotBuiltTile)
script.on_event(defines.events.on_player_mined_tile, checkMinedTilesOnPlayerMinedTile)
script.on_event(defines.events.on_robot_mined_tile, checkMinedTilesOnRobotMinedTile)

local chooseTargetCoast = function(rg)
  local coastMap = global.coastMap
  local xcnt = countLength(coastMap)
  if xcnt > 0 then
    local x = findKeyByIndex(rg(1, xcnt), coastMap)
    local ys = coastMap[x]
    local ycnt = countLength(ys)
    if ycnt > 0 then
      local y = findKeyByIndex(rg(1, ycnt), ys)
      local c = ys[y]
      local threshold = ({ 4, 9, 16, 25 })[c] or 50
      local dice = rg(1, 100)
      log('threshold: '..threshold..', dice: '..dice)
      if dice <= threshold then
        return { x = x, y = y }
      end
      return
    end
  end
end

local destroyCoastTile = function(position)
  local s = game.surfaces[1]
  local a = {
    left_top = position,
    right_bottom = { x = position.x + 1, y = position.y + 1 }
  }
  local es = s.find_entities(a)
  for __idx, e in ipairs(es) do
    if e.valid then
      if e.name == 'player' then
        break
      else
        if (e.force.name == 'player') then
          for __idx, player in pairs(game.connected_players) do
            player.add_alert(e, defines.alert_type.entity_destroyed)
          end
        end
        e.destroy()
      end
    end
  end
  -- set water tile
  local coastMap = global.coastMap
  s.set_tiles({{ name = 'water', position = position }})
  updateCoastTilePoint(position, 0)
  updateNeighboursCoastTilePoint(s, position)
end

local erodeCoast = function(event)
  local coastCount = global.coastCount
  log('coastCount: '..coastCount)
  local rg = game.create_random_generator()
  rg.re_seed(event.tick)
  for n = 1, math.max(math.min(100, coastCount * 0.05), 1) do
    local p = chooseTargetCoast(rg)
    if p then destroyCoastTile(p) end
  end
end

-- script.on_nth_tick(50, erodeCoast)
script.on_nth_tick(1000, erodeCoast)

script.on_init(function()
  local coastMap = global.coastMap
  local s = game.surfaces[1]
  for __idx, tile in ipairs(s.find_tiles_filtered({name = waterTileNames})) do
    updateNeighboursCoastTilePoint(s, tile.position)
  end
end)
