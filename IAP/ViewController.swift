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
    fileprivate let COINS_PRODUCT_ID = "com.testnixsolutions.SergP.PushNotifications.Coins"
    fileprivate let PREMIUM_PRODUCT_ID = "com.testnixsolutions.SergP.PushNotifications.FirstPurchase"
    fileprivate let SUBSCRIPTION_NON_AUTORENEW = "com.testnixsolutions.SergP.PushNotifications.subscriptions2"
    fileprivate let SUBSCRIPTION_AUTORENEW = "com.testnixsolutions.SergP.PushNotifications.SubscriptionAutoreNew"

    fileprivate let shared_secret_key = "3bfef31710684e4d9599817091788a4b"

    fileprivate var productsRequest = SKProductsRequest()
    fileprivate var iapProducts = [SKProduct]()
    fileprivate var nonConsumablePurchaseMade = UserDefaults.standard.bool(forKey: "nonConsumablePurchaseMade")
    fileprivate var coins = UserDefaults.standard.integer(forKey: "coins")

    @IBOutlet fileprivate weak var coinsCount: UILabel!
    @IBOutlet fileprivate weak var nextLevel: UIButton!
    @IBOutlet fileprivate weak var labelPurchaseNonConsumable: UILabel!
    @IBOutlet fileprivate weak var labelSubscriptionAutorenew: UILabel!
    @IBOutlet fileprivate weak var labelSubscriptionNonAutorenew: UILabel!

    @IBOutlet fileprivate weak var labelPrice1: UILabel!
    @IBOutlet fileprivate weak var labelPrice2: UILabel!
    @IBOutlet fileprivate weak var labelPrice3: UILabel!
    @IBOutlet fileprivate weak var labelPrice4: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()

        print("NON CONSUMABLE PURCHASE MADE: \(nonConsumablePurchaseMade)")
        print("COINS: \(coins)")

        // Set text

        coinsCount.text = String(coins)
        if nonConsumablePurchaseMade {
            nextLevel.isEnabled = true
            labelPurchaseNonConsumable.text = "yes"
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

    @IBAction func subscriptionNONAutorenew(_ sender: Any) {
        purchaseMyProduct(product: iapProducts[3])
    }

    @IBAction func subscriptionAutorenew(_ sender: Any) {
        purchaseMyProduct(product: iapProducts[2])
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
        print(queue.transactions)
        let queueOfTransactions = queue.transactions
        for productIdentifier in queueOfTransactions {
            if productIdentifier.payment.productIdentifier == PREMIUM_PRODUCT_ID {
                nonConsumablePurchaseMade = true
                UserDefaults.standard.set(nonConsumablePurchaseMade, forKey: "nonConsumablePurchaseMade")
                nextLevel.isEnabled = true
                labelPurchaseNonConsumable.text = "yes"
            } else if productIdentifier.payment.productIdentifier == SUBSCRIPTION_AUTORENEW {
                checkSubscriptionExpirityDate()
            }
        }

    }
    //MARK: - SwiftyStoreKit function for check expirity date subscription
    //check expirity date of subscription by pod SwiftyStoreKit
    func checkSubscriptionExpirityDate() {
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: shared_secret_key)
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { result in
            switch result {
            case .success(let receipt):
                let productId = self.SUBSCRIPTION_AUTORENEW //product identifier for check
                // Verify the purchase of a Subscription
                let purchaseResult = SwiftyStoreKit.verifySubscription(
                    ofType: .autoRenewable ,//.nonRenewing(validDuration: 3600 * 24 * 30), // or .nonRenewing (see below)//type of subscription
                    productId: productId,
                    inReceipt: receipt)
                //check purchase status
                switch purchaseResult {
                case .purchased(let expiryDate, let items):
                    //self.expirityLabel.text = "NO expirity"
                    print("\(productId) is valid until \(expiryDate)\n\(items)\n")
                    self.labelSubscriptionAutorenew.text = "yes"
                case .expired(let expiryDate, let items):
                    //self.expirityLabel.text = "expirity"
                    print("\(productId) is expired since \(expiryDate)")
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
            labelPrice1.text = firstProduct.localizedDescription + " price \(price1Str!)"
            // ------------------------------------------------

            // 2nd IAP Product ------------------------------
            let secondProd = response.products[1] as SKProduct

            // Get its price from iTunes Connect
            numberFormatter.locale = secondProd.priceLocale
            let price2Str = numberFormatter.string(from: secondProd.price)

            // Show its description
            labelPrice2.text = secondProd.localizedDescription + " price \(price2Str!)"
            // ------------------------------------
            // 3nd IAP Product ------------------------------
            let thirdProd = response.products[2] as SKProduct

            // Get its price from iTunes Connect
            numberFormatter.locale = thirdProd.priceLocale
            let price3Str = numberFormatter.string(from: thirdProd.price)

            // Show its description
            labelPrice4.text = secondProd.localizedDescription + " price \(price3Str!)"
            // ------------------------------------
            // 4nd IAP Product ------------------------------
            let fourthProd = response.products[3] as SKProduct

            // Get its price from iTunes Connect
            numberFormatter.locale = fourthProd.priceLocale
            let price4Str = numberFormatter.string(from: fourthProd.price)

            // Show its description
            labelPrice3.text = secondProd.localizedDescription + " price \(price4Str!)"
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
                        labelPurchaseNonConsumable.text = "yes"
                    } else if trans.payment.productIdentifier == SUBSCRIPTION_NON_AUTORENEW {
                        labelSubscriptionNonAutorenew.text = "yes"
                    } else if trans.payment.productIdentifier == SUBSCRIPTION_AUTORENEW {
                        labelSubscriptionAutorenew.text = "yes"
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

