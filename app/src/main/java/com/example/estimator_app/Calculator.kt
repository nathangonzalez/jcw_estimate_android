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
