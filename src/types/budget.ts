export type ResetPeriod = 'monthly';

export interface BudgetConfig {
  monthlyTarget: number;
  thresholds: number[];
  resetPeriod: ResetPeriod;
}

export interface MonthlySpend {
  amount: number;
  currency: 'USD';
  periodLabel: string;
  source: 'mock' | 'azure-cost-management';
  subscriptionId?: string;
  refreshedAt?: string | null;
}

export interface ThresholdStatus {
  percent: number;
  amount: number;
  reached: boolean;
}

export interface BudgetStatus {
  percentUsed: number;
  isOverBudget: boolean;
  highestReachedThreshold: number | null;
  thresholds: ThresholdStatus[];
}