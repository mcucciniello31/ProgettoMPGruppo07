import 'package:flutter/material.dart';

class BarcodePainter extends CustomPainter {
  final String code;
  final Color barColor;

  BarcodePainter({
    required this.code,
    this.barColor = Colors.black,
  });

  static const Map<String, String> _code39Map = {
    '0': '000110100', '1': '100100001', '2': '001100001', '3': '101100000',
    '4': '000110001', '5': '100110000', '6': '001110000', '7': '000100101',
    '8': '100100100', '9': '001100100',
    'A': '100001001', 'B': '001001001', 'C': '101001000', 'D': '000011001',
    'E': '100011000', 'F': '001011000', 'G': '000001101', 'H': '100001100',
    'I': '001001100', 'J': '000011100', 'K': '100000011', 'L': '001000011',
    'M': '101000010', 'N': '000010011', 'O': '100010010', 'P': '001010010',
    'Q': '000000111', 'R': '100000110', 'S': '001000110', 'T': '000010110',
    'U': '110000001', 'V': '011000001', 'W': '111000000', 'X': '010010001',
    'Y': '110010000', 'Z': '011010000',
    '-': '010000101', '.': '110000100', ' ': '011000100', '*': '010010100',
    '\$': '010101000', '/': '010100010', '+': '010001010', '%': '000101010',
  };

  @override
  void paint(Canvas canvas, Size size) {
    final String cleanCode = code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-\.\ \$\/\+\%]'), '');
    final String fullCode = '*$cleanCode*';
    
    // Calcola la dimensione totale per determinare lo spessore dell'unità grafica
    double totalUnits = 0;
    const double narrowWidth = 1.0;
    const double wideWidth = 2.5;
    const double interCharacterGap = 1.0;

    for (int i = 0; i < fullCode.length; i++) {
      final char = fullCode[i];
      final pattern = _code39Map[char] ?? _code39Map['*']!;
      for (int j = 0; j < pattern.length; j++) {
        final isWide = pattern[j] == '1';
        totalUnits += isWide ? wideWidth : narrowWidth;
      }
      if (i < fullCode.length - 1) {
        totalUnits += interCharacterGap;
      }
    }

    if (totalUnits == 0) return;
    final double scale = size.width / totalUnits;
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    double currentX = 0;

    for (int i = 0; i < fullCode.length; i++) {
      final char = fullCode[i];
      final pattern = _code39Map[char] ?? _code39Map['*']!;
      
      for (int j = 0; j < 9; j++) {
        final isWide = pattern[j] == '1';
        final width = (isWide ? wideWidth : narrowWidth) * scale;
        
        final isBar = j % 2 == 0;
        if (isBar) {
          canvas.drawRect(
            Rect.fromLTWH(currentX, 0, width, size.height),
            paint,
          );
        }
        currentX += width;
      }
      
      if (i < fullCode.length - 1) {
        currentX += interCharacterGap * scale;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarcodePainter oldDelegate) {
    return oldDelegate.code != code || oldDelegate.barColor != barColor;
  }
}

class QrCodePainter extends CustomPainter {
  final String code;
  final Color qrColor;

  QrCodePainter({
    required this.code,
    this.qrColor = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int gridSize = 21;
    final double moduleSize = size.width / gridSize;
    
    final paint = Paint()
      ..color = qrColor
      ..style = PaintingStyle.fill;

    // Inizializza il seed del generatore di numeri casuali
    int seed = 0;
    final cleanCode = code.trim().toUpperCase();
    for (int i = 0; i < cleanCode.length; i++) {
      seed = cleanCode.codeUnitAt(i) + ((seed << 5) - seed);
    }
    seed = seed.abs();
    
    // Generatore pseudo-casuale lineare congruenziale (LCG)
    int currentSeed = seed;
    double nextDouble() {
      currentSeed = (1103515245 * currentSeed + 12345) & 0x7FFFFFFF;
      return currentSeed / 2147483647.0;
    }

    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        bool isBlack = false;

        // 1. Disegna i quadrati di allineamento (Finder patterns)
        if (r < 7 && c < 7) {
          // Quadrato in alto a sinistra
          isBlack = _isFinderPatternCell(r, c);
        } else if (r < 7 && c >= 14) {
          // Quadrato in alto a destra
          isBlack = _isFinderPatternCell(r, c - 14);
        } else if (r >= 14 && c < 7) {
          // Quadrato in basso a sinistra
          isBlack = _isFinderPatternCell(r - 14, c);
        }
        // 2. Disegna i pattern di sincronizzazione alternati (Timing patterns)
        else if (r == 6 && c >= 7 && c < 14) {
          isBlack = c % 2 == 0;
        } else if (c == 6 && r >= 7 && r < 14) {
          isBlack = r % 2 == 0;
        }
        // 3. Rumore deterministico calcolato in base all'hash del codice di prenotazione
        else {
          isBlack = nextDouble() < 0.5;
        }

        if (isBlack) {
          canvas.drawRect(
            Rect.fromLTWH(
              c * moduleSize,
              r * moduleSize,
              moduleSize,
              moduleSize,
            ),
            paint,
          );
        }
      }
    }
  }

  bool _isFinderPatternCell(int localR, int localC) {
    if (localR == 0 || localR == 6 || localC == 0 || localC == 6) {
      return true;
    }
    if (localR == 1 || localR == 5 || localC == 1 || localC == 5) {
      return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(covariant QrCodePainter oldDelegate) {
    return oldDelegate.code != code || oldDelegate.qrColor != qrColor;
  }
}
