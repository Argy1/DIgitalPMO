// Photo verification — SUCCESS state

function CameraSuccess() {
  // Confetti positions (small colored dots)
  const confetti = [
    { top: 30, left: 40, c: PMO.primary, s: 6 },
    { top: 50, left: 80, c: PMO.amber, s: 5 },
    { top: 90, left: 20, c: PMO.success, s: 7 },
    { top: 110, left: 70, c: PMO.primary, s: 4 },
    { top: 40, right: 50, c: PMO.amber, s: 6 },
    { top: 80, right: 30, c: PMO.success, s: 5 },
    { top: 120, right: 70, c: PMO.primary, s: 7 },
    { top: 20, right: 100, c: PMO.amber, s: 4 },
    { bottom: 30, left: 60, c: PMO.success, s: 6 },
    { bottom: 50, right: 50, c: PMO.amber, s: 5 },
    { top: 60, left: '50%', c: PMO.primary, s: 4 },
  ];

  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <style>{`
        @keyframes pmoCheckBounce { 0%{transform:scale(0)} 60%{transform:scale(1.15)} 100%{transform:scale(1)} }
        @keyframes pmoGlowPulse { 0%,100%{opacity:0.6;transform:scale(1)} 50%{opacity:0.9;transform:scale(1.06)} }
        @keyframes pmoConfetti { 0%{transform:translateY(0) scale(0)} 30%{transform:translateY(-4px) scale(1)} 100%{transform:translateY(8px) scale(0.6);opacity:0.4} }
      `}</style>

      {/* TOP 40% — soft teal */}
      <div style={{
        height: '40%', background: PMO.tealSoft,
        position: 'relative', overflow: 'hidden',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {/* Confetti */}
        {confetti.map((d, i) => (
          <div key={i} style={{
            position: 'absolute',
            top: d.top, bottom: d.bottom, left: d.left, right: d.right,
            width: d.s, height: d.s, borderRadius: '50%',
            background: d.c, opacity: 0.6,
            animation: `pmoConfetti 2.4s ease-out ${i * 0.15}s infinite`,
          }} />
        ))}

        {/* Outer glow ring */}
        <div style={{
          position: 'absolute',
          width: 160, height: 160, borderRadius: '50%',
          background: `radial-gradient(circle, ${PMO.primary}33 0%, transparent 70%)`,
          animation: 'pmoGlowPulse 2.2s ease-in-out infinite',
        }} />
        <div style={{
          position: 'absolute',
          width: 120, height: 120, borderRadius: '50%',
          background: `${PMO.primary}33`,
        }} />
        {/* Main check circle */}
        <div style={{
          width: 96, height: 96, borderRadius: '50%',
          background: `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 16px 40px ${PMO.primary}66, inset 0 2px 0 rgba(255,255,255,0.2)`,
          position: 'relative', zIndex: 2,
        }}>
          <svg width="44" height="44" viewBox="0 0 24 24" fill="none">
            <path d="M4 12.5l5 5 11-11" stroke="#fff" strokeWidth="3.6" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      </div>

      {/* CONTENT 60% */}
      <div style={{
        flex: 1, padding: '20px 20px 30px', boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* Title + subtitle */}
        <div style={{ textAlign: 'center' }}>
          <h1 style={{
            margin: 0, fontFamily: PMO.fontHead, fontSize: 22, fontWeight: 700,
            color: PMO.text, letterSpacing: -0.5,
          }}>Obat Terverifikasi! ✅</h1>
          <p style={{
            margin: '4px 0 0', fontSize: 14, color: PMO.textMute,
            fontFamily: PMO.fontBody,
          }}>AI berhasil mendeteksi obatmu</p>
        </div>

        {/* Streak celebration card */}
        <div style={{
          marginTop: 16, background: `linear-gradient(135deg, ${PMO.primary} 0%, #15594B 100%)`,
          borderRadius: 20, padding: 16,
          display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: `0 8px 20px ${PMO.primary}44, inset 0 1px 0 rgba(255,255,255,0.12)`,
          position: 'relative', overflow: 'hidden',
        }}>
          <div style={{ position:'absolute', top: -20, right: -10, width: 100, height: 100, borderRadius: '50%', background: 'rgba(255,255,255,0.06)' }} />
          {/* Flame */}
          <div style={{
            width: 48, height: 48, borderRadius: 14,
            background: 'rgba(245,166,35,0.18)',
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            border: '1px solid rgba(245,166,35,0.3)',
          }}>
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none">
              <path d="M12 2s4 4 4 9a4 4 0 11-8 0c0-2 1-3 1-3s-2 2-2 5a5 5 0 0010 0c0-6-5-11-5-11z" fill="#FFB547"/>
            </svg>
          </div>
          <div style={{ flex: 1, minWidth: 0, position: 'relative' }}>
            <div style={{ fontSize: 12, color: 'rgba(255,255,255,0.7)', fontWeight: 600 }}>
              Streak Kamu
            </div>
            <div style={{
              fontSize: 32, fontWeight: 800, color: '#fff',
              fontFamily: PMO.fontHead, letterSpacing: -1, lineHeight: 1.05, marginTop: 2,
            }}>46 hari</div>
          </div>
          <div style={{ fontSize: 36, lineHeight: 1, position: 'relative' }}>🔥</div>
        </div>

        {/* Education card */}
        <div style={{
          marginTop: 12, background: '#fff', borderRadius: 16,
          padding: 14, border: `1px solid ${PMO.border}`,
          boxShadow: PMO.shadowCard,
          borderLeft: `4px solid ${PMO.amber}`,
          position: 'relative',
        }}>
          <div style={{
            fontSize: 11, fontWeight: 700, color: '#A66A00',
            letterSpacing: 0.4, textTransform: 'uppercase',
          }}>💡 Tahukah kamu?</div>
          <div style={{
            fontSize: 13, fontWeight: 700, color: PMO.text,
            lineHeight: 1.4, marginTop: 4,
          }}>Urine kemerahan setelah minum Rifampicin itu NORMAL</div>
          <a href="#" style={{
            display: 'inline-block', marginTop: 6,
            fontSize: 12, color: PMO.primary, fontWeight: 700,
            textDecoration: 'none',
          }}>Baca Selengkapnya →</a>
        </div>

        <div style={{ flex: 1, minHeight: 12 }} />

        {/* Buttons */}
        <button style={{
          width: '100%', height: 52, borderRadius: 14,
          background: '#fff', color: PMO.primary,
          border: `1.5px solid ${PMO.primary}`,
          fontSize: 15, fontWeight: 700, fontFamily: PMO.fontHead, letterSpacing: -0.2,
          cursor: 'pointer', marginBottom: 10,
        }}>Ada Efek Samping?</button>
        <button style={{
          width: '100%', height: 56, borderRadius: 14,
          background: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
          color: '#fff', border: 'none',
          fontSize: 16, fontWeight: 700, fontFamily: PMO.fontHead, letterSpacing: -0.2,
          cursor: 'pointer',
          boxShadow: [
            '0 6px 16px rgba(26,107,90,0.32)',
            '0 1px 0 rgba(255,255,255,0.18) inset',
            '0 -2px 0 rgba(0,0,0,0.10) inset',
          ].join(', '),
        }}>Kembali ke Beranda</button>
      </div>
    </div>
  );
}

Object.assign(window, { CameraSuccess });
