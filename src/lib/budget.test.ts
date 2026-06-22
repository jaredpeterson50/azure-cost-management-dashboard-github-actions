import { describe, expect, it } from 'vitest';
import { calculateBudgetStatus } from './budget';
import type { BudgetConfig, MonthlySpend } from '../types/budget';

const config: BudgetConfig = {
  monthlyTarget: 5,
  thresholds: [50, 75, 90],
  resetPeriod: 'monthly'
};

function spend(amount: number): MonthlySpend {
  return {
    amount,
    currency: 'USD',
    periodLabel: 'Test period',
    source: 'mock'
  };
}

describe('calculateBudgetStatus', () => {
  it('triggers the 50% threshold at $2.50', () => {
    const status = calculateBudgetStatus(spend(2.5), config);

    expect(status.highestReachedThreshold).toBe(50);
    expect(status.thresholds.map((threshold) => threshold.reached)).toEqual([true, false, false]);
  });

  it('triggers the 75% threshold at $3.75', () => {
    const status = calculateBudgetStatus(spend(3.75), config);

    expect(status.highestReachedThreshold).toBe(75);
    expect(status.thresholds.map((threshold) => threshold.reached)).toEqual([true, true, false]);
  });

  it('triggers the 90% threshold at $4.50', () => {
    const status = calculateBudgetStatus(spend(4.5), config);

    expect(status.highestReachedThreshold).toBe(90);
    expect(status.thresholds.map((threshold) => threshold.reached)).toEqual([true, true, true]);
  });

  it('does not trigger a threshold before the spend reaches it', () => {
    const status = calculateBudgetStatus(spend(2.49), config);

    expect(status.highestReachedThreshold).toBeNull();
    expect(status.thresholds.map((threshold) => threshold.reached)).toEqual([false, false, false]);
  });

  it('marks spend above $5.00 as over budget', () => {
    const status = calculateBudgetStatus(spend(5.01), config);

    expect(status.isOverBudget).toBe(true);
    expect(status.percentUsed).toBeCloseTo(100.2);
  });
});
