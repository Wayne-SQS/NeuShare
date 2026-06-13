import router from '@ohos.router';
import { ColorTokens } from '@neushare/common';
import postgradData from '../data/postgrad.json';

interface PostgradTimeline {
  phase: string;
  period: string;
  emoji: string;
  description: string;
}

interface PostgradSubject {
  sections: string[];
  materials: string[];
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

@Entry
@Component
struct PostgradGuidePage {
  @State expandedSubject: string = '';
  private timeline: PostgradTimeline[] = [];
  private subjectNames: string[] = [];
  private subjectMap: Record<string, PostgradSubject> = {};
  private infoSources: InfoSource[] = [];
  private schoolOptions: PostgradOption[] = [];
  private schoolIntro: string = '';
  private schoolSuggestion: string = '';
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
    this.studySchedule = data.studySchedule;
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
        Text('←')
          .fontSize(24).fontColor(ColorTokens.TEXT_PRIMARY)
          .onClick(() => { router.back(); })
        Text('考研全攻略')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 24 })
      }
      .width('100%').height(52).padding({ left: 16, right: 16 })
      .backgroundColor(ColorTokens.BG_CARD)

      Scroll() {
        Column() {
          // Hero banner
          Stack({ alignContent: Alignment.Start }) {
            Column()
              .width('100%').height(100)
              .backgroundColor('#1A1A1A')
              .borderRadius(16)
            Row() {
              Text('🎓').fontSize(36)
              Column() {
                Text('软件工程考研全攻略')
                  .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                Text('从报名到上岸，一站式信息整合')
                  .fontSize(12).fontColor('#FFFFFFBB').margin({ top: 4 })
              }.margin({ left: 14 }).alignItems(HorizontalAlign.Start)
            }.padding(20)
          }.width('100%').margin({ left: 16, right: 16, top: 16 })

          // ── Timeline ─────────────────────────
          this.sectionTitle('📅 考研关键时间轴')
          Column() {
            ForEach(this.timeline, (item: PostgradTimeline, index: number) => {
              Row() {
                // Timeline line + dot
                Column() {
                  Text(item.emoji).fontSize(22)
                  if (index < this.timeline.length - 1) {
                    Column()
                      .width(2).height(30)
                      .backgroundColor(ColorTokens.DIVIDER)
                      .margin({ top: 4 })
                  }
                }.alignItems(HorizontalAlign.Center)

                // Content card
                Column() {
                  Text(item.phase)
                    .fontSize(15).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                  Text(item.period)
                    .fontSize(12).fontColor(ColorTokens.PRIMARY)
                    .margin({ top: 2 })
                  Text(item.description)
                    .fontSize(12).fontColor(ColorTokens.TEXT_SECONDARY)
                    .lineHeight(18).margin({ top: 4 })
                }
                .layoutWeight(1).padding(14)
                .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
                .margin({ left: 12, bottom: 8 })
                .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
              }
              .width('100%').alignItems(VerticalAlign.Top)
            })
          }
          .width('100%').padding({ left: 20, right: 16 })

          // ── Exam Subjects ────────────────────
          this.sectionTitle('📝 考试科目详解')
          Column() {
            ForEach(this.subjectNames, (subjectName: string) => {
              Column() {
                Row() {
                  Text(this.subjectEmoji(subjectName)).fontSize(20)
                  Text(subjectName)
                    .fontSize(16).fontWeight(FontWeight.Bold)
                    .fontColor(ColorTokens.TEXT_PRIMARY)
                    .margin({ left: 8 })
                  Blank()
                  Text(this.expandedSubject === subjectName ? '▲' : '▼')
                    .fontSize(12).fontColor(ColorTokens.TEXT_HINT)
                }
                .width('100%').padding(14)
                .onClick(() => { this.toggleSubject(subjectName); })

                if (this.expandedSubject === subjectName) {
                  Column() {
                    // Sections
                    Text('考察内容')
                      .fontSize(12).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_HINT)
                      .width('100%')
                    Row() {
                      ForEach(this.subjectMap[subjectName].sections, (sec: string) => {
                        Text(sec)
                          .fontSize(11).fontColor(ColorTokens.PRIMARY)
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                          .borderRadius(6).margin({ right: 6, top: 4 })
                      })
                    }.width('100%')

                    // Materials
                    Text('推荐资料')
                      .fontSize(12).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_HINT)
                      .width('100%').margin({ top: 12 })
                    ForEach(this.subjectMap[subjectName].materials, (mat: string) => {
                      Row() {
                        Text('·').fontSize(14).fontColor(ColorTokens.ACCENT).margin({ right: 6 })
                        Text(mat)
                          .fontSize(12).fontColor(ColorTokens.TEXT_SECONDARY)
                          .layoutWeight(1)
                      }.width('100%').margin({ top: 3 })
                    })

                    // Tip
                    Text('💡 ' + this.subjectMap[subjectName].tip)
                      .fontSize(11).fontColor(ColorTokens.ACCENT)
                      .lineHeight(16)
                      .padding(10)
                      .backgroundColor(ColorTokens.ACCENT_LIGHT)
                      .borderRadius(8)
                      .width('100%').margin({ top: 10 })
                  }
                  .width('100%').padding({ left: 14, right: 14, bottom: 14 })
                }
              }
              .width('100%')
              .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
              .margin({ bottom: 8 })
              .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
            })
          }
          .width('100%').padding({ left: 16, right: 16 })

          // ── Info Sources ─────────────────────
          this.sectionTitle('🔗 信息查询渠道')
          Column() {
            ForEach(this.infoSources, (source: InfoSource) => {
              Row() {
                Column() {
                  Text(source.name)
                    .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(source.desc)
                    .fontSize(11).fontColor(ColorTokens.TEXT_HINT)
                    .lineHeight(16).margin({ top: 2 })
                }.layoutWeight(1)
                if (source.url) {
                  Text('🔗')
                    .fontSize(16)
                    .padding(6)
                    .onClick(() => {
                      // External link would go here, but ArkWeb not included
                    })
                }
              }
              .width('100%').padding(14)
              .backgroundColor(ColorTokens.BG_CARD).borderRadius(12)
              .margin({ bottom: 6 })
              .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
            })
          }
          .width('100%').padding({ left: 16, right: 16 })

          // ── School Selection ─────────────────
          this.sectionTitle('🎯 择校建议')
          Text(this.schoolIntro)
            .fontSize(13).fontColor(ColorTokens.TEXT_SECONDARY)
            .lineHeight(20)
            .width('100%').padding({ left: 16, right: 16 }).margin({ bottom: 12 })

          ForEach(this.schoolOptions, (option: PostgradOption) => {
            Column() {
              Text(option.type)
                .fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor(option.type.includes('408') ? ColorTokens.PRIMARY : ColorTokens.ACCENT)
              Text(option.description)
                .fontSize(12).fontColor(ColorTokens.TEXT_SECONDARY)
                .lineHeight(18).margin({ top: 8 })

              // Schools
              if (option.schools.length > 0) {
                Text('常见院校')
                  .fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_HINT)
                  .margin({ top: 10, bottom: 6 })
                Row() {
                  ForEach(option.schools, (school: string) => {
                    Text(school)
                      .fontSize(11).fontColor(ColorTokens.PRIMARY)
                      .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                      .backgroundColor(ColorTokens.PRIMARY_LIGHT)
                      .borderRadius(6).margin({ right: 6, top: 4 })
                  })
                }.width('100%')
              }

              // Pros/Cons
              Row() {
                Column() {
                  Text('✅ 优势').fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.GREEN)
                  ForEach(option.pros, (pro: string) => {
                    Text('· ' + pro)
                      .fontSize(11).fontColor(ColorTokens.TEXT_SECONDARY).margin({ top: 2 })
                  })
                }.width('48%')
                Column() {
                  Text('⚠️ 劣势').fontSize(11).fontWeight(FontWeight.Bold).fontColor(ColorTokens.RED)
                  ForEach(option.cons, (con: string) => {
                    Text('· ' + con)
                      .fontSize(11).fontColor(ColorTokens.TEXT_SECONDARY).margin({ top: 2 })
                  })
                }.width('48%')
              }.width('100%').margin({ top: 10 })
            }
            .width('100%').padding(16)
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
            .margin({ left: 16, right: 16, bottom: 10 })
            .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
          })

          // School suggestion
          Column() {
            Text('💡 建议')
              .fontSize(14).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
            Text(this.schoolSuggestion)
              .fontSize(12).fontColor(ColorTokens.TEXT_SECONDARY)
              .lineHeight(18).margin({ top: 6 })
          }
          .width('100%').padding(16)
          .backgroundColor(ColorTokens.ACCENT_LIGHT).borderRadius(14)
          .margin({ left: 16, right: 16, top: 0, bottom: 12 })

          // ── Study Schedule ───────────────────
          this.sectionTitle('📆 备考时间规划')
          ForEach(this.studySchedule, (phase: PostgradSchedulePhase, index: number) => {
            Row() {
              // Phase number
              Stack({ alignContent: Alignment.Center }) {
                Column()
                  .width(36).height(36).borderRadius(18)
                  .backgroundColor(index === 0 ? ColorTokens.PRIMARY :
                    index === 1 ? ColorTokens.ACCENT : ColorTokens.GREEN)
                Text((index + 1).toString())
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
              }

              Column() {
                Text(phase.phase)
                  .fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
                Text(phase.period)
                  .fontSize(12).fontColor(
                    index === 0 ? ColorTokens.PRIMARY :
                    index === 1 ? ColorTokens.ACCENT : ColorTokens.GREEN
                  ).margin({ top: 2 })
                ForEach(phase.tasks, (task: string) => {
                  Row() {
                    Text('▸').fontSize(10).fontColor(ColorTokens.TEXT_HINT).margin({ right: 6 })
                    Text(task)
                      .fontSize(12).fontColor(ColorTokens.TEXT_SECONDARY)
                      .layoutWeight(1).lineHeight(18)
                  }.width('100%').margin({ top: 3 })
                })
              }
              .layoutWeight(1).margin({ left: 14 })
            }
            .width('100%').padding(14)
            .backgroundColor(ColorTokens.BG_CARD).borderRadius(14)
            .margin({ left: 16, right: 16, bottom: 10 })
            .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
          })

          // ── Bottom CTA ───────────────────────
          Button('浏览全部考研资源 →')
            .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .backgroundColor(ColorTokens.PRIMARY).borderRadius(14)
            .margin({ left: 16, right: 16, top: 8 })
            .shadow({ radius: 8, color: ColorTokens.PRIMARY + '40', offsetX: 0, offsetY: 4 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CategoryPage', params: { categoryId: 5, categoryTitle: '考研' } });
            })

          Column().height(80)
        }
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Off).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.BG_PAGE)
  }

  @Builder
  sectionTitle(title: string) {
    Row() {
      Text(title)
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.TEXT_PRIMARY)
    }
    .width('100%').padding({ left: 16, right: 16, top: 24, bottom: 12 })
  }

  private subjectEmoji(name: string): string {
    switch (name) {
      case '政治': return '📕';
      case '英语': return '📗';
      case '数学一': return '📘';
      case '408计算机专业基础综合': return '📙';
      default: return '📖';
    }
  }
}
