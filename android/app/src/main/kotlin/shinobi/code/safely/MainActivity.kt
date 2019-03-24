package shinobi.code.safely

import android.annotation.TargetApi
import android.app.Notification
import android.os.Process
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import io.flutter.app.FlutterActivity
import com.github.nisrulz.sensey.Sensey
import com.github.nisrulz.sensey.ShakeDetector
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    private val CHANNEL = "safely.flutter.io/safely"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)
        Sensey.getInstance().init(applicationContext)
        Log.e("SENSE:", "Sensey Instance created.")
    }

    override fun onStop() {
        super.onStop()
        startService(Intent(this, TheService::class.java))
    }

    override fun onResume() {
        super.onResume()
        stopService(Intent(this, TheService::class.java))
    }
}


@TargetApi(11)
class TheService : Service() {
    val receiver = ScreenReceiver()
    companion object {
        val TAG = TheService::class.java.simpleName
    }
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        Sensey.getInstance().init(applicationContext)
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = manager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Sensor:WakeLogTag")
        registerReceiver(receiver, IntentFilter(Intent.ACTION_SCREEN_OFF))

    }

    val shakeListener = object : ShakeDetector.ShakeListener{
        override fun onShakeDetected() {
            Log.e("SHAKE:::", "Hey I detected a shake event. Sensey rocks!")
        }

        override fun onShakeStopped() {
            Log.e("SHAKESTOPPED:", "Hey I detected that the shake event has stopped. Sensey Rocks!")
        }
    }

    override fun onDestroy() {
        unregisterReceiver(receiver)
        if (wakeLock?.isHeld as Boolean)
            wakeLock?.release()
        Sensey.getInstance().stopShakeDetection(shakeListener)
        stopForeground(true)
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        startForeground(Process.myPid(), Notification())
        wakeLock?.acquire(100)

        return START_STICKY
    }

    inner class ScreenReceiver : BroadcastReceiver(){
        override fun onReceive(context: Context?, intent: Intent?) {
            Log.i("SCREEN_STATE", "OnReceive($intent)")

            if (intent?.action != Intent.ACTION_SCREEN_OFF) return

            val runnable = Runnable {
                Log.e("RUNNABLE", "Runnable Executing...")
                Sensey.getInstance().startShakeDetection(shakeListener)
//                startService(Intent(context, TheService::class.java))
            }
            Handler().postDelayed(runnable, 1000)
        }
    }
}