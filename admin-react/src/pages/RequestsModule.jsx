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
  Fab
} from '@mui/material';
import {
  Search,
  Visibility,
  Edit,
  Delete,
  FilterList,
  Refresh,
  Add,
  LocationOn,
  Person,
  AccessTime,
  AttachMoney,
  Category
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const RequestsModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedType, setSelectedType] = useState('all');
  const [selectedRequest, setSelectedRequest] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);

  const statusColors = {
    active: 'success',
    completed: 'primary',
    cancelled: 'error',
    expired: 'warning',
    draft: 'default'
  };

  const typeColors = {
    item_request: 'primary',
    service_request: 'secondary',
    ride_request: 'success',
    delivery_request: 'warning',
    rental_request: 'info'
  };

  const loadRequests = async () => {
    try {
      setLoading(true);
      setError(null);

      const data = await getFilteredData('requests', adminData);
      setRequests(data || []);
      
      console.log(`📊 Loaded ${data?.length || 0} requests for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading requests:', err);
      setError('Failed to load requests: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadRequests();
  }, [adminData]);

  const handleViewRequest = (request) => {
    setSelectedRequest(request);
    setViewDialogOpen(true);
  };

  const handleStatusFilter = (status) => {
    setSelectedStatus(status);
    setFilterAnchorEl(null);
  };

  const handleTypeFilter = (type) => {
    setSelectedType(type);
    setFilterAnchorEl(null);
  };

  const filteredRequests = requests.filter(request => {
    const matchesSearch = request.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         request.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         request.requesterId?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = selectedStatus === 'all' || request.status === selectedStatus;
    const matchesType = selectedType === 'all' || request.type === selectedType;
    
    return matchesSearch && matchesStatus && matchesType;
  });

  const formatDate = (dateValue) => {
    if (!dateValue) return 'N/A';
    
    let date;
    if (dateValue.toDate) {
      date = dateValue.toDate();
    } else if (dateValue instanceof Date) {
      date = dateValue;
    } else {
      date = new Date(dateValue);
    }
    
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  const formatCurrency = (amount, currency) => {
    if (!amount) return 'N/A';
    return `${currency || 'LKR'} ${amount.toLocaleString()}`;
  };

  const getRequestStats = () => {
    return {
      total: filteredRequests.length,
      active: filteredRequests.filter(r => r.status === 'active').length,
      completed: filteredRequests.filter(r => r.status === 'completed').length,
      cancelled: filteredRequests.filter(r => r.status === 'cancelled').length,
    };
  };

  const stats = getRequestStats();

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      {/* Header */}
      <Box sx={{ mb: 3 }}>
        <Typography variant="h4" gutterBottom>
          Requests Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin ? 'Manage all requests across countries' : `Manage requests in ${getCountryDisplayName(userCountry)}`}
        </Typography>
      </Box>

      {/* Error Alert */}
      {error && (
        <Alert severity="error" sx={{ mb: 3 }}>
          {error}
        </Alert>
      )}

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Total Requests
              </Typography>
              <Typography variant="h4">
                {stats.total}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Active
              </Typography>
              <Typography variant="h4" color="success.main">
                {stats.active}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Completed
              </Typography>
              <Typography variant="h4" color="primary.main">
                {stats.completed}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Cancelled
              </Typography>
              <Typography variant="h4" color="error.main">
                {stats.cancelled}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search and Filter Bar */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
          <TextField
            placeholder="Search requests..."
            variant="outlined"
            size="small"
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
            variant="outlined"
            startIcon={<FilterList />}
            onClick={(e) => setFilterAnchorEl(e.currentTarget)}
          >
            Filters ({selectedStatus !== 'all' || selectedType !== 'all' ? 'Active' : 'None'})
          </Button>

          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadRequests}
          >
            Refresh
          </Button>
        </Box>
      </Paper>

      {/* Filter Menu */}
      <Menu
        anchorEl={filterAnchorEl}
        open={Boolean(filterAnchorEl)}
        onClose={() => setFilterAnchorEl(null)}
      >
        <MenuItem disabled><strong>Status</strong></MenuItem>
        <MenuItem onClick={() => handleStatusFilter('all')} selected={selectedStatus === 'all'}>All Status</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('active')} selected={selectedStatus === 'active'}>Active</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('completed')} selected={selectedStatus === 'completed'}>Completed</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('cancelled')} selected={selectedStatus === 'cancelled'}>Cancelled</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('expired')} selected={selectedStatus === 'expired'}>Expired</MenuItem>
        <MenuItem disabled><strong>Type</strong></MenuItem>
        <MenuItem onClick={() => handleTypeFilter('all')} selected={selectedType === 'all'}>All Types</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('item_request')} selected={selectedType === 'item_request'}>Item Request</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('service_request')} selected={selectedType === 'service_request'}>Service Request</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('ride_request')} selected={selectedType === 'ride_request'}>Ride Request</MenuItem>
        <MenuItem onClick={() => handleTypeFilter('delivery_request')} selected={selectedType === 'delivery_request'}>Delivery Request</MenuItem>
      </Menu>

      {/* Requests Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Title</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Requester</TableCell>
              <TableCell>Budget</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Country</TableCell>
              <TableCell align="center">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredRequests.map((request) => (
              <TableRow key={request.id} hover>
                <TableCell>
                  <Box>
                    <Typography variant="subtitle2" noWrap sx={{ maxWidth: 200 }}>
                      {request.title || 'Untitled Request'}
                    </Typography>
                    <Typography variant="caption" color="text.secondary" noWrap sx={{ maxWidth: 200 }}>
                      {request.description}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={request.type?.replace('_', ' ').toUpperCase() || 'N/A'}
                    color={typeColors[request.type] || 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Chip 
                    label={request.status?.toUpperCase() || 'N/A'}
                    color={statusColors[request.status] || 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Person fontSize="small" color="action" />
                    <Typography variant="body2" noWrap>
                      {request.requesterId || 'N/A'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AttachMoney fontSize="small" color="action" />
                    <Typography variant="body2">
                      {formatCurrency(request.budget, request.currency)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <LocationOn fontSize="small" color="action" />
                    <Typography variant="body2" noWrap sx={{ maxWidth: 150 }}>
                      {request.location?.address || request.location?.name || 'N/A'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AccessTime fontSize="small" color="action" />
                    <Typography variant="body2">
                      {formatDate(request.createdAt)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getCountryDisplayName(request.country)}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell align="center">
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Tooltip title="View Details">
                      <IconButton
                        size="small"
                        onClick={() => handleViewRequest(request)}
                        color="primary"
                      >
                        <Visibility fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
            {filteredRequests.length === 0 && (
              <TableRow>
                <TableCell colSpan={9} align="center">
                  <Typography variant="body1" color="text.secondary">
                    No requests found
                  </Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* View Request Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Request Details
        </DialogTitle>
        <DialogContent>
          {selectedRequest && (
            <Box sx={{ pt: 1 }}>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Typography variant="h6">{selectedRequest.title}</Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {selectedRequest.description}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Type:</Typography>
                  <Typography variant="body2">{selectedRequest.type?.replace('_', ' ')}</Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Status:</Typography>
                  <Chip 
                    label={selectedRequest.status?.toUpperCase()}
                    color={statusColors[selectedRequest.status] || 'default'}
                    size="small"
                  />
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Budget:</Typography>
                  <Typography variant="body2">
                    {formatCurrency(selectedRequest.budget, selectedRequest.currency)}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Country:</Typography>
                  <Typography variant="body2">
                    {getCountryDisplayName(selectedRequest.country)}
                  </Typography>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="subtitle2">Location:</Typography>
                  <Typography variant="body2">
                    {selectedRequest.location?.address || selectedRequest.location?.name || 'N/A'}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Created:</Typography>
                  <Typography variant="body2">{formatDate(selectedRequest.createdAt)}</Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Updated:</Typography>
                  <Typography variant="body2">{formatDate(selectedRequest.updatedAt)}</Typography>
                </Grid>

                {selectedRequest.deadline && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2">Deadline:</Typography>
                    <Typography variant="body2">{formatDate(selectedRequest.deadline)}</Typography>
                  </Grid>
                )}
                
                {selectedRequest.tags && selectedRequest.tags.length > 0 && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2">Tags:</Typography>
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 1 }}>
                      {selectedRequest.tags.map((tag, index) => (
                        <Chip key={index} label={tag} size="small" variant="outlined" />
                      ))}
                    </Box>
                  </Grid>
                )}
              </Grid>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default RequestsModule;
