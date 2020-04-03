package it.unisi.sirslab.covidwear


import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.RingtoneManager
import android.net.Uri
import android.os.Bundle
import android.os.Vibrator
import android.support.wearable.activity.WearableActivity
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.android.synthetic.main.activity_start.*
//import kotlinx.android.synthetic.main.activity_title.*
import android.util.Log
import kotlin.math.absoluteValue
import android.view.Window;
import android.view.WindowManager;

class LogoActivity : WearableActivity(),  View.OnClickListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_start)
    }

    override fun onClick(v: View?) {
        if(v!!.id==R.id.sirsLogo) {
            val intent = Intent(this, TitleActivity::class.java)
            startActivity(intent)
            //updateGUI()
        }
    }
}