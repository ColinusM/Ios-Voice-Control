package com.voicecontrol.app.speech.model

import kotlinx.serialization.Serializable

/**
 * Transcription Result Model for Voice Control App
 * 
 * Direct port of iOS TranscriptionResult to Kotlin data class
 * Represents the result of speech-to-text transcription from AssemblyAI
 * 
 * Features:
 * - Text transcription content
 * - Final vs partial transcript indication
 * - Confidence scoring
 * - Timestamp information
 * - Serialization support for state persistence
 */
@Serializable
data class TranscriptionResult(
    /**
     * The transcribed text content
     * Equivalent to iOS text property
     */
    val text: String,
    
    /**
     * Whether this is a final or partial transcript
     * Partial transcripts are updated in real-time
     * Final transcripts are the completed result
     * Equivalent to iOS isFinal property
     */
    val isFinal: Boolean,
    
    /**
     * Confidence score from 0.0 to 1.0
     * Higher values indicate more confident transcription
     * Equivalent to iOS confidence property
     */
    val confidence: Double = 0.0,
    
    /**
     * Timestamp when transcription was received (milliseconds since epoch)
     * Equivalent to iOS timestamp property
     */
    val timestamp: Long = System.currentTimeMillis(),
    
    /**
     * Optional session ID from AssemblyAI
     * Used for tracking and debugging
     */
    val sessionId: String? = null,
    
    /**
     * Optional message ID from AssemblyAI
     * Used for message ordering and deduplication
     */
    val messageId: String? = null,
    
    /**
     * Audio duration in seconds that this transcript covers
     * Useful for timing and synchronization
     */
    val audioDuration: Double? = null,
    
    /**
     * Start time of the audio segment (seconds from start of session)
     * Useful for precise timing alignment
     */
    val audioStart: Double? = null,
    
    /**
     * End time of the audio segment (seconds from start of session)
     * Useful for precise timing alignment  
     */
    val audioEnd: Double? = null
) {
    
    /**
     * Check if this is a meaningful transcription result
     * Filters out empty or very low confidence results
     * Equivalent to iOS isValid computed property
     */
    val isValid: Boolean
        get() = text.isNotBlank() && confidence > 0.1
    
    /**
     * Get display-ready text with proper formatting
     * Trims whitespace and handles punctuation
     * Equivalent to iOS displayText computed property
     */
    val displayText: String
        get() = text.trim().let { trimmed ->
            if (trimmed.isNotEmpty() && !isFinal) {
                // Add ellipsis for partial transcripts to indicate ongoing
                "$trimmed..."
            } else {
                trimmed
            }
        }
    
    /**
     * Get confidence as percentage string
     * Equivalent to iOS confidencePercentage computed property
     */
    val confidencePercentage: String
        get() = "${(confidence * 100).toInt()}%"
    
    /**
     * Check if confidence is above acceptable threshold
     * Equivalent to iOS hasGoodConfidence computed property
     */
    val hasGoodConfidence: Boolean
        get() = confidence >= 0.7 // 70% confidence threshold
    
    /**
     * Get formatted timestamp string
     * Equivalent to iOS formattedTimestamp computed property
     */
    val formattedTimestamp: String
        get() {
            val date = java.util.Date(timestamp)
            val format = java.text.SimpleDateFormat("HH:mm:ss.SSS", java.util.Locale.US)
            return format.format(date)
        }
    
    /**
     * Create a copy with updated text (for partial transcript updates)
     * Equivalent to iOS updatedWith method
     */
    fun updatedWith(newText: String, newConfidence: Double = confidence): TranscriptionResult {
        return copy(
            text = newText,
            confidence = newConfidence,
            timestamp = System.currentTimeMillis()
        )
    }
    
    /**
     * Create final version of this transcript
     * Equivalent to iOS finalized method
     */
    fun finalized(finalText: String = text, finalConfidence: Double = confidence): TranscriptionResult {
        return copy(
            text = finalText,
            isFinal = true,
            confidence = finalConfidence,
            timestamp = System.currentTimeMillis()
        )
    }
    
    companion object {
        
        /**
         * Create empty transcription result
         * Equivalent to iOS empty static property
         */
        fun empty(): TranscriptionResult {
            return TranscriptionResult(
                text = "",
                isFinal = false,
                confidence = 0.0
            )
        }
        
        /**
         * Create placeholder transcription result for loading states
         * Equivalent to iOS loading static property
         */
        fun loading(): TranscriptionResult {
            return TranscriptionResult(
                text = "Listening...",
                isFinal = false,
                confidence = 0.0
            )
        }
        
        /**
         * Create error transcription result
         * Equivalent to iOS error static method
         */
        fun error(errorMessage: String): TranscriptionResult {
            return TranscriptionResult(
                text = "Error: $errorMessage",
                isFinal = true,
                confidence = 0.0
            )
        }
        
        /**
         * Minimum confidence threshold for considering a result valid
         * Equivalent to iOS minConfidenceThreshold static property
         */
        const val MIN_CONFIDENCE_THRESHOLD = 0.1
        
        /**
         * Good confidence threshold for UI indicators
         * Equivalent to iOS goodConfidenceThreshold static property  
         */
        const val GOOD_CONFIDENCE_THRESHOLD = 0.7
        
        /**
         * Excellent confidence threshold for UI indicators
         * Equivalent to iOS excellentConfidenceThreshold static property
         */
        const val EXCELLENT_CONFIDENCE_THRESHOLD = 0.9
    }
}