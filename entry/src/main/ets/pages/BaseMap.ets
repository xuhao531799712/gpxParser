import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { AsyncCallback } from '@kit.BasicServicesKit';
import { display, promptAction } from '@kit.ArkUI';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { PermissionsUtil } from '../common/utils/PermissionsUtil';
import { LocationUtil } from '../common/utils/LocationUtil';
import { authentication } from '@kit.AccountKit';
import { buffer, JSON, util } from '@kit.ArkTS';
import { fileIo, picker } from '@kit.CoreFileKit';
import GPXParser from '../common/gpx/GPXParser';
import { Point, Waypoint } from '../common/gpx/GPXTypes';
import {UISlider} from '@hw-agconnect/ui-slider'
import { gcj02_to_wgs84 } from '../common/utils/CoordinateUtil';
import { ElevationService } from '../common/utils/ElevationService';
import { GPXWriter } from '../common/gpx/GPXWriter';
import uri from '@ohos.uri';
import { ELEChart } from './ELEChart';

PersistentStorage.persistProp('avatarUris', '');

enum MarkType {
  Start, // 起点
  End, // 终点
  WayPoint, // 兴趣点
  Normal // 普通
}

class MarkerWindowData {
  title: string | undefined = undefined
  des: string | undefined = undefined
  latitude: string | undefined = undefined // 纬度
  longitude: string | undefined = undefined // 经度
}

@Entry
@Component
struct Index {
  @State mapController?: map.MapComponentController = undefined
  @StorageLink('avatarUris') avatarUri: string = ''
  @State showSlider: boolean = false
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
  private tapMarkerIndex: number = -1
  private waypointMarkers: map.Marker[] = [];
  private tmpWaypointMarker: map.Marker | undefined = undefined;
  private gpxReaded: boolean = false
  private sliderValue: [number, number] = [0, 100]
  private static wayPointNamePrefix: string = '兴趣点:'
  @State windowData: MarkerWindowData = new MarkerWindowData()
  @State showDelete: boolean = false
  private inMarkMode: boolean = false
  private elevationService = new ElevationService()
  @State inChangeStartPointMode: boolean = false
  @State spec: Record<string, string|ESObject> | undefined = undefined
  @State dis: number = 0 // 单位km
  @State ele: number = 0 // 单位m
  @State totalDis: number = 0
  @State totalEle: number = 0
  // 自定义信息窗Builder
  @LocalBuilder
  customInfoWindowBuilder(delegate: map.MarkerDelegate) {
    if (delegate.marker) {
      Column() {
        // 标题
        Text('编辑兴趣点信息')
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, bottom: 5 })

        // 输入区域
        Column() {
          // 经度
          Row() {
            Text('经度 : ')
              .fontSize(12)
              .textAlign(TextAlign.End)

            TextInput({ text: this.windowData.longitude })
              .width('40%')
              .borderRadius(4)
              .borderWidth(1)
              .borderColor('#ccc')
              .padding(5)
              .onChange((value: string) => {
                this.windowData.longitude = value
              })
          }
          .margin({ bottom: 10 })

          // 纬度
          Row() {
            Text('纬度 : ')
              .fontSize(12)
              .textAlign(TextAlign.End)

            TextInput({ text: this.windowData.latitude })
              .width('40%')
              .borderRadius(4)
              .borderWidth(1)
              .borderColor('#ccc')
              .padding(5)
              .onChange((value: string) => {
                this.windowData.latitude = value
              })
          }
          .margin({ bottom: 10 })
          if (!this.inChangeStartPointMode) {
            // 名称
            Row() {
              Text('名称 : ')
                .fontSize(12)
                .textAlign(TextAlign.End)

              TextInput({ text: (this.windowData.title) })
                .width('40%')
                .borderRadius(4)
                .borderWidth(1)
                .borderColor('#ccc')
                .padding(5)
                .onChange((value: string) => {
                  this.windowData.title = value
                })
            }
            .margin({ bottom: 10 })

            // 描述
            Row() {
              Text('描述 : ')
                .fontSize(12)
                .textAlign(TextAlign.End)

              TextInput({ text: this.windowData.des })
                .width('40%')
                .borderRadius(4)
                .borderWidth(1)
                .borderColor('#ccc')
                .padding(5)
                .onChange((value: string) => {
                  this.windowData.des = value
                })
            }
            .margin({ bottom: 15 })
          }
        }
        .padding({ left: 15, right: 15 })

        // 按钮区域
        Row() {
          if (this.inChangeStartPointMode) {
            Button('设置为起点')
              .width(160)
              .height(30)
              .backgroundColor('#f0f0f0')
              .fontColor('#333')
              .onClick(() => {
                this.onNewStartPointChange();
                delegate.marker?.setInfoWindowVisible(false)
              })
          } else {
          // 取消按钮
            Button('取消')
              .width(60)
              .height(30)
              .backgroundColor('#f0f0f0')
              .fontColor('#333')
              .onClick(() => {
                this.onCancel();
                delegate.marker?.setInfoWindowVisible(false)
              })

          if (this.showDelete) {
            // 间距
            Blank()
              .width(10)

            // 保存按钮
            Button('删除')
              .width(60)
              .height(30)
              .backgroundColor('#1890ff')
              .fontColor(Color.White)
              .onClick(() => {
                delegate.marker?.setInfoWindowVisible(false)
                this.onDelete(delegate.marker!);
              })
          }

          // 间距
          Blank()
            .width(10)

          // 保存按钮
          Button('保存')
            .width(60)
            .height(30)
            .backgroundColor('#1890ff')
            .fontColor(Color.White)
            .onClick(() => {
              this.onSave(delegate.marker!);
              delegate.marker?.setInfoWindowVisible(false)
            })
          }
        }
        .justifyContent(FlexAlign.Center)
        .margin({ bottom: 10 })
      }
      // .width('80%')
      .backgroundColor(Color.White)
      .borderRadius(10)
      .padding(5)
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      Column() {
        Stack({ alignContent: Alignment.Bottom }) {
          // 构造MapComponent
          MapComponent({
            mapOptions: this.mapOption,
            mapCallback: this.callback,
            customInfoWindow: (markerDelegate: map.MarkerDelegate) => {
              this.customInfoWindowBuilder(markerDelegate)
            }
          })
            .width($r('app.string.full_page'))
            .height($r('app.string.map_ratio'))

          if (this.showSlider) {
            Column() {
              Row() {
                Button("取消", {type: ButtonType.Normal})
                .width('15%')
                .onClick( ()=> {
                  this.showSlider = false
                  this.recoverStartEndMarkers()
                })

                UISlider({
                  value: [0, 100],
                  style: SliderStyle.OutSet,
                  showTip: true,
                  onChange: (value) => {
                    if (Array.isArray(value)) {
                      this.moveStartEndMarkers(value)
                    }
                  }
                })
                  .width('65%')

                Button("确认", {type: ButtonType.Normal})
                .width('15%')
                .onClick( ()=> {
                  this.saveSliderChange()
                  this.showSlider = false
                })
              }
              .backgroundColor(Color.White)
              .width('100%')
              .justifyContent(FlexAlign.SpaceBetween)

              Divider()
            }
          }
        }

        ELEChart({spec: this.spec, chartWidth: this.getScreenWidth(), chartHeight: this.getScreenHeight() * 0.15, onReady: ()=> {
            this.parseELEPoints()
          }, onTap: async (index)=> {
            this.updateDisEle(index)
            await this.addTapMarker(index)
          },
          dis: this.dis, ele: this.ele, totalDis: this.totalDis, totalEle: this.totalEle})
      }

      Column() {
        Image(this.avatarUri.length > 0 ? this.avatarUri : $r('app.media.user'))
          .width(64)
          .height(64)
          .borderRadius(32)
          .margin({ top: 16, right: 16 })
          .onClick(async () => {
            await this.getAvatarAndNickName()
          })

        Image($r('app.media.icon_reverse'))
          .width(48)
          .height(48)
          .margin({ top: 8, right: 16 })
          .enabled(!this.showSlider)
          .onClick(() => {
              if (this.showSlider) return
              this.gpxParser.revertTrackPoints(this.gpxParser.tracks[0])
              this.parseLatLngPoints()
              this.parseELEPoints()
            })

        Image($r('app.media.icon_cut'))
          .width(48)
          .height(48)
          .margin({ top: 8, right: 16 })
          .onClick(() => {
            this.showSlider = true
            // todo: 同时禁止其他编辑功能使用
          })

        Image($r('app.media.icon_mark_point'))
          .width(48)
          .height(48)
          .margin({ top: 8, right: 16 })
          .onClick(async () => {
            this.inMarkMode = !this.inMarkMode
            if (!this.inMarkMode) {
              this.clearWayPointMarkers()
            } else {
              await this.addWayPointMarkers()
            }
          })

        Image($r('app.media.icon_startpoint'))
          .width(48)
          .height(48)
          .margin({ top: 8, right: 16 })
          .onClick(() => {
            this.intoStartPointChangeMode()
          })

        Image($r('app.media.icon_save'))
          .width(48)
          .height(48)
          .margin({ top: 8, right: 16 })
          .onClick(async () => {
            await this.saveGPXFile()
          })
      }
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
        // 如果定义了这个，那么就相当于由用户来定义点击效果，就不会自动居中了
        this.mapController.on('markerClick', (marker)=> {
          // 只有途经点Marker会触发
          if (marker.getTitle().startsWith(Index.wayPointNamePrefix)) {
            this.windowData.title = marker.getTitle().substring(Index.wayPointNamePrefix.length)
          } else {
            this.windowData.title = marker.getTitle()
          }
          this.windowData.des = marker.getSnippet()
          this.windowData.latitude = marker.getPosition().latitude.toString()
          this.windowData.longitude = marker.getPosition().longitude.toString()
          this.mapController?.animateCamera(map.newLatLng({
            latitude: marker.getPosition().latitude,
            longitude: marker.getPosition().longitude
          }, 15), 500)
          this.showDelete = true
          marker.setInfoWindowVisible(true) // 打开自定义信息窗
        })
        this.mapController.on('mapLongClick', async (point) => {
          // 判断当前为兴趣点编辑模式
          if (this.inMarkMode) {
            this.windowData.title = ''
            this.windowData.des = ''
            this.windowData.latitude = point.latitude.toString()
            this.windowData.longitude = point.longitude.toString()
            await this.addTempWayPointMarker(point)
            this.showDelete = false
            this.tmpWaypointMarker?.setInfoWindowVisible(true)
          }
        })
        this.mapController.on('mapClick', async (point) => {
          // 判断当前是否有临时兴趣点的infoWindow正在打开
          if (this.tmpWaypointMarker != undefined) {
            this.onCancel()
          }
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
          this.parseELEPoints()
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
    let gcj02Position: mapCommon.LatLng = map.convertCoordinateSync(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, {
      latitude: point.lat,
      longitude: point.lon
    } as mapCommon.LatLng);
    return gcj02Position;
  }

  private async convertToWaypoint(data: MarkerWindowData): Promise<Waypoint> {
    let wgs84Position = gcj02_to_wgs84(Number(data.longitude), Number(data.latitude))
    let point = new Waypoint()
    point.name = data.title
    point.desc = data.des
    point.lat = wgs84Position[1]
    point.lon = wgs84Position[0]
    // todo 获取海拔优化，网络有延迟或者网络未连接
    point.ele = await this.elevationService.getElevation(wgs84Position[1], wgs84Position[0])
    return point
  }

  private async parseLatLngPoints() {
    // 首次进入地图或者编辑路书保存后调用本接口更新地图标点和标线
    this.clearMarkers()
    this.clearPolyLine()

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
      icon: this.createCustomMarkerIcon(MarkType.Start), // 绿色图标
    };
    this.startMarker = await this.mapController?.addMarker(startMarkerOptions);

    // 4. 添加终点标记
    const endMarkerOptions: mapCommon.MarkerOptions = {
      position: points[points.length - 1],
      title: '终点',
      snippet: '行程结束位置',
      icon: this.createCustomMarkerIcon(MarkType.End), // 红色图标
    };
    this.endMarker = await this.mapController?.addMarker(endMarkerOptions);
    if (this.tapMarker == undefined) {
      let tapMarkerOptions: mapCommon.MarkerOptions = {
        position: points[0],
        title: 'Tap',
        icon: this.createCustomMarkerIcon(MarkType.Normal), // 绿色图标
        visible: false
      };
      this.tapMarker = await this.mapController?.addMarker(tapMarkerOptions);
    }
    try {
      this.polyline = await this.mapController?.addPolyline(polylineOption)
      this.zoomToTrackWithPadding()
    } catch (err) {
      console.error("addPolyline failed with error message: " + err.message);
    }
  }

  parseELEPoints() {
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
    let cumuls: Array<number> = this.gpxParser.tracks[0].distance.cumul.map(
      cumul => (cumul / 1000.0)
    );

    this.totalDis = this.gpxParser.tracks[0].distance.total / 1000.0
    this.totalEle = this.gpxParser.tracks[0].elevation.pos

    interface CombinedPoint {
      'distance': number;
      'ele': number;
    }

    let data:CombinedPoint[] = eles.map((ele, index)=>{
      const point: CombinedPoint = {
        distance: cumuls[index],
        ele: ele
      };
      return point
    })
    this.spec = {
      'type': 'area',
      'stack': false,
      'data': {
        'values': (data) as ESObject
      },
      'padding': {
        'left': 10,
        'right': 10,
        'top': 0
      },
      'xField': ['distance'],
      'yField': 'ele',
      'seriesField': 'type',
      'bar': {
        'state': ({
          'aaa': ({
            'fill': 'red'
          } as ESObject)
        } as ESObject),
        'style': ({
          "stroke": "#000",
          "lineWidth": 1
        } as ESObject)
      },
      'legends': {
        "visible": true,
        "position": "start",
        "orient": "top"
      },
      'line': {
        'style': ({
          'curveType': 'monotone'
        } as ESObject)
      },
      'tooltip': {
        'visible': false
      },
      'point': {
        'style': {
          'size': 0,
          'fill': 'white',
          'stroke': null,
          'lineWidth': 2
        } as ESObject,
        'state': {
          'dimension_hover': {
            'size': 10
          } as ESObject,
        } as ESObject
      },
      'axes': [
        {
          'type': 'linear',
          'orient': 'left',
          'visible': true,
          'range': {
            'min': this.gpxParser.tracks[0].elevation.min,
            'max': this.gpxParser.tracks[0].elevation.max
          } as ESObject
        } as ESObject,
        {
          'orient': 'bottom',
          'visible': false
        } as ESObject
      ] as ESObject[],
    }
  }

  async addTapMarker(index: number) {
    if ( this.tapMarkerIndex == index ) return
    this.tapMarkerIndex = index
    let points = this.polyline?.getPoints()
    if (points == undefined) return
    this.tapMarker?.setPosition(points[index])
    this.tapMarker?.setClickable(this.inChangeStartPointMode) // 修改轨迹起点状态支持tapMarker点击
    this.tapMarker?.setVisible(true)
  }

  updateDisEle(index: number) {
    this.ele = this.gpxParser.tracks[0].segments[0][index].ele
    this.dis = this.gpxParser.tracks[0].distance.cumul[index] / 1000.0
  }

  createCustomMarkerIcon(type: MarkType): Resource {
    switch (type) {
      case MarkType.Start:
        return $r("app.media.icon_start");
      case MarkType.End:
        return $r("app.media.icon_end");
      case MarkType.WayPoint:
        return $r("app.media.icon_waypoint");
      case MarkType.Normal:
        return $r('app.media.icon_mark');
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

  moveStartEndMarkers(value: [number, number]) {
    this.sliderValue = value
    let startValue = value[0] / 100.0
    let endValue = value[1] / 100.0
    let points = this.polyline!.getPoints()
    let newStartPoint = points[Math.round(points.length * startValue)]
    let newEndPoint = points[Math.round(points.length * endValue)]
    this.startMarker?.setPosition(newStartPoint)
    this.endMarker?.setPosition(newEndPoint)
  }

  recoverStartEndMarkers() {
    this.sliderValue = [0, 100]
    let points = this.polyline!.getPoints()
    this.startMarker?.setPosition(points[0])
    this.endMarker?.setPosition(points[points.length - 1])
  }

  async addTempWayPointMarker(position: mapCommon.LatLng) {
    let markerOptions: mapCommon.MarkerOptions = {
      position: position,
      title: Index.wayPointNamePrefix,
      snippet: '',
      icon: this.createCustomMarkerIcon(MarkType.WayPoint), // 绿色图标
      clickable: true,
    };
    this.tmpWaypointMarker = await this.mapController!.addMarker(markerOptions);
  }

  async addWayPointMarkers() {
    let points: Array<mapCommon.LatLng> = this.gpxParser.waypoints.map(
      point => this.convertToLatLng(point)
    );
    for (let i = 0; i < points.length; i++) {
      let markerOptions: mapCommon.MarkerOptions = {
        position: points[i],
        title: Index.wayPointNamePrefix + this.gpxParser.waypoints[i].name,
        snippet: this.gpxParser.waypoints[i].desc,
        icon: this.createCustomMarkerIcon(MarkType.WayPoint), // 绿色图标
        clickable: true
      };
      this.waypointMarkers.push(await this.mapController!.addMarker(markerOptions));
    }
  }

  intoStartPointChangeMode() {
    let points = this.gpxParser.tracks[0].segments[0]
    let startToEndDistance = GPXParser.calculateDistance(points[0].lat, points[0].lon, points[points.length - 1].lat, points[points.length - 1].lon)
    if (startToEndDistance < 100) {
      // 首尾节点距离小于100米，认为是环线轨迹
      this.inChangeStartPointMode = true
    } else {
      // 非环线轨迹
      // todo: 添加提示区域
      promptAction.showToast({
        message: '当前轨迹非环线轨迹，不支持修改起点',
        duration: 4000
      })
    }
  }

  async saveGPXFile() {
    // 创建文件管理器选项实例。
    let defaultName = this.getFileNameFromUrl(this.gpxFileUrl)
    const documentSaveOptions = new picker.DocumentSaveOptions();
    documentSaveOptions.newFileNames = [defaultName];
    let context = getContext(this) as common.Context;
    const documentViewPicker = new picker.DocumentViewPicker(context);
    try {
      let uris: string[] = await documentViewPicker.save(documentSaveOptions)
      await GPXWriter.writeGPXFile(this.gpxParser.tracks, this.gpxParser.waypoints, uris[0])
      console.info('documentViewPicker.save to file succeed and uri is:' + uris[0]);
    } catch (err) {
      console.error(`Invoke documentViewPicker.save failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  private getFileNameFromUrl(url: string): string {
  try {
    // 创建 URI 对象
    const uriObj = new uri.URI(url);
    // 获取路径部分
    return uriObj.getLastSegment();
  } catch (error) {
    console.error(`解析URI失败: ${error.message}`);
    return '';
  }
}

  clearWayPointMarkers() {
    this.waypointMarkers.forEach((marker)=> {
      marker.remove()
    })
    this.waypointMarkers = []
  }

  saveSliderChange() {
    let startValue = this.sliderValue[0] / 100.0
    let endValue = this.sliderValue[1] / 100.0
    let length = this.gpxParser.tracks[0].segments[0].length
    let from = Math.round(length * startValue)
    let to = Math.round(length * endValue)
    this.gpxParser.trimTrackPoints(this.gpxParser.tracks[0], from, to)

    this.parseLatLngPoints()
    this.parseELEPoints()
    this.sliderValue = [0, 100]
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
    if (this.tapMarker) {
      this.tapMarker.remove();
      this.tapMarker = undefined;
    }
  }

  // 清除所有标记
  clearPolyLine() {
    if (this.polyline) {
      this.polyline.remove();
      this.polyline = undefined;
    }
  }

  onCancel() {
    if (this.tmpWaypointMarker != undefined) {
      // 添加新兴趣点时取消
      this.tmpWaypointMarker.remove()
      this.tmpWaypointMarker = undefined
    } else {
      // 编辑现有兴趣点时取消,什么都不用做
    }
  }

  async onSave(marker: map.Marker) {
    if (this.tmpWaypointMarker != undefined) {
      // 添加新兴趣点时保存
      this.tmpWaypointMarker.setTitle(Index.wayPointNamePrefix + this.windowData.title)
      this.tmpWaypointMarker.setSnippet(this.windowData.des)
      this.tmpWaypointMarker.setPosition( {longitude: Number(this.windowData.longitude), latitude: Number(this.windowData.latitude)} )
      this.waypointMarkers.push(this.tmpWaypointMarker)
      this.gpxParser.waypoints.push(
        await this.convertToWaypoint(this.windowData)
      )
      this.tmpWaypointMarker = undefined
    } else {
      // 编辑现有兴趣点时保存
      let index = this.waypointMarkers.indexOf(marker)
      marker.setTitle(Index.wayPointNamePrefix + this.windowData.title)
      marker.setSnippet(this.windowData.des)
      marker.setPosition( {longitude: Number(this.windowData.longitude), latitude: Number(this.windowData.latitude)} )
      let waypoint = await this.convertToWaypoint(this.windowData)
      this.gpxParser.waypoints[index].name = waypoint.name
      this.gpxParser.waypoints[index].desc = waypoint.desc
      this.gpxParser.waypoints[index].lat = waypoint.lat
      this.gpxParser.waypoints[index].lon = waypoint.lon
      this.gpxParser.waypoints[index].ele = waypoint.ele
    }
  }

  onDelete(marker: map.Marker) {
    // 一定是对现有的兴趣点进行删除
    let index = this.waypointMarkers.indexOf(marker)
    this.waypointMarkers.splice(index, 1)
    this.gpxParser.waypoints.splice(index, 1)
    marker.remove()
  }

  onNewStartPointChange() {
    let index = this.tapMarkerIndex
    let points = this.gpxParser.tracks[0].segments[0]
    const firstPart = points.slice(index, points.length -1)
    const secondPart = points.slice(0, index - 1)
    let newPoints = [...firstPart, ...secondPart]
    this.gpxParser.tracks[0].segments[0] = newPoints
    this.parseLatLngPoints()
    this.parseELEPoints()
  }

  private getScreenHeight(): number {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      return px2vp(displayInfo.height); // 原始为像素，转为虚拟像素
    } catch (error) {
      console.error('获取屏幕高度失败:', error);
      // 设置默认高度（例如1280px）
      return 1280
    }
  }

  private getScreenWidth(): number {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      return px2vp(displayInfo.width); // 原始为像素，转为虚拟像素
    } catch (error) {
      console.error('获取屏幕高度失败:', error);
      // 设置默认高度（例如1280px）
      return 1280
    }
  }
}
