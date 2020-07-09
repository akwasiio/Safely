package shinobi.code.safely

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.*
import android.util.Log
import androidx.core.app.NotificationCompat
import com.github.nisrulz.sensey.Sensey
import com.github.nisrulz.sensey.ShakeDetector

class TheService : Service() {
    private val receiver = ScreenReceiver()
    private var wakeLock: PowerManager.WakeLock? = null
    lateinit var vibrator: Vibrator

    override fun onCreate() {
        super.onCreate()
        Sensey.getInstance().init(applicationContext)
        val manager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = manager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Sensor:WakeLogTag")
        val screenStateFilter = IntentFilter()
        screenStateFilter.addAction(Intent.ACTION_SCREEN_ON)
        screenStateFilter.addAction(Intent.ACTION_SCREEN_OFF)
        registerReceiver(receiver, screenStateFilter)

        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
    }

    val shakeListener: ShakeDetector.ShakeListener = object : ShakeDetector.ShakeListener {
        override fun onShakeDetected() {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                vibrator.vibrate(
                        VibrationEffect.createOneShot(
                                2000,
                                VibrationEffect.DEFAULT_AMPLITUDE
                        )
                )
            else
                vibrator.vibrate(2000)
        }

        override fun onShakeStopped() {
            Sensey.getInstance().stopShakeDetection(this)
            val intent = Intent(applicationContext, LocationService::class.java)
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val numbers = prefs.getString("flutter.addedContacts", null)
            numbers?.let { nums ->
                val parsed = ArrayList<String>()
                parsed.addAll(nums.split(","))
                intent.putStringArrayListExtra("nums", parsed)
                startService(intent)
                val handler = Handler()
                val runner = Runnable {
                    stopService(intent)
                }
                handler.postDelayed(runner, 60_000)
            }
        }
    }

    override fun onDestroy() {
        unregisterReceiver(receiver)
        if (wakeLock?.isHeld as Boolean)
            wakeLock?.release()
        stopForeground(true)
        stopSelf()
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        super.onStartCommand(intent, flags, startId)
        val notification = getSafelyNotification()
        startForeground(Process.myPid(), notification)
        wakeLock?.acquire(100)
        return START_STICKY
    }

    private fun getSafelyNotification(): Notification {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val chan = NotificationChannel(MainActivity.CHANNEL, "Safely", NotificationManager.IMPORTANCE_HIGH)
            val mNotificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (mNotificationManager.getNotificationChannel(MainActivity.CHANNEL) == null) {
                mNotificationManager.createNotificationChannel(chan)
            }
            chan.description = "Safely notifications"
            val notificationBuilder: NotificationCompat.Builder = NotificationCompat.Builder(applicationContext, "com.shinobi.safely")
            notificationBuilder.setOngoing(true)
                    .setContentTitle("Safely")
                    .setPriority(NotificationManager.IMPORTANCE_HIGH)
                    .setCategory(Notification.CATEGORY_SERVICE)
                    .build()
        } else {
            Notification()
        }
    }

    inner class ScreenReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {

            if (intent?.action == Intent.ACTION_SCREEN_ON) {
                Sensey.getInstance().stop()
                stopForeground(true)
                stopSelf()
                Log.e("Screen_ON", "Service and Sensey stopped when screen came on!")
            } else if (intent?.action == Intent.ACTION_SCREEN_OFF) {
                val notification = getSafelyNotification()
                startForeground(Process.myPid(), notification)
                startService(Intent(applicationContext, TheService::class.java))
                Log.e("SCREEN_OFF ::", "RUNNABLE STARTS NEXT! SERVICE HAS STARTED. ")
                val runnable = Runnable {
                    Sensey.getInstance().startShakeDetection(20f, 1000, shakeListener)
                }
                Handler().postDelayed(runnable, 500)
            }
        }
    }
}
