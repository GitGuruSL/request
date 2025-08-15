import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline } from '@mui/material';
import { AuthProvider } from './contexts/AuthContext';
import { CountryFilterProvider } from './hooks/useCountryFilter.jsx';
import ProtectedRoute from './components/ProtectedRoute';
import Layout from './components/Layout';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Categories from './pages/Categories';
import Brands from './pages/Brands';
import Variables from './pages/Variables';
import Countries from './pages/Countries';
import Cities from './pages/Cities';
import PrivacyTerms from './pages/PrivacyTerms';
import PaymentMethods from './pages/PaymentMethods';
import AdminUsers from './pages/AdminUsers';
import ModuleManagement from './pages/ModuleManagement';
import BusinessVerificationEnhanced from './pages/BusinessVerificationEnhanced';
import DriverVerificationEnhanced from './pages/DriverVerificationEnhanced';
import Vehicles from './pages/Vehicles';
import RequestsModule from './pages/RequestsModule';
import ResponsesModule from './pages/ResponsesModule';
import PriceListingsModule from './pages/PriceListingsModule';
import CategoriesModule from './pages/CategoriesModule';
import DriverVerificationModule from './pages/DriverVerificationModule';
import VehiclesModule from './pages/VehiclesModule';
import VariablesModule from './pages/VariablesModule';
import SubcategoriesModule from './pages/SubcategoriesModule';
import DebugAuth from './components/DebugAuth';

const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <AuthProvider>
        <CountryFilterProvider>
          <Router>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route
                path="/*"
                element={
                  <ProtectedRoute>
                    <Layout />
                  </ProtectedRoute>
                }
            >
              <Route index element={<Dashboard />} />
              <Route path="debug" element={<DebugAuth />} />
              <Route path="modules" element={<ModuleManagement />} />
              <Route path="products" element={<Products />} />
              <Route path="categories" element={<CategoriesModule />} />
              <Route path="brands" element={<Brands />} />
              <Route path="variables" element={<Variables />} />
              <Route path="variable-types" element={<VariablesModule />} />
              <Route path="subcategories" element={<SubcategoriesModule />} />
              <Route path="countries" element={<Countries />} />
              <Route path="country-data" element={<Countries />} />
              <Route path="cities" element={<Cities />} />
              <Route path="payment-methods" element={<PaymentMethods />} />
              <Route path="admin-users" element={<AdminUsers />} />
              <Route path="admin-management" element={<AdminUsers />} />
              <Route path="users" element={<AdminUsers />} />
              <Route path="businesses" element={<BusinessVerificationEnhanced />} />
              <Route path="business-management" element={<BusinessVerificationEnhanced />} />
              <Route path="drivers" element={<DriverVerificationEnhanced />} />
              <Route path="vehicles" element={<VehiclesModule />} />
              <Route path="cars" element={<VehiclesModule />} />
              <Route path="bikes" element={<VehiclesModule />} />
              <Route path="driver-verification" element={<DriverVerificationEnhanced />} />
              <Route path="requests" element={<RequestsModule />} />
              <Route path="responses" element={<ResponsesModule />} />
              <Route path="price-listings" element={<PriceListingsModule />} />
              <Route path="privacy-terms" element={<PrivacyTerms />} />
              {/* Add more protected routes here */}
            </Route>
          </Routes>
        </Router>
        </CountryFilterProvider>
      </AuthProvider>
    </ThemeProvider>
  );
}

export default App;
