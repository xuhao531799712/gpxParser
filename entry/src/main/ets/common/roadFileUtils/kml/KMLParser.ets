import { xml, util } from '@kit.ArkTS';
import { Point, Track, Route, Waypoint, Metadata, Parser } from '../RoadTypes';
import { TrackUtils } from '../TrackUtils'

export default class KMLParser implements Parser {
  public xmlSource: string = '';
  public metadata: Metadata | null = null;
  public waypoints: Waypoint[] = [];
  public tracks: Track[] = [];
  public routes: Route[] = [];
  private completeCallback: ((error?: Error) => void) | undefined = undefined;

  constructor() {
    // 初始化
  }

  /**
   * 解析 KML 字符串
   * @param kmlString - KML XML 字符串
   */
  parse(kmlString: string, completeCallback: (error?: Error) => void): void {
    this.xmlSource = kmlString;
    this.completeCallback = completeCallback;
    this.parseXML(kmlString);
  }

  /**
   * 解析 XML 内容
   * @param xmlString - XML 字符串
   */
  private parseXML(xmlString: string): void {
    try {
      let textEncoder: util.TextEncoder = new util.TextEncoder();
      let arrBuffer: Uint8Array = textEncoder.encodeInto(xmlString);
      const parser = new xml.XmlPullParser(arrBuffer.buffer as object as ArrayBuffer, 'UTF-8');

      let currentTrack: Track | null = null;
      let currentRoute: Route | null = null;
      let currentWaypoint: Waypoint | null = null;
      let currentPoint: Point | null = null;
      let currentElement: string = '';
      let currentTrackSegment: Point[] = [];
      let currentRoutePoints: Point[] = [];
      let currentPlacemarkName: string = '';
      let currentPlacemarkDescription: string = '';
      let currentCoordinates: string = '';
      let inPlacemark: boolean = false;
      let inCoordinates: boolean = false;
      let inLineString: boolean = false;
      let inPoint: boolean = false;

      let tokenFunc: (name: xml.EventType, value: xml.ParseInfo) => boolean =
        (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
          if (eventType !== xml.EventType.END_DOCUMENT) {
            switch (eventType) {
              case xml.EventType.START_TAG:
                const tagName = info.getName();
                switch (tagName) {
                  case 'kml':
                    // 处理 KML 根元素
                    break;
                  case 'Document':
                    this.metadata = this.parseDocumentMetadata(parser);
                    break;
                  case 'Placemark':
                    inPlacemark = true;
                    currentPlacemarkName = '';
                    currentPlacemarkDescription = '';
                    break;
                  case 'name':
                    if (inPlacemark) {
                      currentElement = 'name';
                    }
                    break;
                  case 'description':
                    if (inPlacemark) {
                      currentElement = 'description';
                    }
                    break;
                  case 'Point':
                    inPoint = true;
                    currentWaypoint = this.createWaypoint();
                    break;
                  case 'LineString':
                    inLineString = true;
                    currentTrack = this.initTrack();
                    currentTrackSegment = [];
                    break;
                  case 'coordinates':
                    inCoordinates = true;
                    currentCoordinates = '';
                    break;
                  case 'MultiGeometry':
                    // 处理复合几何体
                    break;
                }
                break;

              case xml.EventType.TEXT:
              case xml.EventType.CDSECT:
                const text = info.getText();
                if (inPlacemark) {
                  if (currentElement === 'name') {
                    currentPlacemarkName = text;
                  } else if (currentElement === 'description') {
                    currentPlacemarkDescription = text;
                  }
                }

                if (inCoordinates) {
                  currentCoordinates += text;
                }
                break;

              case xml.EventType.END_TAG:
                const endTagName = info.getName();
                switch (endTagName) {
                  case 'Placemark':
                    inPlacemark = false;
                    break;
                  case 'name':
                  case 'description':
                    currentElement = '';
                    break;
                  case 'Point':
                    inPoint = false;
                    if (currentWaypoint) {
                      if (currentPlacemarkName.length > 0) {
                        currentWaypoint.name = currentPlacemarkName
                        currentWaypoint.desc = currentPlacemarkDescription
                        currentPlacemarkName = ''
                        currentPlacemarkDescription = ''
                      }
                      this.waypoints.push(currentWaypoint);
                      currentWaypoint = null;
                    }
                    break;
                  case 'LineString':
                    inLineString = false;
                    if (currentTrack && currentTrackSegment.length > 0) {
                      currentTrack.segments.push(currentTrackSegment);
                      TrackUtils.calculateTrackData(currentTrack);
                      this.tracks.push(currentTrack);
                    }
                    currentTrack = null;
                    currentTrackSegment = [];
                    break;
                  case 'coordinates':
                    inCoordinates = false;
                    this.processCoordinates(currentCoordinates, currentWaypoint, currentTrackSegment);
                    currentCoordinates = '';
                    break;
                }
                break;
            }
            return true;
          } else {
            if (this.completeCallback) {
              this.completeCallback();
            }
            return false;
          }
        };

      let options: xml.ParseOptions = {
        supportDoctype: true,
        ignoreNameSpace: true,
        tokenValueCallbackFunction: tokenFunc
      };
      parser.parseXml(options);
    } catch (error) {
      console.error('KML解析错误: ' + error.message);
      if (this.completeCallback) {
        this.completeCallback(error);
      }
    }
  }

  /**
   * 解析文档元数据
   * @param parser - XML 解析器
   * @returns 元数据对象
   */
  private parseDocumentMetadata(parser: xml.XmlPullParser): Metadata {
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
   * 处理坐标数据
   * @param coordinates - 坐标字符串
   * @param waypoint - 当前航点（如果是点）
   * @param segment - 当前轨迹段（如果是线）
   */
  private processCoordinates(coordinates: string, waypoint: Waypoint | null, segment: Point[]): void {
    // KML坐标格式：经度,纬度[,高度] [经度,纬度[,高度]]...
    const coordList = coordinates.trim().split(/\s+/);

    for (const coord of coordList) {
      const parts = coord.split(',');
      if (parts.length < 2) continue;

      const lon = parseFloat(parts[0]);
      const lat = parseFloat(parts[1]);
      const ele = parts.length > 2 ? parseFloat(parts[2]) : 0;

      if (waypoint) {
        // 处理点坐标
        waypoint.lon = lon;
        waypoint.lat = lat;
        waypoint.ele = ele;
      } else if (segment) {
        // 处理线坐标
        const point: Point = {
          lat: lat,
          lon: lon,
          ele: ele,
          time: new Date(),
          hr: 0,
          cad: 0
        };
        segment.push(point);
      }
    }
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


}