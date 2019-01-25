//
//  ViewController.swift
//  LocalAuthentication_Test
//
//  Created by robinson on 2019/1/25.
//  Copyright © 2019 robinson. All rights reserved.
//

/*
 * 使用LocalAuthentication framework
 * TouchID, faceID 登入
 * https://developer.apple.com/documentation/localauthentication
 * Demo: https://developer.apple.com/documentation/localauthentication/logging_a_user_into_your_app_with_face_id_or_touch_id
 */

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var authResultLabel: UILabel!
    
    var context = LAContext()
    
    var alertDesc:String {
        switch self.context.biometryType {
        case .faceID:
            return "使用FaceID驗證"
        case .touchID:
            return "使用TouchID驗證"
        case .none:
            return ""
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //alert right action
        self.context.localizedFallbackTitle = "手動輸入密碼"
        
        //alert fail action
        self.context.localizedCancelTitle = "取消使用TouchID/FaceID"
        
        self.setUpAuthentication()
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.context.invalidate()
    }

    func setUpAuthentication() {
        var error: NSError?
        /*
         * deviceOwnerAuthenticationWithBiometrics, iOS8可用
         * deviceOwnerAuthentication, iOS9可用
         */
        if self.context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            if let error = error {
                //fatalError("[TouchID/FaceID] error:\(error.description)")
                print("[can_evaluate] error:\(error.localizedDescription)")
                self.showAlertMsg(message: error.localizedDescription)
                return
            }
            
            //如果支援TouchID/FaceID, 2秒後開始進行驗證
            if self.deviceSupportTouchIdOrFaceId(){
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    
                    //系統會自帶出Alert,提示使用者
                    //驗證錯誤,會讓使用者選擇要取消還是輸入密碼,輸入密碼會導出系統密碼解鎖畫面,輸入正確回到appㄧ樣會顯示成功
                    //系統密碼解鎖,5次錯誤會停用device TouchID/faceID 認證功能, 停用時間系統決定
                    self.context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: self.alertDesc) { [weak self](success, error) in
                        if let error = error {
                            //點取消也會進入
                            print("evaluate_error:\(error.localizedDescription)")
                            //fatalError("evaluate_error")
                            self?.showAlertMsg(message: error.localizedDescription)
                            return
                        }
                        
                        //
                        
                        DispatchQueue.main.sync {
                            self?.showAuthenticationResult(result: success)
                        }
                        
                    }
                }
                
            }else{
                self.showAlertMsg(message: "device no set password")
            }
            
        }else{
            //fatalError("device no TouchID/FaceID")
            //沒有密碼或是不支援TouchID/FaceID
            print("device no TouchID/FaceID password")
            self.stateLabel.text = "device no TouchID/FaceID password"
            self.showAlertMsg(message: "device no TouchID/FaceID password")
        }
    }

    // MARK - 檢查裝置是否支援TouchID/FaceID
    func deviceSupportTouchIdOrFaceId() -> Bool {
        print("type:\(self.context.biometryType)")
        switch self.context.biometryType {
        case .faceID:
            self.stateLabel.text = "驗證方式: FaceID"
            print("\(self.stateLabel.text!)")
            return true
        case .touchID:
            self.stateLabel.text = "驗證方式: TouchID"
            print("\(self.stateLabel.text!)")
            return true
        case .none:
            self.stateLabel.text = "驗證方式: 手動輸入"
            print("\(self.stateLabel.text!)")
            return false
        }
    }
    
    // MARK : 顯示驗證結果
    func showAuthenticationResult(result success:Bool) {
        self.authResultLabel.text = (success) ? "success" : "fail"
        
        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                let homeVC = self.storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
                
                UIApplication.shared.keyWindow?.rootViewController = homeVC
            }
        }
        
    }
    
    // MARK : 顯示alert
    func showAlertMsg(message msg:String) {
        let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true) {
            self.setUpAuthentication()
        }
    }
}
