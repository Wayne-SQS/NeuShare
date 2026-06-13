import router from '@ohos.router';
import { AuthStore } from '@neushare/common';
import { AuthApi } from '../api/AuthApi';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State college: string = '';
  @State grade: number = 0;
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State showCollegePicker: boolean = false;
  private authApi: AuthApi = new AuthApi();
  private authStore: AuthStore = AuthStore.getInstance();
  private grades: string[] = ['大一', '大二', '大三', '大四'];
  private colleges: string[] = ['软件学院', '计算机学院', '信息学院', '数学学院'];

  getGradeLabel(index: number): string {
    if (index >= 0 && index < this.grades.length) {
      return this.grades[index];
    }
    return '请选择年级';
  }

  toggleGrade(index: number): void {
    this.grade = index + 1;
  }

  async doRegister(): Promise<void> {
    if (!this.username.trim()) {
      this.errorMsg = '请输入学号';
      return;
    }
    if (!this.nickname.trim()) {
      this.errorMsg = '请输入昵称';
      return;
    }
    if (!this.password) {
      this.errorMsg = '请输入密码';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码不一致';
      return;
    }
    if (this.password.length < 6) {
      this.errorMsg = '密码至少6位';
      return;
    }
    if (!this.college) {
      this.errorMsg = '请选择学院';
      return;
    }
    if (this.grade === 0) {
      this.errorMsg = '请选择年级';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.authStore.init(context);
      const resp = await this.authApi.register(
        this.username.trim(), this.password,
        this.nickname.trim(), this.college, this.grade
      );
      if (resp.code === 200) {
        const loginResp = await this.authApi.login(this.username.trim(), this.password);
        if (loginResp.code === 200 && loginResp.data) {
          await this.authStore.saveLogin(loginResp.data.token, loginResp.data.user);
          router.replaceUrl({ url: 'pages/Index' });
        } else {
          router.replaceUrl({ url: 'pages/LoginPage' });
        }
      } else {
        this.errorMsg = resp.message || '注册失败';
      }
    } catch (e) {
      this.errorMsg = '无法连接服务器';
    }
    this.isLoading = false;
  }

  build() {
    Column() {
      Row() {
        Text('←').fontSize(24).fontColor('#000000')
          .onClick(() => { router.back(); })
        Text('创建账号').fontSize(18).fontWeight(FontWeight.Bolder).fontColor('#000000')
          .margin({ left: 12 })
      }
      .width('100%').height(52).padding({ left: 16 }).backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Column() {
            // 学号
            Text('学号').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ bottom: 6 }).width('100%')
            TextInput({ text: this.username, placeholder: '请输入学号' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.username = value; })

            // 昵称
            Text('昵称').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ top: 14, bottom: 6 }).width('100%')
            TextInput({ text: this.nickname, placeholder: '请输入昵称' })
              .fontSize(15).width('100%').height(48)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.nickname = value; })

            // 密码
            Text('密码').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ top: 14, bottom: 6 }).width('100%')
            TextInput({ text: this.password, placeholder: '请输入密码（至少6位）' })
              .fontSize(15).width('100%').height(48)
              .type(InputType.Password)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.password = value; })

            // 确认密码
            Text('确认密码').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ top: 14, bottom: 6 }).width('100%')
            TextInput({ text: this.confirmPassword, placeholder: '请确认密码' })
              .fontSize(15).width('100%').height(48)
              .type(InputType.Password)
              .backgroundColor('#F5F5F5').borderRadius(12)
              .padding({ left: 16 })
              .border({ width: 1, color: '#EEEEEE', radius: 12 })
              .onChange((value: string) => { this.confirmPassword = value; })

            // 学院
            Text('学院').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ top: 14, bottom: 6 }).width('100%')
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.colleges, (item: string) => {
                Text(item)
                  .fontSize(14)
                  .fontColor(this.college === item ? '#FFFFFF' : '#666666')
                  .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .backgroundColor(this.college === item ? '#FF5A5F' : '#F5F5F5')
                  .borderRadius(10)
                  .margin({ right: 8, top: 4 })
                  .onClick(() => { this.college = item; })
              })
            }.width('100%')

            // 年级
            Text('年级').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#333333')
              .margin({ top: 14, bottom: 6 }).width('100%')
            Row() {
              ForEach(this.grades, (label: string, idx: number) => {
                Text(label)
                  .fontSize(14)
                  .fontColor(this.grade === (idx + 1) ? '#FFFFFF' : '#666666')
                  .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                  .backgroundColor(this.grade === (idx + 1) ? '#FF5A5F' : '#F5F5F5')
                  .borderRadius(10)
                  .margin({ right: 8 })
                  .onClick(() => { this.toggleGrade(idx); })
              })
            }.width('100%')

            if (this.errorMsg) {
              Text(this.errorMsg).fontSize(13).fontColor('#FF5A5F').margin({ top: 14 })
            }

            Button(this.isLoading ? '注册中...' : '注 册')
              .width('100%').height(48)
              .fontSize(16).fontWeight(FontWeight.Bolder).fontColor('#FFFFFF')
              .backgroundColor('#FF5A5F').borderRadius(14)
              .margin({ top: 28 })
              .enabled(!this.isLoading)
              .onClick(() => { this.doRegister(); })

            Text('已有账号？去登录 →')
              .fontSize(14).fontWeight(FontWeight.Medium).fontColor('#FF5A5F')
              .margin({ top: 18 })
              .onClick(() => { router.back(); })
          }
          .width('100%').padding(24)
          .margin({ top: 8, left: 16, right: 16 })

          Column().height(60)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#FFFFFF')
  }
}
