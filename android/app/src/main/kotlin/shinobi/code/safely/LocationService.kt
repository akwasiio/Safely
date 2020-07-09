package shinobi.code.safely

import android.app.Service
import android.content.Context
import android.content.Intent
import android.location.Location
import android.location.LocationManager
import android.os.Bundle
import android.os.IBinder
import android.util.Log


class LocationService : Service() {
    private var mLocationManager: LocationManager? = null


    var mLocationListeners = arrayOf(
        LocationListener(LocationManager.GPS_PROVIDER),
        LocationListener(LocationManager.NETWORK_PROVIDER)
    )

    inner class LocationListener(provider: String) : android.location.LocationListener {
        private var mLastLocation: Location

        init {
            Log.e(TAG, "LocationListener $provider")
            mLastLocation = Location(provider)
        }

        override fun onLocationChanged(location: Location) {
            Log.e(TAG, "onLocationChanged: $location")
            mLastLocation.set(location)
            sendTextMessage(message, numbers)

        }

        private fun sendTextMessage(mess: String, num: ArrayList<String>) {
            val long = mLastLocation.longitude
            val lat = mLastLocation.latitude

            val maps = "http://maps.google.com/?q=$lat,$long"
            for (i in 0 until num.size) {
                Thread.sleep(2000)
                sendSms(
                        num[i],
                        message = """Hey, I might be in trouble. Please find me at $maps .
                            | $message
                        """.trimMargin()
                )
            }
        }
        override fun onProviderDisabled(provider: String) {
            Log.e(TAG, "onProviderDisabled: $provider")
        }

        override fun onProviderEnabled(provider: String) {
            Log.e(TAG, "onProviderEnabled: $provider")
        }

        override fun onStatusChanged(provider: String, status: Int, extras: Bundle) {
            Log.e(TAG, "onStatusChanged: $provider")
        }
    }

    override fun onBind(arg0: Intent): IBinder? {
        return null
    }

    private lateinit var numbers: ArrayList<String>

    private lateinit var message: String

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.e(TAG, "onStartCommand")
        super.onStartCommand(intent, flags, startId)
        val bundle = intent?.extras
        numbers = bundle?.getStringArrayList("nums")!!
        message = bundle.getString("message") ?: "I'm caught up in an emergency."
        return START_STICKY
    }

    override fun onCreate() {
        Log.e(TAG, "onCreate")
        initializeLocationManager()
        try {
            mLocationManager!!.requestLocationUpdates(
                LocationManager.NETWORK_PROVIDER, LOCATION_INTERVAL.toLong(), LOCATION_DISTANCE,
                mLocationListeners[1]
            )
        } catch (ex: java.lang.SecurityException) {
            Log.i(TAG, "fail to request location update, ignore", ex)
        } catch (ex: IllegalArgumentException) {
            Log.d(TAG, "network provider does not exist, " + ex.message)
        }

        try {
            mLocationManager!!.requestLocationUpdates(
                LocationManager.GPS_PROVIDER, LOCATION_INTERVAL.toLong(), LOCATION_DISTANCE,
                mLocationListeners[0]
            )
        } catch (ex: java.lang.SecurityException) {
            Log.i(TAG, "fail to request location update, ignore", ex)
        } catch (ex: IllegalArgumentException) {
            Log.d(TAG, "gps provider does not exist " + ex.message)
        }

    }

    override fun onDestroy() {
        Log.e(TAG, "onDestroy")
        super.onDestroy()
        if (mLocationManager != null) {
            for (i in mLocationListeners.indices) {
                try {
                    mLocationManager!!.removeUpdates(mLocationListeners[i])
                } catch (ex: Exception) {
                    Log.i(TAG, "fail to remove location listners, ignore", ex)
                }
            }
        }
    }

    private fun initializeLocationManager() {
        Log.e(TAG, "initializeLocationManager")
        if (mLocationManager == null) {
            mLocationManager =
                applicationContext.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        }
    }

    companion object {
        private val TAG = "BOOMBOOMTESTGPS"
        private val LOCATION_INTERVAL = 30_000
        private val LOCATION_DISTANCE = 0f

    }
}
