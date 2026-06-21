import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
}

interface State {
  error: Error | null;
}

/**
 * Catches render-time errors anywhere in the tree and shows a recoverable
 * fallback instead of a blank white screen.
 */
export default class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error("Uncaught error in dashboard:", error, info);
  }

  render(): ReactNode {
    if (this.state.error) {
      return (
        <div className="login">
          <div className="login-card">
            <h2>Terjadi kesalahan</h2>
            <p className="muted">{this.state.error.message}</p>
            <button type="button" onClick={() => window.location.reload()}>
              Muat ulang
            </button>
          </div>
        </div>
      );
    }
    return this.props.children;
  }
}
