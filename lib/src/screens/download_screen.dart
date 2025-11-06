import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('下载管理')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('下载管理', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('这里将显示下载任务', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
