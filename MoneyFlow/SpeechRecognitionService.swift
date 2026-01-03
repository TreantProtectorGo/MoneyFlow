//
//  SpeechRecognitionService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import Foundation
import Speech
import AVFoundation
import Combine

class SpeechRecognitionService: ObservableObject {
    
    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    
    private let speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    enum SpeechError: LocalizedError {
        case recognizerUnavailable
        case notAuthorized
        case audioEngineError
        case recognitionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .recognizerUnavailable:
                return "語音辨識服務不可用"
            case .notAuthorized:
                return "需要語音辨識權限"
            case .audioEngineError:
                return "音訊引擎錯誤"
            case .recognitionFailed(let reason):
                return "辨識失敗：\(reason)"
            }
        }
    }
    
    init() {
        // 使用繁體中文辨識器
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-Hant-HK"))
        speechRecognizer?.defaultTaskHint = .dictation
        
        // 監聽授權狀態
        authorizationStatus = SFSpeechRecognizer.authorizationStatus()
    }
    
    /// 請求語音辨識權限
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.authorizationStatus = status
                    continuation.resume(returning: status == .authorized)
                }
            }
        }
    }
    
    /// 開始錄音和辨識
    func startRecording() throws {
        // 檢查權限
        guard authorizationStatus == .authorized else {
            throw SpeechError.notAuthorized
        }
        
        // 檢查辨識器可用性
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }
        
        // 取消之前的任務
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
        
        // 設定音訊會話
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        // 建立辨識請求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechError.audioEngineError
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        // 取得輸入節點
        let inputNode = audioEngine.inputNode
        
        // 建立辨識任務
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            var isFinal = false
            
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
                isFinal = result.isFinal
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        }
        
        // 配置音訊格式
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // 準備並啟動音訊引擎
        audioEngine.prepare()
        try audioEngine.start()
        
        DispatchQueue.main.async {
            self.isRecording = true
            self.recognizedText = ""
        }
    }
    
    /// 停止錄音
    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
    
    /// 重置
    func reset() {
        stopRecording()
        DispatchQueue.main.async {
            self.recognizedText = ""
        }
    }
}
