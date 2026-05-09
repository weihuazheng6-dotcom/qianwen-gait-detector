allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 修复 flutter_blue_plus 等插件缺少 compileSdk 的报错
subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library")) {
            project.android.apply {
                compileSdk = 34
                // 如果还需要其他配置可以在这里加
            }
        }
    }
}
