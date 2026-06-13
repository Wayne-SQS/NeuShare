import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import { GradeService } from '../services/GradeService';
import { GradePill } from '../components/GradePill';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct IdentityCardPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State selectedGrade: string = '';
  @State studentId: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State isSaving: boolean = false;
  @State cardOpacity: number = 0;
  @State cardTranslateY: number = 40;
  @State titleOpacity: number = 0;
  @State titleY: number = 20;
  @State showPassword: boolean = false;
  private gradeService: GradeService = GradeService.getInstance();
  private grades: string[] = ['大一', '大二', '大三', '大四'];

  aboutToAppear(): void {
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.titleOpacity = 1;
        this.titleY = 0;
      });
    }, 100);

    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.cardOpacity = 1;
        this.cardTranslateY = 0;
      });
    }, 250);
  }

  async confirmAndEnter(): Promise<void> {
    if (!this.selectedGrade || this.isSaving) return;
    if (this.password.length > 0 && this.password !== this.confirmPassword) return;
    this.isSaving = true;

    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.gradeService.init(context);
      await this.gradeService.setGrade(this.selectedGrade);
      await this.gradeService.setStudentId(this.studentId);
      if (this.password.length > 0) {
        await this.gradeService.setPassword(this.password);
      }
      await this.gradeService.markOnboardingComplete();
    } catch (e) {
      console.error('IdentityCardPage save failed: ' + JSON.stringify(e));
    }

    try {
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {}
  }

  skipRegistration(): void {
    try {
      router.replaceUrl({ url: 'pages/Index' });
    } catch (e) {}
  }

  build() {
    Column() {
      // Top band
      Column()
        .width('100%').height(120)
        .backgroundColor(ColorTokens.primary(this.isDarkMode))

      Scroll() {
        Column() {
          // Welcome header
          Column() {
            Text('🎓 创建你的学习身份')
              .fontSize(22).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
              .opacity(this.titleOpacity).translate({ y: this.titleY })
            Text('只需一次设置，为你精准推荐课程与资源')
              .fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode))
              .margin({ top: 8 })
              .opacity(this.titleOpacity).translate({ y: this.titleY })
          }
          .width('100%').alignItems(HorizontalAlign.Center).margin({ top: 0 })

          // Registration card
          Column() {
            // Major (pre-filled)
            Row() {
              Column() {
                Text('📚 专业').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
                Text('软件工程').fontSize(17).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.textPrimary(this.isDarkMode)).margin({ top: 4 })
              }
              Blank()
              Row() {
                Text('NEU').fontSize(11).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(8)
                Text(' ✓ 已认证').fontSize(11).fontColor(ColorTokens.GREEN).margin({ left: 6 })
              }
            }.width('100%')

            Divider().color(ColorTokens.divider(this.isDarkMode)).margin({ top: 14, bottom: 14 })

            // Grade selector
            Column() {
              Text('🎯 年级').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ bottom: 12 })
              Row() {
                ForEach(this.grades, (grade: string) => {
                  GradePill({
                    label: grade,
                    isSelected: this.selectedGrade === grade,
                    onTap: () => { this.selectedGrade = grade; }
                  }).margin({ right: 10 })
                })
              }.width('100%')
            }

            Divider().color(ColorTokens.divider(this.isDarkMode)).margin({ top: 14, bottom: 14 })

            // Student ID
            Column() {
              Text('🆔 学号（选填）').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ bottom: 8 })
              TextInput({ text: this.studentId, placeholder: '例：20230001' })
                .fontSize(15).width('100%').height(44)
                .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
                .padding({ left: 14 })
                .onChange((value: string) => { this.studentId = value; })
            }

            Divider().color(ColorTokens.divider(this.isDarkMode)).margin({ top: 14, bottom: 14 })

            // Password
            Column() {
              Text('🔒 设置密码（选填，用于账户保护）')
                .fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ bottom: 8 })

              Row() {
                TextInput({ text: this.password, placeholder: '6-16位密码' })
                  .fontSize(15).layoutWeight(1).height(44)
                  .type(this.showPassword ? InputType.Normal : InputType.Password)
                  .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
                  .padding({ left: 14 })
                  .onChange((value: string) => { this.password = value; })
                Text(this.showPassword ? '🙈' : '👁️')
                  .fontSize(16).margin({ left: 8 })
                  .onClick(() => { this.showPassword = !this.showPassword; })
              }.width('100%')

              if (this.password.length > 0) {
                TextInput({ text: this.confirmPassword, placeholder: '确认密码' })
                  .fontSize(15).width('100%').height(44)
                  .type(InputType.Password)
                  .backgroundColor(ColorTokens.bgInput(this.isDarkMode)).borderRadius(12)
                  .padding({ left: 14 }).margin({ top: 8 })
                  .onChange((value: string) => { this.confirmPassword = value; })

                if (this.confirmPassword.length > 0 && this.password !== this.confirmPassword) {
                  Text('⚠ 两次密码不一致').fontSize(11).fontColor(ColorTokens.RED).margin({ top: 6 })
                }
              }
            }
          }
          .width('100%').padding(22)
          .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(20)
          .shadow({ radius: 16, color: '#12000000', offsetX: 0, offsetY: 4 })
          .border({ width: 1, color: '#08000000', radius: 20 })
          .margin({ top: 28, left: 24, right: 24 })
          .opacity(this.cardOpacity).translate({ y: this.cardTranslateY })

          // Confirm button
          Button(this.selectedGrade ? '✓ 完成注册，开始探索' : '请先选择年级')
            .width('100%').height(54)
            .fontSize(16).fontWeight(FontWeight.Bold).fontColor(this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE)
            .backgroundColor(this.selectedGrade ? ColorTokens.primary(this.isDarkMode) : ColorTokens.TEXT_DISABLED)
            .borderRadius(16)
            .shadow(this.selectedGrade ? {
              radius: 12, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), offsetX: 0, offsetY: 6
            } : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
            .margin({ top: 32, left: 24, right: 24 })
            .enabled(this.selectedGrade.length > 0 && !this.isSaving)
            .onClick(() => { this.confirmAndEnter(); })

          // Skip link
          Text('暂时跳过，以后设置 →')
            .fontSize(13).fontColor(ColorTokens.textHint(this.isDarkMode))
            .margin({ top: 18 })
            .onClick(() => { this.skipRegistration(); })

          Text('年级信息仅用于课程推荐，随时可在设置中修改')
            .fontSize(11).fontColor(ColorTokens.TEXT_DISABLED)
            .margin({ top: 12, bottom: 40 }).textAlign(TextAlign.Center)

          Column().height(40)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
  }
}
