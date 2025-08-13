import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Card,
  CardContent,
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
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  IconButton,
  Switch,
  FormControlLabel
} from '@mui/material';
import { 
  Add, 
  Edit, 
  Delete, 
  Category as CategoryIcon,
  ShoppingCart,
  Build
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
  where 
} from 'firebase/firestore';
import { db } from '../firebase/config';
import { useAuth } from '../contexts/AuthContext';

const Categories = () => {
  const { adminData } = useAuth();
  const [categories, setCategories] = useState([]);
  const [subcategories, setSubcategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [openDialog, setOpenDialog] = useState(false);
  const [openSubcategoryDialog, setOpenSubcategoryDialog] = useState(false);
  const [editingCategory, setEditingCategory] = useState(null);
  const [editingSubcategory, setEditingSubcategory] = useState(null);
  const [categoryFormData, setCategoryFormData] = useState({
    name: '',
    description: '',
    applicableFor: 'Item',
    isActive: true
  });
  const [subcategoryFormData, setSubcategoryFormData] = useState({
    name: '',
    description: '',
    categoryId: '',
    isActive: true
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      await Promise.all([loadCategories(), loadSubcategories()]);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCategories = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'categories'));
      const categoriesData = [];
      snapshot.forEach(doc => {
        categoriesData.push({ id: doc.id, ...doc.data() });
      });
      setCategories(categoriesData.sort((a, b) => a.name.localeCompare(b.name)));
    } catch (error) {
      console.error('Error loading categories:', error);
    }
  };

  const loadSubcategories = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'subcategories'));
      const subcategoriesData = [];
      snapshot.forEach(doc => {
        subcategoriesData.push({ id: doc.id, ...doc.data() });
      });
      setSubcategories(subcategoriesData.sort((a, b) => a.name.localeCompare(b.name)));
    } catch (error) {
      console.error('Error loading subcategories:', error);
    }
  };

  const handleOpenCategoryDialog = (category = null) => {
    if (category) {
      setEditingCategory(category.id);
      setCategoryFormData({
        name: category.name || '',
        description: category.description || '',
        applicableFor: category.applicableFor || 'Item',
        isActive: category.isActive !== false
      });
    } else {
      setEditingCategory(null);
      setCategoryFormData({
        name: '',
        description: '',
        applicableFor: 'Item',
        isActive: true
      });
    }
    setOpenDialog(true);
  };

  const handleOpenSubcategoryDialog = (subcategory = null) => {
    if (subcategory) {
      setEditingSubcategory(subcategory.id);
      setSubcategoryFormData({
        name: subcategory.name || '',
        description: subcategory.description || '',
        categoryId: subcategory.categoryId || '',
        isActive: subcategory.isActive !== false
      });
    } else {
      setEditingSubcategory(null);
      setSubcategoryFormData({
        name: '',
        description: '',
        categoryId: '',
        isActive: true
      });
    }
    setOpenSubcategoryDialog(true);
  };

  const handleSaveCategory = async () => {
    try {
      const categoryData = {
        ...categoryFormData,
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email
      };

      if (editingCategory) {
        await updateDoc(doc(db, 'categories', editingCategory), categoryData);
      } else {
        categoryData.createdAt = serverTimestamp();
        categoryData.createdBy = adminData.email;
        await addDoc(collection(db, 'categories'), categoryData);
      }

      setOpenDialog(false);
      loadCategories();
    } catch (error) {
      console.error('Error saving category:', error);
      alert('Error saving category: ' + error.message);
    }
  };

  const handleSaveSubcategory = async () => {
    try {
      const subcategoryData = {
        ...subcategoryFormData,
        updatedAt: serverTimestamp(),
        updatedBy: adminData.email
      };

      if (editingSubcategory) {
        await updateDoc(doc(db, 'subcategories', editingSubcategory), subcategoryData);
      } else {
        subcategoryData.createdAt = serverTimestamp();
        subcategoryData.createdBy = adminData.email;
        await addDoc(collection(db, 'subcategories'), subcategoryData);
      }

      setOpenSubcategoryDialog(false);
      loadSubcategories();
    } catch (error) {
      console.error('Error saving subcategory:', error);
      alert('Error saving subcategory: ' + error.message);
    }
  };

  const handleDeleteCategory = async (categoryId, categoryName) => {
    if (!confirm(`Are you sure you want to delete "${categoryName}"? This action cannot be undone.`)) {
      return;
    }

    try {
      await deleteDoc(doc(db, 'categories', categoryId));
      loadCategories();
    } catch (error) {
      console.error('Error deleting category:', error);
      alert('Error deleting category: ' + error.message);
    }
  };

  const getCategoryName = (categoryId) => {
    const category = categories.find(cat => cat.id === categoryId);
    return category ? category.name : categoryId;
  };

  const getSubcategoriesForCategory = (categoryId) => {
    return subcategories.filter(sub => sub.categoryId === categoryId);
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Categories & Subcategories
      </Typography>
      
      <Alert severity="info" sx={{ mb: 3 }}>
        <strong>Category Management:</strong> Categories are used globally. 
        "Item" categories are for products, "Service" categories are for service requests.
      </Alert>

      {loading && <LinearProgress sx={{ mb: 2 }} />}

      <Grid container spacing={3}>
        {/* Categories Section */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Box display="flex" alignItems="center" gap={2}>
                  <CategoryIcon />
                  <Typography variant="h6">Categories ({categories.length})</Typography>
                </Box>
                <Button
                  variant="contained"
                  startIcon={<Add />}
                  onClick={() => handleOpenCategoryDialog()}
                >
                  Add Category
                </Button>
              </Box>

              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Name</TableCell>
                      <TableCell>Type</TableCell>
                      <TableCell>Subcategories</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {categories.map((category) => (
                      <TableRow key={category.id}>
                        <TableCell>
                          <Box>
                            <Typography variant="subtitle2">{category.name}</Typography>
                            <Typography variant="caption" color="text.secondary">
                              {category.description}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip 
                            icon={category.applicableFor === 'Item' ? <ShoppingCart /> : <Build />}
                            label={category.applicableFor}
                            size="small"
                            color={category.applicableFor === 'Item' ? 'primary' : 'secondary'}
                          />
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label={getSubcategoriesForCategory(category.id).length}
                            size="small"
                            color="default"
                          />
                        </TableCell>
                        <TableCell>
                          <IconButton 
                            size="small" 
                            onClick={() => handleOpenCategoryDialog(category)}
                            color="primary"
                          >
                            <Edit />
                          </IconButton>
                          <IconButton 
                            size="small" 
                            onClick={() => handleDeleteCategory(category.id, category.name)}
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

              {categories.length === 0 && !loading && (
                <Box textAlign="center" py={4}>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    No categories found
                  </Typography>
                  <Button variant="outlined" startIcon={<Add />} onClick={() => handleOpenCategoryDialog()}>
                    Create First Category
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Subcategories Section */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Box display="flex" justifyContent="space-between" alignItems="center" mb={2}>
                <Box display="flex" alignItems="center" gap={2}>
                  <CategoryIcon />
                  <Typography variant="h6">Subcategories ({subcategories.length})</Typography>
                </Box>
                <Button
                  variant="contained"
                  startIcon={<Add />}
                  onClick={() => handleOpenSubcategoryDialog()}
                  disabled={categories.length === 0}
                >
                  Add Subcategory
                </Button>
              </Box>

              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Name</TableCell>
                      <TableCell>Category</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {subcategories.map((subcategory) => (
                      <TableRow key={subcategory.id}>
                        <TableCell>
                          <Box>
                            <Typography variant="subtitle2">{subcategory.name}</Typography>
                            <Typography variant="caption" color="text.secondary">
                              {subcategory.description}
                            </Typography>
                          </Box>
                        </TableCell>
                        <TableCell>
                          <Chip 
                            label={getCategoryName(subcategory.categoryId)}
                            size="small"
                            color="primary"
                            variant="outlined"
                          />
                        </TableCell>
                        <TableCell>
                          <IconButton 
                            size="small" 
                            onClick={() => handleOpenSubcategoryDialog(subcategory)}
                            color="primary"
                          >
                            <Edit />
                          </IconButton>
                          <IconButton 
                            size="small" 
                            onClick={() => handleDeleteCategory(subcategory.id, subcategory.name)}
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

              {subcategories.length === 0 && !loading && (
                <Box textAlign="center" py={4}>
                  <Typography variant="body2" color="text.secondary" mb={2}>
                    No subcategories found
                  </Typography>
                  <Button 
                    variant="outlined" 
                    startIcon={<Add />} 
                    onClick={() => handleOpenSubcategoryDialog()}
                    disabled={categories.length === 0}
                  >
                    Create First Subcategory
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Category Dialog */}
      <Dialog open={openDialog} onClose={() => setOpenDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingCategory ? 'Edit Category' : 'Add Category'}
        </DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={3} pt={2}>
            <TextField
              fullWidth
              label="Category Name"
              value={categoryFormData.name}
              onChange={(e) => setCategoryFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />

            <TextField
              fullWidth
              multiline
              rows={2}
              label="Description"
              value={categoryFormData.description}
              onChange={(e) => setCategoryFormData(prev => ({ ...prev, description: e.target.value }))}
            />

            <FormControl fullWidth>
              <InputLabel>Applicable For</InputLabel>
              <Select
                value={categoryFormData.applicableFor}
                onChange={(e) => setCategoryFormData(prev => ({ ...prev, applicableFor: e.target.value }))}
              >
                <MenuItem value="Item">Item (Products)</MenuItem>
                <MenuItem value="Service">Service (Requests)</MenuItem>
              </Select>
            </FormControl>

            <FormControlLabel
              control={
                <Switch
                  checked={categoryFormData.isActive}
                  onChange={(e) => setCategoryFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                />
              }
              label="Active"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDialog(false)}>Cancel</Button>
          <Button 
            onClick={handleSaveCategory} 
            variant="contained"
            disabled={!categoryFormData.name}
          >
            {editingCategory ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Subcategory Dialog */}
      <Dialog open={openSubcategoryDialog} onClose={() => setOpenSubcategoryDialog(false)} maxWidth="sm" fullWidth>
        <DialogTitle>
          {editingSubcategory ? 'Edit Subcategory' : 'Add Subcategory'}
        </DialogTitle>
        <DialogContent>
          <Box display="flex" flexDirection="column" gap={3} pt={2}>
            <FormControl fullWidth>
              <InputLabel>Parent Category</InputLabel>
              <Select
                value={subcategoryFormData.categoryId}
                onChange={(e) => setSubcategoryFormData(prev => ({ ...prev, categoryId: e.target.value }))}
                required
              >
                {categories.map(category => (
                  <MenuItem key={category.id} value={category.id}>
                    {category.name} ({category.applicableFor})
                  </MenuItem>
                ))}
              </Select>
            </FormControl>

            <TextField
              fullWidth
              label="Subcategory Name"
              value={subcategoryFormData.name}
              onChange={(e) => setSubcategoryFormData(prev => ({ ...prev, name: e.target.value }))}
              required
            />

            <TextField
              fullWidth
              multiline
              rows={2}
              label="Description"
              value={subcategoryFormData.description}
              onChange={(e) => setSubcategoryFormData(prev => ({ ...prev, description: e.target.value }))}
            />

            <FormControlLabel
              control={
                <Switch
                  checked={subcategoryFormData.isActive}
                  onChange={(e) => setSubcategoryFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                />
              }
              label="Active"
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenSubcategoryDialog(false)}>Cancel</Button>
          <Button 
            onClick={handleSaveSubcategory} 
            variant="contained"
            disabled={!subcategoryFormData.name || !subcategoryFormData.categoryId}
          >
            {editingSubcategory ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Categories;
