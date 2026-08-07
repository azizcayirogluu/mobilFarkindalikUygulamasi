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
subprojects {
    afterEvaluate {
        project.extensions.findByName("android")?.let { androidExt ->
            try {
                val namespaceMethod = androidExt.javaClass.methods.find { it.name == "getNamespace" }
                val setNamespaceMethod = androidExt.javaClass.methods.find { it.name == "setNamespace" }
                if (namespaceMethod != null && setNamespaceMethod != null) {
                    val currentNamespace = namespaceMethod.invoke(androidExt)
                    if (currentNamespace == null) {
                        var groupName = project.group.toString()
                        if (groupName.isEmpty()) {
                            groupName = "dev.isar.isar_flutter_libs"
                        }
                        setNamespaceMethod.invoke(androidExt, groupName)
                    }
                }
            } catch (e: Exception) {
                // Ignore
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
