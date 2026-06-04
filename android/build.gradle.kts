allprojects {
    repositories {
        google()
        mavenCentral()
        // Unity Ads Mediation (جزء من Google AdMob Maven)
        maven { url = uri("https://dl.google.com/dl/android/maven2") }
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
// subprojects {
//     project.evaluationDependsOn(":app")
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val configureAndroidProject = {
        if (project.hasProperty("android")) {
            val android = project.extensions.getByName("android")
            
            // 1. Force Compile SDK 35 (Required for Baklava/Android 15 symbols)
            try {
                val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(android, 35)
            } catch (e: Exception) {
                try {
                    val method = android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                    method.invoke(android, 35)
                } catch (e2: Exception) { }
            }

            // 2. Force Java 17 for all subprojects (Fixes Locale.of and threadId errors)
            try {
                val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                val setSource = compileOptions.javaClass.getMethod("setSourceCompatibility", Any::class.java)
                val setTarget = compileOptions.javaClass.getMethod("setTargetCompatibility", Any::class.java)
                setSource.invoke(compileOptions, JavaVersion.VERSION_17)
                setTarget.invoke(compileOptions, JavaVersion.VERSION_17)
            } catch (e: Exception) { }

            // 3. Fix Namespace for AGP 8+
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestContent = manifestFile.readText()
                val packageMatch = Regex("""package="([^"]+)"""").find(manifestContent)
                if (packageMatch != null) {
                    val packageName = packageMatch.groupValues[1]
                    try {
                        val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                        setNamespace.invoke(android, packageName)
                    } catch (e: Exception) { }
                }
            }
        }
    }

    if (project.state.executed) {
        configureAndroidProject()
    } else {
        project.afterEvaluate {
            configureAndroidProject()
        }
    }

    // 4. Force Kotlin JVM Target 17 (Fixes Inconsistent JVM-target error)
    project.tasks.matching { it.name.contains("Kotlin") }.configureEach {
        try {
            val getKotlinOptions = this.javaClass.getMethod("getKotlinOptions")
            val kotlinOptions = getKotlinOptions.invoke(this)
            val setJvmTarget = kotlinOptions.javaClass.getMethod("setJvmTarget", String::class.java)
            setJvmTarget.invoke(kotlinOptions, "17")
        } catch (e: Exception) { }
    }

    // Force specific core version to fix lStar error
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "androidx.core" && (requested.name == "core" || requested.name == "core-ktx")) {
                useVersion("1.13.1")
            }
            if (requested.group == "androidx.browser" && requested.name == "browser") {
                useVersion("1.8.0")
            }
        }
    }
}
