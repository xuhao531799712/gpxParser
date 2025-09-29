import picker from '@ohos.file.picker';
import router from '@ohos.router';
import { BusinessError } from '@ohos.base';
import promptAction from '@ohos.promptAction';
import { Converter } from '../common/utils/Converter'; // 加不加{}有什么区别 todo
import { common } from '@kit.AbilityKit';
import { CommonUtils } from '../common/utils/CommonUtils';
import fileIo from '@ohos.file.fs';
import { buffer } from '@kit.ArkTS';
import { fileManagerService } from '@kit.FileManagerServiceKit';

// 文件转换选项
interface ConversionOption {
  extension: string;
  name: string;
}

// 转换任务
async function convertFile(sourcePath: string, targetPath: string, targetFormat: string): Promise<boolean> {
  let success = false;

  try {
    // 同步读取源文件
    const sourceFile = fileIo.openSync(sourcePath, fileIo.OpenMode.READ_ONLY);
    let stat = fileIo.statSync(sourceFile.fd);
    const arrayBuffer = new ArrayBuffer(stat.size);
    let result = fileIo.readSync(sourceFile.fd, arrayBuffer);
    let content = buffer.from(arrayBuffer, 0, result).toString();
    fileIo.closeSync(sourceFile);

    // 转换逻辑（同步）
    let sourceFormat = CommonUtils.getFileSuffix(sourcePath)
    const error = await Converter.convertContent(content, sourceFormat, targetFormat, targetPath);
    if (error != null) {
      console.error(`转换失败: ${error}`);
      success = false;
    } else {
      success = true;
    }
  } catch (error) {
    console.error(`转换失败: ${error}`);
    success = false;
  }

  return success;
}

@Entry
@Component
struct FileConversionPage {
  // 从路由参数获取文件URI
  private fileUri: string = (router.getParams() as Record<string, string>)?.['fileUri'] || '';

  // 文件信息
  @State fileName: string = "未命名文件";
  @State fileType: string = "";
  @State fileSize: string = "0 KB";

  // 转换选项
  @State conversionOptions: ConversionOption[] = Object.entries(CommonUtils.fileTypes).map(
    (fileType) => ({extension: fileType[0], name: fileType[1]} as ConversionOption)
  );

  @State selectedFormat: string = 'gpx';
  @State isConverting: boolean = false;
  @State conversionProgress: number = 0;
  @State conversionCompleted: boolean = false;
  @State outputPath: string = "";

  aboutToAppear() {
    if (!this.fileUri) {
      promptAction.showToast({ message: "未提供文件路径", duration: 3000 });
      return;
    }

    this.loadFileInfo();
  }

  // 加载文件信息
  loadFileInfo() {
    try {
      // 获取文件名
      this.fileName = CommonUtils.getFileNameFromUri(this.fileUri)

      let file = fileIo.openSync(this.fileUri, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      this.fileSize = this.formatFileSize(stat.size);

      // 获取文件类型
      this.fileType = CommonUtils.getFileType(this.fileName);
      fileIo.closeSync(file.fd)
    } catch (error) {
      console.error(`文件信息获取失败: ${(error as BusinessError).message}`);
      promptAction.showToast({ message: "无法获取文件信息", duration: 3000 });
    }
  }

  // 格式化文件大小
  formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
  }

  // 开始转换
  async startConversion() {
    if (!this.fileUri) {
      promptAction.showToast({ message: "未选择文件", duration: 2000 });
      return;
    }

    try {
      // 选择保存位置
      const documentSaveOptions = new picker.DocumentSaveOptions();
      let context = getContext(this) as common.Context;
      const savePicker = new picker.DocumentViewPicker(context);

      // 生成新文件名
      const originalName = this.fileName.split('.')[0];
      const selectedOption = this.conversionOptions.find(opt => opt.extension === this.selectedFormat);
      const newFileName = `${originalName}_converted.${selectedOption?.extension || '.gpx'}`;

      documentSaveOptions.newFileNames = [newFileName];
      const saveUri = await savePicker.save(documentSaveOptions);

      if (!saveUri) {
        promptAction.showToast({ message: "未选择保存位置", duration: 2000 });
        return;
      }

      this.outputPath = saveUri[0];
      this.isConverting = true;
      this.conversionProgress = 0;
      this.conversionCompleted = false;

      // 在后台执行转换任务
      let success = await convertFile(this.fileUri, this.outputPath, this.selectedFormat);

      this.conversionProgress = 100;

      if (success) {
        this.conversionCompleted = true;
        promptAction.showToast({ message: "转换完成", duration: 2000 });
      } else {
        fileIo.unlink(this.outputPath)
        promptAction.showToast({ message: "转换失败", duration: 2000 });
      }

      this.isConverting = false;
    } catch (error) {
      console.error(`转换失败: ${(error as BusinessError).message}`);
      promptAction.showToast({ message: "转换过程中出错", duration: 2000 });
      this.isConverting = false;
      fileIo.unlink(this.outputPath)
    }
  }

  // 构建文件信息区域
  @Builder
  buildFileInfo() {
    Column() {
      Text("文件信息")
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      // 文件信息卡片
      Column() {
        Row() {
          Text("文件名:")
            .fontSize(18)
            .fontColor('#666666')
            .width(80)
          Text(this.fileName)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.MARQUEE })
        }
        .margin({ bottom: 13 })

        Row() {
          Text("类型:")
            .fontSize(18)
            .fontColor('#666666')
            .width(80)
          Text(this.fileType)
            .fontSize(18)
            .margin({right: 65})
        }
        .margin({ bottom: 13 })

        Row() {
          Text("大小:")
            .fontSize(18)
            .fontColor('#666666')
            .width(80)
          Text(this.fileSize)
            .fontSize(18)
        }
      }
      .padding(20)
      .borderRadius(10)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E0E0E0' })
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .padding(20)
    .width('100%')
  }

  // 构建格式选择区域
  @Builder
  buildFormatSelection() {
    Column() {
      Text("转换格式")
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 15 })

      // 格式选择卡片
      Column() {
        ForEach(this.conversionOptions, (option: ConversionOption) => {
          if (option.name != this.fileType) {
            Row() {
              Radio({ value: option.extension, group: 'formatGroup' })
                .checked(this.selectedFormat === option.extension)
                .onChange((checked: boolean) => {
                  if (checked) this.selectedFormat = option.extension;
                })
                .margin({ right: 15 })

              Text(option.name)
                .fontSize(18)
                .margin({right: 25})
            }
            .margin({ bottom: 13 })
            .width('100%')
            .justifyContent(FlexAlign.Start)
          }
        })
      }
      .padding(20)
      .borderRadius(10)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E0E0E0' })
      .width('100%')
    }
    .padding(20)
    .width('100%')
  }

  // 构建操作区域
  @Builder
  buildActionArea() {
    Column() {
      Button(this.isConverting ? "转换中..." : "开始转换")
        .width('80%')
        .height(50)
        .fontSize(20)
        .backgroundColor(this.isConverting ? '#CCCCCC' : '#007DFF')
        .fontColor(Color.White)
        .enabled(!this.isConverting)
        .onClick(() => {
          if (!this.isConverting) this.startConversion();
        })
        .margin({ bottom: 15 })

      // 转换进度
      if (this.isConverting) {
        Progress({ value: this.conversionProgress, style: ProgressStyle.Linear })
          .width('80%')
          .height(10)
          .margin({ bottom: 8 })

        Text(`${this.conversionProgress}%`)
          .fontSize(16)
          .fontColor('#666666')
      }

      // 转换完成状态
      if (this.conversionCompleted) {
        Column() {
          Image($r('app.media.icon_success'))
            .width(60)
            .height(60)
            .margin({ bottom: 13 })

          Text("转换完成!")
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
            .margin({ bottom: 8 })

          Text(`文件已保存至: ${this.outputPath}`)
            .fontSize(16)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ bottom: 15 })

          Button("打开文件")
            .width(150)
            .height(40)
            .onClick(() => {
              // 实际应用中应调用系统打开文件的方法
              promptAction.showToast({ message: "打开文件功能", duration: 2000 });
            })
        }
        .padding(20)
        .borderRadius(10)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E0E0E0' })
        .width('80%')
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(20)
  }

  build() {
    Column() {
      // 文件信息区域
      this.buildFileInfo()

      // 格式选择区域
      this.buildFormatSelection()

      // 操作区域
      this.buildActionArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    // .scrollBar(BarState.Off)
  }
}