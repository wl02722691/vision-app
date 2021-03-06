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

enum SoundState{
    case off
    case on
}


class CameraVC: UIViewController{
    
    var imagePicker:UIImagePickerController!
    
    var captureSession:AVCaptureSession!
    
    var cameraOutput:AVCapturePhotoOutput!
    
    var previewLayer:AVCaptureVideoPreviewLayer!
    
    var photoData:Data?
    
    var flashControlState:FlashState = .off
    
    var SoundControlState:SoundState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var captureImageView: RoundedShadowImageView!
    
    @IBOutlet weak var flashBtn: RoundedShadowButton!
    
    @IBOutlet weak var soundBtn: RoundedShadowButton!
    
    
    @IBOutlet weak var identicationLbl: UILabel!
    
    @IBOutlet weak var confidenceLbl: UILabel!
    
    @IBOutlet weak var roundedLblView: RoundShadowView!

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        previewLayer.frame = cameraView.bounds
        speechSynthesizer.delegate = self
        spinner.isHidden = true
        

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
        
        switch SoundControlState {
        case .on:
            print("SoundControlState == .on")
            self.cameraView.isUserInteractionEnabled = false
            self.soundBtn.isUserInteractionEnabled = false
            self.spinner.isHidden = false
            self.spinner.startAnimating()
            
        case .off:
            break
        }
        
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    

    
    func resultsMethod(request:VNRequest,error:Error?){
        //handle changing the label text
        guard let results = request.results as? [VNClassificationObservation] else {return}
        for classification in results{
            print(classification.identifier)
            print(classification.confidence)
            
            if classification.confidence < 0.5 {
                let unknowObjectMessage = "我不是很確定這是什麼，請再試一次"
                self.identicationLbl.text = unknowObjectMessage
                self.confidenceLbl.text = ""
                synthesizeSpeech(fromString: unknowObjectMessage)
                break
            }else{
                let identification = classification.identifier
                let confidentce = (Int(classification.confidence * 100))
                self.identicationLbl.text = identification
                self.confidenceLbl.text = "信心指數:\(confidentce)%"
                let completeSentence = "我\(confidentce)%確定，他是一個\(identification)"
                synthesizeSpeech(fromString: completeSentence)
                
                break
              
            }
        }
    }
    
    func synthesizeSpeech(fromString string:String) {
        switch SoundControlState {
        case .on:
            let speechUtterance = AVSpeechUtterance(string: string)
            speechSynthesizer.speak(speechUtterance)
        case .off:
            break
                }
            }
    
    @IBAction func soundButtinWasPressed(_ sender: Any) {
        switch SoundControlState{
        case .off:
            let soundImage = UIImage(named: "sound")
            soundBtn.setImage(soundImage, for: .normal)
            SoundControlState = .on
            print("on")
            
        case .on:
            
            let soundoffImage = UIImage(named: "soundOff")
            soundBtn.setImage(soundoffImage, for: .normal)
            SoundControlState = .off
            print("off")
            
        }
    }
    
    
    @IBAction func flashButttonWasPressed(_ sender: Any) {
        switch flashControlState{
        case .off:
            let flashimage = UIImage(named: "flash")
            flashBtn.setImage(flashimage, for: .normal)
            flashControlState = .on
        case .on:
            let flashoffimage = UIImage(named: "flash-off")
            flashBtn.setImage(flashoffimage, for: .normal)
            flashControlState = .off


        }
    }
    
    
    
    
}




extension CameraVC:AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput?, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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


extension CameraVC:AVSpeechSynthesizerDelegate{
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
            self.cameraView.isUserInteractionEnabled = true
            self.soundBtn.isUserInteractionEnabled = true
            self.spinner.isHidden = true
            self.spinner.stopAnimating()

    }
}

