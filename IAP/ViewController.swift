//
//  ViewController.swift
//  IAP
//
//  Created by Sergey Pogrebnyak on 12/27/18.
//  Copyright © 2018 Sergey Pogrebnyak. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit

class ViewController: UIViewController, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    //product identifier
    let COINS_PRODUCT_ID = "com.testnixsolutions.SergP.PushNotifications.Coins"
    let PREMIUM_PRODUCT_ID = "com.testnixsolutions.SergP.PushNotifications.FirstPurchase"
    let SUBSCRIPTION_NON_AUTORENEW = "com.testnixsolutions.SergP.PushNotifications.subscriptions2"
    let SUBSCRIPTION_AUTORENEW = "com.testnixsolutions.SergP.PushNotifications.SubscriptionAutoreNew"

    let shared_secret_key = "3bfef31710684e4d9599817091788a4b"

    var productsRequest = SKProductsRequest()
    var iapProducts = [SKProduct]()
    var nonConsumablePurchaseMade = UserDefaults.standard.bool(forKey: "nonConsumablePurchaseMade")
    var coins = UserDefaults.standard.integer(forKey: "coins")

    @IBOutlet weak var coinsCount: UILabel!
    @IBOutlet weak var nextLevel: UIButton!
    @IBOutlet weak var labelDesc1: UILabel!
    @IBOutlet weak var labelDesc2: UILabel!
    @IBOutlet weak var expirityLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("NON CONSUMABLE PURCHASE MADE: \(nonConsumablePurchaseMade)")
        print("COINS: \(coins)")

        // Set text

        coinsCount.text = String(coins)
        if nonConsumablePurchaseMade {
            nextLevel.isEnabled = true
        }

        // Fetch IAP Products available
        fetchAvailableProducts()
    }
    //MARK: - function for fetch list and price of product from itunes
    func fetchAvailableProducts()  {
        // Put here your IAP Products ID's
        //set of product for buy and take price on product (localization)
        let productIdentifiers = NSSet(objects:
            COINS_PRODUCT_ID,
            PREMIUM_PRODUCT_ID,
            SUBSCRIPTION_NON_AUTORENEW,
            SUBSCRIPTION_AUTORENEW
        )

        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers as! Set<String>)
        productsRequest.delegate = self
        productsRequest.start()
    }
    //MARK: - button action
    //function for buy product
    @IBAction func byCoinsAction(_ sender: Any) {
        purchaseMyProduct(product: iapProducts[0])
    }

    @IBAction func byLevel(_ sender: Any) {
        purchaseMyProduct(product: iapProducts[1])
    }
    //MARK: - function for check make purchase and buy product
    func canMakePurchases() -> Bool {  return SKPaymentQueue.canMakePayments()  }
    //function for buy product by product id
    func purchaseMyProduct(product: SKProduct) {
        if self.canMakePurchases() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(self)
            SKPaymentQueue.default().add(payment)

            print("PRODUCT TO PURCHASE: \(product.productIdentifier)")
            // IAP Purchases dsabled on the Device
        } else {
            print("Purchases are disabled in your device!")
        }
    }
    //MARK: - Restore purchase
    //restore purchase
    @IBAction func restorePurchaseButt(_ sender: Any) {
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        nonConsumablePurchaseMade = true
        UserDefaults.standard.set(nonConsumablePurchaseMade, forKey: "nonConsumablePurchaseMade")
        nextLevel.isEnabled = true
    }
    //MARK: - SwiftyStoreKit function for check expirity date subscription
    //check expirity date of subscription by pod SwiftyStoreKit
    func checkSubscriptionExpirityDate() {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: shared_secret_key)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = self.COINS_PRODUCT_ID//product identifier for check
                // Verify the purchase of a Subscription
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable ,//.nonRenewing(validDuration: 3600 * 24 * 30), // or .nonRenewing (see below)//type of subscription
                    productId: productId,
                    inReceipt: receipt)
                //check purchase status
                switch purchaseResult {
                case .purchased(let expiryDate, let items):
                    self.expirityLabel.text = "NO expirity"
                    print("\(productId) is valid until \(expiryDate)\n\(items)\n")
                case .expired(let expiryDate, let items):
                    self.expirityLabel.text = "expirity"
                    print("\(productId) is expired since \(expiryDate)\n\(items)\n")
                case .notPurchased:
                    print("The user has never purchased \(productId)")
                }

            case .error(let error):
                print("Receipt verification failed: \(error)")
            }
        }
    }
    //MARK: - StoreKit delegate function
    //function of delegat for take list of product and localization prices
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count > 0 {
            iapProducts = response.products//take set of product after sending set of identifier
            // 1st IAP Product (Consumable) ------------------------------------
            let firstProduct = response.products[0] as SKProduct

            // Get its price from iTunes Connect
            let numberFormatter = NumberFormatter()
            numberFormatter.formatterBehavior = .behavior10_4
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = firstProduct.priceLocale
            let price1Str = numberFormatter.string(from: firstProduct.price)

            // Show its description
            labelDesc1.text = firstProduct.localizedDescription + " price \(price1Str!)"
            // ------------------------------------------------

            // 2nd IAP Product (Non-Consumable) ------------------------------
            let secondProd = response.products[1] as SKProduct

            // Get its price from iTunes Connect
            numberFormatter.locale = secondProd.priceLocale
            let price2Str = numberFormatter.string(from: secondProd.price)

            // Show its description
            labelDesc2.text = secondProd.localizedDescription + " price \(price2Str!)"
            // ------------------------------------
        }
    }
    //delegat result of bought
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction:AnyObject in transactions {
            if let trans = transaction as? SKPaymentTransaction {
                switch trans.transactionState {

                case .purchased:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)

                    // The Consumable product (10 coins) has been purchased -> gain 10 extra coins!
                    if trans.payment.productIdentifier == COINS_PRODUCT_ID {

                        // Add 10 coins and save their total amount
                        coins += 10
                        UserDefaults.standard.set(coins, forKey: "coins")
                        coinsCount.text = "COINS: \(coins)"



                        // The Non-Consumable product (Premium) has been purchased!
                    } else if trans.payment.productIdentifier == PREMIUM_PRODUCT_ID {

                        // Save your purchase locally (needed only for Non-Consumable IAP)
                        nonConsumablePurchaseMade = true
                        UserDefaults.standard.set(nonConsumablePurchaseMade, forKey: "nonConsumablePurchaseMade")

                        print("Premium version PURCHASED!")
                        nextLevel.isEnabled = true
                    }

                    break

                case .failed:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break
                case .restored:
                    SKPaymentQueue.default().finishTransaction(transaction as! SKPaymentTransaction)
                    break

                default: break
                }}}
    }
}

