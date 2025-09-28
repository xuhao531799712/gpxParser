import { Track, Point, Metadata } from '../RoadTypes';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';

export class TCXWriter {
  /**
   * 将轨迹数据写入TCX文件
   * @param tracks 轨迹数组
   * @param filePath 文件保存路径
   * @param metadata 可选的元数据
   */
  static async writeTCXFile(
    tracks: Track[],
    filePath: string,
    metadata?: Metadata
  ): Promise<boolean> {
    try {
      // 生成TCX XML内容
      const tcxContent = TCXWriter.generateTCXContent(tracks, metadata);

      // 创建文件并写入内容
      const file = await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      await fs.write(file.fd, tcxContent);
      await fs.close(file.fd);

      console.log(`TCX文件已保存: ${filePath}`);
      return true;
    } catch (error) {
      console.error(`保存TCX文件失败: ${(error as BusinessError).message}`);
      return false;
    }
  }

  /**
   * 生成TCX XML内容
   */
  private static generateTCXContent(
    tracks: Track[],
    metadata?: Metadata
  ): string {
    const xmlLines: string[] = [];

    // TCX文件头
    xmlLines.push('<?xml version="1.0" encoding="UTF-8"?>');
    xmlLines.push('<TrainingCenterDatabase xmlns="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2"');
    xmlLines.push('  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"');
    xmlLines.push('  xsi:schemaLocation="http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2 http://www.garmin.com/xmlschemas/TrainingCenterDatabasev2.xsd"');
    xmlLines.push('  xmlns:ns2="http://www.garmin.com/xmlschemas/UserProfile/v2"');
    xmlLines.push('  xmlns:ns3="http://www.garmin.com/xmlschemas/ActivityExtension/v2">');
    xmlLines.push('');

    // 活动部分
    xmlLines.push('  <Activities>');

    tracks.forEach((track, index) => {
      xmlLines.push(TCXWriter.trackToActivity(track, index));
    });

    xmlLines.push('  </Activities>');
    xmlLines.push('');

    // 作者信息（使用元数据）
    if (metadata?.author) {
      xmlLines.push('  <Author xsi:type="Application_t">');
      xmlLines.push(`    <Name>${TCXWriter.escapeXml(metadata.author)}</Name>`);
      xmlLines.push('    <Build>');
      xmlLines.push('      <Version>');
      xmlLines.push('        <VersionMajor>1</VersionMajor>');
      xmlLines.push('        <VersionMinor>0</VersionMinor>');
      xmlLines.push('      </Version>');
      xmlLines.push('    </Build>');
      xmlLines.push('  </Author>');
    }

    xmlLines.push('</TrainingCenterDatabase>');

    return xmlLines.join('\n');
  }

  /**
   * 将轨迹转换为TCX活动
   */
  private static trackToActivity(track: Track, index: number): string {
    const lines: string[] = [];

    // 活动类型（默认为骑行）
    const sport = track.type || 'Biking';

    lines.push(`    <Activity Sport="${sport}">`);

    if (track.name) {
      lines.push(`      <Notes>${TCXWriter.escapeXml(track.name)}</Notes>`);
    }

    // 轨迹段作为单独的Lap
    track.segments.forEach((segment, lapIndex) => {
      if (segment.length === 0) return;

      const startTime = segment[0].time || new Date();
      const endTime = segment[segment.length - 1].time || new Date();
      const duration = (endTime.getTime() - startTime.getTime()) / 1000;
      const distance = track.distance?.total || 0;

      lines.push(`      <Lap StartTime="${startTime.toISOString()}">`);
      lines.push(`        <TotalTimeSeconds>${duration}</TotalTimeSeconds>`);
      lines.push(`        <DistanceMeters>${distance}</DistanceMeters>`);

      lines.push(`        <Intensity>Active</Intensity>`);
      lines.push(`        <TriggerMethod>Manual</TriggerMethod>`);

      // 轨迹点
      lines.push(`        <Track>`);
      segment.forEach(point => {
        lines.push(TCXWriter.trackPointToXml(point));
      });
      lines.push(`        </Track>`);

      lines.push(`      </Lap>`);
    });

    lines.push(`    </Activity>`);

    return lines.join('\n');
  }

  /**
   * 将轨迹点转换为XML
   */
  private static trackPointToXml(point: Point): string {
    const lines: string[] = [];

    lines.push(`          <Trackpoint>`);

    // 时间
    if (point.time) {
      lines.push(`            <Time>${point.time.toISOString()}</Time>`);
    }

    // 位置
    if (point.lat !== 0 && point.lon !== 0) {
      lines.push(`            <Position>`);
      lines.push(`              <LatitudeDegrees>${point.lat}</LatitudeDegrees>`);
      lines.push(`              <LongitudeDegrees>${point.lon}</LongitudeDegrees>`);
      lines.push(`            </Position>`);
    }

    // 高程
    if (point.ele !== 0) {
      lines.push(`            <AltitudeMeters>${point.ele}</AltitudeMeters>`);
    }

    // 心率
    if (point.hr !== undefined && point.hr > 0) {
      lines.push(`            <HeartRateBpm>`);
      lines.push(`              <Value>${point.hr}</Value>`);
      lines.push(`            </HeartRateBpm>`);
    }

    // 踏频
    if (point.cad !== undefined && point.cad > 0) {
      lines.push(`            <Cadence>${point.cad}</Cadence>`);
    }

    // 扩展数据（速度、功率等）
    const extensions = TCXWriter.getPointExtensions(point);
    if (extensions) {
      lines.push(`            <Extensions>`);
      lines.push(extensions);
      lines.push(`            </Extensions>`);
    }

    lines.push(`          </Trackpoint>`);

    return lines.join('\n');
  }

  /**
   * 获取点的扩展数据
   */
  private static getPointExtensions(point: Point): string | null {
    const extensions: string[] = [];

    if (extensions.length > 0) {
      return `<ns3:TPX>${extensions.join('\n')}</ns3:TPX>`;
    }

    return null;
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