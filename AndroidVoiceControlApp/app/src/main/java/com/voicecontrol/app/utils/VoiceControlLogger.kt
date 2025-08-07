package com.voicecontrol.app.utils

import android.util.Log
import com.voicecontrol.app.BuildConfig
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Structured Logger for Voice Control App
 * 
 * Enhanced logging system with structured data, performance metrics,
 * and debugging capabilities for Voice Control development
 * 
 * Features:
 * - Structured logging with JSON serialization
 * - Performance timing and metrics
 * - Session tracking and analytics
 * - Memory-efficient circular buffer for debugging
 * - Real-time log streaming for development
 * - Conditional logging based on build configuration
 */
@Singleton
class VoiceControlLogger @Inject constructor() {
    
    companion object {
        private const val MAX_LOG_ENTRIES = 1000
        private const val MAX_PERFORMANCE_ENTRIES = 500
        
        // Log levels matching Android Log levels
        const val VERBOSE = 2
        const val DEBUG = 3
        const val INFO = 4
        const val WARN = 5
        const val ERROR = 6
    }
    
    // JSON serializer for structured data
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
    }
    
    // Coroutine scope for async logging operations
    private val loggingScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    
    // In-memory circular buffer for debug logs
    private val logBuffer = CircularBuffer<LogEntry>(MAX_LOG_ENTRIES)
    
    // Performance metrics tracking
    private val performanceMetrics = ConcurrentHashMap<String, PerformanceEntry>()
    private val performanceBuffer = CircularBuffer<PerformanceEntry>(MAX_PERFORMANCE_ENTRIES)
    
    // Session tracking
    private val sessionId = UUID.randomUUID().toString()
    private val sessionStartTime = System.currentTimeMillis()
    
    // Real-time log streaming for debugging
    private val _logStream = Channel<LogEntry>(Channel.UNLIMITED)
    val logStream: Flow<LogEntry> = _logStream.receiveAsFlow()
    
    /**
     * Structured log entry with metadata
     */
    @Serializable
    data class LogEntry(
        val timestamp: Long,
        val sessionId: String,
        val level: Int,
        val tag: String,
        val message: String,
        val metadata: Map<String, String> = emptyMap(),
        val threadName: String,
        val className: String? = null,
        val methodName: String? = null,
        val lineNumber: Int? = null
    )
    
    /**
     * Performance timing entry
     */
    @Serializable
    data class PerformanceEntry(
        val timestamp: Long,
        val sessionId: String,
        val operationId: String,
        val operationType: String,
        val durationMs: Long,
        val success: Boolean,
        val metadata: Map<String, String> = emptyMap()
    )
    
    /**
     * Session statistics
     */
    @Serializable
    data class SessionStats(
        val sessionId: String,
        val startTime: Long,
        val uptime: Long,
        val totalLogs: Int,
        val errorCount: Int,
        val warningCount: Int,
        val performanceEntries: Int,
        val averageOperationTime: Double
    )
    
    /**
     * Log with structured metadata
     */
    fun log(
        level: Int,
        tag: String,
        message: String,
        metadata: Map<String, String> = emptyMap(),
        throwable: Throwable? = null
    ) {
        // Skip logging if not enabled for this build
        if (!isLoggingEnabled(level)) {
            return
        }
        
        // Get caller information
        val stackTrace = Thread.currentThread().stackTrace
        val callerElement = stackTrace.getOrNull(4) // Skip logger methods
        
        val logEntry = LogEntry(
            timestamp = System.currentTimeMillis(),
            sessionId = sessionId,
            level = level,
            tag = tag,
            message = message,
            metadata = metadata,
            threadName = Thread.currentThread().name,
            className = callerElement?.className,
            methodName = callerElement?.methodName,
            lineNumber = callerElement?.lineNumber
        )
        
        // Add to buffer for debugging
        logBuffer.add(logEntry)
        
        // Stream for real-time monitoring
        _logStream.trySend(logEntry)
        
        // Standard Android logging
        val formattedMessage = formatLogMessage(logEntry)
        when (level) {
            VERBOSE -> Log.v(tag, formattedMessage, throwable)
            DEBUG -> Log.d(tag, formattedMessage, throwable)
            INFO -> Log.i(tag, formattedMessage, throwable)
            WARN -> Log.w(tag, formattedMessage, throwable)
            ERROR -> Log.e(tag, formattedMessage, throwable)
        }
    }
    
    /**
     * Convenience methods for different log levels
     */
    fun v(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        log(VERBOSE, tag, message, metadata)
    }
    
    fun d(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        log(DEBUG, tag, message, metadata)
    }
    
    fun i(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        log(INFO, tag, message, metadata)
    }
    
    fun w(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        log(WARN, tag, message, metadata)
    }
    
    fun e(tag: String, message: String, metadata: Map<String, String> = emptyMap(), throwable: Throwable? = null) {
        log(ERROR, tag, message, metadata, throwable)
    }
    
    /**
     * Performance timing operations
     */
    fun startTiming(operationId: String, operationType: String, metadata: Map<String, String> = emptyMap()) {
        val entry = PerformanceEntry(
            timestamp = System.currentTimeMillis(),
            sessionId = sessionId,
            operationId = operationId,
            operationType = operationType,
            durationMs = 0,
            success = false,
            metadata = metadata
        )
        performanceMetrics[operationId] = entry
        
        if (BuildConfig.ENABLE_LOGGING) {
            d("Performance", "⏱️ Started: $operationType ($operationId)", metadata)
        }
    }
    
    fun endTiming(operationId: String, success: Boolean = true, metadata: Map<String, String> = emptyMap()) {
        val startEntry = performanceMetrics.remove(operationId)
        if (startEntry != null) {
            val duration = System.currentTimeMillis() - startEntry.timestamp
            val finalEntry = startEntry.copy(
                durationMs = duration,
                success = success,
                metadata = startEntry.metadata + metadata
            )
            
            performanceBuffer.add(finalEntry)
            
            if (BuildConfig.ENABLE_LOGGING) {
                val emoji = if (success) "✅" else "❌"
                d("Performance", "$emoji Completed: ${startEntry.operationType} (${duration}ms)", 
                    mapOf("operationId" to operationId, "duration" to "${duration}ms", "success" to success.toString())
                )
            }
        }
    }
    
    /**
     * Inline timing for code blocks
     */
    inline fun <T> time(operationId: String, operationType: String, block: () -> T): T {
        startTiming(operationId, operationType)
        return try {
            val result = block()
            endTiming(operationId, true)
            result
        } catch (e: Exception) {
            endTiming(operationId, false, mapOf("error" to e.message.orEmpty()))
            throw e
        }
    }
    
    /**
     * Get session statistics
     */
    fun getSessionStats(): SessionStats {
        val logs = logBuffer.toList()
        val performances = performanceBuffer.toList()
        
        return SessionStats(
            sessionId = sessionId,
            startTime = sessionStartTime,
            uptime = System.currentTimeMillis() - sessionStartTime,
            totalLogs = logs.size,
            errorCount = logs.count { it.level == ERROR },
            warningCount = logs.count { it.level == WARN },
            performanceEntries = performances.size,
            averageOperationTime = performances.map { it.durationMs }.average()
        )
    }
    
    /**
     * Get recent log entries for debugging
     */
    fun getRecentLogs(limit: Int = 50): List<LogEntry> {
        return logBuffer.toList().takeLast(limit)
    }
    
    /**
     * Get performance metrics for analysis
     */
    fun getPerformanceMetrics(): List<PerformanceEntry> {
        return performanceBuffer.toList()
    }
    
    /**
     * Export logs as JSON for debugging
     */
    fun exportLogsAsJson(): String {
        val data = mapOf(
            "session" to getSessionStats(),
            "logs" to getRecentLogs(100),
            "performance" to getPerformanceMetrics()
        )
        return json.encodeToString(kotlinx.serialization.serializer<Map<String, Any>>(), data)
    }
    
    /**
     * Clear all buffers (for testing or memory management)
     */
    fun clearBuffers() {
        logBuffer.clear()
        performanceBuffer.clear()
        performanceMetrics.clear()
    }
    
    // Private helper methods
    
    private fun isLoggingEnabled(level: Int): Boolean {
        return when {
            BuildConfig.DEBUG -> true
            BuildConfig.ENABLE_LOGGING -> level >= INFO
            else -> level >= ERROR
        }
    }
    
    private fun formatLogMessage(entry: LogEntry): String {
        val metadataString = if (entry.metadata.isNotEmpty()) {
            " | ${entry.metadata.entries.joinToString(", ") { "${it.key}=${it.value}" }}"
        } else ""
        
        return "${entry.message}$metadataString"
    }
    
    /**
     * Thread-safe circular buffer implementation
     */
    private class CircularBuffer<T>(private val capacity: Int) {
        private val buffer = arrayOfNulls<Any>(capacity)
        private var head = 0
        private var tail = 0
        private var size = 0
        
        @Synchronized
        fun add(item: T) {
            buffer[tail] = item
            tail = (tail + 1) % capacity
            
            if (size == capacity) {
                head = (head + 1) % capacity
            } else {
                size++
            }
        }
        
        @Synchronized
        fun toList(): List<T> {
            val result = mutableListOf<T>()
            for (i in 0 until size) {
                val index = (head + i) % capacity
                @Suppress("UNCHECKED_CAST")
                result.add(buffer[index] as T)
            }
            return result
        }
        
        @Synchronized
        fun clear() {
            head = 0
            tail = 0
            size = 0
            buffer.fill(null)
        }
    }
}

/**
 * Global logger instance for easy access
 * Usage: VLogger.d("Tag", "Message", mapOf("key" to "value"))
 */
object VLogger {
    @JvmStatic
    var instance: VoiceControlLogger? = null
    
    fun init(logger: VoiceControlLogger) {
        instance = logger
    }
    
    fun v(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        instance?.v(tag, message, metadata)
    }
    
    fun d(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        instance?.d(tag, message, metadata)
    }
    
    fun i(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        instance?.i(tag, message, metadata)
    }
    
    fun w(tag: String, message: String, metadata: Map<String, String> = emptyMap()) {
        instance?.w(tag, message, metadata)
    }
    
    fun e(tag: String, message: String, metadata: Map<String, String> = emptyMap(), throwable: Throwable? = null) {
        instance?.e(tag, message, metadata, throwable)
    }
    
    fun startTiming(operationId: String, operationType: String, metadata: Map<String, String> = emptyMap()) {
        instance?.startTiming(operationId, operationType, metadata)
    }
    
    fun endTiming(operationId: String, success: Boolean = true, metadata: Map<String, String> = emptyMap()) {
        instance?.endTiming(operationId, success, metadata)
    }
    
    inline fun <T> time(operationId: String, operationType: String, block: () -> T): T {
        return instance?.time(operationId, operationType, block) ?: block()
    }
    
    fun getSessionStats(): VoiceControlLogger.SessionStats? {
        return instance?.getSessionStats()
    }
}