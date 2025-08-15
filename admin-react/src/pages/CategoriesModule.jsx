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
  Category,
  LocalOffer,
  Folder,
  FolderOpen
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const CategoriesModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState('all');
  const [selectedCategory, setSelectedCategory] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const statusColors = {
    active: 'success',
    inactive: 'error',
    draft: 'warning'
  };

  const loadCategories = async () => {
    try {
      setLoading(true);
      setError(null);

      const data = await getFilteredData('categories', adminData);
      setCategories(data || []);
      
      console.log(`📊 Loaded ${data?.length || 0} categories for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading categories:', err);
      setError('Failed to load categories: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCategories();
  }, [adminData]);

  const handleViewCategory = (category) => {
    setSelectedCategory(category);
    setViewDialogOpen(true);
  };

  const handleEditCategory = (category) => {
    setSelectedCategory(category);
    setEditDialogOpen(true);
  };

  const handleDeleteCategory = (category) => {
    setSelectedCategory(category);
    setDeleteDialogOpen(true);
  };

  const handleStatusFilter = (status) => {
    setSelectedStatus(status);
    setFilterAnchorEl(null);
  };

  const filteredCategories = categories.filter(category => {
    const matchesSearch = !searchTerm || 
                         category.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         category.description?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesStatus = selectedStatus === 'all' || category.status === selectedStatus;

    return matchesSearch && matchesStatus;
  });

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
  };

  const getCategoryStats = () => {
    return {
      total: filteredCategories.length,
      active: filteredCategories.filter(c => c.status === 'active').length,
      inactive: filteredCategories.filter(c => c.status === 'inactive').length,
      draft: filteredCategories.filter(c => c.status === 'draft').length,
    };
  };

  const stats = getCategoryStats();

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
        <Button color="inherit" size="small" onClick={loadCategories}>
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
          Categories Management
        </Typography>
        <Typography variant="body2" color="text.secondary">
          {isSuperAdmin ? 'Manage all categories across countries' : `Manage categories in ${getCountryDisplayName(userCountry)}`}
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
                    Total Categories
                  </Typography>
                  <Typography variant="h4">
                    {stats.total}
                  </Typography>
                </Box>
                <Category color="primary" sx={{ fontSize: 40, opacity: 0.3 }} />
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
                    Active
                  </Typography>
                  <Typography variant="h4" color="success.main">
                    {stats.active}
                  </Typography>
                </Box>
                <Folder color="success" sx={{ fontSize: 40, opacity: 0.3 }} />
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
                    Inactive
                  </Typography>
                  <Typography variant="h4" color="error.main">
                    {stats.inactive}
                  </Typography>
                </Box>
                <FolderOpen color="error" sx={{ fontSize: 40, opacity: 0.3 }} />
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
                    Draft
                  </Typography>
                  <Typography variant="h4" color="warning.main">
                    {stats.draft}
                  </Typography>
                </Box>
                <LocalOffer color="warning" sx={{ fontSize: 40, opacity: 0.3 }} />
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Box display="flex" gap={2} alignItems="center" flexWrap="wrap">
          <TextField
            placeholder="Search categories..."
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
            FILTERS ({selectedStatus === 'all' ? 'NONE' : selectedStatus.toUpperCase()})
          </Button>
          <Button
            startIcon={<Refresh />}
            onClick={loadCategories}
          >
            REFRESH
          </Button>
          {isSuperAdmin && (
            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={() => setEditDialogOpen(true)}
            >
              Add Category
            </Button>
          )}
        </Box>
      </Paper>

      {/* Categories Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Category</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Subcategories</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredCategories.map((category) => (
              <TableRow key={category.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Category fontSize="small" color="action" />
                    <Typography variant="body2" fontWeight="medium">
                      {category.name}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" noWrap sx={{ maxWidth: 200 }}>
                    {category.description || 'No description'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={category.status || 'active'}
                    color={statusColors[category.status] || 'default'}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Chip
                    label={category.subcategories?.length || 0}
                    size="small"
                    variant="filled"
                  />
                </TableCell>
                <TableCell>
                  <Typography variant="body2">
                    {formatDate(category.createdAt)}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={category.country || userCountry}
                    size="small"
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', gap: 0.5 }}>
                    <Tooltip title="View Details">
                      <IconButton size="small" onClick={() => handleViewCategory(category)}>
                        <Visibility />
                      </IconButton>
                    </Tooltip>
                    {isSuperAdmin && (
                      <>
                        <Tooltip title="Edit">
                          <IconButton size="small" onClick={() => handleEditCategory(category)}>
                            <Edit />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Delete">
                          <IconButton size="small" onClick={() => handleDeleteCategory(category)}>
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
        <MenuItem onClick={() => handleStatusFilter('all')}>All Status</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('active')}>Active</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('inactive')}>Inactive</MenuItem>
        <MenuItem onClick={() => handleStatusFilter('draft')}>Draft</MenuItem>
      </Menu>

      {/* View Dialog */}
      <Dialog
        open={viewDialogOpen}
        onClose={() => setViewDialogOpen(false)}
        maxWidth="md"
        fullWidth
      >
        {selectedCategory && (
          <>
            <DialogTitle>
              Category Details: {selectedCategory.name}
            </DialogTitle>
            <DialogContent>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" gutterBottom>Name</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedCategory.name}
                  </Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Status</Typography>
                  <Chip
                    label={selectedCategory.status || 'active'}
                    color={statusColors[selectedCategory.status] || 'default'}
                    size="small"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="subtitle2" gutterBottom>Description</Typography>
                  <Typography variant="body2" paragraph>
                    {selectedCategory.description || 'No description available'}
                  </Typography>
                  
                  <Typography variant="subtitle2" gutterBottom>Country</Typography>
                  <Chip
                    label={selectedCategory.country || userCountry}
                    size="small"
                    variant="outlined"
                  />
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="subtitle2" gutterBottom>Subcategories</Typography>
                  <Box display="flex" gap={1} flexWrap="wrap">
                    {selectedCategory.subcategories?.length > 0 ? 
                      selectedCategory.subcategories.map((sub, index) => (
                        <Chip key={index} label={sub} size="small" variant="outlined" />
                      )) :
                      <Typography variant="body2" color="text.secondary">No subcategories</Typography>
                    }
                  </Box>
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
          aria-label="add category"
          sx={{ position: 'fixed', bottom: 16, right: 16 }}
          onClick={() => setEditDialogOpen(true)}
        >
          <Add />
        </Fab>
      )}
    </Box>
  );
};

export default CategoriesModule;
