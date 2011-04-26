/**
 * 
 */
package edu.caltech.android.picking;

import java.util.Vector;

import edu.caltech.android.sensor.accel.AccelSample;



/**
 * Handles sliding windows of Measurements.
 * 
 * TODO: the window size, interval, etc shouldn't be mutable. If the application
 * requires a sliding window of a different size, it should instantiate one.
 * This will reduce cases leading to inconsistent state.
 */
public class SlidingWindow {

	/**
	 * Serialization ID. Increment this when a structural change to
	 * SlidingWindow is made.
	 */
	// private static final long serialVersionUID = 1L;

	/**
	 * Start of the current window, in seconds.
	 */
	private double currentWindowStart = Double.NEGATIVE_INFINITY;

	/**
	 * Measurements currently keeping track of. The Measurements being kept
	 * track of should never include more than one more Measurement than the
	 * number of Measurements in a single window.
	 */
	private Vector<AccelSample> measurements;

	/**
	 * Time of last event, where the meaning of an event is decided by whatever
	 * uses this class.
	 */
	private double lastEventTime = Double.NEGATIVE_INFINITY;

	/**
	 * Size of sliding window.
	 */
	private double windowSize;

	/**
	 * Amount of time between start of subsequent intervals.
	 */
	private double windowInterval;

	/**
	 * Time required to wait between events, in seconds.
	 */
	private double waitingTime;

	/**
	 * Constructor given everything except a waiting time between events, which
	 * is set to 0.
	 * 
	 * @param inWindowSize
	 *            Size, in seconds, of the sliding window.
	 * @param inWindowInterval
	 *            Interval, in seconds, between start times of adjacent windows.
	 */
	public SlidingWindow(final double inWindowSize,
			final double inWindowInterval) {
		this.windowSize = inWindowSize;
		this.windowInterval = inWindowInterval;
		this.waitingTime = 0;
		this.measurements = new Vector<AccelSample>();
	}

	/**
	 * Constructor given all values.
	 * 
	 * @param inWindowSize
	 *            Size, in seconds, of the sliding window.
	 * @param inWindowInterval
	 *            Interval, in seconds, between start times of adjacent windows.
	 * @param inWaitingTime
	 *            Waiting time between events.
	 */
	public SlidingWindow(final double inWindowSize,
			final double inWindowInterval, final double inWaitingTime) {
		this.windowSize = inWindowSize;
		this.windowInterval = inWindowInterval;
		this.waitingTime = inWaitingTime;
		this.measurements = new Vector<AccelSample>();
	}

	/**
	 * Gives this SlidingWindow a new measurement.
	 * 
	 * @param m
	 *            The new measurement to add.
	 */
	public final void addData(final AccelSample m) {
		// Since the measurements are transient, we might have to restore them.
		if (this.measurements == null) {
			this.measurements = new Vector<AccelSample>();
			this.lastEventTime = Double.NEGATIVE_INFINITY;
			this.currentWindowStart = Double.NEGATIVE_INFINITY;
		}
		this.measurements.add(m);
	}

	/**
	 * Returns whether enough time has elapsed between the most recent
	 * Measurement and the last event. Assumes that at least one measurement has
	 * been recorded.
	 * 
	 * @return Whether enough time has elapsed.
	 */
	public final boolean waitedEnough() {
		double newestTime = PickerUtils.millisToSeconds(this.measurements
				.lastElement().t);
		return !(newestTime < this.lastEventTime + this.waitingTime);
	}

	/**
	 * Returns whether the most recent Measurement falls in a new window.
	 * 
	 * @return Whether the most recent Measurement falls in a new window.
	 */
	public final boolean inNewWindow() {
		double newestTime = PickerUtils.millisToSeconds(this.measurements
				.lastElement().t);
		return newestTime > this.currentWindowStart + this.windowSize;
	}

	/**
	 * Returns whether it has been a long time since the last measurement --
	 * whether the last two measurements are not in the same window.
	 * 
	 * @return Whether the the most recent two measurements are not in the same
	 *         window.
	 */
	public final boolean largeInterval() {
		boolean sameWindow = false;
		if (this.measurements.size() >= 2) {
			double newestTime = PickerUtils.millisToSeconds(this.measurements
					.lastElement().t);
			final double secondLastTime = PickerUtils
					.millisToSeconds(this.measurements.get(this.measurements
							.size() - 2).t);
			sameWindow = newestTime - secondLastTime < this.windowSize;
		}
		return !sameWindow;
	}

	/**
	 * Updates all internal data. This should only be called when the most
	 * recent measurement falls in a new sliding window.
	 * 
	 * @param event
	 *            Whether there was a new event caused by the most recent
	 *            measurement or not.
	 */
	public final void update(final boolean event) {
		// Determine whether it has been a long time since the last measurement
		boolean longTime = this.largeInterval();
		AccelSample last = this.measurements.lastElement();
		double newestTime = PickerUtils.millisToSeconds(last.t);
		if (longTime) {
			// If it has been a long time, wipe out all the measurements except
			// for the most recent one and update times.
			this.currentWindowStart = newestTime;
			this.measurements = new Vector<AccelSample>();
			this.measurements.add(last);
		} else {
			// Hasn't been a long time, so just update the event time, slide
			// the window over, and update measurements.
			if (event) {
				this.lastEventTime = newestTime;
			}
			this.currentWindowStart += this.windowInterval;
			// Check which measurements we have to remove.
			int lastRemoveIndex = -1;
			int numMeasurements = this.measurements.size();
			for (int i = 0; i < numMeasurements; i++) {
				if (PickerUtils.millisToSeconds(this.measurements.get(i).t) < currentWindowStart) {
					lastRemoveIndex = i;
				}
			}
			Vector<AccelSample> newMeasurements = new Vector<AccelSample>();
			// Remove all bad measurements, which are all at the front. Do this
			// by adding in the good measurements, because Vector.remove is
			// slow, apparently
			// Reference: http://java.sun.com/docs/books/performance/
			// 1st_edition/html/JPAlgorithms.fm.html
			for (int i = lastRemoveIndex + 1; i < numMeasurements; i++) {
				newMeasurements.add(this.measurements.get(i));
			}
			this.measurements = newMeasurements;
		}
	}

	/**
	 * Sets the waiting time.
	 * 
	 * @param newWaitingTime
	 *            The new waiting time for this SlidingWindow, in seconds.
	 */
	public final void setWaitingTime(final double newWaitingTime) {
		this.waitingTime = newWaitingTime;
	}

	/**
	 * Sets the window size.
	 * 
	 * @param newWindowSize
	 *            The new window size, in seconds.
	 */
	public final void setWindowSize(final double newWindowSize) {
		this.windowSize = newWindowSize;
	}

	/**
	 * Sets the interval between windows.
	 * 
	 * @param newWindowInterval
	 *            The new interval between windows, in seconds.
	 */
	public final void setWindowInterval(final double newWindowInterval) {
		this.windowInterval = newWindowInterval;
	}

	/**
	 * Gets the waiting time.
	 * 
	 * @return The waiting time for this SlidingWindow, in seconds.
	 */
	public final double getWaitingTime() {
		return this.waitingTime;
	}

	/**
	 * Gets the window size.
	 * 
	 * @return The window size for this SlidingWindow, in seconds.
	 */
	public final double getWindowSize() {
		return this.windowSize;
	}

	/**
	 * Gets the interval between windows.
	 * 
	 * @return The new interval between windows for this SlidingWindow, in
	 *         seconds.
	 */
	public final double getWindowInterval() {
		return this.windowInterval;
	}

	/**
	 * Gets the last event time.
	 * 
	 * @return The time of the last event
	 */
	public final double getLastEventTime() {
		return this.lastEventTime;
	}

	/**
	 * Gets the current window start.
	 * 
	 * @return The start of the current window.
	 */
	public final double getCurrentWindowStart() {
		return this.currentWindowStart;
	}

	/**
	 * Gets a (shallow) copy of the current measurements.
	 * 
	 * @return A copy of the current measurements.
	 */
	@SuppressWarnings("unchecked")
	public final Vector<AccelSample> getMeasurements() {
		return (Vector<AccelSample>) this.measurements.clone();
	}
}
