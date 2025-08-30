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
  Tabs,
  Tab,
  Divider,
  Paper,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  Checkbox,
  FormGroup,
} from '@mui/material';
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import api from '../../services/apiClient';

// Plan type options
const PLAN_TYPES = [
  { value: 'basic', label: 'Basic Plan', icon: '🌟', description: 'Free plan with basic features' },
  { value: 'monthly', label: 'Monthly Plan', icon: '📅', description: 'Fixed monthly subscription' },
  { value: 'pay_per_click', label: 'Pay Per Click', icon: '💰', description: 'Pay for each response' },
];

const EnhancedBusinessBenefitsManagement = () => {
  const [currentTab, setCurrentTab] = useState(0);
  const [subscriptionPlans, setSubscriptionPlans] = useState([]);
  const [businessTypes, setBusinessTypes] = useState([]);
  const [planAssignments, setPlanAssignments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  
  // Dialog states
  const [createPlanDialogOpen, setCreatePlanDialogOpen] = useState(false);
  const [editPlanDialogOpen, setEditPlanDialogOpen] = useState(false);
  const [assignPlanDialogOpen, setAssignPlanDialogOpen] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);

  // Form states
  const [planForm, setPlanForm] = useState({
    planName: '',
    planType: '',
    monthlyFee: '',
    costPerResponse: '',
    responseLimit: '',
    features: [],
    allowedRequestTypes: [],
    isActive: true,
  });

  const [editForm, setEditForm] = useState({
    planName: '',
    planType: '',
    monthlyFee: '',
    costPerResponse: '',
    responseLimit: '',
    features: [],
    allowedRequestTypes: [],
    isActive: true,
  });

  const [assignmentForm, setAssignmentForm] = useState({
    planId: '',
    businessTypeIds: [],
  });

  useEffect(() => {
    loadSubscriptionPlans();
    loadBusinessTypes();
    loadPlanAssignments();
  }, []);

  const loadSubscriptionPlans = async () => {
    try {
      setLoading(true);
      const response = await api.get('/enhanced-business-benefits/subscription-plans');
      setSubscriptionPlans(response.data || []);
    } catch (err) {
      console.error('Failed to load subscription plans:', err);
      setError('Failed to load subscription plans: ' + err.message);
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

  const loadPlanAssignments = async () => {
    try {
      const response = await api.get('/enhanced-business-benefits/plan-assignments');
      setPlanAssignments(response.data || []);
    } catch (err) {
      console.error('Failed to load plan assignments:', err);
      setPlanAssignments([]);
    }
  };

  const handleCreatePlan = async () => {
    try {
      const planData = {
        planName: planForm.planName,
        pricingModel: planForm.planType,
        pricing: {
          monthlyFee: planForm.monthlyFee ? parseFloat(planForm.monthlyFee) : null,
          costPerResponse: planForm.costPerResponse ? parseFloat(planForm.costPerResponse) : null
        },
        features: {
          responseLimit: planForm.responseLimit ? parseInt(planForm.responseLimit) : null,
          ...planForm.features.reduce((acc, feature) => ({ ...acc, [feature]: true }), {})
        },
        allowedResponseTypes: planForm.allowedRequestTypes,
        isActive: planForm.isActive
      };

      await api.post('/enhanced-business-benefits/subscription-plans', planData);
      
      setCreatePlanDialogOpen(false);
      resetPlanForm();
      setError(null);
      loadSubscriptionPlans();
    } catch (err) {
      console.error('Failed to create plan:', err);
      setError('Failed to create plan: ' + err.message);
    }
  };

  const handleEditPlan = (plan) => {
    setSelectedPlan(plan);
    setEditForm({
      planName: plan.planName,
      planType: plan.pricingModel,
      monthlyFee: plan.pricing?.monthlyFee || '',
      costPerResponse: plan.pricing?.costPerResponse || '',
      responseLimit: plan.features?.responseLimit || '',
      features: Object.keys(plan.features || {}).filter(f => f !== 'responseLimit' && plan.features[f]),
      allowedRequestTypes: plan.allowedResponseTypes || [],
      isActive: plan.isActive
    });
    setEditPlanDialogOpen(true);
  };

  const handleUpdatePlan = async () => {
    try {
      const updateData = {
        planName: editForm.planName,
        pricingModel: editForm.planType,
        pricing: {
          monthlyFee: editForm.monthlyFee ? parseFloat(editForm.monthlyFee) : null,
          costPerResponse: editForm.costPerResponse ? parseFloat(editForm.costPerResponse) : null
        },
        features: {
          responseLimit: editForm.responseLimit ? parseInt(editForm.responseLimit) : null,
          ...editForm.features.reduce((acc, feature) => ({ ...acc, [feature]: true }), {})
        },
        allowedResponseTypes: editForm.allowedRequestTypes,
        isActive: editForm.isActive
      };

      await api.put(`/enhanced-business-benefits/subscription-plans/${selectedPlan.planId}`, updateData);
      
      setEditPlanDialogOpen(false);
      setSelectedPlan(null);
      setError(null);
      loadSubscriptionPlans();
    } catch (err) {
      console.error('Failed to update plan:', err);
      setError('Failed to update plan: ' + err.message);
    }
  };

  const handleDeletePlan = async (planId) => {
    if (!window.confirm('Are you sure you want to delete this plan?')) return;
    
    try {
      await api.delete(`/enhanced-business-benefits/subscription-plans/${planId}`);
      setError(null);
      loadSubscriptionPlans();
    } catch (err) {
      console.error('Failed to delete plan:', err);
      setError('Failed to delete plan: ' + err.message);
    }
  };

  const handleAssignPlan = async () => {
    try {
      const assignments = assignmentForm.businessTypeIds.map(businessTypeId => ({
        planId: assignmentForm.planId,
        businessTypeId
      }));

      await api.post('/enhanced-business-benefits/plan-assignments', { assignments });
      
      setAssignPlanDialogOpen(false);
      resetAssignmentForm();
      setError(null);
      loadPlanAssignments();
    } catch (err) {
      console.error('Failed to assign plan:', err);
      setError('Failed to assign plan: ' + err.message);
    }
  };

  const handleRemoveAssignment = async (assignmentId) => {
    try {
      await api.delete(`/enhanced-business-benefits/plan-assignments/${assignmentId}`);
      setError(null);
      loadPlanAssignments();
    } catch (err) {
      console.error('Failed to remove assignment:', err);
      setError('Failed to remove assignment: ' + err.message);
    }
  };

  const resetPlanForm = () => {
    setPlanForm({
      planName: '',
      planType: '',
      monthlyFee: '',
      costPerResponse: '',
      responseLimit: '',
      features: [],
      allowedRequestTypes: [],
      isActive: true,
    });
  };

  const resetAssignmentForm = () => {
    setAssignmentForm({
      planId: '',
      businessTypeIds: [],
    });
  };

  // Available features and request types
  const availableFeatures = [
    'basic_analytics',
    'customer_messaging', 
    'priority_support',
    'advanced_analytics',
    'custom_branding',
    'api_access',
    'bulk_operations',
    'export_data'
  ];

  const availableRequestTypes = [
    'general_inquiry',
    'quote_request', 
    'booking',
    'complaint',
    'technical_support',
    'consultation',
    'emergency',
    'maintenance'
  ];

  if (loading) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" height="400px">
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
          onClick={() => setCreatePlanDialogOpen(true)}
        >
          Create New Plan
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 3 }} onClose={() => setError(null)}>
          {error}
        </Alert>
      )}

      {/* Tabs for different views */}
      <Box sx={{ borderBottom: 1, borderColor: 'divider', mb: 3 }}>
        <Tabs value={currentTab} onChange={(e, newValue) => setCurrentTab(newValue)}>
          <Tab label="Subscription Plans" />
          <Tab label="Plan Assignments" />
        </Tabs>
      </Box>

      {/* Subscription Plans Tab */}
      {currentTab === 0 && (
        <Grid container spacing={3}>
          {subscriptionPlans.map((plan) => (
            <Grid item xs={12} sm={6} md={4} key={plan.planId}>
              <Card elevation={2}>
                <CardContent>
                  <Box display="flex" justifyContent="space-between" alignItems="flex-start" mb={2}>
                    <Box>
                      <Typography variant="h6" gutterBottom>
                        {plan.planName}
                      </Typography>
                      <Chip 
                        size="small" 
                        label={plan.pricingModel?.replace('_', ' ').toUpperCase() || 'BASIC'}
                        color={plan.pricingModel === 'basic' ? 'success' : plan.pricingModel === 'monthly' ? 'primary' : 'warning'}
                      />
                    </Box>
                    <Box>
                      <IconButton onClick={() => handleEditPlan(plan)} size="small">
                        <EditIcon />
                      </IconButton>
                      <IconButton onClick={() => handleDeletePlan(plan.planId)} size="small" color="error">
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  </Box>

                  {/* Pricing Display */}
                  <Box mb={2}>
                    {plan.pricing?.monthlyFee && (
                      <Typography variant="body2" color="primary">
                        <strong>Monthly: LKR {plan.pricing.monthlyFee}</strong>
                      </Typography>
                    )}
                    {plan.pricing?.costPerResponse && (
                      <Typography variant="body2" color="primary">
                        <strong>Per Response: LKR {plan.pricing.costPerResponse}</strong>
                      </Typography>
                    )}
                    {plan.features?.responseLimit && (
                      <Typography variant="body2">
                        Response Limit: {plan.features.responseLimit}
                      </Typography>
                    )}
                  </Box>

                  {/* Features */}
                  <Box mb={2}>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      Features:
                    </Typography>
                    <Box display="flex" flexWrap="wrap" gap={0.5}>
                      {Object.keys(plan.features || {}).filter(f => f !== 'responseLimit' && plan.features[f]).map((feature) => (
                        <Chip key={feature} size="small" variant="outlined" label={feature.replace(/_/g, ' ')} />
                      ))}
                    </Box>
                  </Box>

                  {/* Request Types */}
                  {plan.allowedResponseTypes?.length > 0 && (
                    <Box>
                      <Typography variant="body2" color="text.secondary" gutterBottom>
                        Allowed Request Types:
                      </Typography>
                      <Box display="flex" flexWrap="wrap" gap={0.5}>
                        {plan.allowedResponseTypes.slice(0, 3).map((type) => (
                          <Chip key={type} size="small" label={type.replace(/_/g, ' ')} />
                        ))}
                        {plan.allowedResponseTypes.length > 3 && (
                          <Chip size="small" label={`+${plan.allowedResponseTypes.length - 3} more`} />
                        )}
                      </Box>
                    </Box>
                  )}

                  <Box mt={2}>
                    <Chip 
                      size="small" 
                      label={plan.isActive ? 'Active' : 'Inactive'}
                      color={plan.isActive ? 'success' : 'default'}
                      variant={plan.isActive ? 'filled' : 'outlined'}
                    />
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}

          {subscriptionPlans.length === 0 && (
            <Grid item xs={12}>
              <Card>
                <CardContent>
                  <Typography variant="h6" align="center" color="text.secondary">
                    No subscription plans found. Create your first plan!
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          )}
        </Grid>
      )}

      {/* Plan Assignments Tab */}
      {currentTab === 1 && (
        <Box>
          <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
            <Typography variant="h5">
              Plan Assignments
            </Typography>
            <Button
              variant="outlined"
              startIcon={<AddIcon />}
              onClick={() => setAssignPlanDialogOpen(true)}
            >
              Assign Plan to Business Types
            </Button>
          </Box>

          <Grid container spacing={3}>
            {(businessTypes || []).map((businessType) => (
              <Grid item xs={12} md={6} key={businessType.id}>
                <Card>
                  <CardContent>
                    <Typography variant="h6" gutterBottom>
                      {businessType.name}
                    </Typography>
                    <Typography variant="body2" color="text.secondary" gutterBottom>
                      {businessType.description}
                    </Typography>
                    
                    {/* Assigned Plans */}
                    <Box mt={2}>
                      <Typography variant="body2" fontWeight="bold" gutterBottom>
                        Assigned Plans:
                      </Typography>
                      {planAssignments.filter(a => a.businessTypeId === businessType.id).length > 0 ? (
                        planAssignments
                          .filter(a => a.businessTypeId === businessType.id)
                          .map((assignment) => {
                            const plan = subscriptionPlans.find(p => p.planId === assignment.planId);
                            return plan ? (
                              <Chip 
                                key={assignment.id}
                                label={plan.planName}
                                onDelete={() => handleRemoveAssignment(assignment.id)}
                                sx={{ mr: 1, mb: 1 }}
                              />
                            ) : null;
                          })
                      ) : (
                        <Typography variant="body2" color="text.secondary">
                          No plans assigned
                        </Typography>
                      )}
                    </Box>
                  </CardContent>
                </Card>
              </Grid>
            ))}
          </Grid>
        </Box>
      )}

      {/* Create Plan Dialog */}
      <Dialog open={createPlanDialogOpen} onClose={() => setCreatePlanDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create New Subscription Plan</DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            {/* Plan Name */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Name"
                value={planForm.planName}
                onChange={(e) => setPlanForm({ ...planForm, planName: e.target.value })}
                required
              />
            </Grid>

            {/* Plan Type */}
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth required>
                <InputLabel>Plan Type</InputLabel>
                <Select
                  value={planForm.planType}
                  onChange={(e) => setPlanForm({ ...planForm, planType: e.target.value })}
                >
                  {PLAN_TYPES.map(type => (
                    <MenuItem key={type.value} value={type.value}>
                      {type.icon} {type.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Pricing fields based on plan type */}
            {(planForm.planType === 'monthly' || planForm.planType === 'basic') && (
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Monthly Fee (LKR)"
                  type="number"
                  value={planForm.monthlyFee}
                  onChange={(e) => setPlanForm({ ...planForm, monthlyFee: e.target.value })}
                  helperText="Leave empty for free plans"
                />
              </Grid>
            )}

            {planForm.planType === 'pay_per_click' && (
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Cost Per Response (LKR)"
                  type="number"
                  value={planForm.costPerResponse}
                  onChange={(e) => setPlanForm({ ...planForm, costPerResponse: e.target.value })}
                  required
                />
              </Grid>
            )}

            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Response Limit"
                type="number"
                value={planForm.responseLimit}
                onChange={(e) => setPlanForm({ ...planForm, responseLimit: e.target.value })}
                helperText="Leave empty for unlimited"
              />
            </Grid>

            {/* Features */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Features
              </Typography>
              <FormGroup row>
                {availableFeatures.map(feature => (
                  <FormControlLabel
                    key={feature}
                    control={
                      <Checkbox
                        checked={planForm.features.includes(feature)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setPlanForm({
                              ...planForm,
                              features: [...planForm.features, feature]
                            });
                          } else {
                            setPlanForm({
                              ...planForm,
                              features: planForm.features.filter(f => f !== feature)
                            });
                          }
                        }}
                      />
                    }
                    label={feature.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  />
                ))}
              </FormGroup>
            </Grid>

            {/* Allowed Request Types */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Allowed Request Types
              </Typography>
              <FormGroup row>
                {availableRequestTypes.map(type => (
                  <FormControlLabel
                    key={type}
                    control={
                      <Checkbox
                        checked={planForm.allowedRequestTypes.includes(type)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setPlanForm({
                              ...planForm,
                              allowedRequestTypes: [...planForm.allowedRequestTypes, type]
                            });
                          } else {
                            setPlanForm({
                              ...planForm,
                              allowedRequestTypes: planForm.allowedRequestTypes.filter(t => t !== type)
                            });
                          }
                        }}
                      />
                    }
                    label={type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  />
                ))}
              </FormGroup>
            </Grid>

            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={planForm.isActive}
                    onChange={(e) => setPlanForm({ ...planForm, isActive: e.target.checked })}
                  />
                }
                label="Plan Active"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreatePlanDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleCreatePlan} variant="contained">
            Create Plan
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit Plan Dialog */}
      <Dialog open={editPlanDialogOpen} onClose={() => setEditPlanDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>Edit Subscription Plan</DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            {/* Plan Name */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Name"
                value={editForm.planName}
                onChange={(e) => setEditForm({ ...editForm, planName: e.target.value })}
              />
            </Grid>

            {/* Plan Type */}
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Plan Type</InputLabel>
                <Select
                  value={editForm.planType}
                  onChange={(e) => setEditForm({ ...editForm, planType: e.target.value })}
                >
                  {PLAN_TYPES.map(type => (
                    <MenuItem key={type.value} value={type.value}>
                      {type.icon} {type.label}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            {/* Pricing Configuration */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Pricing Configuration
              </Typography>
            </Grid>

            {/* Monthly Fee */}
            {(editForm.planType === 'monthly' || editForm.planType === 'basic') && (
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Monthly Fee (LKR)"
                  type="number"
                  value={editForm.monthlyFee}
                  onChange={(e) => setEditForm({ ...editForm, monthlyFee: e.target.value })}
                  helperText="Leave empty for free plans"
                />
              </Grid>
            )}

            {/* Cost Per Response */}
            {editForm.planType === 'pay_per_click' && (
              <Grid item xs={12} sm={6}>
                <TextField
                  fullWidth
                  label="Cost Per Response (LKR)"
                  type="number"
                  value={editForm.costPerResponse}
                  onChange={(e) => setEditForm({ ...editForm, costPerResponse: e.target.value })}
                  required
                />
              </Grid>
            )}

            {/* Response Limit */}
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Response Limit"
                type="number"
                value={editForm.responseLimit}
                onChange={(e) => setEditForm({ ...editForm, responseLimit: e.target.value })}
                helperText="Leave empty for unlimited"
              />
            </Grid>

            {/* Features */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Features
              </Typography>
              <FormGroup row>
                {availableFeatures.map(feature => (
                  <FormControlLabel
                    key={feature}
                    control={
                      <Checkbox
                        checked={editForm.features.includes(feature)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setEditForm({
                              ...editForm,
                              features: [...editForm.features, feature]
                            });
                          } else {
                            setEditForm({
                              ...editForm,
                              features: editForm.features.filter(f => f !== feature)
                            });
                          }
                        }}
                      />
                    }
                    label={feature.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  />
                ))}
              </FormGroup>
            </Grid>

            {/* Allowed Request Types */}
            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Allowed Request Types
              </Typography>
              <FormGroup row>
                {availableRequestTypes.map(type => (
                  <FormControlLabel
                    key={type}
                    control={
                      <Checkbox
                        checked={editForm.allowedRequestTypes.includes(type)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setEditForm({
                              ...editForm,
                              allowedRequestTypes: [...editForm.allowedRequestTypes, type]
                            });
                          } else {
                            setEditForm({
                              ...editForm,
                              allowedRequestTypes: editForm.allowedRequestTypes.filter(t => t !== type)
                            });
                          }
                        }}
                      />
                    }
                    label={type.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  />
                ))}
              </FormGroup>
            </Grid>

            {/* Active Status */}
            <Grid item xs={12}>
              <FormControlLabel
                control={
                  <Switch
                    checked={editForm.isActive}
                    onChange={(e) => setEditForm({ ...editForm, isActive: e.target.checked })}
                  />
                }
                label="Plan Active"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditPlanDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleUpdatePlan} variant="contained">
            Update Plan
          </Button>
        </DialogActions>
      </Dialog>

      {/* Assign Plan Dialog */}
      <Dialog open={assignPlanDialogOpen} onClose={() => setAssignPlanDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Assign Plan to Business Types</DialogTitle>
        <DialogContent>
          <Grid container spacing={3} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <FormControl fullWidth required>
                <InputLabel>Select Plan</InputLabel>
                <Select
                  value={assignmentForm.planId}
                  onChange={(e) => setAssignmentForm({ ...assignmentForm, planId: e.target.value })}
                >
                  {subscriptionPlans.map(plan => (
                    <MenuItem key={plan.planId} value={plan.planId}>
                      {plan.planName} ({plan.pricingModel})
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>

            <Grid item xs={12}>
              <Typography variant="h6" gutterBottom>
                Select Business Types
              </Typography>
              <FormGroup>
                {businessTypes.map(type => (
                  <FormControlLabel
                    key={type.id}
                    control={
                      <Checkbox
                        checked={assignmentForm.businessTypeIds.includes(type.id)}
                        onChange={(e) => {
                          if (e.target.checked) {
                            setAssignmentForm({
                              ...assignmentForm,
                              businessTypeIds: [...assignmentForm.businessTypeIds, type.id]
                            });
                          } else {
                            setAssignmentForm({
                              ...assignmentForm,
                              businessTypeIds: assignmentForm.businessTypeIds.filter(id => id !== type.id)
                            });
                          }
                        }}
                      />
                    }
                    label={type.name}
                  />
                ))}
              </FormGroup>
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAssignPlanDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleAssignPlan} variant="contained">
            Assign Plan
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default EnhancedBusinessBenefitsManagement;
