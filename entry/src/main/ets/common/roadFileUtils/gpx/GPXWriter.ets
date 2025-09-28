// GPXWriter.ets
import { Track, Point, Waypoint, Metadata } from '../RoadTypes';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';

export class GPXWriter {
  /**
   * 将轨迹和航点数据写入GPX文件
   * @param tracks 轨迹数组
   * @param waypoints 航点数组
   * @param filePath 文件保存路径
   * @param metadata 可选的元数据
   */
  static async writeGPXFile(
    tracks: Track[],
    waypoints: Waypoint[],
    filePath: string,
    metadata?: Metadata
  ): Promise<boolean> {
    try {
      // 生成GPX XML内容
      const gpxContent = GPXWriter.generateGPXContent(tracks, waypoints, metadata);

      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, gpxContent);
      await fs.close(file.fd);

      console.log(`GPX文件已保存: ${filePath}`);
      return true;
    } catch (error) {
      console.error(`保存GPX文件失败: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 生成GPX XML内容
   */
  private static generateGPXContent(
    tracks: Track[],
    waypoints: Waypoint[],
    metadata?: Metadata
  ): string {
    const xmlLines: string[] = [];

    // GPX文件头
    xmlLines.push('<?xml version="1.0" encoding="UTF-8"?>');
    xmlLines.push('<gpx xmlns="http://www.topografix.com/GPX/1/1"');
    xmlLines.push('     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    xmlLines.push('     xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"');
    xmlLines.push('     version="1.1" creator="HarmonyOS GPX Editor">');
    xmlLines.push('');

    // 元数据部分
    if (metadata) {
      xmlLines.push('  <metadata>');
      if (metadata.name) {
        xmlLines.push(`    <name>${GPXWriter.escapeXml(metadata.name)}</name>`);
      }
      if (metadata.desc) {
        xmlLines.push(`    <desc>${GPXWriter.escapeXml(metadata.desc)}</desc>`);
      }
      if (metadata.time) {
        xmlLines.push(`    <time>${GPXWriter.formatDate(metadata.time)}</time>`);
      }
      xmlLines.push('  </metadata>');
      xmlLines.push('');
    }

    // 航点部分
    waypoints.forEach(waypoint => {
      xmlLines.push(GPXWriter.waypointToXml(waypoint));
    });

    if (waypoints.length > 0) {
      xmlLines.push('');
    }

    // 轨迹部分
    tracks.forEach(track => {
      xmlLines.push(GPXWriter.trackToXml(track));
    });

    // GPX文件尾
    xmlLines.push('</gpx>');

    return xmlLines.join('\n');
  }

  /**
   * 将航点转换为XML
   */
  private static waypointToXml(waypoint: Waypoint): string {
    const lines: string[] = [];

    lines.push(`  <wpt lat="${waypoint.lat}" lon="${waypoint.lon}">`);

    if (waypoint.ele !== 0) {
      lines.push(`    <ele>${waypoint.ele}</ele>`);
    }

    if (waypoint.time) {
      lines.push(`    <time>${GPXWriter.formatDate(waypoint.time)}</time>`);
    }

    if (waypoint.name) {
      lines.push(`    <name>${GPXWriter.escapeXml(waypoint.name)}</name>`);
    }

    if (waypoint.desc) {
      lines.push(`    <desc>${GPXWriter.escapeXml(waypoint.desc)}</desc>`);
    }

    lines.push('  </wpt>');

    return lines.join('\n');
  }

  /**
   * 将轨迹转换为XML
   */
  private static trackToXml(track: Track): string {
    const lines: string[] = [];

    lines.push('  <trk>');

    if (track.name) {
      lines.push(`    <name>${GPXWriter.escapeXml(track.name)}</name>`);
    }

    if (track.type) {
      lines.push(`    <type>${GPXWriter.escapeXml(track.type)}</type>`);
    }

    // 轨迹段
    lines.push('    <trkseg>');

    // 轨迹点
    track.segments[0].forEach(point => {
      lines.push(GPXWriter.trackPointToXml(point));
    });

    lines.push('    </trkseg>');
    lines.push('  </trk>');

    return lines.join('\n');
  }

  /**
   * 将轨迹点转换为XML
   */
  private static trackPointToXml(point: Point): string {
    const lines: string[] = [];

    lines.push(`      <trkpt lat="${point.lat}" lon="${point.lon}">`);

    if (point.ele !== 0) {
      lines.push(`        <ele>${point.ele}</ele>`);
    }

    if (point.time) {
      lines.push(`        <time>${GPXWriter.formatDate(point.time)}</time>`);
    }

    lines.push('      </trkpt>');

    return lines.join('\n');
  }

  /**
   * 转义XML特殊字符
   */
  private static escapeXml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  /**
   * 格式化日期为ISO字符串
   */
  private static formatDate(date: Date): string {
    return date.toISOString();
  }
}