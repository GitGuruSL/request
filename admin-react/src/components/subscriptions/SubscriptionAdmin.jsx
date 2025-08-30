import React, { useEffect, useState } from 'react';
import { Box, Typography, Paper, TextField, Button, Select, MenuItem, FormControl, InputLabel, Switch, FormControlLabel, Divider, Chip } from '@mui/material';
import apiClient from '../../services/apiClient';

export default function SubscriptionAdmin() {
  const [plans, setPlans] = useState([]);
  const [form, setForm] = useState({ code: '', name: '', plan_type: 'basic', description: '', default_responses_per_month: 3 });

  const [countryCode, setCountryCode] = useState('LK');
  const [countrySettings, setCountrySettings] = useState([]);
  const [settingsForm, setSettingsForm] = useState({ plan_code: 'basic', currency: 'LKR', price: '', responses_per_month: 3, ppc_price: '', is_active: false });

  const [businessTypes, setBusinessTypes] = useState([]);
  const [mappings, setMappings] = useState([]);
  const [mappingForm, setMappingForm] = useState({ business_type_id: '', plan_code: 'basic', allowed_request_types: ['item','service'], is_active: true });

  useEffect(() => {
    loadPlans();
  }, []);

  useEffect(() => {
    if (countryCode) {
      loadCountrySettings(countryCode);
      loadBusinessTypes(countryCode);
      loadMappings(countryCode);
    }
  }, [countryCode]);

  async function loadPlans() {
    try {
      const { data } = await apiClient.get('/api/subscriptions/plans');
      setPlans(data || []);
    } catch (e) {
      console.error('Load plans failed', e);
    }
  }

  async function createOrUpdatePlan() {
    try {
      await apiClient.post('/api/subscriptions/plans', form);
      await loadPlans();
    } catch (e) {
      console.error('Create plan failed', e);
    }
  }

  async function approvePlan(code) {
    try {
      await apiClient.post(`/api/subscriptions/plans/${code}/approve`);
      await loadPlans();
    } catch (e) {
      console.error('Approve plan failed', e);
    }
  }

  async function loadCountrySettings(cc) {
    try {
      const { data } = await apiClient.get('/api/subscriptions/country-settings', { params: { country_code: cc } });
      setCountrySettings(data || []);
    } catch (e) {
      console.error('Load country settings failed', e);
    }
  }

  async function upsertCountrySettings() {
    try {
      await apiClient.post('/api/subscriptions/country-settings', { country_code: countryCode, ...settingsForm });
      await loadCountrySettings(countryCode);
    } catch (e) {
      console.error('Upsert country settings failed', e);
    }
  }

  async function loadBusinessTypes(cc) {
    try {
      const { data } = await apiClient.get('/api/subscriptions/business-types', { params: { country_code: cc } });
      setBusinessTypes(data || []);
    } catch (e) {
      console.error('Load business types failed', e);
    }
  }

  async function loadMappings(cc) {
    try {
      const { data } = await apiClient.get('/api/subscriptions/mappings', { params: { country_code: cc } });
      setMappings(data || []);
    } catch (e) {
      console.error('Load mappings failed', e);
    }
  }

  async function upsertMapping() {
    try {
      const payload = { country_code: countryCode, ...mappingForm };
      await apiClient.post('/api/subscriptions/mappings', payload);
      setMappingForm({ business_type_id: '', plan_code: 'basic', allowed_request_types: ['item','service'], is_active: true });
      await loadMappings(countryCode);
    } catch (e) {
      console.error('Upsert mapping failed', e);
    }
  }

  const allRequestTypes = ['item','service','ride','rent','delivery','tours','events','construction','education','hiring'];

  return (
    <Box p={2}>
      <Typography variant="h5" gutterBottom>Subscription Management</Typography>

      <Paper variant="outlined" sx={{ p:2, mb:3 }}>
        <Typography variant="h6">Create/Update Global Plan (Super Admin)</Typography>
        <Box display="flex" gap={2} mt={2} flexWrap="wrap">
          <TextField label="Code" size="small" value={form.code} onChange={e=>setForm({ ...form, code:e.target.value })} />
          <TextField label="Name" size="small" value={form.name} onChange={e=>setForm({ ...form, name:e.target.value })} />
          <FormControl size="small">
            <InputLabel>Type</InputLabel>
            <Select label="Type" value={form.plan_type} onChange={e=>setForm({ ...form, plan_type:e.target.value })}>
              <MenuItem value="basic">Basic</MenuItem>
              <MenuItem value="unlimited">Unlimited</MenuItem>
              <MenuItem value="ppc">Pay Per Click</MenuItem>
            </Select>
          </FormControl>
          <TextField label="Default Responses/Month" size="small" type="number" value={form.default_responses_per_month||''} onChange={e=>setForm({ ...form, default_responses_per_month:Number(e.target.value) })} />
          <TextField label="Description" size="small" fullWidth value={form.description} onChange={e=>setForm({ ...form, description:e.target.value })} />
          <Button variant="contained" onClick={createOrUpdatePlan}>Save Plan</Button>
        </Box>
        <Box mt={2}>
          <Typography>Existing Plans:</Typography>
          {plans.map(p => (
            <Box key={p.id} display="flex" alignItems="center" gap={2} mt={1}>
              <Typography>{p.code} - {p.name} [{p.plan_type}] - {p.status}</Typography>
              {p.status !== 'active' && <Button size="small" onClick={()=>approvePlan(p.code)}>Approve</Button>}
            </Box>
          ))}
        </Box>
      </Paper>

      <Paper variant="outlined" sx={{ p:2, mb:3 }}>
        <Typography variant="h6">Country Pricing/Responses (Country Admin)</Typography>
        <Box display="flex" gap={2} mt={2} flexWrap="wrap">
          <TextField label="Country Code" size="small" value={countryCode} onChange={e=>setCountryCode(e.target.value.toUpperCase())} />
          <FormControl size="small">
            <InputLabel>Plan Code</InputLabel>
            <Select label="Plan Code" value={settingsForm.plan_code} onChange={e=>setSettingsForm({ ...settingsForm, plan_code:e.target.value })}>
              {['basic','unlimited','ppc'].map(c=> <MenuItem key={c} value={c}>{c}</MenuItem>)}
            </Select>
          </FormControl>
          <TextField label="Currency" size="small" value={settingsForm.currency} onChange={e=>setSettingsForm({ ...settingsForm, currency:e.target.value })} />
          <TextField label="Price" size="small" type="number" value={settingsForm.price} onChange={e=>setSettingsForm({ ...settingsForm, price:e.target.value })} />
          <TextField label="Responses/Month (Basic)" size="small" type="number" value={settingsForm.responses_per_month} onChange={e=>setSettingsForm({ ...settingsForm, responses_per_month:Number(e.target.value) })} />
          <TextField label="PPC Price (PPC)" size="small" type="number" value={settingsForm.ppc_price} onChange={e=>setSettingsForm({ ...settingsForm, ppc_price:e.target.value })} />
          <FormControlLabel control={<Switch checked={settingsForm.is_active} onChange={e=>setSettingsForm({ ...settingsForm, is_active:e.target.checked })} />} label="Active" />
          <Button variant="contained" onClick={upsertCountrySettings}>Save Country Settings</Button>
        </Box>
        <Divider sx={{ my:2 }} />
        <Typography>Existing Settings for {countryCode}:</Typography>
        {countrySettings.map(s => (
          <Box key={s.id} mt={1}>
            <Typography>{s.plan_code} - {s.currency} {s.price ?? s.ppc_price ?? ''} | responses: {s.responses_per_month ?? '-'} | active: {String(s.is_active)}</Typography>
          </Box>
        ))}
      </Paper>

      <Paper variant="outlined" sx={{ p:2 }}>
        <Typography variant="h6">Plan-to-Business-Type Mapping (Country Admin)</Typography>
        <Box display="flex" gap={2} mt={2} flexWrap="wrap">
          <FormControl size="small" sx={{ minWidth: 220 }}>
            <InputLabel>Business Type</InputLabel>
            <Select label="Business Type" value={mappingForm.business_type_id} onChange={e=>setMappingForm({ ...mappingForm, business_type_id: e.target.value })}>
              {businessTypes.map(bt => (
                <MenuItem key={bt.id} value={bt.id}>{bt.name || bt.global_name}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControl size="small">
            <InputLabel>Plan</InputLabel>
            <Select label="Plan" value={mappingForm.plan_code} onChange={e=>setMappingForm({ ...mappingForm, plan_code:e.target.value })}>
              {['basic','unlimited','ppc'].map(c=> <MenuItem key={c} value={c}>{c}</MenuItem>)}
            </Select>
          </FormControl>
          <FormControl size="small" sx={{ minWidth: 240 }}>
            <InputLabel>Allowed Request Types</InputLabel>
            <Select
              multiple
              value={mappingForm.allowed_request_types}
              onChange={e=>setMappingForm({ ...mappingForm, allowed_request_types: e.target.value })}
              renderValue={(selected) => (
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 0.5 }}>
                  {selected.map((value) => (
                    <Chip key={value} label={value} />
                  ))}
                </Box>
              )}
            >
              {allRequestTypes.map(rt => (
                <MenuItem key={rt} value={rt}>{rt}</MenuItem>
              ))}
            </Select>
          </FormControl>
          <FormControlLabel control={<Switch checked={mappingForm.is_active} onChange={e=>setMappingForm({ ...mappingForm, is_active:e.target.checked })} />} label="Active" />
          <Button variant="contained" onClick={upsertMapping}>Save Mapping</Button>
        </Box>
        <Divider sx={{ my:2 }} />
        <Typography>Existing Mappings for {countryCode}:</Typography>
        {mappings.map(m => (
          <Box key={m.id} mt={1}>
            <Typography>
              {`${m.business_type_name} -> ${m.plan_code} | allowed: ${(m.allowed_request_types||[]).join(', ')} | active: ${String(m.is_active)}`}
            </Typography>
          </Box>
        ))}
      </Paper>
    </Box>
  );
}
