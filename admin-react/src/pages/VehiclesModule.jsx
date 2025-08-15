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

      // Load both cars and bikes
      const [carsData, bikesData] = await Promise.all([
        getFilteredData('cars', adminData),
        getFilteredData('bikes', adminData)
      ]);
      
      const allVehicles = [
        ...(carsData || []).map(car => ({ ...car, type: 'car' })),
        ...(bikesData || []).map(bike => ({ ...bike, type: 'bike' }))
      ];
      
      setVehicles(allVehicles);
      
      console.log(`📊 Loaded ${allVehicles.length} vehicles for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading vehicles:', err);
      setError('Failed to load vehicles: ' + err.message);
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
                         vehicle.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.model?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.brand?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         vehicle.color?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesType = selectedType === 'all' || vehicle.type === selectedType;

    return matchesSearch && matchesType;
  });

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  const getVehicleStats = () => {
    return {
      total: filteredVehicles.length,
      cars: filteredVehicles.filter(v => v.type === 'car').length,
      bikes: filteredVehicles.filter(v => v.type === 'bike').length,
      trucks: filteredVehicles.filter(v => v.type === 'truck').length,
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
          Vehicles Management
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {isSuperAdmin ? 'Manage all vehicles across countries' : `Manage vehicles in ${getCountryDisplayName(userCountry)}`}
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} mb={3}>
        <Grid item xs={12} sm={6} md={3}>
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
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Cars
                  </Typography>
                  <Typography variant="h4" color="primary.main">
                    {stats.cars}
                  </Typography>
                </Box>
                <DirectionsCar color="primary" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Bikes
                  </Typography>
                  <Typography variant="h4" color="success.main">
                    {stats.bikes}
                  </Typography>
                </Box>
                <TwoWheeler color="success" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Box display="flex" alignItems="center" justifyContent="space-between">
                <Box>
                  <Typography color="text.secondary" gutterBottom variant="overline">
                    Trucks
                  </Typography>
                  <Typography variant="h4" color="warning.main">
                    {stats.trucks}
                  </Typography>
                </Box>
                <LocalShipping color="warning" sx={{ fontSize: 40, opacity: 0.3 }} />
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
              <TableCell>Vehicle</TableCell>
              <TableCell>Brand</TableCell>
              <TableCell>Model</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Color</TableCell>
              <TableCell>Year</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredVehicles.map((vehicle) => (
              <TableRow key={vehicle.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    {vehicle.imageUrl ? (
                      <Avatar
                        src={vehicle.imageUrl}
                        alt={vehicle.name}
                        sx={{ width: 48, height: 48 }}
                        variant="rounded"
                      />
                    ) : (
                      <Avatar sx={{ width: 48, height: 48 }} variant="rounded">
                        {typeIcons[vehicle.type] || <DirectionsCar />}
                      </Avatar>
                    )}
                    <Box>
                      <Typography variant="subtitle2" fontWeight="medium">
                        {vehicle.name}
                      </Typography>
                      <Typography variant="caption" color="text.secondary">
                        {vehicle.description}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.brand || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.model || 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    icon={typeIcons[vehicle.type]}
                    label={vehicle.type}
                    color={typeColors[vehicle.type] || 'default'}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Box
                      sx={{
                        width: 16,
                        height: 16,
                        borderRadius: '50%',
                        backgroundColor: vehicle.color?.toLowerCase() || '#ccc',
                        border: '1px solid #ddd'
                      }}
                    />
                    <Typography variant="body2">
                      {vehicle.color || 'N/A'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {vehicle.year || 'N/A'}
                  </Typography>
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
        <MenuItem onClick={() => handleTypeFilter('car')}>Cars</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('bike')}>Bikes</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('truck')}>Trucks</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('van')}>Vans</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('bus')}>Buses</MenuItem>
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
              Vehicle Details: {selectedVehicle.name}
            </DialogTitle>
            <DialogContent>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  {selectedVehicle.imageUrl && (
                    <img
                      src={selectedVehicle.imageUrl}
                      alt={selectedVehicle.name}
                      style={{ width: '100%', maxWidth: 300, borderRadius: 8 }}
                    />
                  )}
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" gutterBottom>Vehicle Name</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.name}
                  </Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Brand & Model</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.brand} {selectedVehicle.model}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Type</Typography>
                  <Chip
                    icon={typeIcons[selectedVehicle.type]}
                    label={selectedVehicle.type}
                    color={typeColors[selectedVehicle.type] || 'default'}
                    size="small"
                    sx={{ mb: 2 }}
                  />

                  <Typography variant="subtitle2" gutterBottom>Year & Color</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.year} • {selectedVehicle.color}
                  </Typography>

                  <Typography variant="subtitle2" gutterBottom>Description</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedVehicle.description || 'No description available'}
                  </Typography>
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
