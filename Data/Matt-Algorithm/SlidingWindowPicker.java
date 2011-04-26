/**
 * 
 */
package edu.caltech.android.picking;

import java.util.Vector;

import edu.caltech.android.gaussianMixture.MathLib;
import edu.caltech.android.sensor.accel.AccelSample;

/**
 * Represents a Picker which uses sliding windows in making its picking
 * decisions, which are returned as the maximum accelerations within the time
 * window.
 */
abstract class SlidingWindowPicker  {
	@SuppressWarnings("unused")
	private static final String TAG = "SlidingWindowPicker";
	private static final long serialVersionUID = 1L;

	// Sliding window which this SlidingWindowPicker uses.
	protected SlidingWindow slide;

	// Short-term window size.
	private double shortTermWindowSize;

	// Whether to use long-term features or not.
	protected boolean longTermFeatures;

	/**
	 * Size of long-term window (does not include short-term window size), in
	 * seconds.
	 */
	private double longTermWindowSize;

	// Number of checks for picks made so far.
	protected int numPickChecks;

	// Number of picks made so far.
	protected int numPicks;


	/**
	 * Default constructor. This only exists so that calls to super() work, and
	 * should never be explicitly called.
	 * 
	 * Is this needed? -Matt
	 */
	protected SlidingWindowPicker() {
		this.slide = new SlidingWindow(0, 0);
		this.shortTermWindowSize = 0;
		this.longTermWindowSize = 0;
		this.longTermFeatures = false;
	}


	/**
	 * Constructor given all values.
	 * 
	 * @param inWindowSize
	 *            Duration of the sliding window (Seconds).
	 * @param inWindowInterval
	 *            Interval between start times of adjacent windows (Seconds).
	 * @param inWaitingTime
	 *            Waiting time between picks (Seconds).
	 */
	public SlidingWindowPicker(final double inWindowSize,
			final double inWindowInterval, final double inWaitingTime) {
		this.slide = new SlidingWindow(inWindowSize, inWindowInterval,
				inWaitingTime);
		this.longTermFeatures = false;
		this.shortTermWindowSize = inWindowSize;
		this.longTermWindowSize = 0;
	}

	/**
	 * Gives this SlidingWindorPicker a new measurement and returns some sort of
	 * message in the form of a Pick if there is a pick.
	 * 
	 * @param m
	 *            The new measurement to add.
	 * @return null if there is no pick, a Pick with the maximum acceleration
	 *         values for the current time window otherwise.
	 */
	public final synchronized Pick addData(final AccelSample m) {
		// this.numData++;
		// if ( true) {
		// System.out.println("Got data");
		// System.out.println("Waiting time: " + this.slide.getWaitingTime());
		// System.out.println("Window interval: " +
		// this.slide.getWindowInterval());
		// System.out.println("Short Window size: " + this.shortTermWindowSize);
		// System.out.println("Long Window size: " + this.longTermWindowSize);
		// System.out.println("Last pick time: " + this.getLastPickTime());
		// System.out.println("Current window start: " +
		// this.slide.getCurrentWindowStart());
		// }
		// Update measurements.
		this.slide.addData(m);

		// Pick to return
		Pick returned = null;

		final boolean inNewWindow = this.slide.inNewWindow();

		//  a full window of data has been collected.
		if (inNewWindow) {
			boolean pickDetected = false;
			
			boolean largeInterval = this.slide.largeInterval();
			if (largeInterval) {
				// skip this window of data if it contains samples that are
				// excessively far apart in time
			} else {
				// now, check whether enough time has
				// elapsed since the last pick in order to check for a new pick.
				boolean timeElapsed = this.slide.waitedEnough();
				if (timeElapsed) {
					// It matters where this increment is placed for the
					// purposes of normalization.
					this.numPickChecks++;
					pickDetected = this.pick();
				}
				if (pickDetected) {
					// Get maximum values for this time window
					this.numPicks++;
					returned = this.maxAccels();
				}
			}
			// Remove old measurements and update time windows
			this.slide.update(pickDetected);
		}
		return returned;
	}

	/**
	 * Gets the maximum acceleration values for the most recent time window.
	 * PRECONDITION: pick returned true.
	 * 
	 * @return A Pick with the max acceleration values in it.
	 */
	private Pick maxAccels() {
		// Get all but the most recent measurement
		final Vector<AccelSample> inWindow = this.slide.getMeasurements();
		inWindow.remove(inWindow.size() - 1);

		// Get max magnitude measurement
		final AccelSample max = MathLib.maxMag(inWindow);

		return new Pick(max.x, max.y, max.z, max.t);
	}

	/**
	 * Determines whether to declare a pick or not, given that the most recent
	 * measurement fell in a new time window. This method should not consider
	 * the most recent measurement in its picking decision.
	 * 
	 * @return Whether to declare a pick or not.
	 */
	abstract boolean pick();

	/**
	 * Gets the time of the last pick, in seconds.
	 * 
	 * @return The time of the last pick, in seconds.
	 */
	public final double getLastPickTime() {
		return this.slide.getLastEventTime();
	}

	/**
	 * Gets the short-term window size.
	 * 
	 * @return The short-term window size.
	 */
	public final double getShortTermWindowSize() {
		return this.shortTermWindowSize;
	}

	/**
	 * Sets the waiting time.
	 * 
	 * @param newWaitingTime
	 *            The new waiting time for this Picker.
	 */
	public final void setWaitingTime(final double newWaitingTime) {
		this.slide.setWaitingTime(newWaitingTime);
	}

	/**
	 * Sets the window size.
	 * 
	 * @param newSize
	 *            New sliding window size.
	 */
	public final void setWindowSize(final double newSize) {
		this.shortTermWindowSize = newSize;
		if (this.longTermFeatures) {
			this.slide.setWindowSize(this.shortTermWindowSize
					+ this.longTermWindowSize);
		} else {
			this.slide.setWindowSize(this.shortTermWindowSize);
		}
	}

	/**
	 * Sets the long-term window size.
	 * 
	 * @param newSize
	 *            New sliding window size.
	 */
	public final void setLongTermWindowSize(final double newSize) {
		this.longTermWindowSize = newSize;
		if (this.longTermFeatures) {
			this.slide.setWindowSize(this.shortTermWindowSize
					+ this.longTermWindowSize);
		}
	}

	/**
	 * Sets the window interval.
	 * 
	 * @param newInterval
	 *            New sliding window interval.
	 */
	public final void setWindowInterval(final double newInterval) {
		this.slide.setWindowInterval(newInterval);
	}

	/**
	 * Sets whether to use long-term features or not.
	 * 
	 * @param use
	 *            Whether to use long-term features or not.
	 */
	public final void setUseLongTermFeatures(final boolean use) {
		this.longTermFeatures = use;
		if (this.longTermFeatures) {
			this.slide.setWindowSize(this.shortTermWindowSize
					+ this.longTermWindowSize);
		} else {
			this.slide.setWindowSize(this.shortTermWindowSize);
		}
	}

	/**
	 * Gets the short-term measurements. If long-term features are not used,
	 * this is the same thing as getting the measurements.
	 * 
	 * @return Copy of the stored short-term measurements.
	 */
	public final Vector<AccelSample> getShortTermMeasurements() {
		if (!this.longTermFeatures) {
			return this.slide.getMeasurements();
		} else {
			// Need to find boundary of short-term and long-term measurements.
			// Since we don't have access to the actual window start, just
			// assume that the most recent measurement falls at the end of the
			// window.
			// Binary search
			Vector<AccelSample> measurements = this.slide.getMeasurements();
			
			// TODO: should avoid using nanoseconds
			final double targetTime = PickerUtils.millisToSeconds(measurements
					.lastElement().t)
					- this.shortTermWindowSize;
			
			
			final int index = this.vectorBinarySearch(measurements, targetTime);
			// TODO: Use Lists and subList instead of this made-up stuff
			return MathLib.vectorSubVec(measurements, index, measurements
					.size());
		}
	}

	/**
	 * Gets the long-term measurements. If long-term features are not used, an
	 * empty vector is returned.
	 * 
	 * @return Copy of the stored long-term measurements.
	 */
	public final Vector<AccelSample> getLongTermMeasurements() {
		if (!this.longTermFeatures) {
			return new Vector<AccelSample>();
		} else {
			// Need to find boundary of short-term and long-term measurements.
			// Since we don't have access to the actual window start, just
			// assume that the most recent measurement falls at the end of the
			// window.
			// Binary search
			Vector<AccelSample> measurements = this.slide.getMeasurements();
			final double targetTime = PickerUtils.millisToSeconds(measurements
					.lastElement().t)
					- this.shortTermWindowSize;
			final int index = this.vectorBinarySearch(measurements, targetTime);
			// TODO: Use Lists and subList instead of this made-up stuff
			return MathLib.vectorSubVec(measurements, 0, index);
		}
	}

	/**
	 * Returns the index of the first measurement to fall _after_ the desired
	 * time.
	 * 
	 * @param measurements
	 *            Measurements to do a binary search on.
	 * @param targetTime
	 *            Target time, in seconds.
	 * @return Index of the first measurement to fall after the desired time. If
	 *         the given measurements are empty, -1 is returned. If all of the
	 *         measurements occur too early, the index of the last measurement
	 *         is returned. If all of the measurements occur too late, the index
	 *         of the first measurement is returned.
	 */
	private int vectorBinarySearch(final Vector<AccelSample> measurements,
			final double targetTime) {
		int lower = 0;
		int upper = measurements.size() - 1;
		// Special case with 0 or 1 measurements
		if (upper == 0 || upper == 1) {
			return upper;
		}
		// All measurements are too late
		if (PickerUtils.millisToSeconds(measurements.get(lower).t) > targetTime) {
			return lower;
		}
		// All measurements are too early
		if (PickerUtils.millisToSeconds(measurements.get(upper).t) < targetTime) {
			return upper;
		}
		// Otherwise, binary search
		while (lower != upper - 1) {
			int middle = (lower + upper) / 2;
			double middleTime = PickerUtils.millisToSeconds(measurements
					.get(middle).t);
			if (middleTime > targetTime) {
				upper = middle;
			} else {
				lower = middle;
			}
		}
		// Now lower == upper - 1.
		return upper;
	}

}
