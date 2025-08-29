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
  Tabs,
  Snackbar
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
import api from '../services/apiClient';
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

// (Removed) Old default subscription plans seeding logic

const Subscriptions = () => {
  const { user, adminData, userRole, userCountry } = useAuth();
  const { isSuperAdmin } = useCountryFilter();
  const [subscriptionPlans, setSubscriptionPlans] = useState([]);
  const [userSubscriptions, setUserSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [viewDialog, setViewDialog] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [tabValue, setTabValue] = useState(0);
  const [error, setError] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  // Super admin country view
  const [viewCountry, setViewCountry] = useState('');
  const [availableCountries, setAvailableCountries] = useState([]);
  // Expose as `countries` for existing JSX usages
  const countries = availableCountries;

  // Pricing dialog states
  const [pricingDialogOpen, setPricingDialogOpen] = useState(false);
  const [selectedPlanForPricing, setSelectedPlanForPricing] = useState(null);
  const [countryPricingData, setCountryPricingData] = useState({
    price: '',
    currency: '',
    currencySymbol: ''
  });

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
      // Load enabled countries for super admin country view
      if (isSuperAdmin) {
        api.get('/countries')
          .then(({ data }) => {
            // Support shapes: array | { data: array } | { items: array }
            const raw = Array.isArray(data) ? data : (Array.isArray(data?.data) ? data.data : (data?.items || []));
            const enabled = raw.filter(c => c.is_active === true || c.isActive === true || c.isEnabled === true);
            setAvailableCountries(enabled.map(c => ({ code: c.code || c.countryCode || c.id, name: c.name || c.title || c.code })));
          })
          .catch(() => {});
      }
      fetchSubscriptionPlans();
      fetchUserSubscriptions();
    }
  }, [hasSubscriptionPermission, userCountry, isSuperAdmin, viewCountry]);

  const fetchSubscriptionPlans = async () => {
    try {
      setLoading(true);
      const params = {};
      if (isSuperAdmin) {
        if (viewCountry) params.country = viewCountry;
      } else if (userCountry) {
        params.country = userCountry;
      }
      const { data } = await api.get('/subscription-plans', { params });
      let plans = Array.isArray(data) ? data : data?.items || [];
      // Client-side filtering for country admins
      if (!isSuperAdmin && userCountry) {
        plans = plans.filter(plan => 
          plan.countries?.includes(userCountry) || 
          (plan.isDefaultPlan && plan.requiresCountryPricing) ||
          (plan.isDefaultPlan && !plan.requiresCountryPricing)
        );
      }
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
      const params = {};
      if (isSuperAdmin) {
        if (viewCountry) params.country = viewCountry;
      } else if (userCountry) {
        params.country = userCountry;
      }
      const { data } = await api.get('/user-subscriptions', { params });
      setUserSubscriptions(Array.isArray(data) ? data : data?.items || []);
    } catch (error) {
      console.error('Error fetching user subscriptions:', error);
    }
  };

  // (Removed) initializeDefaultPlans handler and seeding side-effects

  // Add country pricing to a global plan (Country Admin function)
  const addCountryPricing = async (planId, countryCode, pricing) => {
    if (isSuperAdmin) return; // Only country admins should do this
    
    try {
      console.log('Adding country pricing:', { planId, countryCode, pricing });
      
  const plan = subscriptionPlans.find(p => p.id === planId);
      
      if (!plan) {
        console.error('Plan not found:', planId);
        throw new Error('Plan not found');
      }
      
      console.log('Found plan:', plan);
      
      // Get currency info for the country
      const currency = CURRENCIES[countryCode] || { symbol: '$', code: 'USD' };
      
      const updatedPricingByCountry = {
        ...plan.pricingByCountry,
        [countryCode]: {
          price: pricing.price,
          currency: currency.code,
          currencySymbol: currency.symbol,
          addedBy: user.email,
          addedAt: new Date(),
          approvalStatus: 'pending', // New pricing needs super admin approval
          isActive: false // Not active until approved
        }
      };
      
      const updatedCountries = plan.countries?.includes(countryCode) 
        ? plan.countries 
        : [...(plan.countries || []), countryCode];
      
      console.log('Updating plan with:', {
        pricingByCountry: updatedPricingByCountry,
        countries: updatedCountries
      });
      
      await api.put(`/subscription-plans/${planId}/pricing/${countryCode}`, {
        price: pricing.price
      });
      
      console.log('Successfully updated plan');
      
      // Refresh plans
      fetchSubscriptionPlans();
    } catch (error) {
      console.error('Error adding country pricing:', error);
      throw error; // Re-throw to be caught by the calling function
    }
  };

  // Convert USD price to local currency (simplified conversion)
  const convertPriceToLocalCurrency = (usdPrice, countryCode) => {
    const conversionRates = {
      'LK': 300, // 1 USD = 300 LKR (approximate)
      'IN': 80,  // 1 USD = 80 INR
      'US': 1,   // Base currency
      'GB': 0.8, // 1 USD = 0.8 GBP
      'AU': 1.5, // 1 USD = 1.5 AUD
      'CA': 1.3, // 1 USD = 1.3 CAD
      'SG': 1.4, // 1 USD = 1.4 SGD
      'MY': 4.6, // 1 USD = 4.6 MYR
      'TH': 35,  // 1 USD = 35 THB
      'PH': 55,  // 1 USD = 55 PHP
      'ID': 15000, // 1 USD = 15,000 IDR
      'VN': 24000, // 1 USD = 24,000 VND
    };
    
    const rate = conversionRates[countryCode] || 1;
    return Math.round(usdPrice * rate);
  };

  // Open pricing dialog for country admin
  const handleOpenPricingDialog = (plan) => {
    if (isSuperAdmin) return;
    
    setSelectedPlanForPricing(plan);
    
    // Get currency info for user's country
    const currency = CURRENCIES[userCountry] || { symbol: '$', code: 'USD' };
    
    // Suggest a price based on the default USD price
    const suggestedPrice = plan.defaultPrice ? convertPriceToLocalCurrency(plan.defaultPrice, userCountry) : '';
    
    setCountryPricingData({
      price: suggestedPrice.toString(),
      currency: currency.code,
      currencySymbol: currency.symbol
    });
    
    setPricingDialogOpen(true);
  };

  // Edit existing pricing
  const handleEditPricing = (plan) => {
    if (isSuperAdmin) return;
    
    setSelectedPlanForPricing(plan);
    
    // Get existing pricing data
    const existingPricing = plan.pricingByCountry[userCountry];
    const currency = CURRENCIES[userCountry] || { symbol: '$', code: 'USD' };
    
    setCountryPricingData({
      price: existingPricing.price.toString(),
      currency: currency.code,
      currencySymbol: currency.symbol
    });
    
    setPricingDialogOpen(true);
  };

  // Handle country pricing submission
  const handleCountryPricingSubmit = async () => {
    if (!selectedPlanForPricing || !countryPricingData.price) {
      setError('Please enter a valid price');
      return;
    }
    
    try {
      console.log('Submitting country pricing:', {
        plan: selectedPlanForPricing.id,
        country: userCountry,
        price: countryPricingData.price
      });
      
      await addCountryPricing(selectedPlanForPricing.id, userCountry, {
        price: parseFloat(countryPricingData.price)
      });
      
      setPricingDialogOpen(false);
      setSelectedPlanForPricing(null);
      setCountryPricingData({ price: '', currency: '', currencySymbol: '' });
      setError(''); // Clear any previous errors
      
      // Show success message
      setSnackbar({
        open: true,
        message: `Pricing submitted for ${countryPricingData.currencySymbol}${countryPricingData.price}. Awaiting super admin approval.`,
        severity: 'success'
      });
      
      // Refresh the subscription plans
      await fetchSubscriptionPlans();
    } catch (error) {
      console.error('Failed to add pricing:', error);
      const errorMessage = error.message || 'Failed to add pricing for this country';
      setError(errorMessage);
      setSnackbar({
        open: true,
        message: errorMessage,
        severity: 'error'
      });
    }
  };

  // Super Admin functions for pricing approval
  const handleApprovePricing = async (planId, countryCode) => {
    if (!isSuperAdmin) return;
    
    try {
  const plan = subscriptionPlans.find(p => p.id === planId);
      
      if (!plan || !plan.pricingByCountry[countryCode]) return;
      
      const updatedPricingByCountry = {
        ...plan.pricingByCountry,
        [countryCode]: {
          ...plan.pricingByCountry[countryCode],
          approvalStatus: 'approved',
          approvedBy: user.email,
          approvedAt: new Date(),
          isActive: true
        }
      };
      
  await api.post(`/subscription-plans/${planId}/pricing/${countryCode}/approve`);
      
      setSnackbar({
        open: true,
        message: `Pricing approved for ${countryCode}`,
        severity: 'success'
      });
      
      fetchSubscriptionPlans();
    } catch (error) {
      console.error('Error approving pricing:', error);
      setSnackbar({
        open: true,
        message: 'Failed to approve pricing',
        severity: 'error'
      });
    }
  };

  const handleRejectPricing = async (planId, countryCode, reason = '') => {
    if (!isSuperAdmin) return;
    
    try {
  const plan = subscriptionPlans.find(p => p.id === planId);
      
      if (!plan || !plan.pricingByCountry[countryCode]) return;
      
      const updatedPricingByCountry = {
        ...plan.pricingByCountry,
        [countryCode]: {
          ...plan.pricingByCountry[countryCode],
          approvalStatus: 'rejected',
          rejectedBy: user.email,
          rejectedAt: new Date(),
          rejectionReason: reason,
          isActive: false
        }
      };
      
  await api.post(`/subscription-plans/${planId}/pricing/${countryCode}/reject`, { reason });
      
      setSnackbar({
        open: true,
        message: `Pricing rejected for ${countryCode}`,
        severity: 'warning'
      });
      
      fetchSubscriptionPlans();
    } catch (error) {
      console.error('Error rejecting pricing:', error);
      setSnackbar({
        open: true,
        message: 'Failed to reject pricing',
        severity: 'error'
      });
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
      
      // Generate a stable code when creating a new plan (backend expects code/planId)
      const codeFromName = (name) => {
        const base = String(name||'').toLowerCase().trim().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
        return base || `${formData.type || 'plan'}_${formData.planType || 'monthly'}_${Date.now()}`;
      };

      const planData = {
        ...formData,
        countries: countriesToSave,
        createdAt: new Date(),
        updatedAt: new Date(),
        createdBy: user.email,
        createdByCountry: userCountry,
        // Only include code on create; backend PUT ignores if not changing
        ...(selectedPlan ? {} : { code: codeFromName(formData.name) })
      };

      if (selectedPlan) {
        await api.put(`/subscription-plans/${selectedPlan.id}`, planData);
      } else {
        await api.post('/subscription-plans', planData);
      }

      await fetchSubscriptionPlans();
      handleCloseDialog();
    } catch (error) {
      console.error('Error saving subscription plan:', error);
      const status = error?.response?.status;
      const code = error?.response?.data?.code;
      if (status === 409) {
        setError(`A plan with code "${code || (formData.name||'').toLowerCase().replace(/[^a-z0-9]+/g,'_')}" already exists. Change the Name to generate a new code, or edit the existing plan and add LK pricing.`);
      } else {
        setError('Failed to save subscription plan');
      }
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
        await api.delete(`/subscription-plans/${planId}`);
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
        <Box display="flex" gap={2} alignItems="center">
          {isSuperAdmin && (
            <FormControl size="small" sx={{ minWidth: 220 }}>
              <InputLabel id="view-country-label">View Country (optional)</InputLabel>
              <Select
                labelId="view-country-label"
                label="View Country (optional)"
                value={viewCountry}
                onChange={(e) => setViewCountry(e.target.value)}
              >
                <MenuItem value=""><em>Global (All Countries)</em></MenuItem>
                {availableCountries.map((c) => (
                  <MenuItem key={c.code} value={c.code}>{c.name} ({c.code})</MenuItem>
                ))}
              </Select>
            </FormControl>
          )}
          {!isSuperAdmin && userCountry && (
            <FormControl size="small" sx={{ minWidth: 220 }} disabled>
              <InputLabel id="my-country-label">My Country</InputLabel>
              <Select labelId="my-country-label" label="My Country" value={userCountry}>
                <MenuItem value={userCountry}>{userCountry}</MenuItem>
              </Select>
            </FormControl>
          )}
          {isSuperAdmin && (
            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={() => setDialogOpen(true)}
              disabled={loading}
            >
              Add Custom Plan
            </Button>
          )}
        </Box>
      </Box>

      {!isSuperAdmin && userCountry && (
        <Alert severity="info" sx={{ mb: 3 }}>
          You can manage subscription plans for {countries?.find(c => c.code === userCountry)?.name || userCountry}. 
          Add pricing to global plans to make them available in your country.
        </Alert>
      )}

      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={tabValue} onChange={(e, newValue) => setTabValue(newValue)}>
          <Tab label="Subscription Plans" />
          <Tab label="User Subscriptions" />
          {isSuperAdmin && <Tab label="Pricing Approvals" />}
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
                    <TableCell>Pricing</TableCell>
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
                      <TableCell>
                        {plan.pricingByCountry && userCountry && plan.pricingByCountry[userCountry] ? (
                          <Box display="flex" flexDirection="column" alignItems="flex-start" gap={0.5}>
                            <Chip
                              label={`${plan.pricingByCountry[userCountry].currencySymbol}${plan.pricingByCountry[userCountry].price}`}
                              color={plan.pricingByCountry[userCountry].approvalStatus === 'approved' ? 'success' : 
                                     plan.pricingByCountry[userCountry].approvalStatus === 'rejected' ? 'error' : 'warning'}
                              size="small"
                            />
                            {!isSuperAdmin && (
                              <>
                                <Chip 
                                  label={plan.pricingByCountry[userCountry].approvalStatus || 'pending'} 
                                  size="small" 
                                  variant="outlined"
                                  color={plan.pricingByCountry[userCountry].approvalStatus === 'approved' ? 'success' : 
                                         plan.pricingByCountry[userCountry].approvalStatus === 'rejected' ? 'error' : 'warning'}
                                />
                                <Button
                                  size="small"
                                  variant="text"
                                  color="primary"
                                  onClick={() => handleEditPricing(plan)}
                                  sx={{ fontSize: '0.7rem', minWidth: 'auto', p: 0.5 }}
                                >
                                  Edit Price
                                </Button>
                              </>
                            )}
                          </Box>
                        ) : plan.defaultPrice === 0 ? (
                          <Chip label="FREE" color="success" size="small" />
                        ) : (
                          <Box display="flex" flexDirection="column" alignItems="flex-start">
                            {plan.requiresCountryPricing && !isSuperAdmin ? (
                              <Button
                                size="small"
                                variant="outlined"
                                color="primary"
                                onClick={() => handleOpenPricingDialog(plan)}
                                disabled={plan.pricingByCountry && plan.pricingByCountry[userCountry]}
                              >
                                Add Pricing
                              </Button>
                            ) : isSuperAdmin && plan.requiresCountryPricing ? (
                              <Typography variant="body2" color="textSecondary">
                                Country pricing required
                              </Typography>
                            ) : (
                              <Typography variant="body2" color="textSecondary">
                                {plan.defaultPrice ? `$${plan.defaultPrice}` : 'No pricing set'}
                              </Typography>
                            )}
                          </Box>
                        )}
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

          {isSuperAdmin && tabValue === 2 && (
            <>
              <Alert severity="info" sx={{ mb: 2 }}>
                Review and manage pricing requests from country admins. Approve or reject pricing to control what's available in each country.
              </Alert>
              <TableContainer component={Paper}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Plan Name</TableCell>
                      <TableCell>Country</TableCell>
                      <TableCell>Price</TableCell>
                      <TableCell>Submitted By</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell>Date</TableCell>
                      <TableCell>Actions</TableCell>
                    </TableRow>
                  </TableHead>
                <TableBody>
                  {subscriptionPlans.length === 0 ? (
                    <TableRow>
                      <TableCell colSpan={7} align="center">
                        <Typography variant="body2" color="textSecondary" sx={{ py: 4 }}>
                          No subscription plans found. Create default plans first.
                        </Typography>
                      </TableCell>
                    </TableRow>
                  ) : subscriptionPlans.some(plan => plan.pricingByCountry && Object.keys(plan.pricingByCountry).length > 0) ? (
                    subscriptionPlans.map((plan) => 
                      plan.pricingByCountry ? Object.entries(plan.pricingByCountry).map(([country, pricing]) => (
                        <TableRow key={`${plan.id}-${country}`}>
                          <TableCell>
                            <Typography variant="subtitle2">{plan.name}</Typography>
                            <Typography variant="body2" color="textSecondary">
                              {plan.type} - {plan.planType}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            <Chip 
                              label={countries?.find(c => c.code === country)?.name || country} 
                              size="small" 
                              variant="outlined"
                            />
                          </TableCell>
                          <TableCell>
                            <Typography variant="h6" color="primary">
                              {pricing.currencySymbol}{pricing.price}
                            </Typography>
                          </TableCell>
                          <TableCell>{pricing.addedBy}</TableCell>
                          <TableCell>
                            <Chip 
                              label={pricing.approvalStatus || 'pending'} 
                              size="small"
                              color={pricing.approvalStatus === 'approved' ? 'success' : 
                                     pricing.approvalStatus === 'rejected' ? 'error' : 'warning'}
                            />
                          </TableCell>
                          <TableCell>
                            <Typography variant="body2">
                              {pricing.addedAt?.toDate?.()?.toLocaleDateString?.() || 'N/A'}
                            </Typography>
                          </TableCell>
                          <TableCell>
                            {(!pricing.approvalStatus || pricing.approvalStatus === 'pending') && (
                              <Box display="flex" gap={1}>
                                <Button
                                  size="small"
                                  variant="contained"
                                  color="success"
                                  onClick={() => handleApprovePricing(plan.id, country)}
                                >
                                  Approve
                                </Button>
                                <Button
                                  size="small"
                                  variant="outlined"
                                  color="error"
                                  onClick={() => handleRejectPricing(plan.id, country)}
                                >
                                  Reject
                                </Button>
                              </Box>
                            )}
                            {pricing.approvalStatus === 'approved' && (
                              <Box display="flex" flexDirection="column" alignItems="flex-start">
                                <Typography variant="body2" color="success.main">
                                  ✓ Approved
                                </Typography>
                                <Button
                                  size="small"
                                  variant="text"
                                  color="error"
                                  onClick={() => handleRejectPricing(plan.id, country, 'Re-evaluation needed')}
                                  sx={{ fontSize: '0.7rem', minWidth: 'auto', p: 0.5 }}
                                >
                                  Revoke
                                </Button>
                              </Box>
                            )}
                            {pricing.approvalStatus === 'rejected' && (
                              <Box display="flex" flexDirection="column" alignItems="flex-start">
                                <Typography variant="body2" color="error.main">
                                  ✗ Rejected
                                </Typography>
                                <Button
                                  size="small"
                                  variant="text"
                                  color="success"
                                  onClick={() => handleApprovePricing(plan.id, country)}
                                  sx={{ fontSize: '0.7rem', minWidth: 'auto', p: 0.5 }}
                                >
                                  Approve
                                </Button>
                              </Box>
                            )}
                          </TableCell>
                        </TableRow>
                      )) : []
                    ).flat()
                  ) : (
                    <TableRow>
                      <TableCell colSpan={7} align="center">
                        <Typography variant="body2" color="textSecondary" sx={{ py: 4 }}>
                          No pricing requests submitted yet. Country admins need to add pricing first.
                        </Typography>
                      </TableCell>
                    </TableRow>
                  )}
                </TableBody>
              </Table>
            </TableContainer>
            </>
          )}

          {tabValue === (isSuperAdmin ? 3 : 2) && (
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
                      {countries?.map((country) => (
                        <MenuItem key={country.code} value={country.code}>
                          {country.name} ({country.code})
                        </MenuItem>
                      )) || []}
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
                      {countries?.find(c => c.code === country)?.name || country} Pricing
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
                          {countries?.find(c => c.code === country)?.name || country}
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

      {/* Country Pricing Dialog */}
      <Dialog 
        open={pricingDialogOpen} 
        onClose={() => setPricingDialogOpen(false)}
        maxWidth="sm" 
        fullWidth
      >
        <DialogTitle>
          {selectedPlanForPricing?.pricingByCountry?.[userCountry] ? 'Edit' : 'Add'} Pricing for {countries?.find(c => c.code === userCountry)?.name || userCountry}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            {selectedPlanForPricing && (
              <>
                <Typography variant="h6" gutterBottom>
                  {selectedPlanForPricing.name}
                </Typography>
                <Typography variant="body2" color="textSecondary" paragraph>
                  {selectedPlanForPricing.description}
                </Typography>
                
                <Alert severity="info" sx={{ mb: 3 }}>
                  <Typography variant="body2">
                    <strong>Plan Type:</strong> {selectedPlanForPricing.type} - {selectedPlanForPricing.planType}
                    <br />
                    <strong>Currency:</strong> {countryPricingData.currencySymbol} ({countryPricingData.currency})
                    {selectedPlanForPricing.defaultPrice && (
                      <>
                        <br />
                        <strong>Suggested Price:</strong> Based on ${selectedPlanForPricing.defaultPrice} USD
                      </>
                    )}
                  </Typography>
                </Alert>

                {selectedPlanForPricing.pricingByCountry?.[userCountry] && (
                  <Alert 
                    severity={
                      selectedPlanForPricing.pricingByCountry[userCountry].approvalStatus === 'approved' ? 'success' :
                      selectedPlanForPricing.pricingByCountry[userCountry].approvalStatus === 'rejected' ? 'error' : 'warning'
                    } 
                    sx={{ mb: 3 }}
                  >
                    <Typography variant="body2">
                      <strong>Current Status:</strong> {selectedPlanForPricing.pricingByCountry[userCountry].approvalStatus || 'pending'}
                      {selectedPlanForPricing.pricingByCountry[userCountry].approvalStatus === 'rejected' && 
                        selectedPlanForPricing.pricingByCountry[userCountry].rejectionReason && (
                        <>
                          <br />
                          <strong>Reason:</strong> {selectedPlanForPricing.pricingByCountry[userCountry].rejectionReason}
                        </>
                      )}
                      <br />
                      <strong>Note:</strong> Any changes will require super admin approval again.
                    </Typography>
                  </Alert>
                )}

                <TextField
                  fullWidth
                  label={`Price (${countryPricingData.currencySymbol})`}
                  type="number"
                  value={countryPricingData.price}
                  onChange={(e) => setCountryPricingData({
                    ...countryPricingData,
                    price: e.target.value
                  })}
                  placeholder={
                    selectedPlanForPricing.planType === 'pay_per_click' 
                      ? 'Price per response/click' 
                      : 'Monthly subscription price'
                  }
                  helperText={
                    selectedPlanForPricing.planType === 'pay_per_click'
                      ? 'This amount will be charged for each response received'
                      : 'This amount will be charged monthly'
                  }
                  sx={{ mb: 2 }}
                />

                {selectedPlanForPricing.features && (
                  <Box sx={{ mt: 2 }}>
                    <Typography variant="subtitle2" gutterBottom>Plan Features:</Typography>
                    <Box component="ul" sx={{ pl: 2, m: 0 }}>
                      {selectedPlanForPricing.features.map((feature, index) => (
                        <Typography key={index} component="li" variant="body2" color="textSecondary">
                          {feature}
                        </Typography>
                      ))}
                    </Box>
                  </Box>
                )}
              </>
            )}
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setPricingDialogOpen(false)}>Cancel</Button>
          <Button 
            variant="contained" 
            onClick={handleCountryPricingSubmit}
            disabled={!countryPricingData.price}
          >
            Add Pricing
          </Button>
        </DialogActions>
      </Dialog>

      {/* Success/Error Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
          variant="filled"
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Subscriptions;
