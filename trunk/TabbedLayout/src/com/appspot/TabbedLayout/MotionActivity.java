package com.appspot.TabbedLayout;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

import android.app.Activity;
import android.content.Context;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

public class MotionActivity extends TopBarActivity  implements SensorEventListener {
	public final static String FILENAME = "motionData.ascn";
	private FileOutputStream fos;
	
	
	
    final String tag = "IBMEyes";
    SensorManager sm = null;
    TextView xViewA = null;
    TextView yViewA = null;
    TextView zViewA = null;
    TextView azimuthO = null;
    TextView pitchO = null;
    TextView rollO = null;

    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
       // get reference to SensorManager
        sm = (SensorManager) getSystemService(SENSOR_SERVICE);
        setContentView(R.layout.motion);
        xViewA = (TextView) findViewById(R.id.xbox);
        yViewA = (TextView) findViewById(R.id.ybox);
        zViewA = (TextView) findViewById(R.id.zbox);
        azimuthO = (TextView) findViewById(R.id.azimuth);
        pitchO = (TextView) findViewById(R.id.pitch);
        rollO = (TextView) findViewById(R.id.roll);
    }
    public void onSensorChanged(SensorEvent event) {
    	float[] values = event.values;
    	Sensor sensor = event.sensor;
    	long timestamp = event.timestamp;
    	
        synchronized (this) {
            Log.d(tag, "onSensorChanged: " + sensor + ", x: " + 
values[0] + ", y: " + values[1] + ", z: " + values[2]);
            if (sensor.getType() == Sensor.TYPE_ORIENTATION) {
                azimuthO.setText("Orientation X: " + values[0]); // 0 to 360 (horizontal to ground)
                pitchO.setText("Orientation Y: " + values[1]); // -180 to 180
                rollO.setText("Orientation Z: " + values[2]); // -90 to 90
            }
            if (sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
                xViewA.setText("Accel X: " + values[0]);
                yViewA.setText("Accel Y: " + values[1]);
                zViewA.setText("Accel Z: " + values[2]);
                
                String accelData = values[0] + " " + values[1] + " " + values[2] + " " + timestamp +"\n";
                
                try {
					fos.write(accelData.getBytes());
				} catch (IOException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
				
            }
        }
    }
    
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    	Log.d(tag,"onAccuracyChanged: " + sensor + ", accuracy: " + accuracy);
    }
    @Override
    protected void onResume() {
        super.onResume();
      // register this class as a listener for the orientation and accelerometer sensors
        sm.registerListener(this, 
        		sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_UI);
        sm.registerListener(this, 
        		sm.getDefaultSensor(Sensor.TYPE_ORIENTATION), SensorManager.SENSOR_DELAY_UI);
        
        // Get the fileOutputStream
        try {
			fos = openFileOutput(FILENAME, Context.MODE_PRIVATE);
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    }
    
    @Override
    protected void onPause() {
    	super.onPause();

		try {
			fos.close();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    }
    
    @Override
    protected void onStop() {
        // unregister listener
        sm.unregisterListener(this);
        super.onStop();
    }    
    
    
}
