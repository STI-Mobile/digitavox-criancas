import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val distributionFlavors = listOf("dev", "prod")
val signingValueNames = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

// Each store app has its own upload key, read from key-<flavor>.properties or
// from -Pdigitavox.signing.<flavor>.<name>.
fun releaseSigningValues(flavor: String): Map<String, String?> {
    val properties = Properties()
    val propertiesFile = rootProject.file("key-$flavor.properties")
    if (propertiesFile.exists()) {
        propertiesFile.inputStream().use(properties::load)
    }
    return signingValueNames.associateWith { name ->
        providers.gradleProperty("digitavox.signing.$flavor.$name").orNull
            ?: properties.getProperty(name)
    }
}

val releaseSigning = distributionFlavors.associateWith(::releaseSigningValues)
val requestedTaskNames = gradle.startParameter.taskNames.map { it.substringAfterLast(':') }

for ((flavor, values) in releaseSigning) {
    val flavorName = flavor.replaceFirstChar(Char::uppercase)
    // Tasks without a flavor name, such as assembleRelease, build every flavor.
    val releaseArtifactTaskRequested = requestedTaskNames.any { taskName ->
        taskName.matches(Regex("(assemble|bundle|package|sign)($flavorName)?Release.*"))
    }
    val missingValues = values.filterValues { it.isNullOrBlank() }.keys
    if (releaseArtifactTaskRequested && missingValues.isNotEmpty()) {
        throw GradleException(
            "Release signing for the $flavor flavor requires ${missingValues.joinToString()}. " +
                "Create android/key-$flavor.properties or provide " +
                "-Pdigitavox.signing.$flavor.<name>.",
        )
    }
}

android {
    namespace = "br.usp.digitavox_criancas"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.usp.digitavox_criancas"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        for ((flavor, values) in releaseSigning) {
            create(flavor) {
                if (values.values.none { it.isNullOrBlank() }) {
                    storeFile = file(requireNotNull(values["storeFile"]))
                    storePassword = requireNotNull(values["storePassword"])
                    keyAlias = requireNotNull(values["keyAlias"])
                    keyPassword = requireNotNull(values["keyPassword"])
                }
            }
        }
    }

    // See docs/adr/0005-apps-separados-dev-prod.md.
    flavorDimensions += "distribution"
    productFlavors {
        create("dev") {
            dimension = "distribution"
            applicationIdSuffix = ".dev"
            signingConfig = signingConfigs.getByName("dev")
        }
        create("prod") {
            dimension = "distribution"
            signingConfig = signingConfigs.getByName("prod")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
