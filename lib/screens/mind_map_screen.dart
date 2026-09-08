import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/studio_items.dart';

class MindMapScreen extends StatefulWidget {
  final MindMapDeck? initialDeck;

  const MindMapScreen({super.key, this.initialDeck});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  late MindMapDeck _currentDeck;
  late List<MindMapDeck> _allDecks;
  late int _themeIndex;
  String _selectedGrade = 'All';

  final TransformationController _transformController = TransformationController();
  final Set<String> _expandedNodeIds = {};
  MindMapNode? _selectedNode;

  // Virtual Canvas dimensions
  static const double _canvasWidth = 3200;
  static const double _canvasHeight = 2200;
  static const double _centerX = _canvasWidth / 2;
  static const double _centerY = _canvasHeight / 2;

  // Node Dimensions
  static const double _rootWidth = 230;
  static const double _rootHeight = 84;
  static const double _l1Width = 210;
  static const double _l1Height = 74;
  static const double _l2Width = 190;
  static const double _l2Height = 64;

  // Curated pastel branch colors
  static const List<Color> _branchColors = [
    Color(0xFF0D9488), // Teal
    Color(0xFF7C3AED), // Violet
    Color(0xFFEA580C), // Orange
    Color(0xFF059669), // Emerald
    Color(0xFF2563EB), // Blue
    Color(0xFFD97706), // Amber
    Color(0xFFDB2777), // Pink
  ];

  @override
  void initState() {
    super.initState();
    _allDecks = StudioPreTemplates.getSampleMindMaps();
    _currentDeck = widget.initialDeck ?? _allDecks.first;
    _themeIndex = _currentDeck.themeIndex;

    _expandDefaultNodes();
    _selectedNode = _currentDeck.rootNode;

    _initUserClass();
  }

  Future<void> _initUserClass() async {
    if (widget.initialDeck != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot());
      return;
    }
    final userGrade = await StudioPreTemplates.getUserGradeFormatted();
    if (mounted) {
      setState(() {
        if (StudioPreTemplates.allGrades.contains(userGrade)) {
          _selectedGrade = userGrade;
          final matching = _allDecks.where((d) => d.gradeLevel == userGrade).toList();
          if (matching.isNotEmpty) {
            _currentDeck = matching.first;
            _themeIndex = _currentDeck.themeIndex;
            _expandDefaultNodes();
            _selectedNode = _currentDeck.rootNode;
          }
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot());
    }
  }

  void _expandDefaultNodes() {
    _expandedNodeIds.clear();
    _expandedNodeIds.add(_currentDeck.rootNode.id);
    for (final child in _currentDeck.rootNode.children) {
      _expandedNodeIds.add(child.id);
    }
  }

  void _centerOnRoot() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    // On mobile (< 600px width), fit the root node + radiating L1 branches nicely
    final double initialScale = size.width < 600
        ? (size.width / 920).clamp(0.42, 0.65)
        : (size.width / 1400).clamp(0.65, 1.0);

    final dx = (size.width / 2) - (_centerX * initialScale);
    final topOffset = _filteredDecks.length > 1 ? 90.0 : 48.0;
    final bottomOffset = _selectedNode != null ? 140.0 : 40.0;
    final availableHeight = size.height - topOffset - bottomOffset;
    final dy = topOffset + (availableHeight / 2) - (_centerY * initialScale);

    // ignore: deprecated_member_use
    _transformController.value = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(dx, dy)
      // ignore: deprecated_member_use
      ..scale(initialScale);
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    // ignore: deprecated_member_use
    matrix.scale(factor, factor);
    _transformController.value = matrix;
  }

  StudioTheme get _theme => StudioPalettes.all[_themeIndex % StudioPalettes.all.length];

  List<MindMapDeck> get _filteredDecks {
    if (_selectedGrade == 'All') return _allDecks;
    return _allDecks.where((d) => d.gradeLevel == _selectedGrade).toList();
  }

  void _switchDeck(MindMapDeck deck) {
    setState(() {
      _currentDeck = deck;
      _themeIndex = deck.themeIndex;
      _expandDefaultNodes();
      _selectedNode = deck.rootNode;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOnRoot());
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedNodeIds.contains(id)) {
        _expandedNodeIds.remove(id);
      } else {
        _expandedNodeIds.add(id);
      }
    });
  }

  void _toggleExpandAll() {
    setState(() {
      if (_expandedNodeIds.length > 1) {
        _expandedNodeIds.clear();
        _expandedNodeIds.add(_currentDeck.rootNode.id);
      } else {
        void recAdd(MindMapNode n) {
          _expandedNodeIds.add(n.id);
          for (final c in n.children) {
            recAdd(c);
          }
        }
        recAdd(_currentDeck.rootNode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final layout = _computeMindMapLayout();

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mind Map Studio',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.primaryText,
              ),
            ),
            Text(
              '${_currentDeck.title} • ${_currentDeck.gradeLevel}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: theme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Topic Switcher
          PopupMenuButton<MindMapDeck>(
            tooltip: 'Switch Mind Map',
            icon: Icon(Icons.menu_book_rounded, color: theme.accent),
            onSelected: _switchDeck,
            itemBuilder: (context) {
              return _filteredDecks.map((deck) {
                return PopupMenuItem<MindMapDeck>(
                  value: deck,
                  child: Row(
                    children: [
                      Icon(
                        deck.id == _currentDeck.id ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 16,
                        color: deck.id == _currentDeck.id ? theme.accent : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          deck.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: deck.id == _currentDeck.id ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          deck.gradeLevel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          // Palette Selector
          PopupMenuButton<int>(
            tooltip: 'Color Palette',
            icon: Icon(Icons.palette_outlined, color: theme.accent),
            onSelected: (idx) => setState(() => _themeIndex = idx),
            itemBuilder: (context) {
              return List.generate(StudioPalettes.all.length, (index) {
                final p = StudioPalettes.all[index];
                return PopupMenuItem<int>(
                  value: index,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: _themeIndex == index ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Grade Filter Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildGradeFilterBar(theme),
          ),

          // 2. Interactive 2D Mind Map Canvas
          Positioned.fill(
            top: _filteredDecks.length > 1 ? 90 : 48,
            child: InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(1200),
              minScale: 0.3,
              maxScale: 2.5,
              constrained: false,
              child: SizedBox(
                width: _canvasWidth,
                height: _canvasHeight,
                child: Stack(
                  children: [
                    // Canvas grid lines for spatial depth
                    CustomPaint(
                      size: const Size(_canvasWidth, _canvasHeight),
                      painter: _MindMapGridPainter(gridColor: theme.border.withValues(alpha: 0.35)),
                    ),

                    // Curved Bezier Branch Lines
                    CustomPaint(
                      size: const Size(_canvasWidth, _canvasHeight),
                      painter: _MindMapCurvesPainter(
                        connections: layout.connections,
                      ),
                    ),

                    // Rendered Node Widgets
                    ...layout.nodes.map((nodePos) {
                      return Positioned(
                        left: nodePos.x,
                        top: nodePos.y,
                        child: _buildNodeWidget(nodePos, theme),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // 3. Floating Map Controls (Zoom +, Zoom -, Reset, Expand All)
          Positioned(
            right: 16,
            bottom: _selectedNode != null ? 140 : 20,
            child: _buildFloatingControls(theme),
          ),

          // 4. Selected Node Detail Bottom Card
          if (_selectedNode != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildNodeDetailCard(theme),
            ),
        ],
      ),
    );
  }

  Widget _buildGradeFilterBar(StudioTheme theme) {
    return Container(
      color: theme.background.withValues(alpha: 0.95),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: StudioPreTemplates.allGrades.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final grade = StudioPreTemplates.allGrades[i];
                final isSelected = grade == _selectedGrade;
                return FilterChip(
                  label: Text(
                    grade,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : theme.primaryText,
                    ),
                  ),
                  selected: isSelected,
                  showCheckmark: false,
                  backgroundColor: theme.cardBackground,
                  selectedColor: theme.accent,
                  side: BorderSide(
                    color: isSelected ? theme.accent : theme.border,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) {
                    setState(() {
                      _selectedGrade = grade;
                      final filtered = _filteredDecks;
                      if (filtered.isNotEmpty && !filtered.any((d) => d.id == _currentDeck.id)) {
                        _switchDeck(filtered.first);
                      }
                    });
                  },
                );
              },
            ),
          ),
          if (_filteredDecks.length > 1) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 36,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filteredDecks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final d = _filteredDecks[idx];
                  final isCurrent = d.id == _currentDeck.id;
                  return InkWell(
                    onTap: () => _switchDeck(d),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCurrent ? theme.accent.withValues(alpha: 0.15) : theme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? theme.accent : theme.border,
                          width: isCurrent ? 1.6 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            d.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                              color: isCurrent ? theme.accent : theme.primaryText,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d.subject,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: theme.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFloatingControls(StudioTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Zoom In',
            icon: Icon(Icons.add_rounded, size: 20, color: theme.primaryText),
            onPressed: () => _zoom(1.2),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            tooltip: 'Zoom Out',
            icon: Icon(Icons.remove_rounded, size: 20, color: theme.primaryText),
            onPressed: () => _zoom(0.8),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          const Divider(height: 8, indent: 4, endIndent: 4),
          IconButton(
            tooltip: 'Center Mind Map',
            icon: Icon(Icons.filter_center_focus_rounded, size: 20, color: theme.accent),
            onPressed: _centerOnRoot,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
          IconButton(
            tooltip: _expandedNodeIds.length > 1 ? 'Collapse All' : 'Expand All',
            icon: Icon(
              _expandedNodeIds.length > 1 ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              size: 20,
              color: theme.accent,
            ),
            onPressed: _toggleExpandAll,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeDetailCard(StudioTheme theme) {
    final node = _selectedNode!;
    final isRoot = node.id == _currentDeck.rootNode.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.accent.withValues(alpha: 0.4), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRoot ? Icons.hub_rounded : Icons.bubble_chart_rounded,
              color: theme.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: theme.primaryText,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, size: 18, color: theme.secondaryText),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _selectedNode = null),
                    ),
                  ],
                ),
                if (node.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    node.detail,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
                if (node.children.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${node.children.length} connected sub-branches',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.accent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeWidget(_NodePosition nodePos, StudioTheme theme) {
    final node = nodePos.node;
    final isSelected = _selectedNode?.id == node.id;
    final isExpanded = _expandedNodeIds.contains(node.id);
    final hasChildren = node.children.isNotEmpty;

    if (nodePos.level == 0) {
      // Root Node (Center)
      return GestureDetector(
        onTap: () => setState(() => _selectedNode = node),
        child: Container(
          width: nodePos.width,
          height: nodePos.height,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accent,
                theme.accent.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              if (isSelected)
                BoxShadow(
                  color: Colors.white,
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (node.detail.isNotEmpty)
                      Text(
                        node.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (nodePos.level == 1) {
      // Level 1 Branch Node
      final branchColor = nodePos.branchColor;
      return GestureDetector(
        onTap: () => setState(() => _selectedNode = node),
        child: Container(
          width: nodePos.width,
          height: nodePos.height,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? branchColor : branchColor.withValues(alpha: 0.45),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: branchColor.withValues(alpha: isSelected ? 0.22 : 0.08),
                blurRadius: isSelected ? 12 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 36,
                decoration: BoxDecoration(
                  color: branchColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: theme.primaryText,
                      ),
                    ),
                    if (node.detail.isNotEmpty)
                      Text(
                        node.detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: theme.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasChildren)
                GestureDetector(
                  onTap: () => _toggleExpand(node.id),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: branchColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isExpanded ? Icons.remove_rounded : Icons.add_rounded,
                      size: 14,
                      color: branchColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Level 2 Leaf Node
    final branchColor = nodePos.branchColor;
    return GestureDetector(
      onTap: () => setState(() => _selectedNode = node),
      child: Container(
        width: nodePos.width,
        height: nodePos.height,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? branchColor : theme.border,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: branchColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.primaryText,
                    ),
                  ),
                  if (node.detail.isNotEmpty)
                    Text(
                      node.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        color: theme.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compute genuine 2D positions for all nodes and connecting Bezier curves
  _MindMapLayout _computeMindMapLayout() {
    final root = _currentDeck.rootNode;
    final List<_NodePosition> nodePositions = [];
    final List<_BezierConnection> connections = [];

    // Root Position (Center)
    final rootX = _centerX - (_rootWidth / 2);
    final rootY = _centerY - (_rootHeight / 2);
    nodePositions.add(
      _NodePosition(
        node: root,
        level: 0,
        x: rootX,
        y: rootY,
        width: _rootWidth,
        height: _rootHeight,
        branchColor: _theme.accent,
      ),
    );

    if (!_expandedNodeIds.contains(root.id)) {
      return _MindMapLayout(nodes: nodePositions, connections: connections);
    }

    // Split Level 1 children into Right side and Left side
    final l1Children = root.children;
    final rightChildren = <MindMapNode>[];
    final leftChildren = <MindMapNode>[];

    for (int i = 0; i < l1Children.length; i++) {
      if (i % 2 == 0) {
        rightChildren.add(l1Children[i]);
      } else {
        leftChildren.add(l1Children[i]);
      }
    }

    // Layout Right Side
    _layoutBranchSide(
      sideChildren: rightChildren,
      isRight: true,
      rootX: rootX,
      rootY: rootY,
      nodePositions: nodePositions,
      connections: connections,
    );

    // Layout Left Side
    _layoutBranchSide(
      sideChildren: leftChildren,
      isRight: false,
      rootX: rootX,
      rootY: rootY,
      nodePositions: nodePositions,
      connections: connections,
    );

    return _MindMapLayout(nodes: nodePositions, connections: connections);
  }

  void _layoutBranchSide({
    required List<MindMapNode> sideChildren,
    required bool isRight,
    required double rootX,
    required double rootY,
    required List<_NodePosition> nodePositions,
    required List<_BezierConnection> connections,
  }) {
    if (sideChildren.isEmpty) return;

    final double l1X = isRight
        ? rootX + _rootWidth + 120
        : rootX - _l1Width - 120;

    // Estimate total vertical span needed for Level 1 and expanded Level 2 children
    final double spacing = 160.0;
    final double totalHeight = sideChildren.length * spacing;
    final double startY = _centerY - (totalHeight / 2) + (spacing / 2) - (_l1Height / 2);

    for (int i = 0; i < sideChildren.length; i++) {
      final child = sideChildren[i];
      final childY = startY + (i * spacing);
      final branchColor = _branchColors[(i * 2 + (isRight ? 0 : 1)) % _branchColors.length];

      nodePositions.add(
        _NodePosition(
          node: child,
          level: 1,
          x: l1X,
          y: childY,
          width: _l1Width,
          height: _l1Height,
          branchColor: branchColor,
        ),
      );

      // Connect Root to Level 1
      connections.add(
        _BezierConnection(
          startX: isRight ? rootX + _rootWidth : rootX,
          startY: rootY + (_rootHeight / 2),
          endX: isRight ? l1X : l1X + _l1Width,
          endY: childY + (_l1Height / 2),
          color: branchColor,
          isRight: isRight,
          strokeWidth: 2.8,
        ),
      );

      // Layout Level 2 children if this L1 node is expanded
      if (_expandedNodeIds.contains(child.id) && child.children.isNotEmpty) {
        final l2Children = child.children;
        final double l2X = isRight
            ? l1X + _l1Width + 90
            : l1X - _l2Width - 90;

        final double l2Spacing = 76.0;
        final double l2TotalHeight = l2Children.length * l2Spacing;
        final double l2StartY = childY + (_l1Height / 2) - (l2TotalHeight / 2) + (l2Spacing / 2) - (_l2Height / 2);

        for (int j = 0; j < l2Children.length; j++) {
          final l2Node = l2Children[j];
          final l2Y = l2StartY + (j * l2Spacing);

          nodePositions.add(
            _NodePosition(
              node: l2Node,
              level: 2,
              x: l2X,
              y: l2Y,
              width: _l2Width,
              height: _l2Height,
              branchColor: branchColor,
            ),
          );

          // Connect Level 1 to Level 2
          connections.add(
            _BezierConnection(
              startX: isRight ? l1X + _l1Width : l1X,
              startY: childY + (_l1Height / 2),
              endX: isRight ? l2X : l2X + _l2Width,
              endY: l2Y + (_l2Height / 2),
              color: branchColor.withValues(alpha: 0.7),
              isRight: isRight,
              strokeWidth: 1.8,
            ),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// DATA STRUCTURES & CANVAS PAINTERS
// ---------------------------------------------------------------------------

class _NodePosition {
  final MindMapNode node;
  final int level;
  final double x;
  final double y;
  final double width;
  final double height;
  final Color branchColor;

  _NodePosition({
    required this.node,
    required this.level,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.branchColor,
  });
}

class _BezierConnection {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final Color color;
  final bool isRight;
  final double strokeWidth;

  _BezierConnection({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.color,
    required this.isRight,
    required this.strokeWidth,
  });
}

class _MindMapLayout {
  final List<_NodePosition> nodes;
  final List<_BezierConnection> connections;

  _MindMapLayout({required this.nodes, required this.connections});
}

/// Draws smooth organic cubic Bezier curves between mindmap nodes
class _MindMapCurvesPainter extends CustomPainter {
  final List<_BezierConnection> connections;

  _MindMapCurvesPainter({required this.connections});

  @override
  void paint(Canvas canvas, Size size) {
    for (final conn in connections) {
      // Subtle glow underlay
      final glowPaint = Paint()
        ..color = conn.color.withValues(alpha: 0.22)
        ..strokeWidth = conn.strokeWidth + 3.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      // Solid branch curve
      final paint = Paint()
        ..color = conn.color
        ..strokeWidth = conn.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      final path = Path();
      path.moveTo(conn.startX, conn.startY);

      final dx = conn.endX - conn.startX;
      final controlPoint1X = conn.startX + (dx * 0.5);
      final controlPoint1Y = conn.startY;
      final controlPoint2X = conn.startX + (dx * 0.5);
      final controlPoint2Y = conn.endY;

      path.cubicTo(
        controlPoint1X,
        controlPoint1Y,
        controlPoint2X,
        controlPoint2Y,
        conn.endX,
        conn.endY,
      );

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);

      // Draw anchor dot at the destination node
      final dotPaint = Paint()
        ..color = conn.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(conn.endX, conn.endY), conn.strokeWidth + 1.5, dotPaint);

      final whiteDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(conn.endX, conn.endY), 1.5, whiteDot);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapCurvesPainter oldDelegate) => true;
}

/// Subtle grid background to provide spatial orientation on zoom/pan
class _MindMapGridPainter extends CustomPainter {
  final Color gridColor;

  _MindMapGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    const step = 60.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindMapGridPainter oldDelegate) => false;
}
