package com.julian.apps.Sensors141;

import java.io.IOException;
import java.util.Vector;

import com.julian.apps.Sensors141.IRecorder;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.res.Configuration;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.RemoteException;
import android.os.SystemClock;
import android.view.Display;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;

/**
 *  The Sensors Activity is the main activity that is run.  It displays the
 *  accelerometer data as three time series graphs, updated as new observations
 *  come in, and also has a button to start recording.
 */
public class Sensors extends Activity {

    /**
     * Click listener is for the button that is the primary stop/start
     * interface for the user.
     */
    private class ClickListener implements OnClickListener {
        /**
         * Activity this ClickListener is in.
         */
        private Activity c;

        /**
         * Constructor.
         * @param inC Activity this ClickListener is in.
         */
        public ClickListener(final Activity inC) {
            this.c = inC;
        }

        /**
         *  Called when the button is clicked.
         *  @param v View that has been clicked.
         */
        public void onClick(final View v) {

            // Check if the file writing is started, otherwise ask for a
            // filename and start writing
            try {
                if (!Sensors.this.mService.isRecording()) {
                    // Request filename
                    final InputBox input = new InputBox(this.c);
                    input.show();
                } else {
                    // Otherwise, the user is stopping the recording. So signal
                    // to stop the recording
                    try {
                        Sensors.this.logFile.write("Received stop click");
                        Sensors.this.logFile.flush();
                    } catch (final IOException e) {
                        System.exit(1);
                    }

                    Sensors.this.mService.stopRecording();
                    Sensors.this.IOButton.setText("Start Recording");
                }
            } catch (final RemoteException e) {
                try {
                    Sensors.this.logFile.write("Caught remote exception on "
                        + "click listener\n");
                    Sensors.this.logFile.flush();
                } catch (final IOException e1) {
                    System.exit(1);
                }

                System.exit(1);
            }
        }
    }

    /**
     * This input box is for querying a filename.
     */
    private class InputBox {
        /**
         * Alert that the box spawns.
         */
        private final AlertDialog.Builder alert;

        /**
         * Constructor.
         * @param act Activity this InputBox is in.
         */
        public InputBox(final Activity act) {
            // Unregister listeners while the InputBox is up so that entering
            // characters into the InputBox isn't slow.
            Sensors.this.unregisterListener();

            // Ask for a filename
            this.alert = new AlertDialog.Builder(act);
            this.alert.setTitle("Enter filename");
            this.alert.setMessage("Filename:");

            // Set an EditText view to get user input
            final EditText input = new EditText(act);
            this.alert.setView(input);

            // Make a listener for when the cancel button is pressed.  This has
            // the sole purpose of re-registering the accelerometer listener
            this.alert.setOnCancelListener(
                new DialogInterface.OnCancelListener() {
                    @Override
                    public void onCancel(final DialogInterface dialog) {
                        Sensors.this.registerListener();
                    }
                }
            );


            // Make the OK button, and bind it to calling onFilenameSet
            this.alert.setPositiveButton("Ok",
                new DialogInterface.OnClickListener() {
                    public void onClick(final DialogInterface dialog,
                        final int whichButton) {
                        // Pressed Ok.  Now get the filename
                        final CharSequence value = input.getText();
                        Sensors.this.onFilenameSet(value.toString());
                        // Register listener again
                        Sensors.this.registerListener();
                    }
                }
            );

            // Make the Cancel button. Do nothing in this case
            this.alert.setNegativeButton("Cancel",
                new DialogInterface.OnClickListener() {
                public void onClick(final DialogInterface dialog,
                    final int whichButton) {
                    // Register listener again
                    Sensors.this.registerListener();
                }
            });

        }

        /**
         *  Shows the InputBox.
         */
        public void show() {
            this.alert.show();
        }
    }

    /**
     *  A custom view class that implements the user interface we want.
     */
    private static class ViewData extends View {
        /**
         * Paint object for drawing things.
         */
        private final Paint mPaint = new Paint();

        /**
         *  Constructor.
         *  @param context The context that this view is for.
         */
        public ViewData(final Context context) {
            super(context);
            this.setWillNotDraw(false); // Allows for some optimizations
        }

        // Draw the interface we want
        @Override
        protected void onDraw(final Canvas canvas) {
            // Don't do anything if there's nothing to draw
            if (Sensors.measurements == null
                || Sensors.measurements.size() < 1) {
                return;
            }

            // Rectangles on-screen for x, y, z, and t recordings
            RectF xR, yR, zR, tR;

            final Paint paint = this.mPaint;
            canvas.drawColor(Color.BLACK); // Background color
            paint.setStrokeWidth(2);

            // Parameters of the view
            final int height = this.getHeight();
            final int width = this.getWidth();
            final int border = 5;
            final int h = height / 5;
            final int w = width - 2 * border;

            // Make the rectangles
            xR = new RectF(border,         border,
                           border + w,     border +     h);
            yR = new RectF(border,     2 * border +     h,
                           border + w, 2 * border + 2 * h);
            zR = new RectF(border,     3 * border + 2 * h,
                           border + w, 3 * border + 3 * h);
            tR = new RectF(border,     4 * border + 3 * h,
                           border + w, 4 * border + 4 * h);

            int stept = (int) ((float) Sensors.MAX_POINTS / (float) w);
            stept = 1;

            // Draw the rectangles
            paint.setColor(Color.BLUE);
            canvas.drawRect(xR, paint);
            canvas.drawRect(yR, paint);
            canvas.drawRect(zR, paint);
            paint.setColor(Color.GRAY);
            canvas.drawRect(tR, paint);

            // Put labels on the plots
            paint.setColor(Color.WHITE);
            canvas.drawText("X", xR.left, xR.bottom, paint);
            canvas.drawText("Y", yR.left, yR.bottom, paint);
            canvas.drawText("Z", zR.left, zR.bottom, paint);
            canvas.drawText("Tdiff(ms)", tR.left, tR.bottom, paint);

            paint.setColor(Color.YELLOW);
            paint.setStrokeWidth(1);

            int ipos = 0;
            int oldtpos = border + w;

            Measurement m = Sensors.measurements.elementAt(ipos++);

            final float vscale = h / (2.f * Sensors.MAX_ACCEL);

            // Times are reported in nanoseconds
            final float vscalet = 0.000000001f * h;

            int oldx =     border +      h / 2  - (int) (m.x * vscale);
            int oldy = 2 * border + (3 * h / 2) - (int) (m.y * vscale);
            int oldz = 3 * border + (5 * h / 2) - (int) (m.z * vscale);
            int oldt = 4 * border + (8 * h / 2) - (int) (m.t * vscalet);

            // Apply string formatting so that these values take up a
            // fixed amount of space
            final String text = String.format("X=%1$4.6f Y=%2$4.6f Z=%3$4.6f"
                + "(m/s^2)", m.x, m.y, m.z);
            canvas.drawText(text, border, height - 2 * border, paint);
            canvas.drawText("Tdiff = " + (Sensors.tdiff / 1000000) + "ms = "
                + (1000000000.f/Sensors.tdiff) + "Hz",
                width * 6 / 10, height - 2 * border, paint);

            paint.setColor(Color.GREEN);

            // Draw the line-graphs segment-by-segment
            while (ipos < Sensors.measurements.size() && oldtpos > border) {
                m = Sensors.measurements.elementAt(ipos);
                final int x =     border +      h / 2  - (int) (m.x * vscale);
                final int y = 2 * border + (3 * h / 2) - (int) (m.y * vscale);
                final int z = 3 * border + (5 * h / 2) - (int) (m.z * vscale);
                int t = 4 * border + (8 * h / 2) - (int) (m.t * vscalet);
                if (t < tR.top) {
                    t = (int) tR.top;
                }
                final int tpos = oldtpos - 1;
                canvas.drawLine(oldtpos, oldx, tpos, x, paint);
                canvas.drawLine(oldtpos, oldy, tpos, y, paint);
                canvas.drawLine(oldtpos, oldz, tpos, z, paint);
                canvas.drawLine(oldtpos, oldt, tpos, t, paint);

                oldx = x;
                oldy = y;
                oldz = z;
                oldt = t;
                oldtpos = tpos;

                ipos += stept;
            }
        }
    }

    // Fields
    /**
     * The view so that we can see the plots.
     */
    private ViewData viewData;

    /**
     * Lets us listen to sensors.
     */
    private SensorManager mSensorManager;

    // Parameters of the plots
    /**
     * Maximum number of points to plot.
     */
    private static final int MAX_POINTS = 1000;

    /**
     * Maximum acceleration.
     */
    private static final float MAX_ACCEL = 40;

    /**
     * Rate at which sensor listens.
     */
    private static int sensorRate = SensorManager.SENSOR_DELAY_FASTEST;

    
    private static TextView classification;
    
    // Variables used during recording and needed between function calls

    /**
     * Time of first SensorEvent.
     */
    private static long t0;

    /**
     * Time of more recent SensorEvent.
     */
    private static long lastt = 0;

    /**
     * Time difference between measurements.
     */
    private static long tdiff;

    /**
     * Measurements that are being plotted.
     */
    private static Vector<Measurement> measurements;

    /**
     *  Recording button.
     */
    private Button IOButton;

    /**
     *  Interface to recording service.
     */
    private IRecorder mService;

    /**
     *  Debug log file.
     */
    private OutputWriter logFile;

    /**
     * Listener for the accelerometer.
     */
    private final SensorEventListener mSensorListener =
        new SensorEventListener() {

        // Required function.
        public void onAccuracyChanged(final Sensor sensor, final int accuracy) {
        }

        // Called when we get a new value
        public void onSensorChanged(final SensorEvent se) {
            // Add the measurement
            final float x = se.values[0];
            final float y = se.values[1];
            final float z = se.values[2];
            final long t = se.timestamp;
            Sensors.this.addMeasurement(x, y, z, t);
        }
    };

    /**
     *  Sets up the interface between this activity and the recorder
     *  service.
     */
    private final ServiceConnection mConnection = new ServiceConnection() {

        // Called when we connect to the RecorderService
        public void onServiceConnected(final ComponentName className,
            final IBinder service) {
            System.out.println("sensors onServiceConnected"); 
            // Retrieve and store the interface for use throughout
            Sensors.this.mService = IRecorder.Stub.asInterface(service);
            try {
                Sensors.this.logFile.write("Connected to service\n");
                Sensors.this.logFile.flush();
            } catch (final IOException e1) {
                System.exit(1);
            }


            if (Sensors.this.mService == null) {
                try {
                    Sensors.this.logFile.write("mService is null\n");
                    Sensors.this.logFile.flush();
                } catch (final IOException e) {
                    System.exit(1);
                }
            }

            // Set initial button state depending on whether the service is
            // currently recording.
            try {
                while (!Sensors.this.mService.isReady()) {
                    SystemClock.sleep(1000);
                }
                System.out.println("Service is ready, filename "
                    + Sensors.this.mService.getFilename());
                if (!Sensors.this.mService.isRecording()) {
                    System.out.println("Not recording");
                    Sensors.this.IOButton.setText("Start Recording");
                    //Sensors.this.IOButton.setEnabled(true);
                } else {
                    System.out.println("recording file "
                        + Sensors.this.mService.getFilename());
                    Sensors.this.IOButton.setText("Stop Recording "
                        + Sensors.this.mService.getFilename());
                    //Sensors.this.IOButton.setEnabled(true);
                }
            } catch (final RemoteException e) {
                try {
                    Sensors.this.logFile.write("Caught Remote exception at "
                        + "service connection\n");
                    Sensors.this.logFile.flush();
                } catch (final IOException e1) {
                    System.exit(1);
                }

                System.exit(1);
            }
        }

        // Called when we disconnect from the RecorderService
        public void onServiceDisconnected(final ComponentName className) {
            System.out.println("sensors onServiceDisconnected");
            Sensors.this.mService = null;

            try {
                Sensors.this.logFile.write("Disconnected from service\n");
                Sensors.this.logFile.flush();
            } catch (final IOException e) {
                System.exit(1);
            }
        }
    };

    /**
     *  Adds a measurement.
     *  @param x Acceleration in the x direction
     *  @param y Acceleration in the y direction
     *  @param z Acceleration in the z direction
     *  @param t Time of Measurement, in nanoseconds.
     */
    private void addMeasurement(final float x, final float y, final float z,
        final long t) {
        Sensors.tdiff = t - Sensors.lastt;
        // Check if this was the first measurement
        if (Sensors.t0 == 0) {
            Sensors.t0 = t;
            Sensors.tdiff = 0;
        }
        Sensors.lastt = t;

        // Add measurements to the Vector of Measurements and truncate if we
        // have too many.
        Sensors.measurements.insertElementAt(
            new Measurement(x, y, z, Sensors.tdiff), 0);
        if (Sensors.measurements.size() > Sensors.MAX_POINTS) {
            Sensors.measurements.setSize(Sensors.MAX_POINTS);
        }

    	int LENGTH = 512;
        if (Sensors.measurements.size() >= LENGTH && Math.random() < .04)
        {
        	Complex[] c = new Complex[LENGTH];
        	for (int i = 0; i < LENGTH; i++)
        	{
        		Measurement m = Sensors.measurements.get(i);
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
        	
        	double w = (resultWvI + resultWvR + resultWvB) / 3;
        	double r = (resultRvI + (1 - resultWvR) + resultRvB) / 3;
        	double i = (2 - resultWvI - resultRvI + resultIvB) / 3;
        	double b = (3 - resultWvB - resultRvB - resultIvB) / 3;
        	
        	if (i > r && i > w && i > b)
        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Idling " + i);
        	else if (r > i && r > w && r > b)
        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Running " + r);
        	else if (w > i && w > r && w > b)
        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Walking " + w);
        	else
        		classification.setText(/*meanF + " " + stdF + " " + energyF + */"Activity: Biking " + b);
        	
        	
        }
        this.viewData.postInvalidate();
    }
    
    public double walkingVsIdling(double[] red)
    {
    	// For walking vs idling {1, 3, x} with x between 1 and 3.
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
    	
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
    						sigmoidM(multiplyVectorWithOne(w2,
    						sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double walkingVsRunning(double[] red)
    {
    	// For walking vs idling {1, 3, x} with x between 1 and 3.
    	double[][] w1 = {{-0.4470,    1.7171,   -0.9534  ,  0.7626},
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
    	double[][] w3 = {{-0.3862  , -8.2719,   -2.5574 ,  -0.1003 ,  -6.2207,    5.1501}};
    	
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
    						sigmoidM(multiplyVectorWithOne(w2,
    						sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double walkingVsBiking(double[] red)
    {
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
    	
    	return result[0];
    }
    
    public double runningVsIdling(double[] red)
    {
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
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double runningVsBiking(double[] red)
    {
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
    	
    	double[] result = sigmoidM(multiplyVectorWithOne(w3,
				sigmoidM(multiplyVectorWithOne(w2,
				sigmoidM(multiplyVectorWithOne(w1, red))))));
    	return result[0];
    }
    public double idlingVsBiking(double[] red)
    {
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


    @Override
    protected final void onCreate(final Bundle savedInstanceState) {
        System.out.println("sensors onCreate");
        super.onCreate(savedInstanceState);

        // Set up the debug log file
        try {
            this.logFile = new OutputWriter("ActivityUI.log");
            this.logFile.write("Started activity\n");
            this.logFile.flush();
        } catch (final Exception e) {
            System.exit(1);
        }

        // Listen to sensors
        this.mSensorManager = (SensorManager)
                              this.getSystemService(Context.SENSOR_SERVICE);
        this.registerListener();

        // Vector of Measurements to keep track of received data.
        Sensors.measurements = new Vector<Measurement>(Sensors.MAX_POINTS);

        // Set up the connection to the recorder service
        final Intent intent = new Intent(this, RecorderService.class);
        if (this.startService(intent) == null) {
            try {
                this.logFile.write("Could not start service\n");
                this.logFile.flush();
            } catch (final IOException e) {
                System.exit(1);
            }
        }
        this.bindService(intent, this.mConnection, Context.BIND_AUTO_CREATE);

        // Set up the GUI
        final LinearLayout mainView = new LinearLayout(this);
        mainView.setOrientation(LinearLayout.VERTICAL);
        this.viewData = new ViewData(this);
        final Display display = this.getWindowManager().getDefaultDisplay();
        mainView.addView(this.viewData, display.getWidth(),
            display.getHeight() * 6 / 10);

        classification = new TextView(this);
        mainView.addView(classification, display.getWidth(),
                display.getHeight() * 1 / 10);
        classification.setTextSize(20);
        classification.setText("Activity: None");
        
        // Make the button
        this.IOButton = new Button(this);
        this.IOButton.setOnClickListener(new ClickListener(this));
        this.IOButton.setText("Binding to recorder...");
        this.IOButton.setEnabled(false);
        mainView.addView(this.IOButton);
        this.setContentView(mainView);

        
    }

    // Called when the activity is terminated
    @Override
    protected final void onDestroy() {
        System.out.println("sensors onDestroy");
        // Unregister the listener
        this.unregisterListener();
        super.onDestroy();

        // If we are recording, stop the recorder
        try {
            this.unbindService(this.mConnection);
            if (this.mService != null && !this.mService.isRecording()) {
                this.stopService(new Intent(this, RecorderService.class));
            }
        } catch (final RemoteException e) {
            try {
                this.logFile.write("Caught Remote exception on destroy\n");
                this.logFile.flush();
            } catch (final IOException e1) {
                System.exit(1);
            }
            System.exit(1);
        }

        // Log to file
        try {
            this.logFile.write("Destroying activity\n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }
    }


    /**
     *  Called when we set a filename in the InputBox.  Starts recording with
     *  the new filename.
     *  @param newFilename Name of the file which shall be written to.
     */
    final void onFilenameSet(final String newFilename) {
        System.out.println("sensors onFilenameSet");

        // Log debugging info
        try {
            this.logFile.write("Got new filename " + newFilename + "\n");
            this.logFile.flush();
        } catch (final IOException e1) {
            System.exit(1);
        }

        // Start recording
        try {
            this.mService.startRecording(newFilename);
            this.IOButton.setText("Stop Recording " + newFilename);
        } catch (final RemoteException e) {
            try {
                this.logFile.write("Caught remote exception on filename set\n");
                this.logFile.flush();
            } catch (final IOException e1) {
                System.exit(1);
            }
            // Auto-generated catch block
            System.exit(1);
        }
    }

    // Called whenever the activity comes into the foreground
    @Override
    protected final void onResume() {
        System.out.println("sensors onResume");
        super.onResume();

        // Register the listener
        this.registerListener();

        try {
            this.logFile.write("resumed activity\n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }
    }


    // Called when the activity is no longer visible
    @Override
    protected final void onStop() {
        System.out.println("sensors onStop");
        // Don't do anything special
        super.onStop();
        try {
            this.logFile.write("Stopped activity\n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }
    }

    /**
     * Registers a listener to the accelerometer.
     */
    private void registerListener() {
        this.mSensorManager.registerListener(this.mSensorListener,
            this.mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
            Sensors.sensorRate);
        try {
            this.logFile.write("Registered listener\n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }
    }

    /**
     * Unregisters the listener to the accelerometer.
     */
    private void unregisterListener() {
        this.mSensorManager.unregisterListener(this.mSensorListener);
        try {
            this.logFile.write("Unregistered listener\n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }
    };
}
