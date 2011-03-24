package com.julian.apps.Sensors;

import java.io.IOException;
import java.util.Vector;

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
    private static final float MAX_ACCEL = 20;

    /**
     * Rate at which sensor listens.
     */
    private static int sensorRate = SensorManager.SENSOR_DELAY_FASTEST;

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
                    Sensors.this.IOButton.setEnabled(true);
                } else {
                    System.out.println("recording file "
                        + Sensors.this.mService.getFilename());
                    Sensors.this.IOButton.setText("Stop Recording "
                        + Sensors.this.mService.getFilename());
                    Sensors.this.IOButton.setEnabled(true);
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
        this.viewData.postInvalidate();
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
            display.getHeight() * 7 / 10);

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
