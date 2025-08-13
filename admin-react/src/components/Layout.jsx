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
  Chip
} from '@mui/material';
import {
  Menu as MenuIcon,
  Dashboard,
  ShoppingCart,
  Business,
  DirectionsCar,
  Category,
  BrandingWatermark,
  Tune,
  Person,
  Gavel,
  PrivacyTip,
  Logout,
  Settings,
  Public,
  AdminPanelSettings
} from '@mui/icons-material';
import { useNavigate, useLocation, Outlet } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { signOutAdmin } from '../firebase/auth';

const drawerWidth = 280;

const Layout = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const { adminData, isSuperAdmin } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = async () => {
    try {
      await signOutAdmin();
      navigate('/login');
    } catch (error) {
      console.error('Logout error:', error);
    }
    handleClose();
  };

  const menuItems = [
    { 
      text: 'Dashboard', 
      icon: <Dashboard />, 
      path: '/',
      access: 'all'
    },
    { 
      text: 'Master Products', 
      icon: <ShoppingCart />, 
      path: '/products',
      access: 'all',
      description: 'Centralized product database'
    },
    { 
      text: 'Businesses', 
      icon: <Business />, 
      path: '/businesses',
      access: 'all',
      description: isSuperAdmin ? 'All businesses' : `${adminData?.country} businesses`
    },
    { 
      text: 'Drivers', 
      icon: <DirectionsCar />, 
      path: '/drivers',
      access: 'all',
      description: isSuperAdmin ? 'All drivers' : `${adminData?.country} drivers`
    },
    { 
      text: 'Categories', 
      icon: <Category />, 
      path: '/categories',
      access: 'all',
      description: 'Product categories & subcategories'
    },
    { 
      text: 'Brands', 
      icon: <BrandingWatermark />, 
      path: '/brands',
      access: 'all',
      description: 'Product brands and manufacturers'
    },
    { 
      text: 'Product Variables', 
      icon: <Tune />, 
      path: '/variables',
      access: 'all',
      description: 'Custom product fields and attributes'
    },
    { 
      text: 'Admin Users', 
      icon: <Person />, 
      path: '/admin-users',
      access: 'super_admin',
      description: 'Manage admin accounts'
    },
    { 
      text: 'Legal Documents', 
      icon: <Gavel />, 
      path: '/legal',
      access: 'all',
      description: isSuperAdmin ? 'All countries' : `${adminData?.country} legal docs`
    },
    { 
      text: 'Privacy & Terms', 
      icon: <PrivacyTip />, 
      path: '/privacy-terms',
      access: 'all',
      description: 'Country-specific policies'
    }
  ];

  const drawer = (
    <div>
      <Toolbar>
        <Box display="flex" alignItems="center" gap={2}>
          <AdminPanelSettings color="primary" />
          <Typography variant="h6" noWrap component="div">
            Admin Panel
          </Typography>
        </Box>
      </Toolbar>
      <Divider />
      <List>
        {menuItems
          .filter(item => item.access === 'all' || (item.access === 'super_admin' && isSuperAdmin))
          .map((item) => (
            <ListItem key={item.text} disablePadding>
              <ListItemButton
                selected={location.pathname === item.path}
                onClick={() => navigate(item.path)}
              >
                <ListItemIcon>{item.icon}</ListItemIcon>
                <Box>
                  <ListItemText primary={item.text} />
                  {item.description && (
                    <Typography variant="caption" color="text.secondary" display="block">
                      {item.description}
                    </Typography>
                  )}
                </Box>
              </ListItemButton>
            </ListItem>
          ))}
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
            />
            <IconButton
              size="large"
              aria-label="account of current user"
              aria-controls="menu-appbar"
              aria-haspopup="true"
              onClick={handleMenu}
              color="inherit"
            >
              <Avatar sx={{ width: 32, height: 32 }}>
                {adminData?.name?.charAt(0) || 'A'}
              </Avatar>
            </IconButton>
            <Menu
              id="menu-appbar"
              anchorEl={anchorEl}
              anchorOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              keepMounted
              transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
              open={Boolean(anchorEl)}
              onClose={handleClose}
            >
              <MenuItem onClick={handleClose}>
                <ListItemIcon>
                  <Settings fontSize="small" />
                </ListItemIcon>
                Settings
              </MenuItem>
              <MenuItem onClick={handleLogout}>
                <ListItemIcon>
                  <Logout fontSize="small" />
                </ListItemIcon>
                Logout
              </MenuItem>
            </Menu>
          </Box>
        </Toolbar>
      </AppBar>
      <Box
        component="nav"
        sx={{ width: { sm: drawerWidth }, flexShrink: { sm: 0 } }}
        aria-label="mailbox folders"
      >
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{
            keepMounted: true,
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
    </Box>
  );
};

export default Layout;
