import React, { useState } from 'react';
import {
  AppBar,
  Box,
  CssBaseline,
  Drawer,
  IconButton,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Toolbar,
  Typography,
  Menu,
  MenuItem,
  Avatar,
  Divider,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Button,
  Alert
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard,
  ShoppingCart,
  Business,
  DirectionsCar,
  TwoWheeler,
  Category,
  BrandingWatermark,
  Tune,
  Person,
  Gavel,
  PrivacyTip,
  Logout,
  Settings,
  Public,
  LocationCity,
  Payment,
  AdminPanelSettings,
  Assignment,
  Reply,
  PriceCheck,
  Lock
} from '@mui/icons-material';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { signOutAdmin, updateUserPassword } from '../firebase/auth';

const drawerWidth = 280;

const Layout = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const [passwordDialogOpen, setPasswordDialogOpen] = useState(false);
  const [passwordData, setPasswordData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [passwordLoading, setPasswordLoading] = useState(false);
  const [passwordError, setPasswordError] = useState('');

  const { user, adminData, isSuperAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleMenuOpen = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    try {
      await signOutAdmin();
      navigate('/login');
    } catch (error) {
      console.error('Logout error:', error);
    }
    handleMenuClose();
  };

  const handlePasswordChange = async () => {
    setPasswordError('');
    
    if (!passwordData.currentPassword || !passwordData.newPassword) {
      setPasswordError('Please fill in all fields');
      return;
    }

    if (passwordData.newPassword !== passwordData.confirmPassword) {
      setPasswordError('New passwords do not match');
      return;
    }

    if (passwordData.newPassword.length < 6) {
      setPasswordError('New password must be at least 6 characters long');
      return;
    }

    setPasswordLoading(true);
    try {
      await updateUserPassword(passwordData.currentPassword, passwordData.newPassword);
      setPasswordDialogOpen(false);
      setPasswordData({ currentPassword: '', newPassword: '', confirmPassword: '' });
      // Show success message or notification here
    } catch (error) {
      setPasswordError(error.message || 'Failed to update password');
    } finally {
      setPasswordLoading(false);
    }
  };

  const menuItems = [
    { text: 'Dashboard', icon: <Dashboard />, path: '/', access: 'all' },
    { text: 'Requests', icon: <Assignment />, path: '/requests', access: 'all' },
    { text: 'Responses', icon: <Reply />, path: '/responses', access: 'all' },
    { text: 'Price Listings', icon: <PriceCheck />, path: '/price-listings', access: 'all' },
    { text: 'Divider' },
    { text: 'Products', icon: <ShoppingCart />, path: '/products', access: 'all', permission: 'productManagement' },
    { text: 'Businesses', icon: <Business />, path: '/businesses', access: 'all', permission: 'businessManagement' },
    { text: 'Drivers', icon: <Gavel />, path: '/driver-verification', access: 'all', permission: 'driverVerification' },
    { text: 'Divider' },
    { text: 'Vehicles', icon: <DirectionsCar />, path: '/vehicles', access: 'super_admin', permission: 'vehicleManagement' },
    { text: 'Divider' },
    { text: 'Categories', icon: <Category />, path: '/categories', access: 'super_admin' },
    { text: 'Subcategories', icon: <Category />, path: '/subcategories', access: 'super_admin' },
    { text: 'Brands', icon: <BrandingWatermark />, path: '/brands', access: 'super_admin' },
    { text: 'Variable Types', icon: <Tune />, path: '/variable-types', access: 'super_admin' },
    { text: 'Divider' },
    { text: 'Users', icon: <Person />, path: '/users', access: 'all', permission: 'userManagement' },
    { text: 'Privacy Policy', icon: <PrivacyTip />, path: '/privacy-policy', access: 'super_admin' },
    { text: 'Divider' },
    { text: 'Country Data', icon: <Public />, path: '/country-data', access: 'super_admin' },
    { text: 'City Management', icon: <LocationCity />, path: '/cities', access: 'super_admin' },
    { text: 'Module Management', icon: <Settings />, path: '/modules', access: 'all', permission: 'moduleManagement' },
    { text: 'Payment Methods', icon: <Payment />, path: '/payment-methods', access: 'super_admin' },
    { text: 'Divider' },
    { text: 'Admin Management', icon: <AdminPanelSettings />, path: '/admin-management', access: 'super_admin' },
  ];

  const drawer = (
    <div>
      <Toolbar />
      <Divider />
      <List>
        {menuItems.filter(item => {
          if (item.text === 'Divider') return true;
          
          // Check access level
          if (item.access === 'all') return true;
          if (item.access === 'super_admin' && isSuperAdmin) return true;
          
          // Check specific permissions for non-super admins
          if (item.permission && !isSuperAdmin) {
            // Special case for vehicle management - only super admins
            if (isSuperAdmin && item.permission === 'vehicleManagement') return true;
            return adminData?.permissions?.[item.permission] === true;
          }
          
          return false;
        }).map((item, index) => 
          item.text === 'Divider' ? (
            <Divider key={index} sx={{ my: 1 }} />
          ) : (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                selected={location.pathname === item.path}
                onClick={() => navigate(item.path)}
                sx={{
                  '&.Mui-selected': {
                    backgroundColor: 'primary.main',
                    color: 'white',
                    '&:hover': {
                      backgroundColor: 'primary.dark',
                    },
                    '& .MuiListItemIcon-root': {
                      color: 'white',
                    },
                  },
                }}
              >
                <ListItemIcon>
                  {item.icon}
                </ListItemIcon>
                <ListItemText primary={item.text} />
              </ListItemButton>
            </ListItem>
          )
        )}
      </List>
    </div>
  );

  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline />
      <AppBar
        position="fixed"
        sx={{
          width: { sm: `calc(100% - ${drawerWidth}px)` },
          ml: { sm: `${drawerWidth}px` },
        }}
      >
        <Toolbar>
          <IconButton
            color="inherit"
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { sm: 'none' } }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" noWrap component="div" sx={{ flexGrow: 1 }}>
            Request Marketplace Admin
          </Typography>
          
          <Box display="flex" alignItems="center" gap={2}>
            {adminData?.country && (
              <Chip 
                icon={<Public />} 
                label={adminData.country} 
                variant="outlined" 
                size="small"
                sx={{ color: 'white', borderColor: 'rgba(255,255,255,0.5)' }}
              />
            )}
            <Chip 
              label={isSuperAdmin ? 'Super Admin' : 'Country Admin'}
              color={isSuperAdmin ? 'error' : 'success'}
              size="small"
              variant="outlined"
              sx={{ color: 'white', borderColor: 'rgba(255,255,255,0.5)' }}
            />
            <IconButton
              size="large"
              edge="end"
              aria-label="account of current user"
              aria-haspopup="true"
              onClick={handleMenuOpen}
              color="inherit"
            >
              <Avatar sx={{ width: 32, height: 32 }}>
                {user?.email?.charAt(0).toUpperCase()}
              </Avatar>
            </IconButton>
          </Box>
        </Toolbar>
      </AppBar>

      {/* User Menu */}
      <Menu
        anchorEl={anchorEl}
        anchorOrigin={{
          vertical: 'bottom',
          horizontal: 'right',
        }}
        keepMounted
        transformOrigin={{
          vertical: 'top',
          horizontal: 'right',
        }}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItem onClick={() => { setPasswordDialogOpen(true); handleMenuClose(); }}>
          <ListItemIcon>
            <Lock fontSize="small" />
          </ListItemIcon>
          Change Password
        </MenuItem>
        <MenuItem onClick={handleLogout}>
          <ListItemIcon>
            <Logout fontSize="small" />
          </ListItemIcon>
          Logout
        </MenuItem>
      </Menu>

      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true, // Better mobile performance
          }}
          sx={{
            display: { xs: 'block', sm: 'none' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', sm: 'block' },
            '& .MuiDrawer-paper': { boxSizing: 'border-box', width: drawerWidth },
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{ flexGrow: 1, p: 3, width: { sm: `calc(100% - ${drawerWidth}px)` } }}
      >
        <Toolbar />
        <Outlet />
      </Box>

      {/* Password Change Dialog */}
      <Dialog
        open={passwordDialogOpen}
        onClose={() => setPasswordDialogOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Change Password</DialogTitle>
        <DialogContent>
          {passwordError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {passwordError}
            </Alert>
          )}
          <TextField
            margin="normal"
            required
            fullWidth
            type="password"
            label="Current Password"
            value={passwordData.currentPassword}
            onChange={(e) => setPasswordData({ ...passwordData, currentPassword: e.target.value })}
          />
          <TextField
            margin="normal"
            required
            fullWidth
            type="password"
            label="New Password"
            value={passwordData.newPassword}
            onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })}
          />
          <TextField
            margin="normal"
            required
            fullWidth
            type="password"
            label="Confirm New Password"
            value={passwordData.confirmPassword}
            onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })}
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPasswordDialogOpen(false)}>Cancel</Button>
          <Button
            onClick={handlePasswordChange}
            disabled={passwordLoading}
            variant="contained"
          >
            {passwordLoading ? 'Changing...' : 'Change Password'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Layout;
