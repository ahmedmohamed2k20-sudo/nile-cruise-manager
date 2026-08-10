plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}
android {
    namespace = "com.example.nile_cruise_manager"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions { sourceCompatibility = JavaVersion.VERSION_1_8; targetCompatibility = JavaVersion.VERSION_1_8 }
    kotlinOptions { jvmTarget = JavaVersion.VERSION_1_8.toString() }
    defaultConfig { applicationId = "com.example.nile_cruise_manager"; minSdk = flutter.minSdkVersion; targetSdk = flutter.targetSdkVersion; versionCode = flutter.versionCode; versionName = flutter.versionName }
    buildTypes { release { signingConfig = signingConfigs.getByName("debug") } }
    lint { checkReleaseBuilds = false }
}
flutter { source = "../.." }
dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.1.0"))
}
