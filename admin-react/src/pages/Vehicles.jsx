import React, { useState, useEffect } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Chip,
  IconButton,
  Grid,
  Card,
  CardContent,
  Avatar,
  Switch,
  FormControlLabel,
  Alert,
  Snackbar
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  DirectionsCar,
  TwoWheeler,
  LocalTaxi,
  AirportShuttle,
  People
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter';
import { 
  collection, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  getDocs, 
  query, 
  orderBy,
  where,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from '../firebase/config';

const Vehicles = () => {
  const { getFilteredData, adminData, isSuperAdmin, userCountry } = useCountryFilter();
  const [vehicles, setVehicles] = useState([]);
  const [countryVehicles, setCountryVehicles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editingVehicle, setEditingVehicle] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

  // Check permissions
  const hasVehiclePermission = isSuperAdmin || adminData?.permissions?.vehicleManagement;

  if (!hasVehiclePermission) {
    return (
      <Box sx={{ p: 3 }}>
        <Alert severity="error">
          You don't have permission to access Vehicle Management. Please contact your administrator.
        </Alert>
      </Box>
    );
  }

    // Form state
  const [formData, setFormData] = useState({
    name: '',
    icon: 'DirectionsCar',
    isActive: true,
    displayOrder: 1,
    passengerCapacity: 1,
    description: ''
  });

  const vehicleIcons = {
    'TwoWheeler': <TwoWheeler />,
    'DirectionsCar': <DirectionsCar />,
    'LocalTaxi': <LocalTaxi />,
    'AirportShuttle': <AirportShuttle />,
    'People': <People />
  };

  useEffect(() => {
    fetchVehicles();
    if (!isSuperAdmin && adminData?.country) {
      fetchCountryVehicles();
    }
  }, [isSuperAdmin, adminData]);

  const fetchVehicles = async () => {
    try {
      const data = await getFilteredData('vehicle_types', adminData);
      const vehiclesData = (data || []).sort((a, b) => 
        (a.displayOrder || 0) - (b.displayOrder || 0)
      );
      setVehicles(vehiclesData);
    } catch (error) {
      console.error('Error fetching vehicles:', error);
      showSnackbar('Error fetching vehicles', 'error');
    } finally {
      setLoading(false);
    }
  };

  const fetchCountryVehicles = async () => {
    try {
      if (!adminData?.country) {
        console.log('No country data available');
        return;
      }

      console.log('Fetching country vehicles for:', adminData.country);
      
      const countryQuery = query(
        collection(db, 'country_vehicles'),
        where('countryCode', '==', adminData.country)
      );
      const snapshot = await getDocs(countryQuery);
      
      if (!snapshot.empty) {
        const data = snapshot.docs[0].data();
        console.log('Found country vehicles:', data);
        setCountryVehicles(data.enabledVehicles || []);
      } else {
        console.log('No country vehicles found, starting with empty list');
        setCountryVehicles([]);
      }
    } catch (error) {
      console.error('Error fetching country vehicles:', error);
      setCountryVehicles([]);
    }
  };

  const handleSubmit = async () => {
    try {
      const vehicleData = {
        ...formData,
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email
      };

      if (editingVehicle) {
        await updateDoc(doc(db, 'vehicle_types', editingVehicle.id), vehicleData);
        showSnackbar('Vehicle type updated successfully');
      } else {
        await addDoc(collection(db, 'vehicle_types'), {
          ...vehicleData,
          createdAt: serverTimestamp(),
          createdBy: adminData.email
        });
        showSnackbar('Vehicle type added successfully');
      }

      handleCloseDialog();
      fetchVehicles();
    } catch (error) {
      console.error('Error saving vehicle:', error);
      showSnackbar('Error saving vehicle type', 'error');
    }
  };

  const handleEdit = (vehicle) => {
    setEditingVehicle(vehicle);
    setFormData({
      name: vehicle.name || '',
      icon: vehicle.icon || 'DirectionsCar',
      isActive: vehicle.isActive !== false,
      displayOrder: vehicle.displayOrder || 1,
      passengerCapacity: vehicle.passengerCapacity || 1,
      description: vehicle.description || ''
    });
    setOpenDialog(true);
  };

  const handleDelete = async (vehicleId) => {
    if (!window.confirm('Are you sure you want to delete this vehicle type?')) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'vehicle_types', vehicleId));
      showSnackbar('Vehicle type deleted successfully');
      fetchVehicles();
    } catch (error) {
      console.error('Error deleting vehicle:', error);
      showSnackbar('Error deleting vehicle type', 'error');
    }
  };

  const handleToggleCountryVehicle = async (vehicleId, enabled) => {
    try {
      // Validate adminData
      if (!adminData?.country) {
        throw new Error('Country information not available');
      }

      const updatedVehicles = enabled
        ? [...countryVehicles, vehicleId]
        : countryVehicles.filter(id => id !== vehicleId);

      console.log('Updating country vehicles:', {
        country: adminData.country,
        vehicleId,
        enabled,
        updatedVehicles
      });

      const countryQuery = query(
        collection(db, 'country_vehicles'),
        where('countryCode', '==', adminData.country)
      );
      const snapshot = await getDocs(countryQuery);

      const countryData = {
        countryCode: adminData.country,
        countryName: adminData.countryName || adminData.country,
        enabledVehicles: updatedVehicles,
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email || 'unknown'
      };

      if (snapshot.empty) {
        console.log('Creating new country vehicles document');
        await addDoc(collection(db, 'country_vehicles'), {
          ...countryData,
          createdAt: serverTimestamp(),
          createdBy: adminData.email || 'unknown'
        });
      } else {
        console.log('Updating existing country vehicles document');
        await updateDoc(doc(db, 'country_vehicles', snapshot.docs[0].id), countryData);
      }

      setCountryVehicles(updatedVehicles);
      showSnackbar(`Vehicle ${enabled ? 'enabled' : 'disabled'} for ${adminData.country}`);
    } catch (error) {
      console.error('Error updating country vehicles:', error);
      console.error('AdminData:', adminData);
      showSnackbar(`Error updating country vehicles: ${error.message}`, 'error');
    }
  };

  const handleOpenDialog = () => {
    setEditingVehicle(null);
    setFormData({
      name: '',
      icon: 'DirectionsCar',
      isActive: true,
      displayOrder: vehicles.length + 1,
      passengerCapacity: 1,
      description: ''
    });
    setOpenDialog(true);
  };

  const addDefaultVehicleTypes = async () => {
    const defaultVehicles = [
      { 
        name: 'Bike', 
        icon: 'TwoWheeler', 
        displayOrder: 1, 
        passengerCapacity: 1, 
        description: 'Motorcycle or scooter for single passenger' 
      },
      { 
        name: 'Three Wheeler', 
        icon: 'LocalTaxi', 
        displayOrder: 2, 
        passengerCapacity: 3, 
        description: 'Tuk-tuk or auto-rickshaw for up to 3 passengers' 
      },
      { 
        name: 'Car', 
        icon: 'DirectionsCar', 
        displayOrder: 3, 
        passengerCapacity: 4, 
        description: 'Standard car for up to 4 passengers' 
      },
      { 
        name: 'Van', 
        icon: 'AirportShuttle', 
        displayOrder: 4, 
        passengerCapacity: 8, 
        description: 'Van or minibus for up to 8 passengers' 
      },
      { 
        name: 'Shared Ride', 
        icon: 'People', 
        displayOrder: 5, 
        passengerCapacity: 4, 
        description: 'Shared car ride with other passengers' 
      }
    ];

    // Check which default vehicles are missing
    const existingNames = vehicles.map(v => v.name.toLowerCase());
    const missingVehicles = defaultVehicles.filter(v => 
      !existingNames.includes(v.name.toLowerCase())
    );

    if (missingVehicles.length === 0) {
      showSnackbar('All default vehicle types already exist', 'info');
      return;
    }

    const message = `This will add ${missingVehicles.length} missing default vehicle types: ${missingVehicles.map(v => v.name).join(', ')}. Continue?`;
    if (!window.confirm(message)) {
      return;
    }

    setLoading(true);
    try {
      for (const vehicle of missingVehicles) {
        await addDoc(collection(db, 'vehicle_types'), {
          ...vehicle,
          isActive: true,
          createdAt: serverTimestamp(),
          createdBy: adminData?.email || 'super-admin'
        });
      }
      
      showSnackbar(`${missingVehicles.length} default vehicle types added successfully!`);
      fetchVehicles();
    } catch (error) {
      console.error('Error adding default vehicles:', error);
      showSnackbar('Error adding default vehicle types', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingVehicle(null);
  };

  const showSnackbar = (message, severity = 'success') => {
    setSnackbar({ open: true, message, severity });
  };

  const getVehicleIcon = (iconName) => {
    return vehicleIcons[iconName] || <DirectionsCar />;
  };

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Vehicle Types Management
        </Typography>
        {isSuperAdmin && (
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              onClick={addDefaultVehicleTypes}
              disabled={loading}
              title="Add or refresh default vehicle types"
            >
              {loading ? 'Adding...' : 'Add Default Types'}
            </Button>
            <Button
              variant="contained"
              startIcon={<AddIcon />}
              onClick={handleOpenDialog}
            >
              Add Vehicle Type
            </Button>
          </Box>
        )}
      </Box>

      {isSuperAdmin ? (
        // Super Admin View - Manage Vehicle Types
        <Paper sx={{ width: '100%', overflow: 'hidden' }}>
          <TableContainer>
            <Table>
                            <TableHead>
                <TableRow>
                  <TableCell>Icon</TableCell>
                  <TableCell>Name</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Order</TableCell>
                  <TableCell>Passengers</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {vehicles.map((vehicle) => (
                  <TableRow key={vehicle.id}>
                    <TableCell>
                      <Avatar sx={{ bgcolor: 'primary.main' }}>
                        {getVehicleIcon(vehicle.icon)}
                      </Avatar>
                    </TableCell>
                    <TableCell>
                      <Typography variant="subtitle1">{vehicle.name}</Typography>
                    </TableCell>
                    <TableCell>
                      <Chip 
                        label={vehicle.isActive ? 'Active' : 'Inactive'}
                        color={vehicle.isActive ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>{vehicle.displayOrder}</TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {vehicle.passengerCapacity || 1} {vehicle.passengerCapacity === 1 ? 'passenger' : 'passengers'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2">
                        {vehicle.passengerCapacity || 1} {vehicle.passengerCapacity === 1 ? 'passenger' : 'passengers'}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <IconButton onClick={() => handleEdit(vehicle)} size="small">
                        <EditIcon />
                      </IconButton>
                      <IconButton 
                        onClick={() => handleDelete(vehicle.id)} 
                        size="small"
                        color="error"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      ) : (
        // Country Admin View - Select Available Vehicles
        <Box>
          <Alert severity="info" sx={{ mb: 3 }}>
            Select which vehicle types are available in {adminData?.country || 'your country'}. These vehicles will appear in the mobile app for riders and drivers.
          </Alert>

          {/* Debug Info - Remove this after testing */}
          {process.env.NODE_ENV === 'development' && (
            <Alert severity="warning" sx={{ mb: 2 }}>
              <strong>Debug Info:</strong> Country: {adminData?.country || 'undefined'}, 
              Email: {adminData?.email || 'undefined'}
            </Alert>
          )}

          <Grid container spacing={3}>
            {vehicles.map((vehicle) => {
              const isEnabled = countryVehicles.includes(vehicle.id);
              return (
                <Grid item xs={12} sm={6} md={4} key={vehicle.id}>
                  <Card 
                    sx={{ 
                      height: '100%',
                      opacity: vehicle.isActive ? 1 : 0.5,
                      border: isEnabled ? '2px solid' : '1px solid',
                      borderColor: isEnabled ? 'primary.main' : 'divider'
                    }}
                  >
                    <CardContent>
                      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                        <Avatar sx={{ bgcolor: 'primary.main', mr: 2 }}>
                          {getVehicleIcon(vehicle.icon)}
                        </Avatar>
                        <Box sx={{ flexGrow: 1 }}>
                          <Typography variant="h6">{vehicle.name}</Typography>
                          <Typography variant="body2" color="text.secondary">
                            {vehicle.passengerCapacity || 1} {vehicle.passengerCapacity === 1 ? 'passenger' : 'passengers'}
                          </Typography>
                          {vehicle.description && (
                            <Typography variant="caption" color="text.secondary">
                              {vehicle.description}
                            </Typography>
                          )}
                        </Box>
                        <FormControlLabel
                          control={
                            <Switch
                              checked={isEnabled}
                              onChange={(e) => handleToggleCountryVehicle(vehicle.id, e.target.checked)}
                              disabled={!vehicle.isActive}
                            />
                          }
                          label=""
                        />
                      </Box>
                      
                      <Chip 
                        label={vehicle.name}
                        size="small"
                        variant="outlined"
                      />
                    </CardContent>
                  </Card>
                </Grid>
              );
            })}
          </Grid>
        </Box>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingVehicle ? 'Edit Vehicle Type' : 'Add New Vehicle Type'}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Vehicle Type Name"
                value={formData.name}
                onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                placeholder="e.g., Car, Bike, Three Wheeler"
                required
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Display Order"
                type="number"
                value={formData.displayOrder}
                onChange={(e) => setFormData({ ...formData, displayOrder: parseInt(e.target.value) || 1 })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Passenger Capacity"
                type="number"
                value={formData.passengerCapacity}
                onChange={(e) => setFormData({ ...formData, passengerCapacity: parseInt(e.target.value) || 1 })}
                inputProps={{ min: 1, max: 50 }}
              />
            </Grid>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Description"
                multiline
                rows={2}
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Brief description of the vehicle type"
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControlLabel
                control={
                  <Switch
                    checked={formData.isActive}
                    onChange={(e) => setFormData({ ...formData, isActive: e.target.checked })}
                  />
                }
                label="Active"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {editingVehicle ? 'Update' : 'Add'} Vehicle Type
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Vehicles;
