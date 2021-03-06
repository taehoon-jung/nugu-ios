//
//  TTSAgent.swift
//  NuguAgents
//
//  Created by MinChul Lee on 11/04/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

import NuguCore

import RxSwift

final public class TTSAgent: TTSAgentProtocol, CapabilityDirectiveAgentable, CapabilityEventAgentable, CapabilityFocusAgentable {
    // CapabilityAgentable
    public var capabilityAgentProperty: CapabilityAgentProperty = CapabilityAgentProperty(category: .textToSpeech, version: "1.0")
    
    // CapabilityEventAgentable
    public let upstreamDataSender: UpstreamDataSendable
    
    // CapabilityFocusAgentable
    public let focusManager: FocusManageable
    public let channelPriority: FocusChannelPriority
    
    // Private
    private let playSyncManager: PlaySyncManageable
    
    private let ttsDispatchQueue = DispatchQueue(label: "com.sktelecom.romaine.tts_agent", qos: .userInitiated)
    
    private let delegates = DelegateSet<TTSAgentDelegate>()
    
    private var focusState: FocusState = .nothing
    private var ttsState: TTSState = .finished {
        didSet {
            log.info("\(oldValue) \(ttsState)")
            guard oldValue != ttsState else { return }
            guard let media = currentMedia else { return }
            
            switch ttsState {
            case .idle, .stopped, .finished:
                currentMedia = nil
                playSyncManager.releaseSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
            case .playing:
                playSyncManager.startSync(delegate: self, dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
            }
            
            delegates.notify { delegate in
                delegate.ttsAgentDidChange(state: ttsState, dialogRequestId: media.dialogRequestId)
            }
        }
    }
    
    private let ttsResultSubject = PublishSubject<(dialogRequestId: String, result: TTSResult)>()
    
    // Current play Info
    private var currentMedia: TTSMedia?
    
    private var playerIsMuted: Bool = false {
        didSet {
            currentMedia?.player.isMuted = playerIsMuted
        }
    }
    
    private let disposeBag = DisposeBag()
    
    public init(
        focusManager: FocusManageable,
        channelPriority: FocusChannelPriority,
        upstreamDataSender: UpstreamDataSendable,
        playSyncManager: PlaySyncManageable,
        contextManager: ContextManageable,
        directiveSequencer: DirectiveSequenceable
    ) {
        log.info("")
        
        self.focusManager = focusManager
        self.channelPriority = channelPriority
        self.upstreamDataSender = upstreamDataSender
        self.playSyncManager = playSyncManager
        
        contextManager.add(provideContextDelegate: self)
        focusManager.add(channelDelegate: self)
        directiveSequencer.add(handleDirectiveDelegate: self)
        
        ttsResultSubject.subscribe(onNext: { [weak self] (_, result) in
            // Send error
            switch result {
            case .error(let error):
                self?.upstreamDataSender.sendCrashReport(error: error)
            default: break
            }
        }).disposed(by: disposeBag)
    }
    
    deinit {
        log.info("")
    }
}

// MARK: - TTSAgentProtocol

public extension TTSAgent {
    func add(delegate: TTSAgentDelegate) {
        delegates.add(delegate)
    }
    
    func remove(delegate: TTSAgentDelegate) {
        delegates.remove(delegate)
    }
    
    func requestTTS(text: String, playServiceId: String?, handler: ((TTSResult) -> Void)?) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let typeInfo: Event.TypeInfo = .speechPlay(text: text)
            let event = Event(token: nil, playServiceId: playServiceId, typeInfo: typeInfo)
            let dialogRequestId = TimeUUID().hexString
            self.sendEvent(
                event,
                dialogRequestId: dialogRequestId,
                messageId: TimeUUID().hexString
            )
            
            self.ttsResultSubject
                .filter { $0.dialogRequestId == dialogRequestId }
                .take(1)
                .do(onNext: { (_, result) in
                    handler?(result)
                })
                .subscribe().disposed(by: self.disposeBag)
        }
    }
    
    func stopTTS(cancelAssociation: Bool) {
        stop(cancelAssociation: cancelAssociation)
    }
}

// MARK: - HandleDirectiveDelegate

extension TTSAgent: HandleDirectiveDelegate {
    public func handleDirectivePrefetch(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        log.info("\(directive.header.type)")
        
        switch directive.header.type {
        case DirectiveTypeInfo.speak.type:
            prefetchPlay(directive: directive, completionHandler: completionHandler)
        default:
            completionHandler(.success(()))
        }
    }
    
    public func handleDirective(
        _ directive: Downstream.Directive,
        completionHandler: @escaping (Result<Void, Error>) -> Void
        ) {
        log.info("\(directive.header.type)")
        
        guard let directiveTypeInfo = directive.typeInfo(for: DirectiveTypeInfo.self) else {
            completionHandler(.failure(HandleDirectiveError.handleDirectiveError(message: "Unknown directive")))
            return
        }
        
        switch directiveTypeInfo {
        case .speak:
            // Speak 는 재생 완료 후 handler 호출
            play(directive: directive, completionHandler: completionHandler)
        case .stop:
            completionHandler(stop(cancelAssociation: true))
        }
    }
    
    public func handleAttachment(_ attachment: Downstream.Attachment) {
        log.info("\(attachment.header.messageId)")
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia, media.dialogRequestId == attachment.header.dialogRequestId else {
                log.warning("TextToSpeechItem not exist or dialogRequesetId not valid")
                return
            }
            
            let player = media.player as? MediaOpusStreamDataSource
            do {
                try player?.appendData(attachment.content)
                
                if attachment.isEnd {
                    try player?.lastDataAppended()
                }
            } catch {
                self.upstreamDataSender.sendCrashReport(error: error)
                log.error(error)
            }
        }
    }
}

// MARK: - FocusChannelDelegate

extension TTSAgent: FocusChannelDelegate {
    public func focusChannelDidChange(focusState: FocusState) {
        log.info("\(focusState) \(ttsState)")
        self.focusState = focusState
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            switch (focusState, self.ttsState) {
            case (.foreground, let ttsState) where [.idle, .stopped, .finished].contains(ttsState):
                self.currentMedia?.player.play()
            // Foreground. playing 무시
            case (.foreground, _):
                break
            case (.background, .playing):
                self.stop(cancelAssociation: false)
            // background. idle, stopped, finished 무시
            case (.background, _):
                break
            case (.nothing, .playing):
                self.stop(cancelAssociation: false)
            // none. idle/stopped/finished 무시
            case (.nothing, _):
                break
            }
        }
    }
}

// MARK: - ContextInfoDelegate

extension TTSAgent: ContextInfoDelegate {
    public func contextInfoRequestContext() -> ContextInfo? {
        let payload: [String: Any] = [
            "ttsActivity": ttsState.value,
            "version": capabilityAgentProperty.version,
            "engine": "skt"
        ]
        
        return ContextInfo(contextType: .capability, name: capabilityAgentProperty.name, payload: payload)
    }
}

// MARK: - MediaPlayerDelegate

extension TTSAgent: MediaPlayerDelegate {
    public func mediaPlayerDidChange(state: MediaPlayerState) {
        log.info(state)
        
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            guard let media = self.currentMedia else { return }
            
            switch state {
            case .start:
                self.sendEvent(media: media, info: .speechStarted)
                self.ttsState = .playing
            case .resume, .bufferRefilled:
                self.ttsState = .playing
            case .finish:
                // Release focus after receiving directive
                self.sendEvent(media: media, info: .speechFinished) { [weak self] _ in
                    self?.releaseFocusIfNeeded()
                }
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .finished))
                self.ttsState = .finished
            case .pause:
                media.player.stop()
            case .stop:
                self.sendEvent(media: media, info: .speechStopped)
                self.ttsResultSubject.onNext(
                    (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
                )
                self.ttsState = .stopped
                self.releaseFocusIfNeeded()
            case .bufferUnderrun:
                break
            case .error(let error):
                self.sendEvent(media: media, info: .speechStopped)
                self.ttsResultSubject.onNext((dialogRequestId: media.dialogRequestId, result: .error(error)))
                self.ttsState = .stopped
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - PlaySyncDelegate

extension TTSAgent: PlaySyncDelegate {
    public func playSyncIsDisplay() -> Bool {
        return false
    }
    
    public func playSyncDuration() -> PlaySyncDuration {
        return .short
    }
    
    public func playSyncDidChange(state: PlaySyncState, dialogRequestId: String) {
        log.info("\(state)")
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            if case .released = state,
                let media = self.currentMedia, media.dialogRequestId == dialogRequestId {
                self.stopSilently()
                self.currentMedia = nil
                self.releaseFocusIfNeeded()
            }
        }
    }
}

// MARK: - SpeakerVolumeDelegate

extension TTSAgent: SpeakerVolumeDelegate {
    public func speakerVolumeType() -> SpeakerVolumeType {
        return .nugu
    }
    
    public func speakerVolumeIsMuted() -> Bool {
        return playerIsMuted
    }
    
    public func speakerVolumeShouldChange(muted: Bool) -> Bool {
        playerIsMuted = muted
        return true
    }
}

// MARK: - Private (Directive)

private extension TTSAgent {
    func prefetchPlay(directive: Downstream.Directive, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else { return }
            
            let result = Result<Void, Error>(catching: {
                guard let data = directive.payload.data(using: .utf8) else {
                    throw HandleDirectiveError.handleDirectiveError(message: "Invalid payload")
                }
                
                let payload = try JSONDecoder().decode(TTSMedia.Payload.self, from: data)
                guard case .attachment = payload.sourceType else {
                    throw HandleDirectiveError.handleDirectiveError(message: "Not supported sourceType")
                }
                
                self.stopSilently()
                
                let mediaPlayer = OpusPlayer()
                mediaPlayer.delegate = self
                mediaPlayer.isMuted = self.playerIsMuted
                
                self.currentMedia = TTSMedia(
                    player: mediaPlayer,
                    payload: payload,
                    dialogRequestId: directive.header.dialogRequestId
                )
                
                self.playSyncManager.prepareSync(
                    delegate: self,
                    dialogRequestId: directive.header.dialogRequestId,
                    playServiceId: payload.playStackControl?.playServiceId
                )
            })
            
            completionHandler(result)
        }
    }
    
    func play(directive: Downstream.Directive, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self else {
                completionHandler(.success(()))
                return
            }
            guard let media = self.currentMedia, media.dialogRequestId == directive.header.dialogRequestId else {
                log.warning("TextToSpeechItem not exist or dialogRequesetId not valid")
                completionHandler(.success(()))
                return
            }
            
            self.delegates.notify { delegate in
                delegate.ttsAgentDidReceive(text: media.payload.text, dialogRequestId: media.dialogRequestId)
            }
            
            self.ttsResultSubject
                .filter { $0.dialogRequestId == media.dialogRequestId }
                .take(1)
                .do(onNext: { (_, _) in
                    completionHandler(.success(()))
                })
                .subscribe().disposed(by: self.disposeBag)
            
            self.focusManager.requestFocus(channelDelegate: self)
        }
    }
    
    @discardableResult func stop(cancelAssociation: Bool) -> Result<Void, Error> {
        ttsDispatchQueue.async { [weak self] in
            guard let self = self, let media = self.currentMedia else { return }
            self.currentMedia?.cancelAssociation = cancelAssociation

            media.player.stop()
            if cancelAssociation == true {
                self.playSyncManager.releaseSyncImmediately(dialogRequestId: media.dialogRequestId, playServiceId: media.payload.playStackControl?.playServiceId)
            }
        }
        return .success(())
    }
    
    /// Stop previously playing TTS
    func stopSilently() {
        guard let media = currentMedia else { return }
        media.player.delegate = nil
        media.player.stop()
        sendEvent(media: media, info: .speechStopped)
        ttsResultSubject.onNext(
            (dialogRequestId: media.dialogRequestId, result: .stopped(cancelAssociation: media.cancelAssociation))
        )
        ttsState = .stopped
    }
}

// MARK: - Private (Event)

private extension TTSAgent {
    func sendEvent(media: TTSMedia, info: Event.TypeInfo, resultHandler: ((Result<Downstream.Directive, Error>) -> Void)? = nil) {
        guard let playServiceId = media.payload.playServiceId else {
            log.debug("TTSMedia does not have playServiceId")
            return
        }
        
        sendEvent(
            Event(
                token: media.payload.token,
                playServiceId: playServiceId,
                typeInfo: info
            ),
            dialogRequestId: TimeUUID().hexString,
            messageId: TimeUUID().hexString,
            resultHandler: resultHandler
        )
    }
}

// MARK: - Private(FocusManager)

private extension TTSAgent {
    func releaseFocusIfNeeded() {
        guard focusState != .nothing else { return }
        guard [.idle, .stopped, .finished].contains(ttsState) else {
            log.info("Not permitted in current state, \(ttsState)")
            return
        }
        focusManager.releaseFocus(channelDelegate: self)
    }
}
