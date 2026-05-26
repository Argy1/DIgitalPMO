// Onboarding Slide 3 — Progress tracking

function Onb3Top() {
  const today = 30;
  const taken = new Set();
  const missed = 14;
  for (let i = 1; i < today; i++) if (i !== missed) taken.add(i);

  return (
    <>
      <div style={{ position:'absolute', top:-70, right:-50, width:240, height:240, borderRadius:'50%', background:'#2E86DE', opacity:0.06 }} />
      <div style={{ position:'absolute', bottom:-60, left:-40, width:200, height:200, borderRadius:'50%', background:PMO.primary, opacity:0.07 }} />
      <div style={{ position:'absolute', top:130, left:30, width:60, height:60, borderRadius:'50%', background:PMO.amber, opacity:0.10 }} />
      <OBDots id="dotpat3" color="#2E86DE" opacity={0.12}/>

      {/* Main illustration */}
      <div style={{
        position: 'absolute', top: '50%', left: '50%',
        transform: 'translate(-50%, -45%)',
        width: 280, zIndex: 3,
      }}>
        {/* Soft floor shadow */}
        <div style={{
          position: 'absolute', bottom: -28, left: 30, right: 30, height: 28,
          background: 'radial-gradient(ellipse at center, rgba(26,46,42,0.18) 0%, transparent 70%)',
          filter: 'blur(10px)', zIndex: -1,
        }} />

        {/* Calendar card */}
        <div style={{
          background: '#fff', borderRadius: 18, padding: 14,
          boxShadow: '0 22px 40px rgba(26,46,42,0.12), 0 4px 12px rgba(26,46,42,0.06), inset 0 1px 0 rgba(255,255,255,1)',
          border: '1px solid rgba(26,46,42,0.04)',
          position: 'relative',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: PMO.primary, letterSpacing: 0.6, textTransform: 'uppercase', fontFamily: PMO.fontHead }}>
              Juni 2026
            </div>
            <div style={{ display: 'flex', gap: 4 }}>
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: PMO.primary }} />
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: PMO.border }} />
              <div style={{ width: 6, height: 6, borderRadius: '50%', background: PMO.border }} />
            </div>
          </div>
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4,
            fontSize: 9, fontWeight: 700, color: PMO.textMute, textAlign: 'center', marginBottom: 4,
          }}>
            {['M','S','S','R','K','J','S'].map((d, i) => <div key={i}>{d}</div>)}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 4 }}>
            {[...Array(35)].map((_, i) => {
              const day = i + 1;
              const isTaken = taken.has(day);
              const isToday = day === today;
              const isMissed = day === missed;
              const isFuture = day > today;
              return (
                <div key={i} style={{
                  aspectRatio: '1', borderRadius: 7,
                  background: isTaken ? PMO.primary :
                              isMissed ? '#FBE5E2' :
                              isToday ? PMO.amberSoft : '#F0F4F7',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 9, fontWeight: 700,
                  color: isTaken ? '#fff' :
                         isMissed ? '#A1281C' :
                         isToday ? '#A66A00' : '#B5C5C0',
                  fontFamily: PMO.fontHead,
                  border: isToday ? `1.5px solid ${PMO.amber}` : 'none',
                  boxShadow: isTaken ? `0 1px 2px ${PMO.primary}55` : 'none',
                }}>
                  {isTaken ? (
                    <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
                      <path d="M4 12.5l5 5 11-11" stroke="#fff" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                  ) : day}
                </div>
              );
            })}
          </div>

          {/* Trophy */}
          <div style={{
            position: 'absolute', top: -16, right: -16,
            width: 44, height: 44, borderRadius: '50%',
            background: `linear-gradient(160deg, #FFD668 0%, #F5A623 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 14px 24px rgba(245,166,35,0.45), inset 0 1px 0 rgba(255,255,255,0.4)',
            border: '3px solid #fff',
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M7 4h10v2c0 3-2 5-5 5s-5-2-5-5V4z" fill="#fff"/>
              <path d="M7 4H4v3a3 3 0 003 3M17 4h3v3a3 3 0 01-3 3" stroke="#fff" strokeWidth="1.8" strokeLinecap="round"/>
              <path d="M9 14h6l-1 4h-4l-1-4zM7 20h10" stroke="#fff" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>

        {/* Progress card */}
        <div style={{
          marginTop: 12, background: '#fff', borderRadius: 16, padding: '12px 14px',
          boxShadow: '0 14px 28px rgba(26,46,42,0.08), 0 2px 6px rgba(26,46,42,0.04)',
          border: '1px solid rgba(26,46,42,0.04)',
        }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 8 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: PMO.textMute, letterSpacing: 0.4, textTransform: 'uppercase' }}>
              Progress
            </div>
            <div>
              <span style={{ fontSize: 18, fontWeight: 800, color: PMO.primary, fontFamily: PMO.fontHead, letterSpacing: -0.5 }}>67%</span>
              <span style={{ fontSize: 11, color: PMO.textMute, marginLeft: 4, fontWeight: 600 }}>/ 180 hari</span>
            </div>
          </div>
          <div style={{ height: 8, borderRadius: 100, background: 'rgba(26,107,90,0.12)', overflow: 'hidden' }}>
            <div style={{
              width: '67%', height: '100%',
              background: `linear-gradient(90deg, ${PMO.primary} 0%, #2A8B73 100%)`,
              borderRadius: 100,
              boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25)',
            }} />
          </div>
        </div>

        {/* 96% chip */}
        <div style={{
          position: 'absolute', bottom: -28, left: -24,
          background: '#fff', borderRadius: 14, padding: '8px 12px',
          display: 'flex', alignItems: 'center', gap: 8,
          boxShadow: '0 16px 28px rgba(26,46,42,0.14), 0 2px 6px rgba(26,46,42,0.06)',
          border: '1px solid rgba(26,46,42,0.04)',
          transform: 'rotate(-4deg)',
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 8,
            background: PMO.tealSoft,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M22 11.1V12a10 10 0 11-5.9-9.1" stroke={PMO.primary} strokeWidth="2.2" strokeLinecap="round"/>
              <path d="M22 4L12 14.01l-3-3" stroke={PMO.primary} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
          <div>
            <div style={{ fontSize: 16, fontWeight: 800, color: PMO.text, lineHeight: 1, fontFamily: PMO.fontHead, letterSpacing: -0.4 }}>96%</div>
            <div style={{ fontSize: 9, color: PMO.textMute, fontWeight: 600, marginTop: 1 }}>Kepatuhan</div>
          </div>
        </div>

        {/* 45 streak chip */}
        <div style={{
          position: 'absolute', bottom: -22, right: -22,
          background: `linear-gradient(160deg, #FFB547 0%, #E8851A 100%)`,
          borderRadius: 14, padding: '8px 12px',
          display: 'flex', alignItems: 'center', gap: 6,
          boxShadow: '0 16px 30px rgba(232,133,26,0.45), 0 2px 6px rgba(232,133,26,0.2), inset 0 1px 0 rgba(255,255,255,0.25)',
          color: '#fff', transform: 'rotate(4deg)',
        }}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M12 2s4 4 4 9a4 4 0 11-8 0c0-2 1-3 1-3s-2 2-2 5a5 5 0 0010 0c0-6-5-11-5-11z" fill="#fff"/>
          </svg>
          <div>
            <div style={{ fontSize: 16, fontWeight: 800, lineHeight: 1, fontFamily: PMO.fontHead, letterSpacing: -0.4 }}>45</div>
            <div style={{ fontSize: 9, fontWeight: 700, opacity: 0.9, marginTop: 1 }}>HARI</div>
          </div>
        </div>
      </div>

      <OBSparkle size={18} style={{ position:'absolute', top: 130, right: 24, opacity: 0.85 }} />
      <OBSparkle size={14} color={PMO.primary} style={{ position:'absolute', bottom: 40, left: 30, opacity: 0.7 }} />
      <OBSparkle size={12} style={{ position:'absolute', top: 110, left: 18, opacity: 0.6 }} />
    </>
  );
}

function Onboarding3() {
  return (
    <OBSlideShell
      topBg="#EBF5FB"
      topChildren={<Onb3Top />}
      progress={2}
      headline={<>Pantau Perjalanan<br/>Sembuhmu</>}
      body="Lihat progress harian, grafik kepatuhan, dan laporan siap cetak untuk kontrol doktermu."
      ctaLabel="Mulai Sekarang"
      ctaEmoji="🌱"
      ctaArrow={false}
      ctaBold={true}
      showSkip={false}
    />
  );
}

Object.assign(window, { Onboarding3 });
