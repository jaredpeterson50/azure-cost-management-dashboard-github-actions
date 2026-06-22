import '@testing-library/jest-dom/vitest';
import { render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it, vi } from 'vitest';
import App from './App';

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('App', () => {
  it('renders the dashboard summary and threshold markers', () => {
    vi.stubGlobal('fetch', vi.fn().mockRejectedValue(new Error('Use fallback data in tests')));

    render(<App />);

    expect(screen.getByRole('heading', { name: /monthly spend dashboard/i })).toBeInTheDocument();
    expect(screen.getByText('Current spend')).toBeInTheDocument();
    expect(screen.getByText(/of \$2\.60 target/i)).toBeInTheDocument();
    expect(screen.getByText('50%')).toBeInTheDocument();
    expect(screen.getByText('75%')).toBeInTheDocument();
    expect(screen.getByText('90%')).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: /email dispatch path/i })).toBeInTheDocument();
  });
});