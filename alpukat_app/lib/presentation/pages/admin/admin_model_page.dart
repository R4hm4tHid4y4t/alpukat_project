import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'admin_drawer.dart';

class AdminModelPage extends StatelessWidget {
  const AdminModelPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Data Matriks Varietas dari Gambar (2x2)
    // Urutan label: ['Aligator', 'Miki']
    final varietasMatrix = [
      [16, 0], // Aktual Aligator
      [0, 16], // Aktual Miki
    ];
    final varietasLabels = ['Aligator', 'Miki'];

    // 2. Data Matriks Kematangan dari Gambar (4x4)
    // Urutan: 1. Mentah, 2. Setengah Matang, 3. Matang, 4. Terlalu Matang
    final kematanganMatrix = [
      [20, 0, 0, 0], // Aktual Mentah: 20 benar, 0 salah
      [4, 3, 1, 0],  // Aktual Setengah Matang: 4 meleset ke Mentah, 3 benar, 1 meleset ke Matang
      [0, 0, 2, 0],  // Aktual Matang: 2 benar, 0 salah
      [0, 0, 0, 2],  // Aktual Terlalu Matang: 2 benar, 0 salah
    ];
    final kematanganLabels = ['Mentah', 'Setengah Matang', 'Matang', 'Terlalu Matang'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF1A2E1A)),
        title: const Text('Evaluasi Model CNN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
      ),
      drawer: const AdminDrawer(currentRoute: 'model'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performa Model Klasifikasi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A2E1A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hasil pengujian algoritma Convolutional Neural Network dihitung secara otomatis berdasarkan nilai Confusion Matrix.',
              style: TextStyle(color: AppColors.textGrey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Card Evaluasi Varietas
            _buildDynamicEvaluationCard(
              title: 'Model Varietas Alpukat',
              icon: Icons.eco_rounded,
              color: const Color(0xFF2D5A27),
              bgColor: const Color(0xFFE8F5E3),
              matrix: varietasMatrix,
              labels: varietasLabels,
            ),
            const SizedBox(height: 24),

            // Card Evaluasi Kematangan
            _buildDynamicEvaluationCard(
              title: 'Model Tingkat Kematangan',
              icon: Icons.water_drop_rounded,
              color: const Color(0xFF1565C0),
              bgColor: const Color(0xFFE3F2FD),
              matrix: kematanganMatrix,
              labels: kematanganLabels,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicEvaluationCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<List<int>> matrix,
    required List<String> labels,
  }) {
    final int numClasses = labels.length;

    // --- KALKULASI METRIK MULTICLASS (Macro-Average) ---
    int totalData = 0;
    int totalCorrect = 0;
    
    List<double> precisions = [];
    List<double> recalls = [];
    List<double> f1Scores = [];

    for (int i = 0; i < numClasses; i++) {
      int tp = matrix[i][i];
      int fp = 0;
      int fn = 0;

      for (int j = 0; j < numClasses; j++) {
        totalData += matrix[i][j];
        if (i == j) {
          totalCorrect += matrix[i][j];
        } else {
          fn += matrix[i][j]; // False Negatives (jumlah di baris i, selain diagonal)
          fp += matrix[j][i]; // False Positives (jumlah di kolom i, selain diagonal)
        }
      }

      double precision = (tp + fp) == 0 ? 0 : tp / (tp + fp);
      double recall = (tp + fn) == 0 ? 0 : tp / (tp + fn);
      double f1 = (precision + recall) == 0 ? 0 : 2 * (precision * recall) / (precision + recall);

      precisions.add(precision);
      recalls.add(recall);
      f1Scores.add(f1);
    }

    double accuracy = totalData == 0 ? 0 : totalCorrect / totalData;
    double macroPrecision = precisions.reduce((a, b) => a + b) / numClasses;
    double macroRecall = recalls.reduce((a, b) => a + b) / numClasses;
    double macroF1 = f1Scores.reduce((a, b) => a + b) / numClasses;

    // --- FORMAT KE STRING ---
    final String accStr = '${(accuracy * 100).toStringAsFixed(2)}%';
    final String precStr = '${(macroPrecision * 100).toStringAsFixed(2)}%';
    final String recStr = '${(macroRecall * 100).toStringAsFixed(2)}%';
    final String f1Str = '${(macroF1 * 100).toStringAsFixed(2)}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildMetric('Akurasi', accStr, color)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetric('Presisi', precStr, color)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetric('Recall', recStr, color)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetric('F1-Score', f1Str, color)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Confusion Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 12),
          
          // --- MENGGAMBAR GRID CONFUSION MATRIX SECARA OTOMATIS ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E8E0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                children: [
                  // Baris Header Kolom (Prediksi)
                  Row(
                    children: [
                      const SizedBox(width: 80), // Ruang kosong untuk sudut kiri atas
                      ...List.generate(numClasses, (index) {
                        return SizedBox(
                          width: 70,
                          child: Center(
                            child: Text(
                              labels[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Baris Isi Matriks
                  ...List.generate(numClasses, (rowIdx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          // Header Baris (Aktual)
                          SizedBox(
                            width: 80,
                            child: Text(
                              labels[rowIdx],
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                            ),
                          ),
                          // Isi Sel Grid
                          ...List.generate(numClasses, (colIdx) {
                            int val = matrix[rowIdx][colIdx];
                            // Warna biru muda tebal untuk nilai diagonal (TP), putih jika bukan
                            Color cellColor = (rowIdx == colIdx && val > 0) 
                                ? bgColor 
                                : Colors.white;

                            return Container(
                              width: 70,
                              height: 50,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: cellColor,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Center(
                                child: Text(
                                  val.toString(),
                                  style: TextStyle(
                                    fontSize: 16, 
                                    fontWeight: rowIdx == colIdx ? FontWeight.bold : FontWeight.normal,
                                    color: (rowIdx != colIdx && val > 0) ? Colors.red.shade400 : Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7F5), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}