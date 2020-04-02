package it.unisi.sirslab.covidwear

import android.Manifest
import android.content.Context
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
import kotlinx.android.synthetic.main.activity_main.*
import android.util.Log
import kotlin.math.absoluteValue


class MainActivity : WearableActivity(), SensorEventListener, View.OnClickListener {

    private lateinit var sensorManager: SensorManager
    private var mag: Sensor? = null
    private var acc: Sensor? = null

    private var nRimaningCalib=0
    //private var calib = arrayOf(0.0f,0.0f,0.0f)
    private var calib = 0.0f
    private var caliblist = ArrayList<Float>()
    private var activeMonitoring = false;
    private var rawValue = 0.0f

    private var n=0.0f
    private var stateDanger = false
    private var lastVibTime:Long = 0
    private var lastNotificationTime:Long = 0

    private lateinit var vibrator: Vibrator

    private var RECORD_REQUEST_CODE = 1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Enables Always-on
        setAmbientEnabled()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator

        sensitivitySeekBar.max = 100
        sensitivitySeekBar.progress = 50
        vibrationLengthSeekBar.max=1000
        vibrationLengthSeekBar.progress = 400
        calibrationLengthSeekBar.max = 1000
        calibrationLengthSeekBar.progress = 100
        nRimaningCalib = calibrationLengthSeekBar.progress


        val deviceSensors: List<Sensor> = sensorManager.getSensorList(Sensor.TYPE_ALL)
        textView.text = deviceSensors.toString()

        mag = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
        acc = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)


        if (mag!= null) {
            textView.text = "Mag found"
            mag?.also { m ->  sensorManager.registerListener(this, m, SensorManager.SENSOR_DELAY_FASTEST)}
        } else {
            textView.text = "Mag not found"
        }

        if (acc!= null) {
            textView.text = "Acc found"
            Log.d("tom", "Acc found")
            acc?.also { m ->  sensorManager.registerListener(this, m, SensorManager.SENSOR_DELAY_NORMAL)}
        } else {
            textView.text = "Mag not found"
            Log.d("tom", "Acc NOT found")

        }


        val permission = ContextCompat.checkSelfPermission(this, Manifest.permission.VIBRATE)
        if (permission != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this,arrayOf(Manifest.permission.VIBRATE),RECORD_REQUEST_CODE)
        }

        if(caliblist.isEmpty()) {caliblist.add(0.0f)}
        updateGUI()
    }

  /*  private fun normDif(x:FloatArray):Float {
        sequenceOf(0,1,2).forEach { x[it] -= calib[it] }
        return x?.map { it*it }?.reduce { acc, fl -> acc+fl } ?: 0.0f
    }
*/
    private fun normDif(x:FloatArray):Float {
        var valueSquare = 0.0f
        sequenceOf(0,1,2).forEach {
            valueSquare += x[it]*x[it]
        }
        var ndiff = (valueSquare/100 - calib).absoluteValue
        //return x?.map { it*it }?.reduce { acc, fl -> acc+fl } ?: 0.0f
        return ndiff
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        //TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    private fun updateGUI() {
        runOnUiThread {
            textView.text = n.toString()
            textViewAvg.text = calib.toString()
            textViewSamples.text = caliblist.size.toString()
            textViewStatus.text = if (activeMonitoring)  "Monitoring" else ("calibrating")
            textViewThreshold.text =  sensitivitySeekBar.progress.toString()

            when {
                nRimaningCalib>0 -> textView.setBackgroundColor(Color.YELLOW)
                stateDanger -> textView.setBackgroundColor(Color.RED)
                else -> textView.setBackgroundColor(Color.TRANSPARENT)
            }
        }
    }

    private fun updateVibration() {
        val t = System.currentTimeMillis()
        if (activeMonitoring && stateDanger && (lastVibTime +vibrationLengthSeekBar.progress < t)) {
            vibrator .vibrate(vibrationLengthSeekBar.progress.toLong())
            lastVibTime = t
            if (lastNotificationTime+2000 < t) {
                val notification: Uri =
                    RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
                val r = RingtoneManager.getRingtone(applicationContext, notification)
                r.play()
                lastNotificationTime = t
            }
        }
    }

    private fun updateAverage(value: Float): Float {
        var avg = 0.0f
        if (caliblist.size < calibrationLengthSeekBar.progress) {
            caliblist.add(value)
            println("caliblist size" + caliblist.size.toString())
            Log.d("tom", "caliblist size" + caliblist.size.toString())

        }
        else {
            caliblist.removeAt(0)
            caliblist.add(value)
            println("- +" + value.toString())
            Log.d("tom", "- +" + value.toString())

        }
        return caliblist.average().toFloat()
    }


//    override fun onSensorChanged(event: SensorEvent?) {
//        if (event?.sensor == mag) {
//            val v = event?.values ?: return
//            if (nRimaningCalib > 0) {
//                sequenceOf(0, 1, 2).forEach { calib[it] = calib[it] * 0.9f + v[it] * 0.1f }
//                nRimaningCalib -= 1
//                return
//            }
//
//            n = normDif(v)
//            stateDanger = n > sensitivitySeekBar.progress
//            updateVibration()
//            updateGUI()
//        }
//    }

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor == mag) {

            val v = event?.values ?: return
            //val rawValue = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2])/100
            rawValue = rawValue*0.9f + ((v[0]*v[0] + v[1]*v[1] + v[2]*v[2]))/100*0.1f

            Log.d("tom", "Magnetometer Values" + v.contentToString())

            if (nRimaningCalib > 0) {
                //sequenceOf(0,1,2).forEach { calib[it] = calib[it]*0.9f + v[it]*0.1f }
                //  calib = calib*0.9f + (v[0]*v[0] + v[1]*v[1] + v[2]*v[2])*0.1f
                Log.d("tom", "Magnetometer Values" + v.contentToString())

                calib = updateAverage(rawValue)

                nRimaningCalib -= 1
                // return
            }
            else if (!activeMonitoring) {
                calib = updateAverage(rawValue)

            }

            n = normDif(v)
            stateDanger = n > sensitivitySeekBar.progress
            updateVibration()
        }

        if(event?.sensor == acc){
            val v = event?.values ?: return
            Log.d("tom", "Accelerometer Values" + v.contentToString())

            if (v[1].absoluteValue > 7 || v[0] >7) {
                Log.d("tom", "Verticale")
                activeMonitoring = true;

            }
            else {
                Log.d("tom", "Orizzontale")
                activeMonitoring = false;
            }



        }
        updateGUI()
    }




    override fun onClick(v: View?) {
        nRimaningCalib = calibrationLengthSeekBar.progress
        updateGUI()
    }
}
