import { picker } from '@kit.CoreFileKit';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import { common } from '@kit.AbilityKit';
import { router } from '@kit.ArkUI';
import { uri } from '@kit.ArkTS';
import { CommonUtils } from '../common/utils/CommonUtils';

@Entry
@Component
struct FileSelectionPage {
  @State selectedFileUri: string = "";
  @State selectedFilePath: string = "未选择文件"
  @State fileSize: string = "";
  @State fileType: string = "";

  // 构建文件选择区域
  @Builder
  fileSelectionArea() {
    Column() {
      // 标题
      Text("文件选择")
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 文件信息展示框
      Column() {
        Text("文件路径:")
          .fontSize(16)
          .margin({ bottom: 5 })

        Text(this.selectedFilePath)
          .fontSize(14)
          .fontColor(Color.Gray)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 10 })

        Row() {
          Text("大小:")
            .fontSize(16)
            .margin({ right: 10 })
          Text(this.fileSize)
            .fontSize(14)
            .fontColor(Color.Gray)
        }
        .margin({ bottom: 5 })

        Row() {
          Text("类型:")
            .fontSize(16)
            .margin({ right: 10 })
          Text(this.fileType)
            .fontSize(14)
            .fontColor(Color.Gray)
        }
      }
      .padding(15)
      .borderRadius(10)
      .border({ width: 1, color: "#E0E0E0" })
      .margin({ bottom: 20 })
      .width('90%')

      // 选择文件按钮
      Button("选择文件")
        .width(200)
        .height(50)
        .fontSize(18)
        .backgroundColor('#E0F5FF')
        .onClick(() => {
          this.selectFile();
        })
    }
    .width('100%')
    .height('40%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .padding(10)
  }

  // 构建功能按钮区域
  @Builder
  functionButtonsArea() {
    Grid() {
      // 第一行
      GridItem() {
        // 按钮1
        this.functionButton("格式转换", "各类型\n互相转换", "#FFE0E0", () => {
          router.pushUrl({
            url: 'pages/FileConversion',
            params: {
              fileUri: this.selectedFileUri
            }
          }, router.RouterMode.Standard)
        })
      }
      GridItem() {
        // 按钮2
        this.functionButton("轨迹预览", "在地图中展示轨迹\n距离海拔等", "#E0FFE0", () => {
          router.pushUrl({
            url: 'pages/BaseMap',
            params: {
              fileUri: this.selectedFileUri,
              enableMyLocation: 'false',
              enableEdit: 'false'
            }
          }, router.RouterMode.Standard)
        })
      }

      // 第二行
      GridItem() {
        // 按钮3
        this.functionButton("文本预览", "文件裸数据预览", "#E0E0FF", () => {
          router.pushUrl({
            url: 'pages/FileContentViewer',
            params: {
              fileUri: this.selectedFileUri
            }
          }, router.RouterMode.Standard)
        })
      }
      GridItem() {
        // 按钮4
        this.functionButton("二次编辑", "在地图中编辑\n支持方向逆转、兴趣点编辑、轨迹裁剪\n特色功能：环形轨迹调整起点", "#FFFFE0", () => {
          router.pushUrl({
            url: 'pages/BaseMap',
            params: {
              fileUri: this.selectedFileUri,
              enableMyLocation: 'false',
              enableEdit: 'true'
            }
          }, router.RouterMode.Standard)
        })
      }
    }
    .columnsTemplate('1fr 1fr')
    .rowsTemplate('1fr 1fr')
    .width('100%')
    .height('60%')
    .padding(15)
    .backgroundColor('#F5F5F5')
  }

  // 构建单个功能按钮
  @Builder
  functionButton(title: string, description: string, bgColor: string, onClick: () => void) {
    Column() {
      Button(title)
        .width(150)
        .height(50)
        .fontSize(18)
        .backgroundColor(bgColor)
        .onClick( () => {
          if (this.fileSize.length > 0) {
            onClick()
          } else {
            this.showToast('请先选择文件')
          }
        })

      Text(description)
        .fontSize(14)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Center)
        .margin({ top: 10 })
        .width('90%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding(10)
  }

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
  formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
  }

  // 显示提示信息
  showToast(message: string) {
    promptAction.showToast({
      message: message,
      duration: 3000,
      alignment: Alignment.Center
    });
  }

  build() {
    Column() {
      // 文件选择区域
      this.fileSelectionArea()

      // 功能按钮区域
      this.functionButtonsArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F0F0F0')
  }

  showErrorAlertDialog(message: string) {
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
}