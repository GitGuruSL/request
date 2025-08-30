import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Switch,
  FormControlLabel,
  Alert,
  CircularProgress,
  IconButton,
  Tooltip,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  ExpandMore as ExpandMoreIcon,
  Payment as PaymentIcon,
  Schedule as ScheduleIcon,
  Inventory as InventoryIcon,
  Reply as ReplyIcon,
} from '@mui/icons-material';
import api from '../../services/apiClient';

const PRICING_MODELS = [
  { value: 'pay_per_click', label: 'Pay Per Click', icon: PaymentIcon },
  { value: 'monthly_subscription', label: 'Monthly Subscription', icon: ScheduleIcon },
  { value: 'bundle', label: 'Bundle Offer', icon: InventoryIcon },
  { value: 'response_based', label: 'Response Based', icon: ReplyIcon },
];

const EnhancedBusinessBenefitsManagement = () => {
  const [benefits, setBenefits] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [createDialogOpen, setCreateDialogOpen] = useState(false);
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [businessTypes, setBusinessTypes] = useState([]);

  // Form state
  const [planForm, setPlanForm] = useState({
    businessTypeId: '',
    planCode: '',
    planName: '',
    pricingModel: '',
    features: {},
    pricing: {},
    allowedResponseTypes: [],
    isActive: true,
  });

  useEffect(() => {
    loadBenefits();
    loadBusinessTypes();
  }, []);

  const loadBenefits = async () => {
    try {
      setLoading(true);
      const response = await api.get('/enhanced-business-benefits/LK');
      setBenefits(response.data.businessTypeBenefits || {});
      setError(null);
    } catch (err) {
      setError('Failed to load business benefits: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const loadBusinessTypes = async () => {
    try {
      const response = await api.get('/business-types');
      console.log('Business types response:', response.data);
      
      // Ensure we always set an array
      if (Array.isArray(response.data)) {
        setBusinessTypes(response.data);
      } else if (response.data && Array.isArray(response.data.data)) {
        setBusinessTypes(response.data.data);
      } else {
        console.warn('Business types response is not an array:', response.data);
        setBusinessTypes([]);
      }
    } catch (err) {
      console.error('Failed to load business types:', err);
      setBusinessTypes([]); // Ensure we always have an array
    }
  };

  const handleCreatePlan = async () => {
    try {
      await api.post('/enhanced-business-benefits', {
        countryId: 'LK',
        businessTypeId: parseInt(planForm.businessTypeId),
        planCode: planForm.planCode,
        planName: planForm.planName,
        pricingModel: planForm.pricingModel,
        features: planForm.features,
        pricing: planForm.pricing,
        allowedResponseTypes: planForm.allowedResponseTypes,
      });
      
      setCreateDialogOpen(false);
      resetForm();
      loadBenefits();
    } catch (err) {
      setError('Failed to create plan: ' + err.message);
    }
  };

  const handleEditPlan = async () => {
    try {
      await api.put(`/enhanced-business-benefits/${selectedPlan.planId}`, {
        planName: planForm.planName,
        pricingModel: planForm.pricingModel,
        features: planForm.features,
        pricing: planForm.pricing,
        allowedResponseTypes: planForm.allowedResponseTypes,
        isActive: planForm.isActive,
      });
      
      setEditDialogOpen(false);
      setSelectedPlan(null);
      resetForm();
      loadBenefits();
    } catch (err) {
      setError('Failed to update plan: ' + err.message);
    }
  };

  const handleDeletePlan = async (planId) => {
    if (!window.confirm('Are you sure you want to delete this plan?')) {
      return;
    }

    try {
      await api.delete(`/enhanced-business-benefits/${planId}`);
      loadBenefits();
    } catch (err) {
      setError('Failed to delete plan: ' + err.message);
    }
  };

  const resetForm = () => {
    setPlanForm({
      businessTypeId: '',
      planCode: '',
      planName: '',
      pricingModel: '',
      features: {},
      pricing: {},
      allowedResponseTypes: [],
      isActive: true,
    });
  };

  const openCreateDialog = () => {
    resetForm();
    setCreateDialogOpen(true);
  };

  const openEditDialog = (plan, businessTypeId) => {
    setSelectedPlan(plan);
    setPlanForm({
      businessTypeId: businessTypeId.toString(),
      planCode: plan.planCode,
      planName: plan.planName,
      pricingModel: plan.pricingModel,
      features: plan.features || {},
      pricing: plan.pricing || {},
      allowedResponseTypes: plan.allowedResponseTypes || [],
      isActive: plan.isActive,
    });
    setEditDialogOpen(true);
  };

  const getPricingModelIcon = (model) => {
    const modelData = PRICING_MODELS.find(m => m.value === model);
    if (!modelData) return PaymentIcon;
    const IconComponent = modelData.icon;
    return <IconComponent />;
  };

  const getPricingModelColor = (model) => {
    switch (model) {
      case 'pay_per_click': return 'primary';
      case 'monthly_subscription': return 'secondary';
      case 'bundle': return 'success';
      case 'response_based': return 'info';
      default: return 'default';
    }
  };

  const renderPricingDetails = (plan) => {
    const { pricing, pricingModel } = plan;
    
    switch (pricingModel) {
      case 'pay_per_click':
        return (
          <Box>
            <Typography variant="body2">
              <strong>Cost per click:</strong> {pricing.currency} {pricing.cost_per_click}
            </Typography>
            <Typography variant="body2">
              <strong>Minimum budget:</strong> {pricing.currency} {pricing.minimum_budget}
            </Typography>
          </Box>
        );
      case 'monthly_subscription':
        return (
          <Box>
            <Typography variant="body2">
              <strong>Monthly fee:</strong> {pricing.currency} {pricing.monthly_fee}
            </Typography>
            {pricing.setup_fee && (
              <Typography variant="body2">
                <strong>Setup fee:</strong> {pricing.currency} {pricing.setup_fee}
              </Typography>
            )}
          </Box>
        );
      case 'bundle':
        return (
          <Box>
            <Typography variant="body2">
              <strong>Bundle price:</strong> {pricing.currency} {pricing.bundle_price}
            </Typography>
            <Typography variant="body2">
              <strong>Clicks included:</strong> {pricing.clicks_included}
            </Typography>
            {pricing.additional_click_cost && (
              <Typography variant="body2">
                <strong>Additional click cost:</strong> {pricing.currency} {pricing.additional_click_cost}
              </Typography>
            )}
          </Box>
        );
      case 'response_based':
        return (
          <Box>
            <Typography variant="body2">
              <strong>Cost per response:</strong> {pricing.currency} {pricing.cost_per_response}
            </Typography>
            {pricing.monthly_minimum && (
              <Typography variant="body2">
                <strong>Monthly minimum:</strong> {pricing.currency} {pricing.monthly_minimum}
              </Typography>
            )}
          </Box>
        );
      default:
        return (
          <Box>
            {Object.entries(pricing).map(([key, value]) => (
              <Typography key={key} variant="body2">
                <strong>{key}:</strong> {value}
              </Typography>
            ))}
          </Box>
        );
    }
  };

  const renderPlanCard = (plan, businessTypeName, businessTypeId) => (
    <Card key={plan.planId} sx={{ mb: 2 }}>
      <CardContent>
        <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
          <Box>
            <Typography variant="h6" gutterBottom>
              {plan.planName}
            </Typography>
            <Chip
              icon={getPricingModelIcon(plan.pricingModel)}
              label={PRICING_MODELS.find(m => m.value === plan.pricingModel)?.label || plan.pricingModel}
              color={getPricingModelColor(plan.pricingModel)}
              size="small"
            />
            {!plan.isActive && (
              <Chip label="Inactive" color="warning" size="small" sx={{ ml: 1 }} />
            )}
          </Box>
          <Box>
            <Tooltip title="Edit Plan">
              <IconButton onClick={() => openEditDialog(plan, businessTypeId)} size="small">
                <EditIcon />
              </IconButton>
            </Tooltip>
            <Tooltip title="Delete Plan">
              <IconButton onClick={() => handleDeletePlan(plan.planId)} size="small" color="error">
                <DeleteIcon />
              </IconButton>
            </Tooltip>
          </Box>
        </Box>

        <Typography variant="body2" color="text.secondary" gutterBottom>
          Code: {plan.planCode}
        </Typography>

        {renderPricingDetails(plan)}

        {Object.keys(plan.features || {}).length > 0 && (
          <Box mt={2}>
            <Typography variant="subtitle2" gutterBottom>Features:</Typography>
            <Box display="flex" flexWrap="wrap" gap={0.5}>
              {Object.entries(plan.features)
                .filter(([_, enabled]) => enabled)
                .map(([feature, _]) => (
                  <Chip
                    key={feature}
                    label={feature.replace(/_/g, ' ')}
                    size="small"
                    variant="outlined"
                  />
                ))}
            </Box>
          </Box>
        )}
      </CardContent>
    </Card>
  );

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
        <CircularProgress />
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h4" gutterBottom>
          Enhanced Business Benefits Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={openCreateDialog}
        >
          Create New Plan
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {Object.keys(benefits).length === 0 ? (
        <Card>
          <CardContent>
            <Typography variant="h6" align="center" color="text.secondary">
              No business benefits found
            </Typography>
            <Typography variant="body2" align="center" color="text.secondary">
              Create your first benefit plan to get started
            </Typography>
          </CardContent>
        </Card>
      ) : (
        Object.entries(benefits).map(([businessTypeName, businessTypeBenefits]) => (
          <Accordion key={businessTypeName} defaultExpanded>
            <AccordionSummary expandIcon={<ExpandMoreIcon />}>
              <Typography variant="h6">
                {businessTypeName} ({businessTypeBenefits.plans.length} plan{businessTypeBenefits.plans.length !== 1 ? 's' : ''})
              </Typography>
            </AccordionSummary>
            <AccordionDetails>
              {businessTypeBenefits.plans.length === 0 ? (
                <Typography color="text.secondary">
                  No plans available for this business type
                </Typography>
              ) : (
                businessTypeBenefits.plans.map(plan =>
                  renderPlanCard(plan, businessTypeName, businessTypeBenefits.businessTypeId)
                )
              )}
            </AccordionDetails>
          </Accordion>
        ))
      )}

      {/* Create Plan Dialog */}
      <Dialog open={createDialogOpen} onClose={() => setCreateDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create New Benefit Plan</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Business Type</InputLabel>
                <Select
                  value={planForm.businessTypeId}
                  onChange={(e) => setPlanForm({ ...planForm, businessTypeId: e.target.value })}
                >
                  {(businessTypes || []).map(type => (
                    <MenuItem key={type.id} value={type.id}>
                      {type.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Pricing Model</InputLabel>
                <Select
                  value={planForm.pricingModel}
                  onChange={(e) => setPlanForm({ ...planForm, pricingModel: e.target.value })}
                >
                  {PRICING_MODELS.map(model => (
                    <MenuItem key={model.value} value={model.value}>
                      {model.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Code"
                value={planForm.planCode}
                onChange={(e) => setPlanForm({ ...planForm, planCode: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Name"
                value={planForm.planName}
                onChange={(e) => setPlanForm({ ...planForm, planName: e.target.value })}
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreateDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreatePlan} variant="contained">Create</Button>
        </DialogActions>
      </Dialog>

      {/* Edit Plan Dialog */}
      <Dialog open={editDialogOpen} onClose={() => setEditDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Edit Benefit Plan</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Name"
                value={planForm.planName}
                onChange={(e) => setPlanForm({ ...planForm, planName: e.target.value })}
              />
            </Grid>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Pricing Model</InputLabel>
                <Select
                  value={planForm.pricingModel}
                  onChange={(e) => setPlanForm({ ...planForm, pricingModel: e.target.value })}
                >
                  {PRICING_MODELS.map(model => (
                    <MenuItem key={model.value} value={model.value}>
                      {model.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={planForm.isActive}
                    onChange={(e) => setPlanForm({ ...planForm, isActive: e.target.checked })}
                  />
                }
                label="Active"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleEditPlan} variant="contained">Save</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default EnhancedBusinessBenefitsManagement;
