import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Grid,
  Card,
  CardContent,
  CardActions,
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
  Chip,
  Switch,
  FormControlLabel,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Divider,
  Alert,
  Snackbar,
  IconButton,
  Tooltip
} from '@mui/material';
import {
  ExpandMore as ExpandMoreIcon,
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Settings as SettingsIcon
} from '@mui/icons-material';
import api from '../services/api';

const EnhancedBusinessBenefits = () => {
  const [selectedCountry, setSelectedCountry] = useState('');
  const [countries, setCountries] = useState([]);
  const [businessTypes, setBusinessTypes] = useState([]);
  const [benefitPlans, setBenefitPlans] = useState({});
  const [loading, setLoading] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  
  // Dialog states
  const [createPlanDialog, setCreatePlanDialog] = useState(false);
  const [editConfigDialog, setEditConfigDialog] = useState(false);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [configKey, setConfigKey] = useState('');
  const [configData, setConfigData] = useState('');

  // Form states
  const [newPlan, setNewPlan] = useState({
    planCode: '',
    planName: '',
    planDescription: '',
    planType: 'response_based',
    businessTypeId: '',
    config: {},
    allowedResponseTypes: []
  });

  useEffect(() => {
    loadCountries();
    loadBusinessTypes();
  }, []);

  useEffect(() => {
    if (selectedCountry) {
      loadBenefitPlans();
    }
  }, [selectedCountry]);

  const loadCountries = async () => {
    try {
      const { data } = await api.get('/countries');
      setCountries(data);
      if (data.length > 0) {
        setSelectedCountry(data[0].id);
      }
    } catch (error) {
      showSnackbar('Failed to load countries', 'error');
    }
  };

  const loadBusinessTypes = async () => {
    try {
      const { data } = await api.get('/business-types');
      setBusinessTypes(data);
    } catch (error) {
      showSnackbar('Failed to load business types', 'error');
    }
  };

  const loadBenefitPlans = async () => {
    setLoading(true);
    try {
      const { data } = await api.get(`/enhanced-business-benefits/admin/${selectedCountry}`);
      
      // Group plans by business type
      const groupedPlans = {};
      data.plans.forEach(plan => {
        if (!groupedPlans[plan.business_type_name]) {
          groupedPlans[plan.business_type_name] = [];
        }
        groupedPlans[plan.business_type_name].push(plan);
      });
      
      setBenefitPlans(groupedPlans);
    } catch (error) {
      showSnackbar('Failed to load benefit plans', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showSnackbar = (message, severity = 'success') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleCreatePlan = async () => {
    try {
      await api.post(`/enhanced-business-benefits/${selectedCountry}/${newPlan.businessTypeId}/plans`, newPlan);
      showSnackbar('Benefit plan created successfully');
      setCreatePlanDialog(false);
      setNewPlan({
        planCode: '',
        planName: '',
        planDescription: '',
        planType: 'response_based',
        businessTypeId: '',
        config: {},
        allowedResponseTypes: []
      });
      loadBenefitPlans();
    } catch (error) {
      showSnackbar('Failed to create benefit plan', 'error');
    }
  };

  const handleUpdateConfig = async () => {
    try {
      let parsedConfigData;
      try {
        parsedConfigData = JSON.parse(configData);
      } catch (e) {
        showSnackbar('Invalid JSON format in configuration', 'error');
        return;
      }

      await api.put(`/enhanced-business-benefits/plans/${selectedPlan.id}/config`, {
        configKey,
        configData: parsedConfigData
      });
      
      showSnackbar('Configuration updated successfully');
      setEditConfigDialog(false);
      setConfigKey('');
      setConfigData('');
      setSelectedPlan(null);
      loadBenefitPlans();
    } catch (error) {
      showSnackbar('Failed to update configuration', 'error');
    }
  };

  const openConfigEditor = (plan, key = '') => {
    setSelectedPlan(plan);
    setConfigKey(key);
    setConfigData(key && plan.config_data[key] ? JSON.stringify(plan.config_data[key], null, 2) : '{}');
    setEditConfigDialog(true);
  };

  const renderPlanConfig = (config) => {
    return Object.entries(config).map(([key, value]) => (
      <Box key={key} sx={{ mt: 1 }}>
        <Typography variant="subtitle2" color="primary" gutterBottom>
          {key.replace(/_/g, ' ').toUpperCase()}
        </Typography>
        <Box sx={{ ml: 2 }}>
          {typeof value === 'object' ? (
            Object.entries(value).map(([subKey, subValue]) => (
              <Typography key={subKey} variant="body2" sx={{ mb: 0.5 }}>
                <strong>{subKey.replace(/_/g, ' ')}:</strong> {String(subValue)}
              </Typography>
            ))
          ) : (
            <Typography variant="body2">
              {String(value)}
            </Typography>
          )}
        </Box>
      </Box>
    ));
  };

  const getPlanTypeColor = (planType) => {
    switch (planType) {
      case 'response_based': return 'primary';
      case 'pricing_based': return 'secondary';
      case 'hybrid': return 'success';
      default: return 'default';
    }
  };

  const getPlanTypeLabel = (planType) => {
    switch (planType) {
      case 'response_based': return 'Response Based';
      case 'pricing_based': return 'Pricing Based';
      case 'hybrid': return 'Hybrid';
      default: return planType;
    }
  };

  return (
    <Box sx={{ p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Enhanced Business Benefits Management
      </Typography>
      
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Configure flexible benefit plans for different business types. Support response-based plans for service providers 
        and pricing-based plans for product sellers with hybrid options.
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12} md={4}>
          <FormControl fullWidth>
            <InputLabel>Country</InputLabel>
            <Select
              value={selectedCountry}
              onChange={(e) => setSelectedCountry(e.target.value)}
              label="Country"
            >
              {countries.map((country) => (
                <MenuItem key={country.id} value={country.id}>
                  {country.name}
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Button
            variant="contained"
            startIcon={<AddIcon />}
            onClick={() => setCreatePlanDialog(true)}
            disabled={!selectedCountry}
          >
            Create New Plan
          </Button>
        </Grid>
      </Grid>

      {loading ? (
        <Typography sx={{ mt: 3 }}>Loading benefit plans...</Typography>
      ) : (
        <Box sx={{ mt: 4 }}>
          {Object.entries(benefitPlans).map(([businessTypeName, plans]) => (
            <Accordion key={businessTypeName} defaultExpanded>
              <AccordionSummary expandIcon={<ExpandMoreIcon />}>
                <Typography variant="h6">
                  {businessTypeName} ({plans.length} plans)
                </Typography>
              </AccordionSummary>
              <AccordionDetails>
                <Grid container spacing={2}>
                  {plans.map((plan) => (
                    <Grid item xs={12} md={6} lg={4} key={plan.id}>
                      <Card>
                        <CardContent>
                          <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', mb: 2 }}>
                            <Typography variant="h6" gutterBottom>
                              {plan.plan_name}
                            </Typography>
                            <Chip 
                              label={getPlanTypeLabel(plan.plan_type)} 
                              color={getPlanTypeColor(plan.plan_type)}
                              size="small"
                            />
                          </Box>
                          
                          <Typography variant="body2" color="text.secondary" gutterBottom>
                            {plan.plan_description}
                          </Typography>
                          
                          <Typography variant="subtitle2" sx={{ mt: 2, mb: 1 }}>
                            Plan Code: {plan.plan_code}
                          </Typography>
                          
                          <FormControlLabel
                            control={<Switch checked={plan.is_active} disabled />}
                            label="Active"
                            sx={{ mb: 2 }}
                          />

                          {plan.config_data && Object.keys(plan.config_data).length > 0 && (
                            <Box sx={{ mt: 2 }}>
                              <Typography variant="subtitle2" gutterBottom>
                                Configuration:
                              </Typography>
                              {renderPlanConfig(plan.config_data)}
                            </Box>
                          )}

                          {plan.allowed_response_types?.length > 0 && (
                            <Box sx={{ mt: 2 }}>
                              <Typography variant="subtitle2" gutterBottom>
                                Can Respond To:
                              </Typography>
                              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                                {plan.allowed_response_types.map((typeId) => {
                                  const businessType = businessTypes.find(bt => bt.id === typeId);
                                  return (
                                    <Chip
                                      key={typeId}
                                      label={businessType?.name || `Type ${typeId}`}
                                      size="small"
                                      variant="outlined"
                                    />
                                  );
                                })}
                              </Box>
                            </Box>
                          )}
                        </CardContent>
                        
                        <CardActions>
                          <Tooltip title="Edit Responses Config">
                            <IconButton
                              size="small"
                              onClick={() => openConfigEditor(plan, 'responses')}
                            >
                              <EditIcon />
                            </IconButton>
                          </Tooltip>
                          
                          <Tooltip title="Edit Pricing Config">
                            <IconButton
                              size="small"
                              onClick={() => openConfigEditor(plan, 'pricing')}
                            >
                              <SettingsIcon />
                            </IconButton>
                          </Tooltip>
                          
                          <Tooltip title="Edit Features Config">
                            <IconButton
                              size="small"
                              onClick={() => openConfigEditor(plan, 'features')}
                            >
                              <SettingsIcon />
                            </IconButton>
                          </Tooltip>
                        </CardActions>
                      </Card>
                    </Grid>
                  ))}
                </Grid>
              </AccordionDetails>
            </Accordion>
          ))}
        </Box>
      )}

      {/* Create Plan Dialog */}
      <Dialog open={createPlanDialog} onClose={() => setCreatePlanDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>Create New Benefit Plan</DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Business Type</InputLabel>
                <Select
                  value={newPlan.businessTypeId}
                  onChange={(e) => setNewPlan({ ...newPlan, businessTypeId: e.target.value })}
                  label="Business Type"
                >
                  {businessTypes.map((type) => (
                    <MenuItem key={type.id} value={type.id}>
                      {type.name}
                    </MenuItem>
                  ))}
                </Select>
              </FormControl>
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <FormControl fullWidth>
                <InputLabel>Plan Type</InputLabel>
                <Select
                  value={newPlan.planType}
                  onChange={(e) => setNewPlan({ ...newPlan, planType: e.target.value })}
                  label="Plan Type"
                >
                  <MenuItem value="response_based">Response Based</MenuItem>
                  <MenuItem value="pricing_based">Pricing Based</MenuItem>
                  <MenuItem value="hybrid">Hybrid</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Code"
                value={newPlan.planCode}
                onChange={(e) => setNewPlan({ ...newPlan, planCode: e.target.value })}
                placeholder="e.g., free, premium, pay_per_click"
              />
            </Grid>
            
            <Grid item xs={12} sm={6}>
              <TextField
                fullWidth
                label="Plan Name"
                value={newPlan.planName}
                onChange={(e) => setNewPlan({ ...newPlan, planName: e.target.value })}
                placeholder="e.g., Free Plan, Premium Plan"
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Plan Description"
                value={newPlan.planDescription}
                onChange={(e) => setNewPlan({ ...newPlan, planDescription: e.target.value })}
                multiline
                rows={2}
                placeholder="Description of what this plan offers"
              />
            </Grid>
          </Grid>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setCreatePlanDialog(false)}>Cancel</Button>
          <Button onClick={handleCreatePlan} variant="contained">Create Plan</Button>
        </DialogActions>
      </Dialog>

      {/* Edit Config Dialog */}
      <Dialog open={editConfigDialog} onClose={() => setEditConfigDialog(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          Edit Configuration - {selectedPlan?.plan_name}
        </DialogTitle>
        <DialogContent>
          <Grid container spacing={2} sx={{ mt: 1 }}>
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Configuration Key"
                value={configKey}
                onChange={(e) => setConfigKey(e.target.value)}
                placeholder="e.g., responses, pricing, features"
              />
            </Grid>
            
            <Grid item xs={12}>
              <TextField
                fullWidth
                label="Configuration Data (JSON)"
                value={configData}
                onChange={(e) => setConfigData(e.target.value)}
                multiline
                rows={10}
                placeholder="Enter JSON configuration data"
                helperText="Enter valid JSON data for the configuration"
              />
            </Grid>
          </Grid>
          
          <Alert severity="info" sx={{ mt: 2 }}>
            <Typography variant="body2">
              <strong>Example configurations:</strong><br/>
              <strong>Responses:</strong> {`{"responses_per_month": 3, "contact_revealed": false, "can_message_requester": false}`}<br/>
              <strong>Pricing:</strong> {`{"model": "per_click", "price_per_click": 0.50, "currency": "USD"}`}<br/>
              <strong>Features:</strong> {`{"basic_profile": true, "analytics": false, "priority_support": false}`}
            </Typography>
          </Alert>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setEditConfigDialog(false)}>Cancel</Button>
          <Button onClick={handleUpdateConfig} variant="contained">Update Configuration</Button>
        </DialogActions>
      </Dialog>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default EnhancedBusinessBenefits;
