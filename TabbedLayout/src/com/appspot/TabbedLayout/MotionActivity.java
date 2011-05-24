package com.appspot.TabbedLayout;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Vector;


import android.app.Activity;
import android.content.Context;
import android.content.res.Configuration;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

/**
 * I record accelerometer and azimuth, pitch, roll data
 * @author AlexFandrianto
 *
 */

public class MotionActivity extends TopBarActivity  implements SensorEventListener {
	public final static String FILENAME = "motionData.ascn";
	public final static int MAX_POINTS = 1000;
	

	public static TextView classification;
	private FileOutputStream fos;
	
	private int counter = 0;
	
	private SoundManager mSoundManager;
	
    /**
     * Measurements that are being plotted.
     */
    private static Vector<Measurement> measurements;
	
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
        
        classification = (TextView) findViewById(R.id.classification);
        classification.setTextSize(20);
        classification.setText("Activity: None");
        
        measurements = new Vector<Measurement>();
        
        mSoundManager = new SoundManager();
        mSoundManager.initSounds(getBaseContext());
        mSoundManager.addSound(1, R.raw.idling);
        mSoundManager.addSound(2, R.raw.running);
        mSoundManager.addSound(3, R.raw.walking);
        mSoundManager.addSound(4, R.raw.biking);
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
				
				measurements.insertElementAt(
			            new Measurement(values[0], values[1], values[2], 0 /* Ignore time field*/), 0);
			        if (measurements.size() > MAX_POINTS) {
			            measurements.setSize(MAX_POINTS);
			        }
			        
			    	int LENGTH = 512;
			    	counter++;
			        if (measurements.size() >= LENGTH && counter == 512)
			        {
			        	counter = 0;
			        	Complex[] c = new Complex[LENGTH];
			        	for (int i = 0; i < LENGTH; i++)
			        	{
			        		Measurement m = measurements.get(i);
			        		c[i] = new Complex(Math.sqrt(m.x*m.x + m.y*m.y + m.z*m.z), 0);
			        	}
			        	Complex[] trans = FFT.fft(c);
			        	double[] d = new double[LENGTH];
			        	double normF = 0;
			        	double meanF = 0;
			        	for (int i = 0; i < LENGTH; i++)
			        	{
			        		d[i] = trans[i].abs();
			        		if (i < 4 || i +4 >= LENGTH)
			        		System.out.println(i + ": " + d[i]);
			        		normF += d[i] * d[i];
			        		meanF += d[i] * (i+1);
			        	}
			        	normF = Math.sqrt(normF);
			        	meanF /= LENGTH * normF;
			        	
			        	double stdF = 0;
			        	double energyF = 0;
			        	for (int i = 0; i < LENGTH; i++)
			        	{
			        		stdF += (d[i] * (i+1) / normF - meanF) * (d[i] * (i+1) / normF - meanF);
			        		energyF += d[i] * d[i];
			        	}
			        	stdF /= LENGTH;
			        	stdF = Math.sqrt(stdF);
			        	energyF /= LENGTH;
			        	
			        	
			        	double[] red = new double[3];
			        	red[0] = meanF;
			        	red[1] = stdF;
			        	red[2] = energyF / 100000;
			        	
			        	double resultWvI = walkingVsIdling(red);
			        	double resultRvI = runningVsIdling(red);
			        	double resultWvR = walkingVsRunning(red);
			        	double resultWvB = walkingVsBiking(red);
			        	double resultRvB = runningVsBiking(red);
			        	double resultIvB = idlingVsBiking(red);
			        	System.out.println(resultWvI + " " + resultRvI+ " " + resultWvR+ " " + resultWvB+ " " + resultRvB+ " " + resultIvB);
			        	
			        	double w = (resultWvI + resultWvR + resultWvB) / 3;
			        	double r = (resultRvI + (1 - resultWvR) + resultRvB) / 3;
			        	double i = (2 - resultWvI - resultRvI + resultIvB) / 3;
			        	double b = (3 - resultWvB - resultRvB - resultIvB) / 3;
			        	
			        	if (i > r && i > w && i > b)
			        	{
			        		if (((String)classification.getText()).indexOf("Idling") == -1 || true)
			        			mSoundManager.playSound(1);
			        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Idling " + i);
			        	}
			        	else if (r > i && r > w && r > b)
			        	{
			        		if (((String)classification.getText()).indexOf("Running") == -1 || true)
			        			mSoundManager.playSound(2);
			        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Running " + r);
			        	}
			        	else if (w > i && w > r && w > b)
			        	{
			        		if (((String)classification.getText()).indexOf("Walking") == -1 || true)
			        			mSoundManager.playSound(3);
			        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Walking " + w);
			        	}
			        	else
			        	{
			        		if (((String)classification.getText()).indexOf("Biking") == -1 || true)
			        			mSoundManager.playSound(4);
			        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Biking " + b);
			        	}
			        	
			        	
			        }

			        
			        
				
            }
        }
    }
    
    
    public double walkingVsIdling(double[] red)
    {
    	// For walking vs idling {1, 3, x} with x between 1 and 3.
    	
    	/** Alex's weights
    	double[][] w1 = {{0.8438 ,   1.0632  ,  0.0293 ,   0.5072},
    	    {0.5896 ,   0.5305 , -0.9537  , -2.2006},
    	    {1.1394  , -0.9506 ,  -1.4211 ,   3.4108},
    	   {-0.1457   , 0.4987 ,  -0.6722 ,  -0.6232},
    	    {0.7528   , 0.5248  , -1.2448  , -2.1190},
    	};
    	double[][] w2 = {{0.1994  , -1.6328 ,   2.1320  , -1.8682 ,  -1.1888 ,   1.3053},
    		   {-0.6637  , -1.2715 ,   1.1030 ,  -0.7869,   -0.8656 ,   0.5739},
    		    {0.7890  , -1.2822  ,  2.5371  ,  1.0140 ,  -2.9722 ,  -0.5927},
    		   {-0.4548  , -2.8627  ,  2.0919  , -1.0710 ,   0.1422 ,   1.1696},
    		    {1.0399 ,  -1.1573  ,  1.6427  , -1.6365 ,  -3.1910  ,  1.6093}};
    	double[][] w3 = {{-3.3153 ,  -0.3032 ,  -1.1334 ,  -2.0590 ,  -3.9007 ,   4.5734}};
    	**/
    	/** Dai Wei's weights **/
    	double[][] w1 = {{1.4722 ,  -1.9585  ,  0.5958 ,   0.0163},
    	        {2.9524  , -5.0743 ,   1.4579  ,  3.4363},
    	        {2.8172  , -2.6679  ,  1.4274 ,   0.9180},
    	        {1.6689  ,  2.1630 ,  -2.9614 ,  -6.1193},
    	        {3.8175  ,  5.7970 ,  -1.6670 ,  -0.4188}};
    	    	double[][] w2 = {{-0.4984 ,  -2.7277 ,  -2.2438  ,  3.8381 ,   1.1638,   -0.7755},
    	    		   {-1.6224 ,  -2.8382  , -1.5403   , 2.4800  ,  1.6106  , -1.1076},
    	    		   {-1.8177 ,  -3.7288  , -1.5079  ,  3.2357  ,  1.1203 ,  -0.1257},
    	    		   {-0.6175 ,  -1.2671  , -1.0422  ,  1.3612 ,   4.3499 ,   0.0700},
    	    		   {-0.2890 ,  -1.0655  , -1.4881 ,   1.0440  ,  5.3336 ,  -0.4757}};
    	    	double[][] w3 = {{4.2087 ,   2.3846 ,  -0.0957   , 2.8367  ,  1.4591 ,  -6.1199}};
    	
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
    						sigmoidM(multiplyVectorWithOne(w2,
    						sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double walkingVsRunning(double[] red)
    {
    	// For walking vs idling {1, 3, x} with x between 1 and 3.
    	/*double[][] w1 = {{-0.4470,    1.7171,   -0.9534  ,  0.7626},
    		   {-0.9541 ,  -0.5000  , -2.3893  , -1.2829},
    		   {-1.1919 ,   0.6473  ,  2.3547  ,  0.2526},
    		   {-0.1138 ,   0.9742  , -0.0610  , -2.2409},
    		   {-1.3076 ,   0.0585 ,   1.9156  , -1.6768}
    	};
    	double[][] w2 = {{0.2964  ,  0.0711  ,  1.4643  , -0.4143  ,  0.6082  , -0.7833},
    	    {0.6475 ,  -0.5578  , -0.6507 ,  -0.7922  ,  1.4385 ,  -0.9303},
    	    {-0.5968,   -1.0311 , -1.0334  ,  0.8897  ,  0.8999 ,   1.1015},
    	     {0.7603 ,  -1.1215  , -1.1155 , -1.5519 ,   0.9419 ,   0.1604},
    	    {-0.3473  ,  0.1873 ,  -1.7453 ,   0.6958 ,   1.1072  , -0.0843}};
    	double[][] w3 = {{-0.3862  , -8.2719,   -2.5574 ,  -0.1003 ,  -6.2207,    5.1501}};*/
    	double[][] w1 = {{0.5925 ,   1.1153  ,  0.0540 ,  -1.7069},
        	    {1.6419,   -2.0247 ,  -0.8192  ,  0.7496},
        	    {-3.9635 ,   0.3355 ,   8.4632 ,  -2.8420},
        	    {-0.6051  ,  0.8641 ,   0.6781  ,  0.8028},
        	    {-0.4423  , -1.1931 ,   0.1522 ,   1.0075},
            	};
        	double[][] w2 = {{-2.4939 ,   2.9850  , -2.5728 ,   0.9658  ,  0.7294 ,   1.8060},
        		   {-0.6908  , -1.0106 ,  -2.7828 ,   0.1931 ,   1.6303  ,  0.9176},
        		    {0.4939  , -2.0008 ,  -1.9998  , -1.3234 ,  -0.7185  , -0.3844},
        		   {-1.7051 ,   0.5564 ,  -3.0171 ,   1.6455  ,  0.6563  ,  0.9569},
        		    {1.0649 ,   1.1601 ,  -3.4705 ,  -0.6424  ,  0.6973  ,  0.8095}};
        	double[][] w3 = {{3.4561 ,   2.4165 ,  -0.3188 ,   4.6202 ,   4.3906  , -5.7724}};
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
    						sigmoidM(multiplyVectorWithOne(w2,
    						sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double walkingVsBiking(double[] red)
    {
    	/** Alex's
    	double[][] w1 = {{0.4503  , -0.8868  , -0.6072 ,   0.6090},
    		   {-3.7071  ,  0.0002 ,   3.6950 ,   4.0711},
    		   {-2.0433 ,   0.0128 ,   2.4876  ,  0.6996},
    		    {0.4274 ,   0.8824  ,  1.3403 ,   0.2667},
    		    {5.0208 ,  -0.2995  , -2.4849 ,  -4.8438}
    	};
    	double[][] w2 = {{0.8520  , -0.0086 ,   1.0742  , -2.5009  , -0.3765 ,  -1.0030},
    		   {-0.7916  ,  1.3971 ,   2.2831 ,   0.2514 ,  -2.7836  ,  0.4050},
    		   {-1.3784  ,  2.6190 ,  1.4618 ,  -0.4165 ,  -2.3561 ,   0.5676},
    		   {-1.5303 ,   3.0327 ,   2.3250  ,  0.4563 ,  -2.9609 ,   0.1014},
    		   { 1.3422 ,   2.2008  , -0.7538  , -0.8492 ,  -1.7646 ,  -0.0299}};
    	double[][] w3 = {{-1.4189  , -3.2873  , -5.2199  , -5.8599  ,  0.7604 ,   7.0362}};
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
    						sigmoidM(multiplyVectorWithOne(w2,
    						sigmoidM(multiplyVectorWithOne(w1, red))))));
    	
    	return result[0];**/
    	
    	/** Dai Wei's Is inverse of biking vs walking **/
    	double[][] w1 = {{-4.2738  ,  2.5944  ,  3.0673 ,  -1.5461},
        {4.1430 ,   1.2800 ,  -4.5021  , -2.8739},
        {1.6694 ,  -4.0981 ,  -2.0720 ,   3.5636},
        {6.9778 ,   0.7672 ,   7.1223 , -16.2948},
       {-4.3011 ,  -0.8088 ,   3.2186 ,   2.1056}};
    	double[][] w2 = {{-2.4505  ,  2.1403  ,  2.7100 ,  -4.1178,   -2.0975 ,  -0.2945},
    		   {-1.1005  ,  5.1699 ,   2.3689 ,  -4.4155 ,  -2.5370,   -0.5900},
    		   {-0.8498 ,  -1.3325  , -0.6585 ,  -0.9397 ,  -1.1867 ,  -1.3923},
    		   {-1.4127 ,   0.3475  ,  2.2177 ,  -4.2192 ,  -2.9297 ,   0.2718},
    		   {-2.3659 ,   1.7898 ,   2.1888 ,  -3.7840 ,  -0.4472 ,  -0.6111}};
    	double[][] w3 = {{5.2390 ,   4.6036 ,  -1.1818  ,  0.5058 ,   3.0875 ,  -5.3338}};
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));

    	return 1 - result[0];
    	
    }
    
    public double runningVsIdling(double[] red)
    {
    	/** Alex's
    	double[][] w1= {{-0.7097  , -0.5873,   -1.9263 ,   0.5169},
    	   {-1.2026 ,  -0.0614 ,   1.4148 ,  -0.5318},
    	    {0.6214 ,  -0.9253 ,  -0.9599 ,  -1.7551},
    	   {-0.0142 ,  -0.5903 ,   0.1713 ,   1.7029},
    	   {-1.7343 ,  -0.0556 ,   0.3437  ,  1.1927}};
    	double[][] w2 = {{1.5058 ,  -1.2060 ,  -0.4371 ,   2.5984 ,   3.1833 ,  -1.1473},
    		{ 0.0368 ,  -1.6753 ,   1.4677  ,  1.3016  ,  2.3567  , -0.0194},
    	    {1.6136  , -1.7191 ,  -0.8151  ,  1.5118   , 1.3868 ,   0.1627},
    	   {-0.4133  ,  2.3093  , -1.5449  ,  0.2662 ,  -0.1146  ,  1.6439},
    	    {0.0374  ,  1.1677  ,  0.1279  ,  2.4488 ,   0.1081  ,  0.4092}};
    	double[][] w3 = {{-4.2704  , -1.0621,   -2.6289,    3.6779 ,  -0.6997 ,   0.3744}};
    	**/
    	/** Dai Wei's **/
    	double[][] w1 = {{-0.5766 ,   1.9294  ,  0.4134  , -2.1893},
    		   {-0.1956  , -1.3624 ,  -0.0538 ,   1.5302},
    		    {0.6113  , -0.7352 ,   0.3812  , -3.1897},
    		    { 1.3487 ,  -0.0461 ,   0.3137 ,  -0.5180},
    		   {-0.0672  ,  0.6886  , -0.6397  , -3.4115}};
    	double[][] w2 = {{-1.7685 ,   1.5302  ,  0.6056 ,  -1.2990 ,  -1.5639 ,   1.7809},
    			{ -0.2911 ,   0.8957 ,   0.3391  ,  0.5465 ,  -3.2401  ,  0.5604},
    			{ -2.1994 ,   0.9390 ,   0.8706 ,  0.0451 ,  -1.9868 ,   1.4345},
    		    {0.4412  ,  2.3826  ,  2.1131 ,  -0.4041 ,  -2.5782 ,  -0.0603},
    		   {-0.3930 ,  -0.7617,   -0.3539 ,  -0.8433 ,  -2.3750 ,   1.0385}};
    	double[][] w3 = {{-3.9249,   -0.2120,   -0.7358 ,  -0.5467 ,  -2.5034 ,   2.1956}};
    	
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double runningVsBiking(double[] red)
    {
    	/** Alex's
    	double[][] w1= {{-1.0191  ,  0.9259 ,  -2.3346  ,  0.8495},
    		   {-1.9253 ,  -0.1467 ,  -0.4244,   -1.6250},
    		   {-0.6567 ,   0.2978 ,  -1.2139,    0.8782},
    		   {-1.5463 ,   0.6693 ,  -1.6440 ,   1.9131},
    		   {-0.4671 ,  -0.8679 ,  -0.0228 ,  -0.6928}};
    	double[][] w2 = {{-3.2313 ,  -0.0210,   -0.3809 ,  -1.7261  ,  0.2885  ,  1.2868},
    		   {-1.2221 ,   0.8655 ,  -1.3048 ,  -2.5934  , -0.7255  ,  1.1229},
    		   {-1.6017 ,  -0.8356  , -2.3716 ,  -1.4926 ,   0.2277 ,   1.0526},
    		   {-2.3810 ,  -2.6476 ,  -1.5789 ,  -2.2947 ,   0.1062 ,   1.7273},
    		   {-1.3327 ,   0.6449 ,   0.7183 ,  -1.0328  ,  0.5000  , -2.2677}};
    	double[][] w3 = {{3.8811  ,  0.3503 ,   0.2879  ,  4.5723  , -1.0723 ,  -3.5545}};
    	**/
    	double[][] w1 = {{-0.5255  , -0.8688  , -1.1667 ,   0.1114},
    		   {-1.2018 ,   0.3578 ,  -6.0854 ,   6.8071},
    		   {-0.5147  , -0.5201  ,  6.4264 ,  -1.3746},
    		   {-0.2754  ,  2.0673  , -2.7087 ,  -1.9956},
    		    {0.9022 ,   2.3517  ,  1.2702 ,   2.3998}};
    	double[][] w2 = {{0.6859 ,  -4.5967  ,  1.1295 ,  -0.4304  ,  0.0440  ,  0.4048},
    	    {0.0820 ,  -3.0000  ,  1.8895 ,  -1.3776 ,   0.3029 ,  -0.2510},
    	    {-0.9805 ,   2.7156 ,   1.8527 ,   1.9195 ,   0.3366 ,  -0.0061},
    	     {1.5662 ,  -2.0677 ,   3.2188 ,  -1.2552 ,   0.6673  ,  0.3389},
    	     {0.5225 ,  -3.9919 ,   1.8297 ,  -1.0130 ,   1.9164  , -1.7525}};
    	double[][] w3 = {{5.0076 ,   2.0873 ,  -3.3136 ,   2.4724 ,   2.1287 ,  -1.1767}};
    	
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double idlingVsBiking(double[] red)
    {
    	/** Alex's
    	double[][] w1= {{-3.9762 ,   2.0561  , -1.2829 ,  -1.2573},
    	    {0.0971  ,  2.0607 ,  -0.8261 ,  -2.1496},
    	    {0.3415  ,  0.0547 ,  -0.7838 ,  -1.5499},
    	    {1.5303  , -0.5113 ,  -0.3256 ,   0.2203},
    	    {0.8575  , -1.2023 ,  -0.7454 ,  -0.1341}};
    	double[][] w2 = {{2.4450,    1.5185 ,  -0.2771   ,-1.4825  ,  0.7029  , -1.7220},
    	    {2.5148 ,   1.0409  , -0.3429 ,  -0.7567 ,  -1.9827  , -1.6011},
    	    {2.1161 ,   1.4544 ,   0.2932 ,  -2.5687  , -1.9097  , -0.9329},
    	    {2.3992 ,   2.0529  ,  0.0222 ,  -0.2192  ,  0.0856  , -2.8257},
    	   {-1.2395 ,  -1.7078  ,  1.7687  , -1.5538  ,  0.6768  , -2.4540}};
    	double[][] w3 = {{-2.5500 ,  -3.3893 ,  -3.5239 ,  -5.2636  ,  3.6292   , 6.4226}};
    	**/
    	double[][] w1 = {{-2.2076 ,  -1.2178  ,  0.0590 ,  -2.0975},
        {1.0165  , -1.3962  , -1.9381 ,   0.6863},
        {-0.4090 ,  -1.6753 ,   1.6369 ,   0.9666},
         {0.3730 ,  -1.8870 ,   0.6730 ,   1.5960},
         {1.2430 ,   1.7348 ,  -1.0034 ,  -2.0265}};
    	double[][] w2 = {{-0.5327 ,  -0.4096  ,  2.1832  ,  1.4574  , -2.6252  , -0.5355},
    		   {-0.7549  ,  1.2053  ,  1.9769 ,   1.6263 ,  -2.2536  , -0.9667},
    		   { 1.9947 ,   0.4658  , -0.5554 ,   3.2372 ,  -2.6993  , -0.3998},
    		   {-0.6772 ,  0.3370  ,  1.2786 ,   2.0075 ,  -2.5584  , -0.5160},
    		   {-0.0392 ,   1.3034   , 2.1858 ,  -0.1886 ,  -1.8885  , -0.6332}};
    	double[][] w3 = {{3.4588 ,   1.7783 ,   0.1612 ,   1.4833  , -1.5121 ,  -1.9684}};
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    

    public double[] multiplyVectorWithOne(double[][] a, double[] b)
    {
    	// required that a[0].length == b.length + 1
    	double[] c = new double[a.length];
    	for (int i = 0; i < a.length; i++)
    	{
    		c[i] = 0;
    		for (int k = 0; k < a[0].length; k++)
    		{
    			if (k != a[0].length - 1)
    				c[i] += a[i][k] * b[k];
    			else
    				c[i] += a[i][k] * 1;
    		}
    	}
    	return c;
    }
    public double[][] multiplyMatrices(double[][] a, double[][] b)
    {
    	// required that a[0].length == b.length
    	double[][] c = new double[a.length][b[0].length];
    	for (int i = 0; i < a.length; i++)
    		for (int j = 0; j < b[0].length; j++)
    		{
    			c[i][j] = 0;
    			for (int k = 0; k < a[0].length; k++)
    				 c[i][j] += a[i][k] * b[k][j];
    		}
    	return c;
    }
    public double[] sigmoidM(double[] input)
    {
    	double[] d = new double[input.length];
    	for (int i = 0; i < input.length; i++)
    		d[i] = sigmoid(input[i]);
    	return d;
    }
    public double sigmoid(double input)
    {
    	return 1 / (1 + Math.exp(-1 * input));
    }

    // Called when a 'configuration' changes
    @Override
    public final void onConfigurationChanged(final Configuration newConfig) {
        System.out.println("sensors onConfigurationChanged");
        super.onConfigurationChanged(newConfig);
    }

    
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    	Log.d(tag,"onAccuracyChanged: " + sensor + ", accuracy: " + accuracy);
    }
    @Override
    protected void onResume() {
        super.onResume();
      // register this class as a listener for the orientation and accelerometer sensors
        sm.registerListener(this, 
        		sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_FASTEST/*SensorManager.SENSOR_DELAY_UI*/);
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

    	sm.unregisterListener(this);
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
