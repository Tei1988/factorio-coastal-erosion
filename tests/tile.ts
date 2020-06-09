import { WaterTileManager, PavementTileManager, TerrainTileManager } from '../src/models/tile';

const waterTileManager = new WaterTileManager();

const pavementTileManager = new PavementTileManager();

const terrainTileManager = new TerrainTileManager();

describe('WaterTileManager', (): void => {
  test.each([['water'], ['deepwater'], ['water-green'], ['deepwater-green']])(
    'call check with %s have to return true',
    (tile: string): void => {
      expect(waterTileManager.check(tile)).toBe(true);
    }
  );
  test('call check with non water tile have to return false', (): void => {
    expect(waterTileManager.check('stone-path')).toBe(false);
  });
});

describe('PavementTileManager', (): void => {
  test.each([
    ['stone-path'],
    ['refined-concrete'],
    ['refined-hazard-concrete-left'],
    ['refined-hazard-concrete-right'],
  ])('call check with %s have to return true', (tile: string): void => {
    expect(pavementTileManager.check(tile)).toBe(true);
  });
  test('call check with non pavement tile have to return false', (): void => {
    expect(pavementTileManager.check('dirt-1')).toBe(false);
  });
});

describe('TerrainTileManager', (): void => {
  test.each([
    ['dirt-1'],
    ['dirt-2'],
    ['dirt-3'],
    ['dirt-4'],
    ['dirt-5'],
    ['dirt-6'],
    ['dirt-7'],
    ['dry-dirt'],
    ['landfill'],
    ['grass-1'],
    ['grass-2'],
    ['grass-3'],
    ['grass-4'],
    ['lab-dark-1'],
    ['lab-dark-2'],
    ['lab-white'],
    ['red-desert-0'],
    ['red-desert-1'],
    ['red-desert-2'],
    ['red-desert-3'],
    ['sand-1'],
    ['sand-2'],
    ['sand-3'],
  ])('call check with %s have to return true', (tile: string): void => {
    expect(terrainTileManager.check(tile)).toBe(true);
  });
  test('call check with non terrain have to return false', (): void => {
    expect(terrainTileManager.check('water')).toBe(false);
  });
});
