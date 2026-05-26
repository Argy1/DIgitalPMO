// Shared auth components — refined

// ─── Teal header with logo + wordmark + tagline + optional greeting ──
function AuthHeader({ tagline = 'Pendamping Cerdas Pengobatan TB', greeting, height = '38%' }) {
  return (
    <div style={{
      height,
      background: `linear-gradient(165deg, ${PMO.primary} 0%, #15594B 100%)`,
      position: 'relative', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center',
      padding: '0 32px',
    }}>
      {/* Organic blob shapes — partially visible at edges, very subtle */}
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.06 }}
        viewBox="0 0 390 320" preserveAspectRatio="xMidYMid slice">
        <path d="M-40,80 C 40,20 140,40 180,100 C 220,170 140,220 60,200 C -20,180 -80,140 -40,80 Z" fill="#fff"/>
        <path d="M310,-20 C 380,10 410,90 380,140 C 350,190 270,170 250,110 C 230,50 240,-50 310,-20 Z" fill="#fff"/>
        <path d="M180,250 C 240,220 320,250 340,310 C 360,370 290,400 220,380 C 150,360 120,280 180,250 Z" fill="#fff"/>
      </svg>
      <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.4 }}>
        <defs>
          <pattern id="authDots" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
            <circle cx="2" cy="2" r="1" fill="#fff" opacity="0.18"/>
          </pattern>
        </defs>
        <rect width="100%" height="100%" fill="url(#authDots)"/>
      </svg>

      {/* Logo + text */}
      <div style={{ position: 'relative', zIndex: 2, textAlign: 'center', paddingTop: 20 }}>
        <div style={{
          width: 64, height: 64, borderRadius: 18, margin: '0 auto 14px',
          background: 'rgba(255,255,255,0.16)',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: [
            '0 0 0 1px rgba(255,255,255,0.18) inset',
            '0 1px 0 rgba(255,255,255,0.25) inset',
            '0 10px 24px rgba(0,0,0,0.18)',
            '0 0 32px rgba(255,255,255,0.18)', // soft outer glow
          ].join(', '),
        }}>
          <svg width="40" height="40" viewBox="0 0 80 80" style={{
            filter: 'drop-shadow(0 1px 2px rgba(0,0,0,0.18))',
          }}>
            <path d="M37 24 C23 24,13 33,11 47 C9 61,14 71,24 71 C32 71,37 66,37 57 C33 47,39 33,37 24 Z" fill="#fff"/>
            <path d="M43 24 C57 24,67 33,69 47 C71 61,66 71,56 71 C48 71,43 66,43 57 C47 47,41 33,43 24 Z" fill="#fff"/>
            <rect x="38" y="14" width="4" height="13" rx="2" fill="#fff"/>
            <circle cx="40" cy="10" r="4.2" fill={PMO.amber}/>
          </svg>
        </div>

        <div style={{
          fontFamily: PMO.fontHead, fontSize: 24, fontWeight: 700,
          color: '#fff', letterSpacing: -0.5,
        }}>DigitalPMO</div>

        <div style={{
          fontSize: 13, color: 'rgba(255,255,255,0.75)', fontWeight: 500,
          marginTop: 4, letterSpacing: 0.1,
        }}>{tagline}</div>

        {greeting && (
          <div style={{
            fontSize: 16, color: 'rgba(255,255,255,0.9)', fontWeight: 500,
            marginTop: 18, letterSpacing: -0.1,
          }}>{greeting}</div>
        )}
      </div>

      {/* Wave */}
      <svg style={{
        position: 'absolute', bottom: -1, left: 0, right: 0,
        width: '100%', height: 32, display: 'block', zIndex: 4,
      }} viewBox="0 0 390 32" preserveAspectRatio="none">
        <path
          d="M0,32 C 65,32 130,0 195,0 C 260,0 325,32 390,32 L 390,32 L 0,32 Z"
          fill="#fff"
        />
      </svg>
    </div>
  );
}

// ─── Input with floating label, error state, char count ───────────────
function AuthInput({
  label, icon, rightIcon, note, error,
  value, onChange, placeholder, type = 'text',
  maxLength, showCount = false,
}) {
  const [focused, setFocused] = React.useState(false);
  const filled = value && value.length > 0;
  const elevated = focused || filled;
  const hasError = !!error;

  const borderColor = hasError ? PMO.danger : focused ? PMO.primary : '#D4ECE6';
  const iconColor = hasError ? PMO.danger : focused ? PMO.primaryDeep : PMO.primary;

  return (
    <div>
      {/* Floating label */}
      <label style={{
        display: 'flex', alignItems: 'center', gap: 6,
        fontSize: 12, fontWeight: 700,
        color: hasError ? PMO.danger : (elevated ? PMO.primary : PMO.textMute),
        letterSpacing: 0.4, textTransform: 'uppercase',
        marginBottom: elevated ? 8 : 6,
        transform: elevated ? 'translateY(-2px)' : 'translateY(0)',
        transition: 'all 0.2s ease',
        fontFamily: PMO.fontBody,
      }}>
        {label}
        {hasError && (
          <span style={{ width: 5, height: 5, borderRadius: '50%', background: PMO.danger }}/>
        )}
      </label>

      <div style={{ position: 'relative' }}>
        {icon && (
          <div style={{
            position: 'absolute', left: 14, top: '50%', transform: 'translateY(-50%)',
            display: 'flex', alignItems: 'center', zIndex: 2, pointerEvents: 'none',
            color: iconColor, transition: 'color 0.2s',
          }}>{React.cloneElement(icon, { color: iconColor })}</div>
        )}
        <input
          type={type}
          value={value}
          onChange={onChange}
          onFocus={() => setFocused(true)}
          onBlur={() => setFocused(false)}
          placeholder={placeholder}
          maxLength={maxLength}
          style={{
            width: '100%', height: 52,
            background: hasError ? '#FFF6F5' : '#F8FAF9',
            border: `1.5px solid ${borderColor}`,
            borderRadius: 12,
            padding: '0 14px',
            paddingLeft: icon ? 44 : 14,
            paddingRight: rightIcon ? 44 : 14,
            fontSize: 16, fontFamily: PMO.fontBody, color: PMO.text,
            outline: 'none', boxSizing: 'border-box',
            transition: 'all 0.2s',
            boxShadow: focused
              ? `0 0 0 4px ${hasError ? PMO.danger + '1f' : PMO.primary + '1a'}`
              : 'none',
          }}
        />
        {rightIcon && (
          <div style={{
            position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)',
          }}>{rightIcon}</div>
        )}
      </div>

      {/* Error message or note + optional char count */}
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
        marginTop: 6, gap: 8, minHeight: hasError || note ? 14 : 0,
      }}>
        <div style={{
          fontSize: 11, fontWeight: 500,
          color: hasError ? PMO.danger : PMO.textMute,
          display: 'flex', alignItems: 'center', gap: 4,
          paddingLeft: 4,
        }}>
          {hasError && (
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
              <circle cx="12" cy="12" r="10" fill={PMO.danger}/>
              <path d="M12 8v4M12 16h.01" stroke="#fff" strokeWidth="2.4" strokeLinecap="round"/>
            </svg>
          )}
          {error || note}
        </div>
        {showCount && maxLength && (
          <div style={{
            fontSize: 11, fontWeight: 600, color: PMO.textMute,
            fontVariantNumeric: 'tabular-nums', paddingRight: 4,
          }}>{(value || '').length}/{maxLength}</div>
        )}
      </div>
    </div>
  );
}

// ─── Eye toggle ─────────────────────────────────────────────
function AuthEyeToggle({ shown, onToggle }) {
  return (
    <button type="button" onClick={onToggle} style={{
      background: 'transparent', border: 'none', cursor: 'pointer',
      padding: 8, display: 'flex', alignItems: 'center',
    }}>
      {shown ? (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z" stroke={PMO.textMute} strokeWidth="1.8" strokeLinejoin="round"/>
          <circle cx="12" cy="12" r="3" stroke={PMO.textMute} strokeWidth="1.8"/>
        </svg>
      ) : (
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M17.94 17.94A10.94 10.94 0 0112 20c-7 0-11-8-11-8a19.7 19.7 0 014.22-5.61M9.9 4.24A10.94 10.94 0 0112 4c7 0 11 8 11 8a19.7 19.7 0 01-2.16 3.19M14.12 14.12a3 3 0 11-4.24-4.24M1 1l22 22"
            stroke={PMO.textMute} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      )}
    </button>
  );
}

// ─── Password strength indicator (3 bars: red/amber/green) ───────────
function PasswordStrength({ value }) {
  const v = value || '';
  let level = 0;
  if (v.length >= 6) level = 1;
  if (v.length >= 8) level = 2;
  if (v.length >= 8 && /[0-9]/.test(v) && /[^A-Za-z0-9]/.test(v)) level = 3;
  if (v.length >= 10 && /[A-Z]/.test(v) && /[0-9]/.test(v)) level = Math.max(level, 3);

  const palettes = [
    { color: '#E2EAE7', label: '' },
    { color: PMO.danger, label: 'Lemah' },
    { color: PMO.amber, label: 'Cukup' },
    { color: PMO.success, label: 'Kuat' },
  ];
  const active = palettes[level];

  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 8,
      marginTop: 8, paddingLeft: 4,
    }}>
      <div style={{ display: 'flex', gap: 4, flex: 1 }}>
        {[0, 1, 2].map(i => (
          <div key={i} style={{
            flex: 1, height: 4, borderRadius: 100,
            background: i < level ? active.color : '#E2EAE7',
            transition: 'background 0.25s',
            boxShadow: i < level ? `0 0 6px ${active.color}66` : 'none',
          }}/>
        ))}
      </div>
      {v.length > 0 && (
        <span style={{
          fontSize: 11, fontWeight: 700, color: active.color,
          letterSpacing: 0.2, textTransform: 'uppercase', minWidth: 36,
          fontFamily: PMO.fontBody,
        }}>{active.label}</span>
      )}
    </div>
  );
}

// ─── CTA with ripple + loading state ────────────────────────────────
function AuthCTA({ children, onClick, disabled = false, loading = false, loadingLabel = 'Memverifikasi' }) {
  const [dots, setDots] = React.useState('');
  React.useEffect(() => {
    if (!loading) return;
    let i = 0;
    const t = setInterval(() => {
      i = (i + 1) % 4;
      setDots('.'.repeat(i));
    }, 350);
    return () => clearInterval(t);
  }, [loading]);

  const isDisabled = disabled || loading;
  return (
    <button onClick={onClick} disabled={isDisabled} style={{
      position: 'relative', overflow: 'hidden',
      width: '100%', height: 56, borderRadius: 14,
      background: isDisabled
        ? `linear-gradient(180deg, #8EAEA6 0%, #708F87 100%)`
        : `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
      border: 'none', color: '#fff',
      fontSize: 16, fontWeight: 700, fontFamily: PMO.fontHead, letterSpacing: -0.2,
      cursor: isDisabled ? 'not-allowed' : 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
      boxShadow: isDisabled ? 'none' : [
        '0 6px 16px rgba(26,107,90,0.32)',
        '0 1px 0 rgba(255,255,255,0.18) inset',
        '0 -2px 0 rgba(0,0,0,0.10) inset',
      ].join(', '),
      transition: 'all 0.2s',
    }}>
      {/* Ripple/sheen hint */}
      {!isDisabled && (
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(140% 60% at 50% 0%, rgba(255,255,255,0.18), transparent 70%)',
          pointerEvents: 'none',
        }}/>
      )}
      {loading ? (
        <>
          <Spinner />
          <span style={{ fontVariantNumeric: 'tabular-nums' }}>
            {loadingLabel}{dots}
          </span>
        </>
      ) : children}
    </button>
  );
}

// ─── Spinner ────────────────────────────────────────────────
function Spinner({ size = 18, color = '#fff' }) {
  return (
    <>
      <style>{`@keyframes pmoSpin { to { transform: rotate(360deg); } }`}</style>
      <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
        style={{ animation: 'pmoSpin 0.7s linear infinite' }}>
        <circle cx="12" cy="12" r="10" stroke={color} strokeWidth="3" strokeOpacity="0.3"/>
        <path d="M22 12a10 10 0 00-10-10" stroke={color} strokeWidth="3" strokeLinecap="round"/>
      </svg>
    </>
  );
}

// ─── Checkbox ────────────────────────────────────────────────────────
function AuthCheckbox({ checked, onChange, children }) {
  return (
    <label style={{
      display: 'flex', alignItems: 'flex-start', gap: 10,
      cursor: 'pointer', userSelect: 'none',
    }}>
      <div onClick={onChange} style={{
        width: 18, height: 18, borderRadius: 5, flexShrink: 0,
        background: checked ? PMO.primary : '#fff',
        border: `1.5px solid ${checked ? PMO.primary : '#C2D6CF'}`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        marginTop: 1, transition: 'all 0.15s',
        boxShadow: checked ? `0 2px 6px ${PMO.primary}55` : 'none',
      }}>
        {checked && (
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
            <path d="M4 12.5l5 5 11-11" stroke="#fff" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        )}
      </div>
      <div style={{ fontSize: 12, color: PMO.textMute, lineHeight: 1.5 }}>{children}</div>
    </label>
  );
}

// ─── Security note ──────────────────────────────────────────────────
function AuthSecurityNote() {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      fontSize: 11, color: PMO.textMute, fontWeight: 500,
    }}>
      <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
        <rect x="4" y="10" width="16" height="11" rx="2.5" stroke={PMO.textMute} strokeWidth="2"/>
        <path d="M8 10V7a4 4 0 018 0v3" stroke={PMO.textMute} strokeWidth="2" strokeLinecap="round"/>
      </svg>
      Data kamu aman & terenkripsi
    </div>
  );
}

// ─── Icons with dynamic color support ───────────────────────────────
const AuthIcons = {
  user: <UserIcon/>,
  phone: <PhoneIcon/>,
  lock: <LockIcon/>,
  lockCheck: <LockCheckIcon/>,
};
function UserIcon({ color = PMO.primary }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="8" r="4" stroke={color} strokeWidth="1.8"/>
      <path d="M4 21c0-4 4-7 8-7s8 3 8 7" stroke={color} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  );
}
function PhoneIcon({ color = PMO.primary }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <path d="M5 4a1 1 0 011-1h3l2 5-2.5 1.5a11 11 0 005 5L14 12l5 2v3a1 1 0 01-1 1A15 15 0 014 5z" stroke={color} strokeWidth="1.8" strokeLinejoin="round"/>
    </svg>
  );
}
function LockIcon({ color = PMO.primary }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <rect x="4" y="10" width="16" height="11" rx="2.5" stroke={color} strokeWidth="1.8"/>
      <path d="M8 10V7a4 4 0 018 0v3" stroke={color} strokeWidth="1.8" strokeLinecap="round"/>
    </svg>
  );
}
function LockCheckIcon({ color = PMO.primary }) {
  return (
    <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
      <rect x="4" y="10" width="16" height="11" rx="2.5" stroke={color} strokeWidth="1.8"/>
      <path d="M8 10V7a4 4 0 018 0v3" stroke={color} strokeWidth="1.8" strokeLinecap="round"/>
      <path d="M9 16l2 2 4-4" stroke={color} strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

Object.assign(window, {
  AuthHeader, AuthInput, AuthEyeToggle, AuthCTA, AuthCheckbox, AuthSecurityNote,
  AuthIcons, PasswordStrength, Spinner,
});
