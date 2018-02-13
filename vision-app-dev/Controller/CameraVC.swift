//
//  ViewController.swift
//  vision-app-dev
//
//  Created by 張書涵 on 2018/2/13.
//  Copyright © 2018年 AliceChang. All rights reserved.
//

import UIKit
import AVFoundation

class CameraVC: UIViewController {

    var captureSession:AVCaptureSession!
    var cameraOutput:AVCapturePhotoOutput!
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var photoData:Data?
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    
    @IBOutlet weak var identicationLbl: UILabel!
    
    @IBOutlet weak var confidenceLbl: UILabel!
    
    @IBOutlet weak var roundedLblView: RoundShadowView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        previewLayer.frame = cameraView.bounds

    }

    override func viewWillAppear(_ animated: Bool) {
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired = 1
        
        super.viewWillAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1920x1080
       
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input) == true {
                captureSession.addInput(input)
            }
            
            cameraOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddOutput(cameraOutput) == true {
                captureSession.addOutput(cameraOutput!)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation = AVCaptureVideoOrientation.portrait
                
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
        } catch {
            debugPrint(error)
        }
    }
    
    
    @objc func didTapCameraView() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings .__availablePreviewPhotoPixelFormatTypes.first! //回傳first的意思是最基本的相機照片，在這個availablePreviewPhotoPixelFormatTypes的Array中的第一個
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType, kCVPixelBufferWidthKey as String: 160, kCVPixelBufferHeightKey as String: 160]
        
        settings.previewPhotoFormat = previewFormat
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraVC:AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
            
        }
    }
}

