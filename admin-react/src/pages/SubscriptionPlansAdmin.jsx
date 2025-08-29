import React, { useEffect, useMemo, useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  Button,
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
  TextField,
  MenuItem,
  Select,
  InputLabel,
  FormControl,
  Chip,
  Alert,
  Stack,
  Grid,
  Card,
  CardContent,
  CardActions
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon, Check as CheckIcon, Pending as PendingIcon } from '@mui/icons-material';
import api from '../services/apiClient';
import useCountryFilter from '../hooks/useCountryFilter';

const emptyPlan = {
  code: '',
  name: '',
  type: 'business',
  plan_type: 'recurring',
  description: '',
  price: 0,
  currency: 'USD',
  duration_days: 30,
  features: [],
  limitations: {},
  countries: null,
  is_active: true,
  is_default_plan: false,
  requires_country_pricing: false,
};

export default function SubscriptionPlansAdmin() {
  const { adminData, isSuperAdmin, isCountryAdmin } = useCountryFilter();
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyPlan);
  const [myPricing, setMyPricing] = useState([]);
  const [pendingApprovals, setPendingApprovals] = useState([]);

  const myCountry = useMemo(() => adminData?.country || 'LK', [adminData]);

  const loadPlans = async () => {
    setLoading(true); setError('');
    try {
      const res = await api.get('/subscription-plans-new', { params: { active: 'true' } });
      const list = Array.isArray(res.data?.data) ? res.data.data : (res.data || []);
      setPlans(list);
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to load plans');
    } finally { setLoading(false); }
  };

  // Load my country's pricing (for country admin) or pending approvals (for super admin)
  const loadMyData = async () => {
    if (isCountryAdmin) {
      // Load pricing for my country
      try {
        const allPricing = await Promise.all(
          plans.map(async (plan) => {
            try {
              const res = await api.get(`/subscription-plans-new/${plan.id}/country-pricing`, 
                { params: { country: myCountry } });
              const pricing = res.data?.data?.[0];
              return { ...plan, pricing };
            } catch {
              return { ...plan, pricing: null };
            }
          })
        );
        setMyPricing(allPricing);
      } catch (e) {
        console.error('Failed to load my pricing', e);
      }
    } else if (isSuperAdmin) {
      // Load pending approvals
      try {
        const res = await api.get('/subscription-plans-new/pending-country-pricing');
        setPendingApprovals(res.data?.data || []);
      } catch (e) {
        console.error('Failed to load pending approvals', e);
      }
    }
  };

  const openCreate = () => { setEditing(null); setForm(emptyPlan); setOpen(true); };
  const openEdit = (p) => { setEditing(p); setForm({ ...emptyPlan, ...p }); setOpen(true); };
  const closeDialog = () => { setOpen(false); setError(''); };

  const savePlan = async () => {
    try {
      setError(''); setSuccess('');
      if (editing) {
        await api.put(`/subscription-plans-new/${editing.id}`, form);
        setSuccess('Plan updated');
      } else {
        await api.post('/subscription-plans-new', form);
        setSuccess('Plan created');
      }
      setOpen(false);
      await loadPlans();
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Save failed');
    }
  };

  const savePricing = async (plan, price, responseLimit) => {
    try {
      // Auto-load currency for country admin
      let currency = 'USD';
      try {
        const res = await api.get(`/countries/${myCountry}`);
        currency = res.data?.data?.default_currency || res.data?.default_currency || 'USD';
      } catch {}

      await api.post(`/subscription-plans-new/${plan.id}/country-pricing`, {
        country_code: myCountry,
        price: Number(price),
        currency,
        response_limit: responseLimit ? Number(responseLimit) : null,
        notifications_enabled: true,
        show_contact_details: true
      });
      setSuccess('Pricing saved for approval');
      await loadMyData();
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to save pricing');
    }
  };

  const approvePricing = async (item, approve = true) => {
    try {
      await api.put(`/subscription-plans-new/${item.plan_id}/country-pricing/${item.country_code}`, 
        { is_active: approve });
      setSuccess(approve ? 'Pricing approved' : 'Pricing rejected');
      await loadMyData();
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to update approval');
    }
  };

  useEffect(() => { loadPlans(); }, []);
  useEffect(() => { if (plans.length) loadMyData(); }, [plans, isCountryAdmin, isSuperAdmin, myCountry]);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>
        {isSuperAdmin ? 'Subscription Management' : `My Country Pricing (${myCountry})`}
      </Typography>
      
      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess('')}>{success}</Alert>}

      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 3 }}>
        <Chip 
          label={isSuperAdmin ? 'Super Admin' : `Country Admin (${myCountry})`} 
          color="primary" 
        />
        {isSuperAdmin && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>
            Create New Plan
          </Button>
        )}
      </Stack>

      {/* Super Admin View */}
      {isSuperAdmin && (
        <>
          <Paper sx={{ p: 3, mb: 3 }}>
            <Typography variant="h6" gutterBottom>Global Plans</Typography>
            <Grid container spacing={2}>
              {plans.map((plan) => (
                <Grid size={{ xs: 12, md: 6, lg: 4 }} key={plan.id}>
                  <Card>
                    <CardContent>
                      <Typography variant="h6">{plan.name}</Typography>
                      <Typography color="textSecondary" gutterBottom>{plan.code}</Typography>
                      <Typography variant="body2">
                        Type: {plan.type} • {plan.plan_type}
                      </Typography>
                      <Chip 
                        label={plan.is_active ? 'Active' : 'Inactive'} 
                        color={plan.is_active ? 'success' : 'default'}
                        size="small"
                        sx={{ mt: 1 }}
                      />
                    </CardContent>
                    <CardActions>
                      <Button size="small" startIcon={<EditIcon />} onClick={() => openEdit(plan)}>
                        Edit Plan
                      </Button>
                    </CardActions>
                  </Card>
                </Grid>
              ))}
            </Grid>
          </Paper>

          {pendingApprovals.length > 0 && (
            <Paper sx={{ p: 3 }}>
              <Typography variant="h6" gutterBottom>
                Pending Approvals ({pendingApprovals.length})
              </Typography>
              <TableContainer>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell>Country</TableCell>
                      <TableCell>Plan</TableCell>
                      <TableCell>Price</TableCell>
                      <TableCell>Currency</TableCell>
                      <TableCell>Response Limit</TableCell>
                      <TableCell align="right">Actions</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {pendingApprovals.map((item) => (
                      <TableRow key={`${item.plan_id}-${item.country_code}`}>
                        <TableCell>{item.country_code}</TableCell>
                        <TableCell>{item.plan_name}</TableCell>
                        <TableCell>{Number(item.price || 0).toFixed(2)}</TableCell>
                        <TableCell>{item.currency}</TableCell>
                        <TableCell>{item.response_limit || 'Unlimited'}</TableCell>
                        <TableCell align="right">
                          <Button 
                            size="small" 
                            color="success" 
                            startIcon={<CheckIcon />}
                            onClick={() => approvePricing(item, true)}
                            sx={{ mr: 1 }}
                          >
                            Approve
                          </Button>
                          <Button 
                            size="small" 
                            color="error"
                            onClick={() => approvePricing(item, false)}
                          >
                            Reject
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </TableContainer>
            </Paper>
          )}
        </>
      )}

      {/* Country Admin View */}
      {isCountryAdmin && (
        <Paper sx={{ p: 3 }}>
          <Typography variant="h6" gutterBottom>Set Pricing for Your Country</Typography>
          <Grid container spacing={3}>
            {myPricing.map((item) => (
              <Grid size={{ xs: 12, md: 6 }} key={item.id}>
                <PricingCard 
                  plan={item} 
                  pricing={item.pricing}
                  onSave={savePricing}
                />
              </Grid>
            ))}
          </Grid>
        </Paper>
      )}

      {/* Plan Creation/Edit Dialog */}
      <Dialog open={open} onClose={closeDialog} fullWidth maxWidth="sm">
        <DialogTitle>{editing ? 'Edit Plan' : 'Create Plan'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField 
              label="Plan Code" 
              value={form.code} 
              onChange={(e) => setForm({...form, code: e.target.value})} 
              fullWidth 
            />
            <TextField 
              label="Plan Name" 
              value={form.name} 
              onChange={(e) => setForm({...form, name: e.target.value})} 
              fullWidth 
            />
            <FormControl fullWidth>
              <InputLabel>User Type</InputLabel>
              <Select 
                value={form.type} 
                label="User Type" 
                onChange={(e) => setForm({...form, type: e.target.value})}
              >
                <MenuItem value="business">Business</MenuItem>
                <MenuItem value="individual">Individual</MenuItem>
              </Select>
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Plan Type</InputLabel>
              <Select 
                value={form.plan_type} 
                label="Plan Type" 
                onChange={(e) => setForm({...form, plan_type: e.target.value})}
              >
                <MenuItem value="recurring">Monthly Subscription</MenuItem>
                <MenuItem value="ppc">Pay Per Click</MenuItem>
              </Select>
            </FormControl>
            <TextField 
              label="Description" 
              value={form.description} 
              onChange={(e) => setForm({...form, description: e.target.value})} 
              multiline 
              rows={3} 
              fullWidth
            />
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={closeDialog}>Cancel</Button>
          <Button variant="contained" onClick={savePlan}>
            {editing ? 'Update' : 'Create'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}

// Pricing Card Component for Country Admin
function PricingCard({ plan, pricing, onSave }) {
  const [price, setPrice] = useState(pricing?.price || '');
  const [responseLimit, setResponseLimit] = useState(pricing?.response_limit || '');
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave(plan, price, responseLimit);
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
        <Typography variant="body2" sx={{ mb: 2 }}>
          {plan.type} • {plan.plan_type}
        </Typography>
        
        <Chip 
          label={status} 
          color={statusColor}
          icon={pricing?.is_active ? <CheckIcon /> : <PendingIcon />}
          size="small"
          sx={{ mb: 2 }}
        />

        <Stack spacing={2}>
          <TextField
            label="Price"
            type="number"
            value={price}
            onChange={(e) => setPrice(e.target.value)}
            fullWidth
            size="small"
          />
          <TextField
            label="Response Limit (optional)"
            type="number"
            value={responseLimit}
            onChange={(e) => setResponseLimit(e.target.value)}
            placeholder="Leave empty for unlimited"
            fullWidth
            size="small"
          />
        </Stack>
      </CardContent>
      <CardActions>
        <Button 
          variant="contained" 
          onClick={handleSave}
          disabled={saving || !price}
          fullWidth
        >
          {saving ? 'Saving...' : 'Save Pricing'}
        </Button>
      </CardActions>
    </Card>
  );
}