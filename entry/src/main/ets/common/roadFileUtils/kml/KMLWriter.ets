import { Track, Point, Waypoint, Metadata } from '../RoadTypes';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';

export class KMLWriter {
  /**
   * 将轨迹和航点数据写入KML文件
   * @param tracks 轨迹数组
   * @param waypoints 航点数组
   * @param filePath 文件保存路径
   * @param metadata 可选的元数据
   */
  static async writeKMLFile(
    tracks: Track[],
    waypoints: Waypoint[],
    filePath: string,
    metadata?: Metadata
  ): Promise<boolean> {
    try {
      // 生成KML XML内容
      const kmlContent = KMLWriter.generateKMLContent(tracks, waypoints, metadata);

      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, kmlContent);
      await fs.close(file.fd);

      console.log(`KML文件已保存: ${filePath}`);
      return true;
    } catch (error) {
      console.error(`保存KML文件失败: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 生成KML XML内容
   */
  private static generateKMLContent(
    tracks: Track[],
    waypoints: Waypoint[],
    metadata?: Metadata
  ): string {
    const xmlLines: string[] = [];

    // KML文件头
    xmlLines.push('<?xml version="1.0" encoding="UTF-8"?>');
    xmlLines.push('<kml xmlns="http://www.opengis.net/kml/2.2">');
    xmlLines.push('<Document>');
    xmlLines.push('');

    // 元数据部分
    if (metadata) {
      xmlLines.push('  <name>' + KMLWriter.escapeXml(metadata.name) + '</name>');
      if (metadata.desc) {
        xmlLines.push('  <description>' + KMLWriter.escapeXml(metadata.desc) + '</description>');
      }
      if (metadata.author) {
        xmlLines.push('  <author>' + KMLWriter.escapeXml(metadata.author) + '</author>');
      }
      if (metadata.time) {
        xmlLines.push('  <TimeStamp>');
        xmlLines.push('    <when>' + metadata.time.toISOString() + '</when>');
        xmlLines.push('  </TimeStamp>');
      }
      xmlLines.push('');
    }

    // 航点部分
    waypoints.forEach(waypoint => {
      xmlLines.push(KMLWriter.waypointToXml(waypoint));
    });

    if (waypoints.length > 0) {
      xmlLines.push('');
    }

    // 轨迹部分
    tracks.forEach(track => {
      xmlLines.push(KMLWriter.trackToXml(track));
    });

    // KML文件尾
    xmlLines.push('</Document>');
    xmlLines.push('</kml>');

    return xmlLines.join('\n');
  }

  /**
   * 将航点转换为XML
   */
  private static waypointToXml(waypoint: Waypoint): string {
    const lines: string[] = [];

    lines.push('  <Placemark>');

    if (waypoint.name) {
      lines.push(`    <name>${KMLWriter.escapeXml(waypoint.name)}</name>`);
    }

    if (waypoint.desc) {
      lines.push(`    <description>${KMLWriter.escapeXml(waypoint.desc)}</description>`);
    }

    if (waypoint.time) {
      lines.push('    <TimeStamp>');
      lines.push(`      <when>${waypoint.time.toISOString()}</when>`);
      lines.push('    </TimeStamp>');
    }

    if (waypoint.sym) {
      lines.push(`    <styleUrl>#${waypoint.sym}</styleUrl>`);
    }

    lines.push('    <Point>');
    lines.push(`      <coordinates>${waypoint.lon},${waypoint.lat}${waypoint.ele !== 0 ? ',' + waypoint.ele : ''}</coordinates>`);
    lines.push('    </Point>');

    lines.push('  </Placemark>');

    return lines.join('\n');
  }

  /**
   * 将轨迹转换为XML
   */
  private static trackToXml(track: Track): string {
    const lines: string[] = [];

    lines.push('  <Placemark>');

    if (track.name) {
      lines.push(`    <name>${KMLWriter.escapeXml(track.name)}</name>`);
    }

    if (track.desc) {
      lines.push(`    <description>${KMLWriter.escapeXml(track.desc)}</description>`);
    }

    if (track.type) {
      lines.push(`    <styleUrl>#${track.type}</styleUrl>`);
    }

    // 轨迹段
    track.segments.forEach((segment, index) => {
      if (segment.length === 0) return;

      lines.push('    <LineString>');
      lines.push('      <coordinates>');

      // 轨迹点坐标
      const coordinates = segment.map(point =>
      `${point.lon},${point.lat}${point.ele !== 0 ? ',' + point.ele : ''}`
      ).join(' ');

      lines.push(`        ${coordinates}`);
      lines.push('      </coordinates>');
      lines.push('    </LineString>');

      // 添加时间戳（使用第一个点的时间）
      if (segment[0].time) {
        lines.push('    <TimeStamp>');
        lines.push(`      <when>${segment[0].time.toISOString()}</when>`);
        lines.push('    </TimeStamp>');
      }
    });

    lines.push('  </Placemark>');

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
}