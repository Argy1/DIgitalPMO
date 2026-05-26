// DigitalPMO OTP Verification Screen

function OTPScreen() {
  const [digits, setDigits] = React.useState(['', '', '', '', '', '']);
  const [activeIdx, setActiveIdx] = React.useState(0);
  const [seconds, setSeconds] = React.useState(45);
  const [loading, setLoading] = React.useState(false);
  const inputRefs = React.useRef([]);

  // Countdown
  React.useEffect(() => {
    if (seconds <= 0) return;
    const t = setTimeout(() => setSeconds(s => s - 1), 1000);
    return () => clearTimeout(t);
  }, [seconds]);

  // Focus first empty on mount
  React.useEffect(() => {
    inputRefs.current[0]?.focus();
  }, []);

  const handleChange = (i, val) => {
    const cleaned = val.replace(/\D/g, '').slice(-1);
    const next = [...digits];
    next[i] = cleaned;
    setDigits(next);
    if (cleaned && i < 5) {
      inputRefs.current[i + 1]?.focus();
      setActiveIdx(i + 1);
    }
  };

  const handleKey = (i, e) => {
    if (e.key === 'Backspace' && !digits[i] && i > 0) {
      inputRefs.current[i - 1]?.focus();
      setActiveIdx(i - 1);
    }
  };

  const handlePaste = (e) => {
    e.preventDefault();
    const text = (e.clipboardData.getData('text') || '').replace(/\D/g, '').slice(0, 6);
    if (!text) return;
    const next = ['', '', '', '', '', ''];
    for (let j = 0; j < text.length; j++) next[j] = text[j];
    setDigits(next);
    const focusIdx = Math.min(text.length, 5);
    inputRefs.current[focusIdx]?.focus();
    setActiveIdx(focusIdx);
  };

  const allFilled = digits.every(d => d.length === 1);
  const mm = String(Math.floor(seconds / 60)).padStart(2, '0');
  const ss = String(seconds % 60).padStart(2, '0');
  const canResend = seconds === 0;

  const resend = () => {
    setSeconds(45);
    setDigits(['', '', '', '', '', '']);
    inputRefs.current[0]?.focus();
    setActiveIdx(0);
  };

  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
    }}>
      {/* ── HEADER 35% ──────────────────────────────────────── */}
      <div style={{
        height: '35%',
        background: `linear-gradient(165deg, ${PMO.primary} 0%, #15594B 100%)`,
        position: 'relative', overflow: 'hidden',
      }}>
        {/* Organic blob shapes — subtle, 6% opacity */}
        <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.06 }}
          viewBox="0 0 390 280" preserveAspectRatio="xMidYMid slice">
          <path d="M-40,80 C 40,20 140,40 180,100 C 220,170 140,220 60,200 C -20,180 -80,140 -40,80 Z" fill="#fff"/>
          <path d="M310,-20 C 380,10 410,90 380,140 C 350,190 270,170 250,110 C 230,50 240,-50 310,-20 Z" fill="#fff"/>
          <path d="M180,220 C 240,200 320,230 340,280 C 360,330 290,360 220,340 C 150,320 120,240 180,220 Z" fill="#fff"/>
        </svg>
        <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity:0.4 }}>
          <defs>
            <pattern id="otpDots" x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
              <circle cx="2" cy="2" r="1" fill="#fff" opacity="0.18"/>
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#otpDots)"/>
        </svg>

        {/* Top bar: back + logo */}
        <div style={{
          position: 'relative', zIndex: 5,
          padding: '60px 20px 0',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
        }}>
          <button style={{
            width: 40, height: 40, borderRadius: 12,
            background: 'rgba(255,255,255,0.15)',
            border: '1px solid rgba(255,255,255,0.2)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer',
          }}>
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
              <path d="M15 18l-6-6 6-6" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </button>

          {/* Centered logo */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, position: 'relative' }}>
            <svg width="22" height="22" viewBox="0 0 80 80" style={{
              filter: 'drop-shadow(0 0 12px rgba(255,255,255,0.35))',
            }}>
              <path d="M37 24 C23 24,13 33,11 47 C9 61,14 71,24 71 C32 71,37 66,37 57 C33 47,39 33,37 24 Z" fill="#fff"/>
              <path d="M43 24 C57 24,67 33,69 47 C71 61,66 71,56 71 C48 71,43 66,43 57 C47 47,41 33,43 24 Z" fill="#fff"/>
              <rect x="38" y="14" width="4" height="13" rx="2" fill="#fff"/>
              <circle cx="40" cy="10" r="4.2" fill={PMO.amber}/>
            </svg>
            <span style={{ color: '#fff', fontFamily: PMO.fontHead, fontWeight: 700, fontSize: 15, letterSpacing: -0.3 }}>
              DigitalPMO
            </span>
          </div>

          {/* Empty spacer to balance */}
          <div style={{ width: 40 }} />
        </div>

        {/* Page title centered */}
        <div style={{
          position: 'absolute', top: '50%', left: 0, right: 0,
          transform: 'translateY(-32%)', textAlign: 'center', zIndex: 2,
        }}>
          <div style={{
            fontFamily: PMO.fontHead, fontSize: 18, fontWeight: 700,
            color: '#fff', letterSpacing: -0.3,
          }}>
            Verifikasi Nomor HP
          </div>
          <div style={{
            fontSize: 13, color: 'rgba(255,255,255,0.7)', fontWeight: 500,
            marginTop: 4,
          }}>
            Langkah 2 dari 3 · Verifikasi keamanan
          </div>
        </div>

        {/* Wave */}
        <svg style={{
          position: 'absolute', bottom: -1, left: 0, right: 0,
          width: '100%', height: 32, display: 'block', zIndex: 4,
        }} viewBox="0 0 390 32" preserveAspectRatio="none">
          <path d="M0,32 C 65,32 130,0 195,0 C 260,0 325,32 390,32 L 390,32 L 0,32 Z" fill="#fff"/>
        </svg>
      </div>

      {/* ── CONTENT 65% ─────────────────────────────────────── */}
      <div style={{
        height: '65%', background: PMO.card, position: 'relative',
        padding: '20px 24px 34px', boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column',
      }}>

        {/* SMS icon illustration */}
        <div style={{
          margin: '0 auto', position: 'relative',
          width: 76, height: 76,
        }}>
          <div style={{
            width: 76, height: 76, borderRadius: '50%',
            background: `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 16px 32px ${PMO.primary}44, inset 0 2px 0 rgba(255,255,255,0.18)`,
          }}>
            <svg width="34" height="34" viewBox="0 0 24 24" fill="none">
              <path d="M3 6.5A2.5 2.5 0 015.5 4h13A2.5 2.5 0 0121 6.5v8A2.5 2.5 0 0118.5 17H13l-3.6 3.6a1 1 0 01-1.4 0L7 19v-2H5.5A2.5 2.5 0 013 14.5v-8z"
                fill="#fff"/>
              <path d="M7.5 10h9M7.5 13h6"
                stroke={PMO.primary} strokeWidth="1.8" strokeLinecap="round"/>
            </svg>
          </div>
          {/* Checkmark badge */}
          <div style={{
            position: 'absolute', bottom: -2, right: -2,
            width: 28, height: 28, borderRadius: '50%',
            background: PMO.success,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            border: '3px solid #fff',
            boxShadow: `0 4px 10px ${PMO.success}66`,
          }}>
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
              <path d="M4 12.5l5 5 11-11" stroke="#fff" strokeWidth="3.4" strokeLinecap="round" strokeLinejoin="round"/>
            </svg>
          </div>
        </div>

        {/* Title */}
        <h1 style={{
          margin: '18px 0 0', textAlign: 'center',
          fontFamily: PMO.fontHead, fontSize: 20, fontWeight: 700,
          color: PMO.text, letterSpacing: -0.4,
        }}>
          Masukkan Kode OTP
        </h1>

        {/* Subtitle */}
        <p style={{
          margin: '6px 0 0', textAlign: 'center',
          fontSize: 14, color: PMO.textMute, lineHeight: 1.5, fontFamily: PMO.fontBody,
        }}>
          Kode 6 digit dikirim ke<br/>
          <span style={{ color: PMO.primary, fontWeight: 700 }}>+62 812-XXXX-XXXX</span>
        </p>

        {/* OTP boxes */}
        <div style={{
          display: 'flex', justifyContent: 'center', gap: 8,
          marginTop: 24,
        }}>
          {digits.map((d, i) => {
            const filled = d.length === 1;
            const active = i === activeIdx;
            const success = allFilled;
            const borderColor = success ? PMO.success : (active || filled) ? PMO.primary : '#D4ECE6';
            const bgColor = success ? '#EAFBF1' : active ? '#fff' : '#F8FAF9';
            return (
              <input
                key={i}
                ref={el => inputRefs.current[i] = el}
                type="tel" inputMode="numeric" maxLength={1}
                value={d}
                onChange={e => handleChange(i, e.target.value)}
                onKeyDown={e => handleKey(i, e)}
                onPaste={handlePaste}
                onFocus={() => setActiveIdx(i)}
                style={{
                  width: 44, height: 56, borderRadius: 12,
                  background: bgColor,
                  border: `1.5px solid ${borderColor}`,
                  textAlign: 'center',
                  fontSize: 28, fontWeight: 800, fontFamily: PMO.fontHead,
                  color: success ? PMO.success : PMO.text, letterSpacing: -0.5,
                  outline: 'none', boxSizing: 'border-box',
                  boxShadow:
                    success ? `0 0 0 4px ${PMO.success}1f, 0 2px 8px ${PMO.success}33` :
                    active  ? `0 0 0 4px ${PMO.primary}1f, 0 2px 8px ${PMO.primary}22` :
                    'none',
                  transition: 'all 0.2s',
                  caretColor: PMO.primary,
                }}
              />
            );
          })}
        </div>

        {/* Countdown */}
        <div style={{ textAlign: 'center', marginTop: 24 }}>
          {!canResend ? (
            <>
              <div style={{ fontSize: 13, color: PMO.textMute, fontWeight: 500 }}>
                Kirim ulang kode dalam
              </div>
              <div style={{
                fontSize: 22, fontWeight: 800, color: PMO.primary,
                fontFamily: PMO.fontHead, letterSpacing: -0.5,
                marginTop: 4, fontVariantNumeric: 'tabular-nums',
              }}>
                {mm}:{ss}
              </div>
            </>
          ) : (
            <div style={{
              fontSize: 22, fontWeight: 800, color: PMO.textMute,
              fontFamily: PMO.fontHead, letterSpacing: -0.5,
              fontVariantNumeric: 'tabular-nums',
            }}>
              00:00
            </div>
          )}
          <div style={{ marginTop: 8, fontSize: 13, color: PMO.textMute }}>
            Tidak terima kode?{' '}
            <button
              onClick={canResend ? resend : undefined}
              disabled={!canResend}
              style={{
                background: 'transparent', border: 'none', padding: 0,
                fontSize: 13, fontWeight: 700,
                color: canResend ? PMO.primary : '#A6BAB4',
                cursor: canResend ? 'pointer' : 'not-allowed',
                fontFamily: PMO.fontBody,
              }}>
              Kirim Ulang
            </button>
          </div>
        </div>

        {/* Spacer */}
        <div style={{ flex: 1, minHeight: 16 }} />

        {/* CTA */}
        <AuthCTA
          disabled={!allFilled}
          loading={loading}
          loadingLabel="Memverifikasi"
          onClick={() => { setLoading(true); setTimeout(() => setLoading(false), 2400); }}
        >
          Verifikasi
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
            <path d="M4 12.5l5 5 11-11" stroke="#fff" strokeWidth="2.8" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </AuthCTA>

        {/* Change number link */}
        <div style={{ textAlign: 'center', marginTop: 14 }}>
          <a href="#" style={{
            fontSize: 13, color: PMO.primary, fontWeight: 600,
            textDecoration: 'none', padding: 4,
          }}>Ganti nomor HP</a>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { OTPScreen });
