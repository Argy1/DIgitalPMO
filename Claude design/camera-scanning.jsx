// Medication Photo — SCANNING / AI verifying state

function CameraScanning() {
  const [dots, setDots] = React.useState('');
  React.useEffect(() => {
    let i = 0;
    const t = setInterval(() => { i = (i + 1) % 4; setDots('●'.repeat(i)); }, 400);
    return () => clearInterval(t);
  }, []);

  return (
    <div style={{
      height: '100%', background: '#000', position: 'relative',
      fontFamily: PMO.fontBody, color: '#fff', overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <style>{`
        @keyframes pmoScan { 0%{top:0;opacity:0} 8%{opacity:1} 92%{opacity:1} 100%{top:100%;opacity:0} }
        @keyframes pmoScan2 { 0%{top:100%;opacity:0} 8%{opacity:1} 92%{opacity:1} 100%{top:0;opacity:0} }
        @keyframes pmoPulse { 0%,100%{transform:scale(1);opacity:1} 50%{transform:scale(1.6);opacity:0} }
        @keyframes pmoCornerGlow { 0%,100%{filter:drop-shadow(0 0 4px ${PMO.primary}88);opacity:0.7} 50%{filter:drop-shadow(0 0 14px ${PMO.primary});opacity:1} }
        @keyframes pmoSpin { to { transform: rotate(360deg); } }
        @keyframes pmoTextPulse { 0%,100%{opacity:0.7} 50%{opacity:1} }
        @keyframes pmoRingDash { to { stroke-dashoffset: -628; } }
      `}</style>

      {/* TOP BAR */}
      <div style={{
        height: 56, paddingTop: 50,
        background: '#000', position: 'relative', zIndex: 5,
        padding: '50px 16px 0', display: 'flex', alignItems: 'center',
        boxSizing: 'content-box',
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
        }}>Memverifikasi Foto</div>
      </div>

      {/* CAMERA PREVIEW — frozen photo */}
      <div style={{
        flex: 1, position: 'relative', overflow: 'hidden', minHeight: 340,
        background: 'radial-gradient(circle at 50% 40%, #1f2725 0%, #0a0e0d 90%)',
      }}>
        {/* Simulated "captured photo" — abstract blurred pill cluster */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 240, height: 170, opacity: 0.55,
          filter: 'blur(0.5px)',
        }}>
          <div style={{ position:'absolute', top: 40, left: 30, width: 60, height: 30, borderRadius: 14, background: 'linear-gradient(135deg, #E74C3C, #C0392B)', transform: 'rotate(-12deg)', boxShadow: '0 6px 14px rgba(231,76,60,0.45)' }} />
          <div style={{ position:'absolute', top: 30, left: 110, width: 56, height: 28, borderRadius: 14, background: 'linear-gradient(135deg, #2E86DE, #2167B3)', transform: 'rotate(8deg)', boxShadow: '0 6px 14px rgba(46,134,222,0.45)' }} />
          <div style={{ position:'absolute', top: 90, left: 50, width: 60, height: 30, borderRadius: 14, background: 'linear-gradient(135deg, #F5A623, #C77F08)', transform: 'rotate(18deg)', boxShadow: '0 6px 14px rgba(245,166,35,0.5)' }} />
          <div style={{ position:'absolute', top: 100, left: 130, width: 58, height: 28, borderRadius: 14, background: 'linear-gradient(135deg, #8B5CF6, #6D3FCE)', transform: 'rotate(-6deg)', boxShadow: '0 6px 14px rgba(139,92,246,0.45)' }} />
        </div>

        {/* Dark vignette */}
        <div style={{
          position: 'absolute', inset: 0,
          background: 'radial-gradient(ellipse at center, transparent 30%, rgba(0,0,0,0.55) 75%, rgba(0,0,0,0.85) 100%)',
          pointerEvents: 'none',
        }} />
        {/* Subtle teal tint scan glow */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 360, height: 280, borderRadius: '50%',
          background: `radial-gradient(circle, ${PMO.primary}33 0%, transparent 70%)`,
          pointerEvents: 'none',
        }} />

        {/* Scan guide — pulsing corners */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%',
          transform: 'translate(-50%, -50%)',
          width: 280, height: 200,
        }}>
          {[
            { top: 0, left: 0 },
            { top: 0, right: 0 },
            { bottom: 0, left: 0 },
            { bottom: 0, right: 0 },
          ].map((c, i) => (
            <div key={i} style={{
              position: 'absolute',
              top: c.top, left: c.left, right: c.right, bottom: c.bottom,
              width: 24, height: 24,
              borderTop: c.top !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderBottom: c.bottom !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderLeft: c.left !== undefined ? `3px solid ${PMO.primary}` : 'none',
              borderRight: c.right !== undefined ? `3px solid ${PMO.primary}` : 'none',
              animation: `pmoCornerGlow 1.4s ease-in-out infinite ${i * 0.15}s`,
            }} />
          ))}

          {/* Multiple scan lines for intense effect */}
          <div style={{
            position: 'absolute', left: 0, right: 0, height: 2,
            background: `linear-gradient(90deg, transparent 0%, ${PMO.primary} 50%, transparent 100%)`,
            filter: `drop-shadow(0 0 10px ${PMO.primary})`,
            animation: 'pmoScan 1.2s linear infinite',
          }} />
          <div style={{
            position: 'absolute', left: 0, right: 0, height: 2,
            background: `linear-gradient(90deg, transparent 0%, ${PMO.primary}aa 50%, transparent 100%)`,
            filter: `drop-shadow(0 0 8px ${PMO.primary})`,
            animation: 'pmoScan2 1.2s linear infinite',
          }} />
          <div style={{
            position: 'absolute', left: 0, right: 0, height: 1,
            background: `linear-gradient(90deg, transparent 0%, ${PMO.primary}66 50%, transparent 100%)`,
            animation: 'pmoScan 1.8s linear infinite 0.4s',
          }} />
        </div>
      </div>

      {/* AI STATUS BAR */}
      <div style={{
        background: '#1A1A1A',
        padding: '12px 20px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        borderTop: '1px solid rgba(255,255,255,0.04)',
      }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{
            fontSize: 14, fontWeight: 700, color: PMO.primary,
            fontFamily: PMO.fontBody, letterSpacing: 1, minWidth: 30,
            textShadow: `0 0 8px ${PMO.primary}`, display: 'inline-block',
          }}>{dots || '●'}</span>
          <span style={{
            fontSize: 14, fontWeight: 600, color: '#9ECFC4',
            fontFamily: PMO.fontBody, letterSpacing: -0.1,
            animation: 'pmoTextPulse 1.4s ease-in-out infinite',
          }}>
            AI sedang memverifikasi foto...
          </span>
        </div>
        {/* Spinner */}
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none"
          style={{ animation: 'pmoSpin 0.7s linear infinite' }}>
          <circle cx="12" cy="12" r="10" stroke={PMO.primary} strokeWidth="3" strokeOpacity="0.25"/>
          <path d="M22 12a10 10 0 00-10-10" stroke={PMO.primary} strokeWidth="3" strokeLinecap="round"/>
        </svg>
      </div>

      {/* BOTTOM SHEET */}
      <div style={{
        background: '#fff', position: 'relative',
        borderTopLeftRadius: 28, borderTopRightRadius: 28,
        padding: '8px 20px 30px',
        marginTop: -2, zIndex: 2,
      }}>
        <div style={{
          width: 36, height: 4, borderRadius: 100,
          background: '#D4DAD8', margin: '0 auto 14px',
        }} />

        <div style={{
          fontSize: 10, fontWeight: 700, color: PMO.textMute,
          letterSpacing: 1.2, textTransform: 'uppercase', marginBottom: 10,
        }}>Obat yang sedang dicek</div>

        {/* Pills row */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8 }}>
          {Object.keys(PMO_MEDS).map(k => {
            const m = PMO_MEDS[k];
            return (
              <div key={k} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                <div style={{
                  width: 32, height: 32, borderRadius: '50%',
                  background: `radial-gradient(circle at 30% 25%, ${m.color}ff 0%, ${m.color}cc 100%)`,
                  color: '#fff',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontWeight: 800, fontSize: 14, fontFamily: PMO.fontHead, letterSpacing: -0.4,
                  boxShadow: `0 4px 8px ${m.color}55, inset 0 1px 0 rgba(255,255,255,0.25)`,
                }}>{m.short}</div>
                <div style={{ fontSize: 11, color: PMO.textMute, fontWeight: 600, letterSpacing: -0.1 }}>{m.name}</div>
              </div>
            );
          })}
        </div>

        <div style={{ height: 1, background: PMO.border, margin: '12px 0 10px' }} />

        {/* COMPACT PROGRESS — replaces tips */}
        <div style={{
          display: 'flex', alignItems: 'center', gap: 14,
          marginBottom: 12,
        }}>
          <div style={{ position: 'relative', width: 56, height: 56, flexShrink: 0 }}>
            <svg width="56" height="56" viewBox="0 0 100 100" style={{ transform: 'rotate(-90deg)' }}>
              <circle cx="50" cy="50" r="42" stroke={PMO.border} strokeWidth="8" fill="none"/>
              <circle cx="50" cy="50" r="42" stroke={PMO.primary} strokeWidth="8" fill="none"
                strokeLinecap="round" strokeDasharray="120 628"
                style={{ animation: 'pmoSpin 1.2s linear infinite', transformOrigin: '50% 50%' }}/>
            </svg>
            <div style={{
              position: 'absolute', inset: 0, display: 'flex',
              alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
                <path d="M12 2l1.8 4.4L18 8l-4.2 1.6L12 14l-1.8-4.4L6 8l4.2-1.6L12 2z"
                  fill={PMO.primary}/>
              </svg>
            </div>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{
              fontSize: 14, fontWeight: 700,
              color: PMO.primary, fontFamily: PMO.fontHead, letterSpacing: -0.2,
            }}>Menganalisis...</div>
            <div style={{
              marginTop: 2, fontSize: 12, color: PMO.textMute, fontWeight: 500,
            }}>Biasanya kurang dari 3 detik</div>
          </div>
        </div>

        {/* Capture button — DISABLED */}
        <div style={{
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
        }}>
          <div style={{
            width: 72, height: 72, borderRadius: '50%',
            background: 'transparent',
            border: `3px solid #C8D6D1`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'not-allowed', padding: 0,
            opacity: 0.6,
          }}>
            <div style={{
              width: 58, height: 58, borderRadius: '50%',
              background: '#E8EFEC',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none">
                <path d="M3 8a2 2 0 012-2h2.2l1.4-2h6.8l1.4 2H19a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"
                  stroke="#9AAFA8" strokeWidth="2" strokeLinejoin="round"/>
                <circle cx="12" cy="13" r="3.6" stroke="#9AAFA8" strokeWidth="2"/>
              </svg>
            </div>
          </div>

          <button style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontSize: 14, color: PMO.textMute, fontWeight: 600,
            padding: 4, fontFamily: PMO.fontBody,
          }}>Batalkan</button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { CameraScanning });
