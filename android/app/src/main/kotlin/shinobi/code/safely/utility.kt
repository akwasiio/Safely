package shinobi.code.safely

import android.telephony.SmsManager
import android.util.Log
import java.lang.Exception

fun sendSms(number: String?, message: String?): Int {
    return try {
        val smsManager = SmsManager.getDefault()
        smsManager.sendTextMessage(
                number,
                null,
                message,
                null,
                null
        )
        1
    } catch (ex: Exception) {
        ex.printStackTrace()
        0
    }
}
