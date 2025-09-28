// import { xml, util } from '@kit.ArkTS';
// import { Point, Track, Route, Waypoint, Metadata, Distance, Elevation } from '../RoadTypes';
//
// export default class TCXParser {
//   public xmlSource: string = '';
//   public metadata: Metadata | null = null;
//   public tracks: Track[] = [];
//   private completeCallback: ((error?: Error) => void) | undefined = undefined;
//
//   constructor() {
//     // 初始化
//   }
//
//   /**
//    * 解析 TCX 字符串
//    * @param tcxString - TCX XML 字符串
//    * @param completeCallback - 解析完成回调
//    */
//   parse(tcxString: string, completeCallback: (error?: Error) => void): void {
//     this.xmlSource = tcxString;
//     this.completeCallback = completeCallback;
//     this.parseXML(tcxString);
//   }
//
//   /**
//    * 解析 XML 内容
//    * @param xmlString - XML 字符串
//    */
//   private parseXML(xmlString: string): void {
//     try {
//       let textEncoder: util.TextEncoder = new util.TextEncoder();
//       let arrBuffer: Uint8Array = textEncoder.encodeInto(xmlString);
//       const parser = new xml.XmlPullParser(arrBuffer.buffer as object as ArrayBuffer, 'UTF-8');
//
//       let currentTrack: Track | null = null;
//       let currentSegment: Point[] = [];
//       let currentPoint: Point | null = null;
//       let currentElement: string = '';
//       let currentActivity: any = null;
//       let currentLap: any = null;
//       let currentHeartRate: number | null = null;
//       let currentCadence: number | null = null;
//       let currentDistance: number | null = null;
//       let currentAltitude: number | null = null;
//
//       let tokenFunc: (name: xml.EventType, value: xml.ParseInfo) => boolean =
//         (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
//           if (eventType !== xml.EventType.END_DOCUMENT) {
//             switch (eventType) {
//               case xml.EventType.START_TAG:
//                 const tagName = info.getName();
//                 switch (tagName) {
//                   case 'TrainingCenterDatabase':
//                     // 根元素
//                     break;
//                   case 'Activities':
//                     // 活动容器
//                     break;
//                   case 'Activity':
//                     currentActivity = {
//                       sport: info.getAttributeValue(null, 'Sport') || 'Other',
//                       id: ''
//                     };
//                     break;
//                   case 'Id':
//                     currentElement = 'id';
//                     break;
//                   case 'Lap':
//                     currentLap = {
//                       startTime: info.getAttributeValue(null, 'StartTime') || '',
//                       totalTime: 0,
//                       distance: 0,
//                       calories: 0
//                     };
//                     if (currentTrack) {
//                       currentTrack.segments.push([]);
//                     }
//                     break;
//                   case 'TotalTimeSeconds':
//                     currentElement = 'TotalTimeSeconds';
//                     break;
//                   case 'DistanceMeters':
//                     currentElement = 'DistanceMeters';
//                     break;
//                   case 'Calories':
//                     currentElement = 'Calories';
//                     break;
//                   case 'Track':
//                     // 轨迹段开始
//                     currentSegment = [];
//                     break;
//                   case 'Trackpoint':
//                     currentPoint = this.createPoint();
//                     currentHeartRate = null;
//                     currentCadence = null;
//                     currentDistance = null;
//                     currentAltitude = null;
//                     break;
//                   case 'Time':
//                     currentElement = 'Time';
//                     break;
//                   case 'Position':
//                     // 位置信息开始
//                     break;
//                   case 'LatitudeDegrees':
//                     currentElement = 'LatitudeDegrees';
//                     break;
//                   case 'LongitudeDegrees':
//                     currentElement = 'LongitudeDegrees';
//                     break;
//                   case 'AltitudeMeters':
//                     currentElement = 'AltitudeMeters';
//                     break;
//                   case 'DistanceMeters':
//                     currentElement = 'DistanceMeters';
//                     break;
//                   case 'HeartRateBpm':
//                     currentElement = 'HeartRateBpm';
//                     break;
//                   case 'Value':
//                     if (currentElement === 'HeartRateBpm') {
//                       currentElement = 'HeartRateValue';
//                     }
//                     break;
//                   case 'Cadence':
//                     currentElement = 'Cadence';
//                     break;
//                   case 'Extensions':
//                     // 扩展数据开始
//                     break;
//                   case 'TPX':
//                     // Garmin 扩展命名空间
//                     break;
//                   case 'Speed':
//                     currentElement = 'Speed';
//                     break;
//                   case 'Watts':
//                     currentElement = 'Watts';
//                     break;
//                 }
//                 break;
//
//               case xml.EventType.TEXT:
//               case xml.EventType.CDSECT:
//                 const text = info.getText();
//                 if (currentElement && text) {
//                   switch (currentElement) {
//                     case 'id':
//                       if (currentActivity) {
//                         currentActivity.id = text;
//                       }
//                       break;
//                     case 'TotalTimeSeconds':
//                       if (currentLap) {
//                         currentLap.totalTime = parseFloat(text);
//                       }
//                       break;
//                     case 'DistanceMeters':
//                       if (currentLap) {
//                         currentLap.distance = parseFloat(text);
//                       } else if (currentPoint) {
//                         currentDistance = parseFloat(text);
//                       }
//                       break;
//                     case 'Calories':
//                       if (currentLap) {
//                         currentLap.calories = parseInt(text);
//                       }
//                       break;
//                     case 'Time':
//                       if (currentPoint) {
//                         currentPoint.time = new Date(text);
//                       }
//                       break;
//                     case 'LatitudeDegrees':
//                       if (currentPoint) {
//                         currentPoint.lat = parseFloat(text);
//                       }
//                       break;
//                     case 'LongitudeDegrees':
//                       if (currentPoint) {
//                         currentPoint.lon = parseFloat(text);
//                       }
//                       break;
//                     case 'AltitudeMeters':
//                       if (currentPoint) {
//                         currentAltitude = parseFloat(text);
//                       }
//                       break;
//                     case 'HeartRateValue':
//                       if (currentPoint) {
//                         currentHeartRate = parseInt(text);
//                       }
//                       break;
//                     case 'Cadence':
//                       if (currentPoint) {
//                         currentCadence = parseInt(text);
//                       }
//                       break;
//                     case 'Speed':
//                       if (currentPoint) {
//                         // 速度转换为 m/s
//                         currentPoint.speed = parseFloat(text);
//                       }
//                       break;
//                     case 'Watts':
//                       if (currentPoint) {
//                         currentPoint.power = parseFloat(text);
//                       }
//                       break;
//                   }
//                 }
//                 break;
//
//               case xml.EventType.END_TAG:
//                 const endTagName = info.getName();
//                 switch (endTagName) {
//                   case 'Activity':
//                     if (currentActivity) {
//                       if (!this.metadata) {
//                         this.metadata = {
//                           name: '',
//                           desc: '',
//                           author: '',
//                           time: new Date(),
//                           keywords: '',
//                           bounds: {
//                             minlat: 0,
//                             minlon: 0,
//                             maxlat: 0,
//                             maxlon: 0
//                           }
//                         };
//                       }
//                       this.metadata.name = currentActivity.sport + ' Activity';
//                       this.metadata.time = new Date(currentActivity.id);
//                       currentActivity = null;
//                     }
//                     break;
//                   case 'Lap':
//                     if (currentLap && currentTrack) {
//                       // 计算圈数据
//                       this.calculateLapData(currentTrack, currentLap);
//                       currentLap = null;
//                     }
//                     break;
//                   case 'Track':
//                     if (currentTrack && currentSegment.length > 0) {
//                       currentTrack.segments.push(currentSegment);
//                       currentSegment = [];
//                     }
//                     break;
//                   case 'Trackpoint':
//                     if (currentPoint) {
//                       // 设置高程
//                       if (currentAltitude !== null) {
//                         currentPoint.ele = currentAltitude;
//                       }
//
//                       // 设置心率
//                       if (currentHeartRate !== null) {
//                         currentPoint.hr = currentHeartRate;
//                       }
//
//                       // 设置踏频
//                       if (currentCadence !== null) {
//                         currentPoint.cad = currentCadence;
//                       }
//
//                       // 设置距离
//                       if (currentDistance !== null) {
//                         currentPoint.distance = currentDistance;
//                       }
//
//                       currentSegment.push(currentPoint);
//                       currentPoint = null;
//                     }
//                     break;
//                   case 'Position':
//                   case 'HeartRateBpm':
//                   case 'Extensions':
//                   case 'TPX':
//                     // 重置当前元素
//                     currentElement = '';
//                     break;
//                   case 'LatitudeDegrees':
//                   case 'LongitudeDegrees':
//                   case 'AltitudeMeters':
//                   case 'DistanceMeters':
//                   case 'Time':
//                   case 'Value':
//                   case 'Cadence':
//                   case 'Speed':
//                   case 'Watts':
//                   case 'TotalTimeSeconds':
//                   case 'Calories':
//                   case 'Id':
//                     currentElement = '';
//                     break;
//                 }
//                 break;
//             }
//             return true;
//           } else {
//             // 文档结束，计算轨迹数据
//             this.tracks.forEach(track => this.calculateTrackData(track));
//
//             if (this.completeCallback) {
//               this.completeCallback();
//             }
//             return false;
//           }
//         };
//
//       let options: xml.ParseOptions = {
//         supportDoctype: true,
//         ignoreNameSpace: true,
//         tokenValueCallbackFunction: tokenFunc
//       };
//       parser.parseXml(options);
//     } catch (error) {
//       console.error('TCX解析错误: ' + error.message);
//       if (this.completeCallback) {
//         this.completeCallback(error);
//       }
//     }
//   }
//
//   /**
//    * 创建点
//    * @returns 点对象
//    */
//   private createPoint(): Point {
//     return {
//       lat: 0,
//       lon: 0,
//       ele: 0,
//       time: new Date(),
//       hr: 0,
//       cad: 0,
//       distance: 0,
//       speed: 0,
//       power: 0
//     };
//   }
//
//   /**
//    * 初始化轨迹
//    * @returns 新轨迹对象
//    */
//   private initTrack(): Track {
//     return {
//       name: '',
//       cmt: '',
//       desc: '',
//       src: '',
//       type: '',
//       segments: [],
//       distance: {
//         total: 0,
//         cumul: []
//       },
//       elevation: {
//         max: -Infinity,
//         min: Infinity,
//         pos: 0,
//         neg: 0,
//         avg: 0
//       },
//       slopes: [],
//       speed: {
//         max: 0,
//         min: Infinity,
//         avg: 0
//       },
//       heartRate: {
//         max: 0,
//         min: Infinity,
//         avg: 0
//       },
//       cadence: {
//         max: 0,
//         min: Infinity,
//         avg: 0
//       },
//       power: {
//         max: 0,
//         min: Infinity,
//         avg: 0
//       }
//     };
//   }
//
//   /**
//    * 计算圈数据
//    * @param track - 轨迹对象
//    * @param lap - 圈数据
//    */
//   private calculateLapData(track: Track, lap: any): void {
//     if (track.segments.length === 0) return;
//
//     const segment = track.segments[track.segments.length - 1];
//     if (segment.length === 0) return;
//
//     // 设置圈的总距离
//     if (lap.distance > track.distance.total) {
//       track.distance.total = lap.distance;
//     }
//
//     // 计算累计距离
//     let cumulDistance = 0;
//     for (let i = 0; i < segment.length; i++) {
//       if (segment[i].distance !== undefined) {
//         cumulDistance = segment[i].distance;
//         track.distance.cumul.push(cumulDistance);
//       }
//     }
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
//     if (allPoints.length === 0) return;
//
//     // 初始化统计数据
//     track.elevation.max = -Infinity;
//     track.elevation.min = Infinity;
//     track.speed.max = 0;
//     track.speed.min = Infinity;
//     track.heartRate.max = 0;
//     track.heartRate.min = Infinity;
//     track.cadence.max = 0;
//     track.cadence.min = Infinity;
//     track.power.max = 0;
//     track.power.min = Infinity;
//
//     let elevationSum = 0;
//     let speedSum = 0;
//     let hrSum = 0;
//     let cadSum = 0;
//     let powerSum = 0;
//     let validElevationCount = 0;
//     let validSpeedCount = 0;
//     let validHrCount = 0;
//     let validCadCount = 0;
//     let validPowerCount = 0;
//
//     // 第一遍遍历：计算最大值、最小值和总和
//     allPoints.forEach(point => {
//       // 高程
//       if (point.ele !== undefined) {
//         elevationSum += point.ele;
//         validElevationCount++;
//
//         if (point.ele > track.elevation.max) track.elevation.max = point.ele;
//         if (point.ele < track.elevation.min) track.elevation.min = point.ele;
//       }
//
//       // 速度
//       if (point.speed !== undefined) {
//         speedSum += point.speed;
//         validSpeedCount++;
//
//         if (point.speed > track.speed.max) track.speed.max = point.speed;
//         if (point.speed < track.speed.min) track.speed.min = point.speed;
//       }
//
//       // 心率
//       if (point.hr !== undefined) {
//         hrSum += point.hr;
//         validHrCount++;
//
//         if (point.hr > track.heartRate.max) track.heartRate.max = point.hr;
//         if (point.hr < track.heartRate.min) track.heartRate.min = point.hr;
//       }
//
//       // 踏频
//       if (point.cad !== undefined) {
//         cadSum += point.cad;
//         validCadCount++;
//
//         if (point.cad > track.cadence.max) track.cadence.max = point.cad;
//         if (point.cad < track.cadence.min) track.cadence.min = point.cad;
//       }
//
//       // 功率
//       if (point.power !== undefined) {
//         powerSum += point.power;
//         validPowerCount++;
//
//         if (point.power > track.power.max) track.power.max = point.power;
//         if (point.power < track.power.min) track.power.min = point.power;
//       }
//     });
//
//     // 计算平均值
//     if (validElevationCount > 0) {
//       track.elevation.avg = elevationSum / validElevationCount;
//     }
//
//     if (validSpeedCount > 0) {
//       track.speed.avg = speedSum / validSpeedCount;
//     }
//
//     if (validHrCount > 0) {
//       track.heartRate.avg = hrSum / validHrCount;
//     }
//
//     if (validCadCount > 0) {
//       track.cadence.avg = cadSum / validCadCount;
//     }
//
//     if (validPowerCount > 0) {
//       track.power.avg = powerSum / validPowerCount;
//     }
//
//     // 计算累计爬升和下降
//     track.elevation.pos = 0;
//     track.elevation.neg = 0;
//
//     for (let i = 1; i < allPoints.length; i++) {
//       if (allPoints[i].ele !== undefined && allPoints[i - 1].ele !== undefined) {
//         const diff = allPoints[i].ele - allPoints[i - 1].ele;
//         if (diff > 0) {
//           track.elevation.pos += diff;
//         } else {
//           track.elevation.neg += Math.abs(diff);
//         }
//       }
//     }
//
//     // 计算坡度
//     track.slopes = [];
//     for (let i = 1; i < allPoints.length; i++) {
//       if (allPoints[i].ele !== undefined && allPoints[i - 1].ele !== undefined) {
//         const dist = this.calculateDistance(
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
//   private calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
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
//    * 翻转Track上轨迹点方向
//    * @param track - 轨道对象
//    */
//   revertTrackPoints(track: Track) {
//     if (track.segments.length === 0) return;
//
//     for (let n = 0; n < track.segments.length; n++) {
//       track.segments[n] = track.segments[n].reverse();
//     }
//     this.calculateTrackData(track);
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
//       const segment = track.segments[n];
//       const startIndex = Math.floor(segment.length * from);
//       const endIndex = Math.floor(segment.length * to);
//       track.segments[n] = segment.slice(startIndex, endIndex);
//     }
//     this.calculateTrackData(track);
//   }
// }