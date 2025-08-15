import React, { useState, useEffect } from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  MenuItem,
  Grid,
  Chip,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper,
  IconButton,
  Alert,
  CircularProgress,
  FormControl,
  InputLabel,
  Select,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Tab,
  Tabs
} from '@mui/material';
import {
  Add,
  Edit,
  Delete,
  ExpandMore,
  Visibility,
  Payment,
  Group,
  TrendingUp
} from '@mui/icons-material';
import { 
  collection, 
  getDocs, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  query, 
  where, 
  orderBy 
} from 'firebase/firestore';
import { db } from '../firebase/config';
import { useAuth } from '../contexts/AuthContext';
import useCountryFilter from '../hooks/useCountryFilter';

const CURRENCIES = {
  'LK': { symbol: 'Rs', code: 'LKR' },
  'IN': { symbol: '₹', code: 'INR' },
  'US': { symbol: '$', code: 'USD' },
  'GB': { symbol: '£', code: 'GBP' },
  'AU': { symbol: 'A$', code: 'AUD' },
  'CA': { symbol: 'C$', code: 'CAD' },
  'SG': { symbol: 'S$', code: 'SGD' },
  'MY': { symbol: 'RM', code: 'MYR' },
  'TH': { symbol: '฿', code: 'THB' },
  'PH': { symbol: '₱', code: 'PHP' },
  'ID': { symbol: 'Rp', code: 'IDR' },
  'VN': { symbol: '₫', code: 'VND' },
};

const SUBSCRIPTION_TYPES = [
  { value: 'rider', label: 'Rider' },
  { value: 'business', label: 'Business' }
];

const SUBSCRIPTION_PLANS = [
  { value: 'monthly', label: 'Monthly Plan' },
  { value: 'yearly', label: 'Yearly Plan' },
  { value: 'pay_per_click', label: 'Pay Per Click' }
];

const Subscriptions = () => {
  const { user, adminData, userRole, userCountry } = useAuth();
  const { isSuperAdmin, countries } = useCountryFilter();
  const [subscriptionPlans, setSubscriptionPlans] = useState([]);
  const [userSubscriptions, setUserSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [viewDialog, setViewDialog] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [tabValue, setTabValue] = useState(0);
  const [error, setError] = useState('');

  // Form states
  const [formData, setFormData] = useState({
    name: '',
    type: 'rider',
    planType: 'monthly',
    description: '',
    isActive: true,
    countries: [],
    pricingByCountry: {},
    features: [],
    limitations: {}
  });

  // Check permissions
  const hasSubscriptionPermission = isSuperAdmin || adminData?.permissions?.subscriptionManagement;

  useEffect(() => {
    if (hasSubscriptionPermission) {
      fetchSubscriptionPlans();
      fetchUserSubscriptions();
    }
  }, [hasSubscriptionPermission, userCountry]);

  const fetchSubscriptionPlans = async () => {
    try {
      setLoading(true);
      const plansRef = collection(db, 'subscription_plans');
      let plansQuery = plansRef;

      // Country filtering for non-super admins
      if (!isSuperAdmin && userCountry) {
        plansQuery = query(plansRef, where('countries', 'array-contains', userCountry));
      }

      const snapshot = await getDocs(plansQuery);
      const plans = [];
      
      snapshot.forEach((doc) => {
        plans.push({ id: doc.id, ...doc.data() });
      });

      setSubscriptionPlans(plans);
    } catch (error) {
      console.error('Error fetching subscription plans:', error);
      setError('Failed to fetch subscription plans');
    } finally {
      setLoading(false);
    }
  };

  const fetchUserSubscriptions = async () => {
    try {
      const subscriptionsRef = collection(db, 'user_subscriptions');
      let subscriptionsQuery = subscriptionsRef;

      // Country filtering for non-super admins
      if (!isSuperAdmin && userCountry) {
        subscriptionsQuery = query(subscriptionsRef, where('countryCode', '==', userCountry));
      }

      const snapshot = await getDocs(subscriptionsQuery);
      const subscriptions = [];
      
      snapshot.forEach((doc) => {
        subscriptions.push({ id: doc.id, ...doc.data() });
      });

      setUserSubscriptions(subscriptions);
    } catch (error) {
      console.error('Error fetching user subscriptions:', error);
    }
  };

  const handleSubmit = async () => {
    try {
      setError('');
      
      // Validate form
      if (!formData.name || !formData.type || !formData.planType) {
        setError('Please fill in all required fields');
        return;
      }

      // Ensure country filtering for non-super admins
      const countriesToSave = isSuperAdmin ? formData.countries : [userCountry];
      
      const planData = {
        ...formData,
        countries: countriesToSave,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: user.email,
        createdByCountry: userCountry
      };

      if (selectedPlan) {
        // Update existing plan
        await updateDoc(doc(db, 'subscription_plans', selectedPlan.id), {
          ...planData,
          createdAt: selectedPlan.createdAt // Preserve original creation date
        });
      } else {
        // Create new plan
        await addDoc(collection(db, 'subscription_plans'), planData);
      }

      await fetchSubscriptionPlans();
      handleCloseDialog();
    } catch (error) {
      console.error('Error saving subscription plan:', error);
      setError('Failed to save subscription plan');
    }
  };

  const handleEdit = (plan) => {
    setSelectedPlan(plan);
    setFormData({
      name: plan.name || '',
      type: plan.type || 'rider',
      planType: plan.planType || 'monthly',
      description: plan.description || '',
      isActive: plan.isActive !== undefined ? plan.isActive : true,
      countries: plan.countries || [],
      pricingByCountry: plan.pricingByCountry || {},
      features: plan.features || [],
      limitations: plan.limitations || {}
    });
    setDialogOpen(true);
  };

  const handleDelete = async (planId) => {
    if (window.confirm('Are you sure you want to delete this subscription plan?')) {
      try {
        await deleteDoc(doc(db, 'subscription_plans', planId));
        await fetchSubscriptionPlans();
      } catch (error) {
        console.error('Error deleting subscription plan:', error);
        setError('Failed to delete subscription plan');
      }
    }
  };

  const handleView = (plan) => {
    setSelectedPlan(plan);
    setViewDialog(true);
  };

  const handleCloseDialog = () => {
    setDialogOpen(false);
    setViewDialog(false);
    setSelectedPlan(null);
    setFormData({
      name: '',
      type: 'rider',
      planType: 'monthly',
      description: '',
      isActive: true,
      countries: [],
      pricingByCountry: {},
      features: [],
      limitations: {}
    });
    setError('');
  };

  const handlePricingChange = (country, field, value) => {
    setFormData(prev => ({
      ...prev,
      pricingByCountry: {
        ...prev.pricingByCountry,
        [country]: {
          ...prev.pricingByCountry[country],
          [field]: value
        }
      }
    }));
  };

  const formatCurrency = (amount, countryCode) => {
    const currency = CURRENCIES[countryCode] || CURRENCIES['US'];
    return `${currency.symbol}${amount}`;
  };

  const getStatusChip = (isActive) => (
    <Chip 
      label={isActive ? 'Active' : 'Inactive'} 
      color={isActive ? 'success' : 'error'}
      size="small"
    />
  );

  if (!hasSubscriptionPermission) {
    return (
      <Box p={3}>
        <Alert severity="error">
          You don't have permission to access subscription management.
        </Alert>
      </Box>
    );
  }

  return (
    <Box p={3}>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4">Subscription Management</Typography>
        {isSuperAdmin && (
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={() => setDialogOpen(true)}
            disabled={loading}
          >
            Add Subscription Plan
          </Button>
        )}
      </Box>

      {!isSuperAdmin && userCountry && (
        <Alert severity="info" sx={{ mb: 3 }}>
          You can only manage subscription plans for {countries.find(c => c.code === userCountry)?.name || userCountry}.
        </Alert>
      )}

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab label="Subscription Plans" />
          <Tab label="User Subscriptions" />
          <Tab label="Analytics" />
        </Tabs>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {error}
        </Alert>
      )}

      {loading ? (
        <Box display="flex" justifyContent="center" p={4}>
          <CircularProgress />
        </Box>
      ) : (
        <>
          {tabValue === 0 && (
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>Name</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell>Plan Type</TableCell>
                    <TableCell>Countries</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {subscriptionPlans.map((plan) => (
                    <TableRow key={plan.id}>
                      <TableCell>
                        <Typography variant="subtitle2">{plan.name}</Typography>
                        <Typography variant="body2" color="textSecondary">
                          {plan.description?.substring(0, 50)}...
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip label={plan.type} size="small" />
                      </TableCell>
                      <TableCell>
                        <Chip label={plan.planType} variant="outlined" size="small" />
                      </TableCell>
                      <TableCell>
                        <Box display="flex" flexWrap="wrap" gap={0.5}>
                          {plan.countries?.slice(0, 3).map((country) => (
                            <Chip 
                              key={country} 
                              label={country} 
                              size="small" 
                              variant="outlined"
                            />
                          ))}
                          {plan.countries?.length > 3 && (
                            <Chip 
                              label={`+${plan.countries.length - 3}`} 
                              size="small" 
                              variant="outlined"
                            />
                          )}
                        </Box>
                      </TableCell>
                      <TableCell>{getStatusChip(plan.isActive)}</TableCell>
                      <TableCell>
                        <IconButton onClick={() => handleView(plan)} size="small">
                          <Visibility />
                        </IconButton>
                        {(isSuperAdmin || plan.createdByCountry === userCountry) && (
                          <>
                            <IconButton onClick={() => handleEdit(plan)} size="small">
                              <Edit />
                            </IconButton>
                            {isSuperAdmin && (
                              <IconButton 
                                onClick={() => handleDelete(plan.id)} 
                                size="small"
                                color="error"
                              >
                                <Delete />
                              </IconButton>
                            )}
                          </>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}

          {tabValue === 1 && (
            <TableContainer component={Paper}>
              <Table>
                <TableHead>
                  <TableRow>
                    <TableCell>User ID</TableCell>
                    <TableCell>Plan Type</TableCell>
                    <TableCell>Status</TableCell>
                    <TableCell>Country</TableCell>
                    <TableCell>Expires</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {userSubscriptions.map((subscription) => (
                    <TableRow key={subscription.id}>
                      <TableCell>{subscription.userId}</TableCell>
                      <TableCell>
                        <Chip label={subscription.type} size="small" />
                      </TableCell>
                      <TableCell>
                        <Chip 
                          label={subscription.status} 
                          color={subscription.status === 'active' ? 'success' : 'warning'}
                          size="small" 
                        />
                      </TableCell>
                      <TableCell>{subscription.countryCode}</TableCell>
                      <TableCell>
                        {subscription.subscriptionExpiry ? 
                          new Date(subscription.subscriptionExpiry?.toDate()).toLocaleDateString() : 
                          'N/A'
                        }
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          )}

          {tabValue === 2 && (
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Box display="flex" alignItems="center" mb={2}>
                      <Group color="primary" sx={{ mr: 1 }} />
                      <Typography variant="h6">Total Subscriptions</Typography>
                    </Box>
                    <Typography variant="h3">{userSubscriptions.length}</Typography>
                  </CardContent>
                </Card>
              </Grid>
              <Grid item xs={12} md={6}>
                <Card>
                  <CardContent>
                    <Box display="flex" alignItems="center" mb={2}>
                      <TrendingUp color="primary" sx={{ mr: 1 }} />
                      <Typography variant="h6">Active Plans</Typography>
                    </Box>
                    <Typography variant="h3">
                      {subscriptionPlans.filter(p => p.isActive).length}
                    </Typography>
                  </CardContent>
                </Card>
              </Grid>
            </Grid>
          )}
        </>
      )}

      {/* Add/Edit Dialog */}
      <Dialog open={dialogOpen} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {selectedPlan ? 'Edit Subscription Plan' : 'Add Subscription Plan'}
        </DialogTitle>
        <DialogContent>
          <Box mt={2}>
            <Grid container spacing={2}>
              <Grid item xs={12} md={6}>
                <TextField
                  fullWidth
                  label="Plan Name"
                  value={formData.name}
                  onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                  required
                />
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Type</InputLabel>
                  <Select
                    value={formData.type}
                    onChange={(e) => setFormData(prev => ({ ...prev, type: e.target.value }))}
                    label="Type"
                  >
                    {SUBSCRIPTION_TYPES.map((type) => (
                      <MenuItem key={type.value} value={type.value}>
                        {type.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControl fullWidth>
                  <InputLabel>Plan Type</InputLabel>
                  <Select
                    value={formData.planType}
                    onChange={(e) => setFormData(prev => ({ ...prev, planType: e.target.value }))}
                    label="Plan Type"
                  >
                    {SUBSCRIPTION_PLANS.map((plan) => (
                      <MenuItem key={plan.value} value={plan.value}>
                        {plan.label}
                      </MenuItem>
                    ))}
                  </Select>
                </FormControl>
              </Grid>
              <Grid item xs={12} md={6}>
                <FormControlLabel
                  control={
                    <Switch
                      checked={formData.isActive}
                      onChange={(e) => setFormData(prev => ({ ...prev, isActive: e.target.checked }))}
                    />
                  }
                  label="Active"
                />
              </Grid>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  label="Description"
                  multiline
                  rows={3}
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                />
              </Grid>
              
              {/* Country Selection - Super Admin only */}
              {isSuperAdmin && (
                <Grid item xs={12}>
                  <FormControl fullWidth>
                    <InputLabel>Countries</InputLabel>
                    <Select
                      multiple
                      value={formData.countries}
                      onChange={(e) => setFormData(prev => ({ ...prev, countries: e.target.value }))}
                      label="Countries"
                      renderValue={(selected) => (
                        <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                          {selected.map((value) => (
                            <Chip key={value} label={value} />
                          ))}
                        </Box>
                      )}
                    >
                      {countries.map((country) => (
                        <MenuItem key={country.code} value={country.code}>
                          {country.name} ({country.code})
                        </MenuItem>
                      ))}
                    </Select>
                  </FormControl>
                </Grid>
              )}
            </Grid>

            {/* Pricing Configuration */}
            <Box mt={3}>
              <Typography variant="h6" gutterBottom>
                Pricing Configuration
              </Typography>
              {(isSuperAdmin ? formData.countries : [userCountry]).map((country) => (
                <Accordion key={country}>
                  <AccordionSummary expandIcon={<ExpandMore />}>
                    <Typography>
                      {countries.find(c => c.code === country)?.name || country} Pricing
                    </Typography>
                  </AccordionSummary>
                  <AccordionDetails>
                    <Grid container spacing={2}>
                      <Grid item xs={6}>
                        <TextField
                          fullWidth
                          label="Monthly Price"
                          type="number"
                          value={formData.pricingByCountry[country]?.monthlyPrice || ''}
                          onChange={(e) => handlePricingChange(country, 'monthlyPrice', parseFloat(e.target.value) || 0)}
                          InputProps={{
                            startAdornment: CURRENCIES[country]?.symbol || '$'
                          }}
                        />
                      </Grid>
                      <Grid item xs={6}>
                        <TextField
                          fullWidth
                          label="Yearly Price"
                          type="number"
                          value={formData.pricingByCountry[country]?.yearlyPrice || ''}
                          onChange={(e) => handlePricingChange(country, 'yearlyPrice', parseFloat(e.target.value) || 0)}
                          InputProps={{
                            startAdornment: CURRENCIES[country]?.symbol || '$'
                          }}
                        />
                      </Grid>
                      <Grid item xs={12}>
                        <TextField
                          fullWidth
                          label="Click Rate"
                          type="number"
                          value={formData.pricingByCountry[country]?.clickRate || ''}
                          onChange={(e) => handlePricingChange(country, 'clickRate', parseFloat(e.target.value) || 0)}
                          InputProps={{
                            startAdornment: CURRENCIES[country]?.symbol || '$',
                            endAdornment: 'per click'
                          }}
                        />
                      </Grid>
                    </Grid>
                  </AccordionDetails>
                </Accordion>
              ))}
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          <Button onClick={handleSubmit} variant="contained">
            {selectedPlan ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* View Dialog */}
      <Dialog open={viewDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>Subscription Plan Details</DialogTitle>
        <DialogContent>
          {selectedPlan && (
            <Box mt={2}>
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <Typography variant="h6">{selectedPlan.name}</Typography>
                  <Typography variant="body2" color="textSecondary" gutterBottom>
                    {selectedPlan.description}
                  </Typography>
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Type:</Typography>
                  <Chip label={selectedPlan.type} size="small" />
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Plan Type:</Typography>
                  <Chip label={selectedPlan.planType} variant="outlined" size="small" />
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Status:</Typography>
                  {getStatusChip(selectedPlan.isActive)}
                </Grid>
                <Grid item xs={6}>
                  <Typography variant="subtitle2">Countries:</Typography>
                  <Box display="flex" flexWrap="wrap" gap={0.5} mt={1}>
                    {selectedPlan.countries?.map((country) => (
                      <Chip key={country} label={country} size="small" variant="outlined" />
                    ))}
                  </Box>
                </Grid>
              </Grid>

              {/* Pricing Details */}
              {selectedPlan.pricingByCountry && (
                <Box mt={3}>
                  <Typography variant="h6" gutterBottom>Pricing Details</Typography>
                  {Object.entries(selectedPlan.pricingByCountry).map(([country, pricing]) => (
                    <Card key={country} sx={{ mb: 2 }}>
                      <CardContent>
                        <Typography variant="subtitle1" gutterBottom>
                          {countries.find(c => c.code === country)?.name || country}
                        </Typography>
                        <Grid container spacing={2}>
                          {pricing.monthlyPrice && (
                            <Grid item xs={4}>
                              <Typography variant="body2">Monthly</Typography>
                              <Typography variant="h6">
                                {formatCurrency(pricing.monthlyPrice, country)}
                              </Typography>
                            </Grid>
                          )}
                          {pricing.yearlyPrice && (
                            <Grid item xs={4}>
                              <Typography variant="body2">Yearly</Typography>
                              <Typography variant="h6">
                                {formatCurrency(pricing.yearlyPrice, country)}
                              </Typography>
                            </Grid>
                          )}
                          {pricing.clickRate && (
                            <Grid item xs={4}>
                              <Typography variant="body2">Per Click</Typography>
                              <Typography variant="h6">
                                {formatCurrency(pricing.clickRate, country)}
                              </Typography>
                            </Grid>
                          )}
                        </Grid>
                      </CardContent>
                    </Card>
                  ))}
                </Box>
              )}
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Close</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Subscriptions;
