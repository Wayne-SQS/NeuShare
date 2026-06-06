import { Context } from '@ohos.abilityAccessCtrl';
import { PreferencesStore } from '@neushare/common';

const GRADE_KEY = 'user_grade';
const STUDENT_ID_KEY = 'student_id';
const PASSWORD_KEY = 'user_password';
const ONBOARDING_KEY = 'onboarding_complete';

export class GradeService {
  private static instance: GradeService;
  private store: PreferencesStore = new PreferencesStore('neushare_preferences');

  private constructor() {}

  static getInstance(): GradeService {
    if (!GradeService.instance) {
      GradeService.instance = new GradeService();
    }
    return GradeService.instance;
  }

  async init(context: Context): Promise<void> {
    await this.store.init(context);
  }

  async getGrade(): Promise<string> {
    return this.store.get<string>(GRADE_KEY, '');
  }

  async setGrade(grade: string): Promise<void> {
    await this.store.set(GRADE_KEY, grade);
  }

  async setStudentId(studentId: string): Promise<void> {
    await this.store.set(STUDENT_ID_KEY, studentId);
  }

  async setPassword(password: string): Promise<void> {
    await this.store.set(PASSWORD_KEY, password);
  }

  async hasCompletedOnboarding(): Promise<boolean> {
    return this.store.get<boolean>(ONBOARDING_KEY, false);
  }

  async markOnboardingComplete(): Promise<void> {
    await this.store.set(ONBOARDING_KEY, true);
  }
}
