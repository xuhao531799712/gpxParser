@Entry
@Component
export struct PromptBar {
  @Prop text: string = ''
  build() {
    Row({ space: 12  }) // 间距8vp，垂直居中
    {
      Image($r('app.media.lightbulb'))
        .width(20)
        .height(20)
        .margin({ left: 12, right: 4 })

      Text(this.text)
        .fontSize(12)
    } .padding({ left: 8, right : 8, top: 6, bottom:6 })
    .backgroundColor(0xE0F5FF)
    .borderRadius(15)
    .alignItems(VerticalAlign.Center)
    .width('100%')
    .visibility(this.text.length > 0 ? Visibility.Visible : Visibility.None)
  }
}