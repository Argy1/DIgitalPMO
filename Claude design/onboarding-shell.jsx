// Onboarding shared shell — chrome + transitions + CTA
// All 3 slides use OBSlideShell so they stay 1:1 consistent.

// ─── Logo + skip header ─────────────────────────────────────
function OBHeader({ showSkip = true }) {
  return (
    <div style={{
      position: 'relative', zIndex: 5,
      padding: '60px 20px 0',
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
        <svg width="20" height="20" viewBox="0 0 80 80">
          <path d="M37 24 C23 24,13 33,11 47 C9 61,14 71,24 71 C32 71,37 66,37 57 C33 47,39 33,37 24 Z" fill={PMO.primary}/>
          <path d="M43 24 C57 24,67 33,69 47 C71 61,66 71,56 71 C48 71,43 66,43 57 C47 47,41 33,43 24 Z" fill={PMO.primary}/>
          <rect x="38" y="14" width="4" height="13" rx="2" fill={PMO.primary}/>
          <circle cx="40" cy="10" r="4.2" fill={PMO.amber}/>
        </svg>
        <span style={{ fontSize: 14, fontWeight: 700, color: PMO.primary, fontFamily: PMO.fontHead, letterSpacing: -0.3 }}>
          DigitalPMO
        </span>
      </div>
      {showSkip && (
        <button style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          fontSize: 14, color: PMO.textMute, fontWeight: 600, padding: 4,
          fontFamily: PMO.fontBody,
        }}>Lewati</button>
      )}
    </div>
  );
}

// ─── Wave transition (32px peak, white curving up) ──────────
function OBWave() {
  return (
    <svg style={{
      position: 'absolute', top: -32, left: 0, right: 0,
      width: '100%', height: 32, display: 'block', zIndex: 4,
      filter: 'drop-shadow(0 -2px 8px rgba(26,46,42,0.05))',
    }} viewBox="0 0 390 32" preserveAspectRatio="none">
      <path
        d="M0,32 C 65,32 130,0 195,0 C 260,0 325,32 390,32 L 390,32 L 0,32 Z"
        fill="#fff"
      />
    </svg>
  );
}

// ─── Progress dots ──────────────────────────────────────────
function OBProgressDots({ active }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'center', alignItems: 'center', gap: 8,
      marginBottom: 24,
    }}>
      {[0, 1, 2].map(i => (
        <div key={i} style={{
          width: i === active ? 32 : 8,
          height: 8, borderRadius: 100,
          background: i === active ? PMO.primary : PMO.border,
          transition: 'all 0.3s',
        }}/>
      ))}
    </div>
  );
}

// ─── CTA Button ─────────────────────────────────────────────
// Right side: 24px white circle with arrow (or omit for last slide)
function OBCTA({ label, emoji, arrow = true, bold = false }) {
  return (
    <button style={{
      width: '100%', height: 58, borderRadius: 14,
      background: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
      border: 'none', color: '#fff',
      fontSize: 17, fontWeight: bold ? 800 : 700,
      fontFamily: PMO.fontBody, letterSpacing: -0.3,
      cursor: 'pointer',
      position: 'relative',
      display: 'flex', alignItems: 'center',
      justifyContent: arrow ? 'space-between' : 'center',
      padding: arrow ? '0 17px 0 24px' : '0 24px',
      gap: 8,
      // Subtle multi-layer shadows: inner top highlight, inner bottom darken, outer drop
      boxShadow: [
        '0 6px 16px rgba(26,107,90,0.32)',
        '0 1px 0 rgba(255,255,255,0.06) inset',
        '0 -2px 0 rgba(0,0,0,0.10) inset',
        '0 1px 0 rgba(255,255,255,0.18) inset',
      ].join(', '),
    }}>
      <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {label}
        {emoji && <span style={{ fontSize: 20 }}>{emoji}</span>}
      </span>
      {arrow && (
        <div style={{
          width: 24, height: 24, borderRadius: '50%', background: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 1px 3px rgba(0,0,0,0.12)',
        }}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
            <path d="M5 12h14m-6-6l6 6-6 6"
              stroke={PMO.primary} strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
        </div>
      )}
    </button>
  );
}

// ─── Sparkle (consistent across slides) ─────────────────────
function OBSparkle({ size = 18, color = '#F5A623', style = {} }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" style={{ width: size, height: size, ...style }}>
      <path d="M12 2l1.6 6.4L20 10l-6.4 1.6L12 18l-1.6-6.4L4 10l6.4-1.6L12 2z" fill={color}/>
    </svg>
  );
}

// ─── Dot pattern texture (consistent across slides) ─────────
function OBDots({ id, color = PMO.primary, opacity = 0.08 }) {
  return (
    <svg style={{ position:'absolute', inset:0, width:'100%', height:'100%', opacity: 0.5 }}>
      <defs>
        <pattern id={id} x="0" y="0" width="22" height="22" patternUnits="userSpaceOnUse">
          <circle cx="2" cy="2" r="1" fill={color} opacity={opacity * 12}/>
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#${id})`}/>
    </svg>
  );
}

// ─── Slide shell — combines header + top illustration + bottom sheet ──
function OBSlideShell({
  topBg, topChildren,
  progress, headline, body,
  ctaLabel, ctaEmoji, ctaArrow = true, ctaBold = false,
  showSkip = true,
}) {
  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
    }}>
      {/* Top section */}
      <div style={{
        height: '55%', background: topBg,
        position: 'relative', overflow: 'hidden',
      }}>
        <OBHeader showSkip={showSkip} />
        {topChildren}
      </div>

      {/* Bottom section */}
      <div style={{
        height: '45%', background: PMO.card,
        position: 'relative',
        padding: '24px 24px 34px',
        boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column',
        zIndex: 3,
      }}>
        <OBWave />
        <OBProgressDots active={progress} />
        <h1 style={{
          margin: 0, fontFamily: PMO.fontHead,
          fontSize: 28, fontWeight: 700,
          color: PMO.text, lineHeight: 1.2, letterSpacing: -0.8,
        }}>
          {headline}
        </h1>
        <p style={{
          margin: '8px auto 0', maxWidth: '85%', width: '85%',
          fontFamily: PMO.fontBody, fontSize: 16,
          color: PMO.textMute, lineHeight: 1.6, fontWeight: 400,
          alignSelf: 'flex-start',
        }}>
          {body}
        </p>
        <div style={{ flex: 1, minHeight: 16 }} />
        <OBCTA label={ctaLabel} emoji={ctaEmoji} arrow={ctaArrow} bold={ctaBold} />
      </div>
    </div>
  );
}

Object.assign(window, {
  OBHeader, OBWave, OBProgressDots, OBCTA, OBSparkle, OBDots, OBSlideShell,
});
