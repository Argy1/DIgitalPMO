// Shared chat components — refined v2

// ─── Header ──────────────────────────────────────────────────
function ChatHeader({ thinking = false }) {
  return (
    <div style={{
      background: `linear-gradient(165deg, ${PMO.primary} 0%, #15594B 100%)`,
      padding: '56px 16px 14px',
      display: 'flex', alignItems: 'center', gap: 10,
      position: 'relative', zIndex: 5,
    }}>
      <style>{`
        @keyframes pmoHeaderRing { 0%,100% { transform: scale(1); opacity: 0.6 } 50% { transform: scale(1.18); opacity: 0.18 } }
      `}</style>

      <button style={{
        width: 40, height: 40, borderRadius: 12,
        background: 'rgba(255,255,255,0.15)',
        border: '1px solid rgba(255,255,255,0.2)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: 'pointer', flexShrink: 0,
      }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <path d="M15 18l-6-6 6-6" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>

      <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 10, justifyContent: 'center' }}>
        {/* Avatar with pulsing ring */}
        <div style={{ position: 'relative', width: 36, height: 36 }}>
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            background: 'rgba(255,255,255,0.25)',
            animation: 'pmoHeaderRing 2.4s ease-in-out infinite',
          }}/>
          <div style={{
            position: 'absolute', top: 2, left: 2, right: 2, bottom: 2,
            borderRadius: '50%',
            background: 'rgba(255,255,255,0.18)',
            border: '1px solid rgba(255,255,255,0.28)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <RobotGlyph size={18} color="#fff" thin/>
          </div>
        </div>

        <div>
          <div style={{
            fontFamily: PMO.fontHead, fontSize: 16, fontWeight: 700,
            color: '#fff', letterSpacing: -0.2, lineHeight: 1.1,
          }}>PMO Digital</div>
          <div style={{
            display: 'flex', alignItems: 'center', gap: 5,
            fontSize: 11, color: thinking ? 'rgba(255,255,255,0.55)' : 'rgba(255,255,255,0.85)',
            marginTop: 2, fontStyle: thinking ? 'italic' : 'normal',
          }}>
            {thinking ? (
              <>
                <Spinner size={10} color="rgba(255,255,255,0.7)"/>
                Sedang berpikir...
              </>
            ) : (
              <>
                <span style={{
                  width: 8, height: 8, borderRadius: '50%',
                  background: '#3ED27E',
                  boxShadow: '0 0 8px #3ED27E, 0 0 2px #3ED27E',
                }}/>
                Aktif
              </>
            )}
          </div>
        </div>
      </div>

      <button style={{
        width: 40, height: 40, borderRadius: 12,
        background: 'rgba(255,255,255,0.12)',
        border: '1px solid rgba(255,255,255,0.18)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        cursor: 'pointer', flexShrink: 0,
      }}>
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="9" stroke="#fff" strokeWidth="1.8"/>
          <path d="M12 8v.01M12 12v4" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      </button>
    </div>
  );
}

function ChatDisclaimer({ onDismiss }) {
  return (
    <div style={{
      background: '#FEF3E2', padding: '8px 14px',
      display: 'flex', alignItems: 'center', gap: 8,
      borderBottom: '1px solid rgba(232,144,26,0.12)',
    }}>
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" style={{ flexShrink: 0 }}>
        <circle cx="12" cy="12" r="9" stroke="#B8760A" strokeWidth="1.8"/>
        <path d="M12 8v4M12 16h.01" stroke="#B8760A" strokeWidth="2" strokeLinecap="round"/>
      </svg>
      <div style={{ flex: 1, fontSize: 11, color: '#B8760A', fontWeight: 600, lineHeight: 1.35 }}>
        PMO Digital memberikan edukasi, bukan diagnosis medis
      </div>
      <button onClick={onDismiss} style={{
        background: 'transparent', border: 'none', cursor: 'pointer',
        padding: 4, display: 'flex', alignItems: 'center', flexShrink: 0,
      }}>
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M6 6l12 12M18 6L6 18" stroke="#B8760A" strokeWidth="2.4" strokeLinecap="round"/>
        </svg>
      </button>
    </div>
  );
}

function RobotGlyph({ size = 32, color = '#fff', thin = false }) {
  const sw = thin ? 1.6 : 1.8;
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <rect x="4" y="7" width="16" height="12" rx="4" stroke={color} strokeWidth={sw}/>
      <circle cx="9" cy="13" r="1.4" fill={color}/>
      <circle cx="15" cy="13" r="1.4" fill={color}/>
      <path d="M12 4v3M9 19v2M15 19v2" stroke={color} strokeWidth={sw} strokeLinecap="round"/>
      <circle cx="12" cy="3" r="1.2" fill={color}/>
    </svg>
  );
}

function ChatAvatar() {
  return (
    <div style={{
      width: 32, height: 32, borderRadius: '50%',
      background: `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      boxShadow: `0 3px 8px ${PMO.primary}55, inset 0 1px 0 rgba(255,255,255,0.18)`,
      flexShrink: 0,
    }}>
      <RobotGlyph size={18} color="#fff" thin/>
    </div>
  );
}

// ─── Input bar — controlled, with active/empty states ───────
function ChatInputBar({ defaultValue = '', focused = false, voiceActive = false }) {
  const [value, setValue] = React.useState(defaultValue);
  const [isFocused, setIsFocused] = React.useState(focused);
  const hasContent = value.trim().length > 0;

  return (
    <div style={{
      background: '#fff',
      padding: '12px 16px 34px',
      boxShadow: '0 -4px 14px rgba(26,46,42,0.06)',
      borderTop: `1px solid ${PMO.border}`,
      transition: 'all 0.25s ease',
    }}>
      <div style={{
        background: (isFocused || hasContent) ? '#fff' : PMO.bg,
        borderRadius: 24,
        height: 48, padding: '0 6px 0 14px',
        display: 'flex', alignItems: 'center', gap: 10,
        border: (isFocused || hasContent) ? `1.5px solid ${PMO.primary}` : '1.5px solid transparent',
        boxShadow: isFocused ? `0 0 0 4px ${PMO.primary}1a` : 'none',
        transition: 'all 0.2s',
      }}>
        {/* Voice/mic */}
        <button style={{
          width: 32, height: 32, borderRadius: '50%',
          background: voiceActive ? PMO.primary + '1a' : 'transparent',
          border: 'none', cursor: 'pointer', flexShrink: 0,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          transition: 'background 0.2s',
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <rect x="9" y="3" width="6" height="11" rx="3"
              stroke={voiceActive ? PMO.primary : '#9AAFA8'} strokeWidth="1.8"/>
            <path d="M5 11a7 7 0 0014 0M12 18v3"
              stroke={voiceActive ? PMO.primary : '#9AAFA8'} strokeWidth="1.8" strokeLinecap="round"/>
          </svg>
        </button>

        <input
          value={value}
          onChange={e => setValue(e.target.value)}
          onFocus={() => setIsFocused(true)}
          onBlur={() => setIsFocused(false)}
          placeholder="Ketik pertanyaanmu..."
          autoFocus={focused}
          style={{
            flex: 1, height: '100%', border: 'none', outline: 'none',
            background: 'transparent', fontSize: 14, color: PMO.text,
            fontFamily: PMO.fontBody,
          }}
        />

        {/* Send button: active when content present */}
        <button disabled={!hasContent} style={{
          width: 40, height: 40, borderRadius: '50%',
          background: hasContent
            ? `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`
            : '#CFDDD8',
          border: 'none',
          cursor: hasContent ? 'pointer' : 'not-allowed',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
          boxShadow: hasContent
            ? `0 4px 10px ${PMO.primary}55, inset 0 1px 0 rgba(255,255,255,0.2)`
            : 'none',
          transition: 'all 0.2s',
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M3 12l18-9-7 18-3-7-8-2z" fill="#fff" stroke="#fff" strokeWidth="1.4" strokeLinejoin="round"/>
          </svg>
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { ChatHeader, ChatDisclaimer, ChatAvatar, RobotGlyph, ChatInputBar });
