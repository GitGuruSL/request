import Link from 'next/link';
import { getJson } from '../../../lib/fetcher';

async function getRequest(id) {
  const d = await getJson(`/api/requests/${id}`);
  return d?.data || d;
}

async function getResponses(id) {
  const d = await getJson(`/api/requests/${id}/responses`);
  const payload = d?.data || d;
  return payload?.responses || [];
}

export default async function RequestDetail({ params }) {
  const id = params.id;
  const r = await getRequest(id).catch(() => null);
  if (!r) return <main style={{ maxWidth: 900, margin: '0 auto', padding: 16 }}><h1>Not found</h1></main>;
  const responses = await getResponses(id).catch(() => []);
  return (
    <main style={{ maxWidth: 900, margin: '0 auto', padding: 16 }}>
      <Link href="/requests">← Back to requests</Link>
      <h1 style={{ marginTop: 8 }}>{r.title}</h1>
      <div style={{ color: '#666' }}>{r.city_name}{r.effective_country_code ? `, ${r.effective_country_code}` : ''}</div>
      <div style={{ marginTop: 12 }}>{r.description}</div>
      {Array.isArray(r.image_urls) && r.image_urls.length > 0 && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 8, marginTop: 12 }}>
          {r.image_urls.map((u, i) => (
            <img key={i} src={u} alt={`img-${i}`} style={{ width: '100%', height: 160, objectFit: 'cover', borderRadius: 6 }} />
          ))}
        </div>
      )}
      <h2 style={{ marginTop: 20 }}>Responses</h2>
      {responses.length === 0 ? (
        <div>No responses yet.</div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 8 }}>
          {responses.map((resp) => (
            <div key={resp.id} style={{ border: '1px solid #eee', borderRadius: 8, padding: 12 }}>
              <div style={{ fontWeight: 600 }}>{resp.user_name || 'User'}{resp.price ? ` · ${resp.currency || ''} ${resp.price}` : ''}</div>
              <div style={{ marginTop: 6 }}>{resp.message}</div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
