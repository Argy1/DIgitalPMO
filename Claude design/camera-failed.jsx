// Photo verification — FAILED state

function CameraFailed() {
  // Small "?" particles around the top icon (uncertain feel)
  const particles = [
    { top: 40, left: 50, c: PMO.amber, s: 6 },
    { top: 70, left: 25, c: PMO.danger, s: 5 },
    { top: 100, left: 70, c: PMO.amber, s: 7 },
    { top: 50, right: 50, c: PMO.danger, s: 5 },
    { top: 90, right: 30, c: PMO.amber, s: 6 },
    { bottom: 40, right: 60, c: PMO.amber, s: 5 },
    { bottom: 30, left: 40, c: PMO.danger, s: 6 },
  ];

  const tips = [
    'Pastikan cahaya cukup terang',
    'Letakkan semua obat di permukaan datar',
    'Jarak kamera 15–20 cm dari obat',
    'Hindari bayangan di atas obat',
  ];

  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <style>{`
        @keyframes pmoExclamBounce { 0%{transform:scale(0)} 60%{transform:scale(1.12)} 100%{transform:scale(1)} }
        @keyframes pmoShake { 0%,100%{transform:translateX(0)} 25%{transform:translateX(-3px)} 75%{transform:translateX(3px)} }
        @keyframes pmoGlowPulseAmber { 0%,100%{opacity:0.5;transform:scale(1)} 50%{opacity:0.8;transform:scale(1.06)} }
      `}</style>

      {/* TOP 40% — soft red */}
      <div style={{
        height: '40%', background: '#FCEBEB',
        position: 'relative', overflow: 'hidden',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {particles.map((d, i) => (
          <div key={i} style={{
            position: 'absolute',
            top: d.top, bottom: d.bottom, left: d.left, right: d.right,
            width: d.s, height: d.s, borderRadius: '50%',
            background: d.c, opacity: 0.5,
          }} />
        ))}

        {/* Outer glow */}
        <div style={{
          position: 'absolute',
          width: 160, height: 160, borderRadius: '50%',
          background: `radial-gradient(circle, ${PMO.amber}40 0%, transparent 70%)`,
          animation: 'pmoGlowPulseAmber 2.2s ease-in-out infinite',
        }} />
        <div style={{
          position: 'absolute',
          width: 120, height: 120, borderRadius: '50%',
          background: `${PMO.amber}33`,
        }} />
        {/* Main icon — amber circle with exclamation */}
        <div style={{
          width: 96, height: 96, borderRadius: '50%',
          background: `linear-gradient(160deg, #FFB547 0%, ${PMO.amber} 100%)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 16px 40px ${PMO.amber}66, inset 0 2px 0 rgba(255,255,255,0.25)`,
          position: 'relative', zIndex: 2,
        }}>
          <svg width="44" height="44" viewBox="0 0 24 24" fill="none">
            <path d="M12 5v9" stroke="#fff" strokeWidth="4" strokeLinecap="round"/>
            <circle cx="12" cy="19" r="2.2" fill="#fff"/>
          </svg>
        </div>
      </div>

      {/* CONTENT 60% */}
      <div style={{
        flex: 1, padding: '20px 20px 30px', boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ textAlign: 'center' }}>
          <h1 style={{
            margin: 0, fontFamily: PMO.fontHead, fontSize: 22, fontWeight: 700,
            color: PMO.text, letterSpacing: -0.5,
          }}>Foto Kurang Jelas 📸</h1>
          <p style={{
            margin: '4px 0 0', fontSize: 14, color: PMO.textMute,
            fontFamily: PMO.fontBody,
          }}>AI tidak dapat mendeteksi obat</p>
        </div>

        {/* Tips card */}
        <div style={{
          marginTop: 18, background: '#fff', borderRadius: 16,
          padding: 16, border: `1px solid ${PMO.border}`,
          boxShadow: PMO.shadowCard,
          borderLeft: `4px solid ${PMO.amber}`,
        }}>
          <div style={{
            fontSize: 13, fontWeight: 700, color: PMO.text,
            marginBottom: 12, letterSpacing: -0.1,
          }}>Coba lagi dengan:</div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {tips.map((t, i) => (
              <div key={i} style={{
                display: 'flex', alignItems: 'flex-start', gap: 10,
                fontSize: 13, color: PMO.text, fontWeight: 500, lineHeight: 1.4,
              }}>
                <div style={{
                  width: 22, height: 22, borderRadius: '50%',
                  background: PMO.amberSoft,
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0, marginTop: 1,
                  fontSize: 11, fontWeight: 800, color: '#A66A00',
                  fontFamily: PMO.fontHead,
                }}>{i + 1}</div>
                {t}
              </div>
            ))}
          </div>
        </div>

        <div style={{ flex: 1, minHeight: 16 }} />

        {/* Single CTA */}
        <button style={{
          width: '100%', height: 56, borderRadius: 14,
          background: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
          color: '#fff', border: 'none',
          fontSize: 16, fontWeight: 700, fontFamily: PMO.fontHead, letterSpacing: -0.2,
          cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
          boxShadow: [
            '0 6px 16px rgba(26,107,90,0.32)',
            '0 1px 0 rgba(255,255,255,0.18) inset',
            '0 -2px 0 rgba(0,0,0,0.10) inset',
          ].join(', '),
        }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
            <path d="M3 8a2 2 0 012-2h2.2l1.4-2h6.8l1.4 2H19a2 2 0 012 2v10a2 2 0 01-2 2H5a2 2 0 01-2-2V8z" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/>
            <circle cx="12" cy="13" r="3.6" stroke="#fff" strokeWidth="2"/>
          </svg>
          Coba Foto Lagi
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { CameraFailed });
