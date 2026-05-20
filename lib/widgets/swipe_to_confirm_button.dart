import 'package:flutter/material.dart';

class SwipeToConfirmButton extends StatefulWidget {
  final String text;
  final VoidCallback onConfirm;
  final Color color;
  final double height;

  const SwipeToConfirmButton({
    Key? key,
    required this.text,
    required this.onConfirm,
    this.color = Colors.green,
    this.height = 60.0,
  }) : super(key: key);

  @override
  State<SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<SwipeToConfirmButton> with SingleTickerProviderStateMixin {
  double _position = 0.0;
  bool _isFinished = false;
  bool _isDragging = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final double thumbSize = widget.height - 8;
        final double maxPosition = (maxWidth - thumbSize - 8).clamp(1.0, double.infinity);

        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Stack(
            children: [
              // Shimmer effect or moving arrows behind the text could be added here
              Center(
                child: Opacity(
                  opacity: (1.0 - (_position / maxPosition)).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.double_arrow, color: widget.color.withValues(alpha: 0.5), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // The progress track
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: _position + thumbSize + 8,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(widget.height / 2),
                  ),
                ),
              ),
              Positioned(
                left: _position + 4,
                top: 4,
                child: GestureDetector(
                  onHorizontalDragStart: (_) => setState(() => _isDragging = true),
                  onHorizontalDragUpdate: (details) {
                    if (_isFinished) return;
                    setState(() {
                      _position += details.delta.dx;
                      if (_position < 0) _position = 0;
                      if (_position > maxPosition) _position = maxPosition;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isFinished) return;
                    setState(() => _isDragging = false);
                    if (_position > maxPosition * 0.8) {
                      setState(() {
                        _position = maxPosition;
                        _isFinished = true;
                      });
                      widget.onConfirm();
                    } else {
                      _animationController.forward(from: 0.0);
                      final double startPos = _position;
                      _animationController.addListener(() {
                        if (mounted) {
                          setState(() {
                            _position = startPos * (1.0 - _animationController.value);
                          });
                        }
                      });
                    }
                  },
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 100),
                    scale: _isDragging ? 1.1 : 1.0,
                    child: Container(
                      width: thumbSize + 10, // Increase hit area slightly
                      height: thumbSize + 10,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.color, widget.color.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: _isFinished ? 0.25 : 0,
                        child: Icon(
                          _isFinished ? Icons.check : Icons.chevron_right,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(SwipeToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      setState(() {
        _position = 0;
        _isFinished = false;
      });
    }
  }
}
