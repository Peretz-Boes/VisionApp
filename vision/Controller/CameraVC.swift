//
//  ViewController.swift
//  vision
//
//  Created by peretz on 2017-11-19.
//  Copyright © 2017 peretz. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

enum FlashState {
    case off
    case on
}

class CameraVC: UIViewController {
    var captureSession : AVCaptureSession!
    var cameraOutput : AVCapturePhotoOutput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var photoData:Data?
    var flashControlState = .off
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    
    @IBOutlet weak var captureImageView: UIImageView!
    @IBOutlet weak var identificationLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var cameraView: RoundedShadowImageView!
    @IBOutlet weak var roundedLabelView: RoundedShadowView!
    @IBOutlet weak var flashButton: RoundedShadowButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        previewLayer.frame=cameraView.bounds
        speechSynthesizer.delegate=self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapCameraView))
        tap.numberOfTapsRequired=1
        
        captureSession=AVCaptureSession()
        captureSession.sessionPreset=AVCaptureSession.Preset.hd1920x1080
        let backCamera = AVCaptureDevice.default(for: AVMediaType.video)
        do{
            let input = try AVCaptureDeviceInput(device: backCamera!)
            if captureSession.canAddInput(input)==true {
                captureSession.addInput(input)
            }
            
            cameraOutput=AVCapturePhotoOutput()
            if captureSession.canAddOutput(cameraOutput)==true {
                captureSession.addOutput(cameraOutput!)
                previewLayer=AVCaptureVideoPreviewLayer(session: captureSession!)
                previewLayer.videoGravity=AVLayerVideoGravity.resizeAspect
                previewLayer.connection?.videoOrientation=AVCaptureVideoOrientation.portrait
                cameraView.layer.addSublayer(previewLayer!)
                cameraView.addGestureRecognizer(tap)
                captureSession.startRunning()
            }
            
        }catch{
            debugPrint(error)
        }
        
    }
    
    @objc func didTapCameraView() {
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String:previewPixelType,kCVPixelBufferWidthKey as String:160,kCVPixelBufferHeightKey as String:160]
        settings.previewPhotoFormat=previewFormat
        if flashControlState==.off {
            settings.flashMode = .off
        }else{
            settings.flashMode = .on
        }
        cameraOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func resultsMethod(request:VNRequest,error:Error?) {
        guard let results=request.results as? [VNClassificationObservation] else {
            return
        }
        for classification in results {
            if classification.confidence<0.5{
                self.identificationLabel.text="Unknown what this is. Please try again"
                self.confidenceLabel.text=""
                break
            }else{
                self.identificationLabel.text=classification.identifier
                self.confidenceLabel.text="Confidence: \(Int(classification.confidence*100))%"
                break
            }
        }
    }
    
    func synthesizeSpeech(fromString string:String) {
        let speechUtterance = AVSpeechUtterance(string: string)
        
    }
    
    @IBAction func flashButtonWasPressed(_ sender: Any) {
        switch flashControlState {
        case .off:
            flashButton.setTitle("Flash on", for: .normal)
        case .on:
            flashButton.setTitle("Flash off", for: .normal)
        default:
            <#code#>
        }
    }
}

extension CameraVC:AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error=error {
            debugPrint(error)
        }else{
            photoData=photo.fileDataRepresentation()
            do{
                let model = try VNCoreMLModel(for:SqueezeNet().model)
                let request = VMCoreMLRequest(model:model,completionHandler:resultsMethod,error:Error)
                let handler = VNImageRequestHandler(data:photoData!)
                try handler.perform([request])
            }catch{
                debugPrint(error)
            }
            let image = UIImage(data: photoData!)
            self.captureImageView.image=image
            
        }
    }
}

extension CameraVC:AVSpeechSynthesizerDelegate{
    
}