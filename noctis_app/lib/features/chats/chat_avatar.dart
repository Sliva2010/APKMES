// Универсальный аватар чата:
// - для «Избранного» — иконка bookmark
// - для канала — иконка campaign
// - для группы — иконка groups
// - для остальных — картинка, либо инициалы.
import 'dart:io';

import 'package:flutter/material.dart';

import 'chat_repository.dart';

class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.chat, this.size = 48});
  final ChatSummary chat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Особый стиль «Избранного».
    if (chat.isSaved) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.bookmark_rounded,
          color: theme.colorScheme.surface,
          size: size * 0.5,
        ),
      );
    }

    // Картинка-аватар, если есть.
    if (chat.avatarPath != null && File(chat.avatarPath!).existsSync()) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
            width: 1,
          ),
          image: DecorationImage(
            image: FileImage(File(chat.avatarPath!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final IconData? iconForKind = chat.isChannel
        ? Icons.campaign_outlined
        : chat.isGroup
            ? Icons.groups_outlined
            : null;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: iconForKind != null
          ? Icon(
              iconForKind,
              color: theme.colorScheme.onSurface,
              size: size * 0.5,
            )
          : Text(
              chat.initials,
              style: TextStyle(
                fontFamily: 'NoctisSans',
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
                color: theme.colorScheme.onSurface,
              ),
            ),
    );
  }
}
