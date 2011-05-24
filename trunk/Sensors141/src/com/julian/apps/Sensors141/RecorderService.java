package com.julian.apps.Sensors141;

import java.io.IOException;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.concurrent.locks.ReentrantLock;

import com.julian.apps.Sensors141.IRecorder;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;
import android.os.SystemClock;

/**
 * @author jrthemaster
 * This service implements all saving and loading of the sensor data as
 * a service, so that a UI is only needed for stopping/starting the recording.
 */
public class RecorderService extends Service {

    /**
     * SensorManager to handle the accelerometers.
     */
    private SensorManager mSensorManager;

    /**
     * Logfile writer for debugging.
     */
    private OutputWriter logFile;

    /**
     * Name of file to write to, if writing to a file at all.
     */
    private String filename;

    /**
     * Whether this Service is currently writing to file.
     */
    private boolean toFile;

    /**
     * The OutputWriter for the record file if this service is recording.
     */
    private OutputWriter writer;

    /**
     *  WakeLock used to keep the CPU from going to sleep.
     */
    private PowerManager.WakeLock wl;

    /**
     * Number of measurements so far.
     */
    private int numMeasurements;

    /**
     * Stores filename persistently.
     */
    private SharedPreferences sharedPref;

    /**
     * Flag for whether this service has loaded its saved data.
     */
    private boolean ready = false;

    /**
     * Flag for whether to sleep on ACTION_SCREEN_OFF, which is the workaround
     * for accelerometers turning off when the screen goes off.  This flag
     * depends on the SDK version and is determined on startup.
     */
    private boolean doScreenOffSleep;


    // Objects needed to boost the priority of this service
    private static final Class[] mStartForegroundSignature =
        new Class[] {int.class, Notification.class};
    private static final Class[] mStopForegroundSignature =
        new Class[] {boolean.class};
    private NotificationManager mNM;
    private Method mStartForeground;
    private Method mStopForeground;
    private Object[] mStartForegroundArgs = new Object[2];
    private Object[] mStopForegroundArgs = new Object[1];

    /**
     * This is a wrapper around the new startForeground method, using the older
     * APIs if it is not available.
     */
    private void startForegroundCompat(int id, Notification notification) {
        System.out.println("begin startForegroundCompat");
        // If we have the new startForeground API, then use it.
        if (mStartForeground != null) {
            mStartForegroundArgs[0] = Integer.valueOf(id);
            mStartForegroundArgs[1] = notification;
            try {
                mStartForeground.invoke(this, mStartForegroundArgs);
                System.out.println("Using new API");
            } catch (InvocationTargetException e) {
                // Should not happen.
                System.out.println("Unable to invoke startForeground");
            } catch (IllegalAccessException e) {
                // Should not happen.
                System.out.println("Unable to invoke startForeground");
            }
            return;
        }
        System.out.println("Using old API");
        // Fall back on the old API.
        setForeground(true);
        mNM.notify(id, notification);
    }

    /**
     * This is a wrapper around the new stopForeground method, using the older
     * APIs if it is not available.
     */
    private void stopForegroundCompat(int id) {
        // If we have the new stopForeground API, then use it.
        if (mStopForeground != null) {
            mStopForegroundArgs[0] = Boolean.TRUE;
            try {
                mStopForeground.invoke(this, mStopForegroundArgs);
            } catch (InvocationTargetException e) {
                // Should not happen.
                System.out.println("Unable to invoke stopForeground");
            } catch (IllegalAccessException e) {
                // Should not happen.
                System.out.println("Unable to invoke stopForeground");
            }
            return;
        }
        // Fall back on the old API.  Note to cancel BEFORE changing the
        // foreground state, since we could be killed at that point.
        mNM.cancel(id);
        setForeground(false);
    }

    /**
     *  The listener that gets recordings from the accelerometer.
     */
    private final SensorEventListener mSensorListener =
        new SensorEventListener() {

        // When the accuracy of the sensor has changed, there's not much we can
        // do, but this method is required.
        public void onAccuracyChanged(final Sensor sensor, final int accuracy) {
        }

        // Get a new measurement
        public void onSensorChanged(final SensorEvent se) {
            final float x = se.values[0];
            final float y = se.values[1];
            final float z = se.values[2];
            final long t = se.timestamp;
            try {
                // Write the measurement to file
                RecorderService.this.addMeasurement(x, y, z, t);
            } catch (final IOException e) {
                // If adding a measurement fails, something is wrong, so stop
                // recording
                e.printStackTrace();
                RecorderService.this.toFile = false;
                RecorderService.this.writer = null;
            }
        }
    };

    /**
     *  BroadcastReceiver for handling ACTION_SCREEN_OFF.
     */
    private final BroadcastReceiver mReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(final Context context, final Intent intent) {
            // Check action just to be on the safe side.
            if (intent.getAction().equals(Intent.ACTION_SCREEN_OFF)) {
                try {
                    RecorderService.this.logFile.write("Getting screen off"
                        + "message\n");
                    RecorderService.this.logFile.flush();
                } catch (final IOException e) {
                    System.exit(1);
                }

                System.out.println("Screen turned off");
                if (RecorderService.this.toFile) {
                    // If the phone this is running on is of a particular SDK,
                    // sleep, which triggers a timeout and lets the
                    // accelerometers respond again.
                    if (RecorderService.this.doScreenOffSleep) {
                        SystemClock.sleep(20000);
                    }
                    // Unregisters the listener and registers it again.
                    RecorderService.this.mSensorManager.unregisterListener(
                        RecorderService.this.mSensorListener);
                    RecorderService.this.mSensorManager.registerListener(
                        RecorderService.this.mSensorListener,
                        RecorderService.this.mSensorManager.getDefaultSensor(
                            Sensor.TYPE_ACCELEROMETER),
                            SensorManager.SENSOR_DELAY_NORMAL);
                    System.out.println("Accelerometers should be on");
                }
            }
        }
    };


    /**
     * Implement all of the recorder interface in an anonymous class so that
     * Sensors can interface with this process.
     */
    private final IRecorder.Stub mBinder = new IRecorder.Stub() {

        public String getFilename() {
            return RecorderService.this.filename;
        }

        public boolean isRecording() {
            return RecorderService.this.toFile;
        }

        public boolean isReady() {
            return RecorderService.this.ready;
        }

        public void startRecording(final String inFilename) {
            System.out.println("startRecording");
            try {
                RecorderService.this.startOutputWriter(inFilename);
            } catch (final IOException e) {
                System.exit(1);
            }
        }

        public void stopRecording() {
            System.out.println("stopRecording");
            try {
                RecorderService.this.stopOutputWriter();
            } catch (final IOException e) {
                System.exit(1);
            }
        }
    };

    /**
     * Called whenever a measurement was received from the sensor.
     * @param x Acceleration in x direction
     * @param y Acceleration in y direction
     * @param z Acceleration in z direction
     * @param t Time in nanoseconds
     * @throws IOException When the logfile fails to write.
     */
    final void addMeasurement(final float x, final float y, final float z,
        final long t) throws IOException {
        this.numMeasurements++;
        if ((this.numMeasurements & 127) == 0) {
            System.out.println("Recording to " + this.filename);
        }

        // Write to file, if necessary
        if (this.writer != null) {
            try {
                this.writer.write("" + x + " " + y + " " + z + " " + t + "\n");
                if (this.doScreenOffSleep) {
                    this.writer.flush();
                }
            } catch (final IOException e) {
                this.logFile.write("Error in Writing Measurement: "
                    + e.getMessage());
            }
        }
    }


    @Override
    // Called when the activity wants to interface with this service
    public final IBinder onBind(final Intent intent) {
        return this.mBinder;
    }


    // Called when the service is first created
    // Everything to set up recording has to be done
    @Override
    public final void onCreate() {
        System.out.println("service onCreate");
        // Open up a log file for debugging purposes
        try {
            this.logFile = new OutputWriter("RecorderLog.log");
        } catch (final IOException e) {
            // Can't do anything
            e.printStackTrace();
        }
        try {
            this.logFile.write("Created Recorder Service\n");
            this.logFile.flush();
        } catch (final IOException e) {
            e.printStackTrace();
        }

        // Stuff to keep in background
        mNM = (NotificationManager) getSystemService(NOTIFICATION_SERVICE);
        try {
            mStartForeground = getClass().getMethod("startForeground",
                    mStartForegroundSignature);
            mStopForeground = getClass().getMethod("stopForeground",
                    mStopForegroundSignature);
        } catch (NoSuchMethodException e) {
            // Running on an older platform.
            mStartForeground = null;
            mStopForeground = null;
        }

        // Based on the SDK version, we may need to do a workaround when the
        // screen turns off in order to keep listening to the accelerometers.
        // SDK versions 2.0, 2.0.1, and 2.1 appear to be or are expected to
        // be bad.  These are all ECLAIR SDKs.  This also determines whether
        // to flush after each measurement, which is only necessary for the
        // SDKs that need an ACTION_SCREEN_OFF BroadcastReceiver.
        final int sdkVersion = Integer.parseInt(Build.VERSION.SDK);
        this.doScreenOffSleep = false;
        if (sdkVersion == Build.VERSION_CODES.ECLAIR
            || sdkVersion == Build.VERSION_CODES.ECLAIR_0_1
            || sdkVersion == Build.VERSION_CODES.ECLAIR_MR1) {
            this.doScreenOffSleep = true;
        }


        // We aren't logging to file until we are told to start
        this.writer = null;
        this.toFile = false;
        // Start up the sensor manager
        this.mSensorManager = (SensorManager)
            this.getSystemService(Context.SENSOR_SERVICE);

        // Set of SharedPreferences for filename reading.
        this.sharedPref = getSharedPreferences("RecorderService",
            Context.MODE_PRIVATE);
        this.filename = this.sharedPref.getString("filename", null);
        // Start recording if the saved filename is valid.
        if (this.filename != null && this.filename.compareTo("") != 0) {
            try {
                this.startOutputWriter(this.filename);
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
        this.ready = true;

        // Acquire a wakelock to try to get the CPU from not going to sleep
        final PowerManager pm = (PowerManager)
        this.getSystemService(Context.POWER_SERVICE);
        this.wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK,
            "RecorderService");
        if (this.wl == null) {
            try {
                this.logFile.write("wl is null!!!!!\n");
                this.logFile.flush();
            } catch (final IOException e) {
                System.exit(1);
            }
        } else {
            try {
                this.logFile.write("wl is created " + this.wl + "\n");
                this.logFile.flush();
            } catch (final IOException e) {
                System.exit(1);
            }
        }
        // Get the lock
        this.wl.acquire();

        this.numMeasurements = 0;

        // Debug logging
        try {
            this.logFile.write("wl is acquired? \n");
            this.logFile.flush();
        } catch (final IOException e) {
            System.exit(1);
        }

        // Register our receiver for the ACTION_SCREEN_OFF action. This will
        // make our receiver code be called whenever the phone enters standby
        // mode.
        final IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_OFF);
        this.registerReceiver(this.mReceiver, filter);
    }


    // Called when the service is destroyed. This hopefully shouldn't be called
    // by the OS except in rare circumstances when it is under a lot of stress
    // or out of batteries.
    @Override
    public final void onDestroy() {
        System.out.println("service onDestroy");

        // Release the wakelock
        this.wl.release();

        // Unregister ACTION_SCREEN_OFF BroadcastReceiver
        this.unregisterReceiver(mReceiver);

        // Log destruction of service
        try {
            this.logFile.write("Recorder Service Being Destroyed\n");
            this.logFile.flush();
            this.logFile.close();
        } catch (final IOException e) {
            e.printStackTrace();
        }

        // Stop writing to file
        if (this.toFile) {
            try {
                this.stopOutputWriter();
            } catch (final IOException e) {
                System.exit(1);
            }
        }
    }


    /**
     *  Makes this service start writing to file.
     *  @param inFilename The name of the file to which this writer shall write.
     *  @throws IOException When the logfile can't write
     */
    private void startOutputWriter(final String inFilename) throws IOException {
        // Make a new OutputWriter and log this to the log file
        try {
            this.writer = new OutputWriter(inFilename);
            this.filename = inFilename;
            this.toFile = true;
            // Store new filename
            SharedPreferences.Editor e = this.sharedPref.edit();
            e.putString("filename", inFilename);
            e.commit();
            System.out.println("Service set filename " + this.filename);

        } catch (final Exception e) {
            this.logFile.write("Caught exception " + e);
            this.logFile.flush();
        }
        this.logFile.write("Started Recording " + this.filename + "\n");
        this.logFile.flush();

        // Listen to sensors
        this.mSensorManager.registerListener(this.mSensorListener,
            this.mSensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
            SensorManager.SENSOR_DELAY_FASTEST);

        // Make a Notification to alert the user that this will be running in
        // the background.
        // TODO: Make this on the status bar.
        Notification note = new Notification();
        note.ledARGB = 0xff0000ff;
        note.ledOnMS = 2000;
        note.ledOffMS = 1000;
        note.flags |= Notification.FLAG_SHOW_LIGHTS;
        this.startForegroundCompat(0, note);
    }

    /**
     *  Makes this service stop writing to file.
     *  @throws IOException When the logfile can't write.
     */
    private void stopOutputWriter() throws IOException {
        // Log to file and close the writer
        this.logFile.write("Got to Stop Writer \n");
        this.logFile.flush();

        this.writer.flush();
        this.writer.close();

        // Stop listening to sensors
        this.mSensorManager.unregisterListener(this.mSensorListener);

        this.toFile = false;
        this.writer = null;
        this.filename = "";

        // Store empty filename
        SharedPreferences.Editor e = this.sharedPref.edit();
        e.putString("filename", "");
        e.commit();

        // Remove from foreground
        this.stopForegroundCompat(0);

        this.logFile.write("Stopped Recording " + this.filename + "\n");
        this.logFile.flush();
    }
}
