// android/app/build.gradle.kts

import java.util.Properties
import java.io.FileInputStream
import org.gradle.jvm.toolchain.JavaLanguageVersion

plugins {
    id("com.android.application")
    kotlin("android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun getLocalProperty(key: String, project: org.gradle.api.Project): String {
    val properties = Properties()
    val localPropertiesFile = project.rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        properties.load(FileInputStream(localPropertiesFile))
        return properties.getProperty(key) ?: "1"
    }
    return "1"
}

android {
    // This is your app's unique identity.
    namespace = "com.chiranthan.project_kavach_app"
    
    compileSdk = 35 
    ndkVersion = "27.0.12077973"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = "1.8"
    }

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(17))
        }
    }

    defaultConfig {
        // This MUST match the namespace and your old app's ID.
        applicationId = "com.chiranthan.project_kavach_app"
        minSdk = 21
        targetSdk = 35 
        
        versionCode = getLocalProperty("flutter.versionCode", project).toInt()
        versionName = getLocalProperty("flutter.versionName", project)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation("androidx.multidex:multidex:2.0.1")
}