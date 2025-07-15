import * as fs from "node:fs"
import type { Stats } from "node:fs"


export function readConfig() {
  return fs.readFileSync("config.json")
}

export function getSize(): Stats {
  return fs.statSync("config.json")
}

export interface GridConfig {
  rows: number;
  cols: number;
  cellSize: number;
}

export type CellPosition = {
  x: number;
  y: number;
};


export class GridRenderer {
  private config: GridConfig;

  constructor(config: GridConfig) {
    this.config = config;
  }

  render(): string {
    return `Grid ${this.config.rows}x${this.config.cols}`;
  }
}

const DEFAULT_GRID_CONFIG: GridConfig = {
  rows: 10,
  cols: 10,
  cellSize: 32
};

export function createGrid(config?: Partial<GridConfig>): GridRenderer {
  const finalConfig = { ...DEFAULT_GRID_CONFIG, ...config };
  return new GridRenderer(finalConfig);
}

export function main() {
  greet()
}

const message = "Welcome";

function greet() {
  console.log(message)
}

export function calculateGridDimensions(
  containerWidth: number,
  containerHeight: number,
  cellSize: number
): CellPosition {
  const cols = Math.floor(containerWidth / cellSize);
  const rows = Math.floor(containerHeight / cellSize);
  return { x: cols, y: rows };
}

export default {
  main,
  createGrid,
  calculateGridDimensions,
  GridRenderer,
  DEFAULT_GRID_CONFIG
};


