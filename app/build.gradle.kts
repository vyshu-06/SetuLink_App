plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose") version "2.0.21"
    id("com.google.gms.google-services") version "4.4.4"
}

android {
    namespace = "com.example.setulink_app" // Make sure this is your package name
    compileSdk = 36 // Use a recent SDK version

    defaultConfig {
        applicationId = "com.example.setulink_app"
        minSdk = 21 // Minimum SDK for Compose is 21 [5]
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
    // Enable Jetpack Compose [5]
    buildFeatures {
        compose = true
    }
    // Set the Compose compiler version, which is tied to your Kotlin version. [1]
    /*composeOptions {
        kotlinCompilerExtensionVersion = "1.5.15"
    }*/
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    buildToolsVersion = "36.1.0"
}

dependencies {
    // Standard dependencies
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.9.4")
    implementation("androidx.activity:activity-compose:1.11.0")

    // Jetpack Compose Bill of Materials (BOM) - This manages Compose library versions for you. [1]
    val composeBom = platform("androidx.compose:compose-bom:2024.06.00")
    implementation("androidx.compose:compose-bom:2025.10.01")
    androidTestImplementation("androidx.compose:compose-bom:2025.10.01")

    // Compose Dependencies [20]
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.ui.tooling.preview)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.compose.foundation)

    // For the text2 package (includes BasicTextField2)
    implementation(libs.androidx.compose.foundation.text)


    // Test dependencies
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.3.0")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.7.0")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
