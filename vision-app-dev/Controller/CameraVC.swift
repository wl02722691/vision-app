//
//  ViewController.swift
//  vision-app-dev
//
//  Created by 張書涵 on 2018/2/13.
//  Copyright © 2018年 AliceChang. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState{
    case off
    case on
}

class CameraVC: UIViewController {

    var captureSession:AVCaptureSession!
    var cameraOutput:AVCapturePhotoOutput!
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var photoData:Data?
    
    var flashControlState:FlashState = .off
    
    
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
        //點一下後會觸發的內容
        
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
        
        if flashControlState == .off{
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request:VNRequest,error:Error?){
        //handle changing the label text
        guard let results = request.results as? [VNClassificationObservation] else {return}
        for classification in results{
            print(classification.identifier)
            print(classification.confidence)
            if classification.confidence < 0.5{
                self.identicationLbl.text = "我不是很確定這是什麼，請再試一次"
                self.confidenceLbl.text = ""
                break
            }else{
                self.identicationLbl.text = classification.identifier
                self.confidenceLbl.text = "信心指數:\(Int(classification.confidence * 100))%"
                break
              
            }
        }
    }
    @IBAction func flashButttonWasPressed(_ sender: Any) {
        switch flashControlState{
        case .off:
            flashBtn.setTitle("FLASH ON", for: .normal)
            flashControlState = .on
        case .on:
            flashBtn.setTitle("FLASH OFF", for: .normal)
            flashControlState = .off
        }
    }
}




extension CameraVC:AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error{
            debugPrint(error)
        }else{
            photoData = photo.fileDataRepresentation()
            
            do{
                let model = try VNCoreMLModel(for: SqueezeNet().model)
                let request = VNCoreMLRequest(model: model, completionHandler: resultsMethod)
                let handler = VNImageRequestHandler.init(data: photoData!)
                try handler.perform([request])
            }catch{
                    debugPrint(error)
                //Handle errors
            }
            
            
            let image = UIImage(data: photoData!)
            self.captureImageView.image = image
            
        }
    }
}

