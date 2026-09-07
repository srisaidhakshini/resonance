/// Utility to convert LaTeX and ASCII math/chemistry notation into clean,
/// beautiful Unicode formatting that renders flawlessly in Flutter Markdown.
class MathFormatter {
  // Superscript mappings (for exponents like x^2)
  static const Map<String, String> _superscripts = {
    '0': '⁰',
    '1': '¹',
    '2': '²',
    '3': '³',
    '4': '⁴',
    '5': '⁵',
    '6': '⁶',
    '7': '⁷',
    '8': '⁸',
    '9': '⁹',
    '+': '⁺',
    '-': '⁻',
    'n': 'ⁿ',
    'i': 'ⁱ',
    'x': 'ˣ',
  };

  // Subscript mappings (for chemistry like H_2O)
  static const Map<String, String> _subscripts = {
    '0': '₀',
    '1': '₁',
    '2': '₂',
    '3': '₃',
    '4': '₄',
    '5': '₅',
    '6': '₆',
    '7': '₇',
    '8': '₈',
    '9': '₉',
    '+': '₊',
    '-': '₋',
    'a': 'ₐ',
    'b': 'ᵦ',
  };

  // Reverse map: Unicode subscript → ASCII digit
  static const Map<String, String> _subscriptsReverse = {
    '₀': '0',
    '₁': '1',
    '₂': '2',
    '₃': '3',
    '₄': '4',
    '₅': '5',
    '₆': '6',
    '₇': '7',
    '₈': '8',
    '₉': '9',
  };

  /// Cleans LaTeX commands and formats equations into readable text & markdown
  static String format(String text) {
    String result = text;

    // 0. Normalize any mixed Unicode subscripts back to ASCII
    _subscriptsReverse.forEach((unicode, ascii) {
      result = result.replaceAll(unicode, ascii);
    });

    // 1. Clean \mathbf{...} → **...** (Bold text)
    result = result.replaceAllMapped(
      RegExp(r'\\mathbf\{([^}]*)\}'),
      (match) => '**${match.group(1)}**',
    );

    // 2. Clean \text{...} → plain text
    result = result.replaceAllMapped(
      RegExp(r'\\text\{([^}]*)\}'),
      (match) => match.group(1)!,
    );

    // 3. Clean \vec{...} → vector notation
    result = result.replaceAllMapped(
      RegExp(r'\\vec\{([^}]*)\}'),
      (match) => '${match.group(1)}⃗',
    );

    // 4. Clean \mathcal{O} → O (Big-O notation)
    result = result.replaceAll(r'\mathcal{O}', 'O');
    result = result.replaceAll(r'\mathcal{o}', 'o');

    // 5. Clean spacing and relation operators
    result = result.replaceAll(r'\quad', '   ');
    result = result.replaceAll(r'\qquad', '      ');
    result = result.replaceAll(r'\implies', ' ⟹ ');
    result = result.replaceAll(r'\longrightarrow', ' → ');
    result = result.replaceAll(r'\Delta', 'Δ');
    result = result.replaceAll(r'\sum', '∑');
    result = result.replaceAll(r'\int', '∫');
    result = result.replaceAll(r'\partial', '∂');
    result = result.replaceAll(r'\infty', '∞');
    result = result.replaceAll(r'\cdot', ' · ');

    // 6. Common LaTeX mathematical symbols
    final latexSymbols = {
      r'\times': '×',
      r'\div': '÷',
      r'\pm': '±',
      r'\mp': '∓',
      r'\sqrt': '√',
      r'\pi': 'π',
      r'\alpha': 'α',
      r'\beta': 'β',
      r'\gamma': 'γ',
      r'\delta': 'δ',
      r'\epsilon': 'ε',
      r'\theta': 'θ',
      r'\lambda': 'λ',
      r'\mu': 'μ',
      r'\sigma': 'σ',
      r'\omega': 'ω',
      r'\neq': '≠',
      r'\leq': '≤',
      r'\le': '≤',
      r'\geq': '≥',
      r'\ge': '≥',
      r'\approx': '≈',
      r'\equiv': '≡',
      r'\propto': '∝',
      r'\rightarrow': '→',
      r'\leftarrow': '←',
      r'\in': '∈',
      r'\notin': '∉',
    };
    latexSymbols.forEach((latex, symbol) {
      result = result.replaceAll(latex, symbol);
    });

    // 7. Fractions \frac{a}{b} → (a / b)
    result = result.replaceAllMapped(
      RegExp(r'\\frac\{([^}]+)\}\{([^}]+)\}'),
      (match) => '(${match.group(1)} / ${match.group(2)})',
    );

    // 8. Square roots \sqrt{...} → √( ... )
    result = result.replaceAllMapped(
      RegExp(r'√\{([^}]+)\}'),
      (match) => '√(${match.group(1)})',
    );

    // 9. Convert block math: $$ formula $$ → centered bold callout
    result = result.replaceAllMapped(
      RegExp(r'\$\$\s*([^$]+?)\s*\$\$'),
      (match) {
        final formula = match.group(1)!.trim();
        return '\n\n> **$formula**\n\n';
      },
    );

    // 10. Convert inline math: $ formula $ → clean inline expression
    result = result.replaceAllMapped(
      RegExp(r'\$([^$\n]+?)\$'),
      (match) => match.group(1)!.trim(),
    );

    // 11. Clean any stray double or single dollar signs that escaped
    result = result.replaceAll(r'$$', '');
    result = result.replaceAll(r'$', '');

    // 12. Convert superscripts: x^2, x^3, x^{10}
    result = result.replaceAllMapped(RegExp(r'\^(\{?)(\d+)(\}?)'), (match) {
      final digits = match.group(2)!;
      return digits.split('').map((c) => _superscripts[c] ?? c).join();
    });

    // 13. Convert subscripts: H_2, C_{12}, F_{net}
    result = result.replaceAllMapped(RegExp(r'([A-Za-z])_(\{?)(\d+)(\}?)'), (
      match,
    ) {
      final element = match.group(1)!;
      final subscript = match.group(3)!;
      return element +
          subscript.split('').map((c) => _subscripts[c] ?? c).join();
    });

    // 14. Convert plain digit sequences after capital letters (e.g. H2O, CO2)
    result = result.replaceAllMapped(RegExp(r'([A-Z])(\d+)'), (match) {
      final element = match.group(1)!;
      final number = match.group(2)!;
      if (number.length <= 2) {
        return element +
            number.split('').map((c) => _subscripts[c] ?? c).join();
      }
      return match.group(0)!;
    });

    return result;
  }
}
