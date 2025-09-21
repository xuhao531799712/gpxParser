// 鸿蒙版
import { AreaSeries, ChartOptions, UCharts, UChartsController } from '@ibestservices/ucharts'

@Entry
@Component
export struct ELEChart {
  @Link chart: UChartsController;
  onReady:(() => void) | undefined = undefined;
  onTap:((dataIndex: number) => void) | undefined = undefined;
  @Prop chartHeight: number = 0
  @State dis: string = '0km'
  @State ele: string = '0m'
  getChartOpt:(()=>(Partial<ChartOptions> | undefined)) | undefined = undefined

  build() {
    Column(){
      ChartHeader({dis: this.dis, ele: this.ele})

      UCharts({contentHeight: this.chartHeight, controller: this.chart, onReady: () => {
        // this.chart.updateData(this.opts)
        if (this.onReady != undefined) {
          this.onReady()
        }
      }, onTap: (dataIndex: number | number[])=> {
        if (this.onTap == undefined) return
        let index: number = Array.isArray(dataIndex) ? dataIndex[0] : dataIndex
        this.onTap(index)
        if (this.getChartOpt != undefined) {
          let chartOpts = this.getChartOpt()
          if (chartOpts != undefined && chartOpts.series != undefined &&
            chartOpts.categories != undefined) {
            let ser = chartOpts.series[0] as AreaSeries
            this.ele = ser.data[index].toString() + 'm'
            this.dis = chartOpts.categories[index].toString() + 'km'
          }
        }
      }})
        .width('100%')

      /*
       * 或者初始化时传入默认配置
       * @State chart: UChartsController = new UChartsController(this.opts);
       * UCharts({ controller: this.chart })
       * */
    }
    .width('100%')
  }
}

// 图表头部组件
@Component
struct ChartHeader {
  @Prop dis: string = '15.6km'
  @Prop ele: string = '420m'
  build() {
    Row() {
      // 海拔统计信息
      Column() {
        Text('累计距离')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.dis)
          .fontSize(12)
          .fontColor(Color.Red)
      }
      .margin({ right: 20 })

      Column() {
        Text('当前海拔')
          .fontSize(12)
          .fontColor(Color.Gray)
        Text(this.ele)
          .fontSize(12)
          .fontColor(Color.Blue)
      }
      .margin({ right: 20 })
    }
    .justifyContent(FlexAlign.SpaceAround)
    .width('100%')
    .height('5%')
    .padding(10)
  }
}