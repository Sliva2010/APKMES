// Discover — каталог каналов, ботов и подборок NOCTIS.
// Премиальная монохромная вёрстка, плавные переходы, иконки вместо эмодзи.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/animation/durations_curves.dart';
import '../../core/animation/haptics_service.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Discover'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            const _SectionTitle('Категории'),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (BuildContext _, int __) =>
                    const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  final _Category c = _categories[index];
                  return _CategoryCard(category: c);
                },
              ),
            ),
            const SizedBox(height: 8),
            const _SectionTitle('Каналы'),
            for (final _Channel ch in _channels)
              _ChannelTile(channel: ch),
            const SizedBox(height: 8),
            const _SectionTitle('Боты'),
            for (final _Bot b in _bots) _BotTile(bot: b),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Каталог подобран редакцией NOCTIS',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          letterSpacing: 1.5,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _Category {
  const _Category(this.name, this.icon);
  final String name;
  final IconData icon;
}

const List<_Category> _categories = <_Category>[
  _Category('Дизайн', Icons.brush_outlined),
  _Category('Технологии', Icons.memory_rounded),
  _Category('Музыка', Icons.music_note_outlined),
  _Category('Бизнес', Icons.work_outline_rounded),
  _Category('Книги', Icons.menu_book_outlined),
  _Category('Спорт', Icons.directions_run_rounded),
  _Category('Кино', Icons.movie_outlined),
  _Category('Путешествия', Icons.flight_takeoff_rounded),
];

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});
  final _Category category;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () => HapticsService.tap(),
      child: AnimatedContainer(
        duration: NoctisDurations.tap,
        width: 96,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category.icon,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              category.name,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Channel {
  const _Channel(this.name, this.handle, this.subscribers, this.description,
      this.icon);
  final String name;
  final String handle;
  final String subscribers;
  final String description;
  final IconData icon;
}

const List<_Channel> _channels = <_Channel>[
  _Channel(
    'NOCTIS Daily',
    '@noctis',
    '128K',
    'Официальные новости и фичи.',
    Icons.nights_stay_rounded,
  ),
  _Channel(
    'Дизайн без шума',
    '@silent_design',
    '54K',
    'Минимализм, типографика, ч/б.',
    Icons.brush_outlined,
  ),
  _Channel(
    'Code & Coffee',
    '@codecoffee',
    '212K',
    'Каждое утро — статья и сниппет.',
    Icons.code_rounded,
  ),
  _Channel(
    'Long Reads',
    '@longreads',
    '76K',
    'Большие истории на вечер.',
    Icons.menu_book_outlined,
  ),
];

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.channel});
  final _Channel channel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => HapticsService.tap(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    channel.icon,
                    size: 26,
                    color: theme.colorScheme.surface,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              channel.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${channel.handle} · ${channel.subscribers} подписчиков',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _SubscribeButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticsService.selection();
        setState(() => _on = !_on);
      },
      child: AnimatedContainer(
        duration: NoctisDurations.tap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _on
              ? theme.colorScheme.surface
              : theme.colorScheme.onSurface,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: theme.colorScheme.onSurface,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _on ? Icons.check_rounded : Icons.add_rounded,
              size: 16,
              color: _on
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.surface,
            ),
            const SizedBox(width: 4),
            Text(
              _on ? 'Подписан' : 'Подписаться',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _on
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bot {
  const _Bot(this.name, this.handle, this.description, this.icon);
  final String name;
  final String handle;
  final String description;
  final IconData icon;
}

const List<_Bot> _bots = <_Bot>[
  _Bot(
    'NOCTIS Pay',
    '@pay_bot',
    'Платежи и переводы внутри чата.',
    Icons.account_balance_wallet_outlined,
  ),
  _Bot(
    'NOCTIS Translate',
    '@translate_bot',
    'Мгновенный перевод сообщений.',
    Icons.translate_rounded,
  ),
  _Bot(
    'NOCTIS Tasks',
    '@tasks_bot',
    'Совместные задачи и напоминания.',
    Icons.checklist_rounded,
  ),
  _Bot(
    'NOCTIS Polls',
    '@polls_bot',
    'Опросы и викторины в группах.',
    Icons.poll_outlined,
  ),
];

class _BotTile extends StatelessWidget {
  const _BotTile({required this.bot});
  final _Bot bot;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => HapticsService.tap(),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    bot.icon,
                    size: 22,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        bot.name,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(bot.handle, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        bot.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
