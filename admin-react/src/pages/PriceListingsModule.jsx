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
  Avatar,
  Rating
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
  Category,
  Store,
  Star
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const PriceListingsModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [listings, setListings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedListing, setSelectedListing] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);

  const statusColors = {
    active: 'success',
    inactive: 'error',
    pending: 'warning',
    expired: 'default'
  };

  const loadListings = async () => {
    try {
      setLoading(true);
      setError(null);

      const data = await getFilteredData('price_listings', adminData);
      setListings(data || []);
      
      console.log(`📊 Loaded ${data?.length || 0} price listings for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading price listings:', err);
      setError('Failed to load price listings: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadListings();
  }, [adminData]);

  const handleViewListing = (listing) => {
    setSelectedListing(listing);
    setViewDialogOpen(true);
  };

  const handleStatusFilter = (status) => {
    setSelectedStatus(status);
    setFilterAnchorEl(null);
  };

  const handleCategoryFilter = (category) => {
    setSelectedCategory(category);
    setFilterAnchorEl(null);
  };

  const filteredListings = listings.filter(listing => {
    const matchesSearch = listing.title?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         listing.description?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         listing.businessName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         listing.category?.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = selectedStatus === 'all' || listing.status === selectedStatus;
    const matchesCategory = selectedCategory === 'all' || listing.category === selectedCategory;
    
    return matchesSearch && matchesStatus && matchesCategory;
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

  const getListingStats = () => {
    return {
      total: filteredListings.length,
      active: filteredListings.filter(l => l.status === 'active').length,
      inactive: filteredListings.filter(l => l.status === 'inactive').length,
      pending: filteredListings.filter(l => l.status === 'pending').length,
    };
  };

  const getUniqueCategories = () => {
    const categories = listings.map(l => l.category).filter(Boolean);
    return [...new Set(categories)];
  };

  const stats = getListingStats();
  const categories = getUniqueCategories();

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
          Price Listings Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin ? 'Manage all price listings across countries' : `Manage price listings in ${getCountryDisplayName(userCountry)}`}
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
                Total Listings
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
                Pending
              </Typography>
              <Typography variant="h4" color="warning.main">
                {stats.pending}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography color="textSecondary" gutterBottom variant="h6">
                Inactive
              </Typography>
              <Typography variant="h4" color="error.main">
                {stats.inactive}
              </Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Search and Filter Bar */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box sx={{ display: 'flex', gap: 2, alignItems: 'center', flexWrap: 'wrap' }}>
          <TextField
            placeholder="Search listings..."
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
            Filters ({selectedStatus !== 'all' || selectedCategory !== 'all' ? 'Active' : 'None'})
          </Button>

          <Button
            variant="outlined"
            startIcon={<Refresh />}
            onClick={loadListings}
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
        <MenuItem onClick={() => handleStatusFilter('inactive')} selected={selectedStatus === 'inactive'}>Inactive</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('pending')} selected={selectedStatus === 'pending'}>Pending</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('expired')} selected={selectedStatus === 'expired'}>Expired</MenuItem>
        
        {categories.length > 0 && (
          <>
            <MenuItem disabled><strong>Category</strong></MenuItem>
            <MenuItem onClick={() => handleCategoryFilter('all')} selected={selectedCategory === 'all'}>All Categories</MenuItem>
            {categories.map((category) => (
              <MenuItem 
                key={category} 
                onClick={() => handleCategoryFilter(category)} 
                selected={selectedCategory === category}
              >
                {category}
              </MenuItem>
            ))}
          </>
        )}
      </Menu>

      {/* Listings Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Product/Service</TableCell>
              <TableCell>Business</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Price</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Rating</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Country</TableCell>
              <TableCell align="center">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredListings.map((listing) => (
              <TableRow key={listing.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
                    {listing.images && listing.images[0] && (
                      <Avatar 
                        src={listing.images[0]} 
                        alt={listing.title}
                        variant="rounded"
                      />
                    )}
                    <Box>
                      <Typography variant="subtitle2" noWrap sx={{ maxWidth: 200 }}>
                        {listing.title || 'Untitled Listing'}
                      </Typography>
                      <Typography variant="caption" color="text.secondary" noWrap sx={{ maxWidth: 200 }}>
                        {listing.description}
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Store fontSize="small" color="action" />
                    <Typography variant="body2" noWrap>
                      {listing.businessName || listing.businessId || 'N/A'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={listing.category || 'N/A'}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AttachMoney fontSize="small" color="action" />
                    <Typography variant="body2">
                      {formatCurrency(listing.price, listing.currency)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={listing.status?.toUpperCase() || 'N/A'}
                    color={statusColors[listing.status] || 'default'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <LocationOn fontSize="small" color="action" />
                    <Typography variant="body2" noWrap sx={{ maxWidth: 150 }}>
                      {listing.location?.address || listing.location?.name || 'N/A'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Rating 
                      value={listing.averageRating || 0} 
                      size="small" 
                      readOnly 
                      precision={0.1}
                    />
                    <Typography variant="caption" color="text.secondary">
                      ({listing.reviewCount || 0})
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <AccessTime fontSize="small" color="action" />
                    <Typography variant="body2">
                      {formatDate(listing.createdAt)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getCountryDisplayName(listing.country)}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell align="center">
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <Tooltip title="View Details">
                      <IconButton
                        size="small"
                        onClick={() => handleViewListing(listing)}
                        color="primary"
                      >
                        <Visibility fontSize="small" />
                      </IconButton>
                    </Tooltip>
                  </Box>
                </TableCell>
              </TableRow>
            ))}
            {filteredListings.length === 0 && (
              <TableRow>
                <TableCell colSpan={10} align="center">
                  <Typography variant="body1" color="text.secondary">
                    No price listings found
                  </Typography>
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </TableContainer>

      {/* View Listing Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          Listing Details
        </DialogTitle>
        <DialogContent>
          {selectedListing && (
            <Box sx={{ pt: 1 }}>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Typography variant="h6">{selectedListing.title}</Typography>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    {selectedListing.description}
                  </Typography>
                </Grid>
                
                {selectedListing.images && selectedListing.images.length > 0 && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2" sx={{ mb: 1 }}>Images:</Typography>
                    <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                      {selectedListing.images.slice(0, 4).map((image, index) => (
                        <Avatar 
                          key={index}
                          src={image} 
                          alt={`Image ${index + 1}`}
                          variant="rounded"
                          sx={{ width: 80, height: 80 }}
                        />
                      ))}
                    </Box>
                  </Grid>
                )}
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Business:</Typography>
                  <Typography variant="body2">{selectedListing.businessName || 'N/A'}</Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Category:</Typography>
                  <Typography variant="body2">{selectedListing.category || 'N/A'}</Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Price:</Typography>
                  <Typography variant="body2">
                    {formatCurrency(selectedListing.price, selectedListing.currency)}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Status:</Typography>
                  <Chip 
                    label={selectedListing.status?.toUpperCase()}
                    color={statusColors[selectedListing.status] || 'default'}
                    size="small"
                  />
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Rating:</Typography>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Rating 
                      value={selectedListing.averageRating || 0} 
                      size="small" 
                      readOnly 
                      precision={0.1}
                    />
                    <Typography variant="body2">
                      ({selectedListing.reviewCount || 0} reviews)
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Country:</Typography>
                  <Typography variant="body2">
                    {getCountryDisplayName(selectedListing.country)}
                  </Typography>
                </Grid>
                
                <Grid item xs={12}>
                  <Typography variant="subtitle2">Location:</Typography>
                  <Typography variant="body2">
                    {selectedListing.location?.address || selectedListing.location?.name || 'N/A'}
                  </Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Created:</Typography>
                  <Typography variant="body2">{formatDate(selectedListing.createdAt)}</Typography>
                </Grid>
                
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Updated:</Typography>
                  <Typography variant="body2">{formatDate(selectedListing.updatedAt)}</Typography>
                </Grid>

                {selectedListing.tags && selectedListing.tags.length > 0 && (
                  <Grid item xs={12}>
                    <Typography variant="subtitle2">Tags:</Typography>
                    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mt: 1 }}>
                      {selectedListing.tags.map((tag, index) => (
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

export default PriceListingsModule;
