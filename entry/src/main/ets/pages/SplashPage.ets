import router from '@ohos.router';
import { GradeService } from '../services/GradeService';
import { Context } from '@ohos.abilityAccessCtrl';

@Entry
@Component
struct SplashPage {
  // Logo rings
  @State logoScale: number = 0.3;
  @State logoOpacity: number = 0;
  @State ringScale: number = 0;
  @State ringOpacity: number = 0;
  @State ring2Scale: number = 0;
  @State ring2Opacity: number = 0;
  // Text
  @State titleOpacity: number = 0;
  @State titleY: number = 30;
  @State subOpacity: number = 0;
  @State subY: number = 20;
  @State tagOpacity: number = 0;
  @State tagY: number = 16;
  // Particles
  @State particles: ParticleState[] = [];
  // Exit
  @State pageOpacity: number = 1;
  private jumped: boolean = false;
  private gradeService: GradeService = GradeService.getInstance();

  aboutToAppear(): void {
    this.initParticles();
    this.playAnimation();
  }

  initParticles(): void {
    const xs: number[] = [60, 310, 50, 280, 170, 330, 90, 240];
    const ys: number[] = [140, 100, 420, 380, 80, 280, 280, 500];
    const sizes: number[] = [4, 5, 3, 6, 3, 4, 5, 4];
    const colors: string[] = ['#FF6B6B', '#EE5A6F', '#C084FC', '#FF6B6B', '#C084FC', '#EE5A6F', '#FF6B6B', '#C084FC'];
    const delays: number[] = [0, 150, 250, 100, 200, 300, 50, 350];
    for (let i = 0; i < xs.length; i++) {
      const p: ParticleState = { x: xs[i], y: ys[i], size: sizes[i], opacity: 0, delay: delays[i], color: colors[i] };
      this.particles.push(p);
    }
  }

  playAnimation(): void {
    // Particles fade in staggered
    for (let i = 0; i < this.particles.length; i++) {
      setTimeout(() => {
        this.particles[i].opacity = 0.2 + (i % 3) * 0.06;
        this.particles = [...this.particles];
      }, this.particles[i].delay);
    }

    // Outer ring
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 800, curve: Curve.EaseOut }, () => {
        this.ringScale = 1.5;
        this.ringOpacity = 0.5;
      });
    }, 150);

    // Inner ring
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 650, curve: Curve.EaseOut }, () => {
        this.ring2Scale = 1;
        this.ring2Opacity = 0.6;
      });
    }, 300);

    // Logo bounces in
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 550, curve: Curve.FastOutSlowIn }, () => {
        this.logoScale = 1;
        this.logoOpacity = 1;
      });
    }, 450);

    // Title slide up
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 500, curve: Curve.EaseOut }, () => {
        this.titleOpacity = 1;
        this.titleY = 0;
      });
    }, 750);

    // Subtitle
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
        this.subOpacity = 1;
        this.subY = 0;
      });
    }, 1000);

    // Tagline chip
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 400, curve: Curve.EaseOut }, () => {
        this.tagOpacity = 1;
        this.tagY = 0;
      });
    }, 1250);

    // Ring breathe back
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 700, curve: Curve.EaseOut }, () => {
        this.ringScale = 1.3;
      });
    }, 1300);

    // Fade out
    setTimeout(() => {
      this.getUIContext().animateTo({ duration: 450, curve: Curve.EaseIn }, () => {
        this.pageOpacity = 0;
      });
    }, 2300);

    // Navigate
    setTimeout(() => {
      this.goNext();
    }, 2750);
  }

  async goNext(): Promise<void> {
    if (this.jumped) return;
    this.jumped = true;
    try {
      const context = this.getUIContext().getHostContext() as Context;
      await this.gradeService.init(context);
      const completed = await this.gradeService.hasCompletedOnboarding();
      if (completed) {
        router.replaceUrl({ url: 'pages/Index' });
      } else {
        router.replaceUrl({ url: 'pages/IdentityCardPage' });
      }
    } catch (e) {
      router.replaceUrl({ url: 'pages/IdentityCardPage' });
    }
  }

  build() {
    Stack() {
      // Background — warm peach → rose → lavender gradient
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#FFF1EB', 0],
            ['#FFE0D9', 0.25],
            ['#FDE0E8', 0.55],
            ['#F0E6FF', 0.85],
            ['#E8DFF8', 1]
          ]
        })

      // Soft ambient blobs
      Column()
        .width(180).height(180).borderRadius(90)
        .backgroundColor('#FF6B6B12')
        .blur(50)
        .position({ x: -50, y: -30 })

      Column()
        .width(140).height(140).borderRadius(70)
        .backgroundColor('#C084FC10')
        .blur(40)
        .position({ x: 260, y: 200 })

      Column()
        .width(120).height(120).borderRadius(60)
        .backgroundColor('#EE5A6F0E')
        .blur(35)
        .position({ x: 180, y: 460 })

      // Floating particles
      Stack() {
        ForEach(this.particles, (p: ParticleState) => {
          Column()
            .width(p.size).height(p.size)
            .borderRadius(p.size / 2)
            .backgroundColor(p.color + '30')
            .opacity(p.opacity)
            .position({ x: p.x, y: p.y })
            .animation({ duration: 700, curve: Curve.EaseOut })
        }, (p: ParticleState, idx: number) => 'p' + idx.toString())
      }
      .width('100%').height('100%')

      // Main content
      Column() {
        // Logo — geometric circle with text
        Stack({ alignContent: Alignment.Center }) {
          // Outer breathing ring
          Column()
            .width(130).height(130)
            .borderRadius(65)
            .border({ width: 2, color: '#FF6B6B18', radius: 65 })
            .scale({ x: this.ringScale, y: this.ringScale })
            .opacity(this.ringOpacity)

          // Inner ring
          Column()
            .width(90).height(90)
            .borderRadius(45)
            .border({ width: 2.5, color: '#EE5A6F20', radius: 45 })
            .backgroundColor('#FFFFFF40')
            .scale({ x: this.ring2Scale, y: this.ring2Scale })
            .opacity(this.ring2Opacity)

          // Glow behind logo
          Column()
            .width(50).height(50).borderRadius(25)
            .backgroundColor('#FF6B6B25')
            .blur(18)
            .scale({ x: this.logoScale, y: this.logoScale })
            .opacity(this.logoOpacity)

          // Logo circle
          Column()
            .width(68).height(68)
            .borderRadius(34)
            .linearGradient({
              direction: GradientDirection.Bottom,
              colors: [['#FF6B6B', 0], ['#EE5A6F', 0.5], ['#C084FC', 1]]
            })
            .shadow({ radius: 16, color: '#FF6B6B40', offsetX: 0, offsetY: 4 })
            .scale({ x: this.logoScale, y: this.logoScale })
            .opacity(this.logoOpacity)

          // "N" text inside circle
          Text('N')
            .fontSize(34)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .fontFamily('sans-serif-medium')
            .scale({ x: this.logoScale, y: this.logoScale })
            .opacity(this.logoOpacity)
        }

        // Title
        Text('NEU Share')
          .fontSize(34)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2D1B2E')
          .letterSpacing(3)
          .opacity(this.titleOpacity)
          .translate({ y: this.titleY })
          .margin({ top: 28 })

        // Subtitle
        Text('东北大学 · 软件学院')
          .fontSize(14)
          .fontColor('#2D1B2E99')
          .letterSpacing(6)
          .opacity(this.subOpacity)
          .translate({ y: this.subY })
          .margin({ top: 12 })

        // Feature tagline — glass chip
        Text('课程推荐  ·  资源共享  ·  考研指南')
          .fontSize(12)
          .fontColor('#2D1B2E88')
          .letterSpacing(1)
          .opacity(this.tagOpacity)
          .translate({ y: this.tagY })
          .margin({ top: 40 })
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFF60')
          .borderRadius(22)
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .opacity(this.pageOpacity)

      // Bottom text
      Text('Software College · Northeastern University')
        .fontSize(10)
        .fontColor('#2D1B2E44')
        .letterSpacing(2)
        .position({ x: '50%', y: '93%' })
        .translate({ x: '-50%', y: 0 })
        .opacity(this.subOpacity)
    }
    .width('100%').height('100%')
  }
}

interface ParticleState {
  x: number;
  y: number;
  size: number;
  opacity: number;
  delay: number;
  color: string;
}
