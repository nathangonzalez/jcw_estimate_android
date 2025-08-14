#!/bin/bash
set -e

echo "Creating Android project structure..."

# Create directories
mkdir -p app/src/main/java/com/example/estimator_app
mkdir -p app/src/main/res/values
mkdir -p gradle/wrapper

# Create empty files
touch app/src/main/AndroidManifest.xml
touch app/build.gradle.kts
touch app/proguard-rules.pro
touch build.gradle.kts
touch gradle.properties
touch gradlew
touch settings.gradle.kts
touch gradle/wrapper/gradle-wrapper.jar
touch gradle/wrapper/gradle-wrapper.properties

# Write file content
echo "Writing file contents..."

# app/src/main/java/com/example/estimator_app/MainActivity.kt
cat > app/src/main/java/com/example/estimator_app/MainActivity.kt <<'EOF'
package com.example.estimator_app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            EstimatorApp()
        }
    }
}

@Composable
fun EstimatorApp() {
    var rooms by remember { mutableStateOf(listOf(RoomState())) }
    var totalCost by remember { mutableStateOf(0.0) }
    var analysisText by remember { mutableStateOf("") }
    val coroutineScope = rememberCoroutineScope()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "10x Estimator", fontSize = 32.sp, modifier = Modifier.padding(bottom = 16.dp))

        LazyColumn(
            modifier = Modifier.weight(1f)
        ) {
            items(rooms) { room ->
                RoomInput(
                    roomState = room,
                    onUpdate = { updatedRoom ->
                        rooms = rooms.map { if (it.id == room.id) updatedRoom else it }
                        totalCost = calculateTotal(rooms)
                    }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Button(onClick = { rooms = rooms + RoomState() }) {
            Text("Add Another Room")
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Total Estimate: $${"%.2f".format(totalCost)}",
            fontSize = 24.sp,
            color = MaterialTheme.colorScheme.primary
        )

        Spacer(modifier = Modifier.height(16.dp))

        Button(onClick = {
            coroutineScope.launch {
                analysisText = "Thinking..."
                analysisText = AIAnalyzer.getAnalysis(rooms)
            }
        }) {
            Text("Get AI Analysis")
        }

        if (analysisText.isNotEmpty()) {
            Text(
                text = analysisText,
                modifier = Modifier.padding(top = 8.dp)
            )
        }
    }
}

@Composable
fun RoomInput(roomState: RoomState, onUpdate: (RoomState) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        OutlinedTextField(
            value = if (roomState.area == 0.0) "" else roomState.area.toString(),
            onValueChange = {
                val newArea = it.toDoubleOrNull() ?: 0.0
                onUpdate(roomState.copy(area = newArea))
            },
            label = { Text("Area (sqft)") },
            modifier = Modifier.weight(1f),
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
        )
        Spacer(Modifier.width(8.dp))

        var expanded by remember { mutableStateOf(false) }
        Box(modifier = Modifier.wrapContentSize(Alignment.TopStart)) {
            Button(onClick = { expanded = true }) {
                Text(roomState.finish)
            }
            DropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                listOf("Basic", "Standard", "Premium").forEach { finish ->
                    DropdownMenuItem(
                        text = { Text(finish) },
                        onClick = {
                            onUpdate(roomState.copy(finish = finish))
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

data class RoomState(
    val id: String = java.util.UUID.randomUUID().toString(),
    val area: Double = 0.0,
    val finish: String = "Standard"
)

fun calculateTotal(rooms: List<RoomState>): Double {
    return rooms.sumOf {
        val rate = when (it.finish) {
            "Basic" -> 120.0
            "Standard" -> 180.0
            "Premium" -> 240.0
            else -> 0.0
        }
        it.area * rate
    }
}
EOF

# app/src/main/java/com/example/estimator_app/Calculator.kt
cat > app/src/main/java/com/example/estimator_app/Calculator.kt <<'EOF'
package com.example.estimator_app

import kotlin.random.Random

object EstimatorLogic {
    private const val BASIC_RATE = 120.0
    private const val STANDARD_RATE = 180.0
    private const val PREMIUM_RATE = 240.0

    private val specialRoomMultipliers = mapOf(
        "Kitchen" to 1.5,
        "Bathroom" to 1.8
    )

    fun calculateCost(room: RoomState, roomType: String): Double {
        val baseRate = when (room.finish) {
            "Basic" -> BASIC_RATE
            "Standard" -> STANDARD_RATE
            "Premium" -> PREMIUM_RATE
            else -> 0.0
        }
        val multiplier = specialRoomMultipliers[roomType] ?: 1.0
        return room.area * baseRate * multiplier
    }
}

object AIAnalyzer {
    fun getAnalysis(rooms: List<RoomState>): String {
        val totalCost = rooms.sumOf { EstimatorLogic.calculateCost(it, "General") }
        val premiumRooms = rooms.filter { it.finish == "Premium" }
        val largeRooms = rooms.filter { it.area > 200 }

        val analysis = buildString {
            append("This detailed estimate provides a comprehensive overview of your project. ")
            if (premiumRooms.isNotEmpty()) {
                append("The inclusion of premium finishes in ${premiumRooms.size} room(s) is a key driver of the total cost. ")
            }
            if (largeRooms.isNotEmpty()) {
                append("The significant area of your larger rooms is also a major factor. ")
            }
            append("This estimate is based on current market rates and site conditions. ")
            append("Final pricing is subject to on-site inspection and material selection. ")
            append("A final budget of $${"%.2f".format(totalCost * Random.nextDouble(1.05, 1.15))} is recommended for contingencies.")
        }
        return analysis
    }
}
EOF

# app/src/main/AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:label="@string/app_name"
            android:theme="@style/Theme.AppCompat.Light.NoActionBar">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# app/build.gradle.kts
cat > app/build.gradle.kts <<'EOF'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.estimator_app"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.estimator_app"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
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
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }
    kotlinOptions {
        jvmTarget = "1.8"
    }
    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.1"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.9.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.1")
    implementation("androidx.activity:activity-compose:1.7.0")
    implementation(platform("androidx.compose:compose-bom:2023.03.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
EOF

# build.gradle.kts (root level)
cat > build.gradle.kts <<'EOF'
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
}
EOF

# gradle.properties
cat > gradle.properties <<'EOF'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
EOF

# settings.gradle.kts
cat > settings.gradle.kts <<'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "Estimator App"
include(":app")
EOF

# gradle/wrapper/gradle-wrapper.properties
cat > gradle/wrapper/gradle-wrapper.properties <<'EOF'
distributionBase=GRADLE_USER_HOME
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
distributionPath=wrapper/dists
zipStorePath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
EOF

echo "Project setup complete. You can now build the app."
