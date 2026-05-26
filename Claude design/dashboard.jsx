// DigitalPMO — Home Dashboard
// Indonesian TB medication companion app

const PMO = {
  primary: '#1A6B5A',
  primaryDeep: '#125146',
  secondary: '#F5A623',
  secondarySoft: '#FFF2D9',
  bg: '#F0F7F5',
  card: '#FFFFFF',
  text: '#1A2E2A',
  textMute: '#5B716C',
  border: 'rgba(26,46,42,0.08)',
  dark: '#15302B',
};

// ── Icons ────────────────────────────────────────────────────
const Icon = {
  bell: (c = '#fff') => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <path d="M6 8a6 6 0 1112 0c0 7 3 9 3 9H3s3-2 3-9" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M10.3 21a1.94 1.94 0 003.4 0" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  camera: (c = '#fff') => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <path d="M3 8a2 2 0 012-2h2.2l1.4-2h6.8l1.4 2H19a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/>
      <circle cx="12" cy="13" r="3.6" stroke={c} strokeWidth="1.8"/>
    </svg>
  ),
  arrowR: (c = '#fff') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
      <path d="M5 12h14m-6-6l6 6-6 6" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  calendar: (c = PMO.primary) => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="5" width="18" height="16" rx="3" stroke={c} strokeWidth="1.8"/>
      <path d="M3 9h18M8 3v4M16 3v4" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  ),
  robot: (c = '#fff') => (
    <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
      <rect x="4" y="7" width="16" height="12" rx="4" stroke={c} strokeWidth="1.8"/>
      <circle cx="9" cy="13" r="1.4" fill={c}/>
      <circle cx="15" cy="13" r="1.4" fill={c}/>
      <path d="M12 4v3M9 19v2M15 19v2" stroke={c} strokeWidth="1.8" strokeLinecap="round"/>
      <circle cx="12" cy="3" r="1.2" fill={c}/>
    </svg>
  ),
  check: (c = '#fff') => (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
      <path d="M4 12.5l5 5 11-11" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  pill: (c = PMO.primary) => (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <rect x="3" y="9" width="18" height="6" rx="3" stroke={c} strokeWidth="1.8" transform="rotate(-30 12 12)"/>
      <path d="M9.5 6.7l4.8 8.4" stroke={c} strokeWidth="1.8"/>
    </svg>
  ),
  flame: () => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
      <path d="M12 2s4 4 4 9a4 4 0 11-8 0c0-2 1-3 1-3s-2 2-2 5a5 5 0 0010 0c0-6-5-11-5-11z" fill="#FFB547"/>
      <path d="M12 2s4 4 4 9a4 4 0 11-8 0c0-2 1-3 1-3s-2 2-2 5a5 5 0 0010 0c0-6-5-11-5-11z" stroke="#E8851A" strokeWidth="0.6" strokeLinejoin="round"/>
    </svg>
  ),
};

// ── Nav tab icons ────────────────────────────────────────────
const NavIcon = ({ kind, active }) => {
  const c = active ? PMO.primary : '#9AAFA8';
  const w = active ? 2.2 : 1.8;
  switch (kind) {
    case 'home':
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M3 11l9-7 9 7v9a2 2 0 01-2 2h-4v-7h-6v7H5a2 2 0 01-2-2v-9z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={active ? 'rgba(26,107,90,0.12)' : 'none'}/>
        </svg>
      );
    case 'stats':
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M4 20V10M10 20V4M16 20v-7M22 20H2" stroke={c} strokeWidth={w} strokeLinecap="round"/>
        </svg>
      );
    case 'ai':
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M12 2l1.8 4.4L18 8l-4.2 1.6L12 14l-1.8-4.4L6 8l4.2-1.6L12 2z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={active ? 'rgba(26,107,90,0.12)' : 'none'}/>
          <path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15z" stroke={c} strokeWidth={w} strokeLinejoin="round"/>
        </svg>
      );
    case 'symptoms':
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <path d="M12 21s-7-5-7-11a4 4 0 017-2.6A4 4 0 0119 10c0 6-7 11-7 11z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={active ? 'rgba(26,107,90,0.12)' : 'none'}/>
        </svg>
      );
    case 'settings':
      return (
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="3" stroke={c} strokeWidth={w}/>
          <path d="M19.4 15a1.6 1.6 0 00.3 1.7l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.6 1.6 0 00-1.7-.3 1.6 1.6 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.6 1.6 0 00-1-1.5 1.6 1.6 0 00-1.7.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.6 1.6 0 00.3-1.7 1.6 1.6 0 00-1.5-1H3a2 2 0 110-4h.1a1.6 1.6 0 001.5-1 1.6 1.6 0 00-.3-1.7l-.1-.1a2 2 0 112.8-2.8l.1.1a1.6 1.6 0 001.7.3H9a1.6 1.6 0 001-1.5V3a2 2 0 114 0v.1a1.6 1.6 0 001 1.5 1.6 1.6 0 001.7-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.6 1.6 0 00-.3 1.7V9a1.6 1.6 0 001.5 1H21a2 2 0 110 4h-.1a1.6 1.6 0 00-1.5 1z" stroke={c} strokeWidth={w} strokeLinejoin="round"/>
        </svg>
      );
  }
};

// ── Header ───────────────────────────────────────────────────
function Header({ streak }) {
  return (
    <div style={{
      background: `linear-gradient(165deg, ${PMO.primary} 0%, #15594B 100%)`,
      padding: '64px 20px 28px',
      borderBottomLeftRadius: 28, borderBottomRightRadius: 28,
      position: 'relative', overflow: 'hidden',
    }}>
      {/* decorative blob */}
      <div style={{
        position: 'absolute', top: -40, right: -40, width: 180, height: 180,
        borderRadius: '50%', background: 'rgba(255,255,255,0.06)',
      }} />
      <div style={{
        position: 'absolute', bottom: -30, left: -20, width: 100, height: 100,
        borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
      }} />

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', position: 'relative' }}>
        <div>
          <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13, fontWeight: 500, letterSpacing: 0.3 }}>
            JUMAT, 9 JUNI
          </div>
          <div style={{ color: '#fff', fontSize: 26, fontWeight: 700, marginTop: 4, letterSpacing: -0.4 }}>
            Selamat pagi,
          </div>
          <div style={{ color: '#fff', fontSize: 26, fontWeight: 700, letterSpacing: -0.4 }}>
            Budi! 👋
          </div>
        </div>
        <button style={{
          width: 44, height: 44, borderRadius: 14,
          background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.2)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          cursor: 'pointer', position: 'relative',
        }}>
          {Icon.bell('#fff')}
          <div style={{
            position: 'absolute', top: 9, right: 9, width: 9, height: 9,
            borderRadius: '50%', background: PMO.secondary, border: '2px solid #1A6B5A',
          }} />
        </button>
      </div>

      {/* Streak badge */}
      <div style={{
        marginTop: 18, display: 'inline-flex', alignItems: 'center', gap: 8,
        padding: '10px 14px', borderRadius: 100,
        background: 'rgba(255,255,255,0.14)', border: '1px solid rgba(255,255,255,0.18)',
        backdropFilter: 'blur(8px)',
      }}>
        {Icon.flame()}
        <span style={{ color: '#fff', fontSize: 14, fontWeight: 600 }}>
          45 hari berturut-turut
        </span>
      </div>
    </div>
  );
}

// ── Today's Medicine ─────────────────────────────────────────
function MedicineCard({ confirmed, onConfirm }) {
  const pills = [
    { name: 'Rifampicin', color: '#E15554', short: 'R' },
    { name: 'Isoniazid', color: '#3B82B7', short: 'H' },
    { name: 'Pirazinamid', color: '#F5A623', short: 'Z' },
    { name: 'Etambutol', color: '#7B5EA7', short: 'E' },
  ];

  return (
    <div style={{
      background: PMO.card, borderRadius: 20, padding: 20,
      boxShadow: '0 4px 20px rgba(26,46,42,0.06), 0 1px 3px rgba(26,46,42,0.04)',
      border: '1px solid ' + PMO.border,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 4 }}>
        <div>
          <div style={{ fontSize: 12, fontWeight: 600, color: PMO.primary, letterSpacing: 0.6, textTransform: 'uppercase' }}>
            Jadwal Hari Ini
          </div>
          <div style={{ fontSize: 22, fontWeight: 700, color: PMO.text, marginTop: 4, letterSpacing: -0.3 }}>
            Obat Pagi — RHZE
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 6 }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="9" stroke={PMO.textMute} strokeWidth="1.8"/>
              <path d="M12 7v5l3 2" stroke={PMO.textMute} strokeWidth="1.8" strokeLinecap="round"/>
            </svg>
            <span style={{ fontSize: 15, color: PMO.textMute, fontWeight: 500 }}>07:00 WIB</span>
          </div>
        </div>
        <div style={{
          padding: '6px 12px', borderRadius: 100,
          background: confirmed ? '#E6F4EC' : PMO.secondarySoft,
          color: confirmed ? '#137A3F' : '#A66A00',
          fontSize: 12, fontWeight: 700, letterSpacing: 0.2,
          display: 'flex', alignItems: 'center', gap: 6,
        }}>
          <div style={{
            width: 7, height: 7, borderRadius: '50%',
            background: confirmed ? '#1FA15A' : PMO.secondary,
          }} />
          {confirmed ? 'Sudah Diminum' : 'Belum Diminum'}
        </div>
      </div>

      {/* Pills row */}
      <div style={{ display: 'flex', gap: 8, marginTop: 16, marginBottom: 18 }}>
        {pills.map(p => (
          <div key={p.name} style={{
            flex: 1, background: PMO.bg, borderRadius: 14, padding: '12px 6px',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: '50%',
              background: p.color, color: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontWeight: 800, fontSize: 14, letterSpacing: -0.4,
              boxShadow: `0 3px 8px ${p.color}55`,
            }}>{p.short}</div>
            <div style={{ fontSize: 10.5, color: PMO.text, fontWeight: 600, textAlign: 'center', lineHeight: 1.15 }}>
              {p.name}
            </div>
          </div>
        ))}
      </div>

      {/* CTA */}
      <button
        onClick={onConfirm}
        style={{
          width: '100%', height: 58, borderRadius: 16,
          background: confirmed
            ? 'linear-gradient(180deg, #1FA15A 0%, #167A45 100%)'
            : `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
          border: 'none', color: '#fff', fontSize: 16, fontWeight: 700,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          cursor: 'pointer', letterSpacing: -0.2,
          boxShadow: confirmed
            ? '0 6px 16px rgba(31,161,90,0.35)'
            : '0 6px 16px rgba(26,107,90,0.35)',
          transition: 'all 0.2s',
        }}>
        {confirmed ? Icon.check('#fff') : Icon.camera('#fff')}
        {confirmed ? 'Terkonfirmasi — Foto Tersimpan' : 'Konfirmasi Minum Obat'}
      </button>
    </div>
  );
}

// ── Progress card ────────────────────────────────────────────
function ProgressCard() {
  return (
    <div style={{
      background: PMO.card, borderRadius: 20, padding: 20,
      boxShadow: '0 2px 12px rgba(26,46,42,0.05)',
      border: '1px solid ' + PMO.border,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
        <div style={{ fontSize: 15, fontWeight: 700, color: PMO.text }}>
          Progress Pengobatan
        </div>
        <div style={{
          padding: '4px 10px', borderRadius: 100,
          background: 'rgba(26,107,90,0.1)', color: PMO.primary,
          fontSize: 11, fontWeight: 700, letterSpacing: 0.2,
        }}>
          Fase Intensif
        </div>
      </div>

      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginTop: 8 }}>
        <span style={{ fontSize: 36, fontWeight: 800, color: PMO.primary, letterSpacing: -1.5 }}>67%</span>
        <span style={{ fontSize: 14, color: PMO.textMute, fontWeight: 500 }}>selesai</span>
      </div>

      {/* Progress bar */}
      <div style={{
        marginTop: 14, height: 10, borderRadius: 100,
        background: 'rgba(26,107,90,0.1)', position: 'relative', overflow: 'hidden',
      }}>
        <div style={{
          width: '67%', height: '100%', borderRadius: 100,
          background: `linear-gradient(90deg, ${PMO.primary} 0%, #2A8B73 100%)`,
          position: 'relative',
        }}>
          <div style={{
            position: 'absolute', right: 0, top: '50%', transform: 'translate(50%,-50%)',
            width: 16, height: 16, borderRadius: '50%', background: '#fff',
            border: `3px solid ${PMO.primary}`, boxShadow: '0 2px 6px rgba(0,0,0,0.15)',
          }} />
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 10 }}>
        <span style={{ fontSize: 12, color: PMO.textMute, fontWeight: 500 }}>Hari ke-59 dari 180</span>
        <span style={{ fontSize: 12, color: PMO.text, fontWeight: 700 }}>121 hari tersisa</span>
      </div>
    </div>
  );
}

// ── Mini stats ───────────────────────────────────────────────
function MiniStats() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
      <div style={{
        background: PMO.card, borderRadius: 20, padding: 16,
        border: '1px solid ' + PMO.border,
        boxShadow: '0 2px 8px rgba(26,46,42,0.04)',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 10, marginBottom: 12,
          background: 'rgba(26,107,90,0.1)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M22 11.1V12a10 10 0 11-5.9-9.1" stroke={PMO.primary} strokeWidth="2" strokeLinecap="round"/>
            <path d="M22 4L12 14.01l-3-3" stroke={PMO.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
        <div style={{ fontSize: 24, fontWeight: 800, color: PMO.text, letterSpacing: -0.6 }}>96%</div>
        <div style={{ fontSize: 12, color: PMO.textMute, fontWeight: 500, marginTop: 2, lineHeight: 1.3 }}>
          Kepatuhan<br/>bulan ini
        </div>
      </div>
      <div style={{
        background: PMO.card, borderRadius: 20, padding: 16,
        border: '1px solid ' + PMO.border,
        boxShadow: '0 2px 8px rgba(26,46,42,0.04)',
      }}>
        <div style={{
          width: 32, height: 32, borderRadius: 10, marginBottom: 12,
          background: 'rgba(245,166,35,0.15)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {Icon.pill(PMO.secondary)}
        </div>
        <div style={{ fontSize: 24, fontWeight: 800, color: PMO.text, letterSpacing: -0.6 }}>
          29<span style={{ color: PMO.textMute, fontWeight: 600 }}>/30</span>
        </div>
        <div style={{ fontSize: 12, color: PMO.textMute, fontWeight: 500, marginTop: 2, lineHeight: 1.3 }}>
          Dosis<br/>terkonfirmasi
        </div>
      </div>
    </div>
  );
}

// ── AI Chat card ─────────────────────────────────────────────
function AIChatCard() {
  return (
    <div style={{
      background: `linear-gradient(135deg, ${PMO.dark} 0%, #0F2421 100%)`,
      borderRadius: 20, padding: 18,
      display: 'flex', alignItems: 'center', gap: 14,
      cursor: 'pointer', position: 'relative', overflow: 'hidden',
      boxShadow: '0 6px 18px rgba(21,48,43,0.25)',
    }}>
      {/* decorative */}
      <div style={{
        position: 'absolute', top: -30, right: -10, width: 120, height: 120,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(26,107,90,0.5) 0%, transparent 70%)',
      }} />
      <div style={{
        width: 52, height: 52, borderRadius: 16,
        background: `linear-gradient(135deg, ${PMO.primary} 0%, #2A8B73 100%)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', flexShrink: 0,
        boxShadow: '0 4px 12px rgba(26,107,90,0.4)',
      }}>
        {Icon.robot('#fff')}
        {/* online dot */}
        <div style={{
          position: 'absolute', bottom: 2, right: 2, width: 12, height: 12,
          borderRadius: '50%', background: '#3ED27E', border: `2.5px solid ${PMO.dark}`,
        }} />
      </div>
      <div style={{ flex: 1, position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ color: '#fff', fontSize: 16, fontWeight: 700, letterSpacing: -0.2 }}>
            PMO Digital — AI
          </span>
          <span style={{
            fontSize: 9, fontWeight: 700, color: '#3ED27E', letterSpacing: 0.5,
            padding: '2px 6px', borderRadius: 4, background: 'rgba(62,210,126,0.12)',
          }}>ONLINE</span>
        </div>
        <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 13, marginTop: 3, lineHeight: 1.35 }}>
          Tanya apapun tentang pengobatanmu
        </div>
      </div>
      <div style={{
        width: 36, height: 36, borderRadius: 12,
        background: 'rgba(255,255,255,0.1)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        position: 'relative', flexShrink: 0,
      }}>
        {Icon.arrowR('#fff')}
      </div>
    </div>
  );
}

// ── Doctor visit ─────────────────────────────────────────────
function DoctorVisit() {
  return (
    <div style={{
      background: PMO.card, borderRadius: 20, padding: 16,
      border: '1px solid ' + PMO.border,
      boxShadow: '0 2px 8px rgba(26,46,42,0.04)',
      display: 'flex', alignItems: 'center', gap: 14,
    }}>
      {/* date box */}
      <div style={{
        width: 60, height: 64, borderRadius: 14,
        background: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
        display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <div style={{ color: '#fff', fontSize: 22, fontWeight: 800, letterSpacing: -0.5, lineHeight: 1 }}>20</div>
        <div style={{ color: 'rgba(255,255,255,0.8)', fontSize: 10, fontWeight: 700, letterSpacing: 1, marginTop: 2 }}>JUN</div>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11, fontWeight: 700, color: PMO.textMute, letterSpacing: 0.6, textTransform: 'uppercase' }}>
          Kunjungan Berikutnya
        </div>
        <div style={{ fontSize: 16, fontWeight: 700, color: PMO.text, marginTop: 3, letterSpacing: -0.2 }}>
          Kontrol Rutin Dokter
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          <span style={{ fontSize: 12, color: PMO.textMute }}>RSUD Cipto · 09:30</span>
        </div>
      </div>
      <div style={{
        padding: '6px 10px', borderRadius: 100,
        background: PMO.secondarySoft, color: '#A66A00',
        fontSize: 11, fontWeight: 700, whiteSpace: 'nowrap',
      }}>
        11 hari lagi
      </div>
    </div>
  );
}

// ── Bottom nav ───────────────────────────────────────────────
function BottomNav({ active, onChange }) {
  const tabs = [
    { id: 'home', label: 'Beranda', icon: 'home' },
    { id: 'stats', label: 'Statistik', icon: 'stats' },
    { id: 'ai', label: 'PMO AI', icon: 'ai', center: true },
    { id: 'symptoms', label: 'Gejala', icon: 'symptoms' },
    { id: 'settings', label: 'Setelan', icon: 'settings' },
  ];

  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      background: 'rgba(255,255,255,0.95)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: '1px solid rgba(26,46,42,0.08)',
      padding: '10px 8px 28px',
      display: 'flex', justifyContent: 'space-around', alignItems: 'flex-start',
      zIndex: 30,
    }}>
      {tabs.map(t => {
        const isActive = active === t.id;
        return (
          <button
            key={t.id}
            onClick={() => onChange(t.id)}
            style={{
              flex: 1, background: 'transparent', border: 'none', cursor: 'pointer',
              padding: '6px 2px 4px', display: 'flex', flexDirection: 'column',
              alignItems: 'center', gap: 4,
            }}>
            <NavIcon kind={t.icon} active={isActive} />
            <span style={{
              fontSize: 10.5, fontWeight: isActive ? 700 : 500,
              color: isActive ? PMO.primary : '#9AAFA8',
              letterSpacing: -0.1,
            }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── App ──────────────────────────────────────────────────────
function DashboardApp() {
  const [confirmed, setConfirmed] = React.useState(false);
  const [tab, setTab] = React.useState('home');

  return (
    <div style={{
      height: '100%', background: PMO.bg, position: 'relative',
      fontFamily: '-apple-system, "SF Pro", system-ui, sans-serif',
      color: PMO.text,
    }}>
      <div style={{
        height: '100%', overflowY: 'auto', paddingBottom: 100,
      }}>
        <Header />
        <div style={{ padding: '16px 16px 0', display: 'flex', flexDirection: 'column', gap: 14 }}>
          <MedicineCard confirmed={confirmed} onConfirm={() => setConfirmed(c => !c)} />
          <ProgressCard />
          <MiniStats />
          <AIChatCard />
          <DoctorVisit />
        </div>
      </div>
      <BottomNav active={tab} onChange={setTab} />
    </div>
  );
}

Object.assign(window, { DashboardApp });
