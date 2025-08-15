import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  Chip,
  LinearProgress
} from '@mui/material';
import {
  ShoppingCart,
  Business,
  DirectionsCar,
  Person,
  TrendingUp,
  Public
} from '@mui/icons-material';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '../firebase/config';
import { useAuth } from '../contexts/AuthContext';
import { getCountryFilteredQuery, ROLES } from '../firebase/auth';

const Dashboard = () => {
  const { adminData, isSuperAdmin } = useAuth();
  const [stats, setStats] = useState({
    products: 0,
    businesses: 0,
    drivers: 0,
    adminUsers: 0,
    loading: true
  });

  useEffect(() => {
    loadDashboardStats();
  }, [adminData]);

  const loadDashboardStats = async () => {
    try {
      setStats(prev => ({ ...prev, loading: true }));

      // Load products (centralized - all admins see all products)
      const productsSnapshot = await getDocs(collection(db, 'master_products'));
      const productsCount = productsSnapshot.size;

      // Load businesses (country-filtered for country admin)
      let businessesQuery = collection(db, 'new_business_verifications');
      if (!isSuperAdmin && adminData?.country) {
        businessesQuery = query(businessesQuery, where('country', '==', adminData.country));
      }
      const businessesSnapshot = await getDocs(businessesQuery);
      const businessesCount = businessesSnapshot.size;

      // Load drivers (country-filtered for country admin)
      let driversQuery = collection(db, 'driver_verification');
      if (!isSuperAdmin && adminData?.country) {
        driversQuery = query(driversQuery, where('country', '==', adminData.country));
      }
      const driversSnapshot = await getDocs(driversQuery);
      const driversCount = driversSnapshot.size;

      // Load admin users (only super admin can see this)
      let adminUsersCount = 0;
      if (isSuperAdmin) {
        const adminUsersSnapshot = await getDocs(collection(db, 'admin_users'));
        adminUsersCount = adminUsersSnapshot.size;
      }

      setStats({
        products: productsCount,
        businesses: businessesCount,
        drivers: driversCount,
        adminUsers: adminUsersCount,
        loading: false
      });
    } catch (error) {
      console.error('Error loading dashboard stats:', error);
      setStats(prev => ({ ...prev, loading: false }));
    }
  };

  const statCards = [
    {
      title: 'Master Products',
      value: stats.products,
      icon: <ShoppingCart />,
      color: '#1976d2',
      description: 'Centralized product database'
    },
    {
      title: isSuperAdmin ? 'All Businesses' : `${adminData?.country} Businesses`,
      value: stats.businesses,
      icon: <Business />,
      color: '#388e3c',
      description: isSuperAdmin ? 'Global businesses' : 'Country-specific businesses'
    },
    {
      title: isSuperAdmin ? 'All Drivers' : `${adminData?.country} Drivers`,
      value: stats.drivers,
      icon: <DirectionsCar />,
      color: '#f57c00',
      description: isSuperAdmin ? 'Global drivers' : 'Country-specific drivers'
    }
  ];

  if (isSuperAdmin) {
    statCards.push({
      title: 'Admin Users',
      value: stats.adminUsers,
      icon: <Person />,
      color: '#d32f2f',
      description: 'System administrators'
    });
  }

  return (
    <Box>
      <Box mb={3}>
        <Typography variant="h4" gutterBottom>
          Dashboard
        </Typography>
        <Box display="flex" gap={1} alignItems="center">
          <Chip 
            icon={<Public />} 
            label={isSuperAdmin ? 'Global Access' : `${adminData?.country} Access`}
            color={isSuperAdmin ? 'error' : 'primary'}
            variant="outlined"
          />
          <Chip 
            label={adminData?.role === ROLES.SUPER_ADMIN ? 'Super Admin' : 'Country Admin'}
            color="primary"
          />
        </Box>
      </Box>

      {stats.loading && <LinearProgress sx={{ mb: 2 }} />}

      <Grid container spacing={3}>
        {statCards.map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card 
              sx={{ 
                height: '100%',
                background: `linear-gradient(45deg, ${stat.color}, ${stat.color}aa)`,
                color: 'white'
              }}
            >
              <CardContent>
                <Box display="flex" alignItems="center" justifyContent="space-between">
                  <Box>
                    <Typography variant="h4" component="div" gutterBottom>
                      {stat.value.toLocaleString()}
                    </Typography>
                    <Typography variant="h6" component="div">
                      {stat.title}
                    </Typography>
                    <Typography variant="body2" sx={{ opacity: 0.8, mt: 1 }}>
                      {stat.description}
                    </Typography>
                  </Box>
                  <Box sx={{ opacity: 0.3, fontSize: 60 }}>
                    {stat.icon}
                  </Box>
                </Box>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      <Grid container spacing={3} sx={{ mt: 2 }}>
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                System Overview
              </Typography>
              <Typography variant="body2" color="text.secondary" paragraph>
                Welcome to the Request Marketplace Admin Panel. This system provides:
              </Typography>
              <Box component="ul" sx={{ pl: 2 }}>
                <Typography component="li" variant="body2" gutterBottom>
                  <strong>Centralized Product Database:</strong> All products are managed globally
                </Typography>
                <Typography component="li" variant="body2" gutterBottom>
                  <strong>Country-Specific Data:</strong> Businesses, drivers, and legal documents are filtered by country
                </Typography>
                <Typography component="li" variant="body2" gutterBottom>
                  <strong>Role-Based Access:</strong> Super admins see all data, country admins see their region
                </Typography>
                <Typography component="li" variant="body2" gutterBottom>
                  <strong>Legal Compliance:</strong> Privacy policies and terms can be customized per country
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Your Access Level
              </Typography>
              <Box display="flex" flexDirection="column" gap={2}>
                <Box>
                  <Typography variant="subtitle2">Role</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {adminData?.role === ROLES.SUPER_ADMIN ? 'Super Administrator' : 'Country Administrator'}
                  </Typography>
                </Box>
                {adminData?.country && (
                  <Box>
                    <Typography variant="subtitle2">Country</Typography>
                    <Typography variant="body2" color="text.secondary">
                      {adminData.country}
                    </Typography>
                  </Box>
                )}
                <Box>
                  <Typography variant="subtitle2">Data Access</Typography>
                  <Typography variant="body2" color="text.secondary">
                    {isSuperAdmin ? 
                      'Global access to all countries and system settings' : 
                      `Limited to ${adminData?.country} businesses, drivers, and legal documents`
                    }
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
