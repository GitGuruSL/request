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
  Stack
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon } from '@mui/icons-material';
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
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [countryPricing, setCountryPricing] = useState([]);
  const [cpForm, setCpForm] = useState({
    country_code: '', price: 0, currency: 'USD', response_limit: null,
    notifications_enabled: true, show_contact_details: true
  });

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

  const loadCountryPricing = async (planId, countryCodeFilter) => {
    try {
      const params = {};
      if (countryCodeFilter) params.country = countryCodeFilter;
      const res = await api.get(`/subscription-plans-new/${planId}/country-pricing`, { params });
      const rows = Array.isArray(res.data?.data) ? res.data.data : (res.data || []);
      setCountryPricing(rows);
    } catch (e) {
      console.error(e);
      setCountryPricing([]);
    }
  };

  const upsertCountryPricing = async () => {
    if (!selectedPlan) return;
    try {
      await api.post(`/subscription-plans-new/${selectedPlan.id}/country-pricing`, cpForm);
      setSuccess('Country pricing saved');
      await loadCountryPricing(selectedPlan.id, isCountryAdmin ? myCountry : undefined);
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to save pricing');
    }
  };

  useEffect(() => { loadPlans(); }, []);

  useEffect(() => {
    if (selectedPlan) {
      loadCountryPricing(selectedPlan.id, isCountryAdmin ? myCountry : undefined);
      setCpForm((prev) => ({ ...prev, country_code: isCountryAdmin ? myCountry : (prev.country_code || myCountry) }));
    }
  }, [selectedPlan, isCountryAdmin, myCountry]);

  return (
    <Box>
      <Typography variant="h4" gutterBottom>Subscriptions</Typography>
      {error && <Alert severity="error" sx={{ mb: 2 }} onClose={() => setError('')}>{error}</Alert>}
      {success && <Alert severity="success" sx={{ mb: 2 }} onClose={() => setSuccess('')}>{success}</Alert>}

      <Stack direction="row" spacing={2} alignItems="center" sx={{ mb: 2 }}>
        <Chip label={isSuperAdmin ? 'Super Admin' : (isCountryAdmin ? `Country Admin (${myCountry})` : (adminData?.role || 'Admin'))} />
        {isSuperAdmin && (
          <Button variant="contained" startIcon={<AddIcon />} onClick={openCreate}>New Plan</Button>
        )}
      </Stack>

      <Paper variant="outlined" sx={{ p: 2, mb: 3 }}>
        <Typography variant="h6" gutterBottom>Available Plans</Typography>
        <TableContainer>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Code</TableCell>
                <TableCell>Type</TableCell>
                <TableCell>Plan Type</TableCell>
                <TableCell align="right">Price</TableCell>
                <TableCell>Currency</TableCell>
                <TableCell>Active</TableCell>
                <TableCell align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {plans.map(p => (
                <TableRow key={p.id} hover selected={selectedPlan?.id === p.id} onClick={() => setSelectedPlan(p)}>
                  <TableCell>{p.name}</TableCell>
                  <TableCell>{p.code}</TableCell>
                  <TableCell>{p.type}</TableCell>
                  <TableCell>{p.plan_type}</TableCell>
                  <TableCell align="right">{Number(p.price || 0).toFixed(2)}</TableCell>
                  <TableCell>{p.currency}</TableCell>
                  <TableCell>{p.is_active ? <Chip label="Yes" size="small" color="success" /> : <Chip label="No" size="small" />}</TableCell>
                  <TableCell align="right">
                    {isSuperAdmin && (
                      <Button size="small" startIcon={<EditIcon />} onClick={(e)=>{ e.stopPropagation(); openEdit(p); }}>Edit</Button>
                    )}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Paper>

      {selectedPlan && (
        <Paper variant="outlined" sx={{ p: 2 }}>
          <Typography variant="h6" gutterBottom>Country Pricing for: {selectedPlan.name}</Typography>
          <Stack direction="row" spacing={2} sx={{ mb: 2 }}>
            {!isCountryAdmin && (
              <TextField label="Country Code" size="small" value={cpForm.country_code} onChange={(e)=>setCpForm({...cpForm, country_code: e.target.value.toUpperCase()})} placeholder="e.g., LK" />
            )}
            {isCountryAdmin && (
              <TextField label="Country Code" size="small" value={myCountry} disabled />
            )}
            <TextField label="Price" type="number" size="small" value={cpForm.price} onChange={(e)=>setCpForm({...cpForm, price: Number(e.target.value)})} />
            <TextField label="Currency" size="small" value={cpForm.currency} onChange={(e)=>setCpForm({...cpForm, currency: e.target.value.toUpperCase()})} />
            <TextField label="Response Limit (optional)" type="number" size="small" value={cpForm.response_limit ?? ''} onChange={(e)=>setCpForm({...cpForm, response_limit: e.target.value===''? null : Number(e.target.value)})} />
            <Button variant="contained" onClick={upsertCountryPricing}>Save Country Pricing</Button>
          </Stack>

          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Country</TableCell>
                  <TableCell align="right">Price</TableCell>
                  <TableCell>Currency</TableCell>
                  <TableCell>Response Limit</TableCell>
                  <TableCell>Show Contact</TableCell>
                  <TableCell>Notifications</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {countryPricing.map(row => (
                  <TableRow key={`${row.plan_id}-${row.country_code}`}>
                    <TableCell>{row.country_code}</TableCell>
                    <TableCell align="right">{Number(row.price || 0).toFixed(2)}</TableCell>
                    <TableCell>{row.currency}</TableCell>
                    <TableCell>{row.response_limit ?? '-'}</TableCell>
                    <TableCell>{row.show_contact_details ? 'Yes' : 'No'}</TableCell>
                    <TableCell>{row.notifications_enabled ? 'Yes' : 'No'}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      )}

      <Dialog open={open} onClose={closeDialog} fullWidth maxWidth="sm">
        <DialogTitle>{editing ? 'Edit Plan' : 'Create Plan'}</DialogTitle>
        <DialogContent>
          <Stack spacing={2} sx={{ mt: 1 }}>
            <TextField label="Code" value={form.code} onChange={(e)=>setForm({...form, code: e.target.value})} fullWidth />
            <TextField label="Name" value={form.name} onChange={(e)=>setForm({...form, name: e.target.value})} fullWidth />
            <FormControl fullWidth>
              <InputLabel>Type</InputLabel>
              <Select value={form.type} label="Type" onChange={(e)=>setForm({...form, type: e.target.value})}>
                <MenuItem value="business">Business</MenuItem>
                <MenuItem value="individual">Individual</MenuItem>
              </Select>
            </FormControl>
            <FormControl fullWidth>
              <InputLabel>Plan Type</InputLabel>
              <Select value={form.plan_type} label="Plan Type" onChange={(e)=>setForm({...form, plan_type: e.target.value})}>
                <MenuItem value="recurring">Recurring</MenuItem>
                <MenuItem value="ppc">Pay Per Click</MenuItem>
              </Select>
            </FormControl>
            <TextField label="Description" value={form.description} onChange={(e)=>setForm({...form, description: e.target.value})} multiline rows={3} />
            <Stack direction="row" spacing={2}>
              <TextField label="Price" type="number" value={form.price} onChange={(e)=>setForm({...form, price: Number(e.target.value)})} />
              <TextField label="Currency" value={form.currency} onChange={(e)=>setForm({...form, currency: e.target.value.toUpperCase()})} />
              <TextField label="Duration (days)" type="number" value={form.duration_days} onChange={(e)=>setForm({...form, duration_days: Number(e.target.value)})} />
            </Stack>
          </Stack>
        </DialogContent>
        <DialogActions>
          <Button onClick={closeDialog}>Cancel</Button>
          <Button variant="contained" onClick={savePlan}>{editing ? 'Update' : 'Create'}</Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
