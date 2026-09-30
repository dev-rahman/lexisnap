import 'package:flutter/material.dart';

import '../../data/models/app_user.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/initials.dart';

/// The signed-in user's avatar - their photo, or their initials on a navy
/// disc - inside a ring in the user's own hue, with a sliver of page colour
/// between the two so it stays crisp over whatever scrolls underneath it
/// in the shell.
///
/// Drawn once at Profile's header size and scaled by [FittedBox] to
/// whatever it's given. The same widget is a Hero between the shell's 40pt
/// corner button and that header, and a flying Hero passes through every
/// size in between: scaling a finished drawing is just a transform, where
/// sizing ring and type to each frame's size would re-lay out the initials
/// on every frame of the flight.
class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, required this.user});

  /// Shared by the shell button and the Profile header, so the avatar
  /// flies between them when Profile opens and closes.
  static const heroTag = 'app-avatar';

  static const double _drawnSize = 76;
  static const double _ring = _drawnSize * 0.05;

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName?.isNotEmpty == true ? user!.fullName : null;
    // The user's hue, like a deck's: identity colour, stable across runs.
    final hue = AppColors.hueFor(user?.id ?? user?.email ?? '');

    return FittedBox(
      child: Container(
        width: _drawnSize,
        height: _drawnSize,
        padding: const EdgeInsets.all(_ring),
        decoration: BoxDecoration(
          color: context.colorPaper,
          shape: BoxShape.circle,
          border: Border.all(color: hue.resolve(context), width: _ring),
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colorPanel,
            shape: BoxShape.circle,
          ),
          // Initials sit under the photo rather than instead of it: they
          // show while it loads, and stay if it never does.
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  initialsFor(name, user?.email),
                  maxLines: 1,
                  style: AppTextStyles.heading1.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1,
                  ),
                ),
              ),
              if (user?.avatarUrl != null)
                Image.network(
                  user!.avatarUrl!,
                  fit: BoxFit.cover,
                  // Uploads are 256px already; this caps Google/Apple
                  // pictures, which can be far larger, to the same.
                  cacheWidth: 256,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
