import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  IconButton,
  Button,
  Grid,
  Card,
  CardContent,
  TextField,
  InputAdornment,
  Menu,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Alert,
  CircularProgress,
  Tooltip,
  Fab,
  Avatar
} from '@mui/material';
import {
  Search,
  Visibility,
  Edit,
  Delete,
  FilterList,
  Refresh,
  Add,
  DirectionsCar,
  TwoWheeler,
  LocalShipping,
  Speed,
  Palette
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const VehiclesModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [vehicles, setVehicles] = useState([]);
  const [vehicleTypes, setVehicleTypes] = useState([]);
  const [vehicleTypesMap, setVehicleTypesMap] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedType, setSelectedType] = useState('all');
  const [selectedVehicle, setSelectedVehicle] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);

  const typeColors = {
    car: 'primary',
    bike: 'success',
    truck: 'warning',
    van: 'info',
    bus: 'secondary'
  };

  const typeIcons = {
    car: <DirectionsCar />,
    bike: <TwoWheeler />,
    truck: <LocalShipping />,
    van: <DirectionsCar />,
    bus: <LocalShipping />
  };

  const loadVehicles = async () => {
    try {
      setLoading(true);
      setError(null);

      // Load vehicle types first
      const vehicleTypesData = await getFilteredData('vehicle_types', adminData);
      setVehicleTypes(vehicleTypesData || []);
      
      // Create a mapping of vehicle type IDs to names
      const typesMap = {};
      if (vehicleTypesData) {
        vehicleTypesData.forEach(type => {
          typesMap[type.id] = type.name || type.type_name || 'Unknown';
        });
      }
      setVehicleTypesMap(typesMap);

      // Load driver verifications (contains vehicle data)
      const driversData = await getFilteredData('new_driver_verifications', adminData);
      
      if (driversData) {
        // Extract vehicle information from driver verification data
        const vehiclesWithDrivers = driversData.map(driver => {
          return {
            id: driver.id,
            // Driver info - using correct field names
            driverName: driver.fullName || `${driver.firstName || ''} ${driver.lastName || ''}`.trim() || 'N/A',
            driverPhone: driver.phoneNumber || driver.phone || 'N/A', 
            driverEmail: driver.email || 'N/A',
            status: driver.status || 'pending',
            country: driver.country || userCountry,
            // Vehicle info - using correct field names
            vehicleNumber: driver.vehicleNumber || 'N/A',
            vehicleType: typesMap[driver.vehicleType] || driver.vehicleType || 'Unknown',
            vehicleTypeId: driver.vehicleType, // Keep original ID for filtering
            vehicleBrand: driver.vehicleBrand || 'N/A', // No brand field found, using model
            vehicleModel: driver.vehicleModel || '',
            vehicleColor: driver.vehicleColor || 'N/A',
            vehicleYear: driver.vehicleYear || 'N/A',
            vehicleImages: driver.vehicleImageUrls ? Object.values(driver.vehicleImageUrls) : []
          };
        });
        
        setVehicles(vehiclesWithDrivers);
        
        setVehicles(vehiclesWithDrivers);
      } else {
        setVehicles([]);
      }
      
    } catch (error) {
      console.error('Error loading vehicles:', error);
      setError('Failed to load vehicles');
      setVehicles([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadVehicles();
  }, [adminData]);

  const handleViewVehicle = (vehicle) => {
    setSelectedVehicle(vehicle);
    setViewDialogOpen(true);
  };

  const handleTypeFilter = (type) => {
    setSelectedType(type);
    setFilterAnchorEl(null);
  };

  const filteredVehicles = vehicles.filter(vehicle => {
    const matchesSearch = !searchTerm || 
                         vehicle.driverName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.vehicleModel?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.vehicleNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.vehicleColor?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesType = selectedType === 'all' || 
                       vehicle.vehicleTypeId === selectedType ||
                       vehicle.vehicleType?.toLowerCase().includes(selectedType.toLowerCase());

    return matchesSearch && matchesType;
  });

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  const getVehicleStats = () => {
    const totalVehicles = filteredVehicles.length;
    const activeVehicles = filteredVehicles.filter(v => v.isActive).length;
    const availableVehicles = filteredVehicles.filter(v => v.availability).length;
    
    // Get vehicle type counts
    const vehicleTypeStats = vehicleTypes.map(vType => {
      const matchingVehicles = vehicles.filter(v => v.vehicleType === vType.id);
      return {
        name: vType.name,
        count: matchingVehicles.length,
        color: vType.name.toLowerCase().includes('car') ? 'primary' : 
               vType.name.toLowerCase().includes('bike') ? 'success' : 
               vType.name.toLowerCase().includes('van') ? 'info' : 
               vType.name.toLowerCase().includes('truck') ? 'warning' : 'secondary'
      };
    });

    return {
      total: totalVehicles,
      active: activeVehicles,
      available: availableVehicles,
      vehicleTypeStats
    };
  };

  const stats = getVehicleStats();

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Alert severity="error" action={
        <Button color="inherit" size="small" onClick={loadVehicles}>
          Retry
        </Button>
      }>
        {error}
      </Alert>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box mb={3}>
        <Typography variant="h4" gutterBottom>
          Vehicle Management
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {isSuperAdmin ? 'View all registered vehicles across countries by vehicle type' : `View registered vehicles in ${getCountryDisplayName(userCountry)} by vehicle type`}
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Total Vehicles
                  </Typography>
                  <Typography variant="h4">
                    {stats.total}
                  </Typography>
                </Box>
                <DirectionsCar color="primary" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Active Vehicles
                  </Typography>
                  <Typography variant="h4" color="success.main">
                    {stats.active}
                  </Typography>
                </Box>
                <DirectionsCar color="success" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={4}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Available Now
                  </Typography>
                  <Typography variant="h4" color="info.main">
                    {stats.available}
                  </Typography>
                </Box>
                <Speed color="info" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box display="flex" gap={2} alignItems="center" flexWrap="wrap">
          <TextField
            placeholder="Search vehicles..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 300 }}
          />
          <Button
            startIcon={<FilterList />}
            onClick={(e) => setFilterAnchorEl(e.currentTarget)}
          >
            FILTERS ({selectedType === 'all' ? 'NONE' : selectedType.toUpperCase()})
          </Button>
          <Button
            startIcon={<Refresh />}
            onClick={loadVehicles}
          >
            REFRESH
          </Button>
          {isSuperAdmin && (
            <Button
              variant="contained"
              startIcon={<Add />}
            >
              Add Vehicle
            </Button>
          )}
        </Box>
      </Paper>

      {/* Vehicles Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Driver</TableCell>
              <TableCell>Vehicle</TableCell>
              <TableCell>Brand/Model</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Color</TableCell>
              <TableCell>Year</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredVehicles.map((vehicle) => (
              <TableRow key={vehicle.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    <Avatar sx={{ bgcolor: 'primary.main' }}>
                      {vehicle.driverName?.charAt(0) || 'D'}
                    </Avatar>
                    <Box>
                      <Typography variant="subtitle2" fontWeight="medium">
                        {vehicle.driverName || 'N/A'}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {vehicle.driverPhone || 'No phone'}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    {vehicle.vehicleImages?.[0] ? (
                      <Avatar
                        src={vehicle.vehicleImages[0]}
                        alt="Vehicle"
                        variant="rounded"
                        sx={{ width: 40, height: 40 }}
                      />
                    ) : (
                      <Avatar variant="rounded" sx={{ width: 40, height: 40, bgcolor: 'grey.300' }}>
                        <DirectionsCar />
                      </Avatar>
                    )}
                    <Box>
                      <Typography variant="subtitle2" fontWeight="medium">
                        {vehicle.vehicleNumber || 'N/A'}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {vehicle.vehicleType || 'Unknown type'}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.vehicleModel || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={vehicle.vehicleType || 'Unknown'}
                    size="small"
                    variant="outlined"
                    color="primary"
                  />
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.vehicleColor || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.vehicleYear || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={vehicle.status === 'approved' ? 'Active' : 'Pending'}
                    size="small"
                    color={vehicle.status === 'approved' ? 'success' : 'warning'}
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={vehicle.country || userCountry}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Tooltip title="View Details">
                      <IconButton size="small" onClick={() => handleViewVehicle(vehicle)}>
                        <Visibility />
                      </IconButton>
                    </Tooltip>
                    {isSuperAdmin && (
                      <>
                        <Tooltip title="Edit">
                          <IconButton size="small">
                            <Edit />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Delete">
                          <IconButton size="small">
                            <Delete />
                          </IconButton>
                        </Tooltip>
                      </>
                    )}
                  </Box>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Filter Menu */}
      <Menu
        anchorEl={filterAnchorEl}
        open={Boolean(filterAnchorEl)}
        onClose={() => setFilterAnchorEl(null)}
      >
        <MenuItem onClick={() => handleTypeFilter('all')}>All Types</MenuItem>
        {vehicleTypes.map((type) => (
          <MenuItem key={type.id} onClick={() => handleTypeFilter(type.id)}>
            {type.name || type.type_name || 'Unknown'}
          </MenuItem>
        ))}
      </Menu>

      {/* View Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedVehicle && (
          <>
            <DialogTitle>
              Driver & Vehicle Details: {selectedVehicle.driverName}
            </DialogTitle>
            <DialogContent>
              <Grid container spacing={3}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="h6" gutterBottom color="primary">Driver Information</Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Full Name</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.driverName || 'N/A'}
                  </Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Phone Number</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.driverPhone || 'N/A'}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Email</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.driverEmail || 'N/A'}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Country</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.country || 'N/A'}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Status</Typography>
                  <Chip
                    label={selectedVehicle.status === 'approved' ? 'Approved' : 'Pending'}
                    color={selectedVehicle.status === 'approved' ? 'success' : 'warning'}
                    size="small"
                    sx={{ mb: 2 }}
                  />
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Typography variant="h6" gutterBottom color="primary">Vehicle Information</Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Vehicle Number</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.vehicleNumber || 'N/A'}
                  </Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Type</Typography>
                  <Chip
                    label={selectedVehicle.vehicleType || 'Unknown'}
                    color="primary"
                    size="small"
                    sx={{ mb: 2 }}
                  />

                  <Typography variant="subtitle2" gutterBottom>Brand & Model</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.vehicleBrand || 'N/A'} {selectedVehicle.vehicleModel || ''}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Year & Color</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.vehicleYear || 'N/A'} • {selectedVehicle.vehicleColor || 'N/A'}
                  </Typography>

                  {selectedVehicle.vehicleImages && selectedVehicle.vehicleImages.length > 0 && (
                    <>
                      <Typography variant="subtitle2" gutterBottom>Vehicle Images</Typography>
                      <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap', mb: 2 }}>
                        {selectedVehicle.vehicleImages.map((image, index) => (
                          <img
                            key={index}
                            src={image}
                            alt={`Vehicle ${index + 1}`}
                            style={{ 
                              width: 80, 
                              height: 80, 
                              objectFit: 'cover', 
                              borderRadius: 8,
                              border: '1px solid #ddd'
                            }}
                          />
                        ))}
                      </Box>
                    </>
                  )}
                </Grid>
              </Grid>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
            </DialogActions>
          </>
        )}
      </Dialog>

      {/* Floating Action Button */}
      {isSuperAdmin && (
        <Fab
          color="primary"
          aria-label="add vehicle"
          sx={{ position: 'fixed', bottom: 16, right: 16 }}
        >
          <Add />
        </Fab>
      )}
    </Box>
  );
};

export default VehiclesModule;
