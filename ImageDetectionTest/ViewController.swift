//
//  ViewController.swift
//  ImageDetectionTest
//
//  Created by Stephen Emery on 10/24/22.
//

import UIKit
import RealityKit
import ARKit
import AVKit

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet var arView: ARView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Starting Image Tracking
        startImageTracking()
        
        arView.session.delegate = self
        
    }
    
    func startImageTracking() {
        guard let imagesToTrack = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            print("Could not find AR Reference Image.")
            return
        }
        
        // AR Configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = imagesToTrack
        configuration.maximumNumberOfTrackedImages = 2
        
        // Start AR Session
        arView.session.run(configuration)
    }
    
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {

            if let imageAnchor = anchor as? ARImageAnchor {
                // Create video material
                let width = Float(imageAnchor.referenceImage.physicalSize.width)
                let height = Float(imageAnchor.referenceImage.physicalSize.height)
                let videoScreen = createVideoScreen(width: width, height: height)
                
                // Place video material on image.
                placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor)
                
            }
        }
    }
    
    //MARK: - Object placement
    
    func placeVideoScreen(videoScreen: ModelEntity, imageAnchor: ARImageAnchor) {
        let imageAnchorEntity = AnchorEntity(anchor: imageAnchor)
        
        let rotationAngle = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: SIMD3(x: 1, y: 0, z: 0))
        videoScreen.setOrientation(rotationAngle, relativeTo: imageAnchorEntity)
        
        // Positions video to the side
//        let bookwidth = imageAnchor.referenceImage.physicalSize.width
//        videoScreen.setPosition(SIMD3(x: Float(bookwidth), y: 0, z: 0), relativeTo: imageAnchorEntity)
        
        imageAnchorEntity.addChild(videoScreen)
        arView.scene.addAnchor(imageAnchorEntity)
    }
    
    //MARK: - Video Screen
    
    func createVideoScreen(width: Float, height: Float) -> ModelEntity {
        let plane = MeshResource.generatePlane(width: width, height: height)
        let videoItem = createVideoItem(with: "tomandjerry")
        let videoMaterial = createVideoMaterial(videoItem: videoItem)
        
        let videoScreenModel = ModelEntity(mesh: plane, materials: [videoMaterial])
        
        return videoScreenModel
    }
    
    func createVideoItem(with filename: String) -> AVPlayerItem? {
        guard let videoUrl = Bundle.main.url(forResource: "tomandjerry", withExtension: ".mp4") else {
            print("Video not found in bundle.")
            return nil
        }
        
        let asset = AVURLAsset(url: videoUrl)
        let videoItem = AVPlayerItem(asset: asset)
        
        return videoItem
    }
    
    func createVideoMaterial(videoItem: AVPlayerItem?) -> VideoMaterial {
        let player = AVPlayer()
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        if (videoItem != nil) {
            player.replaceCurrentItem(with: videoItem)
            player.play()
        }

        return videoMaterial
    }
}
