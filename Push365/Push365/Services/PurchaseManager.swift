//
//  PurchaseManager.swift
//  Push365
//
//  Created by Lee Chandler on 11/02/2026.
//

import Foundation
import Combine
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    static let supporterProductID = "com.push365.supporter"
    private let supporterKey = "isSupporter"
    
    @Published var product: Product?
    @Published var isSupporter: Bool
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    
    init() {
        self.isSupporter = UserDefaults.standard.bool(forKey: supporterKey)
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
    }
    
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.supporterProductID])
            product = products.first
        } catch {
            errorMessage = "Unable to load purchase options."
        }
    }
    
    func purchase() async {
        guard let product = product else {
            errorMessage = "Purchase is currently unavailable."
            return
        }
        
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified = verification {
                    await refreshEntitlements()
                } else {
                    errorMessage = "Purchase could not be verified."
                }
            case .userCancelled:
                infoMessage = "Purchase cancelled."
            case .pending:
                infoMessage = "Purchase pending."
            @unknown default:
                errorMessage = "Purchase failed."
            }
        } catch {
            errorMessage = "Purchase failed."
        }
        
        isLoading = false
    }
    
    func restore() async {
        isLoading = true
        errorMessage = nil
        infoMessage = nil
        
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "Restore failed."
        }
        
        isLoading = false
    }
    
    func refreshEntitlements() async {
        var supporter = false
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.supporterProductID {
                supporter = true
            }
        }
        
        isSupporter = supporter
        UserDefaults.standard.set(supporter, forKey: supporterKey)
    }
}
