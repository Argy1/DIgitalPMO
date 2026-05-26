// AI Chat — 3 specialized response screens

// Shared red-alert banner above messages
function EmergencyBanner() {
  return (
    <div style={{
      background: '#FCEBEB',
      padding: '10px 16px',
      display: 'flex', alignItems: 'center', gap: 10,
      borderBottom: '1px solid #E74C3C44',
    }}>
      <span style={{ fontSize: 16 }}>🚨</span>
      <div style={{
        flex: 1, fontSize: 13, color: '#A32D2D', fontWeight: 700, lineHeight: 1.35,
      }}>
        Gejala yang kamu laporkan perlu perhatian segera!
      </div>
    </div>
  );
}

// Variant of AIMessage with custom accent color
function AlertAIMessage({ children, time, accent = PMO.primary, bg = '#fff' }) {
  return (
    <div style={{
      display: 'flex', gap: 8, alignItems: 'flex-end',
      marginTop: 16,
    }}>
      <ChatAvatar/>
      <div style={{ flex: 1, minWidth: 0, maxWidth: '88%' }}>
        <div style={{
          background: bg,
          borderRadius: '16px 16px 16px 4px',
          padding: '12px 14px',
          border: `1px solid ${PMO.border}`,
          borderLeft: `4px solid ${accent}`,
          boxShadow: '0 2px 8px rgba(26,46,42,0.05)',
          fontSize: 14, color: PMO.text, lineHeight: 1.5, fontWeight: 400,
          whiteSpace: 'pre-line',
        }}>{children}</div>
        {time && (
          <div style={{
            fontSize: 11, color: PMO.textMute, fontWeight: 500,
            marginTop: 4, marginLeft: 4,
          }}>{time}</div>
        )}
      </div>
    </div>
  );
}

// Emergency action card (cari faskes)
function EmergencyActionCard() {
  return (
    <div style={{
      marginTop: 10, marginLeft: 40,
      background: '#fff',
      border: `1.5px solid ${PMO.danger}`,
      borderRadius: 16, padding: 14,
      maxWidth: '88%',
      boxShadow: `0 4px 14px ${PMO.danger}22`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
        <div style={{
          width: 36, height: 36, borderRadius: 10,
          background: '#FBE5E2',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 18,
        }}>🏥</div>
        <div style={{ flex: 1 }}>
          <div style={{
            fontSize: 14, fontWeight: 700, color: PMO.text,
            fontFamily: PMO.fontHead, letterSpacing: -0.2,
          }}>Cari Faskes Terdekat</div>
          <div style={{ fontSize: 12, color: PMO.textMute, marginTop: 2 }}>
            Puskesmas buka 24 jam tersedia
          </div>
        </div>
      </div>
      <button style={{
        width: '100%', height: 44, borderRadius: 12,
        background: `linear-gradient(180deg, ${PMO.primary} 0%, ${PMO.primaryDeep} 100%)`,
        border: 'none', color: '#fff',
        fontSize: 14, fontWeight: 700, fontFamily: PMO.fontHead, letterSpacing: -0.2,
        cursor: 'pointer', marginTop: 10,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
        boxShadow: `0 4px 10px ${PMO.primary}44, inset 0 1px 0 rgba(255,255,255,0.18)`,
      }}>
        Buka Maps
        <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
          <path d="M5 12h14m-6-6l6 6-6 6" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"/>
        </svg>
      </button>
    </div>
  );
}

// Embedded education card (inside an AI bubble)
function EducationInfoCard() {
  return (
    <div style={{
      marginTop: 10,
      background: PMO.tealSoft,
      borderRadius: 12, padding: 12,
      border: `1px solid ${PMO.primary}22`,
    }}>
      <div style={{
        fontSize: 11, fontWeight: 700, color: PMO.primary,
        letterSpacing: 0.5, textTransform: 'uppercase', marginBottom: 6,
      }}>💊 Tentang Rifampicin</div>
      <ul style={{
        margin: 0, padding: 0, listStyle: 'none',
        display: 'flex', flexDirection: 'column', gap: 4,
      }}>
        {[
          ['Warna urine', 'merah/oranye (normal)'],
          ['Diminum', 'saat perut kosong'],
          ['Efek umum', 'mual ringan'],
        ].map(([k, v], i) => (
          <li key={i} style={{
            fontSize: 12, color: PMO.text, lineHeight: 1.4,
            display: 'flex', gap: 6,
          }}>
            <span style={{ color: PMO.primary, fontWeight: 700 }}>•</span>
            <span><span style={{ fontWeight: 600 }}>{k}:</span> {v}</span>
          </li>
        ))}
      </ul>
      <a href="#" style={{
        display: 'inline-block', marginTop: 8,
        fontSize: 12, color: PMO.primary, fontWeight: 700,
        textDecoration: 'none',
      }}>Baca lebih lanjut →</a>
    </div>
  );
}

// Motivational milestone (inside an AI bubble)
function MotivationProgress() {
  return (
    <div style={{
      marginTop: 12,
      background: PMO.amberSoft,
      borderRadius: 12, padding: 12,
      border: `1px solid ${PMO.amber}33`,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <span style={{
          fontSize: 11, fontWeight: 700, color: '#A66A00',
          letterSpacing: 0.4, textTransform: 'uppercase',
        }}>Progress kamu</span>
        <span style={{
          fontSize: 16, fontWeight: 800, color: PMO.primary,
          fontFamily: PMO.fontHead, letterSpacing: -0.4,
        }}>50%</span>
      </div>
      <div style={{ height: 8, borderRadius: 100, background: '#fff', overflow: 'hidden' }}>
        <div style={{
          width: '50%', height: '100%',
          background: `linear-gradient(90deg, ${PMO.primary} 0%, #2A8B73 100%)`,
          borderRadius: 100,
          boxShadow: 'inset 0 1px 0 rgba(255,255,255,0.25)',
        }} />
      </div>
      <div style={{
        marginTop: 6, fontSize: 12, color: '#A66A00', fontWeight: 600,
      }}>90 hari tersisa menuju kesembuhan 🎯</div>
    </div>
  );
}

// ─── SCREEN 1: Emergency Alert ─────────────────────────────
function ChatEmergency() {
  return (
    <div style={{ height: '100%', background: PMO.bg, display: 'flex', flexDirection: 'column', fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden' }}>
      <ChatHeader/>
      <EmergencyBanner/>
      <div style={{ flex: 1, overflowY: 'auto', padding: '4px 16px 12px' }}>
        <ChatTimestamp>Hari ini, 14:22</ChatTimestamp>
        <UserMessage time="14:22">
          Kulitku gatal dan ada ruam merah di seluruh tubuh setelah minum obat 😰
        </UserMessage>
        <AlertAIMessage time="14:22" accent={PMO.danger} bg="#FFF8F7">
          Berdasarkan yang kamu ceritakan, ruam kulit yang parah bisa jadi reaksi alergi terhadap obat TB.
          {'\n\n'}⚠️ <b>Yang perlu kamu lakukan:</b>
          {'\n'}1. Hentikan minum obat sementara
          {'\n'}2. Segera ke fasilitas kesehatan
        </AlertAIMessage>
        <EmergencyActionCard/>
      </div>
      <ChatInputBar/>
    </div>
  );
}

// ─── SCREEN 2: Education ───────────────────────────────────
function ChatEducation() {
  return (
    <div style={{ height: '100%', background: PMO.bg, display: 'flex', flexDirection: 'column', fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden' }}>
      <ChatHeader/>
      <ChatDisclaimer onDismiss={() => {}}/>
      <div style={{ flex: 1, overflowY: 'auto', padding: '4px 16px 12px' }}>
        <ChatTimestamp>Hari ini, 10:14</ChatTimestamp>
        <UserMessage time="10:14">
          Tadi pagi urine ku warnanya kemerahan, ini kenapa ya?
        </UserMessage>
        <AlertAIMessage time="10:14">
          Tenang Budi 😊 itu hal yang normal banget!
          {'\n\n'}Warna kemerahan/oranye pada urine adalah efek samping umum dari <b>Rifampicin</b> — salah satu obat TB yang kamu minum.
          <EducationInfoCard/>
        </AlertAIMessage>
      </div>
      <ChatInputBar/>
    </div>
  );
}

// ─── SCREEN 3: Motivational milestone ──────────────────────
function ChatMotivation() {
  return (
    <div style={{ height: '100%', background: PMO.bg, display: 'flex', flexDirection: 'column', fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden' }}>
      <ChatHeader/>
      <ChatDisclaimer onDismiss={() => {}}/>
      <div style={{ flex: 1, overflowY: 'auto', padding: '4px 16px 12px' }}>
        <ChatTimestamp>Hari ini, 07:02</ChatTimestamp>
        <AlertAIMessage time="07:02" accent={PMO.amber} bg="#FFFCF6">
          🎉 <b>Wow Budi! Kamu baru saja menyelesaikan 50% pengobatan!</b>
          {'\n\n'}Ini pencapaian luar biasa! Hanya 90 hari lagi menuju kebebasan dari TB.
          {'\n\n'}Kamu pasti bisa! 💪
          <MotivationProgress/>
        </AlertAIMessage>
      </div>
      <ChatInputBar/>
    </div>
  );
}

Object.assign(window, { ChatEmergency, ChatEducation, ChatMotivation });
