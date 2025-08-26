import { buildQuery, getJson } from '../../lib/fetcher';
import { DEFAULT_COUNTRY } from '../../lib/siteConfig';

async function getListings({ country = 'LK', q = '', limit = 20 } = {}) {
  const qs = buildQuery({ country, q, limit });
  try {
    const data = await getJson(`/api/price-listings${qs}`);
    return Array.isArray(data) ? data : (data?.data || []);
  } catch {
    return [];
  }
}

export const metadata = { title: 'Prices - Request' };

export default async function PricesPage({ searchParams }) {
  const country = DEFAULT_COUNTRY; // Fixed to LK
  const q = searchParams?.q || '';
  const listings = await getListings({ country, q, limit: 24 });
  return (
    <main style={{ maxWidth: 1200, margin: '0 auto', padding: 16 }}>
      <h1>Price Listings (Sri Lanka)</h1>
      <form method="get" style={{ display: 'flex', gap: 8, marginBottom: 12 }}>
        <input type="text" name="q" placeholder="Search products" defaultValue={q} style={{ flex: 1, padding: 8, border: '1px solid #ddd', borderRadius: 6 }} />
        {/* Country fixed to LK; hide input */}
        <button type="submit" style={{ padding: '8px 12px' }}>Search</button>
      </form>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(260px, 1fr))', gap: 12 }}>
        {listings.map((p) => (
          <div key={p.id || p._id} style={{ border: '1px solid #eee', borderRadius: 8, padding: 12 }}>
            <div style={{ fontWeight: 600, marginBottom: 6 }}>{p.title || p.name}</div>
            {p.imageUrl && <img src={p.imageUrl} alt={p.title || p.name} style={{ width: '100%', height: 140, objectFit: 'cover', borderRadius: 6 }} />}
            <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 8 }}>
              <div style={{ color: '#555' }}>{p.brand || p.store || p.source || ''}</div>
              <div style={{ fontWeight: 700 }}>
                {p.currency || 'LKR'} {p.price ?? p.selling_price ?? p.amount ?? ''}
              </div>
            </div>
          </div>
        ))}
      </div>
    </main>
  );
}
