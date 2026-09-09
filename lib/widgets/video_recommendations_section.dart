import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/video_recommendation.dart';
import '../services/video_recommendation_service.dart';
import '../theme/app_theme.dart';

/// Interactive carousel displaying curated YouTube video recommendations
/// matching the user's study doubt or AI lesson response.
class VideoRecommendationsSection extends StatelessWidget {
  final List<VideoRecommendation> videos;
  final bool isDark;
  final VoidCallback? onDismiss;

  const VideoRecommendationsSection({
    super.key,
    required this.videos,
    required this.isDark,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 4, left: 38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0000).withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Recommended Video Lessons',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Watch to clarify',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Horizontal list of video cards
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: videos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final video = videos[index];
                return _VideoCard(video: video, isDark: isDark);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatefulWidget {
  final VideoRecommendation video;
  final bool isDark;

  const _VideoCard({required this.video, required this.isDark});

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final cardBg = widget.isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderCol = widget.isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textCol = widget.isDark ? AppColors.darkForeground : AppColors.lightForeground;
    final subTextCol = widget.isDark ? AppColors.darkMutedForeground : AppColors.lightMutedForeground;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => VideoRecommendationService.launchVideo(widget.video.url),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 190,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFFF0000).withValues(alpha: 0.6)
                  : borderCol,
              width: _isHovered ? 1.2 : 1.0,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF0000).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : (widget.isDark ? AppShadows.darkCard : AppShadows.card),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail preview with Play overlay
                Stack(
                  children: [
                    Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.black26,
                      child: widget.video.thumbnail.isNotEmpty
                          ? Image.network(
                              widget.video.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                child: const Center(
                                  child: Icon(Icons.video_library_rounded, color: Colors.grey, size: 28),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    // Red play badge
                    Positioned.fill(
                      child: Center(
                        child: AnimatedScale(
                          scale: _isHovered ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 180),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                    // Duration badge
                    if (widget.video.duration.isNotEmpty)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.video.duration,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Info: Title & Channel
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.video.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textCol,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.video.channel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                color: subTextCol,
                              ),
                            ),
                          ),
                          Icon(Icons.open_in_new_rounded, size: 10, color: subTextCol),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
