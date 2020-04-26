/*
Copyright (C) 2020 SIRSLab - University of Siena  <Gianluca, Nicole, Tommaso>

This program is part of No Touch-Face App.

No Touch-Face App is a free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

No Touch-Face App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

package it.unisi.sirslab.noFaceTouchAppWear

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioManager
import android.media.ToneGenerator
import android.media.ToneGenerator.TONE_CDMA_ABBR_ALERT
import android.os.Bundle
import android.os.Vibrator
import android.support.wearable.activity.WearableActivity
import android.util.Log
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.android.synthetic.main.activity_nft3.*
import kotlin.math.*


class NFTActivity : WearableActivity(), SensorEventListener, View.OnClickListener {

    private lateinit var sensorManager: SensorManager
    private var mag: Sensor? = null
    private var acc: Sensor? = null
    private var RPY = arrayOf(0.0f,0.0f,0.0f)
    private var righthanded = false

    private var nRimaningCalib=0
    private var calib = 0.0f
    private var stddev = 0.0f // new
    private var calibrFactor = 1.0f // new
    private var caliblist = ArrayList<Float>()
    private var activeMonitoring = false;
    private var rawValue = 0.0f
    private var maxValue = 1.0f
    private var n=0.0f
    private var stateDanger = false
    private var lastVibTime:Long = 0
    private var lastNotificationTime:Long = 0
    private var updateMaxValue = false
    private var lastTimeOn =0.toLong()
    private var useMagnetometer = true;
    private var slope = ArrayList<Float>()
    private var old_pitch =0.0f
    private var alpha = 0.1
    private var accBuffer = ArrayList<Float>()
    private var pitch_dot=0.0f

    private lateinit var vibrator: Vibrator
    private lateinit var toneGen: ToneGenerator
    private val tone = ToneGenerator.TONE_PROP_BEEP

    private var RECORD_REQUEST_CODE = 1

    private val vibrationLength = 1000
    private val averageSamples = 20
    private val maxThreshold = 10
    private var isNFTscreen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_nft1)
        initSensors()
    }

    private fun initSensors(){

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // Get Sensors
        mag = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
        acc = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)


        //val deviceSensors: List<Sensor> = sensorManager.getSensorList(Sensor.TYPE_ALL)
        //textView.text = deviceSensors.toString()

        if (mag!= null) {
            Log.d("DEBUG", "Mag found")
            mag?.also { m ->  sensorManager.registerListener(this, m, SensorManager.SENSOR_DELAY_GAME)}
        } else {
            Log.d("DEBUG", "Mag NOT found")
        }

        if (acc!= null) {
            //textView.text = "Acc found"
            Log.d("DEBUG", "Acc found")
            acc?.also { m ->  sensorManager.registerListener(this, m, SensorManager.SENSOR_DELAY_GAME)}
        }
        else {
            //textView.text = "Mag not found"
            Log.d("DEBUG", "Acc NOT found")
        }

        if(caliblist.isEmpty()) {caliblist.add(0.0f)}
    }

      private fun initNFT(){

        // Enables Always-on
        setAmbientEnabled()

        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        toneGen = ToneGenerator(AudioManager.STREAM_NOTIFICATION,100)

        sensitivitySeekBar.max = maxThreshold
        sensitivitySeekBar.progress = maxThreshold/2
        nRimaningCalib = averageSamples

        isNFTscreen = true

        val permission = ContextCompat.checkSelfPermission(this, Manifest.permission.VIBRATE)
        if (permission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,arrayOf(Manifest.permission.VIBRATE),RECORD_REQUEST_CODE)
        }

        updateGUI()
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        //TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    private fun updateGUI() {
        runOnUiThread {
            if(useMagnetometer){
                textView.text = String.format("%.1f", n) + " " + if (righthanded)  "R" else ("L")
            }
            else
            {
                textView.text = String.format("%.4f", slope.average()) + " " + if (righthanded)  "R" else ("L")
            }
            //textViewMaxv.text = String.format("%.1f", maxValue)
            //textViewAvg.text = calib.toString()
            // textViewSamples.text = caliblist.size.toString()
            //textViewStatus.text = if (activeMonitoring)  "Monitoring" else ("calibrating")
            textViewThreshold.text =  sensitivitySeekBar.progress.toString()
            //textViewRPY.text = String.format("%.2f", RPY[0]) + " "+ String.format("%.2f", RPY[1]) +" "+ String.format("%.2f", RPY[2])


            when {
                stateDanger && activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.RED)
                }
                stateDanger && !activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.YELLOW)
                }
                updateMaxValue -> {
                    textView.setBackgroundColor(Color.BLUE)
                }
                else -> {
                    textView.setBackgroundColor(Color.GREEN)
                    if (activeMonitoring)  textView.setTextColor(Color.WHITE) else textView.setTextColor(Color.LTGRAY)
                }
            }
        }
    }

    private fun updateVibration() {

        val t = System.currentTimeMillis()
        if (activeMonitoring && stateDanger && (lastVibTime +vibrationLength < t)) {
            vibrator .vibrate(vibrationLength.toLong())
            toneGen.startTone(TONE_CDMA_ABBR_ALERT,vibrationLength)
            lastVibTime = t
            /*
            if (lastNotificationTime+2000 < t) {
                val notification: Uri =
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val r = RingtoneManager.getRingtone(applicationContext, notification)
                r.play()
                lastNotificationTime = t
            }

             */
        }
    }

    fun calculateSD(numArray: ArrayList<Float>): Double {
        var standardDeviation = 0.0

        val mean = numArray.average()

        for (num in numArray) {
            standardDeviation += Math.pow(num - mean, 2.0)
        }

        return sqrt(standardDeviation / (numArray.size - 1))
    }

    fun stdDev(array: ArrayList<Float>): Float {
        var variance = 0.0f
        for (sample: Float in array){
            variance += (sample - calib).pow(2)
        }
        variance /= array.size - 1
        return sqrt(variance)
    }

    private fun updateAverage(value: Float) {
        if (caliblist.size < averageSamples) {
            caliblist.add(value)
        }
        else {
            caliblist.removeAt(0)
            caliblist.add(value)
        }
        calib = caliblist.average().toFloat()
        stddev = stdDev(caliblist)
    }

    private fun updateSlope(value: Float) {
        if (slope.size < averageSamples) {
            slope.add(value)
        }
        else {
            slope.removeAt(0)
            slope.add(value)
        }
    }


    override fun onSensorChanged(event: SensorEvent?) {

        if (useMagnetometer) {
            if (!isNFTscreen) {

                if (event?.sensor == mag) {
                    val v = event?.values ?: return
                    rawValue = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / 100

                    updateAverage(rawValue)
                    n = (rawValue - calib).absoluteValue / stddev
                }
                return
            }

            if (event?.sensor == mag && isNFTscreen) {
                val v = event?.values ?: return
                rawValue = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / 100

                if (!activeMonitoring && !updateMaxValue) {
                    updateAverage(rawValue)
                }

                if (updateMaxValue) {
                    val tempval = (rawValue - calib).absoluteValue

                    if (System.currentTimeMillis() - lastTimeOn < 5000) {

                        if (tempval > maxValue) {
                            maxValue = tempval
                            calibrFactor = floor(maxValue / stddev)

                        }
                    } else {

                        updateMaxValue = false
                        sensitivitySeekBar.progress = calibrFactor.toInt()
                        if (sensitivitySeekBar.progress < 0) sensitivitySeekBar.progress = 0
                        if (sensitivitySeekBar.progress > maxThreshold) sensitivitySeekBar.progress =
                            maxThreshold
                    }

                }

                n = (rawValue - calib).absoluteValue / stddev
                stateDanger = n > sensitivitySeekBar.progress
                updateVibration()
            }
        }

        if(event?.sensor == acc && isNFTscreen){
            val v = event?.values ?: return

            val roll = atan2(v[1], v[2]) * 180/kotlin.math.PI;
            val pitch = atan2(-v[0], sqrt(v[1]*v[1] + v[2]*v[2])) * 180/kotlin.math.PI;
            val yaw = 0.0f

            RPY[0] = roll.toFloat()
            RPY[1] = pitch.toFloat()
            RPY[2] = yaw

            Log.d("acc", "Orientation:" + RPY.contentToString())

            if(!righthanded) { //left handed
                //activeMonitoring = roll > -80 && roll < 20 && pitch > -100 && pitch < -30
                activeMonitoring = pitch > -100 && pitch < -20
            }
            else{
                //  activeMonitoring = roll > -20 && roll < 80 && pitch > 30 && pitch < 100
                activeMonitoring = pitch > 20 && pitch < 100
            }

            if(!useMagnetometer) {

                pitch_dot = RPY[1] - old_pitch;
                old_pitch = RPY[1]

                if(!righthanded) {
                    if (pitch_dot < -alpha) { ///sto salendo
                        updateSlope(1.0f)
                    } else {
                        updateSlope(-1.0f)
                    }
                }
                else
                {
                    if (pitch_dot > alpha) { ///sto salendo
                        updateSlope(1.0f)
                    } else {
                        updateSlope(-1.0f)
                    }
                }

                stateDanger = slope.average().toFloat() > 0 // negli ultimi n samples sono salito

                if (stateDanger && activeMonitoring) {
                    updateVibration()
                    Log.d("acc", "Vibro!")
                }


                if (updateMaxValue) { //ricalibro

                    if (System.currentTimeMillis() - lastTimeOn < 2000) {
                        accBuffer.add(RPY[1])
                    }
                    else {
                        val stdAcc = calculateSD(accBuffer)
                        updateMaxValue = false
                        val numSTD = sensitivitySeekBar.progress
                        alpha = (numSTD * stdAcc)
                        Log.d("Acc", "alpha " + alpha + " "+ stdAcc)
                        //    sensitivitySeekBar.progress = Math.ceil(alpha).toInt()
                        if (sensitivitySeekBar.progress < 0) sensitivitySeekBar.progress = 0
                        if (sensitivitySeekBar.progress > maxThreshold) sensitivitySeekBar.progress =
                            maxThreshold
                    }

                }

            }

        }
        updateGUI()
    }


    override fun onClick(v: View?) {
        if (v != null) {
            when (v.id) {

                R.id.leftButton -> {
                    righthanded = false
                    setContentView(R.layout.activity_nft2)
                }

                R.id.imageViewL -> {
                    righthanded = false
                    setContentView(R.layout.activity_nft2)
                }

                R.id.rightButton -> {
                    righthanded = true
                    setContentView(R.layout.activity_nft2)
                }

                R.id.imageViewR-> {
                    righthanded = true
                    setContentView(R.layout.activity_nft2)
                }


                R.id.startButton -> {
                    setContentView(R.layout.activity_nft3)
                    lastTimeOn = System.currentTimeMillis()
                    updateMaxValue = true
                    initNFT()
                }

                R.id.noMag -> {
                    setContentView(R.layout.activity_nft3)
                    useMagnetometer =false
                    initNFT()
                }

                R.id.button_decrement -> {
                    sensitivitySeekBar.progress = sensitivitySeekBar.progress-2
                    if (sensitivitySeekBar.progress < 0)
                        sensitivitySeekBar.progress = 0
                    updateGUI()
                }
                R.id.button_increment -> {
                    sensitivitySeekBar.progress = sensitivitySeekBar.progress+2
                    if (sensitivitySeekBar.progress > maxThreshold)
                        sensitivitySeekBar.progress = maxThreshold
                    updateGUI()
                }
                R.id.recalibrate -> {
                    nRimaningCalib = averageSamples
                    updateGUI()
                }
                R.id.autoRecalibrate -> {
                    maxValue = 0.0f
                    updateMaxValue = true
                    lastTimeOn = System.currentTimeMillis()
                    if(!useMagnetometer){
                        accBuffer.clear()
                    }
                    updateGUI()
                }
                R.id.exitButton -> {
                    finish()
                    finishAffinity();
                    System.exit(0)

                }
            }
        }
    }
}
