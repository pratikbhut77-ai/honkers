import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

class QuestionPhotoStripWidget extends StatelessWidget {
  const QuestionPhotoStripWidget({super.key});

  static const List<Map<String, String>> _photos = [
    {
      'url':
          'https://images.unsplash.com/photo-1665156958464-90a8b463e1e6',
      'semanticLabel': 'Street food stall with misal pav on display',
    },
    {
      'url':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1180172b9-1781545345152.png',
      'semanticLabel': 'Bowl of spicy misal with bread on wooden table',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CustomImageWidget(
            imageUrl: _photos[i]['url']!,
            width: 120,
            height: 90,
            fit: BoxFit.cover,
            semanticLabel: _photos[i]['semanticLabel']!,
          ),
        ),
      ),
    );
  }
}
