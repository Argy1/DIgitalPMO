// DigitalPMO Register (refined)

function Register() {
  const [name, setName] = React.useState('');
  const [phone, setPhone] = React.useState('');
  const [pw, setPw] = React.useState('');
  const [pw2, setPw2] = React.useState('');
  const [showPw, setShowPw] = React.useState(false);
  const [showPw2, setShowPw2] = React.useState(false);
  const [agreed, setAgreed] = React.useState(false);
  const [loading, setLoading] = React.useState(false);

  const pwMismatch = pw2.length > 0 && pw2 !== pw ? 'Password tidak cocok' : '';
  const handleSubmit = () => {
    setLoading(true);
    setTimeout(() => setLoading(false), 2400);
  };

  return (
    <div style={{
      height: '100%', background: PMO.card, position: 'relative',
      fontFamily: PMO.fontBody, color: PMO.text, overflow: 'hidden',
    }}>
      <AuthHeader tagline="Mulai perjalanan sembuhmu 🌱" />

      <div style={{
        height: '62%', background: PMO.card, position: 'relative',
        boxSizing: 'border-box',
        display: 'flex', flexDirection: 'column', overflow: 'hidden',
      }}>
        <div style={{
          flex: 1, overflowY: 'auto',
          padding: '20px 20px 0',
          WebkitOverflowScrolling: 'touch',
        }}>
          <h1 style={{
            margin: 0, fontFamily: PMO.fontHead, fontSize: 20, fontWeight: 700,
            color: PMO.text, letterSpacing: -0.3, lineHeight: 1.2, marginBottom: 4,
          }}>Buat Akun Baru</h1>
          <p style={{
            margin: 0, fontSize: 13, color: PMO.textMute,
            fontFamily: PMO.fontBody, marginBottom: 20,
          }}>Isi data diri kamu dengan benar</p>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <AuthInput
              label="Nama Lengkap" icon={<UserIcon/>}
              placeholder="Nama sesuai KTP"
              value={name} onChange={e => setName(e.target.value)}
            />
            <AuthInput
              label="Nomor HP" icon={<PhoneIcon/>} type="tel"
              placeholder="+62 812-XXXX-XXXX"
              value={phone} onChange={e => setPhone(e.target.value)}
              note="Kode OTP akan dikirim ke nomor ini"
            />

            {/* Password — with strength indicator */}
            <div>
              <AuthInput
                label="Password" icon={<LockIcon/>}
                type={showPw ? 'text' : 'password'}
                placeholder="Masukkan password"
                value={pw} onChange={e => setPw(e.target.value)}
                rightIcon={<AuthEyeToggle shown={showPw} onToggle={() => setShowPw(s => !s)} />}
                note={pw.length === 0 ? 'Minimal 8 karakter' : null}
              />
              {pw.length > 0 && <PasswordStrength value={pw}/>}
            </div>

            <AuthInput
              label="Konfirmasi Password" icon={<LockCheckIcon/>}
              type={showPw2 ? 'text' : 'password'}
              placeholder="Ulangi password"
              value={pw2} onChange={e => setPw2(e.target.value)}
              rightIcon={<AuthEyeToggle shown={showPw2} onToggle={() => setShowPw2(s => !s)} />}
              error={pwMismatch}
              maxLength={32} showCount={pw2.length > 0}
            />
          </div>

          <div style={{ marginTop: 16 }}>
            <AuthCheckbox checked={agreed} onChange={() => setAgreed(a => !a)}>
              Saya menyetujui{' '}
              <a href="#" style={{ color: PMO.primary, fontWeight: 600, textDecoration: 'underline' }}>
                Syarat & Ketentuan
              </a>
              {' '}dan{' '}
              <a href="#" style={{ color: PMO.primary, fontWeight: 600, textDecoration: 'underline' }}>
                Kebijakan Privasi
              </a>
            </AuthCheckbox>
          </div>

          <div style={{ marginTop: 20 }}>
            <AuthCTA
              disabled={!agreed}
              loading={loading}
              loadingLabel="Mendaftarkan"
              onClick={handleSubmit}
            >Daftar Sekarang</AuthCTA>
          </div>

          <div style={{
            textAlign: 'center', fontSize: 14, color: PMO.textMute,
            marginTop: 16,
          }}>
            Sudah punya akun?{' '}
            <a href="#" style={{ color: PMO.primary, fontWeight: 700, textDecoration: 'none' }}>
              Masuk
            </a>
          </div>

          <div style={{ height: 20 }} />
        </div>

        <div style={{ padding: '8px 20px 34px' }}>
          <AuthSecurityNote />
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { Register });
