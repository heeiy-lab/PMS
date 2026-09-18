# Period Tracker App

Aplikasi Flutter untuk pelacakan haid dan edukasi PMS berbasis Gemini AI.

## Menjalankan fitur AI

Fitur edukasi AI membaca API key dari environment saat proses build/run. Jangan
menulis API key langsung ke source code atau melakukan commit terhadapnya.

```bash
flutter run --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Untuk build release:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=YOUR_GEMINI_API_KEY
```

Jika API key tidak diberikan atau layanan Gemini gagal diakses, aplikasi
menampilkan konten edukasi cadangan.
