// AI Chat — Welcome / Empty state (refined v2)

function QuestionCard({ icon, question }) {
  const [hover, setHover] = React.useState(false);
  return (
    <div
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        background: '#fff', borderRadius: 16, padding: 14,
        border: `1px solid ${hover ? PMO.primary : PMO.border}`,
        boxShadow: hover
          ? `0 10px 24px rgba(26,107,90,0.16), 0 2px 6px rgba(26,107,90,0.10)`
          : `0 2px 8px rgba(26,107,90,0.06)`,
        transform: hover ? 'translateY(-2px)' : 'translateY(0)',
        cursor: 'pointer',
        display: 'flex', flexDirection: 'column',
        position: 'relative', overflow: 'hidden',
        minHeight: 96,
        transition: 'all 0.2s',
      }}>
      <div style={{
        width: 28, height: 28, borderRadius: '50%',
        background: `linear-gradient(135deg, ${PMO.primary}, #2A8B73)`,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: `0 4px 10px ${PMO.primary}40`,
      }}>{icon}</div>
      <div style={{
        fontSize: 13, fontWeight: 700, color: PMO.text,
        lineHeight: 1.35, marginTop: 10, paddingRight: 18,
      }}>{question}</div>
      <div style={{
        position: 'absolute', bottom: 10, right: 10,
        width: 22, height: 22, borderRadius: '50%',
        background: hover ? PMO.primary : PMO.tealSoft,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'background 0.2s',
      }}>
        <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
          <path d="M5 12h14m-6-6l6 6-6 6"
            stroke={hover ? '#fff' : PMO.primary}
            strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </div>
    </div>
  );
}

function ChatWelcome() {
  const [dismissed, setDismissed] = React.useState(false);

  const cards = [
    { id: 'pill',  q: 'Efek samping obat TB?',
      icon: (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <rect x="3" y="9" width="18" height="6" rx="3" stroke="#fff" strokeWidth="2" transform="rotate(-30 12 12)"/>
          <path d="M9.5 6.7l4.8 8.4" stroke="#fff" strokeWidth="2"/>
        </svg>
      ) },
    { id: 'food', q: 'Makanan yang boleh?',
      icon: (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M4 8h13v6a5 5 0 01-5 5H9a5 5 0 01-5-5V8z" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/>
          <path d="M17 10h2a2 2 0 010 4h-2" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
          <path d="M7 3v2M10 3v2M13 3v2" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      ) },
    { id: 'clock', q: 'Lupa minum obat?',
      icon: (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="12" r="9" stroke="#fff" strokeWidth="2"/>
          <path d="M12 7v5l3 2" stroke="#fff" strokeWidth="2" strokeLinecap="round"/>
        </svg>
      ) },
    { id: 'drop', q: 'Urine merah normal?',
      icon: (
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M12 3s7 7 7 12a7 7 0 11-14 0c0-5 7-12 7-12z" stroke="#fff" strokeWidth="2" strokeLinejoin="round"/>
        </svg>
      ) },
  ];

  return (
    <div style={{
      height: '100%', background: PMO.bg, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <ChatHeader/>
      {!dismissed && <ChatDisclaimer onDismiss={() => setDismissed(true)}/>}

      <div style={{
        flex: 1, overflowY: 'auto',
        padding: '28px 16px 16px',
        display: 'flex', flexDirection: 'column',
      }}>
        {/* AI avatar */}
        <div style={{
          position: 'relative', width: 120, height: 120,
          margin: '0 auto',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <style>{`@keyframes pmoAvatarPulse { 0%,100% { transform: scale(1); opacity: 0.55 } 50% { transform: scale(1.08); opacity: 0.25 } }`}</style>
          <div style={{
            position: 'absolute', inset: 0, borderRadius: '50%',
            background: `${PMO.primary}26`,
            animation: 'pmoAvatarPulse 3s ease-in-out infinite',
          }}/>
          <div style={{
            width: 96, height: 96, borderRadius: '50%',
            background: `linear-gradient(160deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: `0 16px 32px ${PMO.primary}55, inset 0 2px 0 rgba(255,255,255,0.18)`,
            position: 'relative',
          }}>
            <svg width="48" height="48" viewBox="0 0 24 24" fill="none">
              <rect x="4" y="7" width="16" height="12" rx="4" stroke="#fff" strokeWidth="1.6"/>
              <circle cx="9" cy="13" r="1.5" fill="#fff"/>
              <circle cx="15" cy="13" r="1.5" fill="#fff"/>
              <path d="M12 4v3M9 19v2M15 19v2" stroke="#fff" strokeWidth="1.6" strokeLinecap="round"/>
              <circle cx="12" cy="3" r="1.3" fill="#fff"/>
              <path d="M10.5 15.5q1.5 1, 3 0" stroke="#fff" strokeWidth="1.4" strokeLinecap="round" fill="none"/>
            </svg>
            <div style={{
              position: 'absolute', bottom: 4, right: 4,
              width: 18, height: 18, borderRadius: '50%',
              background: '#3ED27E', border: '3px solid #F0F7F5',
              boxShadow: '0 2px 6px rgba(62,210,126,0.45)',
            }}/>
          </div>
        </div>

        <h1 style={{
          margin: '14px 0 0', textAlign: 'center',
          fontFamily: PMO.fontHead, fontSize: 20, fontWeight: 700,
          color: PMO.text, letterSpacing: -0.4,
        }}>Halo! Saya PMO Digital 👋</h1>
        <p style={{
          margin: '6px auto 0', maxWidth: '75%', textAlign: 'center',
          fontSize: 14, color: PMO.textMute, lineHeight: 1.6, fontWeight: 400,
        }}>Siap menjawab pertanyaanmu tentang pengobatan TB kapanpun</p>

        <div style={{
          fontSize: 11, fontWeight: 700, color: PMO.textMute,
          letterSpacing: 1, textTransform: 'uppercase',
          margin: '24px 0 12px 4px',
        }}>Pertanyaan yang sering ditanyakan</div>

        <div style={{
          display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10,
        }}>
          {cards.map(c => (
            <QuestionCard key={c.id} icon={c.icon} question={c.q}/>
          ))}
        </div>

        <div style={{
          textAlign: 'center', marginTop: 14,
          fontSize: 12, color: PMO.textMute, fontStyle: 'italic',
        }}>atau ketik pertanyaanmu sendiri ↓</div>
      </div>

      <ChatInputBar/>
    </div>
  );
}

Object.assign(window, { ChatWelcome, QuestionCard });
