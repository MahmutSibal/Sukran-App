import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';

import {
  AuthProvider,
  useAuth,
  defaultRouteForRole,
} from '../auth/AuthContext.jsx';
import ProtectedRoute from '../auth/ProtectedRoute.jsx';
import { UserRole } from '../api/config.js';

import Login from '../pages/Login/Login.jsx';
import CustomerTable from '../pages/CustomerTable/CustomerTable.jsx';

import AdminCategories from '../pages/AdminCategories/AdminCategories.jsx';
import AdminLayout from '../pages/AdminLayout/AdminLayout.jsx';
import AdminDashboard from '../pages/AdminDashboard/AdminDashboardDesign.jsx';
import ProductManagement from '../pages/ProductManagement/ProductManagement.jsx';
import AddProduct from '../pages/AddProduct/AddProduct.jsx';
import AdminActiveOrders from '../pages/AdminActiveOrders/AdminActiveOrders.jsx';
import AdminTables from '../pages/AdminTables/AdminTables.jsx';
import AdminPersonels from '../pages/AdminPersonels/AdminPersonels.jsx';
import AdminOrderHistory from '../pages/AdminOrderHistory/AdminOrderHistory.jsx';
import AdminDailyReports from '../pages/AdminDailyReports/AdminDailyReports.jsx';
import AdminTransactions from '../pages/AdminTransactions/AdminTransactions.jsx';
import BusinessProfile from '../pages/BusinessProfile/BusinessProfile.jsx';
import AdminEvents from '../pages/AdminEvents/AdminEvents.jsx';

import KitchenLayout from '../pages/KitchenLayout/KitchenLayout.jsx';
import KitchenPanel from '../pages/KitchenPanel/KitchenPanel.jsx';
import KitchenTables from '../pages/KitchenTables/KitchenTables.jsx';
import KitchenProducts from '../pages/KitchenProducts/KitchenProducts.jsx';
import KitchenOrderHistory from '../pages/KitchenOrderHistory/KitchenOrderHistory.jsx';

import SuperAdminLayout from '../pages/SuperAdminLayout/SuperAdminLayout.jsx';
import SuperAdminRestaurant from '../pages/SuperAdminRestaurant/SuperAdminRestaurant.jsx';
import SuperAdminCreateRestaurant from '../pages/SuperAdminCreateRestaurant/SuperAdminCreateRestaurant.jsx';
import SuperAdminSupport from '../pages/SuperAdminSupport/SuperAdminSupport.jsx';
import SuperAdminRestaurantDetail from '../pages/SuperAdminRestaurantDetail/SuperAdminRestaurantDetail.jsx';
import SuperAdminComplaints from '../pages/SuperAdminComplaints/SuperAdminComplaints.jsx';

// Kök `/`: oturum/role göre doğru panele yönlendirir.
function RootRedirect() {
  const { isAuthenticated, role, loading } = useAuth();
  if (loading) return null;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  return <Navigate to={defaultRouteForRole(role)} replace />;
}

function NotFound() {
  return (
    <div style={{ padding: 40 }}>
      <h1>Sayfa bulunamadı</h1>
      <p>Bu URL için route eşleşmesi yok.</p>
    </div>
  );
}

export default function AppRouter() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          {/* QR ile açılan herkese açık müşteri sayfası (oturum gerektirmez) */}
          <Route
            path="/t/:restaurantId/:tableNo/:qrToken"
            element={<CustomerTable />}
          />
          <Route path="/" element={<RootRedirect />} />

          {/* İşletme sahibi paneli (RestaurantOwner) */}
          <Route element={<ProtectedRoute allowedRoles={[UserRole.RestaurantOwner]} />}>
            <Route path="/admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
              <Route path="categories" element={<AdminCategories />} />
              <Route path="products" element={<ProductManagement />} />
              <Route path="products/add" element={<AddProduct />} />
              <Route path="products/edit/:productId" element={<AddProduct />} />
              <Route path="orders/active" element={<AdminActiveOrders />} />
              <Route path="tables" element={<AdminTables />} />
              <Route path="staff" element={<AdminPersonels />} />
              <Route path="order-history" element={<AdminOrderHistory />} />
              <Route path="daily-reports" element={<AdminDailyReports />} />
              <Route path="transactions" element={<AdminTransactions />} />
              <Route path="business-profile" element={<BusinessProfile />} />
              <Route path="events" element={<AdminEvents />} />
            </Route>

            <Route path="/kitchen" element={<KitchenLayout />}>
              <Route index element={<Navigate to="orders/active" replace />} />
              <Route path="orders/active" element={<KitchenPanel />} />
              <Route path="tables" element={<KitchenTables />} />
              <Route path="products" element={<KitchenProducts />} />
              <Route path="order-history" element={<KitchenOrderHistory />} />
            </Route>
          </Route>

          {/* Platform yöneticisi paneli (SuperAdmin) */}
          <Route element={<ProtectedRoute allowedRoles={[UserRole.SuperAdmin]} />}>
            <Route path="/super-admin" element={<SuperAdminLayout />}>
              <Route index element={<Navigate to="restaurants" replace />} />
              <Route path="restaurants" element={<SuperAdminRestaurant />} />
              <Route path="restaurants/new" element={<SuperAdminCreateRestaurant />} />
              <Route path="restaurants/:restaurantId" element={<SuperAdminRestaurantDetail />} />
              <Route path="support" element={<SuperAdminSupport />} />
              <Route path="complaints" element={<SuperAdminComplaints />} />
            </Route>
          </Route>

          <Route path="*" element={<NotFound />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
