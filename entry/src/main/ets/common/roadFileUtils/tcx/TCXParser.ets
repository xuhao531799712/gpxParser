import { xml, util } from '@kit.ArkTS';
import { Point, Track, Route, Waypoint, Metadata, Parser } from '../RoadTypes';
import { TrackUtils } from '../TrackUtils';

export default class TCXParser implements Parser{
  public xmlSource: string = '';
  public metadata: Metadata | null = null;
  public tracks: Track[] = [];
  waypoints: Waypoint[] = [];
  routes: Route[] = [];
  private completeCallback: ((error?: Error) => void) | undefined = undefined;

  constructor() {
    // 初始化
  }

  /**
   * 解析 TCX 字符串
   * @param tcxString - TCX XML 字符串
   * @param completeCallback - 解析完成回调
   */
  parse(tcxString: string, completeCallback: (error?: Error) => void): void {
    this.xmlSource = tcxString;
    this.completeCallback = completeCallback;
    this.parseXML(tcxString);
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
      let currentSegment: Point[] = [];
      let currentPoint: Point | null = null;
      let currentElement: string = '';
      let currentHeartRate: number | null = null;
      let currentCadence: number | null = null;
      let currentAltitude: number | null = null;

      let tokenFunc: (name: xml.EventType, value: xml.ParseInfo) => boolean =
        (eventType: xml.EventType, info: xml.ParseInfo): boolean => {
          if (eventType !== xml.EventType.END_DOCUMENT) {
            switch (eventType) {
              case xml.EventType.START_TAG:
                const tagName = info.getName();
                switch (tagName) {
                  case 'TrainingCenterDatabase':
                    // 根元素
                    break;
                  case 'Activities':
                    // 活动容器
                    break;
                  case 'Activity':
                    break;
                  case 'Id':
                    currentElement = 'id';
                    break;
                  case 'Lap':
                    if (currentTrack) {
                      currentTrack.segments.push([]);
                    }
                    break;
                  case 'TotalTimeSeconds':
                    currentElement = 'TotalTimeSeconds';
                    break;
                  case 'DistanceMeters':
                    currentElement = 'DistanceMeters';
                    break;
                  case 'Calories':
                    currentElement = 'Calories';
                    break;
                  case 'Track':
                    // 轨迹段开始
                    currentTrack = this.initTrack();
                    currentSegment = [];
                    break;
                  case 'Trackpoint':
                    currentPoint = this.createPoint();
                    currentHeartRate = null;
                    currentCadence = null;
                    currentAltitude = null;
                    break;
                  case 'Time':
                    currentElement = 'Time';
                    break;
                  case 'Position':
                    // 位置信息开始
                    break;
                  case 'LatitudeDegrees':
                    currentElement = 'LatitudeDegrees';
                    break;
                  case 'LongitudeDegrees':
                    currentElement = 'LongitudeDegrees';
                    break;
                  case 'AltitudeMeters':
                    currentElement = 'AltitudeMeters';
                    break;
                  case 'DistanceMeters':
                    currentElement = 'DistanceMeters';
                    break;
                  case 'HeartRateBpm':
                    currentElement = 'HeartRateBpm';
                    break;
                  case 'Value':
                    if (currentElement === 'HeartRateBpm') {
                      currentElement = 'HeartRateValue';
                    }
                    break;
                  case 'Cadence':
                    currentElement = 'Cadence';
                    break;
                  case 'Extensions':
                    // 扩展数据开始
                    break;
                  case 'TPX':
                    // Garmin 扩展命名空间
                    break;
                  case 'Speed':
                    currentElement = 'Speed';
                    break;
                  case 'Watts':
                    currentElement = 'Watts';
                    break;
                }
                break;

              case xml.EventType.TEXT:
              case xml.EventType.CDSECT:
                const text = info.getText();
                if (currentElement && text) {
                  switch (currentElement) {
                    case 'id':
                      break;
                    case 'TotalTimeSeconds':
                      break;
                    case 'DistanceMeters':
                      break;
                    case 'Calories':
                      break;
                    case 'Time':
                      if (currentPoint) {
                        currentPoint.time = new Date(text);
                      }
                      break;
                    case 'LatitudeDegrees':
                      if (currentPoint) {
                        currentPoint.lat = parseFloat(text);
                      }
                      break;
                    case 'LongitudeDegrees':
                      if (currentPoint) {
                        currentPoint.lon = parseFloat(text);
                      }
                      break;
                    case 'AltitudeMeters':
                      if (currentPoint) {
                        currentAltitude = parseFloat(text);
                      }
                      break;
                    case 'HeartRateValue':
                      if (currentPoint) {
                        currentHeartRate = parseInt(text);
                      }
                      break;
                    case 'Cadence':
                      if (currentPoint) {
                        currentCadence = parseInt(text);
                      }
                      break;
                    case 'Speed':
                      break;
                    case 'Watts':
                      break;
                  }
                }
                break;

              case xml.EventType.END_TAG:
                const endTagName = info.getName();
                switch (endTagName) {
                  case 'Activity':
                    break;
                  case 'Lap':
                    break;
                  case 'Track':
                    if (currentTrack && currentSegment.length > 0) {
                      currentTrack.segments.push(currentSegment);
                      currentSegment = [];
                      TrackUtils.calculateTrackData(currentTrack);
                      this.tracks.push(currentTrack);
                    }
                    break;
                  case 'Trackpoint':
                    if (currentPoint) {
                      // 设置高程
                      if (currentAltitude !== null) {
                        currentPoint.ele = currentAltitude;
                      }

                      // 设置心率
                      if (currentHeartRate !== null) {
                        currentPoint.hr = currentHeartRate;
                      }

                      // 设置踏频
                      if (currentCadence !== null) {
                        currentPoint.cad = currentCadence;
                      }

                      currentSegment.push(currentPoint);
                      currentPoint = null;
                    }
                    break;
                  case 'Position':
                  case 'HeartRateBpm':
                  case 'Extensions':
                  case 'TPX':
                    // 重置当前元素
                    currentElement = '';
                    break;
                  case 'LatitudeDegrees':
                  case 'LongitudeDegrees':
                  case 'AltitudeMeters':
                  case 'DistanceMeters':
                  case 'Time':
                  case 'Value':
                  case 'Cadence':
                  case 'Speed':
                  case 'Watts':
                  case 'TotalTimeSeconds':
                  case 'Calories':
                  case 'Id':
                    currentElement = '';
                    break;
                }
                break;
            }
            return true;
          } else {
            // 文档结束，计算轨迹数据
            this.tracks.forEach(track => TrackUtils.calculateTrackData(track));

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
      console.error('TCX解析错误: ' + error.message);
      if (this.completeCallback) {
        this.completeCallback(error);
      }
    }
  }

  /**
   * 创建点
   * @returns 点对象
   */
  private createPoint(): Point {
    return {
      lat: 0,
      lon: 0,
      ele: 0,
      time: new Date(),
      hr: 0,
      cad: 0,
    };
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
}