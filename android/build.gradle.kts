import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Align Java/Kotlin JVM targets across Flutter plugins.
// flutter_js (and some older plugins) hardcode Kotlin jvmTarget 1.8 while AGP 9
// defaults JavaCompile to 11, which fails with:
//   Inconsistent JVM-target compatibility ... Java (11) and Kotlin (1.8)
//
// Also: file_picker 11+ skips applying kotlin-android under AGP 9 (expects
// Built-in Kotlin), but Flutter plugin subprojects do not get AGP's built-in
// Kotlin wiring — so Kotlin sources never compile and GeneratedPluginRegistrant
// fails with "cannot find symbol FilePickerPlugin". Force-apply KGP there.
subprojects {
    // Lazy task config — no afterEvaluate, so it plays nicely with evaluationDependsOn(":app").
    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = JavaVersion.VERSION_17.toString()
        targetCompatibility = JavaVersion.VERSION_17.toString()
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }

    pluginManager.withPlugin("com.android.library") {
        extensions.findByType(BaseExtension::class.java)?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
    pluginManager.withPlugin("com.android.application") {
        extensions.findByType(BaseExtension::class.java)?.compileOptions {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
    }
}

// file_picker 11 under AGP 9 skips `kotlin-android` (Built-in Kotlin path),
// but Flutter plugin modules do not compile Kotlin automatically →
// GeneratedPluginRegistrant cannot find FilePickerPlugin. Force KGP.
subprojects {
    if (name == "file_picker") {
        pluginManager.withPlugin("com.android.library") {
            if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
                pluginManager.apply("org.jetbrains.kotlin.android")
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
