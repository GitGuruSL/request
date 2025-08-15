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
  FormControl,
  InputLabel,
  Select
} from '@mui/material';
import {
  Search,
  Visibility,
  Edit,
  Delete,
  FilterList,
  Refresh,
  Add,
  Tune,
  Category,
  DataObject,
  ToggleOn,
  ToggleOff
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const VariablesModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [variables, setVariables] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedType, setSelectedType] = useState('all');
  const [selectedVariable, setSelectedVariable] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);

  const typeColors = {
    text: 'primary',
    number: 'secondary',
    boolean: 'success',
    select: 'info',
    multiselect: 'warning',
    date: 'error'
  };

  const loadVariables = async () => {
    try {
      setLoading(true);
      setError(null);

      const data = await getFilteredData('custom_product_variables', adminData);
      setVariables(data || []);
      
      console.log(`📊 Loaded ${data?.length || 0} variables for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading variables:', err);
      setError('Failed to load variables: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadVariables();
  }, [adminData]);

  const handleViewVariable = (variable) => {
    setSelectedVariable(variable);
    setViewDialogOpen(true);
  };

  const handleTypeFilter = (type) => {
    setSelectedType(type);
    setFilterAnchorEl(null);
  };

  const filteredVariables = variables.filter(variable => {
    const matchesSearch = !searchTerm || 
                         variable.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         variable.label?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         variable.category?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesType = selectedType === 'all' || variable.type === selectedType;

    return matchesSearch && matchesType;
  });

  // Calculate stats
  const totalVariables = variables.length;
  const activeVariables = variables.filter(v => v.isActive !== false).length;
  const inactiveVariables = totalVariables - activeVariables;

  const stats = [
    { label: 'Total Variables', value: totalVariables, color: 'primary' },
    { label: 'Active', value: activeVariables, color: 'success' },
    { label: 'Inactive', value: inactiveVariables, color: 'error' },
    { label: 'Types', value: [...new Set(variables.map(v => v.type))].length, color: 'info' }
  ];

  const uniqueTypes = [...new Set(variables.map(v => v.type).filter(Boolean))];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      {/* Header */}
      <Box mb={3}>
        <Typography variant="h4" component="h1" gutterBottom>
          Variables Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin ? 'Manage all variable types across countries' : `Manage variables in ${getCountryDisplayName(userCountry)}`}
        </Typography>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Grid container spacing={3} mb={3}>
        {stats.map((stat, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <Card>
              <CardContent sx={{ textAlign: 'center' }}>
                <Typography variant="h3" color={`${stat.color}.main`} gutterBottom>
                  {stat.value}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {stat.label}
                </Typography>
              </CardContent>
            </Card>
          </Grid>
        ))}
      </Grid>

      {/* Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box display="flex" gap={2} alignItems="center" flexWrap="wrap">
          <TextField
            size="small"
            placeholder="Search variables..."
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
            color={selectedType !== 'all' ? 'primary' : 'inherit'}
          >
            FILTERS ({selectedType !== 'all' ? '1' : 'NONE'})
          </Button>
          
          <Button
            startIcon={<Refresh />}
            onClick={loadVariables}
          >
            REFRESH
          </Button>

          {isSuperAdmin && (
            <Fab
              color="primary"
              aria-label="add"
              size="medium"
              sx={{ ml: 'auto' }}
            >
              <Add />
            </Fab>
          )}
        </Box>
      </Paper>

      {/* Filter Menu */}
      <Menu
        anchorEl={filterAnchorEl}
        open={Boolean(filterAnchorEl)}
        onClose={() => setFilterAnchorEl(null)}
      >
        <MenuItem onClick={() => handleTypeFilter('all')}>
          <Typography variant="body2">All Types</Typography>
        </MenuItem>
        {uniqueTypes.map(type => (
          <MenuItem key={type} onClick={() => handleTypeFilter(type)}>
            <Typography variant="body2" sx={{ textTransform: 'capitalize' }}>
              {type}
            </Typography>
          </MenuItem>
        ))}
      </Menu>

      {/* Variables Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Label</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredVariables.map((variable) => (
              <TableRow key={variable.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <DataObject fontSize="small" color="action" />
                    <Typography variant="body2" fontWeight="medium">
                      {variable.name || 'Unnamed Variable'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {variable.label || 'No Label'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={variable.type || 'Unknown'}
                    color={typeColors[variable.type] || 'default'}
                    size="small"
                    sx={{ textTransform: 'capitalize' }}
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Category fontSize="small" color="action" />
                    <Typography variant="body2">
                      {variable.category || 'Uncategorized'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  {variable.isActive !== false ? (
                    <Chip icon={<ToggleOn />} label="Active" color="success" size="small" />
                  ) : (
                    <Chip icon={<ToggleOff />} label="Inactive" color="error" size="small" />
                  )}
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {variable.createdAt ? new Date(variable.createdAt.toDate ? variable.createdAt.toDate() : variable.createdAt).toLocaleDateString() : 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip label={variable.country || userCountry || 'N/A'} size="small" variant="outlined" />
                </TableCell>
                <TableCell>
                  <Box display="flex" gap={1}>
                    <Tooltip title="View Details">
                      <IconButton 
                        size="small" 
                        onClick={() => handleViewVariable(variable)}
                      >
                        <Visibility />
                      </IconButton>
                    </Tooltip>
                    {isSuperAdmin && (
                      <>
                        <Tooltip title="Edit">
                          <IconButton 
                            size="small" 
                            color="primary"
                            onClick={() => {
                              alert('Edit functionality not yet implemented');
                            }}
                          >
                            <Edit />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Delete">
                          <IconButton 
                            size="small" 
                            color="error"
                            onClick={() => {
                              alert('Delete functionality not yet implemented');
                            }}
                          >
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

        {filteredVariables.length === 0 && (
          <Box p={4} textAlign="center">
            <Typography variant="body1" color="text.secondary">
              {variables.length === 0 ? 'No variables found' : 'No variables match your current filters'}
            </Typography>
          </Box>
        )}
      </TableContainer>

      {/* View Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedVariable && (
          <>
            <DialogTitle>
              Variable Details: {selectedVariable.name}
            </DialogTitle>
            <DialogContent>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Name</Typography>
                  <Typography variant="body1" gutterBottom>{selectedVariable.name || 'N/A'}</Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Label</Typography>
                  <Typography variant="body1" gutterBottom>{selectedVariable.label || 'N/A'}</Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Type</Typography>
                  <Typography variant="body1" gutterBottom sx={{ textTransform: 'capitalize' }}>{selectedVariable.type || 'N/A'}</Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Category</Typography>
                  <Typography variant="body1" gutterBottom>{selectedVariable.category || 'N/A'}</Typography>
                </Grid>
                {selectedVariable.options && (
                  <Grid item xs={12}>
                    <Typography variant="body2" color="text.secondary">Options</Typography>
                    <Typography variant="body1" gutterBottom>
                      {Array.isArray(selectedVariable.options) 
                        ? selectedVariable.options.join(', ') 
                        : JSON.stringify(selectedVariable.options)
                      }
                    </Typography>
                  </Grid>
                )}
                <Grid item xs={12}>
                  <Typography variant="body2" color="text.secondary">Description</Typography>
                  <Typography variant="body1" gutterBottom>
                    {selectedVariable.description || 'No description provided'}
                  </Typography>
                </Grid>
              </Grid>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
              {isSuperAdmin && (
                <Button variant="contained" color="primary">
                  Edit Variable
                </Button>
              )}
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
};

export default VariablesModule;
