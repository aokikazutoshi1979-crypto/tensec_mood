import 'package:flutter/material.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TenSec Mood プレミアム（構想）')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'この画面はダミーです',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '現在は購入できません。将来の有料化を検討中で、内容と価格は仮の表示です。',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
                    'プラン（仮・購入不可）',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '月額 ¥480 / 年額 ¥3,800（仮）',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: null,
                      child: const Text('購入はまだできません'),
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
                  Text('課金に関する説明（将来の表示例）'),
                  SizedBox(height: 8),
                  Text('※ 現時点では購入・課金は一切ありません。'),
                  SizedBox(height: 8),
                  Text('・例）サブスクリプションは自動更新です。'),
                  Text('・例）期間終了の24時間前までに解約しない限り更新されます。'),
                  Text('・例）次回更新日は購入日から期間を加算した日です。'),
                  Text('・例）解約はApp Storeのサブスク管理から行えます。'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '※ これはPaywall画面のモックです。現在は無料で、購入処理は実装されていません。',
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
