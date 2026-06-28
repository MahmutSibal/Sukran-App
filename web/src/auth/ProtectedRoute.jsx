import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuth, defaultRouteForRole } from './AuthContext';

// Oturum + rol kontrolü yapan koruyucu route.
// allowedRoles verilmezse sadece girişi kontrol eder.
export default function ProtectedRoute({ allowedRoles }) {
  const { isAuthenticated, role, loading } = useAuth();
  const location = useLocation();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background text-on-surface-variant">
        <div className="flex items-center gap-3">
          <span className="material-symbols-outlined animate-spin">progress_activity</span>
          Yükleniyor...
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />;
  }

  // Sıkı rol izolasyonu (çok kiracılı sistem): her rol YALNIZCA kendi görev
  // alanına girebilir. SuperAdmin'in genel erişim bypass'ı bilerek kaldırıldı;
  // SuperAdmin sadece /super-admin, RestaurantOwner sadece /admin ve /kitchen.
  // İzinsiz bir alana gelen kullanıcı kendi varsayılan paneline yönlendirilir.
  if (allowedRoles && !allowedRoles.includes(role)) {
    return <Navigate to={defaultRouteForRole(role)} replace />;
  }

  return <Outlet />;
}
