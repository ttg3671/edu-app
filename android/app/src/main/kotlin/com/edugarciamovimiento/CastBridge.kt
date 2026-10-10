package com.edugarciamovimiento

import android.util.Log
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Reports the real Cast SDK state (session, player state, position, device
 * volume) to Flutter and exposes device volume / mute.
 *
 * The flutter_chrome_cast plugin still does discovery, connecting and the
 * media commands, but its own status events are not reliable enough to drive
 * the player UI: it drops every media status it fails to parse (which happens
 * for HLS streams, whose tracks have no content type) and it never reports
 * device volume changes. This reads the same values straight from the SDK.
 */
class CastBridge(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "CastBridge"
        private const val CHANNEL = "com.edugarciamovimiento/cast"
        private const val PROGRESS_INTERVAL_MS = 500L
    }

    private val channel = MethodChannel(messenger, CHANNEL)
    private var listening = false
    private var session: CastSession? = null
    private var client: RemoteMediaClient? = null
    private var suspended = false

    private val mediaCallback = object : RemoteMediaClient.Callback() {
        override fun onStatusUpdated() = sendState()
        override fun onMetadataUpdated() = sendState()
    }

    private val progressListener = RemoteMediaClient.ProgressListener { progress, duration ->
        channel.invokeMethod(
            "onProgress",
            mapOf("positionMs" to progress, "durationMs" to duration)
        )
    }

    private val castListener = object : Cast.Listener() {
        override fun onVolumeChanged() = sendState()
    }

    private val sessionListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarting(session: CastSession) {}
        override fun onSessionStarted(session: CastSession, sessionId: String) = attach(session)
        override fun onSessionStartFailed(session: CastSession, error: Int) = detach()
        override fun onSessionEnding(session: CastSession) = detach()
        override fun onSessionEnded(session: CastSession, error: Int) = detach()
        override fun onSessionResuming(session: CastSession, sessionId: String) {}
        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) = attach(session)
        override fun onSessionResumeFailed(session: CastSession, error: Int) = detach()
        override fun onSessionSuspended(session: CastSession, reason: Int) {
            suspended = true
            sendState()
        }
    }

    init {
        channel.setMethodCallHandler(this)
    }

    private val sessionManager: SessionManager?
        get() = try {
            CastContext.getSharedInstance()?.sessionManager
        } catch (e: Exception) {
            null
        }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "init" -> {
                    init()
                    result.success(snapshot())
                }
                "getState" -> result.success(snapshot())
                "setVolume" -> {
                    session?.volume = (call.arguments as Number).toDouble().coerceIn(0.0, 1.0)
                    result.success(null)
                }
                "setMuted" -> {
                    session?.isMute = call.arguments as Boolean
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.w(TAG, "${call.method} failed", e)
            result.error("CAST_BRIDGE", e.message, null)
        }
    }

    /** Called once per Dart start-up, after the Cast context is initialised. */
    private fun init() {
        val manager = sessionManager ?: return
        if (!listening) {
            listening = true
            manager.addSessionManagerListener(sessionListener, CastSession::class.java)
        }
        // A session that outlived the previous Flutter UI (the activity was
        // closed but the process stayed alive) is one the new Dart side never
        // hears about: the app would show "not connected" while the TV keeps
        // playing, and picking the TV again would do nothing. Always start
        // from a clean, disconnected state instead.
        detach()
        if (manager.currentCastSession != null) {
            manager.endCurrentSession(true)
        }
    }

    private fun attach(newSession: CastSession) {
        release()
        suspended = false
        session = newSession
        try {
            newSession.addCastListener(castListener)
            client = newSession.remoteMediaClient?.also {
                it.registerCallback(mediaCallback)
                it.addProgressListener(progressListener, PROGRESS_INTERVAL_MS)
            }
        } catch (e: Exception) {
            Log.w(TAG, "attach failed", e)
        }
        sendState()
    }

    private fun detach() {
        release()
        sendState()
    }

    private fun release() {
        try {
            client?.unregisterCallback(mediaCallback)
            client?.removeProgressListener(progressListener)
            session?.removeCastListener(castListener)
        } catch (e: Exception) {
            Log.w(TAG, "release failed", e)
        }
        client = null
        session = null
        suspended = false
    }

    private fun snapshot(): Map<String, Any?> {
        val s = session
        val c = client
        val connected = try {
            s?.isConnected == true
        } catch (e: Exception) {
            false
        }
        val phase = when {
            s == null -> "none"
            suspended && !connected -> "suspended"
            else -> "connected"
        }
        val map = mutableMapOf<String, Any?>(
            "phase" to phase,
            "deviceName" to s?.castDevice?.friendlyName,
            "playerState" to 0,
            "idleReason" to 0,
            "positionMs" to 0L,
            "durationMs" to 0L,
            "volume" to 0.0,
            "muted" to false,
            "hasVolume" to false,
        )
        try {
            if (c != null) {
                map["playerState"] = c.playerState
                map["idleReason"] = c.idleReason
                map["positionMs"] = c.approximateStreamPosition
                map["durationMs"] = c.streamDuration
            }
            if (s != null && connected) {
                map["volume"] = s.volume
                map["muted"] = s.isMute
                map["hasVolume"] = true
            }
        } catch (e: Exception) {
            Log.w(TAG, "snapshot failed", e)
        }
        return map
    }

    private fun sendState() {
        channel.invokeMethod("onState", snapshot())
    }

    fun dispose() {
        release()
        if (listening) {
            listening = false
            try {
                sessionManager?.removeSessionManagerListener(sessionListener, CastSession::class.java)
            } catch (e: Exception) {
                Log.w(TAG, "dispose failed", e)
            }
        }
        channel.setMethodCallHandler(null)
    }
}
