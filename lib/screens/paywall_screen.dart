import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TenSec Mood プレミアム')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '無料でできること',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _BulletCard(items: [
            '気分チェックイン',
            '履歴の確認',
            '週次レビューの基本集計',
          ]),
          const SizedBox(height: 16),
          Text(
            '有料でできること',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const _BulletCard(items: [
            '長期の振り返り',
            'タグ分析の深掘り',
            'テーマ別のメモ整理',
          ]),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プラン (ダミー)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '月額 ¥480 / 年額 ¥3,800',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {},
                      child: const Text('購入する (準備中)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('課金の透明性'),
                  SizedBox(height: 8),
                  Text('・サブスクリプションは自動更新です。'),
                  Text('・期間終了の24時間前までに解約しない限り更新されます。'),
                  Text('・次回更新日は購入日から期間を加算した日です。'),
                  Text('・解約はApp Storeのサブスク管理から行えます。'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ これはPaywall画面のモックです。購入処理はまだ実装されていません。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('・$item'),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
