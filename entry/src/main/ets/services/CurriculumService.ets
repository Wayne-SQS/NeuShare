import curriculumData from '../data/curriculum.json';

export interface CurriculumCourse {
  name: string;
  emoji: string;
  categoryIds: number[];
  searchTags: string[];
  description: string;
}

interface CurriculumGrade {
  description: string;
  courses: CurriculumCourse[];
}

interface CurriculumData {
  grades: Record<string, CurriculumGrade>;
}

export class CurriculumService {
  private static instance: CurriculumService;

  private constructor() {}

  static getInstance(): CurriculumService {
    if (!CurriculumService.instance) {
      CurriculumService.instance = new CurriculumService();
    }
    return CurriculumService.instance;
  }

  getCurriculumForGrade(grade: string): CurriculumGrade | undefined {
    const data = curriculumData as CurriculumData;
    return data.grades[grade];
  }

  getCourseRecommendations(grade: string, count: number = 6): CurriculumCourse[] {
    const gradeData = this.getCurriculumForGrade(grade);
    if (!gradeData) return [];
    return gradeData.courses.slice(0, count);
  }
}
