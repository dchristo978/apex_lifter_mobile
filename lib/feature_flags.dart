/// Compile-time feature flags.
library;

/// Whether the muscle map (the 3D/CustomPaint anatomical model and its screen)
/// is reachable from the UI.
///
/// Currently **off**: the model's anatomy is not up to standard yet, so the
/// entry point on the profile screen is hidden while it gets reworked. None of
/// the feature's code has been removed — flip this back to `true` to restore it:
///   - lib/screens/muscle_model_screen.dart  (the full-screen rotatable model)
///   - lib/widgets/muscle_body.dart          (procedural CustomPaint mesh)
///   - lib/widgets/muscle_3d_view.dart       (flutter_scene GPU path)
///   - lib/widgets/muscle_glb_materials.dart + assets_src/muscle.glb
///
/// The dev harnesses (lib/dev_muscle_preview.dart, lib/dev_body_preview.dart)
/// bypass this flag, so the model can still be iterated on in isolation while
/// it stays hidden from users.
const bool kMuscleMapEnabled = false;
