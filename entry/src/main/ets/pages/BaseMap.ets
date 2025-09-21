import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { PermissionsUtil } from '../common/utils/PermissionsUtil';
import { LocationUtil } from '../common/utils/LocationUtil';
import { authentication } from '@kit.AccountKit';
import { buffer, JSON, util } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import GPXParser from '../common/parser/GPXParser';
import { Point } from '../common/parser/GPXTypes';
import { ELEChart } from './ELEChart';
import { ChartOptions, UChartsController } from '@ibestservices/ucharts';

PersistentStorage.persistProp('avatarUris', '');

@Entry
@Component
struct Index {
  @State mapController?: map.MapComponentController = undefined
  @StorageLink('avatarUris') avatarUri: string = ''
  @State chart: UChartsController = new UChartsController();
  private gpxFileUrl: string = '33'
  private mapOption?: mapCommon.MapOptions
  private callback?: AsyncCallback<map.MapComponentController>
  private locationPermissions: Array<Permissions> = ['ohos.permission.LOCATION', 'ohos.permission.APPROXIMATELY_LOCATION']
  private gpxParser: GPXParser = new GPXParser()
  private enableMyLocation: boolean = false
  private polyline: map.MapPolyline | undefined = undefined;
  private startMarker: map.Marker | undefined = undefined;
  private endMarker: map.Marker | undefined = undefined;
  private tapMarker: map.Marker | undefined = undefined;
  private gpxReaded: boolean = false

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        // 构造MapComponent
        MapComponent({
          mapOptions: this.mapOption,
          mapCallback: this.callback
        })
          .width($r('app.string.full_page'))
          .height($r('app.string.map_ratio'))

        Row() {
          ELEChart({chart: this.chart, onReady: ()=> {
            this.parseElePoints()
          }, onTap: async (index)=> {
            await this.addTapMarker(index)
          }})
        }
        .width($r('app.string.full_page'))
        .height($r('app.string.chart_ratio'))
        .alignItems(VerticalAlign.Center)
      }

      Image(this.avatarUri.length > 0 ? this.avatarUri : $r('app.media.user'))
        .width(64)
        .height(64)
        .borderRadius(32)
        .margin({ top: 16, right: 16 })
        .onClick(async () => {
          await this.getAvatarAndNickName()
        })
    }
    .width($r('app.string.full_page'))
    .height($r('app.string.full_page'))
  }

  async aboutToAppear(): Promise<void> {
    let params = (this.getUIContext().getRouter().getParams() as Record<string, string>)
    this.gpxFileUrl = params['gpxUrl']
    this.enableMyLocation = (params['enableMyLocation'] == 'true')
    this.mapOption = {
      position:{
        target: {
          latitude:39.9,
          longitude:116.4
        },
        zoom: 15
      }
    }

    this.callback = async (err, mapController) => {
      if (!err) {
        this.mapController = mapController
        this.mapController.on('mapLoad', async () => {
          console.info('on mapLoad')
          promptAction.showToast({
            message: '地图加载完成',
            duration: 4000
          })
        })

        const grantStatus = this.checkPermissions()
        if (!grantStatus) {
          await PermissionsUtil.reqPermissionsFromUser(this.locationPermissions)
        }
        if (this.enableMyLocation) {
          this.mapController.setMyLocationEnabled(true) // 在地图上显示我的位置的标注，并实时移动
          this.mapController.setMyLocationControlsEnabled(true)
          this.moveToMyLocation()
        }
      } else {
        promptAction.showToast({
          message: '地图加载错误',
          duration: 4000
        })
      }
      this.readGPX()
    }
  }

  checkPermissions(): boolean {
    for (const permission of this.locationPermissions) {
      const grantStatus = PermissionsUtil.checkAccessToken(permission)
      if (grantStatus == abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        return false
      }
    }
    return true
  }

  async moveToMyLocation() {
    const location = await LocationUtil.currentLocation()
    if (location != undefined) {
      // 由geoLocationManager获取到的是WGS84坐标系，而要在地图上显示需要转化为GCJ02坐标系，否则会有部分偏移
      let gcj02Posion: mapCommon.LatLng = await map.convertCoordinate(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, location);
      this.mapController?.animateCamera(map.newLatLng({
        latitude: gcj02Posion.latitude,
        longitude: gcj02Posion.longitude
      }, 15), 500)
    }
  }

  async getAvatarAndNickName() {
    let authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
    authRequest.scopes = ['profile']
    authRequest.forceAuthorization = true
    authRequest.state = util.generateRandomUUID()
    try {
      let controller = new authentication.AuthenticationController(getContext(this))
      let response: authentication.AuthorizationWithHuaweiIDResponse = await controller.executeRequest(authRequest)
      if (response) {
        this.avatarUri = response.data?.avatarUri as string;
      }
    } catch (error) {
      console.error("getAvatarAndNickName failed, error: " + JSON.stringify(error))
    }
  }

  async readGPX() {
    try {
      let file = fileIo.openSync(this.gpxFileUrl, fileIo.OpenMode.READ_ONLY);
      let stat = fileIo.statSync(file.fd);
      const arrayBuffer = new ArrayBuffer(stat.size);
      let result = await fileIo.read(file.fd, arrayBuffer);
      let buf = buffer.from(arrayBuffer, 0, result).toString();
      this.gpxParser.parse(buf, async (err) => {
        if (err == undefined) {
          // 解析成功，可从parser中取对应的坐标数据
          this.gpxReaded = true
          await this.parseLatLngPoints()
          this.parseElePoints()
        } else {
          console.error("readGPX failed with error message: " + err.message);
        }
      })
    } catch (err) {
      console.error("read failed with error message: " + err.message + ", error code: " + err.code);
    }
  }

  // 定义一个转换函数
  private convertToLatLng(point: Point): mapCommon.LatLng {
    let gcj02Posion: mapCommon.LatLng = map.convertCoordinateSync(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, {
      latitude: point.lat,
      longitude: point.lon
    } as mapCommon.LatLng);
    return gcj02Posion;
  }

  private async parseLatLngPoints() {
    const allPoints: Point[] = [];
    this.gpxParser.tracks[0].segments.forEach(segment => {
      allPoints.push(...segment);
    });
    let points: Array<mapCommon.LatLng> = allPoints.map(
      point => this.convertToLatLng(point)
    );

    let polylineOption: mapCommon.MapPolylineOptions = {
      // 折线坐标点，必传
      points: points,
      clickable: false,
      color: 0xff000080, // 海军蓝
      startCap: mapCommon.CapStyle.ROUND,
      endCap: mapCommon.CapStyle.ROUND,
      geodesic: false,
      jointType: mapCommon.JointType.DEFAULT,
      visible: true,
      width: 15,
      zIndex: 0,
      gradient: false
    };
    // 3. 添加起点标记
    let startMarkerOptions: mapCommon.MarkerOptions = {
      position: points[0],
      title: '起点',
      snippet: '行程开始位置',
      icon: this.createCustomMarkerIcon(true), // 绿色图标
    };
    this.startMarker = await this.mapController?.addMarker(startMarkerOptions);

    // 4. 添加终点标记
    const endMarkerOptions: mapCommon.MarkerOptions = {
      position: points[points.length - 1],
      title: '终点',
      snippet: '行程结束位置',
      icon: this.createCustomMarkerIcon(false), // 红色图标
    };
    this.endMarker = await this.mapController?.addMarker(endMarkerOptions);
    try {
      this.polyline = await this.mapController?.addPolyline(polylineOption)
      this.zoomToTrackWithPadding()
    } catch (err) {
      console.error("addPolyline failed with error message: " + err.message);
    }
  }

  parseElePoints() {
    if (this.gpxReaded != true) return
    // 海拔数据
    const allPoints: Point[] = [];
    this.gpxParser.tracks[0].segments.forEach(segment => {
      allPoints.push(...segment);
    });
    let eles: Array<number> = allPoints.map(
      point => point.ele
    );
    // 单位米，需要/1000换算为km
    let cumuls: Array<string> = this.gpxParser.tracks[0].distance.cumul.map(
      cumul => (cumul / 1000.0).toFixed(2)
    );
    let opts: Partial<ChartOptions> = {
      type: "area",
      categories: cumuls,
      series: [
        {
          name: "海拔", // 必须配置
          data: eles,
          legendShape: 'none'
        }
      ],
      // enableScroll: true,
      padding: [5,5,0,5],
      xAxis: {
        disabled: true,
        // labelCount: 5, // 限制展示的X标数量，当放缩时可以显示被隐藏的
      },
      yAxis: {
        gridType: 'dash',
        dashLength: 2
      },
      dataLabel: false,
      extra: {
        area: {
          activeType: 'hollow',
          type: 'curve',
          opacity: 1
        },
        markLine: {
          type: 'dash'
        },
        tooltip: {
          xAxisLabel: true,
          yAxisLabel: true
        }
      }
    }
    this.chart.updateData(opts)
  }

  async addTapMarker(index: number) {
    let points = this.polyline?.getPoints()
    if (points == undefined) return
    if (this.tapMarker == undefined) {
      let tapMarkerOptions: mapCommon.MarkerOptions = {
        position: points[index],
        title: '起点',
        snippet: '行程开始位置',
        icon: this.createCustomMarkerIcon(undefined), // 绿色图标
      };
      this.tapMarker = await this.mapController?.addMarker(tapMarkerOptions);
    } else {
      this.tapMarker.setPosition(points[index])
    }
  }

  createCustomMarkerIcon(start: boolean | undefined): Resource {
    if (start == undefined) {
      return $r('app.media.icon_mark');
    } else if (start == true) {
      return $r('app.media.icon_start');
    } else {
      return $r('app.media.icon_end');
    }
  }

  // 调整地图视野，包含折线和标记
  zoomToTrackWithPadding() {
    if (!this.mapController || this.gpxParser.tracks[0].segments[0].length === 0) return;

    // 计算包含所有点的边界
    let bounds: mapCommon.LatLngBounds = {
      northeast: {
        latitude: Math.max(...this.gpxParser.tracks[0].segments[0].map(p => p.lat)),
        longitude: Math.max(...this.gpxParser.tracks[0].segments[0].map(p => p.lon))
      },
      southwest: {
        latitude: Math.min(...this.gpxParser.tracks[0].segments[0].map(p => p.lat)),
        longitude: Math.min(...this.gpxParser.tracks[0].segments[0].map(p => p.lon))
      }
    };

    // 添加额外边距以确保标记完全可见
    this.mapController.moveCamera(map.newLatLngBounds(bounds, 100))
  }

  // 清除所有标记
  clearMarkers() {
    if (this.startMarker) {
      this.startMarker.remove();
      this.startMarker = undefined;
    }
    if (this.endMarker) {
      this.endMarker.remove();
      this.endMarker = undefined;
    }
  }
}