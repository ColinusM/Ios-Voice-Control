# Podfile for VoiceControlApp - Optimized for Fast Builds
platform :ios, '16.0'

target 'VoiceControlApp' do
  use_frameworks!

  # PRECOMPILED FIREBASE FRAMEWORKS (60-80% faster builds)
  # Using community precompiled binaries instead of source compilation
  
  # Core Firebase (precompiled)
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Database' 
  pod 'Firebase/Functions'
  
  # Precompiled Firestore (MASSIVE build time improvement)
  # This eliminates 500k+ lines of C++ compilation
  pod 'FirebaseFirestore', :git => 'https://github.com/invertase/firestore-ios-sdk-frameworks.git', :tag => '11.15.0'
  
  # Google Sign-In
  pod 'GoogleSignIn'
  
  # WebSocket for AssemblyAI
  pod 'Starscream', '~> 4.0.8'

  # Note: HotSwiftUI will be kept as SPM dependency
  # as it's not available via CocoaPods
end

# POST-INSTALL OPTIMIZATIONS FOR FASTER BUILDS
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Ensure iOS 16+ deployment target
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
      
      # SWIFT COMPILATION OPTIMIZATIONS
      if config.name == 'Debug'
        # Use incremental compilation for debug (fastest)
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'singlefile'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
        config.build_settings['GCC_OPTIMIZATION_LEVEL'] = '0'
        # Enable faster debugging
        config.build_settings['ENABLE_TESTABILITY'] = 'YES'
      else
        # Use whole module optimization for release
        config.build_settings['SWIFT_COMPILATION_MODE'] = 'wholemodule'
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-O'
      end
      
      # PARALLEL COMPILATION OPTIMIZATIONS
      config.build_settings['CLANG_ENABLE_MODULE_CACHING'] = 'YES'
      config.build_settings['SWIFT_ENABLE_INCREMENTAL_COMPILATION'] = 'YES'
      
      # Module cache optimizations
      config.build_settings['CLANG_MODULES_BUILD_SESSION_FILE'] = '$(DERIVED_DATA_DIR)/ModuleCache.noindex/Session.modulevalidation'
      
      # Reduce warnings that slow compilation
      config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      config.build_settings['SWIFT_SUPPRESS_WARNINGS'] = 'YES'
      
      # Exclude architectures for simulator (faster builds)
      if target.name == 'FirebaseFirestore' || target.name.include?('Firebase')
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386'
      end
    end
  end
  
  # Fix any potential code signing issues
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:product_type) && target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end
end