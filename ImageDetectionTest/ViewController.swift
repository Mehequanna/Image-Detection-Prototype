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

enum ARReferenceImageNames : String {
    case bridge, jungle
}

class ViewController: UIViewController {
    @IBOutlet var arView: ARView!
    
    let player = AVPlayer()
    var siri = AVSpeechSynthesizer()
    
    let contentFor = [
        "bridge" : "Water Lily Pond by Claude Monet. In 1883 Monet moved to Giverny where he lived until his death. There, on the grounds of his property, he created a water garden 'for the purpose of cultivating aquatic plants', over which he built an arched bridge in the Japanese style. In 1899, once the garden had matured, the painter undertook 17 views of the motif under differing light conditions. Surrounded by luxuriant foliage, the bridge is seen here from the pond itself, among an artful arrangement of reeds and willow leaves.",
        "jungle" : "Surprised! by Henri Rousseau. This jungle scene was painted by the French artist, Henri Rousseau, in 1891, and is signed in the bottom left corner. Rousseau is now famous for his jungle scenes, although it is thought that he never actually visited a jungle – rather, he took his inspiration from trips to the Jardin des Plantes, the botanical gardens in Paris, and from prints and illustrated books. Rousseau later described the painting as representing a tiger pursuing explorers, but he may originally have intended the 'surprise' to be the sudden tropical storm breaking in the sky above the tiger. We can see long streaks of lightening, and imagine the rumble of thunder. Stripes govern the whole design, in tones of green, yellow, orange, brown and red, and the tiger is well camouflaged amongst the lush foliage.",
    ]
    
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
        // TODO use different video
        guard let videoUrl = Bundle.main.url(forResource: "tomandjerry", withExtension: ".mp4") else {
            print("Video not found in bundle.")
            return nil
        }
        
        let asset = AVURLAsset(url: videoUrl)
        let videoItem = AVPlayerItem(asset: asset)
        
        return videoItem
    }
    
    func createVideoMaterial(videoItem: AVPlayerItem?) -> VideoMaterial {
        let videoMaterial = VideoMaterial(avPlayer: player)
        
        if (videoItem != nil) {
            player.replaceCurrentItem(with: videoItem)
            player.play()
        }
        
        return videoMaterial
    }
    
    // MARK: Siri
    
    func say(what description: String) {
        siri.stopSpeaking(at: .immediate)
        let content = AVSpeechUtterance(string: description)
        siri.speak(content)
    }
}

// MARK: ARSessionDelegate

extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            
            if let imageAnchor = anchor as? ARImageAnchor,
               let imageName = imageAnchor.name {
                
                if imageName == ARReferenceImageNames.bridge.rawValue {
                    siri.stopSpeaking(at: .immediate)
                    
                    // Create video material
                    let width = Float(imageAnchor.referenceImage.physicalSize.width)
                    let height = Float(imageAnchor.referenceImage.physicalSize.height)
                    let videoScreen = createVideoScreen(width: width, height: height)
                    
                    // Place video material on image.
                    placeVideoScreen(videoScreen: videoScreen, imageAnchor: imageAnchor)
                } else if imageName == ARReferenceImageNames.jungle.rawValue,
                          let content = contentFor[imageName] {
                    player.pause()
                    say(what: content)
                }
            }
        }
    }
    
    // Handle reusing anchors to restart videos.
    
//    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
//        for anchor in anchors {
//
//            if let imageAnchor = anchor as? ARImageAnchor {
//                let imageName = imageAnchor.name
//
//                if imageName == ARReferenceImageNames.bridge.rawValue {
//                    // TODO make this work
//                    player.pause()
//                }
//            }
//        }
//    }
}
