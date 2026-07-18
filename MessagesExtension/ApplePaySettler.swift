import Foundation
import PassKit
import SplitCore
import SwiftUI
import UIKit

enum ApplePaySettleResult {
    case success
    case cancelled
    case unavailable(String)
    case failed(String)
}

/// Presents Apple Pay to settle a balance. Requires a real merchant ID + payment
/// processor in production; without that, callers should fall back to manual mark-paid.
@MainActor
final class ApplePaySettler: NSObject {
    private var completion: ((ApplePaySettleResult) -> Void)?
    private var controller: PKPaymentAuthorizationController?

    static var canMakePayments: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    func settle(
        amountCents: Int,
        currencyCode: String,
        label: String,
        completion: @escaping (ApplePaySettleResult) -> Void
    ) {
        self.completion = completion

        guard ApplePayConfig.isConfigured else {
            completion(.unavailable("Add your Apple Pay merchant ID in ApplePayConfig to enable live payments."))
            return
        }

        guard Self.canMakePayments else {
            completion(.unavailable("Apple Pay isn’t available on this device."))
            return
        }

        let request = PKPaymentRequest()
        request.merchantIdentifier = ApplePayConfig.merchantIdentifier
        request.countryCode = ApplePayConfig.countryCode
        request.currencyCode = currencyCode
        request.merchantCapabilities = [.threeDSecure, .credit, .debit]
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(
                label: label,
                amount: NSDecimalNumber(value: Double(amountCents) / 100.0),
                type: .final
            )
        ]

        let controller = PKPaymentAuthorizationController(paymentRequest: request)
        controller.delegate = self
        self.controller = controller

        controller.present { [weak self] presented in
            if !presented {
                self?.finish(.unavailable("Couldn’t present Apple Pay."))
            }
        }
    }

    private func finish(_ result: ApplePaySettleResult) {
        completion?(result)
        completion = nil
        controller = nil
    }
}

extension ApplePaySettler: PKPaymentAuthorizationControllerDelegate {
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss { [weak self] in
            if self?.completion != nil {
                self?.finish(.cancelled)
            }
        }
    }

    func paymentAuthorizationController(
        _ controller: PKPaymentAuthorizationController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        // Production: send `payment.token` to your payment processor, then settle.
        // Demo path: accept the authorization so the Messages settle flow can continue.
        _ = payment
        completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
        finish(.success)
    }
}

/// SwiftUI wrapper for the system Apple Pay button.
struct ApplePayButton: UIViewRepresentable {
    var type: PKPaymentButtonType = .plain
    var style: PKPaymentButtonStyle = .black
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {
        context.coordinator.action = action
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(action: action)
    }

    final class Coordinator: NSObject {
        var action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func tap() { action() }
    }
}
