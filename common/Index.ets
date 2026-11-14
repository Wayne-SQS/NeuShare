// NEUShare Common HAR - 公共能力层

// Config（后端地址等全局配置，单一数据源）
export { BASE_URL, FILE_BASE_URL } from './src/main/ets/config/AppConfig';

// Theme
export { ColorTokens } from './src/main/ets/theme/ColorTokens';
export { AppTheme, ThemeMode } from './src/main/ets/theme/AppTheme';
export { Spacing, Radii, FontScale, FontWeights, ControlSize, Elevation, ZIndex, Layout, Opacity, GridLayout } from './src/main/ets/theme/DesignTokens';

// Utils
export { ResourceTypeUtils } from './src/main/ets/utils/ResourceTypeUtils';
export { BreakpointSystem, BreakpointType, BreakpointTypeEnum, BreakpointTypeValue } from './src/main/ets/utils/BreakpointSystem';
export { PressableScale } from './src/main/ets/utils/InteractionUtils';
export { BlurPerformance, BlurLevel } from './src/main/ets/utils/BlurPerformance';

// Services
export { PreferencesStore } from './src/main/ets/services/PreferencesStore';

// Types
export { PageData } from './src/main/ets/types/PageData';

// Network
export { HttpClient, ApiResponse } from './src/main/ets/network/HttpClient';
export { AuthStore } from './src/main/ets/network/AuthStore';

// Components
export { EmptyState } from './src/main/ets/components/EmptyState';
export { StateView, ViewState } from './src/main/ets/components/StateView';
export { PageScaffold } from './src/main/ets/components/PageScaffold';
export { PageHeader } from './src/main/ets/components/PageHeader';
export { SectionHeader } from './src/main/ets/components/SectionHeader';
export { AppButton } from './src/main/ets/components/AppButton';
