// import { DOMParser, Document, Element } from '@xmldom/xmldom';
// import { Point, Track, Route, Waypoint, Metadata, Elevation, Parser } from '../RoadTypes';
// import { BusinessError } from '@ohos.base';
//
// export default class GPXParser implements Parser {
//   public xmlSource: string = '';
//   public metadata: Metadata | null = null;
//   public waypoints: Waypoint[] = [];
//   public tracks: Track[] = [];
//   public routes: Route[] = [];
//
//   private EARTH_RADIUS = 6371000; // 地球半径（米）
//
//   parse(gpxContent: string, completeCallback:(error?: Error)=>void) {
//     this.parseXML(gpxContent)
//     if (completeCallback != undefined) {
//       completeCallback()
//     }
//   }
//
//   private parseXML(gpxContent: string): void {
//     try {
//       const parser = new DOMParser();
//       const xmlDoc = parser.parseFromString(gpxContent, "text/xml");
//
//       // 检查解析错误
//       const parserError = xmlDoc.getElementsByTagName("parsererror");
//       if (parserError.length > 0) {
//         throw new Error("XML解析失败: " + parserError[0].textContent);
//       }
//
//       // 解析元数据
//       this.parseMetadata(xmlDoc);
//
//       // 解析航点
//       this.parseWaypoints(xmlDoc);
//
//       // 解析轨迹
//       this.parseTracks(xmlDoc);
//
//       // 解析路线
//       this.parseRoutes(xmlDoc);
//     } catch (error) {
//       console.error(`GPX解析失败: ${(error as BusinessError).message}`);
//       // throw error;
//     }
//   }
//
//   private parseMetadata(xmlDoc: Document): void {
//     const metadataElement = xmlDoc.getElementsByTagName("metadata")[0];
//     if (!metadataElement) return;
//
//     this.metadata = new Metadata();
//
//     // 基本信息
//     this.metadata.name = this.getTextContent(metadataElement, "name") || '';
//     this.metadata.desc = this.getTextContent(metadataElement, "desc") || '';
//     this.metadata.keywords = this.getTextContent(metadataElement, "keywords") || '';
//
//     // 时间
//     const timeStr = this.getTextContent(metadataElement, "time");
//     if (timeStr) {
//       this.metadata.time = new Date(timeStr);
//     }
//
//     // 作者
//     const authorElement = metadataElement.getElementsByTagName("author")[0];
//     if (authorElement) {
//       this.metadata.author = this.getTextContent(authorElement, "name") || '';
//     }
//
//     // 边界
//     const boundsElement = metadataElement.getElementsByTagName("bounds")[0];
//     if (boundsElement) {
//       this.metadata.bounds.minlat = parseFloat(boundsElement.getAttribute("minlat") || "0");
//       this.metadata.bounds.minlon = parseFloat(boundsElement.getAttribute("minlon") || "0");
//       this.metadata.bounds.maxlat = parseFloat(boundsElement.getAttribute("maxlat") || "0");
//       this.metadata.bounds.maxlon = parseFloat(boundsElement.getAttribute("maxlon") || "0");
//     }
//   }
//
//   private parseWaypoints(xmlDoc: Document): void {
//     const waypoints = xmlDoc.getElementsByTagName("wpt");
//
//     for (let i = 0; i < waypoints.length; i++) {
//       const wpt = waypoints[i];
//       const waypoint = new Waypoint();
//
//       // 基本位置信息
//       waypoint.lat = parseFloat(wpt.getAttribute("lat") || "0");
//       waypoint.lon = parseFloat(wpt.getAttribute("lon") || "0");
//
//       // 高程
//       const ele = this.getTextContent(wpt, "ele");
//       if (ele) waypoint.ele = parseFloat(ele);
//
//       // 时间
//       const time = this.getTextContent(wpt, "time");
//       if (time) waypoint.time = new Date(time);
//
//       // 心率
//       const hr = this.getTextContent(wpt, "hr");
//       if (hr) waypoint.hr = parseInt(hr);
//
//       // 踏频
//       const cad = this.getTextContent(wpt, "cad");
//       if (cad) waypoint.cad = parseInt(cad);
//
//       // 航点属性
//       waypoint.name = this.getTextContent(wpt, "name");
//       waypoint.cmt = this.getTextContent(wpt, "cmt");
//       waypoint.desc = this.getTextContent(wpt, "desc");
//       waypoint.sym = this.getTextContent(wpt, "sym");
//       waypoint.type = this.getTextContent(wpt, "type");
//
//       this.waypoints.push(waypoint);
//     }
//   }
//
//   private parseTracks(xmlDoc: Document): void {
//     const tracks = xmlDoc.getElementsByTagName("trk");
//
//     for (let i = 0; i < tracks.length; i++) {
//       const trk = tracks[i];
//       const track = new Track();
//
//       // 轨迹属性
//       track.name = this.getTextContent(trk, "name") || '';
//       track.cmt = this.getTextContent(trk, "cmt");
//       track.desc = this.getTextContent(trk, "desc");
//       track.src = this.getTextContent(trk, "src");
//       track.type = this.getTextContent(trk, "type");
//
//       // 解析轨迹段
//       const segments = trk.getElementsByTagName("trkseg");
//       for (let j = 0; j < segments.length; j++) {
//         const seg = segments[j];
//         const segmentPoints: Point[] = [];
//         const points = seg.getElementsByTagName("trkpt");
//
//         for (let k = 0; k < points.length; k++) {
//           const pt = points[k];
//           const point = new Point();
//
//           point.lat = parseFloat(pt.getAttribute("lat") || "0");
//           point.lon = parseFloat(pt.getAttribute("lon") || "0");
//
//           const ele = this.getTextContent(pt, "ele");
//           if (ele) point.ele = parseFloat(ele);
//
//           const time = this.getTextContent(pt, "time");
//           if (time) point.time = new Date(time);
//
//           const hr = this.getTextContent(pt, "hr");
//           if (hr) point.hr = parseInt(hr);
//
//           const cad = this.getTextContent(pt, "cad");
//           if (cad) point.cad = parseInt(cad);
//
//           segmentPoints.push(point);
//         }
//
//         track.segments.push(segmentPoints);
//       }
//
//       // 计算轨迹统计信息
//       this.calculateTrackStats(track);
//
//       this.tracks.push(track);
//     }
//   }
//
//   private parseRoutes(xmlDoc: Document): void {
//     const routes = xmlDoc.getElementsByTagName("rte");
//
//     for (let i = 0; i < routes.length; i++) {
//       const rte = routes[i];
//       const route = new Route();
//
//       // 路线属性
//       route.name = this.getTextContent(rte, "name") || '';
//       route.cmt = this.getTextContent(rte, "cmt");
//       route.desc = this.getTextContent(rte, "desc");
//       route.src = this.getTextContent(rte, "src");
//       route.type = this.getTextContent(rte, "type");
//
//       // 解析路线点
//       const points = rte.getElementsByTagName("rtept");
//       for (let j = 0; j < points.length; j++) {
//         const pt = points[j];
//         const point = new Point();
//
//         point.lat = parseFloat(pt.getAttribute("lat") || "0");
//         point.lon = parseFloat(pt.getAttribute("lon") || "0");
//
//         const ele = this.getTextContent(pt, "ele");
//         if (ele) point.ele = parseFloat(ele);
//
//         const time = this.getTextContent(pt, "time");
//         if (time) point.time = new Date(time);
//
//         const hr = this.getTextContent(pt, "hr");
//         if (hr) point.hr = parseInt(hr);
//
//         const cad = this.getTextContent(pt, "cad");
//         if (cad) point.cad = parseInt(cad);
//
//         route.points.push(point);
//       }
//
//       // 计算路线统计信息
//       this.calculateRouteStats(route);
//
//       this.routes.push(route);
//     }
//   }
//
//   private calculateTrackStats(track: Track): void {
//     let totalDistance = 0;
//     let cumulDistance = 0;
//     let elevationStats = new Elevation();
//     let slopes: number[] = [];
//
//     // 遍历所有轨迹段
//     for (const segment of track.segments) {
//       if (segment.length === 0) continue;
//
//       // 初始化第一个点的高程
//       elevationStats.max = Math.max(elevationStats.max, segment[0].ele);
//       elevationStats.min = Math.min(elevationStats.min, segment[0].ele);
//
//       // 遍历段内点
//       for (let i = 1; i < segment.length; i++) {
//         const prev = segment[i - 1];
//         const curr = segment[i];
//
//         // 计算距离
//         const distance = this.calculateDistance(prev, curr);
//         totalDistance += distance;
//         cumulDistance += distance;
//         track.distance.cumul.push(cumulDistance);
//
//         // 计算高程变化
//         if (prev.ele !== undefined && curr.ele !== undefined) {
//           const elevationDiff = curr.ele - prev.ele;
//
//           // 更新最大最小高程
//           elevationStats.max = Math.max(elevationStats.max, curr.ele);
//           elevationStats.min = Math.min(elevationStats.min, curr.ele);
//
//           // 累计爬升和下降
//           if (elevationDiff > 0) {
//             elevationStats.pos += elevationDiff;
//           } else {
//             elevationStats.neg += Math.abs(elevationDiff);
//           }
//
//           // 计算坡度（百分比）
//           if (distance > 0) {
//             const slope = (elevationDiff / distance) * 100;
//             slopes.push(slope);
//           }
//         }
//       }
//     }
//
//     // 设置轨迹统计信息
//     track.distance.total = totalDistance;
//     track.elevation = elevationStats;
//
//     // 计算平均高程
//     if (track.segments.length > 0 && track.segments[0].length > 0) {
//       let totalElevation = 0;
//       let count = 0;
//
//       for (const segment of track.segments) {
//         for (const point of segment) {
//           if (point.ele !== undefined) {
//             totalElevation += point.ele;
//             count++;
//           }
//         }
//       }
//
//       if (count > 0) {
//         track.elevation.avg = totalElevation / count;
//       }
//     }
//
//     // 设置坡度
//     track.slopes = slopes;
//   }
//
//   private calculateRouteStats(route: Route): void {
//     let totalDistance = 0;
//     let cumulDistance = 0;
//
//     if (route.points.length === 0) return;
//
//     // 初始化累计距离数组
//     route.distance.cumul.push(0);
//
//     // 遍历路线点
//     for (let i = 1; i < route.points.length; i++) {
//       const prev = route.points[i - 1];
//       const curr = route.points[i];
//
//       // 计算距离
//       const distance = this.calculateDistance(prev, curr);
//       totalDistance += distance;
//       cumulDistance += distance;
//       route.distance.cumul.push(cumulDistance);
//     }
//
//     // 设置总距离
//     route.distance.total = totalDistance;
//   }
//
//   private calculateDistance(p1: Point, p2: Point): number {
//     // 使用Haversine公式计算球面距离
//     const dLat = this.toRadians(p2.lat - p1.lat);
//     const dLon = this.toRadians(p2.lon - p1.lon);
//
//     const a =
//       Math.sin(dLat / 2) * Math.sin(dLat / 2) +
//         Math.cos(this.toRadians(p1.lat)) *
//         Math.cos(this.toRadians(p2.lat)) *
//         Math.sin(dLon / 2) * Math.sin(dLon / 2);
//
//     const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
//
//     return this.EARTH_RADIUS * c;
//   }
//
//   private toRadians(degrees: number): number {
//     return degrees * Math.PI / 180;
//   }
//
//   private getTextContent(element: Element, tagName: string): string | undefined {
//     const elements = element.getElementsByTagName(tagName);
//     return elements.length > 0 ? (elements[0].textContent != null ? elements[0].textContent : undefined) : undefined;
//   }
//
//   /**
//    * 计算轨迹数据
//    * @param track - 轨迹对象
//    */
//   private calculateTrackData(track: Track): void {
//     if (track.segments.length === 0) return;
//
//     // 合并所有段落的点
//     const allPoints: Point[] = [];
//     track.segments.forEach(segment => {
//       allPoints.push(...segment);
//     });
//
//     if (allPoints.length < 2) return;
//
//     // 计算距离
//     track.distance.total = 0;
//     track.distance.cumul = [0];
//
//     for (let i = 1; i < allPoints.length; i++) {
//       const dist = GPXParser.calculateDistance(
//         allPoints[i - 1].lat, allPoints[i - 1].lon,
//         allPoints[i].lat, allPoints[i].lon
//       );
//       track.distance.total += dist;
//       track.distance.cumul.push(track.distance.total);
//     }
//
//     // 计算高程数据
//     let elevationSum = 0;
//     track.elevation.max = -Infinity;
//     track.elevation.min = Infinity;
//     track.elevation.pos = 0;
//     track.elevation.neg = 0;
//
//     allPoints.forEach(point => {
//       if (point.ele) {
//         elevationSum += point.ele;
//         if (point.ele > track.elevation.max) track.elevation.max = point.ele;
//         if (point.ele < track.elevation.min) track.elevation.min = point.ele;
//       }
//     });
//
//     // 计算累计爬升和下降
//     for (let i = 1; i < allPoints.length; i++) {
//       if (allPoints[i].ele && allPoints[i - 1].ele) {
//         const diff = allPoints[i].ele - allPoints[i - 1].ele;
//         if (diff > 0) {
//           track.elevation.pos += diff;
//         } else {
//           track.elevation.neg += Math.abs(diff);
//         }
//       }
//     }
//
//     // 计算平均高程
//     track.elevation.avg = elevationSum / allPoints.length;
//
//     // 计算坡度
//     track.slopes = [];
//     for (let i = 1; i < allPoints.length; i++) {
//       if (allPoints[i].ele && allPoints[i - 1].ele) {
//         const dist = GPXParser.calculateDistance(
//           allPoints[i - 1].lat, allPoints[i - 1].lon,
//           allPoints[i].lat, allPoints[i].lon
//         );
//         const eleDiff = allPoints[i].ele - allPoints[i - 1].ele;
//         const slope = dist > 0 ? (eleDiff / dist) * 100 : 0;
//         track.slopes.push(slope);
//       }
//     }
//   }
//
//   /**
//    * 计算两点间距离（使用Haversine公式）
//    * @param lat1 - 点1纬度
//    * @param lon1 - 点1经度
//    * @param lat2 - 点2纬度
//    * @param lon2 - 点2经度
//    * @returns 距离（米）
//    */
//   static calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
//     const R = 6371e3; // 地球半径（米）
//     const φ1 = lat1 * Math.PI / 180;
//     const φ2 = lat2 * Math.PI / 180;
//     const Δφ = (lat2 - lat1) * Math.PI / 180;
//     const Δλ = (lon2 - lon1) * Math.PI / 180;
//
//     const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
//       Math.cos(φ1) * Math.cos(φ2) *
//       Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
//     const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
//
//     return R * c;
//   }
//
//   /**
//    * 百分比区间裁剪Track上的轨迹点
//    * @param track - 轨道对象
//    * @param from - 起始百分比
//    * @param to - 终止百分比
//    */
//   trimTrackPoints(track: Track, from: number, to: number) {
//     if (track.segments.length === 0) return;
//
//     for (let n = 0; n < track.segments.length; n++) {
//       track.segments[n] = track.segments[n].slice(from, to)
//     }
//     this.calculateTrackData(track)
//   }
// }
