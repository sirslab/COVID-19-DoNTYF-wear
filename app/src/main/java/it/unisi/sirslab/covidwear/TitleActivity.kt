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
import kotlinx.android.synthetic.main.activity_title.*
import android.util.Log
import kotlin.math.absoluteValue
import android.view.Window;
import android.view.WindowManager;

class TitleActivity : WearableActivity(),  View.OnClickListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_title)
    }

    private fun updateGUI() {
        /*runOnUiThread {
            textView.text = String.format("%.2f", n) // ; n("%.2f").toString
            textViewMaxv.text = String.format("%.1f", maxValue)
            // textViewAvg.text = calib.toString()
            // textViewSamples.text = caliblist.size.toString()
            textViewStatus.text = if (activeMonitoring)  "Monitoring" else ("calibrating")
            textViewThreshold.text =  sensitivitySeekBar.progress.toString()

            when {
                nRimaningCalib>0 -> {
                    textView.setBackgroundColor(Color.YELLOW)
                    textViewStatus.setBackgroundColor(Color.YELLOW)
                }
                stateDanger && activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.RED)
                    textViewStatus.setBackgroundColor(Color.RED)
                                   }
                stateDanger && !activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.MAGENTA)
                    textViewStatus.setBackgroundColor(Color.MAGENTA)
                }
                updateMaxValue -> {
                    textView.setBackgroundColor(Color.BLUE)
                    textViewStatus.setBackgroundColor(Color.BLUE)
                }
                else -> {
                    textView.setBackgroundColor(Color.GREEN)
                    textView.setTextColor(Color.WHITE)
                    textViewStatus.setBackgroundColor(Color.GREEN)
                    textViewStatus.setTextColor(Color.WHITE)
                }
            }
        }*/
    }


    override fun onClick(v: View?) {
        if(v!!.id==R.id.enterButton) {
            val intent = Intent(this, MainActivity::class.java)
            startActivity(intent)
            //updateGUI()
        }
    }
}