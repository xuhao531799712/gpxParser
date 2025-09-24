// GPXParser.ets
import { xml, util } from '@kit.ArkTS';
import { Point, Track, Route, Waypoint, Metadata } from './GPXTypes';

export default class GPXParser {
  public xmlSource: string = '';
  public metadata: Metadata | null = null;
  public waypoints: Waypoint[] = [];
  public tracks: Track[] = [];
  public routes: Route[] = [];
  private completeCallback:((error?: Error)=>void) | undefined = undefined


  constructor() {
    // 初始化
  }

  /**
   * 解析 GPX 字符串
   * @param gpxString - GPX XML 字符串
   */
  parse(gpxString: string, completeCallback:(error?: Error)=>void): void {
    this.xmlSource = gpxString;
    this.completeCallback = completeCallback
    this.parseXML(gpxString);
  }

  /**
   * 解析 XML 内容
   * @param xmlString - XML 字符串
   */
  private parseXML(xmlString: string): void {
    try {
      let textEncoder: util.TextEncoder = new util.TextEncoder();
      let arrBuffer: Uint8Array = textEncoder.encodeInto(xmlString); // 对数据编码，防止包含中文字符乱码
      const parser = new xml.XmlPullParser(arrBuffer.buffer as object as ArrayBuffer, 'UTF-8');

      let currentTrack: Track | null = null;
      let currentRoute: Route | null = null;
      let currentWaypoint: Waypoint | null = null;
      let currentPoint: Point | null = null;
      let currentElement: string = '';
      let currentTrackSegment: Point[] = [];
      let currentRoutePoints: Point[] = [];
      let currentAttr: "gpx" | "wpt" | "trkpt" | "" = ""

      let attFunc: (name: string, value: string) => boolean = (name: string, value: string): boolean => {
        switch (currentAttr) {
          case "gpx":
          case "wpt":
            if (currentWaypoint != null) this.parseWaypointElement(currentWaypoint, name, value)
            break;
          case "trkpt":
            if (currentPoint != null) this.parsePointElement(currentPoint, name, value)
            break;
        }
        return true;
      };

      let tokenFunc: (name: xml.EventType, value: xml.ParseInfo) => boolean =
        (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
          if (eventType !== xml.EventType.END_DOCUMENT) {
              switch (eventType) {
                case xml.EventType.START_TAG:
                  const tagName = info.getName();
                  switch (tagName) {
                    case 'gpx':
                      currentAttr = 'gpx'
                      this.parseGPXAttributes(parser);
                      break;
                    case 'metadata':
                      this.metadata = this.parseMetadata(parser);
                      break;
                    case 'wpt':
                      currentAttr = 'wpt'
                      currentWaypoint = this.createWaypoint();
                      this.waypoints.push(currentWaypoint);
                      break;
                    case 'trk':
                      currentTrack = this.initTrack();
                      this.tracks.push(currentTrack);
                      break;
                    case 'trkseg':
                      currentTrackSegment = [];
                      break;
                    case 'trkpt':
                    case 'rtept':
                      currentAttr = 'trkpt'
                      currentPoint = this.createPoint();
                      if (currentTrack) {
                        currentTrackSegment.push(currentPoint);
                      }
                      break;
                    case 'rte':
                      currentRoute = this.initRoute();
                      this.routes.push(currentRoute);
                      break;
                    case 'ele':
                    case 'time':
                    case 'name':
                    case 'cmt':
                    case 'desc':
                    case 'src':
                    case 'type':
                    case 'sym':
                    case 'fix':
                    case 'sat':
                    case 'hdop':
                    case 'vdop':
                    case 'pdop':
                    case 'ageofdgpsdata':
                    case 'dgpsid':
                    case 'extensions':
                      currentElement = tagName;
                      break;
                  }
                  break;

                case xml.EventType.TEXT:
                case xml.EventType.CDSECT:
                  const text = info.getText();
                  if (currentPoint && currentElement) {
                    this.parsePointElement(currentPoint, currentElement, text);
                  } else if (currentWaypoint && currentElement) {
                    this.parseWaypointElement(currentWaypoint, currentElement, text);
                  } else if (currentTrack && currentElement) {
                    this.parseTrackElement(currentTrack, currentElement, text);
                  } else if (currentRoute && currentElement) {
                    this.parseRouteElement(currentRoute, currentElement, text);
                  }
                  break;

                case xml.EventType.END_TAG:
                  const endTagName = info.getName();
                  switch (endTagName) {
                    case 'trkseg':
                      if (currentTrack && currentTrackSegment.length > 0) {
                        currentTrack.segments.push(currentTrackSegment);
                        this.calculateTrackData(currentTrack);
                      }
                      currentTrackSegment = [];
                      break;
                    case 'rte':
                      if (currentRoute && currentRoutePoints.length > 0) {
                        currentRoute.points = currentRoutePoints;
                        this.calculateRouteData(currentRoute);
                      }
                      currentRoutePoints = [];
                      currentRoute = null;
                      break;
                    case 'trk':
                      currentTrack = null;
                      break;
                    case 'wpt':
                      currentWaypoint = null;
                      break;
                    case 'trkpt':
                    case 'rtept':
                      currentPoint = null;
                      break;
                    case 'ele':
                    case 'time':
                    case 'name':
                    case 'cmt':
                    case 'desc':
                    case 'src':
                    case 'type':
                    case 'sym':
                    case 'fix':
                    case 'sat':
                    case 'hdop':
                    case 'vdop':
                    case 'pdop':
                    case 'ageofdgpsdata':
                    case 'dgpsid':
                    case 'extensions':
                      currentElement = '';
                      break;
                  }
                  break;
              }
            return true
          } else {
            if (this.completeCallback != undefined) {
              // TODO: 切换线程？
              this.completeCallback()
            }
            return false
          }
        };

      // 计算所有轨迹数据
      this.tracks.forEach(track => this.calculateTrackData(track));
      let options: xml.ParseOptions = {
        supportDoctype: true,
        ignoreNameSpace: true,
        attributeValueCallbackFunction:attFunc,
        tokenValueCallbackFunction: tokenFunc
      };
      parser.parseXml(options);
    } catch (error) {
      console.error('GPX解析错误: ' + error.message);
    }
  }

  /**
   * 解析 GPX 属性
   * @param parser - XML 解析器
   */
  private parseGPXAttributes(parser: xml.XmlPullParser): void {
    // 可以在此处处理GPX版本等属性
  }

  /**
   * 解析元数据
   * @param parser - XML 解析器
   * @returns 元数据对象
   */
  private parseMetadata(parser: xml.XmlPullParser): Metadata {
    const metadata: Metadata = {
      name: '',
      desc: '',
      author: '',
      time: new Date(),
      keywords: '',
      bounds: {
        minlat: 0,
        minlon: 0,
        maxlat: 0,
        maxlon: 0
      }
    };

    // 实际解析逻辑需要根据XML结构实现
    return metadata;
  }

  /**
   * 初始化轨迹
   * @returns 新轨迹对象
   */
  private initTrack(): Track {
    return {
      name: '',
      cmt: '',
      desc: '',
      src: '',
      type: '',
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
   * 初始化路径
   * @returns 新路径对象
   */
  private initRoute(): Route {
    return {
      name: '',
      cmt: '',
      desc: '',
      src: '',
      type: '',
      points: [],
      distance: {
        total: 0,
        cumul: []
      }
    };
  }

  /**
   * 创建航点
   * @returns 航点对象
   */
  private createWaypoint(): Waypoint {
    return {
      lat: 0,
      lon: 0,
      ele: 0,
      time: new Date(),
      name: '',
      cmt: '',
      desc: '',
      sym: '',
      type: ''
    };
  }

  /**
   * 创建解析点（轨迹点或路径点）
   * @returns 点对象
   */
  private createPoint(): Point {
    return {
      lat: 0,
      lon: 0,
      ele: 0,
      time: new Date(),
      hr: 0,
      cad: 0
    };
  }

  /**
   * 解析点元素
   * @param point - 点对象
   * @param element - 元素名称
   * @param text - 元素文本内容
   */
  private parsePointElement(point: Point, element: string, text: string): void {
    switch (element) {
      case 'lat':
        point.lat = parseFloat(text);
        break;
      case 'lon':
        point.lon = parseFloat(text);
        break;
      case 'ele':
        point.ele = parseFloat(text);
        break;
      case 'time':
        point.time = new Date(text);
        break;
      case 'hr':
        point.hr = parseInt(text);
        break;
      case 'cad':
        point.cad = parseInt(text);
        break;
    }
  }

  /**
   * 解析航点元素
   * @param waypoint - 航点对象
   * @param element - 元素名称
   * @param text - 元素文本内容
   */
  private parseWaypointElement(waypoint: Waypoint, element: string, text: string): void {
    switch (element) {
      case 'lat':
        waypoint.lat = parseFloat(text);
        break;
      case 'lon':
        waypoint.lon = parseFloat(text);
        break;
      case 'ele':
        waypoint.ele = parseFloat(text);
        break;
      case 'time':
        waypoint.time = new Date(text);
        break;
      case 'name':
        waypoint.name = text;
        break;
      case 'cmt':
        waypoint.cmt = text;
        break;
      case 'desc':
        waypoint.desc = text;
        break;
      case 'sym':
        waypoint.sym = text;
        break;
      case 'type':
        waypoint.type = text;
        break;
    }
  }

  /**
   * 解析轨迹元素
   * @param track - 轨迹对象
   * @param element - 元素名称
   * @param text - 元素文本内容
   */
  private parseTrackElement(track: Track, element: string, text: string): void {
    switch (element) {
      case 'name':
        track.name = text;
        break;
      case 'cmt':
        track.cmt = text;
        break;
      case 'desc':
        track.desc = text;
        break;
      case 'src':
        track.src = text;
        break;
      case 'type':
        track.type = text;
        break;
    }
  }

  /**
   * 解析路径元素
   * @param route - 路径对象
   * @param element - 元素名称
   * @param text - 元素文本内容
   */
  private parseRouteElement(route: Route, element: string, text: string): void {
    switch (element) {
      case 'name':
        route.name = text;
        break;
      case 'cmt':
        route.cmt = text;
        break;
      case 'desc':
        route.desc = text;
        break;
      case 'src':
        route.src = text;
        break;
      case 'type':
        route.type = text;
        break;
    }
  }

  /**
   * 计算轨迹数据
   * @param track - 轨迹对象
   */
  private calculateTrackData(track: Track): void {
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
      const dist = GPXParser.calculateDistance(
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
        const dist = GPXParser.calculateDistance(
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
   * 计算路径数据
   * @param route - 路径对象
   */
  private calculateRouteData(route: Route): void {
    if (route.points.length < 2) return;

    // 计算距离
    route.distance.total = 0;
    route.distance.cumul = [0];

    for (let i = 1; i < route.points.length; i++) {
      const dist = GPXParser.calculateDistance(
        route.points[i - 1].lat, route.points[i - 1].lon,
        route.points[i].lat, route.points[i].lon
      );
      route.distance.total += dist;
      route.distance.cumul.push(route.distance.total);
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
  revertTrackPoints(track: Track) {
    if (track.segments.length === 0) return;

    for (let n = 0; n < track.segments.length; n++) {
      track.segments[n] = track.segments[n].reverse()
    }
    this.calculateTrackData(track)
  }

  /**
   * 百分比区间裁剪Track上的轨迹点
   * @param track - 轨道对象
   * @param from - 起始百分比
   * @param to - 终止百分比
   */
  trimTrackPoints(track: Track, from: number, to: number) {
    if (track.segments.length === 0) return;

    for (let n = 0; n < track.segments.length; n++) {
      track.segments[n] = track.segments[n].slice(from, to)
    }
    this.calculateTrackData(track)
  }

  /**
   * 转换为GeoJSON格式
   * @returns GeoJSON对象
   */
  // toGeoJSON(): any {
  //   const geoJSON: any = {
  //     type: 'FeatureCollection',
  //     features: []
  //   };
  //
  //   // 添加航点
  //   this.waypoints.forEach(wpt => {
  //     geoJSON.features.push({
  //       type: 'Feature',
  //       geometry: {
  //         type: 'Point',
  //         coordinates: [wpt.lon, wpt.lat]
  //       },
  //       properties: {
  //         name: wpt.name,
  //         ele: wpt.ele,
  //         time: wpt.time,
  //         sym: wpt.sym,
  //         type: wpt.type
  //       }
  //     });
  //   });
  //
  //   // 添加轨迹
  //   this.tracks.forEach(track => {
  //     track.segments.forEach(segment => {
  //       const coordinates = segment.map(pt => [pt.lon, pt.lat]);
  //       geoJSON.features.push({
  //         type: 'Feature',
  //         geometry: {
  //           type: 'LineString',
  //           coordinates: coordinates
  //         },
  //         properties: {
  //           name: track.name,
  //           distance: track.distance.total,
  //           elevation: track.elevation
  //         }
  //       });
  //     });
  //   });
  //
  //   // 添加路径
  //   this.routes.forEach(route => {
  //     const coordinates = route.points.map(pt => [pt.lon, pt.lat]);
  //     geoJSON.features.push({
  //       type: 'Feature',
  //       geometry: {
  //         type: 'LineString',
  //         coordinates: coordinates
  //       },
  //       properties: {
  //         name: route.name,
  //         distance: route.distance.total
  //       }
  //     });
  //   });
  //
  //   return geoJSON;
  // }
}