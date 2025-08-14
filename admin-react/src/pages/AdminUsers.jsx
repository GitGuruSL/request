import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Grid,
  Card,
  CardContent,
  Box,
  IconButton,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  Alert,
  Switch,
  FormControlLabel,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Snackbar,
  CircularProgress
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Person as PersonIcon,
  LockReset as LockResetIcon
} from '@mui/icons-material';
import { db } from '../firebase/config';
import { 
  collection, 
  addDoc, 
  getDocs, 
  updateDoc, 
  deleteDoc, 
  doc,
  query,
  where,
  orderBy 
} from 'firebase/firestore';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '../firebase/config';
import { createAdminUser } from '../firebase/auth';
import { useAuth } from '../contexts/AuthContext';
import { generateSecurePassword } from '../utils/passwordUtils';
import { sendCredentialsEmail } from '../utils/emailService';

const AdminUsers = () => {
  const { user, adminData, userRole, userCountry } = useAuth();
  
  const [adminUsers, setAdminUsers] = useState([]);
  const [countries, setCountries] = useState([]);
  const [open, setOpen] = useState(false);
  const [editingUser, setEditingUser] = useState(null);
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [generatedCredentials, setGeneratedCredentials] = useState(null);
  const [showCredentials, setShowCredentials] = useState(false);

  const [formData, setFormData] = useState({
    email: '',
    displayName: '',
    country: '', // Will be set based on user role
    role: 'country_admin',
    isActive: true,
    permissions: {
      paymentMethods: true,
      legalDocuments: true,
      businessManagement: true,
      driverManagement: true,
      vehicleManagement: false,
      adminUsersManagement: false // Only super admins should have this by default
    }
  });

  useEffect(() => {
    console.log('Admin Users Component - Auth State:');
    console.log('User:', user);
    console.log('AdminData:', adminData);
    console.log('User Role:', userRole);
    console.log('User Country:', userCountry);
    
    if (user && adminData) {
      fetchAdminUsers();
      fetchCountries();
    }
  }, [user, adminData]);

  const fetchAdminUsers = async () => {
    try {
      console.log('Fetching admin users...');
      console.log('Current user role:', userRole);
      console.log('Current user country:', userCountry);
      
      let q;
      if (userRole === 'super_admin') {
        // Super admin sees all users
        q = query(collection(db, 'admin_users'));
        console.log('Fetching all admin users for super admin');
      } else {
        // Country admin sees their country's users
        q = query(
          collection(db, 'admin_users'), 
          where('country', '==', userCountry || 'LK')
        );
        console.log('Fetching admin users for country:', userCountry || 'LK');
      }
      
      const snapshot = await getDocs(q);
      console.log('Query snapshot size:', snapshot.size);
      
      const users = snapshot.docs.map(doc => {
        const data = doc.data();
        console.log('User document:', doc.id, data);
        return {
          id: doc.id,
          ...data
        };
      });
      
      console.log('Processed users:', users);
      setAdminUsers(users);
      
    } catch (error) {
      console.error('Error fetching admin users:', error);
      setSnackbar({ 
        open: true, 
        message: 'Error fetching admin users: ' + error.message, 
        severity: 'error' 
      });
    }
  };

  const fetchCountries = async () => {
    try {
      console.log('Fetching countries...');
      const snapshot = await getDocs(collection(db, 'app_countries'));
      const countriesList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      // If no countries in Firebase, provide fallback
      if (countriesList.length === 0) {
        console.log('No countries in Firebase, using fallback');
        const fallbackCountries = [
          { id: 'LK', code: 'LK', name: 'Sri Lanka', isEnabled: true },
          { id: 'US', code: 'US', name: 'United States', isEnabled: true },
          { id: 'GB', code: 'GB', name: 'United Kingdom', isEnabled: true },
          { id: 'IN', code: 'IN', name: 'India', isEnabled: true }
        ];
        setCountries(fallbackCountries);
      } else {
        console.log('Fetched countries from Firebase:', countriesList);
        setCountries(countriesList);
      }
      
    } catch (error) {
      console.error('Error fetching countries:', error);
      // Provide fallback countries in case of error
      const fallbackCountries = [
        { id: 'LK', code: 'LK', name: 'Sri Lanka', isEnabled: true },
        { id: 'US', code: 'US', name: 'United States', isEnabled: true }
      ];
      setCountries(fallbackCountries);
      setSnackbar({ open: true, message: 'Using fallback countries due to fetch error', severity: 'warning' });
    }
  };

  const handleSubmit = async () => {
    // Validation
    if (!formData.displayName.trim()) {
      setSnackbar({ open: true, message: 'Please enter a display name', severity: 'error' });
      return;
    }
    if (!formData.email.trim()) {
      setSnackbar({ open: true, message: 'Please enter an email', severity: 'error' });
      return;
    }

    // Permission validation: Country admins cannot create super admins
    if (userRole === 'country_admin' && formData.role === 'super_admin') {
      setSnackbar({ 
        open: true, 
        message: 'Country admins cannot create super admin users', 
        severity: 'error' 
      });
      return;
    }
    
    // Determine country - super admin can choose, others use their assigned country
    const selectedCountry = userRole === 'super_admin' ? formData.country : (userCountry || 'LK');
    
    if (!selectedCountry) {
      setSnackbar({ open: true, message: 'Please select a country', severity: 'error' });
      return;
    }

    console.log('Form data before save:', formData);
    console.log('Selected country:', selectedCountry);
    console.log('User role:', userRole);
    console.log('User country:', userCountry);

    setLoading(true);
    try {
      if (editingUser) {
        // Update existing user
        const userData = {
          displayName: formData.displayName.trim(),
          email: formData.email.trim(),
          country: selectedCountry,
          role: formData.role || 'country_admin',
          isActive: formData.isActive !== undefined ? formData.isActive : true,
          permissions: {
            paymentMethods: formData.permissions?.paymentMethods !== undefined ? formData.permissions.paymentMethods : true,
            legalDocuments: formData.permissions?.legalDocuments !== undefined ? formData.permissions.legalDocuments : true,
            businessManagement: formData.permissions?.businessManagement !== undefined ? formData.permissions.businessManagement : true,
            driverManagement: formData.permissions?.driverManagement !== undefined ? formData.permissions.driverManagement : true,
            vehicleManagement: formData.permissions?.vehicleManagement !== undefined ? formData.permissions.vehicleManagement : false,
            adminUsersManagement: formData.permissions?.adminUsersManagement !== undefined ? formData.permissions.adminUsersManagement : false
          },
          updatedAt: new Date()
        };

        console.log('Updating user:', editingUser.id);
        await updateDoc(doc(db, 'admin_users', editingUser.id), userData);
        console.log('User updated successfully');
        
        setSnackbar({ 
          open: true, 
          message: 'Admin user updated successfully!', 
          severity: 'success' 
        });
      } else {
        // Create new user with generated password
        const generatedPassword = generateSecurePassword();
        console.log('Generated password:', generatedPassword);

        // Check if email already exists in Firestore first
        console.log('🔍 Checking if email already exists in admin_users...');
        const emailQuery = query(
          collection(db, 'admin_users'),
          where('email', '==', formData.email.toLowerCase().trim())
        );
        const emailSnapshot = await getDocs(emailQuery);
        
        if (!emailSnapshot.empty) {
          throw new Error('This email is already registered as an admin user.');
        }

        const adminUserData = {
          displayName: formData.displayName.trim(),
          email: formData.email.toLowerCase().trim(),
          password: generatedPassword,
          country: selectedCountry,
          role: formData.role || 'country_admin',
          isActive: true,
          permissions: {
            paymentMethods: formData.permissions?.paymentMethods !== undefined ? formData.permissions.paymentMethods : true,
            legalDocuments: formData.permissions?.legalDocuments !== undefined ? formData.permissions.legalDocuments : true,
            businessManagement: formData.permissions?.businessManagement !== undefined ? formData.permissions.businessManagement : true,
            driverManagement: formData.permissions?.driverManagement !== undefined ? formData.permissions.driverManagement : true,
            vehicleManagement: formData.permissions?.vehicleManagement !== undefined ? formData.permissions.vehicleManagement : false,
            adminUsersManagement: formData.permissions?.adminUsersManagement !== undefined ? formData.permissions.adminUsersManagement : false
          }
        };

        console.log('Creating new admin user with Firebase Auth...');
        const newUser = await createAdminUser(adminUserData);
        console.log('Admin user created successfully with ID:', newUser.uid);

        // Store credentials to show in dialog
        setGeneratedCredentials({
          email: adminUserData.email,
          password: generatedPassword,
          displayName: adminUserData.displayName,
          role: adminUserData.role,
          country: adminUserData.country
        });

        // Send credentials via email
        try {
          const emailResult = await sendCredentialsEmail(adminUserData, generatedPassword);
          if (emailResult.success) {
            console.log('Credentials email sent successfully');
          } else {
            console.warn('Email sending failed:', emailResult.error);
          }
        } catch (emailError) {
          console.error('Error sending credentials email:', emailError);
        }

        // Show credentials dialog
        setShowCredentials(true);
        
        setSnackbar({ 
          open: true, 
          message: 'Admin user created successfully! Credentials have been generated.', 
          severity: 'success' 
        });
      }

      await fetchAdminUsers();
      if (!showCredentials) {
        handleClose();
      }
    } catch (error) {
      console.error('Error saving admin user:', error);
      
      let errorMessage = 'Failed to save admin user';
      if (error.code === 'auth/email-already-in-use') {
        errorMessage = 'This email is already registered in Firebase Authentication. Please use a different email address.';
      } else if (error.code === 'auth/invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      } else if (error.code === 'auth/weak-password') {
        errorMessage = 'The generated password is too weak. Please try again.';
      } else if (error.message && error.message.includes('already registered')) {
        errorMessage = error.message;
      } else if (error.message) {
        errorMessage = error.message;
      }
      
      setSnackbar({ 
        open: true, 
        message: `❌ ${errorMessage}`, 
        severity: 'error' 
      });
    }
    setLoading(false);
  };

  const handleEdit = (user) => {
    setEditingUser(user);
    setFormData({
      displayName: user.displayName || '',
      email: user.email || '',
      country: user.country || '',
      role: user.role || 'country_admin',
      isActive: user.isActive !== undefined ? user.isActive : true,
      permissions: {
        paymentMethods: user.permissions?.paymentMethods !== undefined ? user.permissions.paymentMethods : true,
        legalDocuments: user.permissions?.legalDocuments !== undefined ? user.permissions.legalDocuments : true,
        businessManagement: user.permissions?.businessManagement !== undefined ? user.permissions.businessManagement : true,
        driverManagement: user.permissions?.driverManagement !== undefined ? user.permissions.driverManagement : true,
        vehicleManagement: user.permissions?.vehicleManagement !== undefined ? user.permissions.vehicleManagement : false,
        adminUsersManagement: user.permissions?.adminUsersManagement !== undefined ? user.permissions.adminUsersManagement : false
      }
    });
    setOpen(true);
  };

  const handleToggleActive = async (user) => {
    try {
      const newActiveStatus = !user.isActive;
      console.log(`Toggling user ${user.id} active status from ${user.isActive} to ${newActiveStatus}`);
      
      await updateDoc(doc(db, 'admin_users', user.id), {
        isActive: newActiveStatus,
        updatedAt: new Date()
      });
      
      await fetchAdminUsers(); // Refresh the list
      setSnackbar({ 
        open: true, 
        message: `User ${newActiveStatus ? 'activated' : 'deactivated'} successfully!`, 
        severity: 'success' 
      });
    } catch (error) {
      console.error('Error toggling user active status:', error);
      setSnackbar({ 
        open: true, 
        message: 'Error updating user status: ' + error.message, 
        severity: 'error' 
      });
    }
  };

  const handleDelete = async (user) => {
    if (window.confirm(`Are you sure you want to delete user ${user.displayName || user.email}? This action cannot be undone.`)) {
      try {
        console.log(`Deleting user ${user.id}`);
        await deleteDoc(doc(db, 'admin_users', user.id));
        
        await fetchAdminUsers(); // Refresh the list
        setSnackbar({ 
          open: true, 
          message: 'User deleted successfully!', 
          severity: 'success' 
        });
      } catch (error) {
        console.error('Error deleting user:', error);
        setSnackbar({ 
          open: true, 
          message: 'Error deleting user: ' + error.message, 
          severity: 'error' 
        });
      }
    }
  };

  const handlePasswordReset = async (user) => {
    if (window.confirm(`Send password reset email to ${user.displayName || user.email}?`)) {
      try {
        console.log(`Sending password reset email to ${user.email}`);
        await sendPasswordResetEmail(auth, user.email);
        
        setSnackbar({ 
          open: true, 
          message: `Password reset email sent to ${user.email}!`, 
          severity: 'success' 
        });
      } catch (error) {
        console.error('Error sending password reset email:', error);
        setSnackbar({ 
          open: true, 
          message: 'Error sending password reset email: ' + error.message, 
          severity: 'error' 
        });
      }
    }
  };

  const handleClose = () => {
    setOpen(false);
    setEditingUser(null);
    setFormData({
      email: '',
      displayName: '',
      country: userRole === 'super_admin' ? '' : (userCountry || 'LK'), // Set default country for non-super admins
      role: 'country_admin',
      isActive: true,
      permissions: {
        paymentMethods: true,
        legalDocuments: true,
        businessManagement: true,
        driverManagement: true,
        vehicleManagement: false,
        adminUsersManagement: false
      }
    });
  };

  const handleInputChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const handlePermissionChange = (permission, value) => {
    setFormData(prev => ({
      ...prev,
      permissions: {
        ...prev.permissions,
        [permission]: value
      }
    }));
  };

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          Admin Users Management
        </Typography>
        <Box>
          <Button
            variant="outlined"
            onClick={fetchAdminUsers}
            sx={{ mr: 1 }}
          >
            Refresh
          </Button>
          {userRole === 'super_admin' && (
            <Button
              variant="outlined"
              startIcon={<LockResetIcon />}
              onClick={() => {
                if (window.confirm('Send password reset emails to all admin users?')) {
                  adminUsers.forEach(admin => {
                    sendPasswordResetEmail(auth, admin.email).catch(console.error);
                  });
                  setSnackbar({
                    open: true,
                    message: `Password reset emails sent to ${adminUsers.length} admin users!`,
                    severity: 'success'
                  });
                }
              }}
              sx={{ mr: 1 }}
            >
              Reset All Passwords
            </Button>
          )}
          {(userRole === 'super_admin' || userRole === 'country_admin') && (
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={() => setOpen(true)}
              color="primary"
            >
              Add New Admin User
            </Button>
          )}
        </Box>
      </Box>

      {userRole !== 'super_admin' && (
        <Alert severity="info" sx={{ mb: 3 }}>
          <strong>Your Admin Role:</strong> {userRole === 'country_admin' ? 'Country Admin' : userRole} for <strong>{userCountry}</strong>
          <br />
          <strong>Permissions:</strong> You can create and manage Country Admin users for your assigned region.
          <br />
          <strong>Note:</strong> Only Super Admins can create other Super Admin users.
        </Alert>
      )}

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Email</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Role</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Permissions</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {adminUsers.map((adminUser) => (
              <TableRow key={adminUser.id}>
                <TableCell>{adminUser.displayName}</TableCell>
                <TableCell>{adminUser.email}</TableCell>
                <TableCell>
                  <Chip label={adminUser.country} size="small" color="primary" />
                </TableCell>
                <TableCell>
                  <Chip 
                    label={adminUser.role === 'super_admin' ? 'Super Admin' : 'Country Admin'} 
                    size="small" 
                    color={adminUser.role === 'super_admin' ? 'secondary' : 'default'}
                  />
                </TableCell>
                <TableCell>
                  <Switch
                    checked={adminUser.isActive}
                    onChange={() => handleToggleActive(adminUser)}
                    color="primary"
                    size="small"
                  />
                  <Chip 
                    label={adminUser.isActive ? 'Active' : 'Inactive'} 
                    size="small" 
                    color={adminUser.isActive ? 'success' : 'error'}
                    sx={{ ml: 1 }}
                  />
                </TableCell>
                <TableCell>
                  <Box display="flex" gap={0.5} flexWrap="wrap">
                    {adminUser.permissions?.paymentMethods && (
                      <Chip label="Payment" size="small" variant="outlined" />
                    )}
                    {adminUser.permissions?.legalDocuments && (
                      <Chip label="Legal" size="small" variant="outlined" />
                    )}
                    {adminUser.permissions?.businessManagement && (
                      <Chip label="Business" size="small" variant="outlined" />
                    )}
                    {adminUser.permissions?.driverManagement && (
                      <Chip label="Driver" size="small" variant="outlined" />
                    )}
                    {adminUser.permissions?.vehicleManagement && (
                      <Chip label="Vehicle" size="small" variant="outlined" />
                    )}
                    {adminUser.permissions?.adminUsersManagement && (
                      <Chip label="Admin Users" size="small" variant="outlined" color="primary" />
                    )}
                  </Box>
                </TableCell>
                <TableCell>
                  <Box display="flex" gap={1}>
                    <IconButton 
                      onClick={() => handleEdit(adminUser)}
                      color="primary"
                      size="small"
                      title="Edit User"
                    >
                      <EditIcon />
                    </IconButton>
                    {userRole === 'super_admin' && (
                      <>
                        <IconButton 
                          onClick={() => handlePasswordReset(adminUser)}
                          color="warning"
                          size="small"
                          title="Send Password Reset Email"
                        >
                          <LockResetIcon />
                        </IconButton>
                        <IconButton 
                          onClick={() => handleDelete(adminUser)} 
                          color="error"
                          size="small"
                          title="Delete User"
                        >
                          <DeleteIcon />
                        </IconButton>
                      </>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Add/Edit Dialog */}
      <Dialog open={open} onClose={handleClose} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingUser ? 'Edit Admin User' : 'Add Admin User'}
          {userRole === 'country_admin' && (
            <Typography variant="caption" display="block" color="textSecondary" sx={{ mt: 0.5 }}>
              As a Country Admin, you can only create Country Admins for your assigned region
            </Typography>
          )}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Display Name"
                value={formData.displayName}
                onChange={(e) => handleInputChange('displayName', e.target.value)}
                required
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Email"
                type="email"
                value={formData.email}
                onChange={(e) => handleInputChange('email', e.target.value)}
                required
              />
            </Grid>

            <Grid item xs={12} sm={6}>
              {userRole === 'super_admin' ? (
                <FormControl fullWidth required>
                  <InputLabel>Country</InputLabel>
                  <Select
                    value={formData.country}
                    label="Country"
                    onChange={(e) => handleInputChange('country', e.target.value)}
                  >
                    {countries.map((country) => (
                      <MenuItem key={country.id} value={country.code}>
                        {country.name} ({country.code})
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              ) : (
                <TextField
                  fullWidth
                  label="Country"
                  value={`${userCountry || 'LK'} (Assigned Country)`}
                  disabled
                  helperText="Country admins are assigned to their specific country"
                />
              )}
            </Grid>

            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Role</InputLabel>
                <Select
                  value={formData.role}
                  label="Role"
                  onChange={(e) => handleInputChange('role', e.target.value)}
                >
                  <MenuItem value="country_admin">Country Admin</MenuItem>
                  {userRole === 'super_admin' && (
                    <MenuItem value="super_admin">Super Admin</MenuItem>
                  )}
                </Select>
              </FormControl>
              {userRole !== 'super_admin' && (
                <Typography variant="caption" color="textSecondary" sx={{ mt: 0.5, display: 'block' }}>
                  Country admins can only create other country admins
                </Typography>
              )}
            </Grid>

            <Grid item xs={12}>
              <Typography variant="subtitle2" gutterBottom>
                Permissions
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.paymentMethods}
                        onChange={(e) => handlePermissionChange('paymentMethods', e.target.checked)}
                      />
                    }
                    label="Payment Methods Management"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.legalDocuments}
                        onChange={(e) => handlePermissionChange('legalDocuments', e.target.checked)}
                      />
                    }
                    label="Legal Documents Management"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.businessManagement}
                        onChange={(e) => handlePermissionChange('businessManagement', e.target.checked)}
                      />
                    }
                    label="Business Management"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.driverManagement}
                        onChange={(e) => handlePermissionChange('driverManagement', e.target.checked)}
                      />
                    }
                    label="Driver Management"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.vehicleManagement}
                        onChange={(e) => handlePermissionChange('vehicleManagement', e.target.checked)}
                      />
                    }
                    label="Vehicle Management"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={formData.permissions?.adminUsersManagement}
                        onChange={(e) => handlePermissionChange('adminUsersManagement', e.target.checked)}
                      />
                    }
                    label="Admin Users Management"
                  />
                </Grid>
              </Grid>
            </Grid>

            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.isActive}
                    onChange={(e) => handleInputChange('isActive', e.target.checked)}
                  />
                }
                label="Active (can access admin panel)"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleClose} disabled={loading}>Cancel</Button>
          <Button 
            onClick={handleSubmit} 
            variant="contained"
            disabled={loading}
          >
            {loading ? (
              <>
                <CircularProgress size={20} sx={{ mr: 1 }} />
                Saving...
              </>
            ) : 'Save'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Credentials Display Dialog */}
      <Dialog 
        open={showCredentials} 
        onClose={() => {
          setShowCredentials(false);
          setGeneratedCredentials(null);
          handleClose();
        }}
        maxWidth="md" 
        fullWidth
      >
        <DialogTitle sx={{ backgroundColor: '#e3f2fd' }}>
          🎉 Admin User Created Successfully!
        </DialogTitle>
        <DialogContent sx={{ mt: 2 }}>
          {generatedCredentials && (
            <>
              <Alert severity="success" sx={{ mb: 3 }}>
                <strong>New admin user has been created!</strong> The login credentials have been generated and sent via email.
              </Alert>

              <Box sx={{ backgroundColor: '#f5f5f5', border: '1px solid #ddd', borderRadius: 2, p: 3, mb: 3 }}>
                <Typography variant="h6" gutterBottom color="primary">
                  🔐 Login Credentials
                </Typography>
                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <Typography variant="body2" color="textSecondary">Name</Typography>
                    <Typography variant="body1" sx={{ fontWeight: 'bold', mb: 1 }}>
                      {generatedCredentials.displayName}
                    </Typography>
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Typography variant="body2" color="textSecondary">Role</Typography>
                    <Typography variant="body1" sx={{ fontWeight: 'bold', mb: 1 }}>
                      {generatedCredentials.role === 'super_admin' ? 'Super Admin' : 'Country Admin'}
                    </Typography>
                  </Grid>
                  <Grid item xs={12}>
                    <Typography variant="body2" color="textSecondary">Email</Typography>
                    <Typography variant="body1" sx={{ fontWeight: 'bold', mb: 1, fontFamily: 'monospace' }}>
                      {generatedCredentials.email}
                    </Typography>
                  </Grid>
                  <Grid item xs={12}>
                    <Typography variant="body2" color="textSecondary">Password</Typography>
                    <Box sx={{ 
                      backgroundColor: '#fff', 
                      border: '1px solid #2196F3', 
                      borderRadius: 1, 
                      p: 2,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between'
                    }}>
                      <Typography variant="h6" sx={{ fontFamily: 'monospace', color: '#2196F3' }}>
                        {generatedCredentials.password}
                      </Typography>
                      <Button 
                        size="small" 
                        variant="outlined"
                        onClick={() => {
                          navigator.clipboard.writeText(generatedCredentials.password);
                          setSnackbar({ 
                            open: true, 
                            message: 'Password copied to clipboard!', 
                            severity: 'success' 
                          });
                        }}
                      >
                        📋 Copy
                      </Button>
                    </Box>
                  </Grid>
                </Grid>
              </Box>

              <Alert severity="warning" sx={{ mb: 2 }}>
                <Typography variant="subtitle2" gutterBottom>
                  🔒 Important Security Notes:
                </Typography>
                <ul style={{ margin: 0, paddingLeft: '20px' }}>
                  <li>These credentials have been sent to the user's email</li>
                  <li>Ask the user to change their password after first login</li>
                  <li>Keep these credentials secure and do not share them</li>
                  <li>The user can access the admin panel at: <code>{window.location.origin}</code></li>
                </ul>
              </Alert>
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => {
              setShowCredentials(false);
              setGeneratedCredentials(null);
              handleClose();
            }}
            variant="contained"
            color="primary"
          >
            Done
          </Button>
        </DialogActions>
      </Dialog>

      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={6000} 
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          severity={snackbar.severity} 
          sx={{ width: '100%' }}
          onClose={() => setSnackbar({ ...snackbar, open: false })}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default AdminUsers;
