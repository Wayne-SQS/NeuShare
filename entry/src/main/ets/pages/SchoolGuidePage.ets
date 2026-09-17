import router from '@ohos.router';
import { ColorTokens, BreakpointType as BpType, BreakpointTypeEnum } from '@neushare/common';

interface EvalItem {
  subject: string;    // 学科名称
  rating: string;     // 评级: A+, A, A-, B+, B 等
  round: string;      // 第几轮: "第五轮" / "第四轮"
}

interface SchoolInfo {
  name: string;
  evaluations: EvalItem[];
  exam: string;
  gradUrl: string;
  colleges: string;
}

const SCHOOLS: SchoolInfo[] = [
  {
    name: '清华大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第五轮' },
      { subject: '计算机', rating: 'A+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://www.tsinghua.edu.cn/yjsy/',
    colleges: '计算机科学与技术系、软件学院、人工智能研究院'
  },
  {
    name: '北京大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第五轮' },
      { subject: '计算机', rating: 'A+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grs.pku.edu.cn/',
    colleges: '计算机学院、智能学院、软件与微电子学院'
  },
  {
    name: '浙江大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第五轮' },
      { subject: '计算机', rating: 'A+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grs.zju.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '国防科技大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第五轮' },
      { subject: '计算机', rating: 'A+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'http://yjszs.nudt.edu.cn/',
    colleges: '计算机学院、智能科学学院'
  },
  {
    name: '北京航空航天大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://graduate.buaa.edu.cn/',
    colleges: '计算机学院、软件学院、人工智能研究院'
  },
  {
    name: '上海交通大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://www.gs.sjtu.edu.cn/',
    colleges: '计算机科学与工程系、人工智能研究院'
  },
  {
    name: '南京大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grawww.nju.edu.cn/',
    colleges: '计算机科学与技术系、软件学院、人工智能学院'
  },
  {
    name: '西北工业大学',
    evaluations: [
      { subject: '计算机', rating: 'A+', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grs.nwpu.edu.cn/',
    colleges: '计算机学院、软件学院'
  },
  {
    name: '哈尔滨工业大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://hitgs.hit.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '华中科技大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gs.hust.edu.cn/',
    colleges: '计算机科学与技术学院、人工智能与自动化学院'
  },
  {
    name: '北京邮电大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://yzb.bupt.edu.cn/',
    colleges: '计算机学院、人工智能学院、网络空间安全学院'
  },
  {
    name: '电子科技大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gr.uestc.edu.cn/',
    colleges: '计算机科学与工程学院、信息与软件工程学院'
  },
  {
    name: '北京理工大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grd.bit.edu.cn/',
    colleges: '计算机学院、软件学院'
  },
  {
    name: '中国人民大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://grs.ruc.edu.cn/',
    colleges: '信息学院、高瓴人工智能学院'
  },
  {
    name: '西安电子科技大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
      { subject: '网络空间安全', rating: 'A+', round: '第五轮' },
    ],
    exam: '自命题', gradUrl: 'https://gr.xidian.edu.cn/',
    colleges: '计算机科学与技术学院、人工智能学院、网络与信息安全学院'
  },
  {
    name: '复旦大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gs.fudan.edu.cn/',
    colleges: '计算机科学技术学院、人工智能研究院'
  },
  {
    name: '同济大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://yjsy.tongji.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '西安交通大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://yjsx.xjtu.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '中国科学技术大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gradschool.ustc.edu.cn/',
    colleges: '计算机科学与技术学院、大数据学院'
  },
  {
    name: '东北大学',
    evaluations: [
      { subject: '计算机', rating: 'A', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://www.graduate.neu.edu.cn/',
    colleges: '计算机科学与工程学院、软件学院、人工智能研究院'
  },
  {
    name: '武汉大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'A', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gs.whu.edu.cn/',
    colleges: '计算机学院、人工智能研究院'
  },
  {
    name: '中山大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://graduate.sysu.edu.cn/',
    colleges: '计算机科学与技术学院、人工智能学院'
  },
  {
    name: '四川大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://gs.scu.edu.cn/',
    colleges: '计算机学院、网络空间安全学院'
  },
  {
    name: '东南大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://seu.seu.edu.cn/',
    colleges: '计算机科学与工程学院、软件学院'
  },
  {
    name: '天津大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://yzb.tju.edu.cn/',
    colleges: '智能与计算学部'
  },
  {
    name: '吉林大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://yjsy.jlu.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '北京交通大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://gs.bjtu.edu.cn/',
    colleges: '计算机与信息技术学院、软件学院'
  },
  {
    name: '杭州电子科技大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://grs.hdu.edu.cn/',
    colleges: '计算机学院、网络空间安全学院'
  },
  {
    name: '湖南大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gra.hnu.edu.cn/',
    colleges: '信息科学与工程学院'
  },
  {
    name: '中南大学',
    evaluations: [
      { subject: '计算机', rating: 'A-', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'A-', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://gra.csu.edu.cn/',
    colleges: '计算机学院、软件学院'
  },
  {
    name: '大连理工大学',
    evaluations: [
      { subject: '计算机', rating: 'B+', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://gs.dlut.edu.cn/',
    colleges: '计算机科学与技术学院、软件学院'
  },
  {
    name: '华南理工大学',
    evaluations: [
      { subject: '计算机', rating: 'B+', round: '第五轮' },
      { subject: '软件工程', rating: 'A-', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '408', gradUrl: 'https://yz.scut.edu.cn/',
    colleges: '计算机科学与工程学院、软件学院'
  },
  {
    name: '南开大学',
    evaluations: [
      { subject: '计算机', rating: 'B+', round: '第五轮' },
      { subject: '软件工程', rating: 'B', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://graduate.nankai.edu.cn/',
    colleges: '计算机学院、人工智能学院'
  },
  {
    name: '重庆大学',
    evaluations: [
      { subject: '计算机', rating: 'B+', round: '第五轮' },
      { subject: '软件工程', rating: 'B+', round: '第五轮' },
      { subject: '计算机', rating: 'B+', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://gs.cqu.edu.cn/',
    colleges: '计算机学院、大数据与软件学院'
  },
  {
    name: '深圳大学',
    evaluations: [
      { subject: '计算机', rating: 'B', round: '第五轮' },
      { subject: '软件工程', rating: 'B', round: '第五轮' },
      { subject: '计算机', rating: 'B', round: '第四轮' },
    ],
    exam: '自命题', gradUrl: 'https://gra.szu.edu.cn/',
    colleges: '计算机与软件学院、人工智能与数字经济研究院'
  },
];

/** 评级→颜色：A+红 → A粉 → A-蓝紫 → B+青绿 → B灰蓝 */
function ratingColor(rating: string): string {
  if (rating === 'A+') return '#FF6B6B';
  if (rating === 'A') return '#FF8FB1';
  if (rating === 'A-') return '#4A6BFF';
  if (rating === 'B+') return '#00C2CB';
  return '#89CFEF';
}

@Entry
@Component
struct SchoolGuidePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointTypeEnum.SM;
  @State expandedIndex: number = -1;
  @State showFifthRound: boolean = true;   // 默认展示第五轮

  private columnsCount(): number {
    return new BpType<number>({ sm: 2, md: 2, lg: 3, xl: 3 }).getValue(this.currentBreakpoint) ?? 2;
  }

  toggleExpand(index: number): void {
    if (this.expandedIndex === index) {
      this.expandedIndex = -1;
    } else {
      this.expandedIndex = index;
    }
  }

  openGradUrl(url: string, name: string): void {
    router.pushUrl({ url: 'pages/WebViewPage', params: { url: url, title: name + ' - 研究生院' } });
  }

  /** 获取学校最高评级（用于概览卡片展示）*/
  private bestRating(evals: EvalItem[]): string {
    const order = ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C'];
    let best = 'C';
    for (const e of evals) {
      if (order.indexOf(e.rating) < order.indexOf(best)) {
        best = e.rating;
      }
    }
    return best;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('←').fontSize(24).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .onClick(() => { router.back(); })
        Text('计算机考研择校')
          .fontSize(18).fontWeight(FontWeight.Bold).fontColor(ColorTokens.textPrimary(this.isDarkMode))
          .layoutWeight(1).textAlign(TextAlign.Center).margin({ right: 24 })
      }
      .width('100%').height(52).padding({ left: 24, right: 24 })
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode))

      // Stats summary — 按最高评级统计
      Row() {
        Column() {
          Text(SCHOOLS.length.toString()).fontSize(20).fontWeight(FontWeight.Bold).fontColor(ColorTokens.primary(this.isDarkMode))
          Text('院校总数').fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text(SCHOOLS.filter(s => this.bestRating(s.evaluations) === 'A+').length.toString())
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ratingColor('A+'))
          Text('A+ 院校').fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text(SCHOOLS.filter(s => this.bestRating(s.evaluations) === 'A').length.toString())
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ratingColor('A'))
          Text('A 院校').fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
        }.layoutWeight(1)
        Column() {
          Text(SCHOOLS.filter(s => this.bestRating(s.evaluations) === 'A-').length.toString())
            .fontSize(20).fontWeight(FontWeight.Bold).fontColor(ratingColor('A-'))
          Text('A- 院校').fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode)).margin({ top: 2 })
        }.layoutWeight(1)
      }
      .width('100%').padding(16)
      .backgroundColor(ColorTokens.bgCard(this.isDarkMode)).margin({ top: 1 })

      // School grid
      Scroll() {
        Column() {
          ForEach(SCHOOLS, (school: SchoolInfo, index: number) => {
            Column() {
              // ═══ 卡片头部（折叠态） ═══
              Row() {
                Text(school.name)
                  .fontSize(14).fontWeight(FontWeight.Bold)
                  .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                  .layoutWeight(1).maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })

                // 多学科评级 tag 行（折叠态：紧凑排列）
                if (this.expandedIndex !== index) {
                  Row() {
                    ForEach(school.evaluations, (ev: EvalItem, ei: number) => {
                      Row() {
                        Text(ev.subject.substring(0, 2))  // "计算机"→"计算" / "软件" / "网络"
                          .fontSize(9)
                          .fontColor(this.isDarkMode ? '#000000' : ev.rating === 'A+' ? '#FFFFFF' : ColorTokens.textPrimary(this.isDarkMode))
                        Text(ev.rating)
                          .fontSize(10).fontWeight(FontWeight.Bold)
                          .fontColor(this.isDarkMode ? '#000000' : '#FFFFFF')
                        Text(ev.round === '第四轮' ? '④' : '⑤')
                          .fontSize(8)
                          .fontColor(this.isDarkMode ? '#000000' : '#FFFFFFBB')
                      }
                      .padding({ left: 5, right: 5, top: 2, bottom: 2 })
                      .backgroundColor(this.isDarkMode ? '#FFFFFF' : ratingColor(ev.rating))
                      .borderRadius(4)
                      .margin({ left: ei > 0 ? 4 : 0 })
                    }, (ev: EvalItem, ei: number) => 'hdr_' + index + '_' + ei.toString())
                  }
                }
              }.width('100%')

              // ═══ 展开详情 ═══
              if (this.expandedIndex === index) {
                Column() {
                  // ── 学科评估表格 ──
                  Text('学科评估')
                    .fontSize(13).fontWeight(FontWeight.Bold)
                    .fontColor(ColorTokens.textPrimary(this.isDarkMode))
                    .width('100%').margin({ top: 10 })

                  // 表头
                  Row() {
                    Text('学科').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).width(80)
                    Text('评级').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).width(44)
                    Text('轮次').fontSize(11).fontColor(ColorTokens.textHint(this.isDarkMode)).layoutWeight(1)
                  }.width('100%').padding({ top: 4, bottom: 4 })

                  // 评估行
                  ForEach(school.evaluations, (ev: EvalItem, ei: number) => {
                    Row() {
                      Text(ev.subject)
                        .fontSize(12).fontColor(ColorTokens.textPrimary(this.isDarkMode))
                        .width(80)
                      Row() {
                        Text(ev.rating)
                          .fontSize(12).fontWeight(FontWeight.Bold)
                          .fontColor(this.isDarkMode ? '#000000' : '#FFFFFF')
                          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                          .backgroundColor(this.isDarkMode ? '#FFFFFF' : ratingColor(ev.rating))
                          .borderRadius(6)
                      }.width(44)
                      Text(ev.round)
                        .fontSize(11).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                        .layoutWeight(1)
                    }
                    .width('100%').padding({ top: 5, bottom: 5 })
                    .border({ width: { bottom: ei < school.evaluations.length - 1 ? 0.5 : 0 }, color: ColorTokens.divider(this.isDarkMode) })
                  }, (ev: EvalItem, ei: number) => 'eval_' + index + '_' + ei.toString())

                  // ── 初试科目 ──
                  Row() {
                    Text('初试：').fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
                    Text(school.exam)
                      .fontSize(11).fontColor(ColorTokens.textOnPrimary(this.isDarkMode))
                      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                      .backgroundColor(school.exam === '408' ? ColorTokens.primary(this.isDarkMode) : ColorTokens.accentLight(this.isDarkMode))
                      .borderRadius(6)
                  }.width('100%').margin({ top: 12 })

                  // ── 相关院系 ──
                  Text('相关院系：')
                    .fontSize(12).fontColor(ColorTokens.textHint(this.isDarkMode))
                    .width('100%').margin({ top: 8 })
                  Text(school.colleges)
                    .fontSize(11).fontColor(ColorTokens.textSecondary(this.isDarkMode))
                    .lineHeight(16).width('100%')

                  // ── 研究生院链接 ──
                  Row() {
                    Text('🔗 研究生院')
                      .fontSize(12).fontColor(ColorTokens.primary(this.isDarkMode))
                      .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                      .backgroundColor(ColorTokens.accentLight(this.isDarkMode))
                      .borderRadius(10)
                      .onClick(() => { this.openGradUrl(school.gradUrl, school.name); })
                  }.width('100%').margin({ top: 10 })
                }
                .animation({ curve: Curve.EaseOut, duration: 200 })
              }

              // ── 底部：展开/收起提示 ──
              Row() {
                Text(this.expandedIndex === index ? '收起 ▲' : '详情 ▼')
                  .fontSize(10).fontColor(ColorTokens.textHint(this.isDarkMode))
              }.width('100%').justifyContent(FlexAlign.Center).margin({ top: this.expandedIndex === index ? 6 : 4 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor(ColorTokens.bgCard(this.isDarkMode))
            .borderRadius(14)
            .margin({ left: 12, right: 12, top: 6 })
            .shadow({ radius: 4, color: '#06000000', offsetX: 0, offsetY: 1 })
            .onClick(() => { this.toggleExpand(index); })
          }, (school: SchoolInfo, index: number) => index.toString())

          Column().height(40)
        }
        .width('100%')
        .constraintSize({ maxWidth: 680 })
      }
      .scrollable(ScrollDirection.Vertical).scrollBar(BarState.Auto).layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ColorTokens.bgPage(this.isDarkMode))
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
