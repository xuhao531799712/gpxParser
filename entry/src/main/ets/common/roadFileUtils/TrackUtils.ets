import { Point, Track, Route, Waypoint, Metadata } from './RoadTypes';

export class TrackUtils {
  /**
   * 计算轨迹数据
   * @param track - 轨迹对象
   */
  static calculateTrackData(track: Track): void {
    if (track.segments.length === 0) return;

    // 合并所有段落的点
    const allPoints: Point[] = [];
    track.segments.forEach(segment => {
      allPoints.push(...segment);
    });

    if (allPoints.length < 2) return;

    // 计算距离
    track.distance.total = 0;
    track.distance.cumul = [0];

    for (let i = 1; i < allPoints.length; i++) {
      const dist = TrackUtils.calculateDistance(
        allPoints[i - 1].lat, allPoints[i - 1].lon,
        allPoints[i].lat, allPoints[i].lon
      );
      track.distance.total += dist;
      track.distance.cumul.push(track.distance.total);
    }

    // 计算高程数据
    let elevationSum = 0;
    track.elevation.max = -Infinity;
    track.elevation.min = Infinity;
    track.elevation.pos = 0;
    track.elevation.neg = 0;

    allPoints.forEach(point => {
      if (point.ele) {
        elevationSum += point.ele;
        if (point.ele > track.elevation.max) track.elevation.max = point.ele;
        if (point.ele < track.elevation.min) track.elevation.min = point.ele;
      }
    });

    // 计算累计爬升和下降
    for (let i = 1; i < allPoints.length; i++) {
      if (allPoints[i].ele && allPoints[i - 1].ele) {
        const diff = allPoints[i].ele - allPoints[i - 1].ele;
        if (diff > 0) {
          track.elevation.pos += diff;
        } else {
          track.elevation.neg += Math.abs(diff);
        }
      }
    }

    // 计算平均高程
    track.elevation.avg = elevationSum / allPoints.length;

    // 计算坡度
    track.slopes = [];
    for (let i = 1; i < allPoints.length; i++) {
      if (allPoints[i].ele && allPoints[i - 1].ele) {
        const dist = TrackUtils.calculateDistance(
          allPoints[i - 1].lat, allPoints[i - 1].lon,
          allPoints[i].lat, allPoints[i].lon
        );
        const eleDiff = allPoints[i].ele - allPoints[i - 1].ele;
        const slope = dist > 0 ? (eleDiff / dist) * 100 : 0;
        track.slopes.push(slope);
      }
    }
  }

  /**
   * 计算两点间距离（使用Haversine公式）
   * @param lat1 - 点1纬度
   * @param lon1 - 点1经度
   * @param lat2 - 点2纬度
   * @param lon2 - 点2经度
   * @returns 距离（米）
   */
  static calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371e3; // 地球半径（米）
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lon2 - lon1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
      Math.cos(φ1) * Math.cos(φ2) *
      Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
  }

  /**
   * 翻转Track上轨迹点方向
   * @param track - 轨道对象
   */
  static revertTrackPoints(track: Track) {
    if (track.segments.length === 0) return;

    for (let n = 0; n < track.segments.length; n++) {
      track.segments[n] = track.segments[n].reverse();
    }
    TrackUtils.calculateTrackData(track);
  }

  /**
   * 百分比区间裁剪Track上的轨迹点
   * @param track - 轨道对象
   * @param from - 起始百分比
   * @param to - 终止百分比
   */
  static trimTrackPoints(track: Track, from: number, to: number) {
    if (track.segments.length === 0) return;

    for (let n = 0; n < track.segments.length; n++) {
      track.segments[n] = track.segments[n].slice(from, to);
    }
    TrackUtils.calculateTrackData(track);
  }
}