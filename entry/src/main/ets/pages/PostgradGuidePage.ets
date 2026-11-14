import router from '@ohos.router';
import { ColorTokens, FontScale, Radii } from '@neushare/common';
import postgradData from '../data/postgrad.json';

interface PostgradTimeline {
  phase: string;
  period: string;
  emoji: string;
  description: string;
}

interface MaterialItem {
  name: string;
  purchaseUrl?: string;
}

interface PostgradSubject {
  sections: string[];
  materials: MaterialItem[];
  tip: string;
}

interface InfoSource {
  name: string;
  url: string;
  desc: string;
}

interface PostgradOption {
  type: string;
  description: string;
  schools: string[];
  pros: string[];
  cons: string[];
}

interface PostgradSchedulePhase {
  phase: string;
  period: string;
  tasks: string[];
}

interface NeuLink {
  name: string;
  url: string;
  desc: string;
}

@Entry
@Component
struct PostgradGuidePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @State expandedSubject: string = '';
  @State showPurchaseNotice: boolean = true;
  @State appearOpacity: number = 0;
  private timeline: PostgradTimeline[] = [];
  private subjectNames: string[] = [];
  private subjectMap: Record<string, PostgradSubject> = {};
  private infoSources: InfoSource[] = [];
  private schoolOptions: PostgradOption[] = [];
  private schoolIntro: string = '';
  private schoolSuggestion: string = '';
  private neuLinks: NeuLink[] = [];
  private studySchedule: PostgradSchedulePhase[] = [];

  aboutToAppear(): void {
    const data = postgradData;
    this.timeline = data.timeline;
    this.subjectNames = Object.keys(data.subjects);
    this.subjectMap = data.subjects;
    this.infoSources = data.infoSources;
    this.schoolOptions = data.schoolSelection.options;
    this.schoolIntro = data.schoolSelection.intro;
    this.schoolSuggestion = data.schoolSelection.suggestion;
    this.neuLinks = data.schoolSelection.neuLinks || [];
    this.studySchedule = data.studySchedule;
    animateTo({ duration: 200, curve: Curve.EaseOut }, () => { this.appearOpacity = 1; });
  }

  toggleSubject(subject: string): void {
    if (this.expandedSubject === subject) {
      this.expandedSubject = '';
    } else {
      this.expandedSubject = subject;
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('返回')
          .fontSize(FontScale.BODY_SM).fontColor(ColorTokens.textSecondary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('考研全攻略')
          .fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 24 })
      }
      .width('100%').height(52).padding({ left: 24, right: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      Scroll() {
        Column() {
          // Hero banner
          Stack({ alignContent: Alignment.Start }) {
            Column()
              .width('100%').height(100)
              .backgroundColor(ColorTokens.bgPage(this.isDarkMode))
              .borderRadius(Radii.XXL)
            Row() {
              Column() {
                Text('软件工程考研全攻略')
                  .fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_WHITE)
                Text('从报名到上岸，一站式信息整合')
                  .fontSize(FontScale.LABEL).fontColor(ColorTokens.withAlpha(ColorTokens.TEXT_WHITE, 'BB')).margin({ top: 4 })
              }.margin({ left: 14 }).alignItems(HorizontalAlign.Start)
            }.padding(20)
          }.width('100%').margin({ left: 24, right: 24, top: 16 })

          // ── Timeline ─────────────────────────
          this.sectionTitle('考研关键时间轴')
          Column() {
            ForEach(this.timeline, (item: PostgradTimeline, index: number) => {
              Row() {
                // Timeline line + dot
                Column() {
                  Text((index + 1).toString())
                    .fontSize(FontScale.LABEL)
                    .fontColor(ColorTokens.primary(this.isDarkMode))
                    .width(24).height(24).textAlign(TextAlign.Center)
                    .borderRadius(Radii.PILL)
                    .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                  if (index < this.timeline.length - 1) {
                    Column()
                      .width(2).height(30)
                      .backgroundColor(ColorTokens.divider(this.isDarkMode))
                      .margin({ top: 4 })
                  }
                }.alignItems(HorizontalAlign.Center)

                // Content card
                Column() {
                  Text(item.phase)
                    .fontSize(FontScale.BODY).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                  Text(item.period)
                    .fontSize(FontScale.LABEL).fontColor(ColorTokens.primary(this.isDarkMode))
                    .margin({ top: 2 })
                  Text(item.description)
                    .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                    .lineHeight(18).margin({ top: 4 })
                }
                .layoutWeight(1).padding(14)
                .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
                .margin({ left: 12, bottom: 8 })
                .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
              }
              .width('100%').alignItems(VerticalAlign.Top)
            })
          }
          .width('100%').padding({ left: 20, right: 24 })

          // ── Purchase Notice ──────────────────
          if (this.showPurchaseNotice) {
            Row() {
              Text('推荐资料为学习参考，请按需购买，不必贪多。书籍价格不菲，建议结合课程进度选择最需要的入手。')
                .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                .layoutWeight(1).lineHeight(18)
              Text('关闭')
                .fontSize(FontScale.BODY_SM).fontColor(ColorTokens.textHint(this.isDarkMode))
                .padding({ left: 8, top: 4, bottom: 4 })
                .onClick(() => { this.showPurchaseNotice = false; })
            }
            .width('100%').padding(12)
            .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
            .borderRadius(Radii.CARD)
            .margin({ left: 24, right: 24, top: 12 })
          }

          // ── Exam Subjects ────────────────────
          this.sectionTitle('考试科目详解')
          Column() {
            ForEach(this.subjectNames, (subjectName: string) => {
              Column() {
                Row() {
                  Text(subjectName)
                    .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
                    .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                    .margin({ left: 8 })
                  Blank()
                  Text(this.expandedSubject === subjectName ? '▲' : '▼')
                    .fontSize(FontScale.LABEL).fontColor(ColorTokens.textHint(this.isDarkMode))
                }
                .width('100%').padding(14)
                .onClick(() => { this.toggleSubject(subjectName); })

                if (this.expandedSubject === subjectName) {
                  Column() {
                    // Sections
                    Text('考察内容')
                      .fontSize(FontScale.LABEL).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textHint(this.isDarkMode))
                      .width('100%')
                    Row() {
                      ForEach(this.subjectMap[subjectName].sections, (sec: string) => {
                        Text(sec)
                          .fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                          .borderRadius(Radii.SM).margin({ right: 6, top: 4 })
                      })
                    }.width('100%')

                    // Materials
                    Text('推荐资料')
                      .fontSize(FontScale.LABEL).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textHint(this.isDarkMode))
                      .width('100%').margin({ top: 12 })
                    ForEach(this.subjectMap[subjectName].materials, (mat: MaterialItem) => {
                      Row() {
                        Text('·').fontSize(FontScale.BODY_SM).fontColor(ColorTokens.primary(this.isDarkMode)).margin({ right: 6 })
                        Text(mat.name)
                          .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                          .layoutWeight(1)
                        if (mat.purchaseUrl && mat.purchaseUrl.length > 0) {
                          Text('去购买')
                            .fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                            .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.SM)
                            .margin({ left: 6 })
                            .onClick(() => {
                              router.pushUrl({ url: 'pages/WebViewPage', params: { url: mat.purchaseUrl, title: mat.name } });
                            })
                        }
                      }.width('100%').margin({ top: 3 })
                    })

                    // Tip
                    Text(this.subjectMap[subjectName].tip)
                      .fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                      .lineHeight(16)
                      .padding(10)
                      .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                      .borderRadius(Radii.MD)
                      .width('100%').margin({ top: 10 })
                  }
                  .width('100%').padding({ left: 14, right: 14, bottom: 14 })
                }
              }
              .width('100%')
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
              .margin({ bottom: 8 })
              .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
            })
          }
          .width('100%').padding({ left: 24, right: 24 })

          // ── Info Sources ─────────────────────
          this.sectionTitle('信息查询渠道')
          Column() {
            ForEach(this.infoSources, (source: InfoSource) => {
              Row() {
                Column() {
                  Text(source.name)
                    .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(source.desc)
                    .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
                    .lineHeight(16).margin({ top: 2 })
                }.layoutWeight(1)
                if (source.url) {
                  Text('打开')
                    .fontSize(FontScale.BODY_SM)
                    .fontColor(ColorTokens.primary(this.isDarkMode))
                    .padding(6)
                    .onClick(() => {
                      router.pushUrl({ url: 'pages/WebViewPage', params: { url: source.url, title: source.name } });
                    })
                }
              }
              .width('100%').padding(14)
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
              .margin({ bottom: 6 })
              .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
            })
          }
          .width('100%').padding({ left: 24, right: 24 })

          // ── School Selection ─────────────────
          this.sectionTitle('择校建议')

          // NEU links（母校单独列出）
          if (this.neuLinks.length > 0) {
            ForEach(this.neuLinks, (link: NeuLink) => {
              Row() {
                Column() {
                  Text(link.name)
                    .fontSize(FontScale.CAPTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                  Text(link.desc)
                    .fontSize(FontScale.MICRO).fontColor(ColorTokens.textHint(this.isDarkMode))
                    .lineHeight(16).margin({ top: 2 })
                }.layoutWeight(1)
                Text('打开')
                  .fontSize(FontScale.BODY_SM)
                  .fontColor(ColorTokens.primary(this.isDarkMode))
                  .padding(6)
                  .onClick(() => {
                    router.pushUrl({ url: 'pages/WebViewPage', params: { url: link.url, title: link.name } });
                  })
              }
              .width('100%').padding(14)
              .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.CARD)
              .margin({ left: 24, right: 24, bottom: 6 })
              .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
            })
          }

          // 查看院校详情按钮
          Row() {
            Text('查看 35 所 CS 院校详情')
              .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              .layoutWeight(1)
          }
          .width('100%').padding(14)
          .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.XL)
          .margin({ left: 24, right: 24, bottom: 12 })
          .shadow({ radius: 8, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), offsetX: 0, offsetY: 4 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/SchoolGuidePage' });
          })

          Text(this.schoolIntro)
            .fontSize(FontScale.CAPTION).fontColor(ColorTokens.textSecondary(this.isDarkMode))
            .lineHeight(20)
            .width('100%').padding({ left: 24, right: 24 }).margin({ bottom: 12 })

          ForEach(this.schoolOptions, (option: PostgradOption) => {
            Column() {
              Text(option.type)
                .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
                .fontColor(option.type.includes('408') ? ColorTokens.primary(this.isDarkMode) : ColorTokens.primary(this.isDarkMode))
              Text(option.description)
                .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                .lineHeight(18).margin({ top: 8 })

              // Schools
              if (option.schools.length > 0) {
                Text('常见院校')
                  .fontSize(FontScale.MICRO).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textHint(this.isDarkMode))
                  .margin({ top: 10, bottom: 6 })
                Row() {
                  ForEach(option.schools, (school: string) => {
                    Text(school)
                      .fontSize(FontScale.MICRO).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                      .borderRadius(Radii.SM).margin({ right: 6, top: 4 })
                  })
                }.width('100%')
              }

              // Pros/Cons
              Row() {
                Column() {
                  Text('优势').fontSize(FontScale.MICRO).fontWeight(FontWeight.Bold).fontColor(ColorTokens.success(this.isDarkMode))
                  ForEach(option.pros, (pro: string) => {
                    Text('· ' + pro)
                      .fontSize(FontScale.MICRO).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ top: 2 })
                  })
                }.width('48%')
                Column() {
                  Text('劣势').fontSize(FontScale.MICRO).fontWeight(FontWeight.Bold).fontColor(ColorTokens.error(this.isDarkMode))
                  ForEach(option.cons, (con: string) => {
                    Text('· ' + con)
                      .fontSize(FontScale.MICRO).fontColor(ColorTokens.textSecondary(this.isDarkMode)).margin({ top: 2 })
                  })
                }.width('48%')
              }.width('100%').margin({ top: 10 })
            }
            .width('100%').padding(16)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
            .margin({ left: 24, right: 24, bottom: 10 })
            .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
          })

          // School suggestion
          Column() {
            Text('建议')
              .fontSize(FontScale.BODY_SM).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
            Text(this.schoolSuggestion)
              .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
              .lineHeight(18).margin({ top: 6 })
          }
          .width('100%').padding(16)
          .backgroundColor(ColorTokens.accentLight(this.isDarkMode)).borderRadius(Radii.XL)
          .margin({ left: 24, right: 24, top: 0, bottom: 12 })

          // ── Study Schedule ───────────────────
          this.sectionTitle('备考时间规划')
          ForEach(this.studySchedule, (phase: PostgradSchedulePhase, index: number) => {
            Row() {
              // Phase number
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(36).height(36).borderRadius(Radii.XXL)
                  .backgroundColor(index === 0 ? ColorTokens.primary(this.isDarkMode) :
                    index === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.success(this.isDarkMode))
                Text((index + 1).toString())
                  .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
              }

              Column() {
                Text(phase.phase)
                  .fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                Text(phase.period)
                  .fontSize(FontScale.LABEL).fontColor(
                    index === 0 ? ColorTokens.primary(this.isDarkMode) :
                    index === 1 ? ColorTokens.primary(this.isDarkMode) : ColorTokens.success(this.isDarkMode)
                  ).margin({ top: 2 })
                ForEach(phase.tasks, (task: string) => {
                  Row() {
                    Text('▸').fontSize(FontScale.TINY).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ right: 6 })
                    Text(task)
                      .fontSize(FontScale.LABEL).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                      .layoutWeight(1).lineHeight(18)
                  }.width('100%').margin({ top: 3 })
                })
              }
              .layoutWeight(1).margin({ left: 14 })
            }
            .width('100%').padding(14)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).borderRadius(Radii.XL)
            .margin({ left: 24, right: 24, bottom: 10 })
            .shadow({ radius: 4, color: ColorTokens.SHADOW_SOFT_LIGHT, offsetX: 0, offsetY: 1 })
          })

          // ── Bottom CTA ───────────────────────
          Button('浏览全部考研资源 →')
            .width('100%').height(50).fontSize(FontScale.SUBTITLE).fontWeight(FontWeight.Bold)
            .fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
            .backgroundColor(ColorTokens.primary(this.isDarkMode)).borderRadius(Radii.XL)
            .margin({ left: 24, right: 24, top: 8 })
            .shadow({ radius: 8, color: ColorTokens.withAlpha(ColorTokens.primary(this.isDarkMode), '40'), offsetX: 0, offsetY: 4 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: 5, categoryTitle: '考研' } });
            })

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
    .opacity(this.appearOpacity).animation({ curve: Curve.EaseOut, duration: 200 })
  }

  pageTransition() {
    PageTransitionEnter({ duration: 300, curve: Curve.EaseOut })
      .slide(SlideEffect.Right)
      .opacity(0.9)
    PageTransitionExit({ duration: 250, curve: Curve.EaseIn })
      .slide(SlideEffect.Left)
      .opacity(0.9)
  }

  @Builder
  sectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(FontScale.SECTION).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
    }
    .width('100%').padding({ left: 24, right: 24, top: 24, bottom: 12 })
  }
}


