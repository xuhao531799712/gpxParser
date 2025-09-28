import { Track, Waypoint } from '../RoadTypes';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import { FeatureCollection } from 'geojson';

export class GeoJSONWriter {
  /**
   * 将轨迹和航点数据写入GeoJSON文件
   * @param tracks 轨迹数组
   * @param waypoints 航点数组
   * @param filePath 文件保存路径
   */
  static async writeGeoJSONFile(
    tracks: Track[],
    waypoints: Waypoint[],
    filePath: string,
  ): Promise<boolean> {
    try {
      // 生成GPX XML内容
      const content = GeoJSONWriter.generateGeoJSONContent(tracks, waypoints);

      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, content);
      await fs.close(file.fd);

      console.log(`GeoJSON文件已保存: ${filePath}`);
      return true;
    } catch (error) {
      console.error(`保存GeoJSON文件失败: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 生成GeoJSON内容
   */
  private static generateGeoJSONContent(
    tracks: Track[],
    waypoints: Waypoint[],
  ): string {
    const geoJSON: FeatureCollection = {
      type: 'FeatureCollection',
      features: []
    };

    // 添加航点
    waypoints.forEach(wpt => {
      geoJSON.features.push({
        type: 'Feature',
        geometry: {
          type: 'Point',
          coordinates: [wpt.lon, wpt.lat]
        },
        properties: {
          name: wpt.name,
          ele: wpt.ele,
          time: wpt.time,
          sym: wpt.sym,
          type: wpt.type
        }
      });
    });

    // 添加轨迹
    tracks.forEach(track => {
      track.segments.forEach(segment => {
        const coordinates = segment.map(pt => [pt.lon, pt.lat, pt.ele]);
        geoJSON.features.push({
          type: 'Feature',
          geometry: {
            type: 'LineString',
            coordinates: coordinates
          },
          properties: {
            name: track.name,
            distance: track.distance.total,
            elevation: track.elevation
          }
        });
      });
    });

    return JSON.stringify(geoJSON, null, 2);
  }
}