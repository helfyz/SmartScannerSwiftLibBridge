//
//  SmartScannerBridge.swift
//  SmartScanner
//
//  Created by helfy on 2022/1/19.
//

import Foundation
import SwiftyTesseract
import SwiftyStoreKit
import StoreKit
import AVFoundation
//import SwiftyFitsize
/**
 Scan & Edit
 */
// oc不能直接使用结构体，这里用class包一层
open class SSQuadrilateralModel: NSObject  {
    var quad:Quadrilateral
    init(quad:Quadrilateral) {
        self.quad = quad;
    }
    
    @objc open func scale(fromSize: CGSize,toSize: CGSize, withRotationAngle rotationAngle: CGFloat = 0.0) -> SSQuadrilateralModel {
        SSQuadrilateralModel(quad: quad.scale(fromSize, toSize,withRotationAngle: rotationAngle))
    }
}

@objc public protocol SSCameraScannerBridgeDelegate: NSObjectProtocol {
    func captureImageFailWithError(error: Error)
    func captureImageSuccess(image: UIImage, withQuad quadModel: SSQuadrilateralModel?)
    func captureImageWaiting(wait : Bool)
    func captureMetadataCode(values: [String])
    
}
// 相机回调转化处理 。
open class SSCameraScannerDelegateBridge: NSObject {
    @objc open weak var delegate:SSCameraScannerBridgeDelegate?
    
    @objc open func bind(scanner:CameraScannerViewController) {
        scanner.delegate = self;
    }
}
extension SSCameraScannerDelegateBridge:CameraScannerViewOutputDelegate {
    open func captureImageFailWithError(error: Error) {
        delegate?.captureImageFailWithError(error: error)
    }
    open func captureImageSuccess(image: UIImage, withQuad quad: Quadrilateral?) {
        if let quad = quad {
            delegate?.captureImageSuccess(image: image, withQuad: SSQuadrilateralModel(quad: quad))
        } else {
            delegate?.captureImageSuccess(image: image, withQuad: nil)
        }
    }
    open func captureImageWaiting(wait: Bool) {
        delegate?.captureImageWaiting(wait: wait)
    }
    open func captureMetadataCode(values: [String]) {
        delegate?.captureMetadataCode(values: values)
    }
  
}

extension CameraScannerViewController {

    @objc public func changeCaptureBatchMode() {
        changeCaptureMode(.batch)
    }
    @objc public func changeCaptureSingleMode() {
        changeCaptureMode(.single)
    }
    @objc public func changeCaptureQrCodeMode() {
        changeCaptureMode(.qrCode)
    }
    @objc public func changeCaptureBarCodeMode() {
        changeCaptureMode(.barCode)
    }
    
    @objc public func configphotoPreset(preset:AVCaptureSession.Preset) {
        captureSessionManager?.photoPreset = preset
    }
    
}
extension QuadrilateralView {
    @objc public func drawQuad(quadModel:SSQuadrilateralModel, scaleTransform:CGAffineTransform) {
        let transforms = [scaleTransform]
        let transformedQuad = quadModel.quad.applyTransforms(transforms)
        drawQuadrilateral(quad: transformedQuad, animated: false)
    }
    
    @objc open var quadModel:SSQuadrilateralModel? {
        if let quad = quad {
            return SSQuadrilateralModel(quad: quad);
        }
        return nil;
    }
    
    
}


public class WeScanBridge: NSObject {
    @objc
    public static func cropImage(originImage:UIImage,quadModel:SSQuadrilateralModel?,rotationAngle:Double = 0.0, complete: @escaping(UIImage)->()) {
        guard let quad = quadModel?.quad, let ciImage = CIImage(image: originImage) else {
            complete(originImage)
            return
        }
            let cgOrientation = CGImagePropertyOrientation(originImage.imageOrientation)
            let orientedImage = ciImage.oriented(forExifOrientation: Int32(cgOrientation.rawValue))
          
            // Cropped Image
            var cartesianScaledQuad = quad.toCartesian(withHeight: originImage.size.height)
            cartesianScaledQuad.reorganize()

            let filteredImage = orientedImage.applyingFilter("CIPerspectiveCorrection", parameters: [
                "inputTopLeft": CIVector(cgPoint: cartesianScaledQuad.bottomLeft),
                "inputTopRight": CIVector(cgPoint: cartesianScaledQuad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: cartesianScaledQuad.topLeft),
                "inputBottomRight": CIVector(cgPoint: cartesianScaledQuad.topRight)
            ])
            var croppedImage = UIImage.from(ciImage: filteredImage)
            croppedImage = croppedImage.rotated(by: Measurement(value: rotationAngle, unit: .radians)) ?? originImage
            DispatchQueue.main.async {
                complete(croppedImage)
             }
    }
    @objc
    public static func detect(image: UIImage, completion: @escaping (SSQuadrilateralModel?) -> Void) {
        guard let ciImage = CIImage(image: image) else {
            completion(nil);
            return
        }
        let orientation = CGImagePropertyOrientation(image.imageOrientation)
        let orientedImage = ciImage.oriented(forExifOrientation: Int32(orientation.rawValue))
        
        if #available(iOS 11.0, *) {
            // Use the VisionRectangleDetector on iOS 11 to attempt to find a rectangle from the initial image.
            VisionRectangleDetector.rectangle(forImage: ciImage, orientation: orientation) { (quad) in
                let detectedQuad = quad?.toCartesian(withHeight: orientedImage.extent.height)
                if let detectedQuad = detectedQuad {
                    completion(SSQuadrilateralModel(quad: detectedQuad))
                } else {
                    completion(nil);
                }
                
            }
        } else {
            // Use the CIRectangleDetector on iOS 10 to attempt to find a rectangle from the initial image.
            let detectedQuad = CIRectangleDetector.rectangle(forImage: ciImage)?.toCartesian(withHeight: orientedImage.extent.height)
            if let detectedQuad = detectedQuad {
                completion(SSQuadrilateralModel(quad: detectedQuad))
            } else {
                completion(nil);
            }
        }
    }
    
    @objc
    public static func rotated(image:UIImage, rotationAngle: Measurement<UnitAngle>) -> UIImage? {
        image.rotated(by: rotationAngle)
    }
    
    @objc
    public static func scaleTransform(forSize fromSize: CGSize, aspectFillInSize toSize: CGSize) -> CGAffineTransform {
        CGAffineTransform.scaleTransform(forSize: fromSize, aspectFillInSize: toSize)
    }
    
    @objc
    public static func defaultQuad(forImage image: UIImage) -> SSQuadrilateralModel {
        let topLeft = CGPoint(x: image.size.width / 3.0, y: image.size.height / 3.0)
        let topRight = CGPoint(x: 2.0 * image.size.width / 3.0, y: image.size.height / 3.0)
        let bottomRight = CGPoint(x: 2.0 * image.size.width / 3.0, y: 2.0 * image.size.height / 3.0)
        let bottomLeft = CGPoint(x: image.size.width / 3.0, y: 2.0 * image.size.height / 3.0)
        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        return SSQuadrilateralModel(quad: quad)
    }

    @objc
    public static func defaultQuad(allOfImage image: UIImage, withOffset offset: CGFloat = 0) -> SSQuadrilateralModel {
        let topLeft = CGPoint(x: offset, y: offset)
        let topRight = CGPoint(x: image.size.width - offset, y: offset)
        let bottomRight = CGPoint(x: image.size.width - offset, y: image.size.height - offset)
        let bottomLeft = CGPoint(x: offset, y: image.size.height - offset)
        let quad = Quadrilateral(topLeft: topLeft, topRight: topRight, bottomRight: bottomRight, bottomLeft: bottomLeft)
        return SSQuadrilateralModel(quad: quad)
    }
}
/**
 ORC
 */

class TesseractDataSource: LanguageModelDataSource {
    var pathToTrainedData: String = ""
    public init(pathToTrainedData:String) {
        self.pathToTrainedData = pathToTrainedData
    }
}

open class SwiftyTesseractBridge:NSObject {
    @objc open class func performOCR(languageCode:String? = "eng", languagesFloderPath:String?, image:UIImage, complete: @escaping (String?, Error?) -> ()) {
        DispatchQueue.global().async {
            let language = RecognitionLanguage.custom(languageCode ?? "eng")
            let tesseract = SwiftyTesseract(language: language, dataSource:TesseractDataSource(pathToTrainedData: languagesFloderPath ?? ""), engineMode: EngineMode.lstmOnly)

            let result = tesseract.performOCR(on: image)
            DispatchQueue.main.async {
                switch result {
                    case .success(let value) :
                    complete(value, nil)
                    break
                    case .failure(let error) :
                    complete(nil, error)
                    break
                }
            }
        }
    }
}

/**
 SwiftyStoreKit
   之前的SSSubscribeAPI 本身就是桥接部分，这里简单改一下，删除一些无用代码
 */
public class SSSubscribeBridge: NSObject {
   
    @objc public static let shared : SSSubscribeBridge = SSSubscribeBridge()

//     @objc class var shared : SSSubscribeBridge {
//          struct Static {
//          }
//          return Static.instance
//      }
    @objc open class func sharedInstance() -> SSSubscribeBridge {
        SSSubscribeBridge.shared
    }
    private var localPrice:String?
    private var transactionArray:[PaymentTransaction] = []
        
        //   添加交易观察者，异步执行completeTransactions，回调block时回到主线程
        @objc open func registerTransactionObserverAPI(completion: @escaping (String,String,Bool) -> Void) {
            self.transactionArray.removeAll()
            SwiftyStoreKit.completeTransactions(atomically: false) { purchases in
                for purchase in purchases {
                    let tra = purchase.transaction as! SKPaymentTransaction
                    switch purchase.transaction.transactionState {
                    case .purchased, .restored:
                        let downloads = purchase.transaction.downloads
                        if !downloads.isEmpty {
                            SwiftyStoreKit.start(downloads)
                        } else if purchase.needsFinishTransaction {
                            self.transactionArray.append(purchase.transaction);
                        }
                        print("🔥👌：\(purchase.transaction.transactionIdentifier ?? "hhhhhhhhhhh"): \(purchase.productId)")
                        print("😊😊😊：\(purchase.needsFinishTransaction)")
                        self.localPrice = purchase.productId + "&" + (tra.payment.applicationUsername ?? "");
                        self.fetchReceiptAPI(completion)
                    case .failed:
                    break // do nothing
                    case .purchasing:
                        break;//// do nothing
                    case .deferred:
                        break;//// do nothing
                    @unknown default:
                        break // do nothing
                    }
                }
            }
            
            SwiftyStoreKit.updatedDownloadsHandler = { downloads in
                // contentURL is not nil if downloadState == .finished
                let contentURLs = downloads.compactMap { $0.contentURL }
                if contentURLs.count == downloads.count {
                    print("Saving: \(contentURLs)")
                    SwiftyStoreKit.finishTransaction(downloads[0].transaction)//1000000549677840
                }
            }
        }
        
        
        @objc open func shoudAddPurchaseAPI(completion: @escaping (String,String,Bool) -> Void) {
            SwiftyStoreKit.shouldAddStorePaymentHandler = { payment, product in
                let indentify = payment.productIdentifier
                completion(indentify,"",true)
                return false//返回True时，点击App Store上的内购推广按钮，系统会发起购买请求
            }
        }
        
    //    完成交易 1000000563058486
       @objc open func finishTransaction() {
        for transaction in self.transactionArray {
            SwiftyStoreKit.finishTransaction(transaction)
         }
        print("🍑🍑🍑🍑🍑🍑交易完成：\(String(describing: self.transactionArray))")
       }
        
    //    获取内购项目列表信息（异步获得当前的应用程序的所有内购项目，回调block时回到主线程）
        @objc open func retrieveProductsInfoAPI(productIds:Set<String>,completiton:@escaping (Dictionary<String, Any>,Bool) -> Void) {
            SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
                var priceDic = [String:String]()
                if result.retrievedProducts.first != nil {
                    
                    for product in result.retrievedProducts{
                       let priceString = product.localizedPrice!//价钱
                       let key = product.productIdentifier
                        priceDic[key] = priceString;
                    }
                    
                    completiton(priceDic,true)
                    
                }else if result.invalidProductIDs.first != nil {
    //                处理产品ID无效的情况
                    completiton(["key":"Invalid product identifier"],false)
                }else {
    //                处理由于网络请求失败等情况，所造成的内购查询失败的问题
                    completiton(["key":"Error: \(String(describing: result.error))"],false)
                }
            }
        }
        
    //    购买指定唯一标识符的内购项目
        @objc open func purchaseProductAPI(productid:String,completion: @escaping (String,String,Bool) -> Void) {
            SwiftyStoreKit.purchaseProduct(productid, atomically: false, applicationUsername: productid) { result in
                switch result{
                case .success(let purchase):
                    let downloads = purchase.transaction.downloads
                    if !downloads.isEmpty {
                        SwiftyStoreKit.start(downloads)
                    }
                    // Deliver content from server, then:
                    if purchase.needsFinishTransaction {//
                        self.transactionArray.removeAll()//1000000542996104
                        self.transactionArray.append(purchase.transaction)
                    }
                    
                   let currencyCode = purchase.product.priceLocale.currencyCode!
                   self.localPrice = purchase.product.price.stringValue + currencyCode;
                    
                    self.fetchReceiptAPI(completion)
                    
                    print("🍎🍎🍎购买🍎🍎🍎：\(purchase.transaction.transactionIdentifier ?? "hhhhhhhhhhh"): \(String(describing: self.localPrice))")
                    
                case .error(let error):
                    print("Purchase Failed: \(error)")
                    switch error.code {
                    case .unknown:
    //                    print("Unknown error. Please contact support")
                        completion("Unknown error. Please contact support","",false)//
                    case .clientInvalid:
    //                    print("Not allowed to make the payment")
                        completion("Not allowed to make the payment", "",false)
                    case .paymentCancelled:
                        completion("Cancel","",false)
                        break
                    case .paymentInvalid:
    //                    print("The purchase identifier was invalid")
                        completion("The purchase identifier was invalid","",false)
                    case .paymentNotAllowed:
    //                    print("The device is not allowed to make the payment")
                        completion("The device is not allowed to make the payment","",false)
                    case .storeProductNotAvailable:
    //                    print("The product is not available in the current storefront")
                        completion("The product is not available in the current storefront","",false)
                    case .cloudServicePermissionDenied:
    //                    print("Access to cloud service information is not allowed")
                        completion("Access to cloud service information is not allowed","",false)
                    case .cloudServiceNetworkConnectionFailed:
    //                    print("Could not connect to the network")
                        completion("Could not connect to the network","",false)
                    case .cloudServiceRevoked:
    //                    print("User has revoked permission to use this cloud service")
                        completion("User has revoked permission to use this cloud service","",false)
                    default:
    //                    print("Purchase Failed reason:\(error.localizedDescription)")
                        completion("\(error.localizedDescription)","",false)
                        break
                    }
                }
            }
        }
        
    //    恢复内购。如果用户之前购买过内购的项目，当用户重新安装应用程序时，可以通过此方法，恢复用户之前购买过的项目
        @objc open func restorePurchaseAPI(completion: @escaping (String,String,Bool) -> Void) {
    //        获得所有购买过的项目
            SwiftyStoreKit.restorePurchases(atomically: true) { results in
                if results.restoreFailedPurchases.count > 0 {
                    print("Restore Failed: \(String(describing: results.restoreFailedPurchases.first))")
                    if (results.restoreFailedPurchases.first?.0.code)!.rawValue == 0{
                        completion("Cancel","",false)//点击系统弹框的取消
                        return;
                    }
                    completion("Restore Failed","",false)
                }else if results.restoredPurchases.count > 0 {
                    for purchase in results.restoredPurchases {
                        let downloads = purchase.transaction.downloads
                        if !downloads.isEmpty {
                            SwiftyStoreKit.start(downloads)
                        } else if purchase.needsFinishTransaction {
    //                         Deliver content from server, then:
                            SwiftyStoreKit.finishTransaction(purchase.transaction)
    //                        self.lastTransaction = purchase.transaction;
                        }
                    }
                    self.fetchReceiptAPI(completion)
    //                print("Restore Success: \(results.restoredPurchases)")
                }else {
    //                print("Nothing to Restore")
                    completion("Nothing to Restore","",false)
                }
            }
        }
        
    //    获取收据
        @objc open func fetchReceiptAPI(_ completion: @escaping (String,String,Bool) -> Void) {
            SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
                switch result {
                case .success(let receiptData):
                    let encryptedReceipt = receiptData.base64EncodedString(options: [])
    //                print("Fetch receipt success:\n\(encryptedReceipt)")
                    completion(encryptedReceipt,self.localPrice ?? "",true)
    //                completion(encryptedReceipt,self.localPrice ?? "",(self.localPrice != nil) ? true : false)
                case .error(let error):
                    print("Fetch receipt failed: \(error)")
                    completion("Fetch receipt failed","",false)
                }
            }
        }
        
        @objc open func existReceiptInfo(_ receiptBlock: @escaping (Bool) -> Void){
            typealias completionBlock = (String,String,Bool) -> Void
            let completion:completionBlock = { receipt,price,success in
    //            print("Fetch receipt Success: \(receipt)")
                receiptBlock(success)
            }
            self.fetchReceiptAPI(completion)
        }
}

