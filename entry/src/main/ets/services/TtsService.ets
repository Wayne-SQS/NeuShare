import { textToSpeech } from '@kit.CoreSpeechKit';

/**
 * TTS 语音朗读服务
 * 使用 HarmonyOS Core Speech Kit 实现文本转语音
 */
export class TtsService {
  private static instance: TtsService;
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null;
  private _isSpeaking: boolean = false;
  private _isInitialized: boolean = false;

  private constructor() {}

  static getInstance(): TtsService {
    if (!TtsService.instance) {
      TtsService.instance = new TtsService();
    }
    return TtsService.instance;
  }

  /**
   * 初始化 TTS 引擎
   */
  async init(): Promise<boolean> {
    if (this._isInitialized) return true;
    try {
      const extraParams: Record<string, Object> = {};
      extraParams['style'] = 'interaction-broadcast';
      extraParams['locate'] = 'CN';
      extraParams['name'] = 'zh-CN-xiaoyi-local';
      const initParams: textToSpeech.CreateEngineParams = {
        language: 'zh-CN',
        person: 0,
        online: 0, // 0 = 离线模式
        extraParams: extraParams
      };
      this.ttsEngine = await textToSpeech.createEngine(initParams);
      // 设置回调
      const listener: textToSpeech.SpeakListener = {
        onStart: () => { this._isSpeaking = true; },
        onComplete: () => { this._isSpeaking = false; },
        onStop: () => { this._isSpeaking = false; },
        onData: () => {},
        onError: () => { this._isSpeaking = false; }
      };
      if (this.ttsEngine !== null) {
        this.ttsEngine.setListener(listener);
      }
      this._isInitialized = true;
      return true;
    } catch (e) {
      console.error('TTS init failed: ' + JSON.stringify(e));
      return false;
    }
  }

  /**
   * 朗读文本
   */
  async speak(text: string): Promise<boolean> {
    if (!this.ttsEngine) {
      const ok = await this.init();
      if (!ok) return false;
    }
    // 如果正在朗读，先停止
    if (this._isSpeaking) {
      this.stop();
    }
    try {
      const speakExtraParams: Record<string, Object> = {};
      speakExtraParams['speed'] = 1.0;
      speakExtraParams['pitch'] = 1.0;
      speakExtraParams['volume'] = 2.0;
      const speakParams: textToSpeech.SpeakParams = {
        requestId: Date.now().toString(),
        extraParams: speakExtraParams
      };
      this.ttsEngine!.speak(text, speakParams);
      return true;
    } catch (e) {
      console.error('TTS speak failed: ' + JSON.stringify(e));
      return false;
    }
  }

  /**
   * 停止朗读
   */
  stop(): void {
    if (this.ttsEngine && this._isSpeaking) {
      try {
        this.ttsEngine.stop();
      } catch (e) {
        console.error('TTS stop failed: ' + JSON.stringify(e));
      }
    }
    this._isSpeaking = false;
  }

  /**
   * 是否正在朗读
   */
  isSpeaking(): boolean {
    return this._isSpeaking;
  }

  /**
   * 朗读资源详情（标题 + 描述）
   */
  async speakResource(title: string, description: string): Promise<boolean> {
    const text = title + '。' + (description || '暂无描述');
    return this.speak(text);
  }

  /**
   * 销毁引擎
   */
  shutdown(): void {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.shutdown();
      } catch (e) {}
      this.ttsEngine = null;
      this._isInitialized = false;
      this._isSpeaking = false;
    }
  }
}
