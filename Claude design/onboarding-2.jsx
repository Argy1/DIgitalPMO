// Onboarding Slide 2 — AI Companion

function Onb2Top() {
  return (
    <>
      {/* Decorative bg */}
      <div style={{ position:'absolute', top:-70, left:-50, width:240, height:240, borderRadius:'50%', background:PMO.amber, opacity:0.06 }} />
      <div style={{ position:'absolute', bottom:-50, right:-30, width:200, height:200, borderRadius:'50%', background:PMO.amber, opacity:0.08 }} />
      <div style={{ position:'absolute', top:140, right:20, width:60, height:60, borderRadius:'50%', background:PMO.amber, opacity:0.08 }} />
      <OBDots id="dotpat2" color={PMO.amber} opacity={0.18}/>

      {/* Robot + chat bubbles */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -45%)',
        width: 280, height: 300,
      }}>
        {/* Soft floor glow under robot */}
        <div style={{
          position: 'absolute', bottom: 30, left: 70, right: 70, height: 24,
          background: 'radial-gradient(ellipse at center, rgba(26,107,90,0.22) 0%, transparent 70%)',
          filter: 'blur(10px)',
        }} />
        {/* Halo glow behind head */}
        <div style={{
          position: 'absolute', top: 40, left: 50, right: 50, height: 160,
          background: `radial-gradient(circle, ${PMO.primary}22 0%, transparent 70%)`,
          borderRadius: '50%',
        }} />

        {/* Robot */}
        <div style={{
          position: 'absolute', top: 50, left: '50%', transform: 'translateX(-50%)',
          width: 120, zIndex: 3,
          filter: 'drop-shadow(0 18px 28px rgba(26,46,42,0.22))',
        }}>
          {/* Antenna with glowing tip */}
          <div style={{
            width: 3, height: 18, background: PMO.primary,
            margin: '0 auto', borderRadius: 2, position: 'relative',
          }}>
            <div style={{
              position: 'absolute', top: -6, left: '50%', transform: 'translateX(-50%)',
              width: 12, height: 12, borderRadius: '50%',
              background: `radial-gradient(circle at 35% 30%, #FFD668, ${PMO.amber})`,
              boxShadow: `0 0 14px ${PMO.amber}aa, 0 0 4px ${PMO.amber}`,
            }} />
          </div>
          {/* Head */}
          <div style={{
            width: 120, height: 100, borderRadius: 32,
            background: `linear-gradient(160deg, #fff 0%, #F3FAF7 100%)`,
            border: `4px solid ${PMO.primary}`,
            boxShadow: 'inset 0 -6px 12px rgba(26,107,90,0.05)',
            position: 'relative',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexDirection: 'column', gap: 8,
          }}>
            {/* Eyes */}
            <div style={{ display: 'flex', gap: 18, marginTop: 6 }}>
              {[0,1].map(i => (
                <div key={i} style={{
                  width: 12, height: 12, borderRadius: '50%', background: PMO.dark,
                  position: 'relative',
                }}>
                  <div style={{ position:'absolute', top: 2, left: 2, width: 4, height: 4, borderRadius: '50%', background: '#fff' }} />
                </div>
              ))}
            </div>
            {/* Smile */}
            <svg width="30" height="14" viewBox="0 0 30 14" fill="none">
              <path d="M3 3 Q15 14, 27 3" stroke={PMO.dark} strokeWidth="2.4" strokeLinecap="round" fill="none"/>
            </svg>
            <div style={{ position:'absolute', top: 50, left: 14, width: 12, height: 6, borderRadius: '50%', background: '#F5A62355' }} />
            <div style={{ position:'absolute', top: 50, right: 14, width: 12, height: 6, borderRadius: '50%', background: '#F5A62355' }} />
            {/* Side antennas */}
            <div style={{ position:'absolute', left: -10, top: 28, width: 8, height: 24, borderRadius: 4, background: PMO.primary, boxShadow: 'inset 0 -2px 0 rgba(0,0,0,0.15)' }} />
            <div style={{ position:'absolute', right: -10, top: 28, width: 8, height: 24, borderRadius: 4, background: PMO.primary, boxShadow: 'inset 0 -2px 0 rgba(0,0,0,0.15)' }} />
          </div>

          {/* Body / Jacket */}
          <div style={{
            width: 100, height: 60, margin: '0 auto', marginTop: -4,
            borderRadius: '16px 16px 24px 24px',
            background: `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
            boxShadow: 'inset 0 2px 0 rgba(255,255,255,0.18), inset 0 -4px 8px rgba(0,0,0,0.18)',
            position: 'relative',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            {/* PMO chest badge */}
            <div style={{
              width: 28, height: 28, borderRadius: 10, background: '#fff',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: 'inset 0 0 0 2px rgba(255,255,255,0.4), 0 2px 4px rgba(0,0,0,0.1)',
            }}>
              <svg width="18" height="18" viewBox="0 0 80 80">
                <path d="M37 24 C23 24,13 33,11 47 C9 61,14 71,24 71 C32 71,37 66,37 57 C33 47,39 33,37 24 Z" fill={PMO.primary}/>
                <path d="M43 24 C57 24,67 33,69 47 C71 61,66 71,56 71 C48 71,43 66,43 57 C47 47,41 33,43 24 Z" fill={PMO.primary}/>
                <circle cx="40" cy="14" r="4" fill={PMO.amber}/>
              </svg>
            </div>
            <div style={{ position:'absolute', top: 4, left: 12, right: 12, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.2)' }} />
          </div>
        </div>

        {/* Left chat bubble — user */}
        <div style={{
          position: 'absolute', top: 14, left: -16,
          background: '#fff', borderRadius: '18px 18px 4px 18px',
          padding: '10px 14px',
          boxShadow: '0 14px 28px rgba(26,46,42,0.14), 0 2px 6px rgba(26,46,42,0.06)',
          border: '1px solid rgba(26,46,42,0.05)',
          maxWidth: 170,
          zIndex: 6,
        }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: PMO.textMute, letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 2 }}>
            Budi
          </div>
          <div style={{ fontSize: 13, color: PMO.text, lineHeight: 1.35, fontWeight: 500 }}>
            Urine merah itu normal ga?
          </div>
        </div>

        {/* Right chat bubble — AI */}
        <div style={{
          position: 'absolute', top: 196, right: -22,
          background: `linear-gradient(135deg, ${PMO.primary} 0%, #15594B 100%)`,
          borderRadius: '18px 18px 18px 4px',
          padding: '10px 14px',
          boxShadow: '0 16px 30px rgba(26,107,90,0.34), 0 2px 6px rgba(26,107,90,0.18)',
          maxWidth: 180,
          zIndex: 6,
        }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: 'rgba(255,255,255,0.75)', letterSpacing: 0.4, textTransform: 'uppercase', marginBottom: 2, display:'flex', alignItems:'center', gap: 4 }}>
            PMO AI
            <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#3ED27E', boxShadow: '0 0 6px #3ED27E' }} />
          </div>
          <div style={{ fontSize: 13, color: '#fff', lineHeight: 1.35, fontWeight: 500 }}>
            Normal! Itu efek Rifampicin 😊
          </div>
        </div>

        {/* Sparkles around */}
        <OBSparkle size={20} style={{ position:'absolute', top: 0, right: 30 }} />
        <OBSparkle size={14} style={{ position:'absolute', bottom: 60, left: 0, opacity: 0.85 }} />
        <OBSparkle size={12} color={PMO.primary} style={{ position:'absolute', top: 156, left: 12, opacity: 0.6 }} />

        {/* Tiny floating dots */}
        <div style={{ position:'absolute', top: 80, left: -4, width: 6, height: 6, borderRadius: '50%', background: PMO.primary, opacity: 0.4 }} />
        <div style={{ position:'absolute', bottom: 110, right: 4, width: 8, height: 8, borderRadius: '50%', background: PMO.amber, opacity: 0.6 }} />
      </div>
    </>
  );
}

function Onboarding2() {
  return (
    <OBSlideShell
      topBg="#FEF3E2"
      topChildren={<Onb2Top />}
      progress={1}
      headline={<>PMO Digital AI<br/>Siap 24 Jam</>}
      body="Tanya apapun soal obat, efek samping, atau sekadar butuh semangat — AI kami selalu ada untukmu."
      ctaLabel="Lanjut"
    />
  );
}

Object.assign(window, { Onboarding2 });
