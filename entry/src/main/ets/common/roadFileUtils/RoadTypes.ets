// RoadTypes.ets
export class Point {
  lat: number = 0;
  lon: number = 0;
  ele: number = 0;
  time?: Date = undefined;
  hr?: number = undefined;
  cad?: number = undefined;
}

export class Waypoint extends Point {
  name?: string = undefined;
  cmt?: string = undefined;
  desc?: string = undefined;
  sym?: string = undefined;
  type?: string = undefined;
}

export class Distance {
  total: number = 0;
  cumul: number[] = [];
}

export class Elevation {
  max: number = -Infinity;
  min: number = Infinity;
  pos: number = 0; // 累计爬升
  neg: number = 0; // 累计下降
  avg: number = 0;
}

export class Track {
  name: string = '';
  cmt?: string = undefined;
  desc?: string = undefined;
  src?: string = undefined;
  type?: string = undefined;
  segments: Point[][] = [];
  distance: Distance = new Distance();
  elevation: Elevation = new Elevation();
  slopes: number[] = [];
}

export class Route {
  name: string = '';
  cmt?: string = undefined;
  desc?: string = undefined;
  src?: string = undefined;
  type?: string = undefined;
  points: Point[] = [];
  distance: Distance = new Distance();
}

export class Bounds {
  minlat: number = 0;
  minlon: number = 0;
  maxlat: number = 0;
  maxlon: number = 0;
}

export class Metadata {
  name: string = '';
  desc: string = '';
  author: string = '';
  time: Date = new Date();
  keywords: string = '';
  bounds: Bounds = new Bounds();
}

export interface Parser {
  xmlSource: string;
  metadata: Metadata | null;
  waypoints: Waypoint[];
  tracks: Track[];
  routes: Route[];
  parse(contentString: string, completeCallback:(error?: Error)=>void): void;
}