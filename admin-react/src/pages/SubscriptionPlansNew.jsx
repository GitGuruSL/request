import React, { useState, useEffect } from 'react';
import { Box, Card, CardContent, Typography, Button, Dialog, DialogTitle, DialogContent, DialogActions, TextField, Grid, Chip, Checkbox, FormControlLabel, Switch, MenuItem, IconButton, Table, TableHead, TableRow, TableCell, TableBody, Toolbar, Tooltip } from '@mui/material';
import { Add, Edit, Delete, Refresh } from '@mui/icons-material';
import api from '../services/apiClient';
import useCountryFilter from '../hooks/useCountryFilter';
import { useAuth } from '../contexts/AuthContext';

const TYPES = ['rider','business'];
const PLAN_TYPES = ['monthly','yearly','pay_per_click'];

export default function SubscriptionPlansNew(){
  const { isSuperAdmin, countries } = useCountryFilter();
  const { adminData } = useAuth();
  const hasPermission = isSuperAdmin || adminData?.permissions?.subscriptionManagement;
  const [rows,setRows]=useState([]);
  const [loading,setLoading]=useState(false);
  const [error,setError]=useState('');
  const [dialogOpen,setDialogOpen]=useState(false);
  const [editing,setEditing]=useState(null);
  const [form,setForm]=useState({ code:'', name:'', type:'rider', plan_type:'monthly', description:'', price:0, currency:'USD', duration_days:30, features:'', limitations:'', countries:[], is_active:true, is_default_plan:false, requires_country_pricing:false });

  function resetForm(){ setForm({ code:'', name:'', type:'rider', plan_type:'monthly', description:'', price:0, currency:'USD', duration_days:30, features:'', limitations:'', countries:[], is_active:true, is_default_plan:false, requires_country_pricing:false }); setEditing(null); }

  async function load(){
    if(!hasPermission) return; setLoading(true); setError('');
    try { const { data } = await api.get('/subscription-plans-new'); setRows(Array.isArray(data)? data: data.items||[]); }
    catch(e){ setError(e.message||'Failed'); }
    finally{ setLoading(false); }
  }
  useEffect(()=>{ load(); },[hasPermission]);

  function openCreate(){ resetForm(); setDialogOpen(true); }
  function openEdit(row){ setEditing(row); setForm({ ...row, features: JSON.stringify(row.features||[] ,null,2), limitations: JSON.stringify(row.limitations||{},null,2)}); setDialogOpen(true); }

  function handleChange(e){ const {name,value} = e.target; setForm(f=>({...f,[name]:value})); }
  function handleToggle(name){ return (e)=> setForm(f=>({...f,[name]: e.target.checked})); }
  function handleCountries(e){ const value=e.target.value; setForm(f=>({...f,countries: typeof value==='string'? value.split(','): value})); }

  async function save(){
    try { const payload={ ...form, features: safeJSON(form.features,'[]'), limitations: safeJSON(form.limitations,'{}') };
      if(editing){ await api.put(`/subscription-plans-new/${editing.id}`, payload); }
      else { await api.post('/subscription-plans-new', payload); }
      setDialogOpen(false); load();
    } catch(e){ setError(e.message||'Save failed'); }
  }
  function safeJSON(txt, fallback){ try { return JSON.parse(txt||fallback); } catch(_){ return JSON.parse(fallback); } }
  async function remove(row){ if(!window.confirm('Delete plan?')) return; try { await api.delete(`/subscription-plans-new/${row.id}`); load(); } catch(e){ alert('Delete failed: '+e.message); } }

  return <Box p={2}>
    <Toolbar disableGutters sx={{justifyContent:'space-between'}}>
      <Typography variant='h5'>Subscription Plans (New)</Typography>
      <Box>
        <Tooltip title='Reload'><IconButton onClick={load} disabled={loading}><Refresh/></IconButton></Tooltip>
        {hasPermission && <Button startIcon={<Add/>} variant='contained' onClick={openCreate}>New Plan</Button>}
      </Box>
    </Toolbar>
    {error && <Typography color='error' variant='body2'>{error}</Typography>}
    <Card sx={{mt:2}}>
      <CardContent>
        <Table size='small'>
          <TableHead>
            <TableRow>
              <TableCell>Name</TableCell>
              <TableCell>Code</TableCell>
              <TableCell>Type</TableCell>
              <TableCell>Plan</TableCell>
              <TableCell>Price</TableCell>
              <TableCell>Currency</TableCell>
              <TableCell>Active</TableCell>
              <TableCell>Default</TableCell>
              <TableCell>Countries</TableCell>
              <TableCell width={140}></TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map(r=> <TableRow key={r.id} hover>
              <TableCell>{r.name}</TableCell>
              <TableCell>{r.code}</TableCell>
              <TableCell>{r.type}</TableCell>
              <TableCell>{r.plan_type}</TableCell>
              <TableCell>{r.price}</TableCell>
              <TableCell>{r.currency}</TableCell>
              <TableCell>{r.is_active? 'Yes':'No'}</TableCell>
              <TableCell>{r.is_default_plan? 'Yes':'No'}</TableCell>
              <TableCell>{(r.countries||[]).join(', ')}</TableCell>
              <TableCell>
                {hasPermission && <>
                  <IconButton size='small' onClick={()=>openEdit(r)}><Edit fontSize='inherit'/></IconButton>
                  <IconButton size='small' onClick={()=>remove(r)}><Delete fontSize='inherit'/></IconButton>
                </>}
              </TableCell>
            </TableRow>)}
          </TableBody>
        </Table>
      </CardContent>
    </Card>

    <Dialog open={dialogOpen} fullWidth maxWidth='md' onClose={()=>setDialogOpen(false)}>
      <DialogTitle>{editing? 'Edit Plan':'Create Plan'}</DialogTitle>
      <DialogContent dividers>
        <Grid container spacing={2} sx={{mt:0}}>
          <Grid item xs={12} sm={6}><TextField fullWidth label='Code' name='code' value={form.code} onChange={handleChange} required /></Grid>
          <Grid item xs={12} sm={6}><TextField fullWidth label='Name' name='name' value={form.name} onChange={handleChange} required /></Grid>
          <Grid item xs={12} sm={4}><TextField select fullWidth label='Type' name='type' value={form.type} onChange={handleChange}>{TYPES.map(t=> <MenuItem key={t} value={t}>{t}</MenuItem>)}</TextField></Grid>
          <Grid item xs={12} sm={4}><TextField select fullWidth label='Plan Type' name='plan_type' value={form.plan_type} onChange={handleChange}>{PLAN_TYPES.map(t=> <MenuItem key={t} value={t}>{t}</MenuItem>)}</TextField></Grid>
          <Grid item xs={6} sm={2}><TextField fullWidth type='number' label='Price' name='price' value={form.price} onChange={handleChange} /></Grid>
          <Grid item xs={6} sm={2}><TextField fullWidth label='Currency' name='currency' value={form.currency} onChange={handleChange} /></Grid>
          <Grid item xs={12}><TextField fullWidth multiline minRows={2} label='Description' name='description' value={form.description} onChange={handleChange} /></Grid>
          <Grid item xs={12} sm={4}><TextField fullWidth type='number' label='Duration Days' name='duration_days' value={form.duration_days} onChange={handleChange} /></Grid>
          <Grid item xs={12} sm={8}><TextField fullWidth label='Countries (comma separated)' value={form.countries.join(',')} onChange={e=> handleCountries({target:{value:e.target.value}})} helperText='Leave empty for global'/></Grid>
          <Grid item xs={12} sm={6}><TextField fullWidth multiline minRows={4} label='Features (JSON array)' name='features' value={form.features} onChange={handleChange} /></Grid>
          <Grid item xs={12} sm={6}><TextField fullWidth multiline minRows={4} label='Limitations (JSON object)' name='limitations' value={form.limitations} onChange={handleChange} /></Grid>
          <Grid item xs={12} sm={4}><FormControlLabel control={<Switch checked={form.is_active} onChange={handleToggle('is_active')} />} label='Active' /></Grid>
          <Grid item xs={12} sm={4}><FormControlLabel control={<Switch checked={form.is_default_plan} onChange={handleToggle('is_default_plan')} />} label='Default Plan' /></Grid>
          <Grid item xs={12} sm={4}><FormControlLabel control={<Switch checked={form.requires_country_pricing} onChange={handleToggle('requires_country_pricing')} />} label='Requires Country Pricing' /></Grid>
        </Grid>
      </DialogContent>
      <DialogActions>
        <Button onClick={()=>setDialogOpen(false)}>Cancel</Button>
        <Button variant='contained' onClick={save}>{editing? 'Update':'Create'}</Button>
      </DialogActions>
    </Dialog>
  </Box>;
}
