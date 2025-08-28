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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Switch,
  FormControlLabel,
  Snackbar
} from '@mui/material';
import {
  Delete as DeleteIcon,
  Edit as EditIcon,
  Add as AddIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon
} from '@mui/icons-material';
import api from '../services/apiClient';
import { getModulesForBusinessType, getCapabilitiesForBusinessType } from '../constants/businessModules';
import { useAuth } from '../contexts/AuthContext';

const CountryBusinessTypesManagement = () => {
  const [businessTypes, setBusinessTypes] = useState([]);
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user, adminData, userRole, userCountry } = useAuth();
  const isSuperAdmin = userRole === 'super_admin';
  const hasPermission = isSuperAdmin || user?.permissions?.countryBusinessTypeManagement;
  const [selectedCountry, setSelectedCountry] = useState(userCountry || 'LK');
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingType, setEditingType] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    icon: '',
    display_order: 0,
    country_code: userCountry || 'LK',
    is_active: true
  });

  // Common business type icons
  const iconSuggestions = [
    '🛍️', '🔧', '🏠', '🍽️', '🚚', '🏢', '💼', '🏪', '🎯', '🌟',
    '💻', '📱', '🏥', '🎓', '🚗', '✈️', '🏭', '🎨', '📚', '🎵'
  ];

  useEffect(() => {
    if (!hasPermission) return;
    // For super admins, allow selecting any country (load countries list)
    // For country admins, bind to their assigned country and hide selector
    if (isSuperAdmin) {
      fetchCountries();
    } else {
      // Ensure selectedCountry matches logged-in admin's country
      if (userCountry && selectedCountry !== userCountry) {
        setSelectedCountry(userCountry);
      }
    }
    fetchBusinessTypes();
  }, [selectedCountry, isSuperAdmin, userCountry, hasPermission]);

  const fetchCountries = async () => {
    try {
      const { data } = await api.get('/countries');
      if (data?.success) setCountries(data.data || []);
    } catch (error) {
      console.error('Error fetching countries:', error);
    }
  };

  const fetchBusinessTypes = async () => {
    try {
      setLoading(true);
      // Use admin endpoint to get full details; backend restricts country automatically for non-super admins
      const params = isSuperAdmin && selectedCountry ? { country_code: selectedCountry } : undefined;
      const { data } = await api.get(`/business-types/admin`, { params });
      if (data?.success) {
        setBusinessTypes(data.data || []);
      } else {
        setSnackbar({ open: true, message: data?.message || 'Failed to fetch business types', severity: 'error' });
      }
    } catch (error) {
      console.error('Error fetching business types:', error);
      setSnackbar({ open: true, message: 'Failed to fetch business types', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
  const url = editingType 
        ? `/business-types/admin/${editingType.id}`
        : '/business-types/admin';
  const boundCountry = isSuperAdmin ? selectedCountry : (userCountry || selectedCountry);
  const payload = { ...formData, country_code: boundCountry };
      const { data } = editingType
        ? await api.put(url, payload)
        : await api.post(url, payload);
      
      if (data?.success) {
        setSnackbar({ open: true, message: editingType ? 'Business type updated successfully' : 'Business type created successfully', severity: 'success' });
        setIsDialogOpen(false);
        setEditingType(null);
        setFormData({
          name: '',
          description: '',
          icon: '',
          display_order: 0,
          country_code: boundCountry,
          is_active: true
        });
        fetchBusinessTypes();
      } else {
        setSnackbar({ open: true, message: data?.message || 'Operation failed', severity: 'error' });
      }
    } catch (error) {
      console.error('Error saving business type:', error);
      setSnackbar({ open: true, message: 'Failed to save business type', severity: 'error' });
    }
  };

  const handleEdit = (businessType) => {
    setEditingType(businessType);
    setFormData({
      name: businessType.name,
      description: businessType.description || '',
      icon: businessType.icon || '',
      display_order: businessType.display_order || 0,
  country_code: businessType.country_code,
      is_active: businessType.is_active
    });
    setIsDialogOpen(true);
  };

  const handleDelete = async (id) => {
    if (!confirm('Are you sure you want to delete this business type?')) {
      return;
    }

    try {
      const { data } = await api.delete(`/business-types/admin/${id}`);
      
      if (data?.success) {
        setSnackbar({ open: true, message: 'Business type deleted successfully', severity: 'success' });
        fetchBusinessTypes();
      } else {
        setSnackbar({ open: true, message: data?.message || 'Failed to delete business type', severity: 'error' });
      }
    } catch (error) {
      console.error('Error deleting business type:', error);
      setSnackbar({ open: true, message: 'Failed to delete business type', severity: 'error' });
    }
  };

  const toggleStatus = async (id, currentStatus) => {
    try {
      const { data } = await api.put(`/business-types/admin/${id}`, {
        is_active: !currentStatus
      });
      
      if (data?.success) {
        setSnackbar({ open: true, message: 'Business type status updated successfully', severity: 'success' });
        fetchBusinessTypes();
      } else {
        setSnackbar({ open: true, message: data?.message || 'Failed to update status', severity: 'error' });
      }
    } catch (error) {
      console.error('Error updating status:', error);
      setSnackbar({ open: true, message: 'Failed to update status', severity: 'error' });
    }
  };

  const resetForm = () => {
    setEditingType(null);
    setFormData({
      name: '',
      description: '',
      icon: '',
      display_order: 0,
      country_code: selectedCountry,
      is_active: true
    });
  };

  if (!hasPermission) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Typography variant="h4" component="h1" gutterBottom>
          Country Business Types Management
        </Typography>
        <Alert severity="warning">You don't have permission to access this page.</Alert>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            Country Business Types Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage business types for your country
          </Typography>
        </Box>
        
        <Box sx={{ display: 'flex', gap: 2 }}>
          {isSuperAdmin ? (
            <FormControl sx={{ minWidth: 220 }}>
              <InputLabel>Country</InputLabel>
              <Select
                value={selectedCountry}
                label="Country"
                onChange={(e) => setSelectedCountry(e.target.value)}
              >
                {countries.map((country) => (
                  <MenuItem key={country.code} value={country.code}>
                    {country.name} ({country.code})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>
          ) : (
            <Chip
              label={`Country: ${userCountry || selectedCountry}`}
              color="default"
              variant="outlined"
            />
          )}

          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setIsDialogOpen(true)}
          >
            Add Business Type
          </Button>
        </Box>
      </Box>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Business Types for {isSuperAdmin ? (countries.find(c => c.code === selectedCountry)?.name || selectedCountry) : (userCountry || selectedCountry)}
          </Typography>
          
          {loading ? (
            <Box sx={{ textAlign: 'center', py: 4 }}>
              <Typography>Loading...</Typography>
            </Box>
          ) : (
            <TableContainer component={Paper} sx={{ mt: 2 }}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Icon</TableCell>
                    <TableCell>Name</TableCell>
                    <TableCell>Description</TableCell>
                    <TableCell>Order</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Modules</TableCell>
                    <TableCell>Capabilities</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {businessTypes.map((type) => (
                    <TableRow key={type.id}>
                      <TableCell sx={{ fontSize: '2rem' }}>{type.icon || '📋'}</TableCell>
                      <TableCell sx={{ fontWeight: 'medium' }}>{type.name}</TableCell>
                      <TableCell sx={{ maxWidth: 300 }}>
                        <Typography variant="body2" noWrap>
                          {type.description || '-'}
                        </Typography>
                      </TableCell>
                      <TableCell>
                        {(() => {
                          const cap = getCapabilitiesForBusinessType(type.name);
                          const chips = [];
                          if (cap.managePrices) chips.push(<Chip key="cap-prices" label="Manage Prices" size="small" color="secondary" />);
                          if (cap.sendItem) chips.push(<Chip key="cap-item" label="Send Item" size="small" />);
                          if (cap.sendService) chips.push(<Chip key="cap-service" label="Send Service" size="small" />);
                          if (cap.sendRent) chips.push(<Chip key="cap-rent" label="Send Rent" size="small" />);
                          if (cap.sendDelivery) chips.push(<Chip key="cap-delivery" label="Send Delivery" size="small" />);
                          if (cap.respondDelivery) chips.push(<Chip key="cap-respond-delivery" label="Respond Delivery" size="small" color="success" />);
                          if (cap.respondOther) chips.push(<Chip key="cap-respond-other" label="Respond Other" size="small" color="success" />);
                          return (
                            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                              {chips.length ? chips : <Typography variant="caption" color="text.secondary">No capabilities</Typography>}
                            </Box>
                          );
                        })()}
                      </TableCell>
                      <TableCell>{type.display_order || 0}</TableCell>
                      <TableCell>
                        <Chip 
                          label={type.is_active ? 'Active' : 'Inactive'}
                          color={type.is_active ? 'success' : 'default'}
                          size="small"
                        />
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                          {getModulesForBusinessType(type.name).map((m) => (
                            <Chip
                              key={m.id}
                              label={m.name}
                              size="small"
                              sx={{
                                backgroundColor: m.color,
                                color: '#fff',
                              }}
                            />
                          ))}
                          {getModulesForBusinessType(type.name).length === 0 && (
                            <Typography variant="caption" color="text.secondary">No mapped modules</Typography>
                          )}
                        </Box>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', gap: 1 }}>
                          <IconButton
                            size="small"
                            onClick={() => toggleStatus(type.id, type.is_active)}
                            color={type.is_active ? 'warning' : 'success'}
                          >
                            {type.is_active ? <VisibilityOffIcon /> : <VisibilityIcon />}
                          </IconButton>
                          <IconButton
                            size="small"
                            onClick={() => handleEdit(type)}
                            color="primary"
                          >
                            <EditIcon />
                          </IconButton>
                          <IconButton
                            size="small"
                            onClick={() => handleDelete(type.id)}
                            color="error"
                          >
                            <DeleteIcon />
                          </IconButton>
                        </Box>
                      </TableCell>
                    </TableRow>
                  ))}
                  {businessTypes.length === 0 && (
                    <TableRow>
                      <TableCell colSpan={8} sx={{ textAlign: 'center', py: 4 }}>
                        <Typography color="text.secondary">
                          No business types found for this country
                        </Typography>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
          )}
        </CardContent>
      </Card>

      {/* Add/Edit Dialog */}
      <Dialog 
        open={isDialogOpen} 
        onClose={() => {
          setIsDialogOpen(false);
          resetForm();
        }}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          {editingType ? 'Edit Business Type' : 'Add New Business Type'}
        </DialogTitle>
        <form onSubmit={handleSubmit}>
          <DialogContent>
            <Grid container spacing={2}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Name"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="e.g., Product Seller"
                  required
                />
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  placeholder="Brief description of this business type"
                  multiline
                  rows={3}
                />
              </Grid>

              <Grid item xs={8}>
                <TextField
                  fullWidth
                  label="Icon"
                  value={formData.icon}
                  onChange={(e) => setFormData({ ...formData, icon: e.target.value })}
                  placeholder="Choose an emoji"
                />
              </Grid>
              <Grid item xs={4}>
                <Box 
                  sx={{ 
                    fontSize: '2rem', 
                    textAlign: 'center', 
                    p: 2, 
                    border: 1, 
                    borderColor: 'grey.300', 
                    borderRadius: 1,
                    minHeight: 56,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}
                >
                  {formData.icon || '📋'}
                </Box>
              </Grid>

              <Grid item xs={12}>
                <Box sx={{ mb: 2 }}>
                  <Typography variant="body2" color="text.secondary" gutterBottom>
                    Suggested icons:
                  </Typography>
                  <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                    {iconSuggestions.map((icon) => (
                      <Button
                        key={icon}
                        onClick={() => setFormData({ ...formData, icon })}
                        sx={{ 
                          minWidth: 'auto', 
                          p: 1, 
                          fontSize: '1.2rem',
                          border: formData.icon === icon ? 2 : 1,
                          borderColor: formData.icon === icon ? 'primary.main' : 'grey.300'
                        }}
                      >
                        {icon}
                      </Button>
                    ))}
                  </Box>
                </Box>
              </Grid>

              <Grid item xs={12}>
                <TextField
                  fullWidth
                  type="number"
                  label="Display Order"
                  value={formData.display_order}
                  onChange={(e) => setFormData({ ...formData, display_order: parseInt(e.target.value) })}
                  inputProps={{ min: 0 }}
                />
              </Grid>

              {/* Preview mapped modules for the entered name */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" gutterBottom>Mapped Modules</Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                  {getModulesForBusinessType(formData.name).map((m) => (
                    <Chip
                      key={m.id}
                      label={m.name}
                      size="small"
                      sx={{ backgroundColor: m.color, color: '#fff' }}
                    />
                  ))}
                  {getModulesForBusinessType(formData.name).length === 0 && (
                    <Typography variant="caption" color="text.secondary">No mapped modules</Typography>
                  )}
                </Box>
              </Grid>

              {/* Capabilities preview */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" gutterBottom>Capabilities</Typography>
                {(() => {
                  const cap = getCapabilitiesForBusinessType(formData.name);
                  const chips = [];
                  if (cap.managePrices) chips.push(<Chip key="cap-prices" label="Manage Prices" size="small" color="secondary" />);
                  if (cap.sendItem) chips.push(<Chip key="cap-item" label="Send Item" size="small" />);
                  if (cap.sendService) chips.push(<Chip key="cap-service" label="Send Service" size="small" />);
                  if (cap.sendRent) chips.push(<Chip key="cap-rent" label="Send Rent" size="small" />);
                  if (cap.sendDelivery) chips.push(<Chip key="cap-delivery" label="Send Delivery" size="small" />);
                  if (cap.respondDelivery) chips.push(<Chip key="cap-respond-delivery" label="Respond Delivery" size="small" color="success" />);
                  if (cap.respondOther) chips.push(<Chip key="cap-respond-other" label="Respond Other" size="small" color="success" />);
                  return (
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                      {chips.length ? chips : <Typography variant="caption" color="text.secondary">No capabilities</Typography>}
                    </Box>
                  );
                })()}
              </Grid>
            </Grid>
          </DialogContent>
          <DialogActions>
            <Button onClick={() => setIsDialogOpen(false)}>
              Cancel
            </Button>
            <Button type="submit" variant="contained">
              {editingType ? 'Update' : 'Create'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
          variant="filled"
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default CountryBusinessTypesManagement;
