plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    id("com.google.gms.google-services") // Firebase services plugin
    id("com.google.firebase.crashlytics") // Crashlytics plugin
    id("com.google.firebase.firebase-perf") // Performance monitoring
    id("dagger.hilt.android.plugin") // Hilt DI
    kotlin("kapt")
    kotlin("plugin.serialization")
}

android {
    namespace = "com.voicecontrol.app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.voicecontrol.app"
        minSdk = 28
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        // Firebase App Indexing
        manifestPlaceholders["appAuthRedirectScheme"] = "com.voicecontrol.app"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }

        // Build config fields for runtime configuration
        buildConfigField("String", "ASSEMBLYAI_API_KEY", "\"${System.getenv("ASSEMBLYAI_API_KEY") ?: ""}\"")
        buildConfigField("boolean", "ENABLE_LOGGING", "true")
    }

    signingConfigs {
        create("release") {
            storeFile = file("keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = signingConfigs.getByName("release")
            
            // Override build config for release
            buildConfigField("boolean", "ENABLE_LOGGING", "false")
            
            // Firebase Crashlytics
            isDebuggable = false
        }
        
        debug {
            // applicationIdSuffix = ".debug" // Temporarily removed for Firebase compatibility
            isDebuggable = true
            buildConfigField("boolean", "ENABLE_LOGGING", "true")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            freeCompilerArgs.addAll(
                "-Xannotation-default-target=param-property"
            )
        }
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    // Firebase BOM for version alignment
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
    
    // Firebase services (versions managed by BOM)
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-crashlytics-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")
    implementation("com.google.firebase:firebase-perf-ktx")
    
    // Google Sign-In for Android
    implementation("com.google.android.gms:play-services-auth:20.7.0")
    
    // Google Play Billing
    implementation("com.android.billingclient:billing-ktx:6.1.0")
    
    // Android Core
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    implementation("androidx.activity:activity-compose:1.8.2")
    
    // Jetpack Compose
    implementation(platform("androidx.compose:compose-bom:2024.02.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // Navigation Compose
    implementation("androidx.navigation:navigation-compose:2.7.6")
    
    // Hilt Dependency Injection
    implementation("com.google.dagger:hilt-android:2.54")
    kapt("com.google.dagger:hilt-compiler:2.54")
    implementation("androidx.hilt:hilt-navigation-compose:1.1.0")
    
    // Networking
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")
    
    // JSON Serialization
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.6.2")
    
    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.7.3")
    
    // Security
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    
    // Biometric Authentication
    implementation("androidx.biometric:biometric:1.1.0")
    
    // Audio Processing
    implementation("androidx.media3:media3-common:1.2.1")
    
    // Accompanist for system UI
    implementation("com.google.accompanist:accompanist-systemuicontroller:0.32.0")
    implementation("com.google.accompanist:accompanist-permissions:0.32.0")
    
    // Testing
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
    testImplementation("io.mockk:mockk:1.13.8")
    testImplementation("app.cash.turbine:turbine:1.0.0")
    
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2024.02.00"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}

// Hilt annotation processor
kapt {
    correctErrorTypes = true
}