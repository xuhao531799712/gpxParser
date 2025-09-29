import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { CommonUtils } from '../common/utils/CommonUtils';

interface Param {
  fileUri: string,
  enableMyLocation: string,
  enableEdit: string
}

@Entry
@Component
struct HomePage {
  @State selectedFileUri: string = "";
  @State selectedFilePath: string = "未选择文件"
  @State fileSize: string = "";
  @State fileType: string = "";

  build() {
    Column({ space: 0 }) {
      // 主内容区域
      Scroll() {
        Column({ space: 24 }) {
          // 文件选择卡片
          this.FileSelectionCard()

          // 功能网格区域
          this.FunctionGrid()
        }
        .padding(20)
        .width('100%')
      }
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F7FA')
  }

  // 文件选择卡片组件
  @Builder FileSelectionCard() {
    Column({ space: 16 }) {
      // 标题区域
      Row() {
        Text('文件选择')
          .fontSize(20)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Bold)

        Blank()

        if (this.selectedFileUri.length > 0) {
          Image($r('app.media.icon_success'))
            .width(20)
            .height(20)
            .fillColor('#999999')
        } else {
          Image($r('app.media.icon_warning'))
            .width(20)
            .height(20)
            .fillColor('#999999')
        }
      }
      .width('100%')

      // 文件信息卡片
      Column({ space: 12 }) {
        Row() {
          Text('文件路径:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)
          Text(this.selectedFilePath)
            .fontSize(14)
            .fontColor(this.selectedFilePath === '未选择文件' ? '#999999' : '#1A1A1A')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
            .layoutWeight(1)
        }
        .width('100%')

        Row() {
          Text('大小:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)
          Text(this.fileSize || '--')
            .fontSize(14)
            .fontColor(this.fileSize ? '#1A1A1A' : '#999999')
        }
        .width('100%')

        Row() {
          Text('类型:')
            .fontSize(14)
            .fontColor('#666666')
            .width(80)
          Text(this.fileType || '--')
            .fontSize(14)
            .fontColor(this.fileType ? '#1A1A1A' : '#999999')
        }
        .width('100%')
      }
      .padding(16)
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .shadow({ radius: 8, color: '#1A1A1A10', offsetX: 0, offsetY: 2 })

      // 选择文件按钮
      Button('选择文件', { type: ButtonType.Normal })
        .width('100%')
        .height(44)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .backgroundColor('#007AFF')
        .borderRadius(8)
        .onClick(() => {
          this.selectFile();
        })
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 12, color: '#1A1A1A10', offsetX: 0, offsetY: 4 })
  }

  // 功能网格组件
  @Builder FunctionGrid() {
    Grid() {
      GridItem() {
        this.FunctionCard(
          '#FF6B9D',
          $r("app.media.icon_change"),
          '格式转换',
          '各类型互相转换\n支持gpx/kml/tcx\ngeojson',
          'FileConversion'
        )
      }

      GridItem() {
        this.FunctionCard(
          '#4CD964',
          $r("app.media.icon_route"),
          '轨迹预览',
          '在地图中展示轨迹\n距离海拔等',
          'BaseMap',
          {
            enableMyLocation: 'false',
            enableEdit: 'false'
          } as Param
        )
      }

      GridItem() {
        this.FunctionCard(
          '#AF52DE',
          $r("app.media.icon_text"),
          '文本预览',
          '文件裸数据预览',
          'FileContentViewer'
        )
      }

      GridItem() {
        this.FunctionCard(
          '#FF9500',
          $r('app.media.icon_edit'),
          '二次编辑',
          '在地图中编辑\n方向逆转/兴趣点编辑\n轨迹裁剪\n特色功能：环形轨迹调整起点',
          'BaseMap',
          {
            enableMyLocation: 'false',
            enableEdit: 'true'
          } as Param
        )
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .columnsGap(12)
    .rowsGap(12)
    .height('60%')
  }

  // 功能卡片组件
  @Builder FunctionCard(color: string, icon: Resource, title: string, desc: string, route: string, params: Param = {} as Param) {
    Column({ space: 12 }) {
      // 图标区域
      Row() {
        Image(icon)
          .width(40)
          .height(40)
          .fillColor('#FFFFFF')
      }
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width(48)
      .height(48)
      .backgroundColor(color)
      .borderRadius(24)
      .margin({ top: 10 })

      // 文字内容
      Column({ space: 4 }) {
        Text(title)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)
          .textAlign(TextAlign.Center)
          .margin({ top: 10 })

        Text(desc)
          .fontSize(12)
          .fontColor('#666666')
          .textAlign(TextAlign.Center)
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .padding(16)
    .width('100%')
    .height(190)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .justifyContent(FlexAlign.Start)
    .shadow({ radius: 6, color: '#1A1A1A08', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      this.navigateToFunction(route, params);
    })
  }

  // 选择文件方法
  // 选择文件方法
  async selectFile() {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.fileSuffixFilters = ['.gpx', 'kml', 'tcx','geojson']
      documentSelectOptions.maxSelectNumber = 1
      let context = getContext(this) as common.Context;
      const documentPicker = new picker.DocumentViewPicker(context);
      const result = await documentPicker.select(documentSelectOptions)

      if (result && result.length > 0) {
        const uri = result[0];
        this.selectedFileUri = uri;
        this.selectedFilePath = CommonUtils.getFilePathFromUri(this.selectedFileUri)

        // 获取文件信息
        const file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
        const stat = fs.statSync(file.fd);
        fs.closeSync(file);

        // 格式化文件大小
        this.fileSize = this.formatFileSize(stat.size);

        // 获取文件类型
        this.fileType = CommonUtils.getFileType(uri);
      } else {
        console.error('DocumentViewPicker.select failed with err: no file');
        this.showErrorAlertDialog('select no file')
      }
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`DocumentViewPicker failed with err: ${err.code}, ${err.message}`);
      this.showErrorAlertDialog(err.message)
    }
  }

  // 格式化文件大小
  private formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
  }

  private showErrorAlertDialog(message: string) {
    this.getUIContext().showAlertDialog(
      {
        title: '文件路径',
        message: '文件导入发生错误：' + message,
        autoCancel: true,
        alignment: DialogAlignment.Center,
        offset: { dx: 0, dy: -20 },
        gridCount: 3,
        width: 300,
        height: 300,
        cornerRadius: $r('sys.float.corner_radius_level7'),
        borderWidth: 1,
        borderStyle: BorderStyle.Dashed,
        borderColor: Color.Blue,
        backgroundColor: Color.White,
        textStyle: { wordBreak: WordBreak.BREAK_ALL },
        confirm: {
          value: '确定',
          action: () => {
            console.log('Confirm button is clicked.');
          },
        },
        onWillDismiss: (dismissDialogAction: DismissDialogAction) => {
          if (dismissDialogAction.reason === DismissReason.PRESS_BACK) {
            dismissDialogAction.dismiss();
          }
          if (dismissDialogAction.reason === DismissReason.TOUCH_OUTSIDE) {
            dismissDialogAction.dismiss();
          }
        }
      }
    )
  }

  // 导航到功能页面
  private navigateToFunction(route: string, params: Param) {
    if (this.fileSize.length > 0) {
      params.fileUri = this.selectedFileUri
      router.pushUrl({
        url: `pages/${route}`,
        params: params
      }, router.RouterMode.Standard);
    } else {
      this.showToast('请先选择文件')
    }
  }

  private showToast(message: string) {
    promptAction.showToast({
      message: message,
      duration: 3000,
      alignment: Alignment.Center
    });
  }
}