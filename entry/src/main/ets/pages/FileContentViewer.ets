import fs from '@ohos.file.fs';
import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { util } from '@kit.ArkTS';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { CommonUtils } from '../common/utils/CommonUtils';

@Entry
@Component
struct FileContentViewer {
  // 从路由参数获取文件URI
  @State fileUri: string = '';
  @State fileContent: string = "正在加载文件内容...";
  @State fileName: string = "未命名文件";
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State fontSize: number = 16;
  @State encoding: string = 'UTF-8';
  @State currentPage: number = 0;
  @State totalPages: number = 0;
  @State fileChunks: string[] = [];

  // 支持的编码列表
  private encodings: string[] = ['UTF-8', 'GBK', 'ISO-8859-1', 'UTF-16'];
  private chunkSize: number = 100000; // 每块5万字符

  aboutToAppear() {
    let params = (router.getParams() as Record<string, string>)
    this.fileUri = params['fileUri']
    if (this.fileUri) {
      this.loadFileContent();
    } else {
      this.errorMessage = "未提供文件URI";
    }
  }

  // 加载文件内容
  async loadFileContent() {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      // 获取文件名
      this.fileName = CommonUtils.getFileNameFromUri(this.fileUri) || '未命名文件';

      // 打开文件
      const file = fs.openSync(this.fileUri, fs.OpenMode.READ_ONLY);

      // 获取文件大小
      const stat = fs.statSync(file.fd);

      // 设置最大读取限制（150KB）
      const maxSize = 150 * 1024;
      if (stat.size > maxSize) {
        this.errorMessage = `文件过大 (${this.formatFileSize(stat.size)})，仅显示前150KB内容`;
      }

      // 计算实际读取大小
      const readSize = Math.min(stat.size, maxSize);

      // 读取文件内容
      const buffer = new ArrayBuffer(readSize);
      const readResult = fs.readSync(file.fd, buffer, {
        offset: 0,
        length: readSize
      });

      // 关闭文件
      fs.closeSync(file);

      // 转换编码
      this.convertBufferToText(buffer, this.encoding);

      this.fileChunks = []
      this.fileChunks.push(this.fileContent);

      this.isLoading = false;
    } catch (error) {
      console.error(`文件读取失败: ${(error as BusinessError).message}`);
      this.errorMessage = "无法读取文件内容";
      this.isLoading = false;
    }
  }

  // 将内容分割成块
  splitContentIntoChunks() {
    if (!this.fileContent) return;

    this.fileChunks = [];
    const contentLength = this.fileContent.length;

    // 计算总页数
    this.totalPages = Math.ceil(contentLength / this.chunkSize);

    // 分割内容
    for (let i = 0; i < this.totalPages; i++) {
      const start = i * this.chunkSize;
      const end = Math.min(start + this.chunkSize, contentLength);
      this.fileChunks.push(this.fileContent.substring(start, end));
    }

    // 设置当前页
    this.currentPage = 0;
  }

  // 转换缓冲区为文本
  convertBufferToText(buffer: ArrayBuffer, encoding: string) {
    try {
      const decoder = util.TextDecoder.create(encoding.toLowerCase())
      this.fileContent = decoder.decodeToString(
        new Uint8Array(buffer),
        { stream: false }
      );
    } catch (e) {
      // 如果指定编码失败，尝试UTF-8
      try {
        const fallbackDecoder = util.TextDecoder.create('utf-8')

        this.fileContent = fallbackDecoder.decodeToString(
          new Uint8Array(buffer),
          { stream: false }
        );
        this.encoding = 'UTF-8';
      } catch (err) {
        this.errorMessage = "无法解码文件内容";
        this.fileContent = "";
      }
    }
  }

  // 格式化文件大小
  formatFileSize(bytes: number): string {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
  }

  // 增加字体大小
  increaseFontSize() {
    this.fontSize = Math.min(this.fontSize + 2, 32);
  }

  // 减小字体大小
  decreaseFontSize() {
    this.fontSize = Math.max(this.fontSize - 2, 10);
  }

  // 切换编码
  changeEncoding() {
    const currentIndex = this.encodings.indexOf(this.encoding);
    const nextIndex = (currentIndex + 1) % this.encodings.length;
    this.encoding = this.encodings[nextIndex];

    // 重新加载文件内容
    this.loadFileContent();
  }

  // 复制内容到剪贴板
  copyToClipboard() {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.fileContent);
      pasteboard.getSystemPasteboard().setData(pasteData);
      promptAction.showToast({ message: "已复制到剪贴板", duration: 2000 });
    } catch (error) {
      promptAction.showToast({ message: "复制失败", duration: 2000 });
    }
  }

  // 上一页
  prevPage() {
    if (this.currentPage > 0) {
      this.currentPage--;
    }
  }

  // 下一页
  nextPage() {
    if (this.currentPage < this.totalPages - 1) {
      this.currentPage++;
    }
  }

  // 构建顶部工具栏
  @Builder
  buildToolbar() {
    Row() {
      Button("返回")
        .width(60)
        .height(30)
        .fontSize(14)
        .onClick(() => {
          router.back();
        })

      Text(this.fileName)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .margin({ left: 10 })
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button("复制")
        .width(60)
        .height(30)
        .fontSize(14)
        .margin({ left: 10 })
        .onClick(() => {
          this.copyToClipboard();
        })
    }
    .padding(10)
    .backgroundColor('#FFFFFF')
    .border({ width: 1, color: '#E0E0E0' })
  }

  // 构建控制栏
  @Builder
  buildControls() {
    Column() {
      Row() {
        Button("A-")
          .width(50)
          .height(30)
          .fontSize(14)
          .onClick(() => {
            this.decreaseFontSize();
          })

        Text(`字体: ${this.fontSize}px`)
          .fontSize(14)
          .margin({ left: 10, right: 10 })

        Button("A+")
          .width(50)
          .height(30)
          .fontSize(14)
          .onClick(() => {
            this.increaseFontSize();
          })

        Button(`编码: ${this.encoding}`)
          .width(130)
          .height(30)
          .fontSize(12)
          .margin({ left: 10 })
          .onClick(() => {
            this.changeEncoding();
          })
      }
      .padding(10)
      .backgroundColor('#FFFFFF')
      .border({ width: 1, color: '#E0E0E0' })
      .width('100%')

      // 分页控制
      if (this.totalPages > 1) {
        Row() {
          Button("<")
            .width(40)
            .height(40)
            .fontSize(16)
            .enabled(this.currentPage > 0)
            .onClick(() => {
              this.prevPage();
            })

          Text(`${this.currentPage + 1}/${this.totalPages}`)
            .fontSize(16)
            .margin({ left: 10, right: 10 })

          Button(">")
            .width(40)
            .height(40)
            .fontSize(16)
            .enabled(this.currentPage < this.totalPages - 1)
            .onClick(() => {
              this.nextPage();
            })
        }
        .padding(10)
        .backgroundColor('#FFFFFF')
        .border({ width: 1, color: '#E0E0E0' })
        .width('100%')
      }
    }
  }

  // 构建内容显示区
  @Builder
  buildContentArea() {
    Column() {
      if (this.isLoading) {
        // 加载状态
        Column() {
          Progress({ value: 50, style: ProgressStyle.Linear })
            .width('80%')
            .margin({ bottom: 20 })

          Text("正在加载文件内容...")
            .fontSize(16)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.errorMessage.length > 0) {
        // 错误状态
        Column() {
          Image($r('app.media.icon_error'))
            .width(60)
            .height(60)
            .margin({ bottom: 20 })

          Text(this.errorMessage)
            .fontSize(16)
            .fontColor(Color.Red)
            .textAlign(TextAlign.Center)
            .margin({ bottom: 10 })

          if (this.errorMessage.includes('文件过大')) {
            Button("确认")
              .width(200)
              .height(40)
              .onClick(() => {
                this.errorMessage = '';
              })
              .margin({ bottom: 10 })
            Button("加载完整内容")
              .width(200)
              .height(40)
              .onClick(() => {
                this.loadFullContent();
              })
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else if (this.fileChunks.length > 0) {
        // 正常显示内容（分块）
        Scroll() {
          Text(this.fileChunks[this.currentPage])
            .fontSize(this.fontSize)
            .fontFamily('monospace')
            .textAlign(TextAlign.Start)
            .width('100%')
            .padding(10)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.On)
        .scrollBarColor('#888888')
        .scrollBarWidth(10)
      } else {
        // 空内容状态
        Column() {
          Text("文件内容为空")
            .fontSize(18)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .layoutWeight(1)
    .backgroundColor('#FFFFFF')
    .margin({ top: 5 })
  }

  // 加载完整内容（仅用于大文件）
  async loadFullContent() {
    try {
      this.isLoading = true;
      this.errorMessage = '';

      const file = fs.openSync(this.fileUri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);

      const buffer = new ArrayBuffer(stat.size);
      const readResult = fs.readSync(file.fd, buffer, {
        offset: 0,
        length: stat.size
      });

      fs.closeSync(file);
      this.convertBufferToText(buffer, this.encoding);
      this.splitContentIntoChunks();
      this.isLoading = false;
    } catch (error) {
      console.error(`完整文件读取失败: ${(error as BusinessError).message}`);
      this.errorMessage = "无法读取完整文件内容";
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // 顶部工具栏
      this.buildToolbar()

      // 控制栏
      this.buildControls()

      // 内容显示区
      this.buildContentArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}