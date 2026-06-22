import type { BudgetConfig } from '../types/budget';

const configuredTarget = Number(import.meta.env.VITE_MONTHLY_BUDGET_TARGET);

export const defaultBudgetConfig: BudgetConfig = {
  monthlyTarget: Number.isFinite(configuredTarget) && configuredTarget > 0 ? configuredTarget : 2.6,
  thresholds: [50, 75, 90],
  resetPeriod: 'monthly'
};
