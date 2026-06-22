import { useEffect, useState } from 'react';
import { defaultBudgetConfig } from './config/budget';
import { mockMonthlySpend } from './data/mockSpend';
import {
  calculateBudgetStatus,
  formatCurrency,
  formatPercent
} from './lib/budget';
import type { MonthlySpend } from './types/budget';

function App() {
  const [monthlySpend, setMonthlySpend] = useState<MonthlySpend>(mockMonthlySpend);
  const [dataState, setDataState] = useState<'loading' | 'live' | 'fallback'>('loading');

  useEffect(() => {
    let cancelled = false;

    fetch('/billing-data.json', { cache: 'no-store' })
      .then((response) => {
        if (!response.ok) {
          throw new Error(`Billing data request failed: ${response.status}`);
        }

        return response.json() as Promise<MonthlySpend>;
      })
      .then((data) => {
        if (!cancelled && Number.isFinite(data.amount)) {
          setMonthlySpend(data);
          setDataState(data.source === 'azure-cost-management' ? 'live' : 'fallback');
        }
      })
      .catch(() => {
        if (!cancelled) {
          setDataState('fallback');
        }
      });

    return () => {
      cancelled = true;
    };
  }, []);

  const status = calculateBudgetStatus(monthlySpend, defaultBudgetConfig);
  const remaining = Math.max(defaultBudgetConfig.monthlyTarget - monthlySpend.amount, 0);
  const nextThreshold = status.thresholds.find((threshold) => !threshold.reached);
  const refreshedAt = monthlySpend.refreshedAt
    ? new Intl.DateTimeFormat('en-US', {
        dateStyle: 'medium',
        timeStyle: 'short'
      }).format(new Date(monthlySpend.refreshedAt))
    : null;

  return (
    <main className="app-shell">
      <section className="dashboard-header" aria-labelledby="dashboard-title">
        <div>
          <p className="eyebrow">Azure Billing</p>
          <h1 id="dashboard-title">Monthly spend dashboard</h1>
        </div>
        <div className="billing-period">
          <span>Current period</span>
          <strong>{monthlySpend.periodLabel}</strong>
        </div>
      </section>

      <section className="summary-grid" aria-label="Billing summary">
        <article className="metric-panel primary-panel">
          <span className="metric-label">Current spend</span>
          <strong className="metric-value">{formatCurrency(monthlySpend.amount)}</strong>
          <span className="metric-detail">
            {formatPercent(status.percentUsed)} of {formatCurrency(defaultBudgetConfig.monthlyTarget)} target
          </span>
        </article>

        <article className="metric-panel">
          <span className="metric-label">Remaining budget</span>
          <strong className="metric-value">{formatCurrency(remaining)}</strong>
          <span className="metric-detail">{status.isOverBudget ? 'Budget exceeded' : 'Before over-budget state'}</span>
        </article>

        <article className="metric-panel">
          <span className="metric-label">Data source</span>
          <strong className="metric-value compact-value">{dataState === 'live' ? 'Azure live' : 'Static'}</strong>
          <span className="metric-detail">
            {dataState === 'loading'
              ? 'Loading Cost Management data'
              : dataState === 'live'
                ? 'Azure Cost Management snapshot'
                : 'Fallback billing snapshot'}
          </span>
        </article>
      </section>

      <section className="budget-panel" aria-labelledby="budget-progress-title">
        <div className="section-heading">
          <div>
            <p className="eyebrow">Thresholds</p>
            <h2 id="budget-progress-title">Budget progress</h2>
          </div>
          <span className={`status-pill ${status.isOverBudget ? 'danger' : 'steady'}`}>
            {status.isOverBudget ? 'Over budget' : `${status.highestReachedThreshold ?? 0}% reached`}
          </span>
        </div>

        <div className="progress-track" aria-label={`${formatPercent(status.percentUsed)} budget used`}>
          <div className="progress-fill" style={{ width: `${Math.min(status.percentUsed, 100)}%` }} />
          {status.thresholds.map((threshold) => (
            <span
              className={`threshold-marker ${threshold.reached ? 'reached' : ''}`}
              key={threshold.percent}
              style={{ left: `${threshold.percent}%` }}
              aria-label={`${threshold.percent}% threshold ${threshold.reached ? 'reached' : 'pending'}`}
            />
          ))}
        </div>

        <div className="threshold-list">
          {status.thresholds.map((threshold) => (
            <article className={threshold.reached ? 'threshold-card reached' : 'threshold-card'} key={threshold.percent}>
              <span>{threshold.percent}%</span>
              <strong>{formatCurrency(threshold.amount)}</strong>
              <small>{threshold.reached ? 'Email alert eligible' : 'Pending'}</small>
            </article>
          ))}
        </div>
      </section>

      <section className="alert-panel" aria-labelledby="alert-title">
        <div>
          <p className="eyebrow">Automation</p>
          <h2 id="alert-title">Email dispatch path</h2>
        </div>
        <div className="alert-copy">
          <p>
            Threshold email notifications should be configured with Azure Budget alerts first. If custom routing,
            templates, or audit workflow are needed, dispatch from an Azure Function or Logic App.
          </p>
          <p>
            {nextThreshold
              ? `Next alert threshold: ${nextThreshold.percent}% at ${formatCurrency(nextThreshold.amount)}.`
              : 'All configured thresholds have been reached for this month.'}
          </p>
          {refreshedAt ? <p>Cost data refreshed {refreshedAt}.</p> : null}
        </div>
      </section>
    </main>
  );
}

export default App;