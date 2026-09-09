class VideoRecommendation {
  final String id;
  final String title;
  final String channel;
  final String thumbnail;
  final String duration;
  final String url;

  const VideoRecommendation({
    required this.id,
    required this.title,
    required this.channel,
    required this.thumbnail,
    required this.duration,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'channel': channel,
        'thumbnail': thumbnail,
        'duration': duration,
        'url': url,
      };

  factory VideoRecommendation.fromJson(Map<String, dynamic> json) =>
      VideoRecommendation(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Educational Video',
        channel: json['channel']?.toString() ?? 'YouTube Learning',
        thumbnail: json['thumbnail']?.toString() ?? '',
        duration: json['duration']?.toString() ?? '',
        url: json['url']?.toString() ?? 'https://www.youtube.com',
      );
}
