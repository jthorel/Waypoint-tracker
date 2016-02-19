//
//  Audio.swift
//  AVAudio
//
//  Created by Max Krog on 2016-02-17.
//  Copyright © 2016 Max Krog. All rights reserved.
//
import CoreLocation
import AVFoundation
class Audio: NSObject{
    
    //MARK: Singleton
    static let singleton = Audio()
    
    //MARK: Soundorientation-values
    var yaw: Float = 0
    var pitch: Float = 0
    var roll: Float = 0
    
    var distance: Float = 0
    
    //MARK: Audio
    var engine = AVAudioEngine()
    var player = AVAudioPlayerNode()
    var envNode = AVAudioEnvironmentNode()

    override init(){
        //player.renderingAlgorithm = AVAudio3DMixingRenderingAlgorithm.HRTF
        //player.occlusion = -10.0
        //player.obstruction = -10.0
        
        envNode.reverbParameters.enable = true
        envNode.reverbParameters.loadFactoryReverbPreset(.Cathedral)
        
        player.reverbBlend = 0.2
        
        envNode.distanceAttenuationParameters.distanceAttenuationModel = AVAudioEnvironmentDistanceAttenuationModel.Inverse
        envNode.distanceAttenuationParameters.maximumDistance = 100
        envNode.distanceAttenuationParameters.referenceDistance = 10
        
        envNode.renderingAlgorithm = .HRTF
        
        envNode.listenerPosition = AVAudioMake3DPoint(0, 0, 0)
        envNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: yaw, pitch: pitch , roll: roll)
        
        super.init()
        
        // MARK: Audio connect nodes
        engine.attachNode(player)
        engine.attachNode(envNode)
        
        //MARK: Load audio-file.
        
        let fileURL = NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("crane", ofType: "wav")!)
        let audioFile = try! AVAudioFile(forReading: fileURL)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(audioFile.length)
        let audioFileBuffer = AVAudioPCMBuffer(PCMFormat: audioFormat, frameCapacity: audioFrameCount)
        try! audioFile.readIntoBuffer(audioFileBuffer)
        
        engine.connect(player, to: envNode, format: audioFormat )
        engine.connect(envNode, to: engine.mainMixerNode , format: nil)
        
        //MARK: Start engine
        try! engine.start()
        
        //MARK: Play sounds
        
        player.scheduleBuffer(audioFileBuffer, atTime: nil, options: .Loops, completionHandler: nil)
        
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    //MARK: Delegate
    func updateDistance (newDistance: Float) {
        distance = newDistance
        player.position = AVAudioMake3DPoint(0, 0, distance)
        print("New audio  distance: \(distance.description)")

    }
    
    func updateObstruction(newObstruction: Float) {
        player.occlusion = newObstruction
    }
    
    func updateRelativeBearing(newRelativeBearing: Double) {
        print("Audio: New bearing: \(newRelativeBearing.description)")
        yaw = Float(newRelativeBearing)
        envNode.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: yaw, pitch: pitch , roll: roll)
        
        let absDist = abs(newRelativeBearing)
        if absDist > 90 {
            print("Value bigger than abs(90)")
            let multi = (absDist - 90) / 90
            print("Multiplier \(multi.description)")
            let occ = multi * -50
            let oc = Float(occ)
            print(occ.description)
            player.occlusion = oc
        } else {
            player.occlusion = 0
        }
        
    }
    
}