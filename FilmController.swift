//
//  FilmController.swift
//  EasyFilm
//
//  Created by Oliver Hill on 1/13/16.
//  Copyright © 2016 Oliver Hill. All rights reserved.
//

import UIKit
import MobileCoreServices

class FilmController: UIViewController,
                      UIImagePickerControllerDelegate,
                      UINavigationControllerDelegate {
    
    
    //MARK: Global variables
    let cameraController: UIImagePickerController! = UIImagePickerController()
    var isFirstLaunch = false
    
    override func viewDidLoad(){
        let isNotFirstLaunch = NSUserDefaults.standardUserDefaults().boolForKey("isFirstLaunch")
        if !isNotFirstLaunch {
            isFirstLaunch = true
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "isFirstLaunch")
        }
    }
    override func viewDidAppear(animated: Bool) {
        if !startCameraFromViewController(self, withDelegate: self){
            createAlert("Camera not found",
                message: "A connection to the camera could not be made",
                button: "OK")
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: "rotated",
            name: UIDeviceOrientationDidChangeNotification,
            object: nil)
    }
    
    
    func startCameraFromViewController(viewController: UIViewController,
        withDelegate delegate: protocol<UIImagePickerControllerDelegate,
        UINavigationControllerDelegate>) -> Bool {

        if UIImagePickerController.isSourceTypeAvailable(.Camera) == false {
            return false
        }
        
        //camera configuration
        cameraController.sourceType = .Camera
        cameraController.mediaTypes = [kUTTypeMovie as String]
        cameraController.showsCameraControls = false
        cameraController.allowsEditing = false
        cameraController.delegate = delegate
        cameraController.videoQuality = UIImagePickerControllerQualityType.TypeHigh

        //custom view configuration
        let overlayController = OverlayViewController(nibName: "OverlayViewController", bundle: nil)
        let overlayView: OverlayView = overlayController.view as! OverlayView
        overlayView.frame = cameraController.view.frame
        
        //add the overlay after the camera is displayed
        presentViewController(cameraController, animated: false, completion: {
            self.cameraController.cameraOverlayView = overlayView
            overlayView.setup(isFirstLaunch: true)
        })
            
        return true
    }
    
    func imagePickerController(picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [String : AnyObject]) {
            
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString

        if mediaType == kUTTypeMovie {
            let path = (info[UIImagePickerControllerMediaURL] as! NSURL).path
            if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(path!) {
                UISaveVideoAtPathToSavedPhotosAlbum(path!,
                    self, "video:didFinishSavingWithError:contextInfo:",nil)
            }
        }
    }
    
    
    func video(videoPath: NSString, didFinishSavingWithError error: NSError?, contextInfo info: AnyObject) {
        if let overlay: OverlayView = cameraController.cameraOverlayView as? OverlayView{
            overlay.configureAndAnimateSaveView()
        }
    }
    
    func createAlert(title: String, message: String, button: String){
        let alert = UIAlertController(title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: button,
            style: UIAlertActionStyle.Default,
            handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    //MARK: Rotation Handling
    func rotated(){
        if UIDevice.currentDevice().orientation == .LandscapeLeft{
                startCapture(positiveRotation: true)
        }
        else if UIDevice.currentDevice().orientation == .LandscapeRight{
                startCapture(positiveRotation: false)
        }
        
        else if(UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)){
            if let overlay: OverlayView = cameraController.cameraOverlayView as? OverlayView{
                if(!overlay.ongoingIntroduction){
                    if overlay.isFilming{
                        cameraController.stopVideoCapture()
                        cameraController.cameraFlashMode = .Off
                        overlay.didChangeToPortrait()
                    }
                }
            }
        }
    }
    
    func startCapture(positiveRotation isPos: Bool){
        if let overlay: OverlayView = cameraController.cameraOverlayView as? OverlayView{
            if(!overlay.ongoingIntroduction && !overlay.isFilming){
                overlay.didBeginFilmingWithPositiveRotation(isPos)
                if overlay.flashOn{
                    cameraController.cameraFlashMode = .On
                }
                else{
                    cameraController.cameraFlashMode = .Off
                }
                cameraController.startVideoCapture()
            }
        }
    }
}
