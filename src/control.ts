global.coastMap = global.coastMap || {};
global.coastCount = global.coastCount || 0;

const waterTileNames: Array<string> = ['water', 'water-green'];
const deepWaterTileNames: Array<string> = ['deepwater', 'deepwater-green'];
const allWaterTileNames: Array<string> = ['water', 'water-green', 'deepwater', 'deepwater-green'];

const checkTiles: Array<string> = [
  'stone-path',
  'refined-concrete',
  'refined-hazard-concrete-left',
  'refined-hazard-concrete-right',
];

const wildTileNames: Array<string> = [
  'dirt-1',
  'dirt-2',
  'dirt-3',
  'dirt-4',
  'dirt-5',
  'dirt-6',
  'dirt-7',
  'dry-dirt',
  'landfill',
  'grass-1',
  'grass-2',
  'grass-3',
  'grass-4',
  'lab-dark-1',
  'lab-dark-2',
  'lab-white',
  'red-desert-0',
  'red-desert-1',
  'red-desert-2',
  'red-desert-3',
  'sand-1',
  'sand-2',
  'sand-3',
];

const debugMessage = function(message: LocalisedString, color: Color = { r: 255, g: 255, b: 255 }) {
  game.connected_players.forEach(player => {
    const isDebug = settings.get_player_settings(player)['coastal-erosion-debug-output'].value as boolean;
    if (isDebug) {
      player.print(message, color);
    }
  });
};
const isInTileNames = function(tileName: string, tileNames: Array<string>) {
  return tileNames.indexOf(tileName) >= 0;
};
const isAnyWaterTile = function(tileName: string) {
  return isInTileNames(tileName, allWaterTileNames);
};
const isAnyWildTile = function(tileName: string) {
  return isInTileNames(tileName, wildTileNames);
};

const findKeyByIndex = function(tidx: number, map: { [key: number]: any }) {
  let idx: number = 1;
  let result: number | undefined = undefined;
  Object.keys(map).forEach(key => {
    if (idx === tidx) result = (key as unknown) as number;
    idx = idx + 1;
  });
  return result;
};
const countLength = function(map: { [key: number]: any }) {
  let n: number = 0;
  Object.keys(map).forEach(k => {
    n = n + 1;
  });
  return n;
};

const findNeighbours = function(surface: LuaSurface, position: Position, f: (tileName: string) => boolean) {
  const x = (position as { x: number; y: number }).x;
  const y = (position as { x: number; y: number }).y;
  const diffs = [
    { x: 1, y: 0 },
    { x: -1, y: 0 },
    { x: 0, y: 1 },
    { x: 0, y: -1 },
  ];
  let r: Array<Position> = [];
  diffs.forEach(diff => {
    const ct = surface.get_tile(x + diff.x, y + diff.y);
    if (ct && ct.valid && f(ct.name)) {
      r.push(ct.position);
    }
  });
  return r;
};

const updateCoastTilePoint = function(position: Position, point: number) {
  const coastMap = global.coastMap as { [key: number]: { [key: number]: number } };
  const cosatCount = global.coastCount as number;
  const x = (position as { x: number; y: number }).x;
  const y = (position as { x: number; y: number }).y;
  if (point > 0) {
    coastMap[x] = coastMap[x] || ({} as { [key: number]: number });
    const c = coastMap[x][y];
    if (c === undefined) {
      global.coastCount = global.coastCount + 1;
    }
    coastMap[x][y] = point;
  } else {
    const c = coastMap[x] && coastMap[x][y];
    if (c !== undefined && c > 0) {
      global.coastCount = global.coastCount - 1;
      delete coastMap[x][y];
      const ycnt = countLength(coastMap[x]);
      if (ycnt === 0) {
        delete coastMap[x];
      }
    }
  }
};

const updateNeighboursCoastTilePoint = function(surface: LuaSurface, position: Position) {
  const coastMap = global.coastMap;
  findNeighbours(surface, position, isAnyWildTile).forEach(cp => {
    const cc = findNeighbours(surface, cp, isAnyWaterTile).length;
    updateCoastTilePoint(cp, cc);
  });
};

const registerCoastTilesToCoastMapOnChunkGenerated = function(this: void, rawEvent: event) {
  const event = rawEvent as on_chunk_generated;
  const coastMap = global.coastMap;
  const s = event.surface;
  const a = event.area;
  s.find_tiles_filtered({ area: a, name: waterTileNames }).forEach((tile: LuaTile) => {
    updateNeighboursCoastTilePoint(s, tile.position);
  });
};
script.on_event(defines.events.on_chunk_generated, registerCoastTilesToCoastMapOnChunkGenerated);

const checkBuiltTilesOnPlayerBuiltTile = function(this: void, rawEvent: event) {
  const event = rawEvent as on_player_built_tile;
  const coastMap = global.coastMap;
  const s = game.surfaces[event.surface_index];
  const ts = event.tiles;
  const item = event.item;
  if (item === undefined) {
    return;
  }
  const placedTile = item.place_as_tile_result.result.name;
  // built tiles like water by using landmover MOD
  if (isAnyWaterTile(placedTile)) {
    ts.forEach(t => {
      const p = t.position;
      updateCoastTilePoint(p, 0);
      updateNeighboursCoastTilePoint(s, p);
    });
    return;
  }
  // built tiles like grass-1 by using landfill
  if (isAnyWildTile(placedTile)) {
    ts.forEach(t => {
      const p = t.position;
      const c = findNeighbours(s, p, isAnyWaterTile).length;
      updateCoastTilePoint(p, c);
      updateNeighboursCoastTilePoint(s, p);
    });
    return;
  }
  // built tiles like concrete
  ts.forEach(t => {
    updateCoastTilePoint(t.position, 0);
  });
};

const checkBuiltTilesOnRobotBuiltTile = function(this: void, event: on_robot_built_tile) {
  const coastMap = global.coastMap;
  const s = game.surfaces[event.surface_index];
  const ts = event.tiles;
  const item = event.item;
  if (item === undefined) {
    return;
  }
  const placedTile = item.place_as_tile_result.result.name;
  // built tiles like water by using landmover MOD
  if (isAnyWaterTile(placedTile)) {
    ts.forEach(t => {
      const p = t.position;
      updateCoastTilePoint(p, 0);
      updateNeighboursCoastTilePoint(s, p);
    });
    return;
  }
  // built tiles like grass-1 by using landfill
  if (isAnyWildTile(placedTile)) {
    ts.forEach(t => {
      const p = t.position;
      const c = findNeighbours(s, p, isAnyWaterTile).length;
      updateCoastTilePoint(p, c);
      updateNeighboursCoastTilePoint(s, p);
    });
    return;
  }
  // built tiles like concrete
  ts.forEach(t => {
    updateCoastTilePoint(t.position, 0);
  });
};

const checkMinedTiles = function(surface: LuaSurface, tiles: OldTileAndPosition[]) {
  const coastMap = global.coastMap;
  tiles.forEach(t => {
    const p = t.position;
    const c = findNeighbours(surface, p, isAnyWaterTile).length;
    updateCoastTilePoint(p, c);
  });
};

const checkMinedTilesOnPlayerMinedTile = function(this: void, event: on_player_mined_tile) {
  const s = game.surfaces[event.surface_index];
  const ts = event.tiles;
  checkMinedTiles(s, ts);
};

const checkMinedTilesOnRobotMinedTile = function(this: void, event: on_robot_mined_tile) {
  const s = game.surfaces[event.surface_index];
  const ts = event.tiles;
  checkMinedTiles(s, ts);
};

script.on_event(defines.events.on_player_built_tile, checkBuiltTilesOnPlayerBuiltTile);
script.on_event(defines.events.on_robot_built_tile, checkBuiltTilesOnRobotBuiltTile);
script.on_event(defines.events.on_player_mined_tile, checkMinedTilesOnPlayerMinedTile);
script.on_event(defines.events.on_robot_mined_tile, checkMinedTilesOnRobotMinedTile);

const chooseTargetCoast = function(rg: LuaRandomGenerator) {
  const coastMap = global.coastMap as { [key: number]: { [key: number]: number } };
  const xcnt = countLength(coastMap);
  if (xcnt > 0) {
    const x = findKeyByIndex(rg(1, xcnt), coastMap);
    if (x === undefined) return;
    const ys = coastMap[x];
    const ycnt = countLength(ys);
    if (ycnt > 0) {
      const y = findKeyByIndex(rg(1, ycnt), ys);
      if (y === undefined) return;
      const c = ys[y];
      const threshold = [4, 9, 16, 25][c] || 50;
      const dice = rg(1, 100);
      debugMessage('threshold: ' + threshold + ', dice: ' + dice);
      if (dice <= threshold) {
        return { x, y } as Position;
      }
    }
  }
  return;
};

const destroyCoastTile = function(position: Position) {
  const x = (position as { x: number; y: number }).x;
  const y = (position as { x: number; y: number }).y;
  const s = game.surfaces[1];
  const a = {
    left_top: position,
    right_bottom: { x: x + 1, y: y + 1 } as Position,
  } as BoundingBox;
  const es = s.find_entities(a);
  es.forEach((e: LuaEntity) => {
    if (e.valid) {
      debugMessage('destroy_entity: ' + e.name);
      if (e.name === 'character') {
        return;
      }
      if ((e.force as LuaForce).name === 'player') {
        game.connected_players.forEach(player => {
          player.add_alert(e, defines.alert_type.entity_destroyed);
        });
      }
      e.destroy({ do_cliff_correction: true, raise_destroy: false });
    }
  });
  // set water tile
  const coastMap = global.coastMap;
  s.set_tiles([{ name: 'water', position: position }]);
  updateCoastTilePoint(position, 0);
  updateNeighboursCoastTilePoint(s, position);
};

const erodeCoast = function(event: NthTickEvent) {
  const coastCount = global.coastCount as number;
  debugMessage('coastCount: ' + coastCount);
  const rg = game.create_random_generator();
  rg.re_seed(event.tick);
  const maxErosionTiles = settings.startup['coastal-erosion-max-erosion-tiles'].value as number;
  const erosionRate = settings.startup['coastal-erosion-erosion-tiles-rate'].value as number;
  const n = Math.max(Math.min(maxErosionTiles, coastCount * erosionRate), 1);
  for (let i = 1; i <= n; i = i + 1) {
    const p = chooseTargetCoast(rg);
    if (p === undefined) continue;
    destroyCoastTile(p);
  }
};

script.on_nth_tick(settings.startup['coastal-erosion-erosion-speed'].value as number, erodeCoast);

script.on_init(() => {
  const coastMap = global.coastMap;
  const s = game.surfaces[1];
  s.find_tiles_filtered({ name: waterTileNames }).forEach(t => {
    updateNeighboursCoastTilePoint(s, t.position);
  });
});
