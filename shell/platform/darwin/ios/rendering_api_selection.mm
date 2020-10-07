// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/rendering_api_selection.h"

#include <Foundation/Foundation.h>
#include <QuartzCore/CAEAGLLayer.h>
#include <QuartzCore/CAMetalLayer.h>
#if FLUTTER_SHELL_ENABLE_METAL
#include <Metal/Metal.h>
#endif  // FLUTTER_SHELL_ENABLE_METAL

#include "flutter/fml/logging.h"

namespace flutter {

#if FLUTTER_SHELL_ENABLE_METAL
bool ShouldUseMetalRenderer() {
  // Flutter supports Metal on all devices with Apple A7 SoC or above that have been updated to or
  // past iOS 10.0. The processor was selected as it is the first version at which Metal was
  // supported. The iOS version floor was selected due to the availability of features used by Skia.
  bool ios_version_supports_metal = false;
  if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
    auto device = MTLCreateSystemDefaultDevice();
    ios_version_supports_metal = [device supportsFeatureSet:MTLFeatureSet_iOS_GPUFamily1_v3];
  }
  return ios_version_supports_metal;
}
#endif  // FLUTTER_SHELL_ENABLE_METAL

IOSRenderingAPI GetRenderingAPIForProcess(bool force_software) {
  if (force_software) {
    return IOSRenderingAPI::kSoftware;
  }

#if FLUTTER_SHELL_ENABLE_METAL
  static bool should_use_metal = ShouldUseMetalRenderer();
  if (should_use_metal) {
    return IOSRenderingAPI::kMetal;
  }
#endif  // FLUTTER_SHELL_ENABLE_METAL

  // OpenGL will be emulated using software rendering by Apple on the simulator, so we use the
  // Skia software rendering since it performs a little better than the emulated OpenGL.
#if TARGET_IPHONE_SIMULATOR
  return IOSRenderingAPI::kSoftware;
#else
  return IOSRenderingAPI::kOpenGLES;
#endif  // TARGET_IPHONE_SIMULATOR
}

Class GetCoreAnimationLayerClassForRenderingAPI(IOSRenderingAPI rendering_api) {
  switch (rendering_api) {
    case IOSRenderingAPI::kSoftware:
      return [CALayer class];
    case IOSRenderingAPI::kOpenGLES:
      return [CAEAGLLayer class];
    case IOSRenderingAPI::kMetal:
      if (@available(iOS METAL_IOS_VERSION_BASELINE, *)) {
        return [CAMetalLayer class];
      }
      FML_CHECK(false) << "Metal availability should already have been checked";
      break;
    default:
      break;
  }
  FML_CHECK(false) << "Unknown client rendering API";
  return [CALayer class];
}

}  // namespace flutter
