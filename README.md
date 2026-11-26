# TPQ NUR FATIMAH DIGITAL RELIGIUS

Aplikasi administrasi eksklusif TPQ Nur Fatimah.

## Status saat ini
- Fondasi prototipe web: dashboard dan CRUD data santri, guru, kelas.
- File SQL fondasi Supabase: `supabase/schema.sql`.
- Workflow deployment GitHub Pages: `.github/workflows/pages.yml`.
- Belum terhubung ke project Supabase pengguna; belum boleh digunakan untuk menyimpan data operasional sebenarnya.

## GitHub Pages
1. Buka Settings → Pages.
2. Pada Build and deployment, pilih **GitHub Actions**.
3. Workflow akan menerbitkan situs setelah push ke `main`.
4. URL situs: https://zendconec-rgb.github.io/tpq-nur-fatimah-digital-religius/

## Supabase
1. Buat project Supabase khusus TPQ Nur Fatimah.
2. Buka SQL Editor dan jalankan isi `supabase/schema.sql`.
3. Buat akun administrator dengan email `tpq.nurfatimah@gmail.com` melalui Authentication.
4. Trigger akan membuat profil dan memberi role admin untuk email tersebut.
5. Sebelum produksi, audit kebijakan RLS, uji login, dan lakukan backup.

## Keamanan dan batasan
- Jangan pernah memasukkan service_role key ke HTML, JavaScript browser, atau GitHub.
- Gunakan hanya anon/publishable key di frontend setelah RLS diuji.
- File SQL ini merupakan fondasi awal dan perlu review serta pengujian sebelum produksi.
- Data prototipe saat ini disimpan di localStorage browser; data tidak tersinkron antarperangkat.
- Fitur absensi QR, keuangan, surat menyurat, akademik, laporan, audit log, dan backup otomatis masih dalam roadmap.
