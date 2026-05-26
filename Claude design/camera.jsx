// Medication Photo Confirmation — Camera screen (dark UI)

function CameraScreen() {
  return (
    <div style={{
      height: '100%', background: '#000', position: 'relative',
      fontFamily: PMO.fontBody, color: '#fff', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <style>{`
        @keyframes pmoScan { 0%{top:0;opacity:0} 10%{opacity:1} 90%{opacity:1} 100%{top:100%;opacity:0} }
        @keyframes pmoPulse { 0%,100%{transform:scale(1);opacity:1} 50%{transform:scale(1.6);opacity:0} }
      `}</style>

      {/* ── TOP BAR (56px) ─────────────────────────────────── */}
      <div style={{
        height: 56, paddingTop: 50,
        background: '#000',
        display: 'flex', alignItems: 'center', padding: '50px 16px 0',
        position: 'relative', zIndex: 5, boxSizing: 'content-box',
      }}>
        <button style={{
          width: 36, height: 36, borderRadius: '50%',
          background: '#333', border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexShrink: 0,
        }}>
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
            <path d="M6 6l12 12M18 6L6 18" stroke="#fff" strokeWidth="2.4" strokeLinecap="round"/>
          </svg>
        </button>
        <div style={{
          position: 'absolute', left: 0, right: 0, textAlign: 'center',
          fontFamily: PMO.fontHead, fontSize: 16, fontWeight: 700,
          color: '#fff', letterSpacing: -0.2, pointerEvents: 'none',
          paddingTop: 50,
        }}>
          Foto Obat Kamu
        </div>
      </div>

      {/* ── CAMERA PREVIEW ─────────────────────────────────── */}
      <div style={{
        flex: 1, background: 'radial-gradient(circle at 50% 40%, #1a1a1a 0%, #050505 90%)',
        position: 'relative', overflow: 'hidden',
        minHeight: 340,
      }}>
        {/* Subtle grid/noise texture */}
        <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:0.25 }}>
          <defs>
            <pattern id="cameraGrid" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
              <path d="M40 0H0V40" fill="none" stroke="#222" strokeWidth="0.5"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#cameraGrid)"/>
        </svg>

        {/* Scan guide — 4 corner brackets only */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 280, height: 200,
        }}>
          {/* Corners */}
          {[
            { top: 0, left: 0, br: '12px 0 0 0' },
            { top: 0, right: 0, br: '0 12px 0 0' },
            { bottom: 0, left: 0, br: '0 0 0 12px' },
            { bottom: 0, right: 0, br: '0 0 12px 0' },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute',
              top: c.top, left: c.left, right: c.right, bottom: c.bottom,
              width: 24, height: 24,
              borderTop: c.top !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderBottom: c.bottom !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderLeft: c.left !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderRight: c.right !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderRadius: c.br,
              filter: `drop-shadow(0 0 6px ${PMO.primary}cc)`,
            }} />
          ))}

          {/* Pill icon + label */}
          <div style={{
            position: 'absolute', top: '50%', left: '50%',
            transform: 'translate(-50%, -50%)',
            textAlign: 'center',
          }}>
            <svg width="32" height="32" viewBox="0 0 24 24" fill="none"
              style={{ opacity: 0.25, margin: '0 auto', display: 'block' }}>
              <rect x="2" y="9" width="20" height="6" rx="3" stroke="#fff" strokeWidth="1.8" transform="rotate(-30 12 12)"/>
              <path d="M8 6.7l4.8 8.4" stroke="#fff" strokeWidth="1.8" transform="rotate(-30 12 12)"/>
            </svg>
            <div style={{
              marginTop: 10, fontSize: 12, color: 'rgba(255,255,255,0.6)',
              fontWeight: 500, letterSpacing: 0.2,
            }}>
              Letakkan obat di sini
            </div>
          </div>

          {/* Scan line — animated top to bottom */}
          <div style={{
            position: 'absolute', left: 0, right: 0,
            height: 2,
            background: `linear-gradient(90deg, transparent 0%, ${PMO.primary} 50%, transparent 100%)`,
            filter: `drop-shadow(0 0 8px ${PMO.primary})`,
            animation: 'pmoScan 2.4s ease-in-out infinite',
          }} />
        </div>
      </div>

      {/* ── AI STATUS BAR ──────────────────────────────────── */}
      <div style={{
        background: '#1A1A1A',
        padding: '10px 20px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        borderTop: '1px solid rgba(255,255,255,0.04)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {/* AI sparkle icon */}
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M12 2l1.8 4.4L18 8l-4.2 1.6L12 14l-1.8-4.4L6 8l4.2-1.6L12 2z"
              fill={PMO.primary} stroke={PMO.primary} strokeWidth="1.2" strokeLinejoin="round"/>
            <path d="M19 15l.9 2.1L22 18l-2.1.9L19 21l-.9-2.1L16 18l2.1-.9L19 15z"
              fill={PMO.primary}/>
          </svg>
          <span style={{
            fontSize: 13, fontWeight: 600, color: '#9ECFC4',
            fontFamily: PMO.fontBody, letterSpacing: -0.1,
          }}>
            AI siap memverifikasi
          </span>
        </div>
        {/* Pulsing green dot */}
        <div style={{ position: 'relative', width: 10, height: 10 }}>
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            background: '#3ED27E',
            animation: 'pmoPulse 1.8s ease-out infinite',
          }} />
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            background: '#3ED27E', boxShadow: '0 0 8px #3ED27E',
          }} />
        </div>
      </div>

      {/* ── BOTTOM SHEET (white) ───────────────────────────── */}
      <div style={{
        background: '#fff', position: 'relative',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '8px 20px 30px',
        marginTop: -2,
        zIndex: 2,
      }}>
        {/* Drag handle */}
        <div style={{
          width: 36, height: 4, borderRadius: 100,
          background: '#D4DAD8', margin: '0 auto 14px',
        }} />

        {/* Medicine reminder label */}
        <div style={{
          fontSize: 10, fontWeight: 700, color: PMO.textMute,
          letterSpacing: 1.2, textTransform: 'uppercase',
          marginBottom: 10,
        }}>
          Obat yang harus difoto
        </div>

        {/* Pills row */}
        <div style={{
          display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8,
        }}>
          {Object.keys(PMO_MEDS).map(k => {
            const m = PMO_MEDS[k];
            return (
              <div key={k} style={{
                display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
              }}>
                <div style={{
                  width: 32, height: 32, borderRadius: '50%',
                  background: `radial-gradient(circle at 30% 25%, ${m.color}ff 0%, ${m.color}cc 100%)`,
                  color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontWeight: 800, fontSize: 14, fontFamily: PMO.fontHead, letterSpacing: -0.4,
                  boxShadow: `0 4px 8px ${m.color}55, inset 0 1px 0 rgba(255,255,255,0.25)`,
                }}>{m.short}</div>
                <div style={{
                  fontSize: 11, color: PMO.textMute, fontWeight: 600,
                  letterSpacing: -0.1,
                }}>{m.name}</div>
              </div>
            );
          })}
        </div>

        {/* Divider */}
        <div style={{ height: 1, background: PMO.border, margin: '14px 0 12px' }} />

        {/* Tips */}
        <div style={{
          fontSize: 13, fontWeight: 700, color: PMO.text,
          fontFamily: PMO.fontBody, marginBottom: 8,
        }}>
          💡 Tips foto yang baik
        </div>
        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr',
          rowGap: 6, columnGap: 12,
          fontSize: 12, color: PMO.text, fontWeight: 500,
        }}>
          {['Cahaya cukup', 'Tidak blur', 'Semua obat ada', 'Latar polos'].map(t => (
            <div key={t} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <circle cx="12" cy="12" r="10" fill={PMO.tealSoft}/>
                <path d="M7 12.5l3.5 3.5 6.5-7" stroke={PMO.primary} strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
              </svg>
              {t}
            </div>
          ))}
        </div>

        {/* Capture button */}
        <div style={{
          marginTop: 18, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
        }}>
          <button style={{
            width: 84, height: 84, borderRadius: '50%',
            background: 'transparent',
            border: `3px solid ${PMO.primary}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', padding: 0,
            boxShadow: `0 8px 20px rgba(26,107,90,0.18)`,
            transition: 'transform 0.15s',
          }}>
            <div style={{
              width: 68, height: 68, borderRadius: '50%',
              background: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: 'inset 0 -2px 4px rgba(0,0,0,0.08)',
            }}>
              <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
                <path d="M3 8a2 2 0 012-2h2.2l1.4-2h6.8l1.4 2H19a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
                  stroke={PMO.primary} strokeWidth="2" strokeLinejoin="round"/>
                <circle cx="12" cy="13" r="3.6" stroke={PMO.primary} strokeWidth="2"/>
              </svg>
            </div>
          </button>

          {/* No gallery note */}
          <div style={{
            fontSize: 11, color: PMO.textMute, fontStyle: 'italic',
            textAlign: 'center', marginTop: 2,
          }}>
            Tidak bisa memilih dari galeri
          </div>

          {/* Cancel */}
          <button style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontSize: 14, color: PMO.textMute, fontWeight: 600,
            padding: 6, fontFamily: PMO.fontBody, marginTop: 2,
          }}>
            Batalkan
          </button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { CameraScreen });
