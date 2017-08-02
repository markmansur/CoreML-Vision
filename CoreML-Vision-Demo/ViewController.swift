//
//  ViewController.swift
//  cameraTest
//
//  Created by Mark Mansur on 2017-08-01.
//  Copyright © 2017 Mark Mansur. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    let captureSession = AVCaptureSession()
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Label"
        label.font = label.font.withSize(30)
        return label
    }()
    
    var captureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
//        print(discoverySession.devices)
        
        captureDevice = discoverySession.devices[0]
        setupCaptureSession()
        
        view.addSubview(label)
        setupLabel()
        
    }
    
    func setupLabel() {
        label.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50).isActive = true
    }
    
    func setupCaptureSession() {
        configureDevice()
        
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice!)
            captureSession.addInput(captureDeviceInput)
            
            let captureOutput = AVCaptureVideoDataOutput()
            captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            captureSession.addOutput(captureOutput)
            
        } catch _ {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.frame
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
    
    func configureDevice() {
        do {
            try captureDevice?.lockForConfiguration()
        } catch _ {
            return
        }
        captureDevice?.focusMode = .continuousAutoFocus
        captureDevice?.unlockForConfiguration()
    }
    
    
    // called everytime a frame is captured
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedRequest, error) in
            
            guard let results = finishedRequest.results as? [VNClassificationObservation] else { return }
            guard let Observation = results.first else {return }
            
//            print (Observation.identifier,Observation.confidence)
            
            DispatchQueue.main.async(execute: {
                self.label.text = "\(Observation.identifier)"
            })
        }
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // executes request
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    

}

