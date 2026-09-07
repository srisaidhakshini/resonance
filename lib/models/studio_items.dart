import 'package:flutter/material.dart';

/// Minimalist pastel palettes for Studio items
class StudioTheme {
  final String name;
  final Color background;
  final Color cardBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color border;

  const StudioTheme({
    required this.name,
    required this.background,
    required this.cardBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.border,
  });
}

class StudioPalettes {
  // 1. Muted Teal (Physics & Mechanics)
  static const StudioTheme teal = StudioTheme(
    name: 'Muted Teal',
    background: Color(0xFFF2F8F6),
    cardBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF133633),
    secondaryText: Color(0xFF557774),
    accent: Color(0xFF159A8C),
    border: Color(0xFFD6EAE5),
  );

  // 2. Lavender Mist (Calculus & 3D Geometry)
  static const StudioTheme lavender = StudioTheme(
    name: 'Lavender Mist',
    background: Color(0xFFF7F5FC),
    cardBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF2E2648),
    secondaryText: Color(0xFF6B6188),
    accent: Color(0xFF7C69C2),
    border: Color(0xFFE5DFF4),
  );

  // 3. Sage Mint (Cybersecurity & Networks)
  static const StudioTheme sage = StudioTheme(
    name: 'Sage Mint',
    background: Color(0xFFF3F7F2),
    cardBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF223624),
    secondaryText: Color(0xFF59705B),
    accent: Color(0xFF4C8F53),
    border: Color(0xFFD8E6D9),
  );

  // 4. Soft Terracotta (Cell Biology & Genetics)
  static const StudioTheme terracotta = StudioTheme(
    name: 'Soft Terracotta',
    background: Color(0xFFFDF6F3),
    cardBackground: Color(0xFFFFFFFF),
    primaryText: Color(0xFF3F251C),
    secondaryText: Color(0xFF825D52),
    accent: Color(0xFFD46C4E),
    border: Color(0xFFF2DDD6),
  );

  static const List<StudioTheme> all = [teal, lavender, sage, terracotta];
}

// ---------------------------------------------------------------------------
// 1. SLIDE DECK MODELS
// ---------------------------------------------------------------------------

class SlideItem {
  final int slideNumber;
  final String title;
  final String subtitle;
  final List<String> bulletPoints;
  final String? codeOrFormula;
  final String keyTakeaway;

  const SlideItem({
    required this.slideNumber,
    required this.title,
    required this.subtitle,
    required this.bulletPoints,
    this.codeOrFormula,
    required this.keyTakeaway,
  });
}

class SlideDeck {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final int themeIndex;
  final List<SlideItem> slides;

  const SlideDeck({
    required this.id,
    required this.title,
    required this.subject,
    this.gradeLevel = 'Class 12',
    this.themeIndex = 0,
    required this.slides,
  });

  StudioTheme get theme => StudioPalettes.all[themeIndex % StudioPalettes.all.length];
}

// ---------------------------------------------------------------------------
// 2. FLASHCARD MODELS
// ---------------------------------------------------------------------------

class FlashcardItem {
  final String id;
  final String frontQuestion;
  final String backAnswer;
  final String category;
  final String hint;
  bool isMastered;

  FlashcardItem({
    required this.id,
    required this.frontQuestion,
    required this.backAnswer,
    required this.category,
    required this.hint,
    this.isMastered = false,
  });
}

class FlashcardDeck {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final int themeIndex;
  final List<FlashcardItem> cards;

  FlashcardDeck({
    required this.id,
    required this.title,
    required this.subject,
    this.gradeLevel = 'Class 12',
    this.themeIndex = 0,
    required this.cards,
  });

  StudioTheme get theme => StudioPalettes.all[themeIndex % StudioPalettes.all.length];
  int get masteredCount => cards.where((c) => c.isMastered).length;
}

// ---------------------------------------------------------------------------
// 3. QUIZ MODELS
// ---------------------------------------------------------------------------

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class QuizDeck {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final int themeIndex;
  final List<QuizQuestion> questions;

  const QuizDeck({
    required this.id,
    required this.title,
    required this.subject,
    this.gradeLevel = 'Class 12',
    this.themeIndex = 0,
    required this.questions,
  });

  StudioTheme get theme => StudioPalettes.all[themeIndex % StudioPalettes.all.length];
}

// ---------------------------------------------------------------------------
// 4. AUDIO OVERVIEW (PODCAST) MODELS
// ---------------------------------------------------------------------------

class PodcastTurn {
  final String speakerName; // "Alex" or "Jamie"
  final bool isHostA; // true = Alex (Lead Analyst), false = Jamie (Curious Host)
  final String dialogue;

  const PodcastTurn({
    required this.speakerName,
    required this.isHostA,
    required this.dialogue,
  });
}

class AudioOverviewTrack {
  final String id;
  final String title;
  final String topic;
  final String gradeLevel;
  final String durationMinutes;
  final int themeIndex;
  final List<PodcastTurn> transcript;

  const AudioOverviewTrack({
    required this.id,
    required this.title,
    required this.topic,
    this.gradeLevel = 'Class 12',
    this.durationMinutes = '3 min',
    this.themeIndex = 0,
    required this.transcript,
  });

  StudioTheme get theme => StudioPalettes.all[themeIndex % StudioPalettes.all.length];
}

// ---------------------------------------------------------------------------
// 5. MIND MAP GRAPH MODELS
// ---------------------------------------------------------------------------

class MindMapNode {
  final String id;
  final String label;
  final String detail;
  final List<MindMapNode> children;

  const MindMapNode({
    required this.id,
    required this.label,
    this.detail = '',
    this.children = const [],
  });
}

class MindMapDeck {
  final String id;
  final String title;
  final String subject;
  final String gradeLevel;
  final int themeIndex;
  final MindMapNode rootNode;

  const MindMapDeck({
    required this.id,
    required this.title,
    required this.subject,
    this.gradeLevel = 'Class 12',
    this.themeIndex = 0,
    required this.rootNode,
  });

  StudioTheme get theme => StudioPalettes.all[themeIndex % StudioPalettes.all.length];
}

// ---------------------------------------------------------------------------
// 6. PRE-BUILT TEMPLATES DATA (CLASS 9, 10, 11, 12)
// ---------------------------------------------------------------------------

class StudioPreTemplates {
  static const List<String> allGrades = ['All', 'Class 9', 'Class 10', 'Class 11', 'Class 12'];

  // -------------------------------------------------------------------------
  // MIND MAPS (4 per class = 16 rich hierarchical mind maps)
  // -------------------------------------------------------------------------
  static List<MindMapDeck> getSampleMindMaps() {
    return [
      // === CLASS 12 ===
      const MindMapDeck(
        id: 'mm_3d_geometry',
        title: '3D Geometry & Space Vectors',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        rootNode: MindMapNode(
          id: 'root_3d',
          label: '3D Coordinate Space',
          detail: 'Euclidean Space (R³)',
          children: [
            MindMapNode(
              id: 'axes',
              label: 'Axes & Octants',
              detail: 'X, Y, Z orthogonal axes intersecting at origin (0, 0, 0)',
              children: [
                MindMapNode(id: 'oct', label: '8 Octants', detail: 'Determined by signs of (+/-x, +/-y, +/-z)'),
                MindMapNode(id: 'planes', label: 'Coordinate Planes', detail: 'XY-plane (z=0), YZ-plane (x=0), XZ-plane (y=0)'),
              ],
            ),
            MindMapNode(
              id: 'dist',
              label: 'Distance & Midpoint',
              detail: 'Extension of Pythagorean theorem to 3 dimensions',
              children: [
                MindMapNode(id: 'dist_f', label: 'Distance Formula', detail: 'd = √[(x₂-x₁)² + (y₂-y₁)² + (z₂-z₁)²]'),
                MindMapNode(id: 'mid_f', label: 'Midpoint Formula', detail: 'M = ((x₁+x₂)/2, (y₁+y₂)/2, (z₁+z₂)/2)'),
              ],
            ),
            MindMapNode(
              id: 'vectors',
              label: 'Vector Operations',
              detail: 'Magnitude and directional components in 3D',
              children: [
                MindMapNode(id: 'dot', label: 'Dot Product', detail: 'A · B = |A||B| cos(θ) -> Scalar result'),
                MindMapNode(id: 'cross', label: 'Cross Product', detail: 'A × B -> Perpendicular vector with magnitude |A||B| sin(θ)'),
              ],
            ),
            MindMapNode(
              id: 'planes_lines',
              label: 'Planes & Lines in R³',
              detail: 'Equations of 3D loci',
              children: [
                MindMapNode(id: 'plane_eq', label: 'Vector Plane', detail: 'r⃗ · n̂ = d or Ax + By + Cz + D = 0'),
                MindMapNode(id: 'line_eq', label: 'Symmetric Line', detail: '(x-x₁)/a = (y-y₁)/b = (z-z₁)/c = λ'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_cybersecurity',
        title: 'Cybersecurity & Network Defense',
        subject: 'Computer Science',
        gradeLevel: 'Class 12',
        themeIndex: 2, // Sage
        rootNode: MindMapNode(
          id: 'root_sec',
          label: 'Information Security',
          detail: 'Defensive computing & network integrity',
          children: [
            MindMapNode(
              id: 'cia',
              label: 'CIA Triad',
              detail: 'Core pillars of information assurance',
              children: [
                MindMapNode(id: 'conf', label: 'Confidentiality', detail: 'Only authorized parties access data (Encryption)'),
                MindMapNode(id: 'integ', label: 'Integrity', detail: 'Data cannot be tampered with undetected (Hashing/HMAC)'),
                MindMapNode(id: 'avail', label: 'Availability', detail: 'Systems remain operational under load (Redundancy, DDoS defense)'),
              ],
            ),
            MindMapNode(
              id: 'crypto',
              label: 'Cryptography',
              detail: 'Mathematical ciphers and key exchanges',
              children: [
                MindMapNode(id: 'symm', label: 'Symmetric', detail: 'AES-256 (single shared key, fast)'),
                MindMapNode(id: 'asymm', label: 'Asymmetric', detail: 'RSA, ECC (Public/Private key pairs)'),
              ],
            ),
            MindMapNode(
              id: 'defense',
              label: 'Network Defense',
              detail: 'Perimeter and endpoint controls',
              children: [
                MindMapNode(id: 'firewall', label: 'Firewalls & WAF', detail: 'Stateful packet inspection & HTTP filtering'),
                MindMapNode(id: 'zero_trust', label: 'Zero Trust Architecture', detail: 'Never trust, always verify every request'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_electrostatics',
        title: 'Electrostatics & Gauss’s Law',
        subject: 'Physics',
        gradeLevel: 'Class 12',
        themeIndex: 0, // Teal
        rootNode: MindMapNode(
          id: 'root_elec',
          label: 'Electrostatic Fields',
          detail: 'Stationary charge interactions and potentials',
          children: [
            MindMapNode(
              id: 'coulomb',
              label: 'Coulomb’s Force Law',
              detail: 'Inverse square electrostatic force',
              children: [
                MindMapNode(id: 'c_formula', label: 'F = k·|q₁q₂| / r²', detail: 'k = 1/(4πε₀) ≈ 8.99 × 10⁹ N·m²/C²'),
                MindMapNode(id: 'superposition', label: 'Superposition', detail: 'Net vector sum of discrete forces'),
              ],
            ),
            MindMapNode(
              id: 'gauss',
              label: 'Gauss’s Law & Flux',
              detail: 'Total electric flux through closed Gaussian surface',
              children: [
                MindMapNode(id: 'flux_def', label: 'Flux Φ = ∮ E · dA', detail: 'Total surface field divergence'),
                MindMapNode(id: 'gauss_eq', label: 'Φ_net = Q_enclosed / ε₀', detail: 'Directly yields field of spheres, cylinders, sheets'),
              ],
            ),
            MindMapNode(
              id: 'capacitance',
              label: 'Capacitance & Dielectrics',
              detail: 'Charge storage capacity',
              children: [
                MindMapNode(id: 'cap_formula', label: 'C = ε₀A / d', detail: 'Parallel plate capacitor with dielectric κ'),
                MindMapNode(id: 'cap_energy', label: 'Stored Energy U = ½CV²', detail: 'Electrostatic field energy density'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_calculus_diff',
        title: 'Differential Calculus & Derivatives',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        rootNode: MindMapNode(
          id: 'root_calc',
          label: 'Differential Calculus',
          detail: 'Instantaneous rates of change & curvature',
          children: [
            MindMapNode(
              id: 'rules',
              label: 'Derivative Rules',
              detail: 'Standard operator mechanics',
              children: [
                MindMapNode(id: 'power_r', label: 'Power Rule: d/dx [xⁿ] = n·xⁿ⁻¹', detail: 'Fundamental polynomial derivative'),
                MindMapNode(id: 'product_r', label: 'Product Rule: (uv)′ = u′v + uv′', detail: 'Leibniz product differentiation'),
                MindMapNode(id: 'chain_r', label: 'Chain Rule: dy/dx = (dy/du)(du/dx)', detail: 'Composite function differentiation'),
              ],
            ),
            MindMapNode(
              id: 'applications',
              label: 'Applications of Derivatives',
              detail: 'Geometric & physical optimization',
              children: [
                MindMapNode(id: 'tangents', label: 'Tangents & Normals', detail: 'Slope m = f′(x₀) at contact point'),
                MindMapNode(id: 'extrema', label: 'Maxima & Minima', detail: 'Critical points f′(c) = 0; 2nd derivative concavity'),
              ],
            ),
          ],
        ),
      ),

      // === CLASS 11 ===
      const MindMapDeck(
        id: 'mm_thermodynamics',
        title: 'Thermodynamics & Kinetic Theory',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        rootNode: MindMapNode(
          id: 'root_thermo',
          label: 'Thermal Physics',
          detail: 'Heat, Work, Energy & Entropy',
          children: [
            MindMapNode(
              id: 'laws',
              label: 'Thermodynamic Laws',
              detail: 'Fundamental rules governing energy exchange',
              children: [
                MindMapNode(id: 'law0', label: 'Zeroth Law', detail: 'Thermal equilibrium defines temperature concept'),
                MindMapNode(id: 'law1', label: 'First Law (ΔU = Q - W)', detail: 'Conservation of energy in thermodynamic systems'),
                MindMapNode(id: 'law2', label: 'Second Law & Entropy', detail: 'Entropy of isolated system never decreases'),
              ],
            ),
            MindMapNode(
              id: 'processes',
              label: 'Quasi-Static Processes',
              detail: 'State transformations in ideal gases',
              children: [
                MindMapNode(id: 'isothermal', label: 'Isothermal (T = const)', detail: 'ΔU = 0, Q = W = nRT ln(V₂/V₁)'),
                MindMapNode(id: 'adiabatic', label: 'Adiabatic (Q = 0)', detail: 'PV^γ = constant, zero heat transfer'),
                MindMapNode(id: 'isochoric', label: 'Isochoric (V = const)', detail: 'W = 0, ΔU = Q = nCvΔT'),
              ],
            ),
            MindMapNode(
              id: 'engines',
              label: 'Heat Engines & Carnot',
              detail: 'Maximum theoretical thermal efficiency',
              children: [
                MindMapNode(id: 'carnot', label: 'Carnot Efficiency', detail: 'η = 1 - (T_cold / T_hot)'),
                MindMapNode(id: 'fridge', label: 'Refrigerators & COP', detail: 'Coefficient of Performance β = Q_cold / W'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_work_energy',
        title: 'Work, Energy & Power Dynamics',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        rootNode: MindMapNode(
          id: 'root_work',
          label: 'Work & Energy Principles',
          detail: 'Mechanical work and kinetic-potential transitions',
          children: [
            MindMapNode(
              id: 'work_def',
              label: 'Work W = F⃗ · s⃗ = F·s·cos(θ)',
              detail: 'Scalar product of force along displacement',
              children: [
                MindMapNode(id: 'w_pos', label: 'Positive Work', detail: 'Force in direction of displacement (θ < 90°)'),
                MindMapNode(id: 'w_neg', label: 'Negative Work (Friction)', detail: 'Force opposes displacement (θ = 180°)'),
              ],
            ),
            MindMapNode(
              id: 'wet',
              label: 'Work-Energy Theorem',
              detail: 'W_net = ΔK = ½mv₂² - ½mv₁²',
              children: [
                MindMapNode(id: 'wet_var', label: 'Variable Force Work', detail: 'W = ∫ F(x) dx between limits'),
              ],
            ),
            MindMapNode(
              id: 'power_eff',
              label: 'Power & Collisions',
              detail: 'Rate of energy transfer and impact conservation',
              children: [
                MindMapNode(id: 'power_eq', label: 'Power P = dW/dt = F⃗ · v⃗', detail: 'SI unit Watt (W) = J/s'),
                MindMapNode(id: 'collisions', label: 'Elastic vs Inelastic', detail: 'Momentum conserved in all; Kinetic energy only in elastic'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_chemical_bonding',
        title: 'Chemical Bonding & Molecular Shapes',
        subject: 'Chemistry',
        gradeLevel: 'Class 11',
        themeIndex: 2, // Sage
        rootNode: MindMapNode(
          id: 'root_bond',
          label: 'Chemical Bonding',
          detail: 'Intramolecular attractions creating stable molecules',
          children: [
            MindMapNode(
              id: 'vsepr',
              label: 'VSEPR Theory',
              detail: 'Valence Shell Electron Pair Repulsion determines 3D shape',
              children: [
                MindMapNode(id: 'v_rep', label: 'Repulsion Order', detail: 'Lone Pair-Lone Pair > Lone Pair-Bond Pair > Bond-Bond'),
                MindMapNode(id: 'v_shapes', label: 'Linear, Planar, Tetrahedral', detail: 'BeCl₂ (180°), BF₃ (120°), CH₄ (109.5°)'),
              ],
            ),
            MindMapNode(
              id: 'hybridization',
              label: 'Orbital Hybridization',
              detail: 'Intermixing of atomic orbitals',
              children: [
                MindMapNode(id: 'sp3', label: 'sp³ Hybridization', detail: '4 equivalent hybrid orbitals (e.g. Methane CH₄)'),
                MindMapNode(id: 'sp2', label: 'sp² Hybridization', detail: '3 planar orbitals + 1 unhybridized p orbital (Ethene)'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_trig_functions',
        title: 'Trigonometric Functions & Identities',
        subject: 'Mathematics',
        gradeLevel: 'Class 11',
        themeIndex: 1, // Lavender
        rootNode: MindMapNode(
          id: 'root_trig',
          label: 'Trigonometry & Unit Circle',
          detail: 'Periodic circular functions and angular relations',
          children: [
            MindMapNode(
              id: 'identities',
              label: 'Pythagorean Identities',
              detail: 'Fundamental relations on unit circle x² + y² = 1',
              children: [
                MindMapNode(id: 'sin_cos', label: 'sin²(x) + cos²(x) = 1', detail: 'Direct radius distance in unit circle'),
                MindMapNode(id: 'sec_tan', label: '1 + tan²(x) = sec²(x)', detail: 'Derived by dividing by cos²(x)'),
              ],
            ),
            MindMapNode(
              id: 'compound',
              label: 'Compound Angle Formulas',
              detail: 'Sum and difference expansions',
              children: [
                MindMapNode(id: 'sin_sum', label: 'sin(A ± B) = sinA·cosB ± cosA·sinB', detail: 'Sinusoidal angle addition'),
                MindMapNode(id: 'cos_sum', label: 'cos(A ± B) = cosA·cosB ∓ sinA·sinB', detail: 'Cosine angle addition with reversed sign'),
              ],
            ),
          ],
        ),
      ),

      // === CLASS 10 ===
      const MindMapDeck(
        id: 'mm_light_optics',
        title: 'Light - Reflection & Refraction',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        rootNode: MindMapNode(
          id: 'root_optics',
          label: 'Optics & Ray Theory',
          detail: 'Electromagnetic wave propagation and imaging',
          children: [
            MindMapNode(
              id: 'reflection',
              label: 'Spherical Mirrors',
              detail: 'Concave & Convex reflecting surfaces',
              children: [
                MindMapNode(id: 'm_formula', label: 'Mirror Formula', detail: '1/f = 1/v + 1/u with sign convention'),
                MindMapNode(id: 'm_mag', label: 'Magnification', detail: 'm = -v/u = h_image / h_object'),
                MindMapNode(id: 'concave', label: 'Concave Mirror', detail: 'Converging rays, real or virtual magnified images'),
              ],
            ),
            MindMapNode(
              id: 'refraction',
              label: 'Refraction & Snell’s Law',
              detail: 'Bending of light across medium boundaries',
              children: [
                MindMapNode(id: 'snell', label: 'Snell’s Law', detail: 'n₁ sin(θ₁) = n₂ sin(θ₂)'),
                MindMapNode(id: 'ri', label: 'Refractive Index', detail: 'n = c / v (speed of light in vacuum vs medium)'),
              ],
            ),
            MindMapNode(
              id: 'lenses',
              label: 'Spherical Lenses',
              detail: 'Convex converging & Concave diverging lenses',
              children: [
                MindMapNode(id: 'lens_formula', label: 'Lens Formula', detail: '1/f = 1/v - 1/u'),
                MindMapNode(id: 'lens_power', label: 'Lens Power', detail: 'P = 1/f (in meters), measured in Dioptres (D)'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_electricity_10',
        title: 'Electricity, Circuits & Ohm’s Law',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 0, // Teal
        rootNode: MindMapNode(
          id: 'root_elec10',
          label: 'Electric Current & Circuits',
          detail: 'Charge flow, potential difference and circuit networks',
          children: [
            MindMapNode(
              id: 'ohm',
              label: 'Ohm’s Law & Resistance',
              detail: 'V = I · R across constant temperature conductor',
              children: [
                MindMapNode(id: 'resistivity', label: 'Resistivity ρ', detail: 'R = ρ · (L / A), depends on material & temperature'),
                MindMapNode(id: 'factors', label: 'Resistance Factors', detail: 'Directly proportional to length; inverse to cross-section'),
              ],
            ),
            MindMapNode(
              id: 'comb',
              label: 'Resistor Combinations',
              detail: 'Series and parallel electrical circuits',
              children: [
                MindMapNode(id: 'series', label: 'Series: R_eq = R₁ + R₂ + R₃', detail: 'Current I constant; potential divides'),
                MindMapNode(id: 'parallel', label: 'Parallel: 1/R_eq = 1/R₁ + 1/R₂', detail: 'Potential V constant; current divides'),
              ],
            ),
            MindMapNode(
              id: 'power',
              label: 'Joule’s Heating & Power',
              detail: 'H = I²Rt thermal energy generation',
              children: [
                MindMapNode(id: 'p_formula', label: 'Electric Power P = VI = I²R = V²/R', detail: 'SI unit Watt (W); 1 kWh = 3.6 × 10⁶ J'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_chemical_reactions',
        title: 'Chemical Reactions & Equations',
        subject: 'Chemistry',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        rootNode: MindMapNode(
          id: 'root_reactions',
          label: 'Chemical Transformations',
          detail: 'Bond breaking, bond making & stoichiometry',
          children: [
            MindMapNode(
              id: 'types',
              label: 'Reaction Types',
              detail: 'Classifying chemical changes',
              children: [
                MindMapNode(id: 'comb_r', label: 'Combination', detail: 'A + B ⟶ AB (Exothermic, e.g. Quicklime + Water)'),
                MindMapNode(id: 'decomp', label: 'Decomposition', detail: 'AB ⟶ A + B (Requires heat, light, or electricity)'),
                MindMapNode(id: 'displace', label: 'Displacement', detail: 'More reactive metal replaces less reactive metal (Fe + CuSO₄)'),
              ],
            ),
            MindMapNode(
              id: 'redox',
              label: 'Redox Phenomena',
              detail: 'Simultaneous oxidation and reduction',
              children: [
                MindMapNode(id: 'ox_red', label: 'Electron / Oxygen Exchange', detail: 'Oxidation = Gain of O / Loss of e⁻; Reduction = Loss of O / Gain of e⁻'),
                MindMapNode(id: 'corrosion', label: 'Corrosion & Rancidity', detail: 'Slow oxidation of metals and unsaturated fatty foods'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_quadratic_ap',
        title: 'Quadratic Equations & Progressions',
        subject: 'Mathematics',
        gradeLevel: 'Class 10',
        themeIndex: 1, // Lavender
        rootNode: MindMapNode(
          id: 'root_quad_ap',
          label: 'Algebra & Sequences',
          detail: '2nd degree equations and arithmetic patterns',
          children: [
            MindMapNode(
              id: 'quad_core',
              label: 'Quadratic Form ax² + bx + c = 0',
              detail: 'Standard algebraic polynomial',
              children: [
                MindMapNode(id: 'q_formula', label: 'Quadratic Formula', detail: 'x = (-b ± √(b² - 4ac)) / (2a)'),
                MindMapNode(id: 'discrim', label: 'Discriminant D = b² - 4ac', detail: 'D > 0: 2 real distinct; D = 0: 2 equal; D < 0: imaginary'),
              ],
            ),
            MindMapNode(
              id: 'ap_core',
              label: 'Arithmetic Progression (AP)',
              detail: 'Sequence with constant difference d',
              children: [
                MindMapNode(id: 'nth_term', label: 'nth Term: aₙ = a + (n - 1)d', detail: 'Predicts any element in arithmetic sequence'),
                MindMapNode(id: 'sum_ap', label: 'Sum Sₙ = n/2 [2a + (n - 1)d]', detail: 'Accumulated total of first n terms'),
              ],
            ),
          ],
        ),
      ),

      // === CLASS 9 ===
      const MindMapDeck(
        id: 'mm_cell_biology',
        title: 'Cell: The Fundamental Unit of Life',
        subject: 'Biology',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        rootNode: MindMapNode(
          id: 'root_cell',
          label: 'Cellular Biology',
          detail: 'Basic structural and functional unit of life',
          children: [
            MindMapNode(
              id: 'boundary',
              label: 'Plasma Membrane & Wall',
              detail: 'Selective barriers protecting cellular contents',
              children: [
                MindMapNode(id: 'lipid', label: 'Phospholipid Bilayer', detail: 'Fluid mosaic structure regulating osmosis and diffusion'),
                MindMapNode(id: 'wall', label: 'Cell Wall (Plants)', detail: 'Rigid cellulose layer providing turgidity and shape'),
              ],
            ),
            MindMapNode(
              id: 'nucleus',
              label: 'Nucleus & Chromosomes',
              detail: 'Cellular control center storing genetic instructions',
              children: [
                MindMapNode(id: 'dna', label: 'DNA & Chromatin', detail: 'Contains hereditary genes encoded in double helix'),
                MindMapNode(id: 'nucleolus', label: 'Nucleolus', detail: 'Site of ribosome subunit assembly'),
              ],
            ),
            MindMapNode(
              id: 'organelles',
              label: 'Cytoplasmic Organelles',
              detail: 'Specialized metabolic factories',
              children: [
                MindMapNode(id: 'mito', label: 'Mitochondria', detail: 'Powerhouse synthesizing ATP through cellular respiration'),
                MindMapNode(id: 'chloro', label: 'Chloroplasts', detail: 'Plastids containing chlorophyll for plant photosynthesis'),
                MindMapNode(id: 'golgi', label: 'Golgi Apparatus', detail: 'Packages, modifies, and secretes cellular proteins'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_laws_of_motion',
        title: 'Newtonian Laws of Motion',
        subject: 'Physics',
        gradeLevel: 'Class 9',
        themeIndex: 0, // Teal
        rootNode: MindMapNode(
          id: 'root_newton',
          label: 'Newton’s Mechanics',
          detail: 'Forces, Inertia, Acceleration & Momentum',
          children: [
            MindMapNode(
              id: 'l1',
              label: '1st Law: Law of Inertia',
              detail: 'Objects maintain uniform motion unless acted on by external unbalanced force',
              children: [
                MindMapNode(id: 'mass_i', label: 'Mass as Measure of Inertia', detail: 'Heavier objects possess greater natural resistance to acceleration'),
              ],
            ),
            MindMapNode(
              id: 'l2',
              label: '2nd Law: F = m · a',
              detail: 'Force equals mass times acceleration',
              children: [
                MindMapNode(id: 'momentum_f', label: 'Momentum p = mv', detail: 'Rate of change of momentum Δp/Δt = Net Force F'),
                MindMapNode(id: 'units_n', label: 'SI Unit: Newton (N)', detail: '1 N = 1 kg·m/s²'),
              ],
            ),
            MindMapNode(
              id: 'l3',
              label: '3rd Law: Action & Reaction',
              detail: 'Equal and opposite collinear forces on separate bodies',
              children: [
                MindMapNode(id: 'recoil', label: 'Recoil & Rockets', detail: 'Direct manifestation of conservation of momentum'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_matter_surroundings',
        title: 'Matter in Our Surroundings',
        subject: 'Chemistry',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        rootNode: MindMapNode(
          id: 'root_matter',
          label: 'States of Matter',
          detail: 'Particulate nature, thermal energy and phase changes',
          children: [
            MindMapNode(
              id: 'states',
              label: 'Solid, Liquid & Gas',
              detail: 'Three primary physical aggregations',
              children: [
                MindMapNode(id: 'solid', label: 'Solid State', detail: 'Definite shape & volume; maximum intermolecular attraction'),
                MindMapNode(id: 'liquid', label: 'Liquid State', detail: 'Indefinite shape, definite volume; fluid flow'),
                MindMapNode(id: 'gas', label: 'Gaseous State', detail: 'High kinetic energy, maximum compressibility & diffusion'),
              ],
            ),
            MindMapNode(
              id: 'phase_change',
              label: 'Phase Transformations',
              detail: 'Temperature and pressure induced changes',
              children: [
                MindMapNode(id: 'latent', label: 'Latent Heat', detail: 'Hidden heat absorbed during fusion and vaporization without temperature rise'),
                MindMapNode(id: 'sublim', label: 'Sublimation', detail: 'Direct transition solid ⟷ gas (Camphor, Dry Ice, Ammonium Chloride)'),
              ],
            ),
          ],
        ),
      ),

      const MindMapDeck(
        id: 'mm_number_systems',
        title: 'Number Systems & Real Numbers',
        subject: 'Mathematics',
        gradeLevel: 'Class 9',
        themeIndex: 1, // Lavender
        rootNode: MindMapNode(
          id: 'root_numbers',
          label: 'Real Number Continuum',
          detail: 'Hierarchy of mathematical numbers on the real line',
          children: [
            MindMapNode(
              id: 'rationals',
              label: 'Rational Numbers (Q)',
              detail: 'Representable in p/q form where p, q ∈ Z and q ≠ 0',
              children: [
                MindMapNode(id: 'term_dec', label: 'Terminating Decimals', detail: 'Denominator prime factors are only 2 and 5'),
                MindMapNode(id: 'rep_dec', label: 'Non-Terminating Repeating', detail: 'Periodic repeating decimal blocks (e.g. 0.333...)'),
              ],
            ),
            MindMapNode(
              id: 'irrationals',
              label: 'Irrational Numbers',
              detail: 'Non-terminating, non-repeating decimals (e.g. √2, √3, π)',
              children: [
                MindMapNode(id: 'surds', label: 'Surds & Radicals', detail: 'Real roots of rational numbers that cannot be simplified'),
                MindMapNode(id: 'rationalize', label: 'Rationalizing Denominators', detail: 'Multiplying conjugate radical expressions'),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // SLIDE DECKS (4 per class = 16 rich slide decks)
  // -------------------------------------------------------------------------
  static List<SlideDeck> getSampleDecks() {
    return [
      // === CLASS 12 ===
      const SlideDeck(
        id: 'deck_3d_geometry',
        title: '3D Geometry & Space Coordinates',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'The 3D Coordinate Space',
            subtitle: 'Expanding beyond the flat Cartesian plane',
            bulletPoints: [
              'Defined by three mutually perpendicular axes: X, Y, and Z',
              'All three planes intersect at the Origin: (0, 0, 0)',
              'Space is partitioned into 8 distinct octants based on coordinate signs',
            ],
            codeOrFormula: 'Point P = (x, y, z)',
            keyTakeaway: 'Any point in physical reality requires 3 spatial coordinates to locate uniquely.',
          ),
          SlideItem(
            slideNumber: 2,
            title: '3D Distance Formula',
            subtitle: 'Generalizing the Pythagorean theorem',
            bulletPoints: [
              'Derived from applying Pythagoras twice across orthogonal planes',
              'Measures the direct Euclidean distance between two spatial points',
              'Works symmetrically across all octants without sign ambiguity',
            ],
            codeOrFormula: 'd = √((x₂ − x₁)² + (y₂ − y₁)² + (z₂ − z₁)²)',
            keyTakeaway: 'Extends 2D distance √(Δx² + Δy²) by simply accumulating the Δz² term.',
          ),
          SlideItem(
            slideNumber: 3,
            title: 'Equations of Planes & Spheres',
            subtitle: 'Standard geometric locus definitions',
            bulletPoints: [
              'A plane has a normal vector n⃗ = (A, B, C) perpendicular to its surface',
              'Linear equation Ax + By + Cz + D = 0 represents a 2D surface in 3D',
              'A sphere is the locus of points equidistant from a fixed center (h, k, l)',
            ],
            codeOrFormula: '(x − h)² + (y − k)² + (z − l)² = r²',
            keyTakeaway: 'A single linear equation in 3D forms a flat plane, while quadratic forms yield spheres.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_cybersecurity',
        title: 'Cybersecurity Fundamentals & CIA Triad',
        subject: 'Computer Science',
        gradeLevel: 'Class 12',
        themeIndex: 2, // Sage
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'The CIA Security Triad',
            subtitle: 'Foundational pillars of cybersecurity',
            bulletPoints: [
              'Confidentiality: Safeguarding data from unauthorized snooping and leaks',
              'Integrity: Ensuring data cannot be altered or tampered with in transit',
              'Availability: Guaranteeing continuous uptime and accessibility for legitimate users',
            ],
            codeOrFormula: 'Security Score = f(Confidentiality, Integrity, Availability)',
            keyTakeaway: 'Every defensive protocol and architecture balances these three core tenets.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Cryptography: Symmetric vs Asymmetric',
            subtitle: 'Mathematical encryption mechanisms',
            bulletPoints: [
              'Symmetric (AES-256): Single shared secret key; extremely fast for bulk data',
              'Asymmetric (RSA/ECC): Public key encrypts, private key decrypts',
              'Diffie-Hellman: Secure key exchange over an insecure communication channel',
            ],
            codeOrFormula: 'Ciphertext C = E_k(Message M)',
            keyTakeaway: 'Modern TLS/HTTPS combines asymmetric handshakes with symmetric session ciphers.',
          ),
          SlideItem(
            slideNumber: 3,
            title: 'Zero Trust & Modern Defense',
            subtitle: 'Perimeter-less architecture',
            bulletPoints: [
              'Never Trust, Always Verify: Explicit authentication for every single request',
              'Least Privilege Access: Restrict credentials to only what is strictly necessary',
              'Assume Breach: Minimize blast radius with strict network micro-segmentation',
            ],
            codeOrFormula: 'Auth(User, Device, Context) == true ∀ Request',
            keyTakeaway: 'Network perimeters are obsolete; identity is the modern security perimeter.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_electrostatics_12',
        title: 'Coulomb’s Law & Electric Potential',
        subject: 'Physics',
        gradeLevel: 'Class 12',
        themeIndex: 0, // Teal
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Coulomb’s Inverse Square Law',
            subtitle: 'Fundamental electrostatic force',
            bulletPoints: [
              'Force between two point charges is proportional to product of charges',
              'Inversely proportional to square of distance separating them',
              'Acts along the straight line joining the two charge centers',
            ],
            codeOrFormula: 'F = (1 / 4πε₀) · (|q₁q₂| / r²)',
            keyTakeaway: 'Electrostatic force is over 10³⁶ times stronger than gravitational attraction.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Gauss’s Law & Symmetry',
            subtitle: 'Calculating fields across closed surfaces',
            bulletPoints: [
              'Electric flux Φ is the surface integral of field E across area dA',
              'Net enclosed charge Q directly dictates total outward flux',
              'Simplifies field derivation for infinite wires, sheets, and spheres',
            ],
            codeOrFormula: '∮ E⃗ · dA⃗ = Q_enclosed / ε₀',
            keyTakeaway: 'Internal electric field inside any hollow charged conductor is identically zero.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_calculus_integrals_12',
        title: 'Integral Calculus & Fundamental Theorem',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Indefinite Integrals & Anti-derivatives',
            subtitle: 'Reversing the differential operator',
            bulletPoints: [
              'Integration accumulates continuous infinitesimal increments',
              'Every indefinite integral includes an arbitrary constant of integration C',
              'Integration by parts: derived from the differential product rule',
            ],
            codeOrFormula: '∫ u dv = uv − ∫ v du',
            keyTakeaway: 'Integration and differentiation are exact inverse operators of each other.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Definite Integrals & Area Under Curve',
            subtitle: 'The Fundamental Theorem of Calculus',
            bulletPoints: [
              'Computes net signed area bounded between curve and x-axis',
              'Evaluated by taking F(b) − F(a) where F′(x) = f(x)',
              'Symmetric odd functions integrate to exactly 0 over [-a, a]',
            ],
            codeOrFormula: '∫ₐᵇ f(x) dx = F(b) − F(a)',
            keyTakeaway: 'Transforms complex continuous accumulation problems into simple endpoint evaluation.',
          ),
        ],
      ),

      // === CLASS 11 ===
      const SlideDeck(
        id: 'deck_thermodynamics_11',
        title: 'Thermodynamics & Heat Engines',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'The First Law of Thermodynamics',
            subtitle: 'Conservation of thermal and mechanical energy',
            bulletPoints: [
              'Heat Q added to a system splits into internal energy ΔU and work W done',
              'Internal energy U of an ideal gas depends solely on its absolute temperature',
              'In cyclic processes, total change in internal energy ΔU is identically zero',
            ],
            codeOrFormula: 'ΔU = Q − W',
            keyTakeaway: 'Energy cannot be created or destroyed, only converted between heat and work.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Carnot Cycle & Maximum Efficiency',
            subtitle: 'Reversible theoretical limit',
            bulletPoints: [
              'Consists of two reversible isotherms and two reversible adiabatics',
              'No real engine operating between two reservoirs can exceed Carnot efficiency',
              'Efficiency increases as the cold sink temperature approaches 0 Kelvin',
            ],
            codeOrFormula: 'η = 1 − (T_cold / T_hot)',
            keyTakeaway: 'The 2nd Law forbids 100% thermal conversion into mechanical work.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_work_energy_11',
        title: 'Work-Energy Theorem & Conservation',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Work Done by Constant & Variable Forces',
            subtitle: 'Scalar dot product mechanics',
            bulletPoints: [
              'Work is the scalar product of force vector and displacement vector',
              'Zero work is done when force is perpendicular to motion (e.g. circular orbits)',
              'Area under a Force vs Position (F-x) graph represents total work done',
            ],
            codeOrFormula: 'W = ∫ F(x) dx = F · s · cos(θ)',
            keyTakeaway: 'Only the collinear component of force does physical work.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'The Work-Energy Theorem',
            subtitle: 'Linking net force directly to kinetic energy',
            bulletPoints: [
              'Net work done by all forces equals change in kinetic energy of particle',
              'Applies equally to conservative and non-conservative force fields',
              'Potential energy is defined solely for conservative forces: F = -dU/dx',
            ],
            codeOrFormula: 'W_net = ΔK = ½m(v₂² − v₁²)',
            keyTakeaway: 'Simplifies complex mechanical problems without integrating acceleration vectors.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_chemical_bonding_11',
        title: 'VSEPR Theory & Molecular Geometry',
        subject: 'Chemistry',
        gradeLevel: 'Class 11',
        themeIndex: 2, // Sage
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Electron Pair Repulsion (VSEPR)',
            subtitle: 'Predicting 3D molecular architecture',
            bulletPoints: [
              'Valence electron pairs around central atom arrange to minimize mutual repulsion',
              'Lone pairs occupy more spatial volume than bonded electron pairs',
              'Repulsion order: Lone-Lone > Lone-Bond > Bond-Bond',
            ],
            codeOrFormula: 'Steric Number = (Bonded Atoms) + (Lone Pairs)',
            keyTakeaway: 'Lone pairs compress ideal bond angles (e.g. H₂O angle is 104.5° instead of 109.5°).',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Hybridization: sp, sp², and sp³',
            subtitle: 'Orbital blending for directional bonding',
            bulletPoints: [
              'Linear (sp): 180° bond angle with two unhybridized p orbitals (Acetylene)',
              'Trigonal Planar (sp²): 120° bond angle with one unhybridized p orbital (Ethylene)',
              'Tetrahedral (sp³): 109.5° bond angle forming 4 equivalent sigma bonds (Methane)',
            ],
            codeOrFormula: 'Overlap: σ-bond (axial) vs π-bond (lateral)',
            keyTakeaway: 'Hybridization explains the observed equivalent bond lengths and spatial symmetry.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_trig_functions_11',
        title: 'Trigonometric Identities & Angle Sums',
        subject: 'Mathematics',
        gradeLevel: 'Class 11',
        themeIndex: 1, // Lavender
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Compound Angle Theorems',
            subtitle: 'Expanding sine and cosine sums',
            bulletPoints: [
              'sin(A + B) = sinA·cosB + cosA·sinB',
              'cos(A + B) = cosA·cosB − sinA·sinB (Note the negative sign)',
              'tan(A + B) = (tanA + tanB) / (1 − tanA·tanB)',
            ],
            codeOrFormula: 'sin(2θ) = 2 sin(θ) cos(θ)',
            keyTakeaway: 'Double and half-angle formulas form the backbone of analytical calculus integration.',
          ),
        ],
      ),

      // === CLASS 10 ===
      const SlideDeck(
        id: 'deck_optics_10',
        title: 'Optics: Mirrors, Lenses & Snell’s Law',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Reflection in Spherical Mirrors',
            subtitle: 'Concave and convex surfaces',
            bulletPoints: [
              'Concave mirrors converge light; form real inverted or virtual magnified images',
              'Convex mirrors always produce virtual, erect, and diminished images',
              'Mirror formula uses Cartesian sign convention with pole at origin',
            ],
            codeOrFormula: '1/f = 1/v + 1/u',
            keyTakeaway: 'Rear-view vehicle mirrors use convex curvature to provide a wide field of view.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Refraction & Snell’s Law',
            subtitle: 'Speed change across optical boundaries',
            bulletPoints: [
              'Light bends towards the normal when entering a denser optical medium',
              'Ratio of sine of incidence to sine of refraction is constant',
              'Absolute refractive index n = c / v measures optical deceleration',
            ],
            codeOrFormula: 'n₁ sin(θ₁) = n₂ sin(θ₂)',
            keyTakeaway: 'Snell’s law governs eyeglasses, microscopes, and natural phenomena like atmospheric twinkling.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_electricity_10',
        title: 'Current Electricity & Circuit Power',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 0, // Teal
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Ohm’s Law & Resistance Factors',
            subtitle: 'Potential difference driving electron flow',
            bulletPoints: [
              'Current is directly proportional to potential difference across conductor at constant temp',
              'Resistance R depends on material resistivity ρ, length L, and cross-section A',
              'Thicker wires have lower resistance; longer wires have higher resistance',
            ],
            codeOrFormula: 'V = I · R  and  R = ρ · (L / A)',
            keyTakeaway: 'Ohm’s law establishes the fundamental linear impedance relationship in circuits.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Electric Power & Joule’s Heating',
            subtitle: 'Energy dissipation in resistive networks',
            bulletPoints: [
              'Heat generated is proportional to square of current, resistance, and time',
              'Electric power P is the rate of electrical energy consumption in Watts',
              'Commercial unit of energy is the kilowatt-hour (kWh): 1 kWh = 3.6 × 10⁶ J',
            ],
            codeOrFormula: 'H = I² · R · t  and  P = V · I = I²R = V²/R',
            keyTakeaway: 'High-voltage grid transmission minimizes I²R heating losses across long distances.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_chemical_reactions_10',
        title: 'Chemical Reactions & Balancing Stoichiometry',
        subject: 'Chemistry',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Balancing Chemical Equations',
            subtitle: 'Law of Conservation of Mass',
            bulletPoints: [
              'Total mass of reactants must equal total mass of products in chemical change',
              'Number of atoms of each element remains identical on both sides of equation',
              'Balanced using integer stoichiometric coefficients, never altering chemical formulas',
            ],
            codeOrFormula: '2 H₂ (g) + O₂ (g) ⟶ 2 H₂O (l)',
            keyTakeaway: 'Chemical equations must be balanced to reflect atomic mass conservation.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_quadratic_ap_10',
        title: 'Quadratic Equations & Arithmetic Sequences',
        subject: 'Mathematics',
        gradeLevel: 'Class 10',
        themeIndex: 1, // Lavender
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Solving Quadratic Equations',
            subtitle: 'Discriminant and root nature',
            bulletPoints: [
              'Standard form ax² + bx + c = 0 where a ≠ 0',
              'Discriminant D = b² − 4ac governs the nature of roots',
              'If D > 0: two distinct real roots; D = 0: two equal roots; D < 0: no real roots',
            ],
            codeOrFormula: 'x = (−b ± √(b² − 4ac)) / (2a)',
            keyTakeaway: 'Parabolic trajectories in physics map directly to quadratic equations.',
          ),
        ],
      ),

      // === CLASS 9 ===
      const SlideDeck(
        id: 'deck_matter_surroundings_9',
        title: 'Matter in Our Surroundings & Latent Heat',
        subject: 'Chemistry',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Physical Nature of Matter',
            subtitle: 'Particulate theory and kinetic energy',
            bulletPoints: [
              'Matter is composed of tiny continuous particles with space between them',
              'Particles possess kinetic energy that increases directly with temperature',
              'Particles diffuse spontaneously from high concentration to low concentration',
            ],
            codeOrFormula: 'Kinetic Energy E_k ∝ Absolute Temperature T',
            keyTakeaway: 'All physical properties of solids, liquids, and gases arise from intermolecular spacing and forces.',
          ),
          SlideItem(
            slideNumber: 2,
            title: 'Evaporation & Latent Heat',
            subtitle: 'Surface phenomenon causing cooling',
            bulletPoints: [
              'Evaporation occurs at any temperature below the liquid boiling point',
              'Rate increases with surface area, temperature, and wind speed; decreases with humidity',
              'Latent Heat of Vaporization absorbs thermal energy, producing a distinct cooling effect',
            ],
            codeOrFormula: 'Heat absorbed Q = m · L_vap',
            keyTakeaway: 'Sweating and earthen pots rely directly on evaporative cooling to regulate temperature.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_kinematics_9',
        title: 'Kinematics & Equations of Motion',
        subject: 'Physics',
        gradeLevel: 'Class 9',
        themeIndex: 0, // Teal
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'The Three Equations of Motion',
            subtitle: 'Uniformly accelerated linear kinematics',
            bulletPoints: [
              'Velocity-time relation: v = u + at',
              'Position-time relation: s = ut + ½at²',
              'Position-velocity relation: v² = u² + 2as',
            ],
            codeOrFormula: 'v² = u² + 2as  (where a is constant acceleration)',
            keyTakeaway: 'These three formulas predict position and velocity of any uniformly accelerated body.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_cell_biology_9',
        title: 'Cell Biology & Organelle Functions',
        subject: 'Biology',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Cell Organelle Architecture',
            subtitle: 'Specialized microscopic compartments',
            bulletPoints: [
              'Plasma membrane: Selectively permeable phospholipid bilayer',
              'Mitochondria: Double-membraned powerhouse producing ATP via respiration',
              'Ribosomes & ER: Protein assembly line and lipid synthesis',
            ],
            codeOrFormula: 'Glucose + O₂ ⟶ CO₂ + H₂O + ATP',
            keyTakeaway: 'The cell is the basic structural and functional unit of all living organisms.',
          ),
        ],
      ),

      const SlideDeck(
        id: 'deck_number_systems_9',
        title: 'Real Numbers & Decimal Expansions',
        subject: 'Mathematics',
        gradeLevel: 'Class 9',
        themeIndex: 1, // Lavender
        slides: [
          SlideItem(
            slideNumber: 1,
            title: 'Rational vs Irrational Decimals',
            subtitle: 'The Real Number Line',
            bulletPoints: [
              'Rational numbers have terminating or non-terminating recurring decimal expansions',
              'Irrational numbers have non-terminating, non-recurring decimal expansions (e.g. √2, π)',
              'Every real number is represented by a unique point on the real number line',
            ],
            codeOrFormula: 'Real Numbers ℝ = Rationals ℚ ∪ Irrationals',
            keyTakeaway: 'Between any two rational numbers on the number line, there exist infinitely many real numbers.',
          ),
        ],
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // FLASHCARD DECKS (4 per class = 16 decks with 5-6 cards each = 90+ cards)
  // -------------------------------------------------------------------------
  static List<FlashcardDeck> getSampleFlashcards() {
    return [
      // === CLASS 12 ===
      FlashcardDeck(
        id: 'fc_math',
        title: '3D Geometry & Space Vectors',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        cards: [
          FlashcardItem(
            id: 'fc_m1',
            frontQuestion: 'What is the 3D distance formula between P(x₁, y₁, z₁) and Q(x₂, y₂, z₂)?',
            backAnswer: 'd = √((x₂ − x₁)² + (y₂ − y₁)² + (z₂ − z₁)²)',
            category: 'Geometry',
            hint: 'Think of 2D distance and add the Z component squared.',
          ),
          FlashcardItem(
            id: 'fc_m2',
            frontQuestion: 'What is the cross product formula |A × B| for two 3D vectors?',
            backAnswer: '|A × B| = |A| |B| sin(θ) n̂, pointing perpendicular to both A and B.',
            category: 'Vectors',
            hint: 'Uses sine instead of cosine, resulting in a vector quantity.',
          ),
          FlashcardItem(
            id: 'fc_m3',
            frontQuestion: 'What is the general vector equation of a plane in 3D?',
            backAnswer: 'r⃗ · n̂ = d, where n̂ is the unit normal vector and d is the perpendicular distance from origin.',
            category: 'Planes',
            hint: 'Dot product of position vector with normal vector.',
          ),
          FlashcardItem(
            id: 'fc_m4',
            frontQuestion: 'What are direction cosines (l, m, n) of a vector in 3D?',
            backAnswer: 'l = cos(α), m = cos(β), n = cos(γ), where l² + m² + n² = 1.',
            category: 'Vectors',
            hint: 'Angles α, β, γ made with the X, Y, Z axes.',
          ),
          FlashcardItem(
            id: 'fc_m5',
            frontQuestion: 'What is the condition for two vectors A and B to be perpendicular in 3D?',
            backAnswer: 'Their dot product must equal zero: A · B = A_x B_x + A_y B_y + A_z B_z = 0.',
            category: 'Vectors',
            hint: 'cos(90°) = 0.',
          ),
          FlashcardItem(
            id: 'fc_m6',
            frontQuestion: 'What is the formula for the angle θ between two planes with normals n₁ and n₂?',
            backAnswer: 'cos(θ) = |n₁ · n₂| / (|n₁| |n₂|)',
            category: 'Planes',
            hint: 'Angle between planes equals the angle between their normal vectors.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_cybersecurity_12',
        title: 'Cybersecurity & Cryptography',
        subject: 'Computer Science',
        gradeLevel: 'Class 12',
        themeIndex: 2, // Sage
        cards: [
          FlashcardItem(
            id: 'fc_cs1',
            frontQuestion: 'What are the three core pillars of the CIA security triad?',
            backAnswer: 'Confidentiality (preventing unauthorized access), Integrity (preventing tampering), and Availability (system uptime).',
            category: 'Security',
            hint: 'Three letters: C, I, A.',
          ),
          FlashcardItem(
            id: 'fc_cs2',
            frontQuestion: 'What is the fundamental difference between Symmetric and Asymmetric encryption?',
            backAnswer: 'Symmetric uses a single shared secret key (e.g. AES); Asymmetric uses a public/private key pair (e.g. RSA).',
            category: 'Cryptography',
            hint: 'One key vs Two mathematically linked keys.',
          ),
          FlashcardItem(
            id: 'fc_cs3',
            frontQuestion: 'What is a cryptographic hash function and name two key properties?',
            backAnswer: 'A one-way deterministic algorithm (e.g. SHA-256). Properties: Pre-image resistance (cannot reverse) and collision resistance.',
            category: 'Hashing',
            hint: 'Fixed size output regardless of input size; cannot be undone.',
          ),
          FlashcardItem(
            id: 'fc_cs4',
            frontQuestion: 'What is the core principle of Zero Trust Architecture?',
            backAnswer: 'Never trust, always verify. Every request is fully authenticated, authorized, and encrypted before granting access.',
            category: 'Architecture',
            hint: 'Assumes the network is already hostile.',
          ),
          FlashcardItem(
            id: 'fc_cs5',
            frontQuestion: 'What is a Man-in-the-Middle (MITM) attack and how is it prevented?',
            backAnswer: 'An attacker intercepts communication between two parties. Prevented via digital certificates and TLS encryption.',
            category: 'Network Attacks',
            hint: 'HTTPS with verified CA certificates prevents it.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_electrostatics_12',
        title: 'Electrostatics & Gauss’s Law',
        subject: 'Physics',
        gradeLevel: 'Class 12',
        themeIndex: 0, // Teal
        cards: [
          FlashcardItem(
            id: 'fc_el1',
            frontQuestion: 'State Coulomb’s Law for electrostatic force.',
            backAnswer: 'F = (1 / 4πε₀) · (|q₁q₂| / r²), directed along the line joining the two charges.',
            category: 'Forces',
            hint: 'Inverse square law proportional to charge product.',
          ),
          FlashcardItem(
            id: 'fc_el2',
            frontQuestion: 'State Gauss’s Law for electrostatics in mathematical form.',
            backAnswer: 'Φ = ∮ E⃗ · dA⃗ = Q_enclosed / ε₀',
            category: 'Flux',
            hint: 'Net flux through a closed surface equals enclosed charge over permittivity.',
          ),
          FlashcardItem(
            id: 'fc_el3',
            frontQuestion: 'What is the electric field inside a hollow charged conductor in electrostatic equilibrium?',
            backAnswer: 'E = 0 everywhere inside the cavity of the conductor.',
            category: 'Conductors',
            hint: 'Electrostatic shielding principle.',
          ),
          FlashcardItem(
            id: 'fc_el4',
            frontQuestion: 'What is the capacitance formula for a parallel plate capacitor?',
            backAnswer: 'C = (κ · ε₀ · A) / d, where κ is the dielectric constant, A is plate area, and d is separation.',
            category: 'Capacitance',
            hint: 'Increases with area, decreases with plate distance.',
          ),
          FlashcardItem(
            id: 'fc_el5',
            frontQuestion: 'What is the energy stored in a charged capacitor?',
            backAnswer: 'U = ½CV² = ½QV = Q² / (2C)',
            category: 'Energy',
            hint: 'Similar to kinetic energy formula with C and V.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_calculus_12',
        title: 'Calculus: Derivatives & Integrals',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        cards: [
          FlashcardItem(
            id: 'fc_c1',
            frontQuestion: 'What is the derivative of e^(kx) with respect to x?',
            backAnswer: 'd/dx [e^(kx)] = k · e^(kx)',
            category: 'Calculus',
            hint: 'Chain rule multiplies by constant k.',
          ),
          FlashcardItem(
            id: 'fc_c2',
            frontQuestion: 'What is the formula for integration by parts?',
            backAnswer: '∫ u dv = u·v − ∫ v du',
            category: 'Calculus',
            hint: 'ILATE rule helps choose u.',
          ),
          FlashcardItem(
            id: 'fc_c3',
            frontQuestion: 'What is the derivative of ln(x)?',
            backAnswer: 'd/dx [ln(x)] = 1 / x, for x > 0.',
            category: 'Calculus',
            hint: 'Reciprocal of x.',
          ),
          FlashcardItem(
            id: 'fc_c4',
            frontQuestion: 'What is the integral ∫ (1 / (1 + x²)) dx?',
            backAnswer: 'arctan(x) + C (or tan⁻¹(x) + C)',
            category: 'Calculus',
            hint: 'Inverse trigonometric function.',
          ),
          FlashcardItem(
            id: 'fc_c5',
            frontQuestion: 'What is L’Hôpital’s Rule for limits?',
            backAnswer: 'If lim f(x)/g(x) yields 0/0 or ∞/∞, then lim f(x)/g(x) = lim f′(x)/g′(x).',
            category: 'Calculus',
            hint: 'Differentiate numerator and denominator separately.',
          ),
        ],
      ),

      // === CLASS 11 ===
      FlashcardDeck(
        id: 'fc_physics',
        title: 'Physics Core Laws & Thermodynamics',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        cards: [
          FlashcardItem(
            id: 'fc_p1',
            frontQuestion: 'State the First Law of Thermodynamics.',
            backAnswer: 'ΔU = Q − W (Change in internal energy equals heat added minus work done by system).',
            category: 'Thermodynamics',
            hint: 'Conservation of energy applied to thermal systems.',
          ),
          FlashcardItem(
            id: 'fc_p2',
            frontQuestion: 'What is the maximum theoretical efficiency of a Carnot heat engine?',
            backAnswer: 'η = 1 − (T_cold / T_hot) where temperatures are in Kelvin.',
            category: 'Thermodynamics',
            hint: 'Depends only on absolute temperatures of hot and cold reservoirs.',
          ),
          FlashcardItem(
            id: 'fc_p3',
            frontQuestion: 'What is the horizontal range formula for projectile motion?',
            backAnswer: 'R = (u² sin(2θ)) / g, with maximum range achieved at θ = 45°.',
            category: 'Kinematics',
            hint: 'Features sin(2θ) in the numerator.',
          ),
          FlashcardItem(
            id: 'fc_p4',
            frontQuestion: 'What is the work-energy theorem formula?',
            backAnswer: 'W_net = ΔK = ½m(v₂² − v₁²)',
            category: 'Mechanics',
            hint: 'Net work equals change in kinetic energy.',
          ),
          FlashcardItem(
            id: 'fc_p5',
            frontQuestion: 'What is the equation for an adiabatic process of an ideal gas?',
            backAnswer: 'P · V^γ = constant, where γ = C_p / C_v is the heat capacity ratio.',
            category: 'Thermodynamics',
            hint: 'Q = 0, no heat enters or leaves.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_chemistry_bonding_11',
        title: 'Chemical Bonding & Hybridization',
        subject: 'Chemistry',
        gradeLevel: 'Class 11',
        themeIndex: 2, // Sage
        cards: [
          FlashcardItem(
            id: 'fc_cb1',
            frontQuestion: 'What is the molecular shape and bond angle of methane (CH₄)?',
            backAnswer: 'Tetrahedral geometry with a bond angle of 109.5° (sp³ hybridization).',
            category: 'VSEPR',
            hint: '4 equivalent sigma bonds.',
          ),
          FlashcardItem(
            id: 'fc_cb2',
            frontQuestion: 'Why is the bond angle of water (H₂O) 104.5° instead of 109.5°?',
            backAnswer: 'Because water has 2 lone pairs on oxygen, which exert greater repulsion than bonding pairs, compressing the H-O-H angle.',
            category: 'VSEPR',
            hint: 'Lone pair - lone pair repulsion is strongest.',
          ),
          FlashcardItem(
            id: 'fc_cb3',
            frontQuestion: 'What is the hybridization and bond angle in ethylene (C₂H₄)?',
            backAnswer: 'sp² hybridization with a trigonal planar geometry and 120° bond angle.',
            category: 'Hybridization',
            hint: 'Contains 1 sigma bond and 1 pi bond between carbons.',
          ),
          FlashcardItem(
            id: 'fc_cb4',
            frontQuestion: 'What is dipole moment (μ) and its SI unit?',
            backAnswer: 'μ = q · d (product of charge and separation distance). SI unit is Coulomb-meter (C·m); often measured in Debye (D).',
            category: 'Bonding',
            hint: 'Vector quantity measuring molecular polarity.',
          ),
          FlashcardItem(
            id: 'fc_cb5',
            frontQuestion: 'What is the difference between a sigma (σ) and pi (π) covalent bond?',
            backAnswer: 'Sigma bonds form by head-on (axial) orbital overlap and are stronger; Pi bonds form by lateral (sideways) overlap of unhybridized p orbitals.',
            category: 'Bonding',
            hint: 'Axial vs Sideways overlap.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_math_trig_11',
        title: 'Trigonometry & Conic Sections',
        subject: 'Mathematics',
        gradeLevel: 'Class 11',
        themeIndex: 1, // Lavender
        cards: [
          FlashcardItem(
            id: 'fc_mt1',
            frontQuestion: 'What is the expansion of cos(A + B)?',
            backAnswer: 'cos(A + B) = cosA·cosB − sinA·sinB',
            category: 'Trigonometry',
            hint: 'Notice the minus sign in the cosine sum formula.',
          ),
          FlashcardItem(
            id: 'fc_mt2',
            frontQuestion: 'What is the standard equation of an ellipse centered at the origin?',
            backAnswer: '(x² / a²) + (y² / b²) = 1, where eccentricity e = √(1 − b²/a²) < 1.',
            category: 'Conic Sections',
            hint: 'Sum of squares with differing denominators equals 1.',
          ),
          FlashcardItem(
            id: 'fc_mt3',
            frontQuestion: 'What is the fundamental limit: lim (x ⟶ 0) [sin(x) / x]?',
            backAnswer: 'lim (x ⟶ 0) [sin(x) / x] = 1, where x is measured in radians.',
            category: 'Limits',
            hint: 'Derived using the squeeze theorem on a unit circle.',
          ),
          FlashcardItem(
            id: 'fc_mt4',
            frontQuestion: 'What is the general equation of a parabola opening to the right?',
            backAnswer: 'y² = 4ax, with focus at (a, 0) and directrix x = −a.',
            category: 'Conic Sections',
            hint: 'Axis of symmetry is the X-axis.',
          ),
          FlashcardItem(
            id: 'fc_mt5',
            frontQuestion: 'What is the double angle formula for tan(2θ)?',
            backAnswer: 'tan(2θ) = (2 tan(θ)) / (1 − tan²(θ))',
            category: 'Trigonometry',
            hint: 'Ratio of 2 tan(θ) over 1 minus tan squared.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_waves_shm_11',
        title: 'Simple Harmonic Motion & Waves',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        cards: [
          FlashcardItem(
            id: 'fc_w1',
            frontQuestion: 'What is the defining condition for Simple Harmonic Motion (SHM)?',
            backAnswer: 'The restoring force is directly proportional to displacement and directed towards the equilibrium position: F = −k·x or a = −ω²·x.',
            category: 'SHM',
            hint: 'Acceleration is directly proportional to negative displacement.',
          ),
          FlashcardItem(
            id: 'fc_w2',
            frontQuestion: 'What is the time period of a simple pendulum of length L?',
            backAnswer: 'T = 2π √(L / g)',
            category: 'SHM',
            hint: 'Depends only on length and gravity, independent of mass.',
          ),
          FlashcardItem(
            id: 'fc_w3',
            frontQuestion: 'What is the wave speed formula linking wavelength and frequency?',
            backAnswer: 'v = f · λ (Speed equals frequency times wavelength).',
            category: 'Waves',
            hint: 'Distance traveled per cycle multiplied by cycles per second.',
          ),
          FlashcardItem(
            id: 'fc_w4',
            frontQuestion: 'What is the total energy of a particle executing SHM with amplitude A?',
            backAnswer: 'E_total = ½k·A² = ½m·ω²·A²',
            category: 'Energy',
            hint: 'Constant sum of kinetic and potential energies, proportional to A².',
          ),
        ],
      ),

      // === CLASS 10 ===
      FlashcardDeck(
        id: 'fc_class10_science',
        title: 'Class 10 Board Rapid Recall',
        subject: 'Science',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        cards: [
          FlashcardItem(
            id: 'fc_c10_1',
            frontQuestion: 'State Ohm’s Law and write its mathematical formula.',
            backAnswer: 'V = I · R. Potential difference across a conductor is directly proportional to current flowing through it at constant temperature.',
            category: 'Physics',
            hint: 'Relates voltage (V), current (I), and resistance (R).',
          ),
          FlashcardItem(
            id: 'fc_c10_2',
            frontQuestion: 'What is the mirror formula and Cartesian sign convention for focal length of a concave mirror?',
            backAnswer: '1/f = 1/v + 1/u. Focal length f is negative for concave mirrors and positive for convex mirrors.',
            category: 'Physics',
            hint: 'f is negative when the focus is in front of the reflecting surface.',
          ),
          FlashcardItem(
            id: 'fc_c10_3',
            frontQuestion: 'What is the pH of a neutral solution at 25°C, and what does pH stand for?',
            backAnswer: 'pH = 7 (Neutral). It stands for "potential of Hydrogen", measuring hydronium ion concentration: -log₁₀[H⁺].',
            category: 'Chemistry',
            hint: 'Scale ranges from 0 (strong acid) to 14 (strong base).',
          ),
          FlashcardItem(
            id: 'fc_c10_4',
            frontQuestion: 'What happens during a redox reaction in terms of electron transfer?',
            backAnswer: 'Oxidation is loss of electrons (OIL); Reduction is gain of electrons (RIG). Both happen simultaneously.',
            category: 'Chemistry',
            hint: 'OIL RIG mnemonic.',
          ),
          FlashcardItem(
            id: 'fc_c10_5',
            frontQuestion: 'What is the power of a lens having a focal length of +0.5 meters?',
            backAnswer: 'P = 1/f = 1 / (+0.5 m) = +2.0 Dioptres (D). It is a convex lens.',
            category: 'Physics',
            hint: 'Power is reciprocal of focal length in meters.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_electricity_circuits_10',
        title: 'Electricity & Circuit Formulas',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 0, // Teal
        cards: [
          FlashcardItem(
            id: 'fc_ec1',
            frontQuestion: 'What is the equivalent resistance of resistors in series vs parallel?',
            backAnswer: 'Series: R_eq = R₁ + R₂ + R₃; Parallel: 1/R_eq = 1/R₁ + 1/R₂ + 1/R₃.',
            category: 'Circuits',
            hint: 'Resistances add directly in series; add reciprocally in parallel.',
          ),
          FlashcardItem(
            id: 'fc_ec2',
            frontQuestion: 'State Joule’s Law of Heating in electrical circuits.',
            backAnswer: 'H = I² · R · t (Heat produced is directly proportional to square of current, resistance, and time).',
            category: 'Heating',
            hint: 'Notice that current is squared.',
          ),
          FlashcardItem(
            id: 'fc_ec3',
            frontQuestion: 'How many Joules are there in 1 kilowatt-hour (1 commercial unit of electricity)?',
            backAnswer: '1 kWh = 1,000 W × 3,600 s = 3.6 × 10⁶ Joules (3.6 MegaJoules).',
            category: 'Energy',
            hint: '1000 Watts times 3600 seconds.',
          ),
          FlashcardItem(
            id: 'fc_ec4',
            frontQuestion: 'What is an ammeter and how is it connected in an electrical circuit?',
            backAnswer: 'An ammeter measures electric current and is always connected in series; it has very low resistance.',
            category: 'Instruments',
            hint: 'Must be in series so all current flows through it.',
          ),
          FlashcardItem(
            id: 'fc_ec5',
            frontQuestion: 'What is a voltmeter and how is it connected in a circuit?',
            backAnswer: 'A voltmeter measures potential difference and is connected in parallel; it has very high resistance.',
            category: 'Instruments',
            hint: 'Connected across two points in parallel.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_acids_bases_10',
        title: 'Acids, Bases & Salts Mastery',
        subject: 'Chemistry',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        cards: [
          FlashcardItem(
            id: 'fc_ab1',
            frontQuestion: 'What gas is evolved when an acid reacts with an active metal?',
            backAnswer: 'Hydrogen gas (H₂), which burns with a characteristic pop sound when a burning splint is introduced.',
            category: 'Reactions',
            hint: 'Zn + H₂SO₄ ⟶ ZnSO₄ + H₂↑.',
          ),
          FlashcardItem(
            id: 'fc_ab2',
            frontQuestion: 'What is the chemical formula of Plaster of Paris and how is it prepared?',
            backAnswer: 'CaSO₄ · ½H₂O (Calcium sulphate hemihydrate). Prepared by heating gypsum (CaSO₄ · 2H₂O) at 373 K (100°C).',
            category: 'Salts',
            hint: 'Hemihydrate with half water of crystallization.',
          ),
          FlashcardItem(
            id: 'fc_ab3',
            frontQuestion: 'What is the chemical formula of Bleaching Powder?',
            backAnswer: 'CaOCl₂ (Calcium oxychloride), produced by reacting dry slaked lime with chlorine gas.',
            category: 'Salts',
            hint: 'Contains Calcium, Oxygen, and Chlorine.',
          ),
          FlashcardItem(
            id: 'fc_ab4',
            frontQuestion: 'What is the color change of blue litmus when dipped into an acidic solution?',
            backAnswer: 'Blue litmus turns RED in acidic solutions; red litmus turns BLUE in basic solutions.',
            category: 'Indicators',
            hint: 'Acids turn litmus red.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_math_algebra_10',
        title: 'Quadratic Equations & AP Formulas',
        subject: 'Mathematics',
        gradeLevel: 'Class 10',
        themeIndex: 1, // Lavender
        cards: [
          FlashcardItem(
            id: 'fc_ma1',
            frontQuestion: 'What is the quadratic formula to solve ax² + bx + c = 0?',
            backAnswer: 'x = (−b ± √(b² − 4ac)) / (2a)',
            category: 'Quadratics',
            hint: 'Sridharacharya’s formula.',
          ),
          FlashcardItem(
            id: 'fc_ma2',
            frontQuestion: 'What is the formula for the nth term of an Arithmetic Progression?',
            backAnswer: 'aₙ = a + (n − 1)d, where a is first term and d is common difference.',
            category: 'AP',
            hint: 'Add (n - 1) differences to first term.',
          ),
          FlashcardItem(
            id: 'fc_ma3',
            frontQuestion: 'What is the sum formula for the first n terms of an AP?',
            backAnswer: 'Sₙ = (n / 2) [2a + (n − 1)d] = (n / 2) [first term + last term].',
            category: 'AP',
            hint: 'n/2 times the sum of first and last terms.',
          ),
          FlashcardItem(
            id: 'fc_ma4',
            frontQuestion: 'What are the coordinates of the midpoint of line segment joining (x₁, y₁) and (x₂, y₂)?',
            backAnswer: 'M = ((x₁ + x₂) / 2, (y₁ + y₂) / 2)',
            category: 'Coordinate Geometry',
            hint: 'Average of x coordinates and average of y coordinates.',
          ),
          FlashcardItem(
            id: 'fc_ma5',
            frontQuestion: 'What is sin²(θ) + cos²(θ) equal to for any angle θ?',
            backAnswer: 'sin²(θ) + cos²(θ) = 1 (Fundamental Pythagorean trigonometric identity).',
            category: 'Trigonometry',
            hint: 'Always equals unity.',
          ),
        ],
      ),

      // === CLASS 9 ===
      FlashcardDeck(
        id: 'fc_class9_foundation',
        title: 'Class 9 Science & Motion Essentials',
        subject: 'Physics',
        gradeLevel: 'Class 9',
        themeIndex: 0, // Teal
        cards: [
          FlashcardItem(
            id: 'fc_c9_1',
            frontQuestion: 'Why are mitochondria referred to as the powerhouse of the cell?',
            backAnswer: 'Because they synthesize ATP (Adenosine Triphosphate), the primary chemical energy currency required for all cellular activities.',
            category: 'Biology',
            hint: 'Produces ATP through cellular respiration.',
          ),
          FlashcardItem(
            id: 'fc_c9_2',
            frontQuestion: 'What is the value of universal gravitational constant G in SI units?',
            backAnswer: 'G = 6.674 × 10⁻¹¹ N·m²/kg²',
            category: 'Physics',
            hint: 'Discovered experimentally by Henry Cavendish.',
          ),
          FlashcardItem(
            id: 'fc_c9_3',
            frontQuestion: 'State Newton’s Second Law of Motion in formula form.',
            backAnswer: 'F = m · a (Force = mass × acceleration), or F = dp/dt (rate of change of momentum).',
            category: 'Physics',
            hint: 'Force equals mass times acceleration.',
          ),
          FlashcardItem(
            id: 'fc_c9_4',
            frontQuestion: 'What is the difference between speed and velocity?',
            backAnswer: 'Speed is a scalar quantity (magnitude only); Velocity is a vector quantity (speed in a specific direction).',
            category: 'Kinematics',
            hint: 'Scalar vs Vector.',
          ),
          FlashcardItem(
            id: 'fc_c9_5',
            frontQuestion: 'What is the third equation of motion relating velocity, acceleration, and distance?',
            backAnswer: 'v² = u² + 2as, where v is final velocity, u is initial velocity, a is acceleration, and s is distance.',
            category: 'Kinematics',
            hint: 'Does not contain time variable t.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_matter_chemistry_9',
        title: 'Matter in Our Surroundings & Atoms',
        subject: 'Chemistry',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        cards: [
          FlashcardItem(
            id: 'fc_mc1',
            frontQuestion: 'What is sublimation and give two common substances that sublime?',
            backAnswer: 'The direct phase transition from solid to gas without entering the liquid state. Examples: Camphor, Dry Ice (solid CO₂), Ammonium chloride.',
            category: 'Phase Changes',
            hint: 'Solid jumps directly to gas.',
          ),
          FlashcardItem(
            id: 'fc_mc2',
            frontQuestion: 'What is Latent Heat of Vaporization?',
            backAnswer: 'The amount of heat energy required to convert 1 kg of liquid into gas at its boiling point at atmospheric pressure without temperature change.',
            category: 'Thermal',
            hint: 'Hidden heat absorbed during boiling.',
          ),
          FlashcardItem(
            id: 'fc_mc3',
            frontQuestion: 'What is the value of Avogadro’s constant?',
            backAnswer: 'N_A = 6.022 × 10²³ particles per mole.',
            category: 'Mole Concept',
            hint: 'Number of particles in exactly 12 grams of Carbon-12.',
          ),
          FlashcardItem(
            id: 'fc_mc4',
            frontQuestion: 'What is the boiling point of pure water in Kelvin scale?',
            backAnswer: '100°C = 100 + 273.15 = 373.15 K.',
            category: 'Temperature',
            hint: 'Add 273 to Celsius temperature.',
          ),
          FlashcardItem(
            id: 'fc_mc5',
            frontQuestion: 'Why does ice float on liquid water?',
            backAnswer: 'Because ice has an open cage-like crystalline structure, giving it a lower density than liquid water.',
            category: 'States of Matter',
            hint: 'Lower density due to hydrogen bonding structure.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_cell_biology_9',
        title: 'Cell Biology & Tissue Structures',
        subject: 'Biology',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        cards: [
          FlashcardItem(
            id: 'fc_cb9_1',
            frontQuestion: 'Which organelle is called the "suicide bag" of the cell and why?',
            backAnswer: 'Lysosomes, because they contain powerful digestive enzymes that can digest the cell’s own damaged components if ruptured.',
            category: 'Organelles',
            hint: 'Contains hydrolytic enzymes.',
          ),
          FlashcardItem(
            id: 'fc_cb9_2',
            frontQuestion: 'What is the main chemical component of the plant cell wall?',
            backAnswer: 'Cellulose, a complex structural carbohydrate providing rigidity and mechanical support.',
            category: 'Plant Cell',
            hint: 'Gives rigidity to plant cells.',
          ),
          FlashcardItem(
            id: 'fc_cb9_3',
            frontQuestion: 'What is the primary function of the Golgi Apparatus?',
            backAnswer: 'Packaging, modification, and dispatching of proteins and lipids synthesized in the Endoplasmic Reticulum.',
            category: 'Organelles',
            hint: 'Post office of the cell.',
          ),
          FlashcardItem(
            id: 'fc_cb9_4',
            frontQuestion: 'What is the difference between Rough ER and Smooth ER?',
            backAnswer: 'Rough ER has ribosomes on its surface and synthesizes proteins; Smooth ER lacks ribosomes and synthesizes lipids/detoxifies drugs.',
            category: 'Organelles',
            hint: 'Presence or absence of ribosomes.',
          ),
          FlashcardItem(
            id: 'fc_cb9_5',
            frontQuestion: 'What are plastids and what is the function of chloroplasts?',
            backAnswer: 'Plastids are plant-specific organelles. Chloroplasts contain green chlorophyll pigments and conduct photosynthesis.',
            category: 'Plant Cell',
            hint: 'Solar energy trapping organelle.',
          ),
        ],
      ),

      FlashcardDeck(
        id: 'fc_math_identities_9',
        title: 'Algebraic Identities & Real Numbers',
        subject: 'Mathematics',
        gradeLevel: 'Class 9',
        themeIndex: 1, // Lavender
        cards: [
          FlashcardItem(
            id: 'fc_mi1',
            frontQuestion: 'What is the algebraic expansion of (a + b)³?',
            backAnswer: '(a + b)³ = a³ + 3a²b + 3ab² + b³ = a³ + b³ + 3ab(a + b)',
            category: 'Identities',
            hint: 'Pascal triangle row 1, 3, 3, 1.',
          ),
          FlashcardItem(
            id: 'fc_mi2',
            frontQuestion: 'What is the expansion of (a + b + c)²?',
            backAnswer: '(a + b + c)² = a² + b² + c² + 2ab + 2bc + 2ca',
            category: 'Identities',
            hint: 'Sum of squares plus 2 times all pairwise products.',
          ),
          FlashcardItem(
            id: 'fc_mi3',
            frontQuestion: 'What is a³ + b³ in factored form?',
            backAnswer: 'a³ + b³ = (a + b)(a² − ab + b²)',
            category: 'Factoring',
            hint: 'First factor is (a + b); middle term of quadratic is -ab.',
          ),
          FlashcardItem(
            id: 'fc_mi4',
            frontQuestion: 'What is the rationalizing factor for (√a + √b)?',
            backAnswer: 'The conjugate radical expression (√a − √b), since (√a + √b)(√a − √b) = a − b.',
            category: 'Real Numbers',
            hint: 'Change plus to minus.',
          ),
          FlashcardItem(
            id: 'fc_mi5',
            frontQuestion: 'State the Remainder Theorem for a polynomial p(x) divided by (x − a).',
            backAnswer: 'The remainder when polynomial p(x) is divided by (x − a) is simply equal to p(a).',
            category: 'Polynomials',
            hint: 'Evaluate the polynomial at x = a.',
          ),
        ],
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // QUIZZES (4 per class = 16 rich interactive quizzes)
  // -------------------------------------------------------------------------
  static List<QuizDeck> getSampleQuizzes() {
    return [
      // === CLASS 12 ===
      const QuizDeck(
        id: 'quiz_math_physics_12',
        title: 'Class 12 Advanced STEM Quiz',
        subject: 'Mathematics & CS',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        questions: [
          QuizQuestion(
            id: 'q12_1',
            question: 'What is the distance between points (0, 0, 0) and (2, 3, 6) in 3D Euclidean space?',
            options: ['5 units', '7 units', '11 units', '9 units'],
            correctOptionIndex: 1,
            explanation: 'd = √(2² + 3² + 6²) = √(4 + 9 + 36) = √49 = 7 units.',
          ),
          QuizQuestion(
            id: 'q12_2',
            question: 'Which of the following encryption algorithms utilizes asymmetric public/private key pairs?',
            options: ['AES-256', 'DES', 'RSA', 'ChaCha20'],
            correctOptionIndex: 2,
            explanation: 'RSA relies on prime factorization difficulty for public-key cryptography; AES and DES are symmetric.',
          ),
          QuizQuestion(
            id: 'q12_3',
            question: 'What is the angle between vectors A = (1, 0, 0) and B = (0, 1, 0)?',
            options: ['0°', '45°', '90°', '180°'],
            correctOptionIndex: 2,
            explanation: 'A · B = (1)(0) + (0)(1) + (0)(0) = 0. A dot product of zero indicates perpendicularity (90°).',
          ),
          QuizQuestion(
            id: 'q12_4',
            question: 'What is the derivative of e^(3x) with respect to x?',
            options: ['e^(3x)', '3 e^(3x)', '3x e^(3x)', 'e^(3x) / 3'],
            correctOptionIndex: 1,
            explanation: 'By the chain rule: d/dx [e^(3x)] = e^(3x) · d/dx[3x] = 3 e^(3x).',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_electrostatics_12',
        title: 'Class 12 Physics: Electrostatics & Fields',
        subject: 'Physics',
        gradeLevel: 'Class 12',
        themeIndex: 0, // Teal
        questions: [
          QuizQuestion(
            id: 'qe12_1',
            question: 'What is the electric field inside a hollow spherical charged conductor in equilibrium?',
            options: ['Maximum at center', 'Depends on radius', 'Zero everywhere', 'Infinite'],
            correctOptionIndex: 2,
            explanation: 'By Gauss’s Law, with no enclosed charge inside the hollow cavity, E = 0 everywhere within the conductor.',
          ),
          QuizQuestion(
            id: 'qe12_2',
            question: 'If the distance between two point charges is halved, how does the electrostatic force change?',
            options: ['Halved', 'Doubled', 'Quadrupled (4x)', 'Unchanged'],
            correctOptionIndex: 2,
            explanation: 'Coulomb’s force obeys inverse square law F ∝ 1/r². Halving r multiplies force by 1/(½)² = 4x.',
          ),
          QuizQuestion(
            id: 'qe12_3',
            question: 'What happens to the capacitance of a parallel plate capacitor if a dielectric of constant κ is inserted?',
            options: ['Decreases by factor κ', 'Increases by factor κ', 'Remains unchanged', 'Becomes zero'],
            correctOptionIndex: 1,
            explanation: 'Capacitance scales directly with dielectric constant: C = κ · C₀.',
          ),
          QuizQuestion(
            id: 'qe12_4',
            question: 'What is the SI unit of electric flux Φ?',
            options: ['Newton / Coulomb', 'Volt · meter (or N·m²/C)', 'Joule / Coulomb', 'Tesla · meter'],
            correctOptionIndex: 1,
            explanation: 'Flux Φ = E · A has units (N/C)·m² = N·m²/C, which is dimensionally equivalent to Volt·meter.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_cybersecurity_12',
        title: 'Class 12 CS: Cybersecurity & Networks',
        subject: 'Computer Science',
        gradeLevel: 'Class 12',
        themeIndex: 2, // Sage
        questions: [
          QuizQuestion(
            id: 'qcs12_1',
            question: 'Which of the following is NOT one of the three CIA Triad pillars?',
            options: ['Confidentiality', 'Integrity', 'Authentication', 'Availability'],
            correctOptionIndex: 2,
            explanation: 'The CIA Triad specifically consists of Confidentiality, Integrity, and Availability. Authentication supports them.',
          ),
          QuizQuestion(
            id: 'qcs12_2',
            question: 'What type of attack floods a server with overwhelming traffic to take it offline?',
            options: ['SQL Injection', 'DDoS (Distributed Denial of Service)', 'Phishing', 'Cross-Site Scripting (XSS)'],
            correctOptionIndex: 1,
            explanation: 'A DDoS attack floods target bandwidth and resources with distributed traffic, violating Availability.',
          ),
          QuizQuestion(
            id: 'qcs12_3',
            question: 'What key is used to decrypt a message in asymmetric public-key cryptography?',
            options: ['Sender’s public key', 'Recipient’s private key', 'Recipient’s public key', 'Pre-shared symmetric key'],
            correctOptionIndex: 1,
            explanation: 'Messages encrypted with the recipient’s public key can only be decrypted by the recipient’s matching private key.',
          ),
          QuizQuestion(
            id: 'qcs12_4',
            question: 'What is the primary defense against SQL injection vulnerabilities?',
            options: ['Using parameterized queries (prepared statements)', 'Client-side JavaScript validation', 'Hashing table names', 'Increasing server RAM'],
            correctOptionIndex: 0,
            explanation: 'Parameterized queries ensure user input is treated strictly as data parameters rather than executable SQL commands.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_calculus_12',
        title: 'Class 12 Math: Integration Mastery',
        subject: 'Mathematics',
        gradeLevel: 'Class 12',
        themeIndex: 1, // Lavender
        questions: [
          QuizQuestion(
            id: 'qc12_1',
            question: 'What is the value of ∫₋₁¹ x³ dx?',
            options: ['0', '1', '2', '½'],
            correctOptionIndex: 0,
            explanation: 'f(x) = x³ is an odd function (f(-x) = -f(x)). The integral of any odd function over symmetric limits [-a, a] is exactly 0.',
          ),
          QuizQuestion(
            id: 'qc12_2',
            question: 'What is ∫ (1 / x) dx for x > 0?',
            options: ['−1/x² + C', 'ln(x) + C', 'x² / 2 + C', 'e^x + C'],
            correctOptionIndex: 1,
            explanation: 'The integral of 1/x is ln|x| + C, which is the singular exception to the power rule for integration.',
          ),
          QuizQuestion(
            id: 'qc12_3',
            question: 'What is the derivative of sin²(x)?',
            options: ['cos²(x)', '2 sin(x)', '2 sin(x) cos(x) = sin(2x)', '−2 cos(x)'],
            correctOptionIndex: 2,
            explanation: 'By chain rule: d/dx [sin²(x)] = 2 sin(x) · cos(x) = sin(2x).',
          ),
          QuizQuestion(
            id: 'qc12_4',
            question: 'What is the slope of tangent to curve y = x³ − 3x at x = 2?',
            options: ['3', '6', '9', '12'],
            correctOptionIndex: 2,
            explanation: 'dy/dx = 3x² − 3. At x = 2: m = 3(2²) − 3 = 12 − 3 = 9.',
          ),
        ],
      ),

      // === CLASS 11 ===
      const QuizDeck(
        id: 'quiz_class11',
        title: 'Class 11 Physics & Chemistry Quiz',
        subject: 'Physics & Chemistry',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        questions: [
          QuizQuestion(
            id: 'q11_1',
            question: 'In an adiabatic expansion of an ideal gas, how much heat Q is exchanged with surroundings?',
            options: ['Q = ΔU', 'Q = 0', 'Q = W', 'Q = nRT'],
            correctOptionIndex: 1,
            explanation: 'By definition, adiabatic processes have zero heat exchange (Q = 0), so ΔU = -W.',
          ),
          QuizQuestion(
            id: 'q11_2',
            question: 'What is the molecular geometry of methane (CH₄) according to VSEPR theory?',
            options: ['Linear', 'Trigonal Planar', 'Tetrahedral', 'Octahedral'],
            correctOptionIndex: 2,
            explanation: 'Carbon in methane has 4 bonding pairs and 0 lone pairs, creating a symmetric tetrahedral geometry at 109.5°.',
          ),
          QuizQuestion(
            id: 'q11_3',
            question: 'What is the limit of sin(x)/x as x approaches 0?',
            options: ['0', '1', 'Infinity', 'Undefined'],
            correctOptionIndex: 1,
            explanation: 'lim (x->0) sin(x)/x = 1 is the fundamental trigonometric limit derived via the squeeze theorem.',
          ),
          QuizQuestion(
            id: 'q11_4',
            question: 'What is the work done by centripetal force on a body moving in a uniform circle?',
            options: ['Positive', 'Negative', 'Zero', 'Depends on radius'],
            correctOptionIndex: 2,
            explanation: 'Centripetal force is always perpendicular to instantaneous displacement (θ = 90°), so W = F · s · cos(90°) = 0.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_thermodynamics_11',
        title: 'Class 11 Physics: Thermal Dynamics',
        subject: 'Physics',
        gradeLevel: 'Class 11',
        themeIndex: 0, // Teal
        questions: [
          QuizQuestion(
            id: 'qt11_1',
            question: 'What is the efficiency of a Carnot engine operating between 300 K and 600 K?',
            options: ['25%', '50%', '75%', '100%'],
            correctOptionIndex: 1,
            explanation: 'η = 1 − (T_cold / T_hot) = 1 − (300 / 600) = 1 − 0.5 = 0.5 = 50%.',
          ),
          QuizQuestion(
            id: 'qt11_2',
            question: 'For an isothermal expansion of an ideal gas, what is the change in internal energy ΔU?',
            options: ['Positive', 'Negative', 'Zero', 'Equal to PV'],
            correctOptionIndex: 2,
            explanation: 'Internal energy of ideal gas depends solely on temperature. At constant temperature (isothermal), ΔT = 0, so ΔU = 0.',
          ),
          QuizQuestion(
            id: 'qt11_3',
            question: 'What does the Zeroth Law of Thermodynamics establish?',
            options: ['Concept of Entropy', 'Concept of Temperature', 'Conservation of Energy', 'Absolute Zero limit'],
            correctOptionIndex: 1,
            explanation: 'The Zeroth Law states that two systems in thermal equilibrium with a third are in equilibrium with each other, defining temperature.',
          ),
          QuizQuestion(
            id: 'qt11_4',
            question: 'What is the molar heat capacity ratio γ for a monoatomic ideal gas (like Helium)?',
            options: ['1.33', '1.40', '1.67', '2.00'],
            correctOptionIndex: 2,
            explanation: 'For monoatomic gas: Cv = (3/2)R, Cp = (5/2)R. γ = Cp / Cv = 5/3 ≈ 1.67.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_chem_bonding_11',
        title: 'Class 11 Chemistry: Chemical Bonding',
        subject: 'Chemistry',
        gradeLevel: 'Class 11',
        themeIndex: 2, // Sage
        questions: [
          QuizQuestion(
            id: 'qc11_1',
            question: 'What is the hybridization of Boron in Boron trifluoride (BF₃)?',
            options: ['sp', 'sp²', 'sp³', 'dsp²'],
            correctOptionIndex: 1,
            explanation: 'Boron forms 3 single bonds with 0 lone pairs, giving a steric number of 3 and trigonal planar sp² hybridization.',
          ),
          QuizQuestion(
            id: 'qc11_2',
            question: 'Which of the following molecules has a zero net dipole moment?',
            options: ['H₂O', 'NH₃', 'CO₂', 'SO₂'],
            correctOptionIndex: 2,
            explanation: 'CO₂ has a linear structure (O=C=O) with two equal and opposite bond dipoles that cancel out completely (μ = 0).',
          ),
          QuizQuestion(
            id: 'qc11_3',
            question: 'How many sigma (σ) and pi (π) bonds are present in an ethyne (acetylene) molecule C₂H₂?',
            options: ['3 σ and 2 π', '2 σ and 3 π', '5 σ and 0 π', '1 σ and 2 π'],
            correctOptionIndex: 0,
            explanation: 'Structure H−C≡C−H contains 2 C-H sigma bonds + 1 C-C sigma bond (3 σ) and 2 C-C pi bonds in the triple bond (2 π).',
          ),
          QuizQuestion(
            id: 'qc11_4',
            question: 'Which molecule has the highest bond dissociation energy?',
            options: ['O₂', 'N₂', 'Cl₂', 'F₂'],
            correctOptionIndex: 1,
            explanation: 'N₂ possesses a very short and strong triple bond (N≡N) with bond dissociation energy of ~945 kJ/mol.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_math_conics_11',
        title: 'Class 11 Math: Trigonometry & Geometry',
        subject: 'Mathematics',
        gradeLevel: 'Class 11',
        themeIndex: 1, // Lavender
        questions: [
          QuizQuestion(
            id: 'qm11_1',
            question: 'What is the eccentricity e of a parabola?',
            options: ['e = 0', 'e = 1', 'e < 1', 'e > 1'],
            correctOptionIndex: 1,
            explanation: 'By definition, a parabola is the locus of points equidistant from focus and directrix, meaning e = 1.',
          ),
          QuizQuestion(
            id: 'qm11_2',
            question: 'What is the value of cos(75°)?',
            options: ['(√6 + √2) / 4', '(√6 − √2) / 4', '(√3 − 1) / 2', '½'],
            correctOptionIndex: 1,
            explanation: 'cos(75°) = cos(45° + 30°) = cos45°cos30° − sin45°sin30° = (√2/2)(√3/2) − (√2/2)(1/2) = (√6 − √2) / 4.',
          ),
          QuizQuestion(
            id: 'qm11_3',
            question: 'What is the length of latus rectum for the parabola y² = 12x?',
            options: ['3', '6', '12', '24'],
            correctOptionIndex: 2,
            explanation: 'Comparing with standard form y² = 4ax: length of latus rectum is 4a = 12.',
          ),
          QuizQuestion(
            id: 'qm11_4',
            question: 'What is the sum of angles of a triangle in radian measure?',
            options: ['π/2 radians', 'π radians', '2π radians', '3π/2 radians'],
            correctOptionIndex: 1,
            explanation: '180° = π radians.',
          ),
        ],
      ),

      // === CLASS 10 ===
      const QuizDeck(
        id: 'quiz_class10',
        title: 'Class 10 Science & Math Sprint',
        subject: 'Science & Math',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        questions: [
          QuizQuestion(
            id: 'q10_1',
            question: 'A convex mirror has a radius of curvature of 30 cm. What is its focal length?',
            options: ['+15 cm', '-15 cm', '+60 cm', '-30 cm'],
            correctOptionIndex: 0,
            explanation: 'Focal length f = R / 2 = 30 / 2 = +15 cm (positive behind the convex mirror).',
          ),
          QuizQuestion(
            id: 'q10_2',
            question: 'Which element is oxidized in the reaction: CuO + H₂ ⟶ Cu + H₂O?',
            options: ['Copper (Cu)', 'Oxygen (O)', 'Hydrogen (H₂)', 'None'],
            correctOptionIndex: 2,
            explanation: 'Hydrogen gains oxygen to form water, meaning H₂ is oxidized, while CuO is reduced.',
          ),
          QuizQuestion(
            id: 'q10_3',
            question: 'What is the nature of roots for quadratic equation 2x² - 4x + 3 = 0?',
            options: ['Two distinct real roots', 'Two equal real roots', 'No real roots (imaginary)', 'Infinite roots'],
            correctOptionIndex: 2,
            explanation: 'Discriminant D = b² - 4ac = (-4)² - 4(2)(3) = 16 - 24 = -8 < 0. Hence, roots are imaginary.',
          ),
          QuizQuestion(
            id: 'q10_4',
            question: 'If current in a circuit is doubled at constant resistance, by what factor does heating increase?',
            options: ['2x', '4x', '8x', 'Remains same'],
            correctOptionIndex: 1,
            explanation: 'By Joule’s law H = I²Rt. Since current I is squared, doubling I increases heat generation by 2² = 4x.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_optics_10',
        title: 'Class 10 Physics: Light & Eyes',
        subject: 'Physics',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        questions: [
          QuizQuestion(
            id: 'qo10_1',
            question: 'Which defect of vision is corrected using a concave lens?',
            options: ['Hypermetropia (Farsightedness)', 'Myopia (Nearsightedness)', 'Presbyopia', 'Astigmatism'],
            correctOptionIndex: 1,
            explanation: 'Myopia causes light rays to converge in front of the retina. A diverging concave lens moves the focus back onto retina.',
          ),
          QuizQuestion(
            id: 'qo10_2',
            question: 'What is the speed of light in a glass prism with refractive index n = 1.5?',
            options: ['3.0 × 10⁸ m/s', '2.0 × 10⁸ m/s', '1.5 × 10⁸ m/s', '4.5 × 10⁸ m/s'],
            correctOptionIndex: 1,
            explanation: 'v = c / n = (3.0 × 10⁸ m/s) / 1.5 = 2.0 × 10⁸ m/s.',
          ),
          QuizQuestion(
            id: 'qo10_3',
            question: 'Why does the sky appear blue during a clear sunny day?',
            options: ['Atmospheric refraction', 'Total internal reflection', 'Rayleigh scattering of shorter blue wavelengths', 'Absorption of red light'],
            correctOptionIndex: 2,
            explanation: 'Fine atmospheric air molecules scatter shorter wavelengths (blue light) much more strongly than longer red wavelengths.',
          ),
          QuizQuestion(
            id: 'qo10_4',
            question: 'What is the magnification formula for spherical lenses in terms of v and u?',
            options: ['m = −v/u', 'm = +v/u', 'm = u/v', 'm = uv'],
            correctOptionIndex: 1,
            explanation: 'For lenses, magnification m = +v/u. (For mirrors it is -v/u).',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_acids_salts_10',
        title: 'Class 10 Chemistry: Acids & Reactions',
        subject: 'Chemistry',
        gradeLevel: 'Class 10',
        themeIndex: 3, // Terracotta
        questions: [
          QuizQuestion(
            id: 'qa10_1',
            question: 'What is the pH range of human blood under healthy physiological conditions?',
            options: ['5.0 - 5.5', '6.0 - 6.5', '7.35 - 7.45', '8.5 - 9.0'],
            correctOptionIndex: 2,
            explanation: 'Human blood is slightly basic, maintaining a narrow physiological buffer range of 7.35 to 7.45.',
          ),
          QuizQuestion(
            id: 'qa10_2',
            question: 'What acid is injected into the skin by an ant sting?',
            options: ['Acetic acid', 'Methanoic acid (Formic acid)', 'Citric acid', 'Oxalic acid'],
            correctOptionIndex: 1,
            explanation: 'Ant stings inject methanoic acid (HCOOH), which causes burning pain relieved by mild bases like baking soda.',
          ),
          QuizQuestion(
            id: 'qa10_3',
            question: 'What is the common name of Sodium Hydrogen Carbonate (NaHCO₃)?',
            options: ['Washing Soda', 'Baking Soda', 'Bleaching Powder', 'Caustic Soda'],
            correctOptionIndex: 1,
            explanation: 'NaHCO₃ is Baking Soda; Na₂CO₃·10H₂O is Washing Soda.',
          ),
          QuizQuestion(
            id: 'qa10_4',
            question: 'What turns lime water milky when carbon dioxide gas is bubbled through it?',
            options: ['Formation of Calcium Oxide', 'Formation of Calcium Carbonate precipitate (CaCO₃)', 'Formation of Calcium Hydroxide', 'Dissolved Nitrogen'],
            correctOptionIndex: 1,
            explanation: 'Ca(OH)₂ + CO₂ ⟶ CaCO₃ (white insoluble precipitate) + H₂O.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_math_ap_10',
        title: 'Class 10 Math: Arithmetic Progressions',
        subject: 'Mathematics',
        gradeLevel: 'Class 10',
        themeIndex: 1, // Lavender
        questions: [
          QuizQuestion(
            id: 'qma10_1',
            question: 'What is the 10th term of the AP: 2, 7, 12, 17...?',
            options: ['42', '47', '52', '57'],
            correctOptionIndex: 1,
            explanation: 'a = 2, d = 5. a₁₀ = a + 9d = 2 + 9(5) = 2 + 45 = 47.',
          ),
          QuizQuestion(
            id: 'qma10_2',
            question: 'What is the sum of the first 10 natural numbers?',
            options: ['45', '50', '55', '60'],
            correctOptionIndex: 2,
            explanation: 'Sum = n(n + 1) / 2 = 10(11) / 2 = 110 / 2 = 55.',
          ),
          QuizQuestion(
            id: 'qma10_3',
            question: 'What is the distance of point P(3, 4) from the origin (0, 0)?',
            options: ['3 units', '4 units', '5 units', '7 units'],
            correctOptionIndex: 2,
            explanation: 'd = √(3² + 4²) = √(9 + 16) = √25 = 5 units.',
          ),
          QuizQuestion(
            id: 'qma10_4',
            question: 'If tan(θ) = 4/3, what is the value of sin(θ)?',
            options: ['3/5', '4/5', '3/4', '5/4'],
            correctOptionIndex: 1,
            explanation: 'In a 3-4-5 right triangle, opposite = 4, adjacent = 3, hypotenuse = 5. Therefore sin(θ) = opposite / hypotenuse = 4/5.',
          ),
        ],
      ),

      // === CLASS 9 ===
      const QuizDeck(
        id: 'quiz_class9',
        title: 'Class 9 Foundation Mastery Quiz',
        subject: 'Science & Math',
        gradeLevel: 'Class 9',
        themeIndex: 0, // Teal
        questions: [
          QuizQuestion(
            id: 'q9_1',
            question: 'Which organelle is responsible for synthesizing proteins in biological cells?',
            options: ['Lysosome', 'Ribosome', 'Vacuole', 'Centrosome'],
            correctOptionIndex: 1,
            explanation: 'Ribosomes translate mRNA sequences to synthesize polypeptide chains of proteins.',
          ),
          QuizQuestion(
            id: 'q9_2',
            question: 'If an object travels 20 meters in 2 seconds with constant acceleration from rest, what is its acceleration?',
            options: ['5 m/s²', '10 m/s²', '20 m/s²', '2.5 m/s²'],
            correctOptionIndex: 1,
            explanation: 's = ut + ½at². With u = 0: 20 = ½·a·(2²) = 2a ⟹ a = 10 m/s².',
          ),
          QuizQuestion(
            id: 'q9_3',
            question: 'What is the product of (x + 3)(x - 3)?',
            options: ['x² + 9', 'x² - 9', 'x² - 6x + 9', 'x² + 6x - 9'],
            correctOptionIndex: 1,
            explanation: 'Difference of squares identity: (a + b)(a - b) = a² - b² ⟹ x² - 9.',
          ),
          QuizQuestion(
            id: 'q9_4',
            question: 'What is the SI unit of momentum?',
            options: ['kg · m/s', 'kg · m/s²', 'Newton · meter', 'Joule'],
            correctOptionIndex: 0,
            explanation: 'Momentum p = m · v, giving SI units of mass (kg) multiplied by velocity (m/s) = kg·m/s.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_matter_9',
        title: 'Class 9 Chemistry: States of Matter',
        subject: 'Chemistry',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        questions: [
          QuizQuestion(
            id: 'qm9_1',
            question: 'What is the process called when solid Carbon Dioxide converts directly into gas without melting?',
            options: ['Condensation', 'Sublimation', 'Evaporation', 'Deposition'],
            correctOptionIndex: 1,
            explanation: 'Sublimation is the direct phase change from solid to gas without entering the liquid phase.',
          ),
          QuizQuestion(
            id: 'qm9_2',
            question: 'Which of the following factors DECREASES the rate of evaporation of a liquid?',
            options: ['Increase in temperature', 'Increase in surface area', 'Increase in humidity', 'Increase in wind speed'],
            correctOptionIndex: 2,
            explanation: 'High humidity means the surrounding air is already saturated with water vapor, decreasing the rate of evaporation.',
          ),
          QuizQuestion(
            id: 'qm9_3',
            question: 'What temperature in Celsius corresponds to 300 Kelvin?',
            options: ['27°C', '37°C', '573°C', '-27°C'],
            correctOptionIndex: 0,
            explanation: '°C = K − 273.15 = 300 − 273.15 ≈ 27°C (approximate room temperature).',
          ),
          QuizQuestion(
            id: 'qm9_4',
            question: 'Why does temperature remain constant while a pure substance is melting at its melting point?',
            options: ['Thermometer stops working', 'Heat is used as Latent Heat to overcome intermolecular forces', 'Heat escapes to walls', 'Molecules stop moving'],
            correctOptionIndex: 1,
            explanation: 'All supplied thermal energy is absorbed as Latent Heat of Fusion to break intermolecular bonds rather than increasing kinetic energy.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_cell_biology_9',
        title: 'Class 9 Biology: Cell Structures',
        subject: 'Biology',
        gradeLevel: 'Class 9',
        themeIndex: 3, // Terracotta
        questions: [
          QuizQuestion(
            id: 'qcb9_1',
            question: 'Which cellular structure is present in plant cells but absent in animal cells?',
            options: ['Mitochondria', 'Cell Wall and Chloroplasts', 'Ribosomes', 'Golgi apparatus'],
            correctOptionIndex: 1,
            explanation: 'Cell walls and chloroplasts are unique to plant and algal cells, providing cellulose rigidity and photosynthesis.',
          ),
          QuizQuestion(
            id: 'qcb9_2',
            question: 'What is the full chemical name of ATP synthesized in mitochondria?',
            options: ['Adenosine Triphosphate', 'Adenosine Diphosphate', 'Ammonium Triphosphate', 'Adenine Tetra Phosphate'],
            correctOptionIndex: 0,
            explanation: 'ATP stands for Adenosine Triphosphate, the cellular chemical energy currency.',
          ),
          QuizQuestion(
            id: 'qcb9_3',
            question: 'What process allows water to cross the semi-permeable cell membrane from high to low water concentration?',
            options: ['Active transport', 'Osmosis', 'Endocytosis', 'Phagocytosis'],
            correctOptionIndex: 1,
            explanation: 'Osmosis is the spontaneous net movement of water molecules through a selectively permeable membrane.',
          ),
          QuizQuestion(
            id: 'qcb9_4',
            question: 'Where is genetic DNA stored inside a eukaryotic cell?',
            options: ['Cytoplasm', 'Nucleus', 'Vacuole', 'Centriole'],
            correctOptionIndex: 1,
            explanation: 'In eukaryotic cells, linear DNA is organized into chromatin fibers inside the membrane-bound nucleus.',
          ),
        ],
      ),

      const QuizDeck(
        id: 'quiz_math_polynomials_9',
        title: 'Class 9 Math: Polynomials & Number Systems',
        subject: 'Mathematics',
        gradeLevel: 'Class 9',
        themeIndex: 1, // Lavender
        questions: [
          QuizQuestion(
            id: 'qmp9_1',
            question: 'What is the degree of the zero polynomial?',
            options: ['0', '1', 'Undefined (or not defined)', 'Infinity'],
            correctOptionIndex: 2,
            explanation: 'The degree of the zero polynomial 0 is mathematically not defined (or conventionally set to -∞).',
          ),
          QuizQuestion(
            id: 'qmp9_2',
            question: 'Which of the following is an irrational number?',
            options: ['√4', '√9', '√7', '0.25'],
            correctOptionIndex: 2,
            explanation: '√7 is a surd that cannot be simplified to a ratio of integers; √4 = 2, √9 = 3, and 0.25 = 1/4 are all rational.',
          ),
          QuizQuestion(
            id: 'qmp9_3',
            question: 'If p(x) = 2x³ − 3x + 4, what is the value of p(−1)?',
            options: ['3', '5', '−1', '9'],
            correctOptionIndex: 1,
            explanation: 'p(-1) = 2(-1)³ − 3(-1) + 4 = -2 + 3 + 4 = 5.',
          ),
          QuizQuestion(
            id: 'qmp9_4',
            question: 'What is the remainder when x⁴ − 1 is divided by (x − 1)?',
            options: ['0', '1', '2', '−1'],
            correctOptionIndex: 0,
            explanation: 'By the Remainder Theorem, R = p(1) = 1⁴ − 1 = 1 − 1 = 0. Therefore (x − 1) is an exact factor.',
          ),
        ],
      ),
    ];
  }

  // -------------------------------------------------------------------------
  // AUDIO OVERVIEW TRACKS (3-4 per class = 14 dual-host podcast episodes)
  // -------------------------------------------------------------------------
  static List<AudioOverviewTrack> getSamplePodcasts() {
    return [
      // === CLASS 12 ===
      const AudioOverviewTrack(
        id: 'audio_3d_geometry',
        title: 'Deep Dive: Visualizing 3D Geometry',
        topic: 'Mathematics & Spatial Coordinates',
        gradeLevel: 'Class 12',
        durationMinutes: '2 min listen',
        themeIndex: 1, // Lavender
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Right! Most students are super comfortable with X and Y axes on graph paper, but adding that third z-axis for depth or height can feel a little intimidating at first.',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'It does! But the beauty is how elegant the math is. Instead of quadrants, you now have eight octants. And calculating distance between two points in 3D space uses the exact same logic as Pythagoras: you just add the squared delta of the z-axis under the square root.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Wait, so finding the diagonal through a 3D rectangular box is just the square root of delta-x squared plus delta-y squared plus delta-z squared?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Exactly! And when you look at equations, a single linear equation in 3D doesn’t make a line anymore—it defines an entire flat 2D plane cutting through space.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'That is so cool to visualize! Because the normal vector acts like an arrow standing straight up from the floor, locking that plane into orientation.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_cybersecurity',
        title: 'Deep Dive: Zero Trust & Modern Cryptography',
        topic: 'Computer Science & Security',
        gradeLevel: 'Class 12',
        durationMinutes: '3 min listen',
        themeIndex: 2, // Sage
        transcript: [
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Welcome back! Today we are tackling cybersecurity. If there is one mantra every computer science student should engrave in their memory, it is: Never Trust, Always Verify.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Zero Trust! Because back in the day, people thought having a strong firewall at the perimeter of the building was enough. Once someone was inside the office Wi-Fi, they were trusted by default.',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'And that perimeter-castle model failed repeatedly. In modern cloud architecture, every single API call and microservice interaction requires cryptographic verification.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'And that brings us to the CIA Triad: Confidentiality, Integrity, and Availability. Alex, how does asymmetric encryption protect confidentiality so neatly?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'With RSA or Elliptic Curve crypto, I can publish my public key to the entire world. Anyone can lock a message with it, but only my private key holds the mathematical secret to unlock it!',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_electrostatics_12',
        title: 'Deep Dive: Gauss’s Law & Electric Flux',
        topic: 'Physics & Field Theory',
        gradeLevel: 'Class 12',
        durationMinutes: '2 min listen',
        themeIndex: 0, // Teal
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Alex, Gauss’s Law looks super intimidating with that closed surface integral symbol with the circle on it. How do you explain it simply?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Think of electric charges as glowing lightbulbs and flux as the total amount of light rays passing through an invisible bubble surrounding them. It doesn’t matter what shape your bubble is!',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'So whether the bubble is a tiny sphere or a giant squiggly potato, all the light rays originating from that bulb still have to punch through the surface?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Spot on! The total outward flux is strictly equal to the enclosed charge divided by epsilon-nought. That is why the field inside a hollow metal conductor is always zero—the charge rests solely on the outer skin.',
          ),
        ],
      ),

      // === CLASS 11 ===
      const AudioOverviewTrack(
        id: 'audio_thermodynamics_11',
        title: 'Deep Dive: Carnot Engines & Entropy',
        topic: 'Physics & Energy Laws',
        gradeLevel: 'Class 11',
        durationMinutes: '2 min listen',
        themeIndex: 0, // Teal
        transcript: [
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Today we are exploring the Second Law of Thermodynamics. Sadi Carnot proved something profound: you can never build a heat engine that is 100 percent efficient.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Even if there is zero friction and perfect engineering? Why can’t we turn every single Joule of heat into pure mechanical work?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Because nature requires a temperature difference to drive heat flow. You must dump a portion of that thermal energy into a colder sink to reset the cycle. That is the tax of entropy!',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'So maximum efficiency is always limited to 1 minus the ratio of the cold reservoir over the hot reservoir in Kelvin.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_bonding_11',
        title: 'Deep Dive: Why Molecules Have Shapes (VSEPR)',
        topic: 'Chemistry & Molecular Geometry',
        gradeLevel: 'Class 11',
        durationMinutes: '2 min listen',
        themeIndex: 2, // Sage
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Alex, why is water bent at 104.5 degrees instead of being a straight line like carbon dioxide?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'It all comes down to electron repulsion! Oxygen has two bonding pairs of electrons with hydrogen, but it also has two unshared lone pairs hovering on top.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'And those lone pairs take up extra space like bulky balloons, pushing the two hydrogen atoms closer together!',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Exactly right. Carbon dioxide only has two double bonds and no lone pairs on the central carbon, so the bonds push directly opposite at 180 degrees into a straight line.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_projectile_11',
        title: 'Deep Dive: Projectiles & Curved Trajectories',
        topic: 'Physics & Kinematics',
        gradeLevel: 'Class 11',
        durationMinutes: '2 min listen',
        themeIndex: 0, // Teal
        transcript: [
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'When you throw a ball into the air, its horizontal motion and vertical motion are completely independent of each other.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'That always blows my mind. The horizontal velocity stays constant because there is no horizontal force, while gravity accelerates the vertical velocity downward at 9.8 m/s².',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'And combining constant horizontal speed with uniform downward acceleration traces out a mathematically perfect parabola!',
          ),
        ],
      ),

      // === CLASS 10 ===
      const AudioOverviewTrack(
        id: 'audio_optics_10',
        title: 'Deep Dive: Bending Light & Rainbows',
        topic: 'Physics & Wave Refraction',
        gradeLevel: 'Class 10',
        durationMinutes: '2 min listen',
        themeIndex: 3, // Terracotta
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'When you place a straw in a glass of water, it looks broken or shifted at the surface. Why does light do that?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Light travels slower through water than through air! When a beam of light hits the water at an angle, one side slows down before the other, causing the wavefront to pivot—that is refraction.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'And Snell’s Law gives us the exact ratio: n1 sine theta 1 equals n2 sine theta 2.',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Precisely. And inside raindrops, different wavelengths refract at slightly different angles, splitting white sunlight into the magnificent spectrum of a rainbow.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_electricity_10',
        title: 'Deep Dive: Flow of Electrons & Ohm’s Law',
        topic: 'Physics & Circuits',
        gradeLevel: 'Class 10',
        durationMinutes: '2 min listen',
        themeIndex: 0, // Teal
        transcript: [
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Think of voltage as the water pressure in a pipe, current as the actual flow rate of water gallons per second, and resistance as a narrowing of the pipe.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'That makes Ohm’s Law V = IR so intuitive! Higher voltage pushes more current through, but high resistance chokes the current back.',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'And where does that choked energy go? It gets converted directly into thermal heat—which is exactly how electric toasters and heaters operate.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_acids_10',
        title: 'Deep Dive: The pH Scale & Neutralization',
        topic: 'Chemistry & Aqueous Solutions',
        gradeLevel: 'Class 10',
        durationMinutes: '2 min listen',
        themeIndex: 3, // Terracotta
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Alex, why is the pH scale logarithmic? Why isn’t it just a regular 1 to 14 linear count?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Because the concentration of hydrogen ions changes by orders of magnitude! A solution with pH 3 has 10 times more hydrogen ions than pH 4, and 100 times more than pH 5.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Wow! So jumping two numbers on the scale is a hundredfold increase in acidity!',
          ),
        ],
      ),

      // === CLASS 9 ===
      const AudioOverviewTrack(
        id: 'audio_cell_9',
        title: 'Deep Dive: The Cell as a Microscopic City',
        topic: 'Biology & Cellular Organelles',
        gradeLevel: 'Class 9',
        durationMinutes: '2 min listen',
        themeIndex: 3, // Terracotta
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Alex, I love the analogy of a biological cell as a tiny bustling city. Who does what in this microscopic city?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'The Nucleus is City Hall holding all the master architectural blueprints in DNA. The Mitochondria are the power plants burning fuel into ATP energy currency.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'And the Endoplasmic Reticulum and Golgi apparatus are the factories and postal dispatch centers packaging proteins!',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Exactly! And lysosomes are the municipal waste disposal and recycling crews keeping the city immaculately clean.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_motion_9',
        title: 'Deep Dive: Why Do Things Move? (Newton’s Laws)',
        topic: 'Physics & Inertia',
        gradeLevel: 'Class 9',
        durationMinutes: '2 min listen',
        themeIndex: 0, // Teal
        transcript: [
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'Before Isaac Newton, ancient thinkers believed objects naturally wanted to slow down and stop. Newton realized that is completely wrong!',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Right! In deep space with no friction or gravity, if you throw a baseball, it will literally travel forever in a straight line at that exact same speed.',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'That is the First Law: Inertia. Things only accelerate or decelerate when an outside unbalanced force interferes with them.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'And the Second Law tells us that the bigger the mass of the object, the harder you have to push to achieve that same acceleration: Force equals mass times acceleration.',
          ),
        ],
      ),

      const AudioOverviewTrack(
        id: 'audio_matter_9',
        title: 'Deep Dive: The Dance of Atoms & States of Matter',
        topic: 'Chemistry & Thermal Physics',
        gradeLevel: 'Class 9',
        durationMinutes: '2 min listen',
        themeIndex: 3, // Terracotta
        transcript: [
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'When ice is melting in a glass, if you stick a thermometer in the slush, the temperature stays at zero degrees Celsius until the very last chip of ice is gone. Why doesn’t it warm up as we heat it?',
          ),
          PodcastTurn(
            speakerName: 'Alex',
            isHostA: true,
            dialogue: 'That is Latent Heat! The thermal energy isn’t speeding up the water molecules—it is being consumed to break the rigid molecular bonds holding the ice crystal together.',
          ),
          PodcastTurn(
            speakerName: 'Jamie',
            isHostA: false,
            dialogue: 'Once the bonds are broken and all ice becomes liquid, only then does additional heat begin raising the temperature toward boiling point!',
          ),
        ],
      ),
    ];
  }
}
