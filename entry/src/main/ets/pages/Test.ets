import { AAID } from '@kit.PushKit';

@Entry
@Component
struct Test {
  @State message: string = 'Hello World';
  map: Record<'John' | 'Mary', 25 | 21> = {
  'John': 25,
  'Mary': 21,
}

  build() {
    RelativeContainer() {

      Text(this.message)
        .id('TestHelloWorld')
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(() => {
          this.message = 'Welcome';
          let a: A = new B()
          a.print()
          let c: AA = {}
          this.map['John'] = 21

        })
    }
    .height('100%')
    .width('100%')
  }
}

class A {
  print(...resA: number[]) {
    console.log("AAAAAAAAAAAAAAAAAAAAAAA")
  }
}
class B extends A {
  private _age = 0
  print(): void {
    super.print()
    console.log("AAAAAAAAAAAAABBBBBBBBBB")
  }

  get age(): number {
    return this._age
  }
}

class AA {
}