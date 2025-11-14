import 'package:flutter/material.dart';
import '../models/work.dart';

class RatingDetailPopup extends StatelessWidget {
  final List<RatingDetail> ratingDetails;
  final double averageRating;
  final int totalCount;

  const RatingDetailPopup({
    super.key,
    required this.ratingDetails,
    required this.averageRating,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    // 按照评分从高到低排序
    final sortedDetails = List<RatingDetail>.from(ratingDetails)
      ..sort((a, b) => b.reviewPoint.compareTo(a.reviewPoint));

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '评分详情',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 平均分和总评分数
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    averageRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ 5',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              Text(
                '共 $totalCount 个评分',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 评分分布
          ...sortedDetails.map((detail) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // 星级
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${detail.reviewPoint}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 16,
                  ),
                  const SizedBox(width: 8),

                  // 进度条
                  Expanded(
                    child: Stack(
                      children: [
                        // 背景条
                        Container(
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        // 填充条
                        FractionallySizedBox(
                          widthFactor: detail.ratio / 100.0,
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // 比例和数量
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${detail.ratio}% (${detail.count})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
