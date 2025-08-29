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
  FormControlLabel,
  Checkbox,
  Chip,
  Alert,
  Stack,
  Tabs,
  Tab
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
  // Super admin country selection + overview
  const [countries, setCountries] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState('');
  const [pricingMap, setPricingMap] = useState({}); // planId -> pricing row for selected country
  const [tab, setTab] = useState(0); // 0: Plans, 1: Country Pricing, 2: Approvals
  const [pending, setPending] = useState([]);

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
      const payload = { ...cpForm };
      // Only super admin can set active on creation/update; country admin submissions are pending approval
      if (!isSuperAdmin) delete payload.is_active;
      await api.post(`/subscription-plans-new/${selectedPlan.id}/country-pricing`, payload);
      setSuccess('Country pricing saved');
      await loadCountryPricing(selectedPlan.id, isCountryAdmin ? myCountry : undefined);
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to save pricing');
    }
  };

  const toggleApproval = async (row, flag) => {
    if (!selectedPlan) return;
    try {
      await api.put(`/subscription-plans-new/${selectedPlan.id}/country-pricing/${row.country_code}`, { is_active: !!flag });
      setSuccess(flag ? 'Pricing approved' : 'Pricing deactivated');
      await loadCountryPricing(selectedPlan.id, isCountryAdmin ? myCountry : undefined);
    } catch (e) {
      console.error(e);
      setError(e.response?.data?.error || 'Failed to update approval');
    }
  };

  const loadCountryCurrency = async (code) => {
    if (!code) return;
    try {
      const res = await api.get(`/countries/${code}`);
      const cur = res.data?.data?.default_currency || res.data?.default_currency;
      if (cur) setCpForm((prev) => ({ ...prev, currency: cur }));
    } catch (e) {
      // ignore; keep manual currency
    }
  };

  useEffect(() => { loadPlans(); }, []);

  // Load countries for super admin dropdown
  const loadCountries = async () => {
    try {
      const res = await api.get('/countries', { params: { public: 1 } });
      const rows = res.data?.data || res.data || [];
      const list = rows.map(r => ({ code: r.code, name: r.name, currency: r.default_currency }));
      setCountries(list);
      if (!selectedCountry && list.length) setSelectedCountry(adminData?.country || list[0].code);
    } catch (e) {
      // non-fatal
    }
  };
  useEffect(() => { if (isSuperAdmin) loadCountries(); }, [isSuperAdmin]);

  useEffect(() => {
    if (selectedPlan) {
      loadCountryPricing(selectedPlan.id, isCountryAdmin ? myCountry : undefined);
      setCpForm((prev) => ({ ...prev, country_code: isCountryAdmin ? myCountry : (prev.country_code || myCountry), is_active: isSuperAdmin ? false : undefined }));
      // Only country admins: preload currency from their country
      if (isCountryAdmin) loadCountryCurrency(myCountry);
    }
  }, [selectedPlan, isCountryAdmin, isSuperAdmin, myCountry]);

  // Only auto-load currency for country admins when country_code changes
  useEffect(() => {
    if (isCountryAdmin && cpForm.country_code) {
      loadCountryCurrency(cpForm.country_code);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isCountryAdmin, cpForm.country_code]);

  // Build pricing map for selected country (super admin overview)
  useEffect(() => {
    const fetchMap = async () => {
      if (!isSuperAdmin || !selectedCountry || !plans.length) { setPricingMap({}); return; }
      try {
        const results = await Promise.all(
          plans.map(p => api.get(`/subscription-plans-new/${p.id}/country-pricing`, { params: { country: selectedCountry } })
            .then(r => ({ planId: p.id, row: (r.data?.data?.[0] || null) }))
            .catch(() => ({ planId: p.id, row: null })))
        );
        const map = {};
        results.forEach(({ planId, row }) => { map[planId] = row; });
        setPricingMap(map);
      } catch (_) { setPricingMap({}); }
    };
    fetchMap();
  }, [isSuperAdmin, selectedCountry, plans]);

  // Load pending pricing for approvals tab
  const loadPending = async () => {
    try {
      const params = isSuperAdmin ? (selectedCountry ? { country: selectedCountry } : {}) : {};
      const res = await api.get('/subscription-plans-new/pending-country-pricing', { params });
      setPending(res.data?.data || []);
    } catch (_) { setPending([]); }
  };
  useEffect(() => { if (tab === 2) loadPending(); }, [tab, selectedCountry, isSuperAdmin]);

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
        {isSuperAdmin && (
          <FormControl size="small" sx={{ minWidth: 220, ml: 'auto' }}>
            <InputLabel>Country</InputLabel>
            <Select value={selectedCountry} label="Country" onChange={(e)=>setSelectedCountry(e.target.value)}>
              {countries.map(c => (
                <MenuItem key={c.code} value={c.code}>{c.name} ({c.code})</MenuItem>
              ))}
            </Select>
          </FormControl>
        )}
      </Stack>

  {isSuperAdmin && selectedCountry && tab === 0 && (
        <Paper variant="outlined" sx={{ p: 2, mb: 3 }}>
          <Typography variant="h6" gutterBottom>
    Country Overview: {selectedCountry}
          </Typography>
          <TableContainer>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Plan</TableCell>
                  <TableCell>Code</TableCell>
                  <TableCell>Type</TableCell>
                  <TableCell align="right">Price</TableCell>
                  <TableCell>Currency</TableCell>
                  <TableCell>Response Limit</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell align="right">Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {plans.map(p => {
                  const row = pricingMap[p.id];
                  return (
                    <TableRow key={`ov-${p.id}`}>
                      <TableCell>{p.name}</TableCell>
                      <TableCell>{p.code}</TableCell>
                      <TableCell>{p.plan_type}</TableCell>
                      <TableCell align="right">{row ? Number(row.price||0).toFixed(2) : '—'}</TableCell>
                      <TableCell>{row ? row.currency : '—'}</TableCell>
                      <TableCell>{row ? (row.response_limit ?? '-') : '—'}</TableCell>
                      <TableCell>{row ? (row.is_active ? <Chip size="small" color="success" label="Active" /> : <Chip size="small" label="Pending" />) : <Chip size="small" label="No Pricing" />}</TableCell>
                      <TableCell align="right">
                        {row ? (
                          row.is_active ? (
                            <Button size="small" color="warning" onClick={()=>toggleApproval(row, false)}>Deactivate</Button>
                          ) : (
                            <Button size="small" color="success" onClick={()=>toggleApproval(row, true)}>Approve</Button>
                          )
                        ) : (
                          <Button size="small" onClick={()=>{ setSelectedPlan(p); setCpForm({ country_code: selectedCountry, price: 0, currency: '', response_limit: null, notifications_enabled: true, show_contact_details: true, is_active: true }); }}>Add Pricing</Button>
                        )}
                      </TableCell>
                    </TableRow>
                  );
                })}
              </TableBody>
            </Table>
          </TableContainer>
        </Paper>
      )}

      <Paper variant="outlined" sx={{ p: 2, mb: 3 }}>
        <Tabs value={tab} onChange={(_,v)=>setTab(v)} sx={{ mb: 2 }}>
          <Tab label="Plans" />
          <Tab label="Country Pricing" />
          <Tab label="Approvals" />
        </Tabs>

        {tab === 0 && (
          <>
            <Typography variant="h6" gutterBottom>Global Plans</Typography>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Name</TableCell>
                    <TableCell>Code</TableCell>
                    <TableCell>Type</TableCell>
                    <TableCell>Plan Type</TableCell>
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
          </>
        )}

        {tab === 1 && selectedPlan && (
          <>
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
              {isSuperAdmin && (
                <FormControlLabel control={<Checkbox checked={!!cpForm.is_active} onChange={(e)=>setCpForm({...cpForm, is_active: e.target.checked})} />} label="Active (visible to users)" />
              )}
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
                    <TableCell>Status</TableCell>
                    {isSuperAdmin && <TableCell align="right">Approval</TableCell>}
                  </TableRow>
                </TableHead>
                <TableBody>
                  {countryPricing.map(row => (
                    <TableRow key={`${row.plan_id}-${row.country_code}`}>
                      <TableCell>{row.country_code}</TableCell>
                      <TableCell align="right">{Number(row.price || 0).toFixed(2)}</TableCell>
                      <TableCell>{row.currency}</TableCell>
                      <TableCell>{row.response_limit ?? '-'}</TableCell>
                      <TableCell>{row.is_active ? <Chip size="small" color="success" label="Active" /> : <Chip size="small" label="Pending" />}</TableCell>
                      {isSuperAdmin && (
                        <TableCell align="right">
                          {row.is_active ? (
                            <Button size="small" color="warning" onClick={()=>toggleApproval(row, false)}>Deactivate</Button>
                          ) : (
                            <Button size="small" color="success" onClick={()=>toggleApproval(row, true)}>Approve</Button>
                          )}
                        </TableCell>
                      )}
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </>
        )}

        {tab === 2 && (
          <>
            <Typography variant="h6" gutterBottom>Pending Approvals</Typography>
            <TableContainer>
              <Table size="small">
                <TableHead>
                  <TableRow>
                    <TableCell>Country</TableCell>
                    <TableCell>Plan</TableCell>
                    <TableCell>Code</TableCell>
                    <TableCell align="right">Price</TableCell>
                    <TableCell>Currency</TableCell>
                    <TableCell>Response Limit</TableCell>
                    <TableCell align="right">Actions</TableCell>
                  </TableRow>
                </TableHead>
                <TableBody>
                  {pending.map(row => (
                    <TableRow key={`pend-${row.plan_id}-${row.country_code}`}>
                      <TableCell>{row.country_code}</TableCell>
                      <TableCell>{row.plan_name}</TableCell>
                      <TableCell>{row.plan_code}</TableCell>
                      <TableCell align="right">{Number(row.price || 0).toFixed(2)}</TableCell>
                      <TableCell>{row.currency}</TableCell>
                      <TableCell>{row.response_limit ?? '-'}</TableCell>
                      <TableCell align="right">
                        {isSuperAdmin ? (
                          <>
                            <Button size="small" color="success" onClick={()=>{ setSelectedPlan({ id: row.plan_id, name: row.plan_name }); toggleApproval(row, true); }}>Approve</Button>
                            <Button size="small" sx={{ ml: 1 }} onClick={()=>{ setSelectedPlan({ id: row.plan_id, name: row.plan_name }); setCpForm({ country_code: row.country_code, price: row.price, currency: row.currency, response_limit: row.response_limit, notifications_enabled: row.notifications_enabled, show_contact_details: row.show_contact_details, is_active: row.is_active }); setTab(1); }}>Edit</Button>
                          </>
                        ) : (
                          <Button size="small" onClick={()=>{ setSelectedPlan({ id: row.plan_id, name: row.plan_name }); setCpForm({ country_code: row.country_code, price: row.price, currency: row.currency, response_limit: row.response_limit, notifications_enabled: row.notifications_enabled, show_contact_details: row.show_contact_details, is_active: row.is_active }); setTab(1); }}>Edit</Button>
                        )}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </TableContainer>
          </>
        )}
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
            {isSuperAdmin && (
              <FormControlLabel control={<Checkbox checked={!!cpForm.is_active} onChange={(e)=>setCpForm({...cpForm, is_active: e.target.checked})} />} label="Active (visible to users)" />
            )}
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
                  <TableCell>Status</TableCell>
                  {isSuperAdmin && <TableCell align="right">Approval</TableCell>}
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
                    <TableCell>{row.is_active ? <Chip size="small" color="success" label="Active" /> : <Chip size="small" label="Pending" />}</TableCell>
                    {isSuperAdmin && (
                      <TableCell align="right">
                        {row.is_active ? (
                          <Button size="small" color="warning" onClick={()=>toggleApproval(row, false)}>Deactivate</Button>
                        ) : (
                          <Button size="small" color="success" onClick={()=>toggleApproval(row, true)}>Approve</Button>
                        )}
                      </TableCell>
                    )}
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
