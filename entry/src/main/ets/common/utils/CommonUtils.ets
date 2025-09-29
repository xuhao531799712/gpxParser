import { uri } from "@kit.ArkTS";
import { GeoJSONParser } from "../roadFileUtils/geoJSON/GeoJSONParser";
import GPXParser from "../roadFileUtils/gpx/GPXParser";
import KMLParser from "../roadFileUtils/kml/KMLParser";
import { Parser } from "../roadFileUtils/RoadTypes";
import TCXParser from "../roadFileUtils/tcx/TCXParser";


export class CommonUtils {

  static TAG = 'CommonUtils'

  static getFileNameFromUri(input: string): string {
    try {
      // 创建 URI 对象
      const uriObj = new uri.URI(input);
      // 获取路径部分
      return uriObj.getLastSegment();
    } catch (error) {
      console.error(`解析URI失败: ${error.message}`);
      return '';
    }
  }

  static getFilePathFromUri(input: string): string {
    try {
      // 创建 URI 对象
      const uriObj = new uri.URI(input);
      // 获取路径部分
      return uriObj.path;
    } catch (error) {
      console.error(`解析URI失败: ${error.message}`);
      return '未命名文件';
    }
  }

  // 获取文件类型
  static getFileType(filePath: string): string {
    const extension = filePath.split('.').pop()?.toLowerCase() || '';

    return CommonUtils.fileTypes[extension] || '未知文件类型';
  }

  static getFileSuffix(filePath: string): string {
    const extension = filePath.split('.').pop()?.toLowerCase() || '';

    return extension;
  }

  static fileTypes: Record<string, string> = {
    'gpx': 'GPS 轨迹文件',
    'kml': 'Google Earth KML 文件',
    'tcx': 'Garmin Training Center TCX 文件',
    'geojson': 'GeoJSON 文件'
  };

  static createParser(suffix: string): Parser {
    switch (suffix) {
      case 'gpx':
        return new GPXParser()
      case 'kml':
        return new KMLParser()
      case 'tcx':
        return new TCXParser()
      default:
        return new GeoJSONParser()
    }
  }
}