import { useState } from 'react';
import { useNavigate, useLocation, Navigate } from 'react-router-dom';
import { useAuth, defaultRouteForRole } from '../../auth/AuthContext';

export default function Login() {
  const { login, isAuthenticated, role, loading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Zaten girişliyse rolüne göre yönlendir
  if (!loading && isAuthenticated) {
    const target = location.state?.from?.pathname || defaultRouteForRole(role);
    return <Navigate to={target} replace />;
  }

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSubmitting(true);
    try {
      const profile = await login(email.trim(), password);
      const target =
        location.state?.from?.pathname || defaultRouteForRole(profile.role);
      navigate(target, { replace: true });
    } catch (err) {
      setError(
        err?.status === 401 || err?.status === 400
          ? 'E-posta veya şifre hatalı.'
          : err?.message || 'Giriş yapılamadı. Lütfen tekrar deneyin.'
      );
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-background text-on-background flex items-center justify-center px-4">
      <div className="w-full max-w-[420px] bg-surface-container-lowest border border-outline-variant rounded-2xl ambient-shadow p-8">
        <div className="flex flex-col items-center mb-6">
          <img
            src="/sukranapp.png"
            alt="Şükran App"
            className="h-14 w-auto object-contain mb-4"
          />
          <h1 className="font-headline-md text-headline-md text-on-background">
            İşletme Paneli Girişi
          </h1>
          <p className="font-body-sm text-body-sm text-on-surface-variant mt-1">
            Devam etmek için hesabınıza giriş yapın
          </p>
        </div>

        {error && (
          <div className="mb-4 flex items-center gap-2 bg-error-container text-error rounded-lg px-4 py-3 text-body-sm">
            <span className="material-symbols-outlined text-[20px]">error</span>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="flex flex-col gap-4">
          <label className="flex flex-col gap-1">
            <span className="font-label-sm text-label-sm text-on-surface-variant">
              E-posta
            </span>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
                mail
              </span>
              <input
                type="email"
                required
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="ornek@isletme.com"
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 pl-11 pr-4 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
              />
            </div>
          </label>

          <label className="flex flex-col gap-1">
            <span className="font-label-sm text-label-sm text-on-surface-variant">
              Şifre
            </span>
            <div className="relative">
              <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-on-surface-variant text-[20px]">
                lock
              </span>
              <input
                type={showPassword ? 'text' : 'password'}
                required
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full bg-surface-container-low border border-outline-variant rounded-lg py-3 pl-11 pr-11 text-body-md focus:border-primary-container focus:ring-1 focus:ring-primary-container outline-none transition-all"
              />
              <button
                type="button"
                onClick={() => setShowPassword((p) => !p)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-on-surface-variant hover:text-on-background"
                aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
              >
                <span className="material-symbols-outlined text-[20px]">
                  {showPassword ? 'visibility_off' : 'visibility'}
                </span>
              </button>
            </div>
          </label>

          <button
            type="submit"
            disabled={submitting}
            className="mt-2 bg-primary-container text-on-primary-container py-3 rounded-lg font-label-md text-label-md hover:opacity-90 transition-opacity flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {submitting ? (
              <>
                <span className="material-symbols-outlined animate-spin text-[20px]">
                  progress_activity
                </span>
                Giriş yapılıyor...
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[20px]">login</span>
                Giriş Yap
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
}
