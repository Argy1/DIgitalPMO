// DigitalPMO Login (refined)

function Login() {
  const [phone, setPhone] = React.useState('');
  const [pw, setPw] = React.useState('');
  const [showPw, setShowPw] = React.useState(false);
  const [loading, setLoading] = React.useState(false);
  const [submitted, setSubmitted] = React.useState(false);

  // Demonstrative validation: phone must start with +62 or 08 and be 10-15 digits
  const phoneError = submitted && phone && !/^(\+62|08)\d{8,13}$/.test(phone.replace(/[-\s]/g,''))
    ? 'Nomor HP tidak valid'
    : '';

  const handleSubmit = () => {
    setSubmitted(true);
    if (!phone || !pw) return;
    if (!/^(\+62|08)\d{8,13}$/.test(phone.replace(/[-\s]/g,''))) return;
    setLoading(true);
    setTimeout(() => setLoading(false), 2400);
  };

  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
    }}>
      <AuthHeader greeting="Selamat datang kembali 👋" />

      <div style={{
        height: '62%', background: PMO.card, position: 'relative',
        padding: '24px 24px 34px', boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <AuthInput
            label="Nomor HP" icon={<PhoneIcon/>} type="tel"
            placeholder="+62 812-XXXX-XXXX"
            value={phone} onChange={e => setPhone(e.target.value)}
            error={phoneError}
          />
          <AuthInput
            label="Password" icon={<LockIcon/>}
            type={showPw ? 'text' : 'password'}
            placeholder="Masukkan password"
            value={pw} onChange={e => setPw(e.target.value)}
            rightIcon={<AuthEyeToggle shown={showPw} onToggle={() => setShowPw(s => !s)} />}
          />
        </div>

        <div style={{ textAlign: 'right', marginTop: 4 }}>
          <a href="#" style={{
            fontSize: 13, color: PMO.primary, fontWeight: 600,
            textDecoration: 'none', padding: 4, fontFamily: PMO.fontBody,
          }}>Lupa Password?</a>
        </div>

        <div style={{ marginTop: 24 }}>
          <AuthCTA onClick={handleSubmit} loading={loading} loadingLabel="Memverifikasi">
            Masuk
          </AuthCTA>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '24px 0' }}>
          <div style={{ flex: 1, height: 1, background: PMO.border }} />
          <span style={{ fontSize: 13, color: PMO.textMute, fontWeight: 500 }}>atau</span>
          <div style={{ flex: 1, height: 1, background: PMO.border }} />
        </div>

        <div style={{ textAlign: 'center', fontSize: 14, color: PMO.textMute }}>
          Belum punya akun?{' '}
          <a href="#" style={{ color: PMO.primary, fontWeight: 700, textDecoration: 'none' }}>
            Daftar Sekarang
          </a>
        </div>

        <div style={{ flex: 1 }} />
        <AuthSecurityNote />
      </div>
    </div>
  );
}

Object.assign(window, { Login });
