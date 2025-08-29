import React, { useEffect, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
  Tabs,
  Tab,
  Grid,
  Card,
  CardContent,
  CardActions,
  TextField,
  Chip,
  Alert,
  Stack,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  FormControl,
  InputLabel,
  Select,
  MenuItem
} from '@mui/material';
import { 
  Add as AddIcon, 
  Edit as EditIcon, 
  Check as CheckIcon, 
  Store as StoreIcon,
  Chat as ChatIcon 
} from '@mui/icons-material';
import api from '../services/apiClient';
import useCountryFilter from '../hooks/useCountryFilter';

export default function SubscriptionManagement() {
  const { adminData, isSuperAdmin, isCountryAdmin } = useCountryFilter();
  const [tab, setTab] = useState(0); // 0: Product Seller, 1: User Response, 2: Approvals
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  
  // Product Seller Plans
  const [productPlans, setProductPlans] = useState([]);
  const [productPricing, setProductPricing] = useState([]);
  
  // User Response Plans
  const [responsePlans, setResponsePlans] = useState([]);
  const [responsePricing, setResponsePricing] = useState([]);
  
  // Approvals
  const [pendingApprovals, setPendingApprovals] = useState([]);
  
  // Dialogs
  const [createDialog, setCreateDialog] = useState({ open: false, type: '' });
  const [planForm, setPlanForm] = useState({});
  
  const myCountry = adminData?.country || 'LK';

  // Load data functions
  const loadProductPlans = async () => {
    try {
      const res = await api.get('/subscription-management/product-seller-plans');
      setProductPlans(res.data?.data || []);
    } catch (e) {
      console.error('Failed to load product plans', e);
    }
  };

  const loadResponsePlans = async () => {
    try {
      const res = await api.get('/subscription-management/user-response-plans');
      setResponsePlans(res.data?.data || []);
    } catch (e) {
      console.error('Failed to load response plans', e);
    }
  };

  const loadMyProductPricing = async () => {
    if (!isCountryAdmin) return;
    try {
      const allPricing = await Promise.all(
        productPlans.map(async (plan) => {
          try {
            const res = await api.get(`/subscription-management/product-seller-plans/${plan.id}/pricing`, 
              { params: { country: myCountry } });
            const pricing = res.data?.data?.[0];
            return { ...plan, pricing };
          } catch {
            return { ...plan, pricing: null };
          }
        })
      );
      setProductPricing(allPricing);
    } catch (e) {
      console.error('Failed to load product pricing', e);
    }
  };

  const loadMyResponsePricing = async () => {
    if (!isCountryAdmin) return;
    try {
      const allPricing = await Promise.all(
        responsePlans.map(async (plan) => {
          try {
            const res = await api.get(`/subscription-management/user-response-plans/${plan.id}/pricing`, 
              { params: { country: myCountry } });
            const pricing = res.data?.data?.[0];
            return { ...plan, pricing };
          } catch {
            return { ...plan, pricing: null };
          }
        })
      );
      setResponsePricing(allPricing);
    } catch (e) {
      console.error('Failed to load response pricing', e);
    }
  };

  const loadPendingApprovals = async () => {
    try {
      const res = await api.get('/subscription-management/pending-approvals', 
        isCountryAdmin ? { params: { country: myCountry } } : {});
      setPendingApprovals(res.data?.data || []);
    } catch (e) {
      console.error('Failed to load pending approvals', e);
    }
  };

  // Action functions
  const createPlan = async () => {
    try {
      const endpoint = createDialog.type === 'product' 
        ? '/subscription-management/product-seller-plans'
        : '/subscription-management/user-response-plans';
      
      await api.post(endpoint, planForm);
      setSuccess('Plan created successfully');
      setCreateDialog({ open: false, type: '' });
      setPlanForm({});
      
      if (createDialog.type === 'product') {
        loadProductPlans();
      } else {
        loadResponsePlans();
      }
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to create plan');
    }
  };

  const saveProductPricing = async (plan, pricePerClick, monthlyFee) => {
    try {
      await api.post(`/subscription-management/product-seller-plans/${plan.id}/pricing`, {
        country_code: myCountry,
        price_per_click: pricePerClick || null,
        monthly_fee: monthlyFee || null
      });
      setSuccess('Product pricing saved for approval');
      loadMyProductPricing();
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to save pricing');
    }
  };

  const saveResponsePricing = async (plan, monthlyPrice) => {
    try {
      await api.post(`/subscription-management/user-response-plans/${plan.id}/pricing`, {
        country_code: myCountry,
        monthly_price: monthlyPrice
      });
      setSuccess('Response pricing saved for approval');
      loadMyResponsePricing();
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to save pricing');
    }
  };

  const approveItem = async (item, approve = true) => {
    try {
      const endpoint = item.pricing_type === 'product_seller'
        ? `/subscription-management/product-seller-plans/${item.plan_id}/pricing/${item.country_code}`
        : `/subscription-management/user-response-plans/${item.plan_id}/pricing/${item.country_code}`;
      
      await api.put(endpoint, { is_active: approve });
      setSuccess(approve ? 'Pricing approved' : 'Pricing rejected');
      loadPendingApprovals();
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to update approval');
    }
  };

  // Effects
  useEffect(() => {
    loadProductPlans();
    loadResponsePlans();
    loadPendingApprovals();
  }, []);

  useEffect(() => {
    if (productPlans.length) loadMyProductPricing();
  }, [productPlans, isCountryAdmin, myCountry]);

  useEffect(() => {
    if (responsePlans.length) loadMyResponsePricing();
  }, [responsePlans, isCountryAdmin, myCountry]);

  const openCreateDialog = (type) => {
    setCreateDialog({ open: true, type });
    setPlanForm({
      code: '',
      name: '',
      description: '',
      ...(type === 'product' ? { billing_type: 'per_click' } : { response_type: 'other', response_limit: null, features: [] })
    });
  };

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        Subscription Management
      </Typography>
      
      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess('')}>{success}</Alert>}

      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <Chip 
          label={isSuperAdmin ? 'Super Admin' : `Country Admin (${myCountry})`} 
          color="primary" 
        />
      </Stack>

      <Paper sx={{ mb: 3 }}>
        <Tabs value={tab} onChange={(_, v) => setTab(v)} sx={{ borderBottom: 1, borderColor: 'divider' }}>
          <Tab icon={<StoreIcon />} label="Product Marketplace" />
          <Tab icon={<ChatIcon />} label="User Responses" />
          <Tab label="Approvals" />
        </Tabs>

        <Box sx={{ p: 3 }}>
          {/* PRODUCT SELLER PRICING */}
          {tab === 0 && (
            <>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
                <Typography variant="h6">
                  Product Marketplace Pricing
                </Typography>
                {isSuperAdmin && (
                  <Button 
                    variant="contained" 
                    startIcon={<AddIcon />} 
                    onClick={() => openCreateDialog('product')}
                  >
                    Create Product Plan
                  </Button>
                )}
              </Stack>

              {isSuperAdmin ? (
                <Grid container spacing={2}>
                  {productPlans.map((plan) => (
                    <Grid size={{ xs: 12, md: 6 }} key={plan.id}>
                      <Card>
                        <CardContent>
                          <Typography variant="h6">{plan.name}</Typography>
                          <Typography color="textSecondary" gutterBottom>{plan.code}</Typography>
                          <Chip 
                            label={plan.billing_type === 'per_click' ? 'Pay Per Click' : 'Monthly Fee'} 
                            size="small"
                            color={plan.billing_type === 'per_click' ? 'primary' : 'secondary'}
                          />
                          <Typography variant="body2" sx={{ mt: 1 }}>
                            {plan.description}
                          </Typography>
                        </CardContent>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              ) : (
                <Grid container spacing={2}>
                  {productPricing.map((item) => (
                    <Grid size={{ xs: 12, md: 6 }} key={item.id}>
                      <ProductPricingCard 
                        plan={item} 
                        pricing={item.pricing}
                        onSave={saveProductPricing}
                      />
                    </Grid>
                  ))}
                </Grid>
              )}
            </>
          )}

          {/* USER RESPONSE PRICING */}
          {tab === 1 && (
            <>
              <Stack direction="row" justifyContent="space-between" alignItems="center" sx={{ mb: 3 }}>
                <Typography variant="h6">
                  User Response Pricing
                </Typography>
                {isSuperAdmin && (
                  <Button 
                    variant="contained" 
                    startIcon={<AddIcon />} 
                    onClick={() => openCreateDialog('response')}
                  >
                    Create Response Plan
                  </Button>
                )}
              </Stack>

              {isSuperAdmin ? (
                <Grid container spacing={2}>
                  {responsePlans.map((plan) => (
                    <Grid size={{ xs: 12, md: 6 }} key={plan.id}>
                      <Card>
                        <CardContent>
                          <Typography variant="h6">{plan.name}</Typography>
                          <Typography color="textSecondary" gutterBottom>{plan.code}</Typography>
                          <Chip 
                            label={plan.response_type.toUpperCase()} 
                            size="small"
                            color="primary"
                          />
                          <Typography variant="body2" sx={{ mt: 1 }}>
                            {plan.response_limit ? `${plan.response_limit} responses/month` : 'Unlimited responses'}
                          </Typography>
                          <Typography variant="body2">
                            {plan.description}
                          </Typography>
                        </CardContent>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              ) : (
                <Grid container spacing={2}>
                  {responsePricing.map((item) => (
                    <Grid size={{ xs: 12, md: 6 }} key={item.id}>
                      <ResponsePricingCard 
                        plan={item} 
                        pricing={item.pricing}
                        onSave={saveResponsePricing}
                      />
                    </Grid>
                  ))}
                </Grid>
              )}
            </>
          )}

          {/* APPROVALS */}
          {tab === 2 && (
            <>
              <Typography variant="h6" gutterBottom>
                Pending Approvals ({pendingApprovals.length})
              </Typography>
              
              {pendingApprovals.length === 0 ? (
                <Typography color="textSecondary">No pending approvals</Typography>
              ) : (
                <TableContainer>
                  <Table>
                    <TableHead>
                      <TableRow>
                        <TableCell>Country</TableCell>
                        <TableCell>Plan</TableCell>
                        <TableCell>Type</TableCell>
                        <TableCell>Pricing</TableCell>
                        <TableCell>Currency</TableCell>
                        <TableCell align="right">Actions</TableCell>
                      </TableRow>
                    </TableHead>
                    <TableBody>
                      {pendingApprovals.map((item, index) => (
                        <TableRow key={index}>
                          <TableCell>{item.country_code}</TableCell>
                          <TableCell>{item.plan_name}</TableCell>
                          <TableCell>
                            <Chip 
                              label={item.pricing_type === 'product_seller' ? 'Product Marketplace' : 'User Response'} 
                              size="small"
                              color={item.pricing_type === 'product_seller' ? 'primary' : 'secondary'}
                            />
                          </TableCell>
                          <TableCell>
                            {item.pricing_type === 'product_seller' ? (
                              <>
                                {item.price_per_click && `${Number(item.price_per_click).toFixed(4)}/click`}
                                {item.price_per_click && item.monthly_fee && ' + '}
                                {item.monthly_fee && `${Number(item.monthly_fee).toFixed(2)}/month`}
                              </>
                            ) : (
                              `${Number(item.monthly_price || 0).toFixed(2)}/month`
                            )}
                          </TableCell>
                          <TableCell>{item.currency}</TableCell>
                          <TableCell align="right">
                            {isSuperAdmin && (
                              <>
                                <Button 
                                  size="small" 
                                  color="success" 
                                  startIcon={<CheckIcon />}
                                  onClick={() => approveItem(item, true)}
                                  sx={{ mr: 1 }}
                                >
                                  Approve
                                </Button>
                                <Button 
                                  size="small" 
                                  color="error"
                                  onClick={() => approveItem(item, false)}
                                >
                                  Reject
                                </Button>
                              </>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                </TableContainer>
              )}
            </>
          )}
        </Box>
      </Paper>

      {/* CREATE PLAN DIALOG */}
      <Dialog open={createDialog.open} onClose={() => setCreateDialog({ open: false, type: '' })} maxWidth="sm" fullWidth>
        <DialogTitle>
          Create {createDialog.type === 'product' ? 'Product Seller' : 'User Response'} Plan
        </DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField
              label="Plan Code"
              value={planForm.code || ''}
              onChange={(e) => setPlanForm({ ...planForm, code: e.target.value })}
              fullWidth
            />
            <TextField
              label="Plan Name"
              value={planForm.name || ''}
              onChange={(e) => setPlanForm({ ...planForm, name: e.target.value })}
              fullWidth
            />
            <TextField
              label="Description"
              value={planForm.description || ''}
              onChange={(e) => setPlanForm({ ...planForm, description: e.target.value })}
              multiline
              rows={3}
              fullWidth
            />
            
            {createDialog.type === 'product' && (
              <FormControl fullWidth>
                <InputLabel>Billing Type</InputLabel>
                <Select
                  value={planForm.billing_type || 'per_click'}
                  label="Billing Type"
                  onChange={(e) => setPlanForm({ ...planForm, billing_type: e.target.value })}
                >
                  <MenuItem value="per_click">Pay Per Click</MenuItem>
                  <MenuItem value="monthly">Monthly Fee</MenuItem>
                </Select>
              </FormControl>
            )}
            
            {createDialog.type === 'response' && (
              <>
                <FormControl fullWidth>
                  <InputLabel>Response Type</InputLabel>
                  <Select
                    value={planForm.response_type || 'other'}
                    label="Response Type"
                    onChange={(e) => setPlanForm({ ...planForm, response_type: e.target.value })}
                  >
                    <MenuItem value="free">Free Plan</MenuItem>
                    <MenuItem value="ride">Ride Responses Only</MenuItem>
                    <MenuItem value="other">Other Responses Only</MenuItem>
                    <MenuItem value="all">All Response Types</MenuItem>
                  </Select>
                </FormControl>
                <TextField
                  label="Response Limit (leave empty for unlimited)"
                  type="number"
                  value={planForm.response_limit || ''}
                  onChange={(e) => setPlanForm({ ...planForm, response_limit: e.target.value ? Number(e.target.value) : null })}
                  fullWidth
                />
              </>
            )}
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialog({ open: false, type: '' })}>Cancel</Button>
          <Button variant="contained" onClick={createPlan}>Create</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// Product Pricing Card Component
function ProductPricingCard({ plan, pricing, onSave }) {
  const [pricePerClick, setPricePerClick] = useState(pricing?.price_per_click || '');
  const [monthlyFee, setMonthlyFee] = useState(pricing?.monthly_fee || '');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave(plan, pricePerClick, monthlyFee);
    } finally {
      setSaving(false);
    }
  };

  const status = pricing?.is_active ? 'Active' : (pricing ? 'Pending Approval' : 'Not Set');
  const statusColor = pricing?.is_active ? 'success' : (pricing ? 'warning' : 'default');

  return (
    <Card>
      <CardContent>
        <Typography variant="h6">{plan.name}</Typography>
        <Typography color="textSecondary" gutterBottom>{plan.code}</Typography>
        <Chip 
          label={plan.billing_type === 'per_click' ? 'Pay Per Click' : 'Monthly Fee'} 
          size="small"
          color={plan.billing_type === 'per_click' ? 'primary' : 'secondary'}
          sx={{ mb: 1 }}
        />
        <br />
        <Chip 
          label={status} 
          color={statusColor}
          size="small"
          sx={{ mb: 2 }}
        />

        <Stack spacing={2}>
          {(plan.billing_type === 'per_click' || plan.billing_type === 'monthly') && (
            <TextField
              label="Price Per Click"
              type="number"
              value={pricePerClick}
              onChange={(e) => setPricePerClick(e.target.value)}
              disabled={plan.billing_type === 'monthly'}
              fullWidth
              size="small"
              InputProps={{ inputProps: { step: 0.0001 } }}
            />
          )}
          {(plan.billing_type === 'monthly' || plan.billing_type === 'per_click') && (
            <TextField
              label="Monthly Fee"
              type="number"
              value={monthlyFee}
              onChange={(e) => setMonthlyFee(e.target.value)}
              disabled={plan.billing_type === 'per_click'}
              fullWidth
              size="small"
            />
          )}
        </Stack>
      </CardContent>
      <CardActions>
        <Button 
          variant="contained" 
          onClick={handleSave}
          disabled={saving || (!pricePerClick && !monthlyFee)}
          fullWidth
        >
          {saving ? 'Saving...' : 'Save Pricing'}
        </Button>
      </CardActions>
    </Card>
  );
}

// Response Pricing Card Component
function ResponsePricingCard({ plan, pricing, onSave }) {
  const [monthlyPrice, setMonthlyPrice] = useState(pricing?.monthly_price || '');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave(plan, monthlyPrice);
    } finally {
      setSaving(false);
    }
  };

  const status = pricing?.is_active ? 'Active' : (pricing ? 'Pending Approval' : 'Not Set');
  const statusColor = pricing?.is_active ? 'success' : (pricing ? 'warning' : 'default');

  return (
    <Card>
      <CardContent>
        <Typography variant="h6">{plan.name}</Typography>
        <Typography color="textSecondary" gutterBottom>{plan.code}</Typography>
        <Chip 
          label={plan.response_type.toUpperCase()} 
          size="small"
          color="primary"
          sx={{ mb: 1 }}
        />
        <br />
        <Chip 
          label={status} 
          color={statusColor}
          size="small"
          sx={{ mb: 2 }}
        />
        
        <Typography variant="body2" sx={{ mb: 2 }}>
          {plan.response_limit ? `${plan.response_limit} responses/month` : 'Unlimited responses'}
        </Typography>

        <TextField
          label={plan.response_type === 'free' ? 'Price (should be 0)' : 'Monthly Price'}
          type="number"
          value={monthlyPrice}
          onChange={(e) => setMonthlyPrice(e.target.value)}
          fullWidth
          size="small"
        />
      </CardContent>
      <CardActions>
        <Button 
          variant="contained" 
          onClick={handleSave}
          disabled={saving || !monthlyPrice}
          fullWidth
        >
          {saving ? 'Saving...' : 'Save Pricing'}
        </Button>
      </CardActions>
    </Card>
  );
}
