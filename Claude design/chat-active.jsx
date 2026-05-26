// AI Chat — Active conversation (refined)

// ─── Bubble components ──────────────────────────────────────
// Auto-emoji-large detection: any emoji-only line in text content
// gets a wrapper span. We just apply a CSS rule on .pmo-large-emoji.
const emojiStyles = `
  .pmo-bubble strong { font-weight: 700; }
  .pmo-bubble a { color: ${PMO.primary}; text-decoration: underline; font-weight: 600; }
  .pmo-bubble .pmo-emoji { font-size: 18px; line-height: 1; vertical-align: -2px; }
`;

function AIMessage({ children, time, showAvatar = true, accent = PMO.primary, bg = '#fff' }) {
  return (
    <div style={{
      display: 'flex', gap: 8, alignItems: 'flex-end',
      marginTop: showAvatar ? 16 : 4,
    }}>
      {showAvatar ? <ChatAvatar/> : <div style={{ width: 32, flexShrink: 0 }}/>}
      <div style={{ flex: 1, minWidth: 0, maxWidth: '85%' }}>
        <div className="pmo-bubble" style={{
          background: bg,
          borderRadius: '16px 16px 16px 4px',
          padding: '12px 14px',
          border: `1px solid ${PMO.border}`,
          borderLeft: `3px solid ${accent}`,
          boxShadow: '0 2px 8px rgba(26,107,90,0.08)',
          fontSize: 14, color: PMO.text, lineHeight: 1.55, fontWeight: 400,
          whiteSpace: 'pre-line',
        }}>{children}</div>
        {time && (
          <div style={{
            fontSize: 11, color: PMO.textMute, fontWeight: 500, fontStyle: 'italic',
            marginTop: 3, marginLeft: 4,
          }}>{time}</div>
        )}
      </div>
    </div>
  );
}

function UserMessage({ children, time, group = false }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'flex-end',
      marginTop: group ? 4 : 16,
    }}>
      <div style={{ maxWidth: '75%', display: 'flex', flexDirection: 'column', alignItems: 'flex-end' }}>
        <div className="pmo-bubble" style={{
          background: `linear-gradient(135deg, #1F7C68 0%, ${PMO.primary} 60%, ${PMO.primaryDeep} 100%)`,
          borderRadius: '16px 16px 4px 16px',
          padding: '12px 14px',
          fontSize: 14, color: '#fff', lineHeight: 1.55, fontWeight: 500,
          boxShadow: `0 6px 16px ${PMO.primary}44, inset 0 1px 0 rgba(255,255,255,0.12)`,
        }}>{children}</div>
        {time && (
          <div style={{
            fontSize: 11, color: PMO.textMute, fontWeight: 500, fontStyle: 'italic',
            marginTop: 3, marginRight: 4,
          }}>{time}</div>
        )}
      </div>
    </div>
  );
}

function TypingIndicator() {
  return (
    <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', marginTop: 16 }}>
      <ChatAvatar/>
      <div style={{
        background: '#fff',
        borderRadius: '16px 16px 16px 4px',
        padding: '14px 16px',
        border: `1px solid ${PMO.border}`,
        borderLeft: `3px solid ${PMO.primary}`,
        boxShadow: '0 2px 8px rgba(26,107,90,0.08)',
        display: 'flex', alignItems: 'center', gap: 6,
      }}>
        <style>{`
          @keyframes pmoTypeBounce {
            0%, 60%, 100% { transform: translateY(0); opacity: 0.4; }
            30% { transform: translateY(-5px); opacity: 1; }
          }
        `}</style>
        {[0, 1, 2].map(i => (
          <div key={i} style={{
            width: 8, height: 8, borderRadius: '50%',
            background: PMO.primary, opacity: 0.7,
            animation: `pmoTypeBounce 1.2s ease-in-out ${i * 0.15}s infinite`,
          }}/>
        ))}
      </div>
    </div>
  );
}

function ChatTimestamp({ children }) {
  return (
    <div style={{
      display: 'flex', justifyContent: 'center', margin: '8px 0 4px',
    }}>
      <div style={{
        background: 'rgba(26,46,42,0.06)',
        padding: '4px 12px', borderRadius: 100,
        fontSize: 11, color: PMO.textMute, fontWeight: 600,
      }}>{children}</div>
    </div>
  );
}

// ─── Quick reply chips — with fade gradient + selection ────
function QuickReplies({ items, selectedIndex = null, onSelect }) {
  const [sel, setSel] = React.useState(selectedIndex);
  const pick = (i) => { setSel(i); onSelect && onSelect(i); };
  return (
    <div style={{
      position: 'relative', padding: '10px 0 0',
    }}>
      {/* Right edge fade gradient */}
      <div style={{
        position: 'absolute', right: 0, top: 10, bottom: 0, width: 40,
        background: `linear-gradient(90deg, transparent 0%, ${PMO.bg} 80%)`,
        pointerEvents: 'none', zIndex: 2,
      }}/>
      <style>{`.pmoQR::-webkit-scrollbar{display:none}`}</style>
      <div className="pmoQR" style={{
        display: 'flex', gap: 8, padding: '0 16px 4px',
        overflowX: 'auto', scrollbarWidth: 'none',
        WebkitOverflowScrolling: 'touch',
      }}>
        {items.map((label, i) => {
          const selected = i === sel;
          return (
            <button key={i} onClick={() => pick(i)} style={{
              height: 34, padding: '0 14px', borderRadius: 17,
              background: selected
                ? `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`
                : '#fff',
              border: `1.5px solid ${PMO.primary}`,
              color: selected ? '#fff' : PMO.primary,
              fontSize: 13, fontWeight: 700, fontFamily: PMO.fontBody,
              cursor: 'pointer', whiteSpace: 'nowrap', flexShrink: 0,
              display: 'flex', alignItems: 'center', gap: 4,
              boxShadow: selected
                ? `0 4px 10px ${PMO.primary}55, inset 0 1px 0 rgba(255,255,255,0.18)`
                : `0 2px 6px ${PMO.primary}1a`,
              letterSpacing: -0.1,
              transition: 'all 0.2s',
            }}>{label}</button>
          );
        })}
      </div>
    </div>
  );
}

// ─── Main screen ────────────────────────────────────────────
function ChatActive() {
  const [dismissed, setDismissed] = React.useState(false);

  return (
    <div style={{
      height: '100%', background: PMO.bg, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
      display: 'flex', flexDirection: 'column',
    }}>
      <style>{emojiStyles}</style>
      <ChatHeader/>
      {!dismissed && <ChatDisclaimer onDismiss={() => setDismissed(true)}/>}

      {/* Messages */}
      <div style={{
        flex: 1, overflowY: 'auto',
        padding: '4px 16px 12px',
      }}>
        <ChatTimestamp>Hari ini, 09:30</ChatTimestamp>

        {/* AI group 1 — single, show time */}
        <AIMessage time="09:30">
          Halo Budi! <span className="pmo-emoji">👋</span> Kamu sudah minum obat pagi ini. Keren! <span className="pmo-emoji">💪</span>
          {'\n'}Ada yang ingin kamu tanyakan?
        </AIMessage>

        {/* User single — show time */}
        <UserMessage time="09:31">
          Boleh minum kopi setelah minum obat?
        </UserMessage>

        <TypingIndicator/>

        {/* AI group 2 — 2 consecutive messages, only last shows time */}
        <AIMessage>
          Boleh minum kopi <span className="pmo-emoji">☕</span>, tapi beri jarak minimal 1 jam dari waktu minum obat ya Budi.
          {'\n\n'}Kafein bisa sedikit mengganggu penyerapan obat TB. <span className="pmo-emoji">✅</span>
          {'\n\n'}<a href="#">Pelajari interaksi obat lainnya →</a>
        </AIMessage>

        <AIMessage showAvatar={false} time="09:31">
          Ada efek samping yang kamu rasakan hari ini? <span className="pmo-emoji">🤔</span>
        </AIMessage>
      </div>

      <QuickReplies
        selectedIndex={0}
        items={[
          'Tidak ada efek samping',
          'Mual ringan',
          'Urine merah',
          'Nyeri sendi',
          'Tanya lain...',
        ]}
      />

      <ChatInputBar/>
    </div>
  );
}

Object.assign(window, { ChatActive, AIMessage, UserMessage, TypingIndicator, ChatTimestamp, QuickReplies, emojiStyles });
