import 'package:blurly/features/blur/data/datasources/gallery_share_data_source.dart';
import 'package:blurly/features/blur/data/datasources/image_picker_data_source.dart';
import 'package:blurly/features/blur/data/datasources/incoming_share_data_source.dart';
import 'package:blurly/features/blur/data/repositories/blur_repository_impl.dart';
import 'package:blurly/features/blur/data/services/selfie_segmentation_model_loader.dart';
import 'package:blurly/features/blur/domain/repositories/blur_repository.dart';
import 'package:blurly/features/blur/domain/usecases/pick_image.dart';
import 'package:blurly/features/blur/domain/usecases/process_blur_image.dart';
import 'package:blurly/features/blur/domain/usecases/save_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/share_blurred_image.dart';
import 'package:blurly/features/blur/domain/usecases/take_photo.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_controller.dart';
import 'package:blurly/features/blur/presentation/controllers/blur_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final imagePickerDataSourceProvider = Provider<ImagePickerDataSource>((ref) {
  return ImagePickerDataSource();
});

final incomingShareDataSourceProvider = Provider<IncomingSharedDataSource>((
  ref,
) {
  return const IncomingSharedDataSource();
});

final galleryShareDataSourceProvider = Provider<GalleryShareDataSource>((ref) {
  return const GalleryShareDataSource();
});

final modelLoaderProvider = Provider<SelfieSegmentationModelLoader>((ref) {
  return SelfieSegmentationModelLoader();
});

final blurRepositoryProvider = Provider<BlurRepository>((ref) {
  return BlurRepositoryImpl(
    pickerDataSource: ref.watch(imagePickerDataSourceProvider),
    galleryShareDataSource: ref.watch(galleryShareDataSourceProvider),
    modelLoader: ref.watch(modelLoaderProvider),
  );
});

final blurControllerProvider = StateNotifierProvider<BlurController, BlurState>(
  (ref) {
    final repository = ref.watch(blurRepositoryProvider);
    return BlurController(
      pickImage: PickImage(repository),
      takePhoto: TakePhoto(repository),
      processBlurImage: ProcessBlurImage(repository),
      saveBlurredImage: SaveBlurredImage(repository),
      shareBlurredImage: ShareBlurredImage(repository),
    );
  },
);
