import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: Stack(
          children: [
            Center(
              child: MacosDock(
                items: [
                  DockItem(icon: Icons.person, onTap: () {}),
                  DockItem(icon: Icons.message, onTap: () {}),
                  DockItem(icon: Icons.call, onTap: () {}),
                  DockItem(icon: Icons.camera, onTap: () {}),
                  DockItem(icon: Icons.photo, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DockItem {
  final IconData icon;
  final VoidCallback onTap;

  DockItem({required this.icon, required this.onTap});
}

class MacosDock extends StatefulWidget {
  final List<DockItem> items;
  final double baseSize;
  final double maxScale;

  const MacosDock({
    super.key,
    required this.items,
    this.baseSize = 48.0,
    this.maxScale = 1.5,
  });

  @override
  _MacosDockState createState() => _MacosDockState();
}

class _MacosDockState extends State<MacosDock> with SingleTickerProviderStateMixin {
  late final List<double> _itemScales;
  late List<DockItem> _items;
  int? _hoveredIndex;
  DockItem? _draggedItem;
  int? _draggedOriginalIndex;
  int? _potentialInsertIndex;
  late AnimationController _insertAnimationController;
  late Animation<double> _insertAnimation;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _itemScales = List.filled(_items.length, 1.0);

    // Initialize animation controller
    _insertAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _insertAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _insertAnimationController,
        curve: Curves.easeInOutQuad,
      ),
    );
  }

  @override
  void dispose() {
    _insertAnimationController.dispose();
    super.dispose();
  }

  void _updateHover(int? index) {
    setState(() {
      _hoveredIndex = index;

      // Reset all scales
      for (int i = 0; i < _itemScales.length; i++) {
        _itemScales[i] = 1.0;
      }

      // Scale up hovered and adjacent items
      if (index != null) {
        _itemScales[index] = widget.maxScale;

        if (index > 0) {
          _itemScales[index - 1] = 1.3;
        }
        if (index < _itemScales.length - 1) {
          _itemScales[index + 1] = 1.3;
        }
      }
    });
  }

  void _onDragStart(DockItem item, int index) {
    setState(() {
      _draggedItem = item;
      _draggedOriginalIndex = index;
      _potentialInsertIndex = null;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    double accumulatedWidth = 0;
    for (int i = 0; i <= _items.length; i++) {
      double itemWidth = (i < _items.length ? widget.baseSize * _itemScales[i] : 0) + 16; // Increased padding

      if (localPosition.dx < accumulatedWidth + itemWidth / 2) {
        setState(() {
          _potentialInsertIndex = i == _draggedOriginalIndex ? null : i;
        });

        // Start insert animation if not already running
        if (!_insertAnimationController.isAnimating) {
          _insertAnimationController.forward(from: 0);
        }
        return;
      }

      accumulatedWidth += itemWidth;
    }

    setState(() {
      _potentialInsertIndex = null;
    });
  }

  void _onDragEnd() {
    if (_potentialInsertIndex != null && _draggedItem != null) {
      setState(() {
        // Remove the item from its original position
        _items.removeAt(_draggedOriginalIndex!);

        // Insert at the new position
        _items.insert(_potentialInsertIndex!, _draggedItem!);
      });
    }

    setState(() {
      _draggedItem = null;
      _draggedOriginalIndex = null;
      _potentialInsertIndex = null;
    });

    // Reset animation
    _insertAnimationController.reset();
  }

  Widget _buildDockItem(DockItem item, int index) {
    return AnimatedBuilder(
      animation: _insertAnimation,
      builder: (context, child) {
        // Calculate dynamic spacing
        double extraSpacing = _potentialInsertIndex == index
            ? 40 * _insertAnimation.value  // Smooth expansion
            : 8;  // Default spacing

        return Container(
          margin: EdgeInsets.symmetric(horizontal: extraSpacing),
          child: Draggable<DockItem>(
            data: item,
            feedback: _buildItemFeedback(item),
            childWhenDragging: const SizedBox.shrink(),
            onDragStarted: () => _onDragStart(item, index),
            child: DragTarget<DockItem>(
              builder: (context, candidateData, rejectedData) {
                return MouseRegion(
                  onEnter: (_) => _updateHover(index),
                  onExit: (_) => _updateHover(null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: widget.baseSize * _itemScales[index],
                    height: widget.baseSize * _itemScales[index],
                    decoration: BoxDecoration(
                      color: Colors.primaries[index % Colors.primaries.length].withOpacity(0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: widget.baseSize * 0.6 * _itemScales[index],
                      ),
                    ),
                  ),
                );
              },
            ),
            onDragUpdate: (details) => _onDragUpdate(details, context),
            onDragEnd: (_) => _onDragEnd(),
          ),
        );
      },
    );
  }

  Widget _buildItemFeedback(DockItem item) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: widget.baseSize * widget.maxScale,
        height: widget.baseSize * widget.maxScale,
        decoration: BoxDecoration(
          color: Colors.primaries[_items.indexOf(item) % Colors.primaries.length].withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            item.icon,
            color: Colors.white,
            size: widget.baseSize * 0.6 * widget.maxScale,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          return _buildDockItem(entry.value, entry.key);
        }).toList(),
      ),
    );
  }
}