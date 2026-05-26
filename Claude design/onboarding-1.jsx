// Onboarding Slide 1 — Medication reminder

function Onb1Top() {
  // Floating pills: vary Y subtly for parallax depth
  const pills = [
    { kind: 'R', top: 120, left: 6,   rot: -14, size: 52, yShift: 0 },
    { kind: 'H', top: 195, right: 4,  rot: 18,  size: 44, yShift: 12 },
    { kind: 'Z', bottom: 60, left: 24, rot: 10,  size: 48, yShift: 8 },
    { kind: 'E', bottom: 130, right: 14, rot: -22, size: 56, yShift: -6 },
  ];

  return (
    <>
      {/* Decorative bg shapes */}
      <div style={{ position:'absolute', top:-80, right:-60, width:280, height:280, borderRadius:'50%', background:PMO.primary, opacity:0.05 }} />
      <div style={{ position:'absolute', bottom:-60, left:-40, width:200, height:200, borderRadius:'50%', background:PMO.primary, opacity:0.06 }} />
      <div style={{ position:'absolute', top:120, left:30, width:80, height:80, borderRadius:'50%', background:PMO.primary, opacity:0.04 }} />
      <div style={{ position:'absolute', top:60, right:80, width:42, height:42, borderRadius:'50%', background:PMO.amber, opacity:0.12 }} />
      <OBDots id="dotpat1" />

      {/* Phone mockup */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -42%)',
        width: 180, height: 320, zIndex: 3,
      }}>
        {/* Soft ground shadow under phone */}
        <div style={{
          position: 'absolute', bottom: -10, left: 14, right: 14, height: 28,
          background: 'radial-gradient(ellipse at center, rgba(26,46,42,0.22) 0%, transparent 70%)',
          filter: 'blur(8px)', zIndex: -1,
        }} />

        {/* Phone body */}
        <div style={{
          width: '100%', height: '100%', borderRadius: 32,
          background: 'linear-gradient(160deg, #1A2E2A 0%, #0E1F1B 100%)',
          padding: 6, boxSizing: 'border-box', position: 'relative',
          boxShadow: '0 30px 60px rgba(26,46,42,0.32), 0 8px 16px rgba(26,46,42,0.18), inset 0 1px 0 rgba(255,255,255,0.08)',
        }}>
          {/* Screen */}
          <div style={{
            width: '100%', height: '100%', borderRadius: 26,
            background: `linear-gradient(170deg, ${PMO.primary} 0%, #15594B 100%)`,
            position: 'relative', overflow: 'hidden',
            padding: '20px 12px', boxSizing: 'border-box',
          }}>
            <div style={{
              position: 'absolute', top: 8, left: '50%', transform: 'translateX(-50%)',
              width: 60, height: 16, borderRadius: 10, background: '#000',
            }} />
            <div style={{ marginTop: 26, textAlign: 'center', color: 'rgba(255,255,255,0.85)' }}>
              <div style={{ fontSize: 9, letterSpacing: 1, fontWeight: 600, opacity: 0.7 }}>
                JUMAT, 9 JUNI
              </div>
              <div style={{
                fontSize: 42, fontWeight: 700, letterSpacing: -2, marginTop: 4,
                fontFamily: PMO.fontHead,
              }}>07:00</div>
            </div>
            <div style={{ position:'absolute', bottom: 16, left: 12, right: 12, display:'flex', gap: 4, opacity: 0.3 }}>
              {[0,1,2,3].map(i => <div key={i} style={{ flex:1, height: 3, borderRadius: 2, background:'#fff' }} />)}
            </div>
          </div>
        </div>

        {/* Notification card on top of phone */}
        <div style={{
          position: 'absolute', top: 56, left: -22, right: -22,
          background: '#fff', borderRadius: 14, padding: 12,
          boxShadow: '0 16px 32px rgba(26,46,42,0.18), 0 2px 6px rgba(26,46,42,0.08), inset 0 1px 0 rgba(255,255,255,1)',
          display: 'flex', alignItems: 'center', gap: 10,
          border: '1px solid rgba(26,46,42,0.05)',
          zIndex: 4,
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: `linear-gradient(135deg, ${PMO.primary}, #2A8B73)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            boxShadow: `0 4px 10px ${PMO.primary}55`,
          }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
              <path d="M6 8a6 6 0 1112 0c0 7 3 9 3 9H3s3-2 3-9" stroke="#fff" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
              <path d="M10.3 21a1.94 1.94 0 003.4 0" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 9, fontWeight: 700, color: PMO.primary, letterSpacing: 0.6, textTransform: 'uppercase' }}>
              DigitalPMO · sekarang
            </div>
            <div style={{ fontSize: 13, fontWeight: 700, color: PMO.text, marginTop: 2, letterSpacing: -0.2, fontFamily: PMO.fontHead }}>
              Waktunya minum obat! 💊
            </div>
          </div>
        </div>

        {/* Clock chip below phone */}
        <div style={{
          position: 'absolute', bottom: 38, right: -34,
          background: '#fff', borderRadius: 100, padding: '6px 10px',
          display: 'flex', alignItems: 'center', gap: 5,
          boxShadow: '0 10px 20px rgba(26,46,42,0.14), 0 1px 3px rgba(26,46,42,0.06)',
          zIndex: 4,
        }}>
          {PMOIcon.clock(PMO.primary)}
          <span style={{ fontSize: 12, fontWeight: 700, color: PMO.text, fontFamily: PMO.fontHead }}>07:00</span>
        </div>
      </div>

      {/* Floating pills with depth */}
      {pills.map((p, i) => {
        const m = PMO_MEDS[p.kind];
        return (
          <div key={i} style={{
            position: 'absolute',
            top: p.top !== undefined ? p.top + p.yShift : undefined,
            bottom: p.bottom !== undefined ? p.bottom - p.yShift : undefined,
            left: p.left, right: p.right,
            width: p.size, height: p.size, borderRadius: '50%',
            background: `radial-gradient(circle at 30% 25%, ${m.color}ff 0%, ${m.color}dd 60%, ${m.color}99 100%)`,
            color: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontWeight: 800, fontSize: p.size * 0.42, letterSpacing: -0.6,
            fontFamily: PMO.fontHead,
            boxShadow: `
              0 16px 28px ${m.color}55,
              0 4px 8px ${m.color}33,
              inset 0 2px 0 rgba(255,255,255,0.35),
              inset 0 -3px 6px rgba(0,0,0,0.12)
            `,
            transform: `rotate(${p.rot}deg)`,
            zIndex: 1,
          }}>
            {m.short}
            <div style={{
              position: 'absolute', left: 4, right: 4, top: '50%',
              height: 1, background: 'rgba(255,255,255,0.3)',
              transform: 'translateY(-0.5px)',
            }} />
          </div>
        );
      })}

      <OBSparkle size={20} style={{ position: 'absolute', top: 96, right: 38 }} />
      <OBSparkle size={14} color={PMO.primary} style={{ position: 'absolute', bottom: 90, right: 90, opacity: 0.6 }} />
    </>
  );
}

function Onboarding1() {
  return (
    <OBSlideShell
      topBg={PMO.tealSoft}
      topChildren={<Onb1Top />}
      progress={0}
      headline={<>Jangan Sampai<br/>Lupa Minum Obat</>}
      body="DigitalPMO mengingatkan kamu minum obat TB setiap hari, tepat waktu, selama 180 hari penuh."
      ctaLabel="Lanjut"
    />
  );
}

Object.assign(window, { Onboarding1 });
