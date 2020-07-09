package shinobi.code.safely

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GeneratedPluginRegistrant.registerWith(this)

        MethodChannel(flutterView, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendSms") {
                val number = call.argument<String>("phone")
                val message = call.argument<String>("message")
                val numberList = number?.split(',')


                if (!(number.isNullOrBlank() || message.isNullOrBlank())) {
                    val intent = Intent(this, LocationService::class.java)
                    val bundle = Bundle()
                    bundle.putString("message", message)
                    val list = ArrayList<String>()
                    list.addAll(numberList!!)
                    bundle.putStringArrayList("numbers", list)
                    intent.putExtras(bundle)
                    startService(intent)

                    result.success("success")
                    val handler = Handler()
                    val runner = Runnable {
                        stopService(intent)
                    }
                    handler.postDelayed(runner, 60_000)
                } else {
                    result.error("Err", "An error occurred!", "")
                }
            } else if (call.method == "persistContactsNatively") {
                val number = call.argument<String>("phone")
                val prefs = getPreferences(Context.MODE_PRIVATE)
                val editor = prefs.edit()
                editor.putString("numbers", number)
                editor.apply()
                result.success("success")
            } else {
                result.notImplemented()
            }
        }

    }


    override fun onStop() {
        super.onStop()
        startService(Intent(this, TheService::class.java))
    }

    companion object {
        const val CHANNEL = "io.safely.code.shinobi/"
    }

}
