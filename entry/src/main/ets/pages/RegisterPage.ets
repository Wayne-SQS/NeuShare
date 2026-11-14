import router from '@ohos.router';
import { AuthStore, ColorTokens, FontScale, Radii, Spacing, ControlSize, PageScaffold, AppButton } from '@neushare/common';
import { AuthApi } from '../api/AuthApi';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct RegisterPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State username: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State nickname: string = '';
  @State college: string = '';
  @State grade: number = 0;
  @State isLoading: boolean = false;
  @State errorMsg: string = '';
  @State showCollegePicker: boolean = false;
  @State btnPressed: boolean = false; // 按钮按压状态（教程 §16.3 生命力原则）
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
    PageScaffold({ title: '创建账号' }) {
      Column() {
        Column() {
          // 学号
          Text('学号').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ bottom: Spacing.XS }).width('100%')
          TextInput({ text: this.username, placeholder: '请输入学号' })
            .fontSize(FontScale.BODY).width('100%').height(ControlSize.INPUT)
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
            .padding({ left: Spacing.LG })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
            .onChange((value: string) => { this.username = value; })

          // 昵称
          Text('昵称').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ top: Spacing.MD, bottom: Spacing.XS }).width('100%')
          TextInput({ text: this.nickname, placeholder: '请输入昵称' })
            .fontSize(FontScale.BODY).width('100%').height(ControlSize.INPUT)
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
            .padding({ left: Spacing.LG })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
            .onChange((value: string) => { this.nickname = value; })

          // 密码
          Text('密码').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ top: Spacing.MD, bottom: Spacing.XS }).width('100%')
          TextInput({ text: this.password, placeholder: '请输入密码（至少6位）' })
            .fontSize(FontScale.BODY).width('100%').height(ControlSize.INPUT)
            .type(InputType.Password)
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
            .padding({ left: Spacing.LG })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
            .onChange((value: string) => { this.password = value; })

          // 确认密码
          Text('确认密码').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ top: Spacing.MD, bottom: Spacing.XS }).width('100%')
          TextInput({ text: this.confirmPassword, placeholder: '请确认密码' })
            .fontSize(FontScale.BODY).width('100%').height(ControlSize.INPUT)
            .type(InputType.Password)
            .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(Radii.CARD)
            .padding({ left: Spacing.LG })
            .border({ width: 1, color: ColorTokens.divider(this.isDarkMode), radius: Radii.CARD })
            .onChange((value: string) => { this.confirmPassword = value; })

          // 学院
          Text('学院').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ top: Spacing.MD, bottom: Spacing.XS }).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(this.colleges, (item: string, idx: number) => {
              Text(item)
                .fontSize(FontScale.BODY_SM)
                .fontColor(this.college === item ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
                .padding({ left: Spacing.LG, right: Spacing.LG, top: Spacing.SM, bottom: Spacing.SM })
                .backgroundColor(this.college === item ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                .borderRadius(Radii.SM)
                .margin({ right: Spacing.SM, top: Spacing.XS })
                .onClick(() => { this.college = item; })
            }, (item: string, idx: number) => 'col_' + idx.toString())
          }.width('100%')

          // 年级
          Text('年级').fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .margin({ top: Spacing.MD, bottom: Spacing.XS }).width('100%')
          Row() {
            ForEach(this.grades, (label: string, idx: number) => {
              Text(label)
                .fontSize(FontScale.BODY_SM)
                .fontColor(this.grade === (idx + 1) ? ColorTokens.textOnPrimary(this.isDarkMode) : ColorTokens.textSecondary(this.isDarkMode))
                .padding({ left: Spacing.XL, right: Spacing.XL, top: Spacing.SM, bottom: Spacing.SM })
                .backgroundColor(this.grade === (idx + 1) ? ColorTokens.primary(this.isDarkMode) : ColorTokens.bgInput(this.isDarkMode))
                .borderRadius(Radii.SM)
                .margin({ right: Spacing.SM })
                .onClick(() => { this.toggleGrade(idx); })
            }, (label: string, idx: number) => 'grad_' + idx.toString())
          }.width('100%')

          if (this.errorMsg) {
            Text(this.errorMsg).fontSize(FontScale.CAPTION).fontColor(ColorTokens.error(this.isDarkMode)).margin({ top: Spacing.MD })
          }

          Button(this.isLoading ? '注册中...' : '注 册')
            .width('100%').height(ControlSize.BUTTON)
            .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
            .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.BUTTON)
            .margin({ top: Spacing.XXL })
            .enabled(!this.isLoading)
            .scale({ x: this.btnPressed ? 0.96 : 1, y: this.btnPressed ? 0.96 : 1 })
            .animation({ curve: Curve.EaseOut, duration: 200 })
            .onTouch((event: TouchEvent) => {
              if (event.type === TouchType.Down) { this.btnPressed = true; }
              else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.btnPressed = false; }
            })
            .onClick(() => { this.doRegister(); })

          Text('已有账号？去登录')
            .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Medium).fontColor(ColorTokens.primary(this.isDarkMode))
            .height(ControlSize.BUTTON)
            .margin({ top: Spacing.MD })
            .onClick(() => { router.back(); })
        }
        .width('100%').padding(Spacing.XXL)

        Column().height(Spacing.HUGE)
      }
      .width('100%')
    }
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.9)
  }
}
