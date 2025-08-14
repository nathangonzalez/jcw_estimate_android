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
