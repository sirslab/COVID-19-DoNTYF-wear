/*
Copyright (C) 2020 SIRSLab - University of Siena  <Gianluca, Nicole, Tommaso>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

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
            finishAffinity();
            //updateGUI()
        }
    }
}