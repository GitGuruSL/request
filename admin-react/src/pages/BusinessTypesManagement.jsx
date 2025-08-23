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
import { useAuth } from '../contexts/AuthContext';

const BusinessTypesManagement = () => {
  const { user } = useAuth();
  const [businessTypes, setBusinessTypes] = useState([]);
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedCountry, setSelectedCountry] = useState('LK');
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingType, setEditingType] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    icon: '',
    display_order: 0,
    country_code: 'LK',
    is_active: true
  });

  // Common business type icons
  const iconSuggestions = [
    '🛍️', '🔧', '🏠', '🍽️', '🚚', '🏢', '💼', '🏪', '🎯', '🌟',
    '💻', '📱', '🏥', '🎓', '🚗', '✈️', '🏭', '🎨', '📚', '🎵'
  ];

  useEffect(() => {
    fetchCountries();
    fetchBusinessTypes();
  }, [selectedCountry]);

  const fetchCountries = async () => {
    try {
      const response = await fetch('/api/countries', {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      const data = await response.json();
      if (data.success) {
        setCountries(data.data);
      }
    } catch (error) {
      console.error('Error fetching countries:', error);
    }
  };

  const fetchBusinessTypes = async () => {
    try {
      setLoading(true);
      const response = await fetch(`/api/business-types?country_code=${selectedCountry}`, {
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });
      const data = await response.json();
      if (data.success) {
        setBusinessTypes(data.data);
      } else {
        toast.error(data.message || 'Failed to fetch business types');
      }
    } catch (error) {
      console.error('Error fetching business types:', error);
      toast.error('Failed to fetch business types');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    try {
      const url = editingType 
        ? `/api/business-types/admin/${editingType.id}`
        : '/api/business-types/admin';
      
      const method = editingType ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({
          ...formData,
          country_code: selectedCountry
        })
      });

      const data = await response.json();
      
      if (data.success) {
        toast.success(editingType ? 'Business type updated successfully' : 'Business type created successfully');
        setIsDialogOpen(false);
        setEditingType(null);
        setFormData({
          name: '',
          description: '',
          icon: '',
          display_order: 0,
          country_code: selectedCountry,
          is_active: true
        });
        fetchBusinessTypes();
      } else {
        toast.error(data.message || 'Operation failed');
      }
    } catch (error) {
      console.error('Error saving business type:', error);
      toast.error('Failed to save business type');
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
      const response = await fetch(`/api/business-types/admin/${id}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        }
      });

      const data = await response.json();
      
      if (data.success) {
        toast.success('Business type deleted successfully');
        fetchBusinessTypes();
      } else {
        toast.error(data.message || 'Failed to delete business type');
      }
    } catch (error) {
      console.error('Error deleting business type:', error);
      toast.error('Failed to delete business type');
    }
  };

  const toggleStatus = async (id, currentStatus) => {
    try {
      const response = await fetch(`/api/business-types/admin/${id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${localStorage.getItem('token')}`
        },
        body: JSON.stringify({
          is_active: !currentStatus
        })
      });

      const data = await response.json();
      
      if (data.success) {
        toast.success('Business type status updated successfully');
        fetchBusinessTypes();
      } else {
        toast.error(data.message || 'Failed to update status');
      }
    } catch (error) {
      console.error('Error updating status:', error);
      toast.error('Failed to update status');
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

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Box>
          <Typography variant="h4" component="h1" gutterBottom>
            Business Types Management
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage business types for each country
          </Typography>
        </Box>
        
        <Box sx={{ display: 'flex', gap: 2 }}>
          <FormControl sx={{ minWidth: 200 }}>
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
            Business Types for {countries.find(c => c.code === selectedCountry)?.name || selectedCountry}
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
                      <TableCell>{type.display_order || 0}</TableCell>
                      <TableCell>
                        <Chip 
                          label={type.is_active ? 'Active' : 'Inactive'}
                          color={type.is_active ? 'success' : 'default'}
                          size="small"
                        />
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
                      <TableCell colSpan={6} sx={{ textAlign: 'center', py: 4 }}>
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
    </Container>
  );
};

export default BusinessTypesManagement;
