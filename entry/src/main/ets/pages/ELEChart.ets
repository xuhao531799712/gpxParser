import { VChart } from '@visactor/harmony-vchart';

interface Event {
  dimensionInfo: Array<DimensionInfo>
  action: string
}

interface DimensionInfo {
  index: number
  value: string
}

@Entry
@Component
export struct ELEChart {
  onReady:(() => void) | undefined = undefined;
  onTap:((dataIndex: number) => void) | undefined = undefined;
  @Prop chartHeight: number = 0
  @Prop chartWidth: number = 0
  @Prop dis: number = 0
  @Prop ele: number = 0
  @Prop totalDis: number = 0
  @Prop totalEle: number = 0

  @Prop spec:Record<string, string|ESObject> = {
    'type': 'area',
    'data': {
      values: ({}) as ESObject
    }
  }

  build() {
    Row() {
      Column() {
        ChartHeader({dis: this.dis, ele: this.ele, totalDis: this.totalDis, totalEle: this.totalEle})

        VChart({
          spec: this.spec,
          w: this.chartWidth,
          h: this.chartHeight,
          onChartInitCb: (vchart) => {
            if (this.onReady != undefined) {
              this.onReady()
            }
          },
          onChartReadyCb: (vchart) => {
            vchart.on('dimensionHover', async (e: Event)=> {
              // 处理逻辑
              console.debug("xxxxxxuuuuu " + e.action + " " + e.dimensionInfo[0].index.toString())
              if (this.onTap != undefined) {
                await this.onTap(e.dimensionInfo[0].index)
              }
            });
          },
        })
      }
      .width('100%')
    }
    // .height('100%')
  }
}

// 图表头部组件
@Component
struct ChartHeader {
  @Prop dis: number = 0
  @Prop ele: number = 0
  @Prop totalDis: number = 0
  @Prop totalEle: number = 0

  build() {
    Row() {
      // 海拔统计信息
      Column() {
        Text('总距离')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.totalDis.toFixed(2) + 'km')
          .fontSize(12)
          .fontColor(Color.Red)
      }
      .margin({ right: 20 })

      Column() {
        Text('总爬升')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.totalEle.toString() + 'm')
          .fontSize(12)
          .fontColor(Color.Red)
      }
      .margin({ right: 20 })

      Column() {
        Text('累计距离')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.dis.toFixed(2) + 'km')
          .fontSize(12)
          .fontColor(Color.Red)
      }
      .margin({ right: 20 })

      Column() {
        Text('当前海拔')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.ele.toString() + 'm')
          .fontSize(12)
          .fontColor(Color.Blue)
      }
      .margin({ right: 20 })
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .height('5%')
    .padding(5)
  }
}