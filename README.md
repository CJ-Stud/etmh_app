# ETMH — Emotional Tracker for Mental Health

> Ruang aman untuk mencatat emosi harian, melihat polanya dari waktu ke waktu, dan mendapatkan insight untuk menentukan langkah berikutnya. Dibangun dengan Flutter dan Clean Architecture.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

---

## Demo

<!-- TODO: Ganti placeholder ini dengan screenshot / GIF aplikasimu.
     Letakkan file gambar di folder screenshots/ lalu sesuaikan namanya di bawah. -->
<p align="center">
  <img src="screenshots/home.png" width="240" alt="Beranda" />
  <img src="screenshots/input_emosi.png" width="240" alt="Input Emosi (BottomSheet)" />
  <img src="screenshots/insight.png" width="240" alt="Insight Card" />
</p>

---

## Latar Belakang

Banyak orang kesulitan mengenali apa yang sebenarnya mereka rasakan, dan sering bingung harus berbuat apa ketika emosi itu datang. ETMH hadir untuk menjawab masalah tersebut: sebuah pendamping yang membantu pengguna mencatat emosi harian secara cepat, meninjau kembali polanya seiring waktu, lalu memberi insight yang bisa ditindaklanjuti sebagai langkah berikutnya.

## Fitur Utama

- **Pencatatan emosi harian** melalui BottomSheet yang dirancang nyaman dijangkau dengan satu tangan, sehingga proses check-in terasa cepat dan tidak membebani.
- **Riwayat emosi** untuk meninjau kembali perasaan dari hari ke hari.
- **Grafik mood** yang memvisualisasikan tren emosi sehingga pola jadi lebih mudah dipahami.
- **Kalender mood** untuk melihat sebaran kondisi emosi dalam satu bulan.
- **Insight & rekomendasi langkah berikutnya** dari pendamping AI berbasis Google Gemini, dengan gaya bahasa yang hangat, empatik, dan santun.
- **Pengingat pencatatan** lewat notifikasi agar kebiasaan mencatat emosi tetap terjaga.
- **Akses darurat** untuk menghubungi pihak berwenang (mis. layanan Kemenkes) dengan cepat saat pengguna membutuhkan bantuan segera.

## Design System — The Healing Palette

Palet warna dirancang untuk memberi kesan tenang dan menenangkan, sesuai konteks kesehatan mental.

| Token            | Hex       | Pratinjau                                                                 | Penggunaan              |
|------------------|-----------|---------------------------------------------------------------------------|-------------------------|
| Cream            | `#FDFBF7` | ![#FDFBF7](https://placehold.co/15x15/FDFBF7/FDFBF7.png) | Background utama        |
| Sage Green       | `#A3B19B` | ![#A3B19B](https://placehold.co/15x15/A3B19B/A3B19B.png) | Tombol utama / sukses   |
| Dusty Lavender   | `#D6C7DE` | ![#D6C7DE](https://placehold.co/15x15/D6C7DE/D6C7DE.png) | Card informasi / insight|
| Charcoal Grey    | `#333333` | ![#333333](https://placehold.co/15x15/333333/333333.png) | Teks utama              |

Implementasi disentralisasi pada satu file tema (`lib/core/theme/`) agar konsisten dan mudah dirawat — tidak ada warna yang ditulis langsung (hard-coded) di luar file ini.

## Arsitektur

Proyek mengikuti **Clean Architecture** sederhana dengan satu arah dependensi (Presentation -> Service -> Data).

```
+---------------------------------------------+
|                PRESENTATION                 |
|   Screens, Widgets, BottomSheets, Providers |
|            (Provider / ChangeNotifier)      |
+----------------------+----------------------+
                       | memanggil
                       v
+---------------------------------------------+
|                  SERVICES                   |
|   Logika murni Dart (mis. Gemini Service)   |
+----------------------+----------------------+
                       | menggunakan
                       v
+---------------------------------------------+
|                    DATA                     |
|   Models, Repositories (Firestore + Hive)   |
|              + error handling try-catch     |
+---------------------------------------------+
```

Prinsip yang dipegang:
- Lapisan `core/` bebas dependensi — boleh diimpor siapa saja, tapi tidak mengimpor apa pun.
- Lapisan `data/` mengenal Firestore & Hive, tapi tidak mengenal widget.
- Semua operasi database dibungkus `try-catch` agar kegagalan tertangani dengan aman.
- State management memakai **Provider** secara konsisten di seluruh aplikasi.

## Tech Stack

| Kategori          | Teknologi                                  |
|-------------------|--------------------------------------------|
| Framework         | Flutter (Dart)                             |
| State Management  | Provider                                   |
| Database Lokal    | Hive                                       |
| Backend & Auth    | Firebase (Authentication + Cloud Firestore)|
| AI                | Google Gemini                              |

## Cara Menjalankan

1. **Clone repositori**
   ```bash
   git clone https://github.com/USERNAME/etmh_app.git
   cd etmh_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Siapkan API key Gemini & konfigurasi Firebase**
   API key Gemini tidak disertakan di repo demi keamanan. Dapatkan key gratis di [Google AI Studio](https://aistudio.google.com/app/apikey), lalu siapkan sesuai mekanisme konfigurasi pada proyek. File konfigurasi Firebase (`firebase_options.dart`) juga sengaja tidak disertakan; hasilkan ulang dengan menjalankan `flutterfire configure` pada proyek Firebase milikmu sendiri.

4. **Jalankan aplikasi**
   ```bash
   flutter run
   ```

## Keamanan & Privasi

- API key Gemini dan file konfigurasi Firebase tidak pernah ikut di-commit (lihat `.gitignore`).
- Data emosi pengguna tersimpan secara lokal (Hive) dan disinkronkan ke Firestore milik pengguna.
- Akses ke data dilindungi melalui **Firebase Security Rules**, bukan dengan menyembunyikan kunci konfigurasi.

## Lisensi

Dirilis di bawah Lisensi MIT. Lihat file [LICENSE](LICENSE) untuk detail.

---

Dibuat oleh **[Claudio Jafna Ibrani]** — [(https://www.linkedin.com/in/claudio-jafna-ibrani-319722218/)]
