@Component
export struct IconButton {
  @State image: Resource | undefined = undefined
  @State text: string = ''
  @Prop selected: boolean = false
  build() {
    Column({ space: 12  }) // 间距8vp，垂直居中
    {
      Image(this.image)
        .width(20)
        .height(20)

      Text(this.text)
        .fontSize(10)
        .lineHeight(1.2)
    } .padding({ left: 8,right : 8, top: 6, bottom:6 })
    .backgroundColor(this.selected? 0x1E90FF : 0xE0F5FF)
    .borderRadius(15)
    .alignItems(HorizontalAlign.Center)
  }
}