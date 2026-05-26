// PMO Design System — shared tokens & primitives
// Locked from Home Dashboard. Import in every new screen.

const PMO = /* tokens */ {
  // Brand
  primary: '#1A6B5A',
  primaryDeep: '#125146',
  dark: '#1A2E2A',
  bg: '#F0F7F5',
  card: '#FFFFFF',

  // Accents
  amber: '#F5A623',
  amberSoft: '#FEF3E2',
  tealSoft: '#E8F5F1',
  success: '#27AE60',
  danger: '#E74C3C',

  // Text
  text: '#1A2E2A',
  textMute: '#6B8080',
  border: '#D4ECE6',

  // Radius / spacing
  rCard: 20,
  rBtn: 14,
  rPill: 100,
  pCard: 16,
  hBtn: 56,

  // Type
  fontHead: '"Poppins", -apple-system, system-ui, sans-serif',
  fontBody: '"Inter", -apple-system, system-ui, sans-serif',

  // Shadow
  shadowCard: '0 2px 12px rgba(26,46,42,0.05)',
  shadowSoft: '0 4px 20px rgba(26,46,42,0.06), 0 1px 3px rgba(26,46,42,0.04)',
};

// Medicine pill colors (exact, from home)
const PMO_MEDS = {
  R: { name: 'Rifampicin',  color: '#E74C3C', short: 'R' },
  H: { name: 'Isoniazid',   color: '#2E86DE', short: 'H' },
  Z: { name: 'Pirazinamid', color: '#F5A623', short: 'Z' },
  E: { name: 'Etambutol',   color: '#8B5CF6', short: 'E' },
};

// ─── Icons (shared) ──────────────────────────────────────────
const PMOIcon = {
  bell:   (c='#fff') => <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M6 8a6 6 0 1112 0c0 7 3 9 3 9H3s3-2 3-9" stroke={c} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/><path d="M10.3 21a1.94 1.94 0 003.4 0" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  back:   (c='#fff') => <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M15 18l-6-6 6-6" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  arrowR: (c='#fff') => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M5 12h14m-6-6l6 6-6 6" stroke={c} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  check:  (c='#fff') => <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M4 12.5l5 5 11-11" stroke={c} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/></svg>,
  camera: (c='#fff') => <svg width="22" height="22" viewBox="0 0 24 24" fill="none"><path d="M3 8a2 2 0 012-2h2.2l1.4-2h6.8l1.4 2H19a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" stroke={c} strokeWidth="1.8" strokeLinejoin="round"/><circle cx="12" cy="13" r="3.6" stroke={c} strokeWidth="1.8"/></svg>,
  clock:  (c=PMO.textMute) => <svg width="16" height="16" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke={c} strokeWidth="1.8"/><path d="M12 7v5l3 2" stroke={c} strokeWidth="1.8" strokeLinecap="round"/></svg>,
  flame:  () => <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M12 2s4 4 4 9a4 4 0 11-8 0c0-2 1-3 1-3s-2 2-2 5a5 5 0 0010 0c0-6-5-11-5-11z" fill="#FFB547" stroke="#E8851A" strokeWidth="0.6" strokeLinejoin="round"/></svg>,
  // The DigitalPMO mark (two leaf-lungs) — for headers
  mark: (c='#fff') => (
    <svg width="22" height="22" viewBox="0 0 80 80">
      <path d="M37 24 C23 24,13 33,11 47 C9 61,14 71,24 71 C32 71,37 66,37 57 C33 47,39 33,37 24 Z" fill={c}/>
      <path d="M43 24 C57 24,67 33,69 47 C71 61,66 71,56 71 C48 71,43 66,43 57 C47 47,41 33,43 24 Z" fill={c}/>
      <rect x="38" y="14" width="4" height="13" rx="2" fill={c}/>
      <circle cx="40" cy="10" r="4.2" fill="#F5A623"/>
    </svg>
  ),
};

// ─── Nav tab icons (used in BottomNav) ──────────────────────
function PMONavIcon({ kind, active }) {
  const c = active ? PMO.primary : '#9AAFA8';
  const w = active ? 2.2 : 1.8;
  const fill = active ? 'rgba(26,107,90,0.12)' : 'none';
  switch (kind) {
    case 'home': return <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M3 11l9-7 9 7v9a2 2 0 01-2 2h-4v-7h-6v7H5a2 2 0 01-2-2v-9z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={fill}/></svg>;
    case 'stats': return <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M4 20V10M10 20V4M16 20v-7M22 20H2" stroke={c} strokeWidth={w} strokeLinecap="round"/></svg>;
    case 'ai': return <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M12 2l1.8 4.4L18 8l-4.2 1.6L12 14l-1.8-4.4L6 8l4.2-1.6L12 2z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={fill}/><path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15z" stroke={c} strokeWidth={w} strokeLinejoin="round"/></svg>;
    case 'symptoms': return <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><path d="M12 21s-7-5-7-11a4 4 0 017-2.6A4 4 0 0119 10c0 6-7 11-7 11z" stroke={c} strokeWidth={w} strokeLinejoin="round" fill={fill}/></svg>;
    case 'settings': return <svg width="24" height="24" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="3" stroke={c} strokeWidth={w}/><path d="M19.4 15a1.6 1.6 0 00.3 1.7l.1.1a2 2 0 11-2.8 2.8l-.1-.1a1.6 1.6 0 00-1.7-.3 1.6 1.6 0 00-1 1.5V21a2 2 0 11-4 0v-.1a1.6 1.6 0 00-1-1.5 1.6 1.6 0 00-1.7.3l-.1.1a2 2 0 11-2.8-2.8l.1-.1a1.6 1.6 0 00.3-1.7 1.6 1.6 0 00-1.5-1H3a2 2 0 110-4h.1a1.6 1.6 0 001.5-1 1.6 1.6 0 00-.3-1.7l-.1-.1a2 2 0 112.8-2.8l.1.1a1.6 1.6 0 001.7.3H9a1.6 1.6 0 001-1.5V3a2 2 0 114 0v.1a1.6 1.6 0 001 1.5 1.6 1.6 0 001.7-.3l.1-.1a2 2 0 112.8 2.8l-.1.1a1.6 1.6 0 00-.3 1.7V9a1.6 1.6 0 001.5 1H21a2 2 0 110 4h-.1a1.6 1.6 0 00-1.5 1z" stroke={c} strokeWidth={w} strokeLinejoin="round"/></svg>;
  }
}

// ─── Curved Teal Header ─────────────────────────────────────
// Used by every screen. Pass either children OR (title, subtitle, onBack).
function PMOHeader({ title, subtitle, onBack, right, children, tall = false }) {
  return (
    <div style={{
      background: `linear-gradient(165deg, ${PMO.primary} 0%, #15594B 100%)`,
      padding: tall ? '64px 20px 32px' : '60px 20px 24px',
      borderBottomLeftRadius: 28, borderBottomRightRadius: 28,
      position: 'relative', overflow: 'hidden',
      fontFamily: PMO.fontBody,
    }}>
      <div style={{
        position: 'absolute', top: -40, right: -40, width: 180, height: 180,
        borderRadius: '50%', background: 'rgba(255,255,255,0.06)',
      }} />
      <div style={{
        position: 'absolute', bottom: -30, left: -20, width: 100, height: 100,
        borderRadius: '50%', background: 'rgba(255,255,255,0.05)',
      }} />

      {children ?? (
        <div style={{ position: 'relative', display: 'flex', alignItems: 'center', gap: 12 }}>
          {onBack && (
            <button onClick={onBack} style={{
              width: 40, height: 40, borderRadius: 12,
              background: 'rgba(255,255,255,0.15)', border: '1px solid rgba(255,255,255,0.2)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', flexShrink: 0,
            }}>{PMOIcon.back('#fff')}</button>
          )}
          <div style={{ flex: 1, minWidth: 0 }}>
            {subtitle && (
              <div style={{ color: 'rgba(255,255,255,0.7)', fontSize: 12, fontWeight: 600, letterSpacing: 0.5, textTransform: 'uppercase' }}>
                {subtitle}
              </div>
            )}
            <div style={{
              color: '#fff', fontSize: 22, fontWeight: 700, letterSpacing: -0.3,
              fontFamily: PMO.fontHead, marginTop: subtitle ? 2 : 0,
            }}>{title}</div>
          </div>
          {right}
        </div>
      )}
    </div>
  );
}

// ─── Bottom Nav ─────────────────────────────────────────────
function PMOBottomNav({ active, onChange }) {
  const tabs = [
    { id: 'home', label: 'Beranda', icon: 'home' },
    { id: 'stats', label: 'Statistik', icon: 'stats' },
    { id: 'ai', label: 'PMO AI', icon: 'ai' },
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
      zIndex: 30, fontFamily: PMO.fontBody,
    }}>
      {tabs.map(t => {
        const isActive = active === t.id;
        return (
          <button key={t.id} onClick={() => onChange && onChange(t.id)} style={{
            flex: 1, background: 'transparent', border: 'none', cursor: 'pointer',
            padding: '6px 2px 4px', display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 4,
          }}>
            <PMONavIcon kind={t.icon} active={isActive} />
            <span style={{
              fontSize: 11, fontWeight: isActive ? 700 : 500,
              color: isActive ? PMO.primary : '#9AAFA8',
              letterSpacing: -0.1, fontFamily: PMO.fontBody,
            }}>{t.label}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─── Primitives ─────────────────────────────────────────────
function PMOCard({ children, style = {}, onClick }) {
  return (
    <div onClick={onClick} style={{
      background: PMO.card, borderRadius: PMO.rCard, padding: PMO.pCard,
      border: '1px solid ' + PMO.border,
      boxShadow: PMO.shadowCard,
      cursor: onClick ? 'pointer' : 'default',
      ...style,
    }}>{children}</div>
  );
}

function PMOButton({ children, onClick, variant = 'primary', icon, style = {} }) {
  const bg = {
    primary: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
    success: `linear-gradient(180deg, #1FA15A 0%, #167A45 100%)`,
    amber: `linear-gradient(180deg, ${PMO.amber} 0%, #D88A12 100%)`,
    ghost: 'transparent',
  }[variant];
  const color = variant === 'ghost' ? PMO.primary : '#fff';
  const shadow = variant === 'ghost' ? 'none' :
    variant === 'success' ? '0 6px 16px rgba(31,161,90,0.35)' :
    variant === 'amber' ? '0 6px 16px rgba(245,166,35,0.35)' :
    '0 6px 16px rgba(26,107,90,0.35)';
  return (
    <button onClick={onClick} style={{
      width: '100%', height: PMO.hBtn, borderRadius: PMO.rBtn,
      background: bg, color, border: variant === 'ghost' ? `1.5px solid ${PMO.border}` : 'none',
      fontSize: 16, fontWeight: 700, fontFamily: PMO.fontBody,
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      cursor: 'pointer', letterSpacing: -0.2,
      boxShadow: shadow, transition: 'all 0.2s', ...style,
    }}>
      {icon}
      {children}
    </button>
  );
}

function PMOBadge({ children, tone = 'teal', dot = false }) {
  const styles = {
    teal:    { bg: PMO.tealSoft,  fg: PMO.primary, dotC: PMO.primary },
    amber:   { bg: PMO.amberSoft, fg: '#A66A00',   dotC: PMO.amber },
    success: { bg: '#E6F4EC',     fg: '#137A3F',   dotC: PMO.success },
    danger:  { bg: '#FBE5E2',     fg: '#A1281C',   dotC: PMO.danger },
    mute:    { bg: '#EEF2F0',     fg: PMO.textMute, dotC: PMO.textMute },
  }[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '6px 12px', borderRadius: PMO.rPill,
      background: styles.bg, color: styles.fg,
      fontSize: 12, fontWeight: 700, letterSpacing: 0.2,
      fontFamily: PMO.fontBody, whiteSpace: 'nowrap',
    }}>
      {dot && <span style={{ width: 7, height: 7, borderRadius: '50%', background: styles.dotC }} />}
      {children}
    </span>
  );
}

function PMOMedPill({ kind, size = 32 }) {
  const m = PMO_MEDS[kind];
  return (
    <div style={{
      width: size, height: size, borderRadius: '50%',
      background: m.color, color: '#fff',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      fontWeight: 800, fontSize: size * 0.44, letterSpacing: -0.4,
      fontFamily: PMO.fontHead,
      boxShadow: `0 3px 8px ${m.color}55`,
      flexShrink: 0,
    }}>{m.short}</div>
  );
}

// Small label text (date/eyebrow)
function PMOLabel({ children, color, style = {} }) {
  return (
    <div style={{
      fontSize: 12, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase',
      color: color || PMO.textMute, fontFamily: PMO.fontBody, ...style,
    }}>{children}</div>
  );
}

// Screen scaffold — full screen with optional header, scroll area, bottom nav
function PMOScreen({ header, children, activeTab, onTabChange }) {
  return (
    <div style={{
      height: '100%', background: PMO.bg, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text,
    }}>
      <div style={{ height: '100%', overflowY: 'auto', paddingBottom: 100 }}>
        {header}
        {children}
      </div>
      {activeTab !== undefined && (
        <PMOBottomNav active={activeTab} onChange={onTabChange} />
      )}
    </div>
  );
}

Object.assign(window, {
  PMO, PMO_MEDS, PMOIcon, PMONavIcon,
  PMOHeader, PMOBottomNav, PMOCard, PMOButton, PMOBadge,
  PMOMedPill, PMOLabel, PMOScreen,
});
