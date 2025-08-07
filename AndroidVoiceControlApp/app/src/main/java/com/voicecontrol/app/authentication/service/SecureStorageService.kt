package com.voicecontrol.app.authentication.service

import android.content.Context
import android.util.Log
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKeys
import com.voicecontrol.app.BuildConfig
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import javax.inject.Inject
import javax.inject.Singleton

/**
 * Secure Storage Service for Voice Control App
 * 
 * Direct port of iOS KeychainService to Android using EncryptedSharedPreferences
 * Provides secure storage for sensitive data like authentication tokens and user credentials
 * 
 * Features:
 * - Hardware-backed encryption when available (equivalent to iOS Keychain)
 * - JSON serialization for complex objects (equivalent to iOS Codable)
 * - Automatic key management with Android Keystore
 * - Type-safe retrieval and storage operations
 * - Comprehensive error handling and logging
 */
@Singleton
class SecureStorageService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val TAG = "SecureStorageService"
        private const val PREFERENCES_FILE_NAME = "voice_control_secure_prefs"
        private const val KEY_USER_DATA = "current_user"
        private const val KEY_FIREBASE_TOKEN = "firebase_id_token"
        private const val KEY_GUEST_DATA = "guest_user"
        private const val KEY_BIOMETRIC_ENABLED = "biometric_auth_enabled"
        private const val KEY_SUBSCRIPTION_DATA = "subscription_data"
    }
    
    // JSON serializer with lenient settings
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        isLenient = true
    }
    
    // Master key for encryption
    private val masterKeyAlias = MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC)
    
    // Encrypted SharedPreferences instance
    private val encryptedPrefs by lazy {
        try {
            EncryptedSharedPreferences.create(
                PREFERENCES_FILE_NAME,
                masterKeyAlias,
                context,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to create EncryptedSharedPreferences", e)
            }
            throw SecureStorageException("Failed to initialize secure storage: ${e.message}", e)
        }
    }
    
    /**
     * Save serializable object to secure storage
     * Equivalent to iOS KeychainService.save(_:for:)
     * 
     * @param T The type of object to save (must be Serializable)
     * @param data The object to save
     * @param key The key to store the object under
     * @throws SecureStorageException if saving fails
     */
    inline fun <reified T> save(data: T, key: String) {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "💾 Saving data for key: $key")
            }
            
            val jsonString = json.encodeToString(data)
            
            encryptedPrefs.edit()
                .putString(key, jsonString)
                .apply()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Successfully saved data for key: $key")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to save data for key: $key", e)
            }
            throw SecureStorageException("Failed to save data for key $key: ${e.message}", e)
        }
    }
    
    /**
     * Retrieve and deserialize object from secure storage
     * Equivalent to iOS KeychainService.retrieve(_:as:)
     * 
     * @param T The type of object to retrieve
     * @param key The key to retrieve the object for
     * @return The deserialized object
     * @throws SecureStorageException if retrieval or deserialization fails
     */
    inline fun <reified T> retrieve(key: String): T {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "📖 Retrieving data for key: $key")
            }
            
            val jsonString = encryptedPrefs.getString(key, null)
                ?: throw SecureStorageException("No data found for key: $key")
            
            val data = json.decodeFromString<T>(jsonString)
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ Successfully retrieved data for key: $key")
            }
            
            return data
            
        } catch (e: SecureStorageException) {
            throw e
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to retrieve data for key: $key", e)
            }
            throw SecureStorageException("Failed to retrieve data for key $key: ${e.message}", e)
        }
    }
    
    /**
     * Safely retrieve object, returning null if not found
     * Equivalent to iOS optional KeychainService operations
     * 
     * @param T The type of object to retrieve
     * @param key The key to retrieve the object for
     * @return The deserialized object or null if not found
     */
    inline fun <reified T> retrieveOrNull(key: String): T? {
        return try {
            retrieve<T>(key)
        } catch (e: SecureStorageException) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🔍 No data found for key: $key")
            }
            null
        }
    }
    
    /**
     * Delete data for given key
     * Equivalent to iOS KeychainService.delete(_:)
     * 
     * @param key The key to delete data for
     * @return true if data was deleted, false if key didn't exist
     */
    fun delete(key: String): Boolean {
        return try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "🗑️ Deleting data for key: $key")
            }
            
            val existed = encryptedPrefs.contains(key)
            
            encryptedPrefs.edit()
                .remove(key)
                .apply()
            
            if (BuildConfig.ENABLE_LOGGING) {
                if (existed) {
                    Log.d(TAG, "✅ Successfully deleted data for key: $key")
                } else {
                    Log.d(TAG, "ℹ️ Key did not exist: $key")
                }
            }
            
            existed
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to delete data for key: $key", e)
            }
            false
        }
    }
    
    /**
     * Check if key exists in secure storage
     * Equivalent to iOS KeychainService existence checks
     * 
     * @param key The key to check for
     * @return true if key exists
     */
    fun contains(key: String): Boolean {
        return try {
            encryptedPrefs.contains(key)
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to check existence for key: $key", e)
            }
            false
        }
    }
    
    /**
     * Clear all secure storage data
     * Equivalent to iOS KeychainService.clearAll()
     * 
     * USE WITH CAUTION - This will sign out the user
     */
    fun clearAll() {
        try {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.w(TAG, "⚠️ Clearing ALL secure storage data")
            }
            
            encryptedPrefs.edit()
                .clear()
                .apply()
            
            if (BuildConfig.ENABLE_LOGGING) {
                Log.d(TAG, "✅ All secure storage data cleared")
            }
            
        } catch (e: Exception) {
            if (BuildConfig.ENABLE_LOGGING) {
                Log.e(TAG, "❌ Failed to clear secure storage", e)
            }
            throw SecureStorageException("Failed to clear secure storage: ${e.message}", e)
        }
    }
    
    // MARK: - Convenience methods for specific data types
    
    /**
     * Save current user data
     * Equivalent to iOS KeychainService.save(user, for: "current_user")
     */
    inline fun <reified T> saveCurrentUser(user: T) {
        save(user, KEY_USER_DATA)
    }
    
    /**
     * Retrieve current user data
     * Equivalent to iOS KeychainService.retrieve("current_user", as: User.self)
     */
    inline fun <reified T> getCurrentUser(): T? {
        return retrieveOrNull<T>(KEY_USER_DATA)
    }
    
    /**
     * Delete current user data
     * Equivalent to iOS KeychainService.delete("current_user")
     */
    fun deleteCurrentUser(): Boolean {
        return delete(KEY_USER_DATA)
    }
    
    /**
     * Save Firebase ID token
     * Equivalent to iOS KeychainService.save(token, for: "firebase_id_token")
     */
    fun saveFirebaseToken(token: String) {
        save(token, KEY_FIREBASE_TOKEN)
    }
    
    /**
     * Retrieve Firebase ID token
     * Equivalent to iOS KeychainService.retrieve("firebase_id_token", as: String.self)
     */
    fun getFirebaseToken(): String? {
        return retrieveOrNull<String>(KEY_FIREBASE_TOKEN)
    }
    
    /**
     * Delete Firebase ID token
     * Equivalent to iOS KeychainService.delete("firebase_id_token")
     */
    fun deleteFirebaseToken(): Boolean {
        return delete(KEY_FIREBASE_TOKEN)
    }
    
    /**
     * Save guest user data
     * Equivalent to iOS GuestUser.saveToUserDefaults()
     */
    inline fun <reified T> saveGuestUser(guestUser: T) {
        save(guestUser, KEY_GUEST_DATA)
    }
    
    /**
     * Retrieve guest user data
     * Equivalent to iOS GuestUser.fromUserDefaults()
     */
    inline fun <reified T> getGuestUser(): T? {
        return retrieveOrNull<T>(KEY_GUEST_DATA)
    }
    
    /**
     * Delete guest user data
     * Equivalent to iOS GuestUser.clearFromUserDefaults()
     */
    fun deleteGuestUser(): Boolean {
        return delete(KEY_GUEST_DATA)
    }
    
    /**
     * Save biometric authentication preference
     * Equivalent to iOS UserDefaults.standard.set(enabled, forKey: "biometric_auth_enabled")
     */
    fun setBiometricEnabled(enabled: Boolean) {
        save(enabled, KEY_BIOMETRIC_ENABLED)
    }
    
    /**
     * Get biometric authentication preference
     * Equivalent to iOS UserDefaults.standard.bool(forKey: "biometric_auth_enabled")
     */
    fun isBiometricEnabled(): Boolean {
        return retrieveOrNull<Boolean>(KEY_BIOMETRIC_ENABLED) ?: false
    }
    
    /**
     * Save subscription data
     */
    inline fun <reified T> saveSubscriptionData(data: T) {
        save(data, KEY_SUBSCRIPTION_DATA)
    }
    
    /**
     * Retrieve subscription data
     */
    inline fun <reified T> getSubscriptionData(): T? {
        return retrieveOrNull<T>(KEY_SUBSCRIPTION_DATA)
    }
}

/**
 * Custom exception for secure storage operations
 * Equivalent to iOS KeychainService errors
 */
class SecureStorageException(
    message: String,
    cause: Throwable? = null
) : Exception(message, cause)