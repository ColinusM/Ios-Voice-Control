import Foundation
import StoreKit

// MARK: - Comprehensive Subscription Error Handling

enum SubscriptionError: Error, LocalizedError, Equatable {
    case productNotFound
    case purchaseFailed(underlying: Error?)
    case purchaseCancelled
    case purchasePending
    case purchaseDeferred
    case verificationFailed
    case receiptValidationFailed
    case networkError(underlying: Error?)
    case userNotEligible
    case paymentNotAllowed
    case systemError
    case subscriptionExpired
    case subscriptionNotFound
    case restoreFailed
    case refundFailed
    case appStoreUnavailable
    case parentalControlsActive
    case invalidProductIdentifier
    case unknown(underlying: Error)
    
    // MARK: - User-Friendly Error Messages
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "The subscription plan is currently unavailable. Please try again later."
        case .purchaseFailed:
            return "Unable to complete your purchase. Please try again or contact support."
        case .purchaseCancelled:
            return "Purchase was cancelled. You can try purchasing again anytime."
        case .purchasePending:
            return "Your purchase is being processed. This may take a few moments."
        case .purchaseDeferred:
            return "Purchase requires approval. You'll be notified when it's complete."
        case .verificationFailed:
            return "Unable to verify your purchase. Please try again or contact support."
        case .receiptValidationFailed:
            return "Unable to validate your subscription. Please restore purchases or contact support."
        case .networkError:
            return "Network error occurred. Please check your connection and try again."
        case .userNotEligible:
            return "You're not eligible for this subscription offer. Check requirements and try again."
        case .paymentNotAllowed:
            return "Payments are not allowed on this device. Check restrictions in Settings."
        case .systemError:
            return "A system error occurred. Please restart the app and try again."
        case .subscriptionExpired:
            return "Your subscription has expired. Renew to continue using premium features."
        case .subscriptionNotFound:
            return "No active subscription found. Purchase a plan to unlock premium features."
        case .restoreFailed:
            return "Unable to restore purchases. Please try again or contact support."
        case .refundFailed:
            return "Unable to process refund request. Please contact Apple Support directly."
        case .appStoreUnavailable:
            return "App Store is currently unavailable. Please try again later."
        case .parentalControlsActive:
            return "Parental controls prevent purchases. Check Screen Time settings."
        case .invalidProductIdentifier:
            return "Invalid subscription plan. Please update the app and try again."
        case .unknown(let underlying):
            return "An unexpected error occurred: \(underlying.localizedDescription)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .productNotFound:
            return "Subscription product not available"
        case .purchaseFailed:
            return "Transaction processing failed"
        case .purchaseCancelled:
            return "User cancelled purchase"
        case .purchasePending:
            return "Purchase awaiting processing"
        case .purchaseDeferred:
            return "Purchase requires external approval"
        case .verificationFailed:
            return "Transaction verification failed"
        case .receiptValidationFailed:
            return "Receipt validation failed"
        case .networkError:
            return "Network connectivity issue"
        case .userNotEligible:
            return "User not eligible for offer"
        case .paymentNotAllowed:
            return "Payment restrictions active"
        case .systemError:
            return "StoreKit system error"
        case .subscriptionExpired:
            return "Subscription validity expired"
        case .subscriptionNotFound:
            return "No active subscription"
        case .restoreFailed:
            return "Purchase restoration failed"
        case .refundFailed:
            return "Refund processing failed"
        case .appStoreUnavailable:
            return "App Store service unavailable"
        case .parentalControlsActive:
            return "Parental controls blocking purchases"
        case .invalidProductIdentifier:
            return "Product identifier invalid"
        case .unknown:
            return "Unhandled error condition"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .productNotFound:
            return "Check your internet connection and try again. If the issue persists, update the app."
        case .purchaseFailed:
            return "Verify your payment method and try purchasing again. Contact support if the issue continues."
        case .purchaseCancelled:
            return "You can attempt the purchase again anytime from the subscription screen."
        case .purchasePending:
            return "Please wait while your purchase is processed. You'll receive confirmation when complete."
        case .purchaseDeferred:
            return "Check with the account holder for purchase approval, then try again."
        case .verificationFailed:
            return "Restart the app and try again. Contact support if verification continues to fail."
        case .receiptValidationFailed:
            return "Use 'Restore Purchases' to validate your subscription, or contact support."
        case .networkError:
            return "Check your internet connection and try again when connected."
        case .userNotEligible:
            return "Check the subscription requirements or try a different plan."
        case .paymentNotAllowed:
            return "Check Screen Time settings or contact the device administrator."
        case .systemError:
            return "Force quit and restart the app, then try again."
        case .subscriptionExpired:
            return "Purchase a new subscription to continue using premium features."
        case .subscriptionNotFound:
            return "Purchase a subscription plan or use 'Restore Purchases' if you've subscribed before."
        case .restoreFailed:
            return "Ensure you're signed into the correct Apple ID and try restoring again."
        case .refundFailed:
            return "Request refunds directly through the App Store or Apple Support."
        case .appStoreUnavailable:
            return "Wait a few minutes and try again, or check Apple's system status."
        case .parentalControlsActive:
            return "Adjust Screen Time settings to allow in-app purchases."
        case .invalidProductIdentifier:
            return "Update to the latest version of the app and try again."
        case .unknown:
            return "Restart the app and try again. Contact support if the problem persists."
        }
    }
    
    // MARK: - StoreKit Error Mapping
    
    static func fromStoreKitError(_ error: Error) -> SubscriptionError {
        if let storeKitError = error as? StoreKitError {
            switch storeKitError {
            case .userCancelled:
                return .purchaseCancelled
            case .systemError:
                return .systemError
            case .networkError:
                return .networkError(underlying: error)
            case .notEntitled:
                return .userNotEligible
            case .notAvailableInStorefront:
                return .productNotFound
            @unknown default:
                return .unknown(underlying: error)
            }
        }
        
        // Handle Product.PurchaseError specifically
        if let purchaseError = error as? Product.PurchaseError {
            switch purchaseError {
            case .invalidQuantity:
                return .systemError
            case .productUnavailable:
                return .productNotFound
            case .purchaseNotAllowed:
                return .paymentNotAllowed
            case .ineligibleForOffer:
                return .userNotEligible
            case .invalidOfferIdentifier:
                return .userNotEligible
            case .invalidOfferPrice:
                return .invalidProductIdentifier
            case .invalidOfferSignature:
                return .verificationFailed
            @unknown default:
                return .unknown(underlying: error)
            }
        }
        
        // Handle NSError cases
        if let nsError = error as NSError? {
            switch nsError.domain {
            case NSURLErrorDomain:
                return .networkError(underlying: error)
            case "SKErrorDomain":
                switch nsError.code {
                case 0: // SKErrorUnknown
                    return .systemError
                case 1: // SKErrorClientInvalid
                    return .systemError
                case 2: // SKErrorPaymentCancelled
                    return .purchaseCancelled
                case 3: // SKErrorPaymentInvalid
                    return .purchaseFailed(underlying: error)
                case 4: // SKErrorPaymentNotAllowed
                    return .paymentNotAllowed
                case 5: // SKErrorStoreProductNotAvailable
                    return .productNotFound
                case 6: // SKErrorCloudServicePermissionDenied
                    return .userNotEligible
                case 7: // SKErrorCloudServiceNetworkConnectionFailed
                    return .networkError(underlying: error)
                case 8: // SKErrorCloudServiceRevoked
                    return .subscriptionExpired
                case 9: // SKErrorPrivacyAcknowledgementRequired
                    return .userNotEligible
                case 10: // SKErrorUnauthorizedRequestData
                    return .verificationFailed
                case 11: // SKErrorInvalidSignature
                    return .verificationFailed
                case 12: // SKErrorMissingOfferParams
                    return .invalidProductIdentifier
                case 13: // SKErrorInvalidOfferIdentifier
                    return .userNotEligible
                case 14: // SKErrorInvalidOfferPrice
                    return .invalidProductIdentifier
                case 15: // SKErrorOverlayCancelled
                    return .purchaseCancelled
                case 16: // SKErrorOverlayTimeout
                    return .systemError
                case 17: // SKErrorIneligibleForOffer
                    return .userNotEligible
                case 18: // SKErrorUnsupportedPlatform
                    return .systemError
                case 19: // SKErrorOverlayPresentedInBackgroundScene
                    return .systemError
                default:
                    return .unknown(underlying: error)
                }
            default:
                return .unknown(underlying: error)
            }
        }
        
        return .unknown(underlying: error)
    }
    
    // MARK: - Convenience Methods
    
    static func from(_ error: Error) -> SubscriptionError {
        if let subscriptionError = error as? SubscriptionError {
            return subscriptionError
        }
        return fromStoreKitError(error)
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .appStoreUnavailable, .systemError, .verificationFailed:
            return true
        case .purchaseCancelled, .paymentNotAllowed, .parentalControlsActive, .userNotEligible:
            return false
        default:
            return true
        }
    }
    
    var shouldShowToUser: Bool {
        switch self {
        case .purchasePending, .purchaseDeferred:
            return false // These are informational, not errors
        default:
            return true
        }
    }
    
    // MARK: - Equatable Conformance
    
    static func == (lhs: SubscriptionError, rhs: SubscriptionError) -> Bool {
        switch (lhs, rhs) {
        case (.productNotFound, .productNotFound),
             (.purchaseCancelled, .purchaseCancelled),
             (.purchasePending, .purchasePending),
             (.purchaseDeferred, .purchaseDeferred),
             (.verificationFailed, .verificationFailed),
             (.receiptValidationFailed, .receiptValidationFailed),
             (.userNotEligible, .userNotEligible),
             (.paymentNotAllowed, .paymentNotAllowed),
             (.systemError, .systemError),
             (.subscriptionExpired, .subscriptionExpired),
             (.subscriptionNotFound, .subscriptionNotFound),
             (.restoreFailed, .restoreFailed),
             (.refundFailed, .refundFailed),
             (.appStoreUnavailable, .appStoreUnavailable),
             (.parentalControlsActive, .parentalControlsActive),
             (.invalidProductIdentifier, .invalidProductIdentifier):
            return true
        case (.purchaseFailed(let lhsError), .purchaseFailed(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        case (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError?.localizedDescription == rhsError?.localizedDescription
        case (.unknown(let lhsError), .unknown(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Debug Description

extension SubscriptionError: CustomStringConvertible {
    var description: String {
        switch self {
        case .productNotFound:
            return "SubscriptionError.productNotFound"
        case .purchaseFailed(let error):
            return "SubscriptionError.purchaseFailed(\(error?.localizedDescription ?? "nil"))"
        case .purchaseCancelled:
            return "SubscriptionError.purchaseCancelled"
        case .purchasePending:
            return "SubscriptionError.purchasePending"
        case .purchaseDeferred:
            return "SubscriptionError.purchaseDeferred"
        case .verificationFailed:
            return "SubscriptionError.verificationFailed"
        case .receiptValidationFailed:
            return "SubscriptionError.receiptValidationFailed"
        case .networkError(let error):
            return "SubscriptionError.networkError(\(error?.localizedDescription ?? "nil"))"
        case .userNotEligible:
            return "SubscriptionError.userNotEligible"
        case .paymentNotAllowed:
            return "SubscriptionError.paymentNotAllowed"
        case .systemError:
            return "SubscriptionError.systemError"
        case .subscriptionExpired:
            return "SubscriptionError.subscriptionExpired"
        case .subscriptionNotFound:
            return "SubscriptionError.subscriptionNotFound"
        case .restoreFailed:
            return "SubscriptionError.restoreFailed"
        case .refundFailed:
            return "SubscriptionError.refundFailed"
        case .appStoreUnavailable:
            return "SubscriptionError.appStoreUnavailable"
        case .parentalControlsActive:
            return "SubscriptionError.parentalControlsActive"
        case .invalidProductIdentifier:
            return "SubscriptionError.invalidProductIdentifier"
        case .unknown(let error):
            return "SubscriptionError.unknown(\(error.localizedDescription))"
        }
    }
}