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
  Category,
  Folder,
  FolderOpen,
  SubdirectoryArrowRight
} from '@mui/icons-material';
import useCountryFilter from '../hooks/useCountryFilter.jsx';

const SubcategoriesModule = () => {
  const {
    getFilteredData,
    adminData,
    isSuperAdmin,
    getCountryDisplayName,
    userCountry
  } = useCountryFilter();

  const [subcategories, setSubcategories] = useState([]);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterAnchorEl, setFilterAnchorEl] = useState(null);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedSubcategory, setSelectedSubcategory] = useState(null);
  const [viewDialogOpen, setViewDialogOpen] = useState(false);

  const loadSubcategories = async () => {
    try {
      setLoading(true);
      setError(null);

      const [subcatsData, catsData] = await Promise.all([
        getFilteredData('subcategories', adminData),
        getFilteredData('categories', adminData)
      ]);
      
      setSubcategories(subcatsData || []);
      setCategories(catsData || []);
      
      console.log(`📊 Loaded ${subcatsData?.length || 0} subcategories for ${isSuperAdmin ? 'super admin' : `country admin (${userCountry})`}`);
    } catch (err) {
      console.error('Error loading subcategories:', err);
      setError('Failed to load subcategories: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSubcategories();
  }, [adminData]);

  const handleViewSubcategory = (subcategory) => {
    setSelectedSubcategory(subcategory);
    setViewDialogOpen(true);
  };

  const handleCategoryFilter = (categoryId) => {
    setSelectedCategory(categoryId);
    setFilterAnchorEl(null);
  };

  const filteredSubcategories = subcategories.filter(subcategory => {
    const matchesSearch = !searchTerm || 
                         (subcategory.name || subcategory.subcategory)?.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         subcategory.description?.toLowerCase().includes(searchTerm.toLowerCase());

    const matchesCategory = selectedCategory === 'all' || 
                           (subcategory.categoryId || subcategory.category_id) === selectedCategory;

    return matchesSearch && matchesCategory;
  });

  // Get category name by ID
  const getCategoryName = (categoryId) => {
    const category = categories.find(c => c.id === categoryId);
    return category ? (category.name || category.category) : 'Unknown Category';
  };

  // Calculate stats
  const totalSubcategories = subcategories.length;
  const activeSubcategories = subcategories.filter(sc => sc.isActive !== false).length;
  const inactiveSubcategories = totalSubcategories - activeSubcategories;

  const stats = [
    { label: 'Total Subcategories', value: totalSubcategories, color: 'primary' },
    { label: 'Active', value: activeSubcategories, color: 'success' },
    { label: 'Inactive', value: inactiveSubcategories, color: 'error' },
    { label: 'Categories', value: categories.length, color: 'info' }
  ];

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
          Subcategories Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin ? 'Manage all subcategories across countries' : `Manage subcategories in ${getCountryDisplayName(userCountry)}`}
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
            placeholder="Search subcategories..."
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
            color={selectedCategory !== 'all' ? 'primary' : 'inherit'}
          >
            FILTERS ({selectedCategory !== 'all' ? '1' : 'NONE'})
          </Button>
          
          <Button
            startIcon={<Refresh />}
            onClick={loadSubcategories}
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
        <MenuItem onClick={() => handleCategoryFilter('all')}>
          <Typography variant="body2">All Categories</Typography>
        </MenuItem>
        {categories.map(category => (
          <MenuItem key={category.id} onClick={() => handleCategoryFilter(category.id)}>
            <Typography variant="body2">
              {category.name}
            </Typography>
          </MenuItem>
        ))}
      </Menu>

      {/* Subcategories Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Parent Category</TableCell>
              <TableCell>Description</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Items Count</TableCell>
              <TableCell>Created</TableCell>
              <TableCell>Country</TableCell>
              <TableCell>Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredSubcategories.map((subcategory) => (
              <TableRow key={subcategory.id} hover>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    {subcategory.icon ? (
                      <Avatar sx={{ width: 32, height: 32, fontSize: '1rem' }}>
                        {subcategory.icon}
                      </Avatar>
                    ) : (
                      <SubdirectoryArrowRight fontSize="small" color="action" />
                    )}
                    <Typography variant="body2" fontWeight="medium">
                      {subcategory.name || subcategory.subcategory || 'Unnamed Subcategory'}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Folder fontSize="small" color="action" />
                    <Typography variant="body2">
                      {getCategoryName(subcategory.categoryId || subcategory.category_id)}
                    </Typography>
                  </Box>
                </TableCell>
                <TableCell>
                  <Typography 
                    variant="body2" 
                    sx={{ 
                      maxWidth: 200, 
                      overflow: 'hidden', 
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap'
                    }}
                  >
                    {subcategory.description || 'No description'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip
                    label={subcategory.isActive !== false ? 'Active' : 'Inactive'}
                    color={subcategory.isActive !== false ? 'success' : 'error'}
                    size="small"
                  />
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {subcategory.itemsCount || 0} items
                  </Typography>
                </TableCell>
                <TableCell>
                  <Typography variant="body2" color="text.secondary">
                    {subcategory.createdAt ? new Date(subcategory.createdAt.toDate ? subcategory.createdAt.toDate() : subcategory.createdAt).toLocaleDateString() : 'N/A'}
                  </Typography>
                </TableCell>
                <TableCell>
                  <Chip label={subcategory.country || userCountry || 'N/A'} size="small" variant="outlined" />
                </TableCell>
                <TableCell>
                  <Box display="flex" gap={1}>
                    <Tooltip title="View Details">
                      <IconButton 
                        size="small" 
                        onClick={() => handleViewSubcategory(subcategory)}
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

        {filteredSubcategories.length === 0 && (
          <Box p={4} textAlign="center">
            <Typography variant="body1" color="text.secondary">
              {subcategories.length === 0 ? 'No subcategories found' : 'No subcategories match your current filters'}
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
        {selectedSubcategory && (
          <>
            <DialogTitle>
              Subcategory Details: {selectedSubcategory.name || selectedSubcategory.subcategory}
            </DialogTitle>
            <DialogContent>
              <Grid container spacing={2}>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Name</Typography>
                  <Typography variant="body1" gutterBottom>{selectedSubcategory.name || selectedSubcategory.subcategory || 'N/A'}</Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Parent Category</Typography>
                  <Typography variant="body1" gutterBottom>{getCategoryName(selectedSubcategory.categoryId || selectedSubcategory.category_id)}</Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2" color="text.secondary">Description</Typography>
                  <Typography variant="body1" gutterBottom>
                    {selectedSubcategory.description || 'No description provided'}
                  </Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Status</Typography>
                  <Typography variant="body1" gutterBottom>
                    {selectedSubcategory.isActive !== false ? 'Active' : 'Inactive'}
                  </Typography>
                </Grid>
                <Grid item xs={12} md={6}>
                  <Typography variant="body2" color="text.secondary">Items Count</Typography>
                  <Typography variant="body1" gutterBottom>
                    {selectedSubcategory.itemsCount || 0} items
                  </Typography>
                </Grid>
              </Grid>
            </DialogContent>
            <DialogActions>
              <Button onClick={() => setViewDialogOpen(false)}>Close</Button>
              {isSuperAdmin && (
                <Button variant="contained" color="primary">
                  Edit Subcategory
                </Button>
              )}
            </DialogActions>
          </>
        )}
      </Dialog>
    </Box>
  );
};

export default SubcategoriesModule;
