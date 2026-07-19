import 'dart:async';

import 'package:blurly/features/blur/domain/entities/blur_image.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingSharedListener extends ConsumerStatefulWidget {
  const IncomingSharedListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<IncomingSharedListener> createState() =>
      _IncomingSharedListenerState();
}

class _IncomingSharedListenerState
    extends ConsumerState<IncomingSharedListener> {
  StreamSubscription<BlurImage?>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _listen());
  }

  Future<void> _listen() async {
    final source = ref.read(incomingShareDataSourceProvider);

    _subscription = source.watchSharedImage().listen(_loadSharedImage);

    final initialImage = await source.getInitialSharedImage();
    await _loadSharedImage(initialImage);
  }

  Future<void> _loadSharedImage(BlurImage? image) async {
    if (!mounted || image == null) return;

    await ref.read(blurControllerProvider.notifier).loadSharedImage(image);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
