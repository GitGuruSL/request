import React, { useEffect, useMemo, useState } from 'react';
import {
  Container,
  Typography,
  Box,
  Grid,
  Paper,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  Switch,
  TextField,
  Button,
  Snackbar,
  Alert,
  CircularProgress,
} from '@mui/material';
import { Save as SaveIcon } from '@mui/icons-material';
import api from '../services/apiClient';
import { useAuth } from '../contexts/AuthContext';

const PlanSwitch = ({ label, checked, onChange, disabled }) => (
  <Box display="flex" alignItems="center" gap={1}>
    <Switch size="small" checked={!!checked} onChange={(e) => onChange(e.target.checked)} disabled={disabled} />
    <Typography variant="body2">{label}</Typography>
  </Box>
);

export default function BusinessTypeBenefits() {
  const { user, adminData } = useAuth();
  const userRole = adminData?.role;
  const isSuperAdmin = userRole === 'super_admin';
  const defaultCountry = adminData?.country_code || adminData?.country || 'LK';

  const [countries, setCountries] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState(defaultCountry);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [benefits, setBenefits] = useState([]); // [{ id, name, free: {...}, paid: {...} }]
  const [readOnly, setReadOnly] = useState(false); // When backend lacks admin endpoints

  const loadCountries = async () => {
    if (!isSuperAdmin) return;
    try {
      const { data } = await api.get('/countries');
      if (data?.success) setCountries(data.data || []);
    } catch (e) {
      console.error('Failed to fetch countries', e);
    }
  };

  // Resolve a country identifier (numeric ID or code like "LK") to a numeric ID the backend expects
  const resolveCountryIdParam = async (value) => {
    if (!value && value !== 0) return null;
    // If already numeric-like, use as-is
    if (typeof value === 'number' || /^\d+$/.test(String(value))) {
      return parseInt(value, 10);
    }
    try {
      const res = await api.get(`/countries/${value}`);
      const id = res?.data?.data?.id || res?.data?.id;
      return id || null;
    } catch (e) {
      console.warn('Could not resolve country code to ID, using original value', value, e?.response?.status);
      return value; // fallback to original; backend may support code as well
    }
  };

  const groupAdminRows = (rows) => {
    const byType = {};
    for (const r of rows) {
      const id = r.business_type_id;
      if (!byType[id]) {
        byType[id] = {
          id,
          name: r.business_type_name,
          free: {
            responsesPerMonth: 3,
            contactRevealed: false,
            canMessageRequester: false,
            respondButtonEnabled: true,
            instantNotifications: false,
            priorityInSearch: false,
          },
          paid: {
            responsesPerMonth: -1,
            contactRevealed: true,
            canMessageRequester: true,
            respondButtonEnabled: true,
            instantNotifications: true,
            priorityInSearch: true,
          },
        };
      }
      const planKey = r.plan_type === 'free' ? 'free' : 'paid';
      byType[id][planKey] = {
        responsesPerMonth: r.responses_per_month,
        contactRevealed: r.contact_revealed,
        canMessageRequester: r.can_message_requester,
        respondButtonEnabled: r.respond_button_enabled,
        instantNotifications: r.instant_notifications,
        priorityInSearch: r.priority_in_search,
      };
    }
    return Object.values(byType).sort((a, b) => a.name.localeCompare(b.name));
  };

  // Adapt non-admin map response { name: { freePlan, paidPlan } } to table rows
  const adaptMapToRows = (mapObj) => {
    const rows = [];
    for (const [name, plans] of Object.entries(mapObj || {})) {
      rows.push({
        id: name, // No numeric ID available here; treat name as key in read-only mode
        name,
        free: {
          responsesPerMonth: plans?.freePlan?.responsesPerMonth ?? 3,
          contactRevealed: !!plans?.freePlan?.contactRevealed,
          canMessageRequester: !!plans?.freePlan?.canMessageRequester,
          respondButtonEnabled: plans?.freePlan?.respondButtonEnabled !== false,
          instantNotifications: !!plans?.freePlan?.instantNotifications,
          priorityInSearch: !!plans?.freePlan?.priorityInSearch,
        },
        paid: {
          responsesPerMonth: plans?.paidPlan?.responsesPerMonth ?? -1,
          contactRevealed: !!plans?.paidPlan?.contactRevealed,
          canMessageRequester: !!plans?.paidPlan?.canMessageRequester,
          respondButtonEnabled: plans?.paidPlan?.respondButtonEnabled !== false,
          instantNotifications: !!plans?.paidPlan?.instantNotifications,
          priorityInSearch: !!plans?.paidPlan?.priorityInSearch,
        },
      });
    }
    return rows.sort((a, b) => a.name.localeCompare(b.name));
  };

  const loadBenefits = async () => {
    if (!selectedCountry) return;
    try {
      setLoading(true);
      const countryIdParam = await resolveCountryIdParam(selectedCountry);
      setReadOnly(false);
      try {
        const { data } = await api.get(`/business-type-benefits/admin/${countryIdParam}`);
        if (data?.success) {
          const rows = data.benefits || data.data || [];
          setBenefits(groupAdminRows(rows));
        } else {
          throw new Error(data?.message || 'Failed to fetch admin benefits');
        }
      } catch (err) {
        // Fallback to non-admin endpoint (read-only)
        const { data: fb } = await api.get(`/business-type-benefits/${countryIdParam}`);
        if (fb?.success && fb?.businessTypeBenefits) {
          setBenefits(adaptMapToRows(fb.businessTypeBenefits));
          setReadOnly(true);
          setSnackbar({ open: true, message: 'Admin endpoint not found; showing read-only data', severity: 'warning' });
        } else {
          throw err;
        }
      }
    } catch (e) {
      console.error('Failed to fetch benefits', e);
      setSnackbar({ open: true, message: 'Failed to fetch benefits', severity: 'error' });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadCountries();
  }, [isSuperAdmin]);

  useEffect(() => {
    loadBenefits();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCountry]);

  const handleFieldChange = (btId, plan, key, value) => {
    setBenefits((prev) => prev.map((b) => (b.id === btId ? { ...b, [plan]: { ...b[plan], [key]: value } } : b)));
  };

  const savePlan = async (btId, plan) => {
    try {
      if (readOnly) {
        setSnackbar({ open: true, message: 'Backend lacks admin endpoints. Please deploy the latest backend to enable editing.', severity: 'warning' });
        return;
      }
      setSaving(true);
      const bt = benefits.find((b) => b.id === btId);
      const payload = bt[plan];
      const planType = plan === 'free' ? 'free' : 'paid';
      const countryIdParam = await resolveCountryIdParam(selectedCountry);
      const { data } = await api.put(
        `/business-type-benefits/${countryIdParam}/${btId}/${planType}`,
        payload
      );
      if (data?.success) {
        setSnackbar({ open: true, message: 'Updated successfully', severity: 'success' });
      } else {
        setSnackbar({ open: true, message: data?.error || 'Update failed', severity: 'error' });
      }
    } catch (e) {
      console.error('Failed to update benefits', e);
      setSnackbar({ open: true, message: 'Update failed', severity: 'error' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <Container maxWidth="xl">
      <Box my={3} display="flex" alignItems="center" justifyContent="space-between">
        <Typography variant="h5">Business Type Benefits</Typography>
        {isSuperAdmin && (
          <FormControl size="small" sx={{ minWidth: 220 }}>
            <InputLabel>Country</InputLabel>
            <Select value={selectedCountry} label="Country" onChange={(e) => setSelectedCountry(e.target.value)}>
              {countries.map((c) => (
                <MenuItem key={c.id || c.code} value={c.id || c.code}>
                  {c.name} ({c.code || c.country_code})
                </MenuItem>
              ))}
            </Select>
          </FormControl>
        )}
      </Box>

      <Paper sx={{ p: 2 }}>
  {loading ? (
          <Box display="flex" justifyContent="center" py={6}><CircularProgress /></Box>
        ) : (
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Business Type</TableCell>
                <TableCell align="center" colSpan={6}>Free Plan</TableCell>
                <TableCell align="center" colSpan={6}>Paid Plan</TableCell>
                <TableCell align="center">Actions</TableCell>
              </TableRow>
              <TableRow>
                <TableCell></TableCell>
                {/* Free plan headers */}
                <TableCell>Responses</TableCell>
                <TableCell>Contact</TableCell>
                <TableCell>Messaging</TableCell>
                <TableCell>Respond Btn</TableCell>
                <TableCell>Notifications</TableCell>
                <TableCell>Priority</TableCell>
                {/* Paid plan headers */}
                <TableCell>Responses</TableCell>
                <TableCell>Contact</TableCell>
                <TableCell>Messaging</TableCell>
                <TableCell>Respond Btn</TableCell>
                <TableCell>Notifications</TableCell>
                <TableCell>Priority</TableCell>
                <TableCell></TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {benefits.map((b) => (
                <TableRow key={b.id} hover>
                  <TableCell sx={{ fontWeight: 600 }}>{b.name}</TableCell>
                  {/* Free plan fields */}
                  <TableCell width={110}>
                    <TextField
                      type="number"
                      size="small"
                      value={b.free.responsesPerMonth}
                      onChange={(e) => handleFieldChange(b.id, 'free', 'responsesPerMonth', parseInt(e.target.value))}
                      inputProps={{ step: 1, min: -1 }}
                    />
                  </TableCell>
                  <TableCell><PlanSwitch label="Contact Revealed" checked={b.free.contactRevealed} onChange={(v) => handleFieldChange(b.id, 'free', 'contactRevealed', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Can Message" checked={b.free.canMessageRequester} onChange={(v) => handleFieldChange(b.id, 'free', 'canMessageRequester', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Respond Enabled" checked={b.free.respondButtonEnabled} onChange={(v) => handleFieldChange(b.id, 'free', 'respondButtonEnabled', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Instant Notifs" checked={b.free.instantNotifications} onChange={(v) => handleFieldChange(b.id, 'free', 'instantNotifications', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Priority" checked={b.free.priorityInSearch} onChange={(v) => handleFieldChange(b.id, 'free', 'priorityInSearch', v)} /></TableCell>

                  {/* Paid plan fields */}
                  <TableCell width={110}>
                    <TextField
                      type="number"
                      size="small"
                      value={b.paid.responsesPerMonth}
                      onChange={(e) => handleFieldChange(b.id, 'paid', 'responsesPerMonth', parseInt(e.target.value))}
                      inputProps={{ step: 1, min: -1 }}
                    />
                  </TableCell>
                  <TableCell><PlanSwitch label="Contact Revealed" checked={b.paid.contactRevealed} onChange={(v) => handleFieldChange(b.id, 'paid', 'contactRevealed', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Can Message" checked={b.paid.canMessageRequester} onChange={(v) => handleFieldChange(b.id, 'paid', 'canMessageRequester', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Respond Enabled" checked={b.paid.respondButtonEnabled} onChange={(v) => handleFieldChange(b.id, 'paid', 'respondButtonEnabled', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Instant Notifs" checked={b.paid.instantNotifications} onChange={(v) => handleFieldChange(b.id, 'paid', 'instantNotifications', v)} /></TableCell>
                  <TableCell><PlanSwitch label="Priority" checked={b.paid.priorityInSearch} onChange={(v) => handleFieldChange(b.id, 'paid', 'priorityInSearch', v)} /></TableCell>

                  <TableCell align="right">
                    <Box display="flex" gap={1}>
                      <Button variant="outlined" size="small" startIcon={<SaveIcon />} disabled={saving || readOnly || typeof b.id !== 'number'} onClick={() => savePlan(b.id, 'free')}>Save Free</Button>
                      <Button variant="contained" size="small" startIcon={<SaveIcon />} disabled={saving || readOnly || typeof b.id !== 'number'} onClick={() => savePlan(b.id, 'paid')}>Save Paid</Button>
                    </Box>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </Paper>

      <Box mt={2}>
        {!readOnly ? (
          <Alert severity="info">
            Use -1 for "Unlimited responses". Other fields are boolean toggles.
          </Alert>
        ) : (
          <Alert severity="warning">
            Read-only mode: The EC2 backend doesn’t expose admin endpoints for Business Type Benefits yet. Deploy the latest backend to enable editing.
          </Alert>
        )}
      </Box>

      <Snackbar
        open={snackbar.open}
        autoHideDuration={3000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert onClose={() => setSnackbar({ ...snackbar, open: false })} severity={snackbar.severity} sx={{ width: '100%' }}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Container>
  );
}
