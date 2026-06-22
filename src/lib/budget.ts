import type { BudgetConfig, BudgetStatus, MonthlySpend } from '../types/budget';

export function calculateBudgetStatus(spend: MonthlySpend, config: BudgetConfig): BudgetStatus {
  const percentUsed = config.monthlyTarget <= 0 ? 0 : (spend.amount / config.monthlyTarget) * 100;
  const thresholds = config.thresholds.map((percent) => {
    const amount = config.monthlyTarget * (percent / 100);

    return {
      percent,
      amount,
      reached: spend.amount >= amount
    };
  });
  const reachedThresholds = thresholds.filter((threshold) => threshold.reached);

  return {
    percentUsed,
    isOverBudget: spend.amount > config.monthlyTarget,
    highestReachedThreshold: reachedThresholds.at(-1)?.percent ?? null,
    thresholds
  };
}

export function formatCurrency(value: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value);
}

export function formatPercent(value: number): string {
  return `${Math.round(value)}%`;
}
