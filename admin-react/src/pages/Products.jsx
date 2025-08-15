import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Card,
  CardContent,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
  Grid,
  Chip,
  Alert,
  LinearProgress,
  IconButton,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  Avatar,
  Switch,
  FormControlLabel,
  ImageList,
  ImageListItem
} from '@mui/material';
import { 
  Add, 
  Edit, 
  Delete, 
  Search,
  FilterList,
  Visibility,
  VisibilityOff,
  PhotoCamera,
  Close
} from '@mui/icons-material';
import { 
  collection, 
  getDocs, 
  addDoc, 
  updateDoc, 
  deleteDoc,
  doc, 
  serverTimestamp,
  query,
  orderBy,
  where 
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../firebase/config';
import useCountryFilter from '../hooks/useCountryFilter';

const Products = () => {
  const { getFilteredData, adminData, isSuperAdmin, userCountry } = useCountryFilter();
  const [products, setProducts] = useState([]);
  const [filteredProducts, setFilteredProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [editingProduct, setEditingProduct] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [brandFilter, setBrandFilter] = useState('');
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [brands, setBrands] = useState([]);
  const [uploadedImages, setUploadedImages] = useState([]);
  const [formData, setFormData] = useState({
    name: '',
    brand: '',
    categoryId: '',
    subcategoryId: '',
    description: '',
    keywords: [],
    images: [],
    availableVariables: {},
    isActive: true
  });

  useEffect(() => {
    loadProducts();
    loadCategories();
    loadBrands();
  }, []);

  useEffect(() => {
    filterProducts();
  }, [products, searchTerm, categoryFilter, brandFilter]);

  // Load subcategories when category changes
  useEffect(() => {
    if (formData.categoryId) {
      loadSubcategories(formData.categoryId);
    } else {
      setSubcategories([]);
    }
  }, [formData.categoryId]);

  const loadProducts = async () => {
    try {
      setLoading(true);
      const data = await getFilteredData('master_products', adminData);
      const productsData = data || [];
      setProducts(productsData);
    } catch (error) {
      console.error('Error loading products:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    try {
      const data = await getFilteredData('categories', adminData);
      const categoriesData = (data || []).filter(category => 
        category.type === 'item' || !category.type
      );
      console.log('Loaded item categories:', categoriesData);
      setCategories(categoriesData.sort((a, b) => {
        const aName = a.name || a.category || '';
        const bName = b.name || b.category || '';
        return aName.localeCompare(bName);
      }));
    } catch (error) {
      console.error('Error loading categories:', error);
    }
  };

  // Load subcategories for selected category
  const loadSubcategories = async (categoryId) => {
    if (!categoryId) {
      setSubcategories([]);
      return;
    }
    
    try {
      // Try different possible field names for the category relationship
      const queries = [
        query(collection(db, 'subcategories'), where('categoryId', '==', categoryId)),
        query(collection(db, 'subcategories'), where('category_id', '==', categoryId)),
        query(collection(db, 'subcategories'), where('parentCategoryId', '==', categoryId)),
        query(collection(db, 'subcategories'), where('parentId', '==', categoryId))
      ];
      
      let subcategoriesData = [];
      
      // Try each query until we find subcategories
      for (const q of queries) {
        try {
          const snapshot = await getDocs(q);
          if (!snapshot.empty) {
            snapshot.forEach(doc => {
              const data = { id: doc.id, ...doc.data() };
              // Avoid duplicates
              if (!subcategoriesData.find(sub => sub.id === data.id)) {
                subcategoriesData.push(data);
              }
            });
            if (subcategoriesData.length > 0) break; // Found some, stop trying
          }
        } catch (err) {
          console.log('Query failed, trying next:', err.message);
        }
      }
      
      console.log('Loaded subcategories for category', categoryId, ':', subcategoriesData);
      setSubcategories(subcategoriesData.sort((a, b) => {
        const aName = a.name || a.subcategory || '';
        const bName = b.name || b.subcategory || '';
        return aName.localeCompare(bName);
      }));
    } catch (error) {
      console.error('Error loading subcategories:', error);
      setSubcategories([]);
    }
  };

  const loadBrands = async () => {
    try {
      const data = await getFilteredData('brands', adminData);
      const brandsData = (data || []).filter(brand => brand.isActive !== false);
      
      // Sort brands by name
      brandsData.sort((a, b) => {
        const aName = a.name || a.brandName || '';
        const bName = b.name || b.brandName || '';
        return aName.localeCompare(bName);
      });
      
      setBrands(brandsData);
    } catch (error) {
      console.error('Error loading brands:', error);
    }
  };

  const filterProducts = () => {
    let filtered = products;
    
    if (searchTerm) {
      filtered = filtered.filter(product =>
        product.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.brand?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        product.description?.toLowerCase().includes(searchTerm.toLowerCase())
      );
    }
    
    if (categoryFilter) {
      filtered = filtered.filter(product => product.categoryId === categoryFilter);
    }
    
    if (brandFilter) {
      filtered = filtered.filter(product => product.brand === brandFilter);
    }
    
    setFilteredProducts(filtered);
  };

  const handleOpenDialog = (product = null) => {
    if (product) {
      setEditingProduct(product.id);
      setFormData({
        name: product.name || '',
        brand: product.brand || '',
        categoryId: product.categoryId || '',
        subcategoryId: product.subcategoryId || '',
        description: product.description || '',
        keywords: product.keywords || [],
        images: product.images || [],
        availableVariables: product.availableVariables || {},
        isActive: product.isActive !== false
      });
      // Load subcategories for existing product
      if (product.categoryId) {
        loadSubcategories(product.categoryId);
      }
    } else {
      setEditingProduct(null);
      setFormData({
        name: '',
        brand: '',
        categoryId: '',
        subcategoryId: '',
        description: '',
        keywords: [],
        images: [],
        availableVariables: {},
        isActive: true
      });
      setSubcategories([]);
    }
    setUploadedImages([]);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setEditingProduct(null);
    setUploadedImages([]);
  };

  const handleImageUpload = async (event) => {
    const files = Array.from(event.target.files);
    if (files.length === 0) return;

    try {
      const uploadedUrls = [];
      
      for (const file of files) {
        const fileExtension = file.name.split('.').pop();
        const fileName = `products/${Date.now()}_${Math.random().toString(36).substr(2, 9)}.${fileExtension}`;
        const storageRef = ref(storage, fileName);
        
        const snapshot = await uploadBytes(storageRef, file);
        const downloadURL = await getDownloadURL(snapshot.ref);
        uploadedUrls.push(downloadURL);
      }
      
      // Store uploaded URLs in state
      setUploadedImages(prev => [...prev, ...uploadedUrls]);
      
      // Also add to form data
      setFormData(prev => ({
        ...prev,
        images: [...(prev.images || []), ...uploadedUrls]
      }));

      console.log('Images uploaded successfully:', uploadedUrls);
    } catch (error) {
      console.error('Error uploading images:', error);
      alert('Error uploading images: ' + error.message);
    }
  };

  const removeImage = (indexToRemove) => {
    setFormData(prev => ({
      ...prev,
      images: prev.images.filter((_, index) => index !== indexToRemove)
    }));
  };

  const handleCategoryChange = (categoryId) => {
    setFormData(prev => ({
      ...prev,
      categoryId,
      subcategoryId: '' // Reset subcategory when category changes
    }));
  };

  const handleSave = async () => {
    try {
      // Ensure images from uploads are included
      const productData = {
        ...formData,
        images: formData.images || [],
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email
      };

      console.log('Saving product with data:', productData);

      if (editingProduct) {
        await updateDoc(doc(db, 'master_products', editingProduct), productData);
        console.log('Product updated successfully');
      } else {
        productData.createdAt = serverTimestamp();
        productData.createdBy = adminData.email;
        await addDoc(collection(db, 'master_products'), productData);
        console.log('Product created successfully');
      }

      handleCloseDialog();
      loadProducts();
    } catch (error) {
      console.error('Error saving product:', error);
      alert('Error saving product: ' + error.message);
    }
  };

  const handleDelete = async (productId) => {
    if (window.confirm('Are you sure you want to delete this product?')) {
      try {
        await deleteDoc(doc(db, 'master_products', productId));
        loadProducts();
      } catch (error) {
        console.error('Error deleting product:', error);
      }
    }
  };

  const toggleProductStatus = async (product) => {
    try {
      await updateDoc(doc(db, 'master_products', product.id), {
        isActive: !product.isActive,
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email
      });
      loadProducts();
    } catch (error) {
      console.error('Error updating product status:', error);
    }
  };

  const getCategoryName = (categoryId) => {
    const category = categories.find(c => c.id === categoryId);
    return category?.name || category?.category || categoryId || 'Unknown Category';
  };

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Master Products</Typography>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={() => handleOpenDialog()}
        >
          Add Product
        </Button>
      </Box>

      <Alert severity="info" sx={{ mb: 3 }}>
        Master products are managed centrally and available to all countries. 
        Businesses worldwide can create price listings based on these products.
        Only item categories are available for products.
      </Alert>

      {/* Filters */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} md={4}>
              <TextField
                fullWidth
                placeholder="Search products..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <Search sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Category</InputLabel>
                <Select
                  value={categoryFilter}
                  onChange={(e) => setCategoryFilter(e.target.value)}
                >
                  <MenuItem value="">All Categories</MenuItem>
                  {categories.map(category => (
                    <MenuItem key={category.id} value={category.id}>
                      {category.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={3}>
              <FormControl fullWidth>
                <InputLabel>Brand</InputLabel>
                <Select
                  value={brandFilter}
                  onChange={(e) => setBrandFilter(e.target.value)}
                >
                  <MenuItem value="">All Brands</MenuItem>
                  {brands.map(brand => (
                    <MenuItem key={brand.id} value={brand.name || brand.brandName}>
                      {brand.name || brand.brandName}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} md={2}>
              <Typography variant="body2" color="text.secondary">
                {filteredProducts.length} of {products.length} products
              </Typography>
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      {/* Products Table */}
      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Product</TableCell>
              <TableCell>Category</TableCell>
              <TableCell>Brand</TableCell>
              <TableCell>Variables</TableCell>
              <TableCell>Status</TableCell>
              <TableCell align="right">Actions</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {filteredProducts.map((product) => (
              <TableRow key={product.id}>
                <TableCell>
                  <Box display="flex" alignItems="center" gap={2}>
                    {product.images && product.images.length > 0 ? (
                      <Avatar 
                        src={product.images[0]} 
                        variant="rounded"
                        sx={{ width: 48, height: 48 }}
                      />
                    ) : (
                      <Avatar 
                        variant="rounded"
                        sx={{ width: 48, height: 48 }}
                      >
                        {product.name?.charAt(0)}
                      </Avatar>
                    )}
                    <Box>
                      <Typography variant="subtitle2">{product.name}</Typography>
                      <Typography variant="body2" color="text.secondary">
                        {product.description?.substring(0, 60)}...
                      </Typography>
                    </Box>
                  </Box>
                </TableCell>
                <TableCell>
                  <Chip 
                    label={getCategoryName(product.categoryId)} 
                    size="small" 
                    variant="outlined"
                  />
                </TableCell>
                <TableCell>{product.brand || '-'}</TableCell>
                <TableCell>
                  {product.availableVariables && Object.keys(product.availableVariables).length > 0 ? (
                    <Chip 
                      label={`${Object.keys(product.availableVariables).length} variables`}
                      size="small"
                      color="primary"
                    />
                  ) : (
                    <Chip label="No variables" size="small" />
                  )}
                </TableCell>
                <TableCell>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={product.isActive !== false}
                        onChange={() => toggleProductStatus(product)}
                        size="small"
                      />
                    }
                    label={product.isActive !== false ? 'Active' : 'Inactive'}
                  />
                </TableCell>
                <TableCell align="right">
                  <IconButton 
                    size="small" 
                    onClick={() => handleOpenDialog(product)}
                    color="primary"
                  >
                    <Edit />
                  </IconButton>
                  <IconButton 
                    size="small" 
                    onClick={() => handleDelete(product.id)}
                    color="error"
                  >
                    <Delete />
                  </IconButton>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {filteredProducts.length === 0 && !loading && (
        <Box textAlign="center" py={4}>
          <Typography variant="h6" color="text.secondary" gutterBottom>
            No products found
          </Typography>
          <Typography variant="body2" color="text.secondary" mb={2}>
            {products.length === 0 ? 
              'Create your first master product to get started' :
              'Try adjusting your search criteria'
            }
          </Typography>
          {products.length === 0 && (
            <Button variant="contained" startIcon={<Add />} onClick={() => handleOpenDialog()}>
              Add First Product
            </Button>
          )}
        </Box>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingProduct ? 'Edit Product' : 'Add Product'}
        </DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={3} pt={2}>
            <TextField
              fullWidth
              label="Product Name"
              value={formData.name}
              onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />
            
            <FormControl fullWidth>
              <InputLabel>Brand</InputLabel>
              <Select
                value={formData.brand}
                onChange={(e) => setFormData(prev => ({ ...prev, brand: e.target.value }))}
              >
                <MenuItem value="">
                  <em>Select Brand (Optional)</em>
                </MenuItem>
                {brands.map(brand => (
                  <MenuItem key={brand.id} value={brand.name || brand.brandName}>
                    {brand.name || brand.brandName}
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth required>
                  <InputLabel>Category</InputLabel>
                  <Select
                    value={formData.categoryId}
                    onChange={(e) => handleCategoryChange(e.target.value)}
                  >
                    {categories.map(category => (
                      <MenuItem key={category.id} value={category.id}>
                        {category.name || category.category}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth disabled={!formData.categoryId}>
                  <InputLabel>Subcategory</InputLabel>
                  <Select
                    value={formData.subcategoryId}
                    onChange={(e) => setFormData(prev => ({ ...prev, subcategoryId: e.target.value }))}
                  >
                    <MenuItem value="">No subcategory</MenuItem>
                    {subcategories.map(subcategory => (
                      <MenuItem key={subcategory.id} value={subcategory.id}>
                        {subcategory.name || subcategory.subcategory}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
            </Grid>

            <TextField
              fullWidth
              multiline
              rows={3}
              label="Description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
            />

            <TextField
              fullWidth
              label="Keywords (comma-separated)"
              value={Array.isArray(formData.keywords) ? formData.keywords.join(', ') : ''}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                keywords: e.target.value.split(',').map(k => k.trim()).filter(k => k)
              }))}
              placeholder="smartphone, electronics, apple"
            />

            <Box>
              <Typography variant="subtitle1" gutterBottom>
                Product Images
              </Typography>
              <input
                accept="image/*"
                style={{ display: 'none' }}
                id="image-upload"
                multiple
                type="file"
                onChange={handleImageUpload}
              />
              <label htmlFor="image-upload">
                <Button
                  variant="outlined"
                  component="span"
                  startIcon={<PhotoCamera />}
                  sx={{ mb: 2 }}
                >
                  Upload Images
                </Button>
              </label>
              
              {/* Display uploaded images */}
              {formData.images && formData.images.length > 0 && (
                <ImageList sx={{ width: '100%', height: 200 }} cols={4} rowHeight={160}>
                  {formData.images.map((image, index) => (
                    <ImageListItem key={index}>
                      <img
                        src={image}
                        alt={`Product ${index + 1}`}
                        loading="lazy"
                        style={{ objectFit: 'cover' }}
                      />
                      <IconButton
                        sx={{
                          position: 'absolute',
                          top: 5,
                          right: 5,
                          bgcolor: 'rgba(255,255,255,0.8)',
                          '&:hover': { bgcolor: 'rgba(255,255,255,0.9)' }
                        }}
                        size="small"
                        onClick={() => removeImage(index)}
                      >
                        <Close fontSize="small" />
                      </IconButton>
                    </ImageListItem>
                  ))}
                </ImageList>
              )}
            </Box>

            <TextField
              fullWidth
              multiline
              rows={4}
              label="Available Variables (JSON)"
              value={formData.availableVariables}
              onChange={(e) => setFormData(prev => ({ ...prev, availableVariables: e.target.value }))}
              placeholder='{"color": ["Red", "Blue", "Green"], "size": ["Small", "Medium", "Large"]}'
              helperText="Define product variations in JSON format for mobile app variable selection"
            />

            <FormControlLabel
              control={
                <Switch
                  checked={formData.isActive}
                  onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                />
              }
              label="Active (visible to businesses)"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button 
            onClick={handleSave} 
            variant="contained"
            disabled={!formData.name || !formData.categoryId}
          >
            {editingProduct ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Products;
