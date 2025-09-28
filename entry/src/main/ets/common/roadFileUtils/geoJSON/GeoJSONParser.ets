import { Track, Point, Waypoint, Metadata, Parser, Route } from '../RoadTypes';
import { BusinessError } from '@ohos.base';
import { Feature, FeatureCollection, Geometry, GeoJsonProperties, MultiPoint, LineString,
  MultiLineString } from 'geojson';
import { Point as pt} from 'geojson'

import { TrackUtils } from '../TrackUtils';

export class GeoJSONParser implements Parser {
  public xmlSource: string = '';
  public tracks: Track[] = [];
  public waypoints: Waypoint[] = [];
  public routes: Route[] = [];
  public metadata: Metadata | null = null;

  /**
   * 解析GeoJSON文件
   * @param geoJsonString GeoJSON字符串
   */
  parse(geoJsonString: string, completeCallback: (error?: Error) => void): void {
    this.xmlSource = geoJsonString;
    try {
      const geoJson = JSON.parse(geoJsonString) as FeatureCollection;

      // 检查是否为有效的GeoJSON
      if (geoJson.type !== 'FeatureCollection') {
        throw new Error('只支持FeatureCollection类型的GeoJSON');
      }

      // 解析所有要素
      geoJson.features.forEach((feature: Feature<Geometry, GeoJsonProperties>) => {
        this.parseFeature(feature);
      });
      if (completeCallback) {
        completeCallback();
      }
    } catch (error) {
      console.error(`GeoJSON解析失败: ${(error as BusinessError).message}`);
      if (completeCallback) {
        completeCallback(error);
      }
    }
  }

  /**
   * 解析单个要素
   * @param feature GeoJSON要素
   */
  private parseFeature(feature: Feature<Geometry, GeoJsonProperties>): void {
    if (!feature.geometry) return;

    switch (feature.geometry.type) {
      case 'Point':
        this.parsePointFeature(feature);
        break;
      case 'MultiPoint':
        this.parseMultiPointFeature(feature);
        break;
      case 'LineString':
        this.parseLineStringFeature(feature);
        break;
      case 'MultiLineString':
        this.parseMultiLineStringFeature(feature);
        break;
      default:
        console.warn(`未支持的几何类型: ${feature.geometry.type}`);
    }
  }

  /**
   * 解析点要素
   * @param feature 点要素
   */
  private parsePointFeature(feature: Feature<Geometry, GeoJsonProperties>): void {
    let ft = feature as Feature<pt, GeoJsonProperties>
    const lon = ft.geometry.coordinates[0]
    const lat = ft.geometry.coordinates[1]
    const ele = ft.geometry.coordinates.length > 2 ? ft.geometry.coordinates[2] : 0;

    const waypoint: Waypoint = {
      lat,
      lon,
      ele,
      name: ft.properties?.name || '',
      desc: ft.properties?.description || '',
      type: ft.properties?.type || '',
      sym: ft.properties?.markerSymbol || '',
      time: this.parseTime(ft.properties?.time)
    };

    this.waypoints.push(waypoint);
  }

  /**
   * 解析多点要素
   * @param feature 多点要素
   */
  private parseMultiPointFeature(feature: Feature<Geometry, GeoJsonProperties>): void {
    let ft = feature as Feature<MultiPoint, GeoJsonProperties>
    ft.geometry.coordinates.forEach((point: number[]) => {
      const lon = point[0]
      const lat = point[1]
      const ele = point.length > 2 ? point[2] : 0;

      const waypoint: Waypoint = {
        lat,
        lon,
        ele,
        name: ft.properties?.name || '',
        desc: ft.properties?.description || '',
        type: ft.properties?.type || '',
        sym: ft.properties?.markerSymbol || '',
        time: this.parseTime(ft.properties?.time)
      };

      this.waypoints.push(waypoint);
    });
  }

  /**
   * 解析线要素
   * @param feature 线要素
   */
  private parseLineStringFeature(feature: Feature<Geometry, GeoJsonProperties>): void {
    let ft = feature as Feature<LineString, GeoJsonProperties>

    const track: Track = this.createTrack(ft.properties);

    const segment: Point[] = ft.geometry.coordinates.map((coord: number[]) => {
      const lon = coord[0]
      const lat = coord[1]
      const ele = coord.length > 2 ? coord[2] : 0;
      return {
        lat: lat,
        lon: lon,
        ele: ele,
        time: this.parseTime(feature.properties?.time)
      } as Point;
    });

    track.segments.push(segment);
    TrackUtils.calculateTrackData(track);
    this.tracks.push(track);
  }

  /**
   * 解析多线要素
   * @param feature 多线要素
   */
  private parseMultiLineStringFeature(feature: Feature<Geometry, GeoJsonProperties>): void {
    let ft = feature as Feature<MultiLineString, GeoJsonProperties>

    const track: Track = this.createTrack(ft.properties);

    ft.geometry.coordinates.forEach((line: number[][]) => {
      const segment: Point[] = line.map((coord: number[]) => {
        const lon = coord[0]
        const lat = coord[1]
        const ele = coord.length > 2 ? coord[2] : 0;

        return {
          lat,
          lon,
          ele,
          time: this.parseTime(feature.properties?.time)
        } as Point;
      });

      track.segments.push(segment);
    });

    TrackUtils.calculateTrackData(track);
    this.tracks.push(track);
  }

  /**
   * 创建轨迹对象
   * @param properties 要素属性
   */
  private createTrack(properties: GeoJsonProperties): Track {
    return {
      name: properties?.name || '',
      cmt: properties?.description || '',
      desc: properties?.description || '',
      src: '',
      type: properties?.type || 'Polygon',
      segments: [],
      distance: {
        total: 0,
        cumul: []
      },
      elevation: {
        max: -Infinity,
        min: Infinity,
        pos: 0,
        neg: 0,
        avg: 0
      },
      slopes: []
    };
  }

  /**
   * 解析时间
   * @param timeString 时间字符串
   */
  private parseTime(timeString: string | number | undefined): Date | undefined {
    if (!timeString) return undefined;

    try {
      // 尝试解析ISO字符串
      if (typeof timeString === 'string') {
        return new Date(timeString);
      }

      // 尝试解析时间戳
      if (typeof timeString === 'number') {
        return new Date(timeString);
      }
    } catch (error) {
      console.warn(`时间解析失败: ${timeString}`);
    }

    return undefined;
  }
}