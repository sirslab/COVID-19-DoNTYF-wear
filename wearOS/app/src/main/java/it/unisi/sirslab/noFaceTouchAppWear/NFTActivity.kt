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
import android.os.Environment
import android.os.Vibrator
import android.support.wearable.activity.WearableActivity
import android.util.Log
import android.view.View
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import kotlinx.android.synthetic.main.activity_nft3.*
import java.io.File
import java.io.FileOutputStream
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

    private lateinit var vibrator: Vibrator
    private lateinit var toneGen: ToneGenerator
    private val tone = ToneGenerator.TONE_PROP_BEEP

    private var RECORD_REQUEST_CODE = 1

    private val vibrationLength = 1000
    private val averageSamples = 20
    private val maxThreshold = 100
    private var isNFTscreen = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_nft1)
        initSensors()
        writeFileInternalStorage("Start Log...\n")
        writeFileExternalStorage("Start Log...\n")
    }

    ///////////////// Added to Log Data ////////////////////
    private val filenameInternal: String? = "logIntFile"
    private val filenameExternal: String? = "logExtFile"


    fun writeFileInternalStorage(dataToLog: String) {
        createUpdateFile(filenameInternal!!, dataToLog, false)
    }

    fun appendFileInternalStorage(dataToLog: String) {
        createUpdateFile(filenameInternal!!, dataToLog, true)
    }

    private fun createUpdateFile(fileName: String, content: String, update: Boolean) {
        val outputStream: FileOutputStream
        try {
            outputStream = if (update) {
                openFileOutput(fileName, Context.MODE_APPEND)
            } else {
                openFileOutput(fileName, Context.MODE_PRIVATE)
            }
            outputStream.write(content.toByteArray())
            outputStream.flush()
            outputStream.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun writeFileExternalStorage(dataToLog: String) {
        val state = Environment.getExternalStorageState()
        //external storage availability check
        if (Environment.MEDIA_MOUNTED != state) {
            return
        }
        appendFileInternalStorage("External check: External memory is available.\n")
        val file = File(
            Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOCUMENTS
            ), filenameExternal
        )
        appendFileInternalStorage("External check: External memory at path " + Environment.DIRECTORY_DOCUMENTS)
        var outputStream: FileOutputStream? = null
        try {
            file.createNewFile()
            //second argument of FileOutputStream constructor indicates whether to append or create new file if one exists
            outputStream = FileOutputStream(file, true)
            outputStream.write(dataToLog.toByteArray())
            outputStream.flush()
            outputStream.close()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    ///////////////////////////////////////////////////////


    private fun initSensors(){

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager

        // Get Sensors
        mag = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
        acc = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)


        //val deviceSensors: List<Sensor> = sensorManager.getSensorList(Sensor.TYPE_ALL)
        //textView.text = deviceSensors.toString()

        if (mag!= null) {
            //textView.text = "Mag found"
            mag?.also { m ->  sensorManager.registerListener(this, m, SensorManager.SENSOR_DELAY_GAME)}
        } else {
            //textView.text = "Mag not found"
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
            textView.text = String.format("%.1f", n) + " " + if (righthanded)  "R" else ("L")
            //textViewMaxv.text = String.format("%.1f", maxValue)
            //textViewAvg.text = calib.toString()
            // textViewSamples.text = caliblist.size.toString()
            //textViewStatus.text = if (activeMonitoring)  "Monitoring" else ("calibrating")
            textViewThreshold.text =  sensitivitySeekBar.progress.toString()
            //textViewRPY.text = String.format("%.2f", RPY[0]) + " "+ String.format("%.2f", RPY[1]) +" "+ String.format("%.2f", RPY[2])


            when {
                stateDanger && activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.RED)
                    //textViewStatus.setBackgroundColor(Color.RED)
                }
                stateDanger && !activeMonitoring && !updateMaxValue -> {
                    textView.setBackgroundColor(Color.YELLOW)
                    //textViewStatus.setBackgroundColor(Color.YELLOW)
                }
                updateMaxValue -> {
                    textView.setBackgroundColor(Color.BLUE)
                    //textViewStatus.setBackgroundColor(Color.BLUE)
                }
                else -> {
                    textView.setBackgroundColor(Color.GREEN)
                    if (activeMonitoring)  textView.setTextColor(Color.WHITE) else textView.setTextColor(Color.LTGRAY)
                   // textViewStatus.setBackgroundColor(Color.GREEN)
                   // textViewStatus.setTextColor(Color.WHITE)
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
            appendFileInternalStorage("Vibration ON \n")
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



    override fun onSensorChanged(event: SensorEvent?) {
        if (!isNFTscreen) {
            if(event?.sensor == mag ) {
                val v = event?.values ?: return
                rawValue = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]) / 100

                updateAverage(rawValue)
                n = (rawValue - calib).absoluteValue/stddev
            }
            return
        }

        if (event?.sensor == mag && isNFTscreen) {
            val v = event?.values ?: return
            rawValue = (v[0]*v[0] + v[1]*v[1] + v[2]*v[2])/100

            if (!activeMonitoring && ! updateMaxValue) {
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

            n = (rawValue - calib).absoluteValue/stddev
            stateDanger = n > sensitivitySeekBar.progress
            updateVibration()
        }

        if(event?.sensor == acc && isNFTscreen){
            val v = event?.values ?: return

            val roll = atan2(v[1], v[2]) * 180/kotlin.math.PI;
            val pitch = atan2(-v[0], sqrt(v[1]*v[1] + v[2]*v[2])) * 180/kotlin.math.PI;
            val yaw = 0.0f
            RPY[0] = roll.toFloat()
            RPY[1] = pitch.toFloat()
            RPY[2] = yaw
            //  Log.d("orient", "Orientation:" + RPY.contentToString())

            if(!righthanded) { //left handed
                //activeMonitoring = roll > -80 && roll < 20 && pitch > -100 && pitch < -30
                activeMonitoring = pitch > -100 && pitch < -20
            }
            else{
                //  activeMonitoring = roll > -20 && roll < 80 && pitch > 30 && pitch < 100
                activeMonitoring = pitch > 20 && pitch < 100
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
