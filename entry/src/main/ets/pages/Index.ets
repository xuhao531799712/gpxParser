import { common } from '@kit.AbilityKit';
import { picker } from '@kit.CoreFileKit';
import type { BusinessError } from '@kit.BasicServicesKit';
import { router } from '@kit.ArkUI';

@Entry
@Component
struct DocumentViewPickerComponent {
  @State title: string = '';

  build() {
    Column() {
      Button('选择文件')
        .backgroundColor($r('sys.color.background_secondary'))
        .width(120)
        .height(40)
        .fontColor($r('sys.color.font_emphasize'))
        .fontWeight(FontWeight.Medium)
        .fontSize($r('sys.float.Body_L'))
        .onClick(() => {
          let context = getContext(this) as common.Context;
          try {
            const documentSelectOptions = new picker.DocumentSelectOptions();
            documentSelectOptions.fileSuffixFilters = ['.gpx']
            const documentPicker = new picker.DocumentViewPicker(context);
            documentPicker.select(documentSelectOptions).then((documentSelectResult: Array<string>) => {
              if (documentSelectResult.length === 0) {
                this.showErrorAlertDialog('文件路径为空')
                return;
              }
              this.getUIContext().getRouter().pushUrl({
                url: 'pages/BaseMap',
                params: {
                  gpxUrl: documentSelectResult[0],
                  enableMyLocation: 'false'
                }
              }, router.RouterMode.Standard)
            }).catch((err: BusinessError) => {
              console.error(`DocumentViewPicker.select failed with err: ${err.code}, ${err.message}`);
              this.showErrorAlertDialog(err.message)
            });
          } catch (error) {
            const err: BusinessError = error as BusinessError;
            console.error(`DocumentViewPicker failed with err: ${err.code}, ${err.message}`);
            this.showErrorAlertDialog(err.message)
          }
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
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