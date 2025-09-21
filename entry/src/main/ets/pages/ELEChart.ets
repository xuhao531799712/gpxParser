// 鸿蒙版
import { ChartOptions, UCharts, UChartsController } from '@ibestservices/ucharts'

@Entry
@Component
export struct ELEChart {
  @Link chart: UChartsController;
  onReady:(() => void) | undefined = undefined;
  onTap:((dataIndex: number) => void) | undefined = undefined;

  build() {
    Column(){
      UCharts({contentHeight: 110, controller: this.chart, onReady: () => {
        // this.chart.updateData(this.opts)
        if (this.onReady != undefined) {
          this.onReady()
        }
      }, onTap: (dataIndex: number | number[])=> {
        if (this.onTap == undefined) return
        if (Array.isArray(dataIndex)) {
          this.onTap(dataIndex[0])
        } else {
          this.onTap(dataIndex)
        }
      }})
        .height($r('app.string.chart_ratio2'))
        .width('100%')

      /*
       * 或者初始化时传入默认配置
       * @State chart: UChartsController = new UChartsController(this.opts);
       * UCharts({ controller: this.chart })
       * */
    }
    .height($r('app.string.chart_ratio2'))
    .width('100%')
  }
}