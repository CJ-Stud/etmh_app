// lib/services/gemini_insight_service.dart
//
// Wraps the Firebase AI Logic SDK (`firebase_ai`) and exposes three
// methods aligned to the product spec:
//
//   • generateDailyInsight()    — empathetic summary + 1 uplifting advice
//   • generateWeeklyInsight()   — trend analysis + exactly 2 action items
//   • generateMonthlyInsight()  — macro psychological trend analysis
//
// Output is in polite Bahasa Indonesia in the persona of "Milo" — a
// warm, professional, counselor-like companion (NEVER a clinician).
//
// Why firebase_ai (not google_generative_ai)?
//   • The old `google_generative_ai` Dart SDK has been deprecated by
//     Google in favor of `firebase_ai`.
//   • Firebase AI Logic keeps the API key on Google's side — the client
//     never holds it, so it can't be extracted from a decompiled APK.

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';

import '../core/utils/data_sanitizer.dart';
import '../data/models/daily_log.dart';

const String _kSystemInstruction = '''
Anda adalah "Milo", seorang teman pendamping kesehatan mental yang profesional,
hangat, dan sangat empatik. Anda berbicara dalam Bahasa Indonesia yang sopan,
lembut, dan menenangkan — seperti seorang sahabat bijak, bukan seorang dokter
yang dingin.

ATURAN MUTLAK:
1. JANGAN PERNAH mendiagnosis pengguna dengan kondisi medis atau psikologis
   apa pun (mis. depresi, kecemasan, bipolar). Anda bukan tenaga medis.
2. Jangan menggurui. Validasi perasaan pengguna terlebih dahulu sebelum
   memberi saran.
3. Gunakan kalimat pendek dan mudah dicerna. Hindari istilah klinis.
4. Saran harus konkret, lembut, dan dapat dilakukan dalam hitungan menit.
5. Jika pengguna menunjukkan tanda krisis serius (mis. menyebut keinginan
   menyakiti diri), arahkan dengan lembut untuk menghubungi tenaga
   profesional atau layanan darurat 119 ext. 8 (Indonesia).
6. Selalu tutup dengan nada penuh harapan, tanpa terkesan memaksa.
7. Jangan gunakan emoji berlebihan. Maksimal 1–2 emoji yang relevan.
''';

/// Result envelope so the UI can render confidence / fallback state.
class InsightResult {
  final String text;
  final bool isFallback; // true → local copy, not Gemini
  final DateTime generatedAt;

  const InsightResult({
    required this.text,
    required this.generatedAt,
    this.isFallback = false,
  });
}

class GeminiInsightService {
  /// Default model — `gemini-2.5-flash` is the fast, generous-free-tier
  /// option that fits this product's "calm, instant" UX.
  GeminiInsightService({String modelName = 'gemini-2.5-flash'})
      : _model = FirebaseAI.googleAI().generativeModel(
          model: modelName,
          systemInstruction: Content.system(_kSystemInstruction),
          generationConfig: GenerationConfig(
            temperature: 0.7,
            topP: 0.95,
            maxOutputTokens: 512,
          ),
          // NOTE: When using FirebaseAI.googleAI() backend, do NOT pass the
          // 3rd `HarmBlockMethod` argument — it throws an AIError. Only the
          // Vertex AI backend supports it.
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium,null),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium,null),
            SafetySetting(
                HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium,null),
            SafetySetting(
                HarmCategory.dangerousContent, HarmBlockThreshold.medium,null),
          ],
        );

  final GenerativeModel _model;

  // ══════════════════════════════════════════════════════════════════
  //  1. DAILY
  // ══════════════════════════════════════════════════════════════════
  Future<InsightResult> generateDailyInsight(DailyLog log) async {
    if (log.isEmpty) {
      return InsightResult(
        text:
            'Belum ada catatan emosi hari ini. Tidak apa-apa, kapan pun kamu '
            'siap, Milo ada di sini untuk mendengarkan. 🌿',
        generatedAt: DateTime.now(),
        isFallback: true,
      );
    }

    final sanitized = DataSanitizer.sanitizeDay(log);

    final prompt = '''
Berikut adalah catatan emosi pengguna untuk hari ini dalam format JSON:

```json
${const JsonEncoder.withIndent('  ').convert(sanitized)}
```

Catatan penting:
- Pengguna mengisi ${sanitized['filled_slot_count']} dari 4 slot
  (${sanitized['missing_slot_count']} slot kosong adalah hal yang wajar).
- Jangan menyebut atau menyalahkan slot yang kosong.

Tugas Anda:
1. Tulis 2–3 kalimat ringkasan yang empatik tentang perjalanan emosi
   pengguna hari ini. Validasi perasaan mereka.
2. Berikan TEPAT 1 saran lembut dan konkret yang bisa dicoba besok pagi
   (durasi maksimal 5 menit, mudah dilakukan).

FORMAT KELUARAN (gunakan persis struktur ini, tanpa heading lain):

Ringkasan:
<2–3 kalimat>

Untuk Besok:
<1 saran konkret>
''';

    return _runPrompt(prompt, fallback: _fallbackDaily(log));
  }

  // ══════════════════════════════════════════════════════════════════
  //  2. WEEKLY
  // ══════════════════════════════════════════════════════════════════
  Future<InsightResult> generateWeeklyInsight(
      List<DailyLog?> last7Days) async {
    final hasData =
        last7Days.whereType<DailyLog>().any((l) => l.filledCount > 0);
    if (!hasData) {
      return InsightResult(
        text:
            'Belum ada cukup data untuk membuat ringkasan mingguan. Coba isi '
            'beberapa check-in dalam beberapa hari ke depan, ya. 🌱',
        generatedAt: DateTime.now(),
        isFallback: true,
      );
    }

    final stats = DataSanitizer.sanitizeRange(last7Days);

    final prompt = '''
Berikut adalah statistik emosi pengguna selama 7 hari terakhir
(beberapa hari mungkin kosong — itu wajar, jangan dikomentari):

```json
${const JsonEncoder.withIndent('  ').convert(stats)}
```

Tugas Anda:
1. Tulis 3–4 kalimat analisis tren mingguan yang empatik. Bicarakan pola
   yang Anda lihat (mis. emosi dominan, tag yang sering muncul, perubahan
   rata-rata skor). Validasi dulu, baru refleksi.
2. Berikan TEPAT 2 action item yang konkret, lembut, dan dapat dimulai
   minggu depan. Tiap action item maksimal 1 kalimat.

FORMAT KELUARAN (persis struktur ini):

Tren Mingguan:
<3–4 kalimat>

2 Langkah Kecil Minggu Depan:
1. <action item 1>
2. <action item 2>
''';

    return _runPrompt(prompt, fallback: _fallbackWeekly(stats));
  }

  // ══════════════════════════════════════════════════════════════════
  //  3. MONTHLY
  // ══════════════════════════════════════════════════════════════════
  Future<InsightResult> generateMonthlyInsight(
      List<DailyLog?> last30Days) async {
    final hasData =
        last30Days.whereType<DailyLog>().any((l) => l.filledCount > 0);
    if (!hasData) {
      return InsightResult(
        text:
            'Belum cukup data untuk analisis bulanan. Konsistensi pelan-pelan '
            'lebih berharga daripada sempurna. 🌷',
        generatedAt: DateTime.now(),
        isFallback: true,
      );
    }

    final stats = DataSanitizer.sanitizeRange(last30Days);

    final prompt = '''
Berikut adalah agregat emosi pengguna selama 30 hari terakhir:

```json
${const JsonEncoder.withIndent('  ').convert(stats)}
```

Tugas Anda — analisis tren psikologis tingkat makro:
1. Tulis 4–6 kalimat yang merefleksikan pola besar selama sebulan
   terakhir. Soroti tema yang muncul dari tag, perubahan rata-rata
   skor, serta konsistensi check-in. Tetap hangat dan tidak menghakimi.
2. Berikan 1 paragraf (2–3 kalimat) "Refleksi & Harapan" untuk bulan
   berikutnya — fokus pada kekuatan yang sudah dimiliki pengguna.
3. INGAT: Anda bukan tenaga medis. Jangan menyebut atau menyiratkan
   diagnosis apa pun. Jika polanya berat, sarankan dengan lembut untuk
   berbicara dengan profesional.

FORMAT KELUARAN (persis struktur ini):

Tren Bulanan:
<4–6 kalimat>

Refleksi & Harapan:
<2–3 kalimat>
''';

    return _runPrompt(prompt, fallback: _fallbackMonthly(stats));
  }

  // ── Internal: single point of error handling ──────────────────────
  Future<InsightResult> _runPrompt(String prompt,
      {required String fallback}) async {
    try {
      final response = await _model
          .generateContent([Content.text(prompt)]).timeout(
        const Duration(seconds: 20),
      );

      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return InsightResult(
          text: fallback,
          generatedAt: DateTime.now(),
          isFallback: true,
        );
      }
      return InsightResult(text: text, generatedAt: DateTime.now());
    } catch (_) {
      // We swallow errors on purpose — the user sees the calm fallback
      // and the UI stays calm. In production this should also log to
      // Crashlytics / Sentry.
      return InsightResult(
        text: fallback,
        generatedAt: DateTime.now(),
        isFallback: true,
      );
    }
  }

  // ── Local fallbacks (offline / API failure) ───────────────────────
  String _fallbackDaily(DailyLog log) {
    final avg = log.averageScore;
    final mood = avg == null
        ? 'beragam'
        : avg >= 4
            ? 'cenderung positif'
            : avg >= 3
                ? 'cukup stabil'
                : 'sedikit menantang';
    return 'Ringkasan:\nHari ini perasaanmu $mood. Terima kasih sudah '
        'meluangkan waktu untuk mendengarkan dirimu sendiri.\n\n'
        'Untuk Besok:\nMulai pagi dengan tarikan napas dalam selama 1 menit '
        'sebelum menyentuh ponsel.';
  }

  String _fallbackWeekly(Map<String, dynamic> stats) {
    return 'Tren Mingguan:\nKamu sudah mencatat ${stats['total_check_ins']} '
        'kali minggu ini — itu pencapaian yang berarti. Konsistensi kecil '
        'seperti ini yang membentuk kebiasaan yang sehat.\n\n'
        '2 Langkah Kecil Minggu Depan:\n'
        '1. Pilih satu waktu tetap setiap hari untuk check-in.\n'
        '2. Tambahkan satu tag baru yang menjelaskan konteks emosimu.';
  }

  String _fallbackMonthly(Map<String, dynamic> stats) {
    return 'Tren Bulanan:\nSelama 30 hari terakhir kamu mencatat '
        '${stats['days_with_data']} hari emosimu. Setiap catatan adalah '
        'bentuk keberanian untuk hadir bagi dirimu sendiri.\n\n'
        'Refleksi & Harapan:\nBulan depan, izinkan dirimu untuk tidak '
        'sempurna. Konsistensi yang lembut lebih bernilai daripada target '
        'yang kaku.';
  }
}
