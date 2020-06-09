export type TileName = string;

export class TileManager {
  public readonly tileMap: { [k: string]: boolean };
  public readonly tileNames: TileName[];
  constructor(tileNames: TileName[]) {
    this.tileNames = tileNames;
    this.tileMap = Object.fromEntries(tileNames.map(tile => [tile, true]));
  }
  public check(tile: TileName): boolean {
    return this.tileMap[tile] || false;
  }
}

export class WaterTileManager extends TileManager {
  private static seaTiles = ['deepwater', 'deepwater-green'];
  public static readonly fordTiles = ['water', 'water-green'];
  constructor() {
    super(WaterTileManager.seaTiles.concat(WaterTileManager.fordTiles));
  }
}

export class PavementTileManager extends TileManager {
  private static tiles = [
    'stone-path',
    'refined-concrete',
    'refined-hazard-concrete-left',
    'refined-hazard-concrete-right',
  ];
  constructor() {
    super(PavementTileManager.tiles);
  }
}

export class TerrainTileManager extends TileManager {
  private static tiles = [
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
  constructor() {
    super(TerrainTileManager.tiles);
  }
}
