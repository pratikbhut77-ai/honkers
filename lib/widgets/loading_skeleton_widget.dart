import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingSkeletonWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingSkeletonWidget({
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 8,
    super.key,
  });

  @override
  State<LoadingSkeletonWidget> createState() => _LoadingSkeletonWidgetState();
}

class _LoadingSkeletonWidgetState extends State<LoadingSkeletonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _shimmer = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceVariantDark,
                AppTheme.surfaceElevatedDark,
                AppTheme.surfaceVariantDark,
              ],
              stops: [
                (_shimmer.value - 0.3).clamp(0.0, 1.0),
                _shimmer.value.clamp(0.0, 1.0),
                (_shimmer.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        );
      },
    );
  }
}

// Feed skeleton — replicates question card layout
class QuestionFeedSkeletonWidget extends StatelessWidget {
  const QuestionFeedSkeletonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LoadingSkeletonWidget(
                  width: 60,
                  height: 20,
                  borderRadius: 999,
                ),
                const Spacer(),
                const LoadingSkeletonWidget(
                  width: 80,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const LoadingSkeletonWidget(height: 18, borderRadius: 6),
            const SizedBox(height: 8),
            const LoadingSkeletonWidget(
              height: 14,
              width: 220,
              borderRadius: 6,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const LoadingSkeletonWidget(
                  width: 32,
                  height: 32,
                  borderRadius: 999,
                ),
                const SizedBox(width: 8),
                const LoadingSkeletonWidget(
                  width: 80,
                  height: 14,
                  borderRadius: 4,
                ),
                const Spacer(),
                const LoadingSkeletonWidget(
                  width: 48,
                  height: 14,
                  borderRadius: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
