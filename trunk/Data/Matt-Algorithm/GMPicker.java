/**
 * 
 */
package edu.caltech.android.picking;

import java.util.Vector;

import Jama.Matrix;
import android.util.Log;
import edu.caltech.android.gaussianMixture.GaussianMixture;
import edu.caltech.android.gaussianMixture.MathLib;
import edu.caltech.android.sensor.accel.AccelSample;


/**
 * Applies a pre-specified Gaussian Mixture model to a feature vector. Features
 * assigned sufficiently low probability are considered "anomalies" and are
 * reported as picks.
 * 
 * TODO this class should not be responsible for gravity subtraction, or feature
 * vector computation. Refactor that functionality into new classes.
 * 
 * TODO implement online percentile estimation for adaptive threshold
 * 
 * TODO this attempts to handle both regular and short term, long term features.
 * That a bad idea. 
 * 
 */
public class GMPicker extends SlidingWindowPicker {
	private static final String TAG = "GMPicker";

	private Double parameterVersion = 1.0;

	// --------- Gravity Subtraction Parameters ----------

	/**
	 * Gravity is calculated as a rolling average, and this parameter tells how
	 * much of gravity is determined by the gravity vector (average) of the
	 * current set of measurements. Should be in [0,1] with 1 the most fresh.
	 */
	private double gravityFreshness;

	/**
	 * Gravity vector. Should be a 3 by 1 Matrix.
	 */
	private Matrix gravity;

	// --------- GMM Anomaly Parameters -------------------

	/**
	 * Mixture model of "normal" data
	 */
	private GaussianMixture gm;

	/**
	 * Probability below which things count as a pick.
	 */
	private double thresholdProb;

	/**
	 * true if the threshold should be updated as time goes on
	 */
	private boolean updateThreshold;

	/**
	 * target rate of picks (fraction of runs of picking algorithm that yield
	 * picks)
	 */
	private double desiredPickFrequency;

	/**
	 * log likelihood of last feature vector. For debugging.
	 */
	private double llh;

	// --------- Feature vector Parameters ---------------

	/**
	 * Number of moments (starting at the second moment) to use for features.
	 */
	private int numMoments;

	/**
	 * Number of Fourier coefficients to use for features.
	 */
	private int numFFT;

	/**
	 * Whether to use the maximum value in each component or not for features.
	 */
	private boolean useMaxes;

	/**
	 * Total number of features, before dimension reduction.
	 */
	private int numFeatures;

	/**
	 * Mean of each feature, used in normalization. Column vector.
	 */
	private Matrix means;

	/**
	 * Whether to update the normalization parameters or not.
	 */
	private boolean onlineNormalization = false;

	/**
	 * Standard deviation of each component of the feature vector.
	 */
	private Matrix stdDevs;

	/**
	 * Sum of squares of differences from the current mean. Used in
	 * normalization. Should have dimensions 'numFeatures' by 1.
	 */
	private Matrix m2;

	/**
	 * Whether to do PCA after converting to features or not.
	 */
	private boolean doPCA;

	/**
	 * Matrix to multiply by for PCA.
	 */
	private Matrix pcaMat;

	/**
	 * Number of dimensions to keep in PCA.
	 */
	private int pcaDim;

	/**
	 * Number of dimensions of each measurement. 1 corresponds to just using z
	 * (after removing gravity), 2 uses z and the norm of x and y, and 3 uses x,
	 * y, and z.
	 */
	private int measurementDim = 3;

	/**
	 * Number of long-term Fourier coefficients. Note that if the long-term
	 * window is larger than the short-term window, these don't correspond to
	 * the same Fourier coefficients
	 */
	private int numLongTermFFT;

	/**
	 * Number of moments of long-term buffer.
	 */
	private int numLongTermMoments;

	/**
	 * Whether to use max absolute values for long-term features or not.
	 */
	private boolean longTermMaxes;

	/**
	 * TODO these default values should be moved to some kind of external
	 * resource, e.g. a text file of parameters Constructor.
	 */
	public GMPicker() {
		super(2, .5, 5);
		// default features and normalization
		this.numMoments = 2;
		this.numFFT = 2;
		this.useMaxes = false;
		this.updateNumFeatures();

		// Make Gaussian mixture with one Gaussian and everything is independent
		// with mean 0 and variance 1 (due to normalization)
		final Vector<Double> weights = new Vector<Double>();
		final Vector<Matrix> meansTemp = new Vector<Matrix>();
		final Vector<Matrix> covs = new Vector<Matrix>();
		weights.add(new Double(1));
		meansTemp.add(new Matrix(this.numFeatures, 1, 0));
		covs.add(Matrix.identity(this.numFeatures, this.numFeatures));

		this.gm = new GaussianMixture(weights, meansTemp, covs);
		this.means = new Matrix(this.numFeatures, 1, 0);
		this.m2 = new Matrix(this.numFeatures, 1, 0);
		// 1e-8: very frequent picks (initial value)
		// 1e-22: seems reasonable on Nexus, slightly unresponsive on Droid
		// 1e-50: picks require vigorous shaking
		this.thresholdProb = 1e-22;
		this.gravityFreshness = .75;
		this.doPCA = false;
		this.updateThreshold = false;
	}

	/**
	 * Constructor, given almost everything.
	 * 
	 * @param gmix
	 *            Gaussian mixture
	 * @param inWindowSize
	 *            Size of time window, in seconds.
	 * @param inWindowInterval
	 *            Interval between Window starts.
	 * @param waitingTime
	 *            Minimum waiting time between picks. (Seconds)
	 * @param inNumMoments
	 *            Number of moments for features.
	 * @param inNumFFT
	 *            Number of FFT coefficients for features.
	 * @param gFreshness
	 *            Freshness of gravity.
	 * @param threshold
	 *            Initial threshold probability.
	 */
	public GMPicker(final GaussianMixture gmix, final double inWindowSize,
			final double inWindowInterval, final double waitingTime,
			final int inNumMoments, final int inNumFFT,
			final double gFreshness, final double threshold) {
		super(inWindowSize, inWindowInterval, waitingTime);
		this.gm = gmix;
		this.numMoments = inNumMoments;
		this.numFFT = inNumFFT;
		this.useMaxes = false;
		this.gravityFreshness = gFreshness;
		this.thresholdProb = threshold;
		this.updateNumFeatures();
		this.means = new Matrix(this.numFeatures, 1, 0);
		this.m2 = new Matrix(this.numFeatures, 1, 0);
		this.doPCA = false;
		this.updateThreshold = true;
	}

	public synchronized Double getParameterVersion(){
		return parameterVersion;
	}
	
	/**
	 * Updates this GMPicker to use the new parameters. TODO the useDefaults
	 * idea really complicates things, and should be removed.
	 * 
	 * @param params
	 *            New set of parameters, many of which may be null.
	 * @param useDefaults
	 *            When true, any parameter whose value is null in params will be
	 *            set to the default value, overwriting the current value.
	 */
	public final synchronized void updateParameters(final GMPickerParams params) {
		Log.v(TAG, "updating parameters");
		if(params.parameterVersion == null){
			Log.e(TAG, "GMPickerParams does not contain a version number. Aborting update.");
			return;
		}

		// Dimension of measurement
		if (params.measurementDim != null) {
			this.measurementDim = params.measurementDim.intValue();
		}
		// Feature descriptions
		if (params.numFFT != null) {
			this.numFFT = params.numFFT.intValue();
		}
		if (params.numMoments != null) {
			this.numMoments = params.numMoments.intValue();
		}
		if (params.useMaxes != null) {
			this.useMaxes = params.useMaxes.booleanValue();
		}
		if (params.numLongTermMoments != null) {
			this.numLongTermMoments = params.numLongTermMoments.intValue();
		}
		if (params.numLongTermFFT != null) {
			this.numLongTermFFT = params.numLongTermFFT.intValue();
		}
		if (params.longTermMaxes != null) {
			this.longTermMaxes = params.longTermMaxes.booleanValue();
		}
		if (params.longTermFeatures != null) {
			this.longTermFeatures = params.longTermFeatures.booleanValue();
		}
		this.updateNumFeatures();
		// Done with features. Now we can move to fields that depend on the
		// number of features.
		// First handle normalization fields
		if (params.means != null) {
			this.means = params.means;
		}
		if (params.stdDevs != null) {
			this.stdDevs = params.stdDevs;
		}
		if (params.m2 != null) {
			this.m2 = params.m2;
		}
		if (params.onlineNormalization != null) {
			this.onlineNormalization = params.onlineNormalization
					.booleanValue();
		}
		// PCA fields
		if (params.doPCA != null) {
			this.doPCA = params.doPCA.booleanValue();
		}
		if (params.pcaMat != null) {
			this.pcaMat = params.pcaMat;
		}
		if (params.pcaDim != null) {
			this.pcaDim = params.pcaDim.intValue();
		}
		// Gaussian mixture model
		if (params.gm != null) {
			this.gm = params.gm;
		}
		// Window size, interval, and waiting time
		if (params.longTermFeatures != null) {
			this.setUseLongTermFeatures(params.longTermFeatures.booleanValue());
		}
		if (params.shortTermWindowSize != null) {
			this.setWindowSize(params.shortTermWindowSize.doubleValue());
		}
		if (params.longTermWindowSize != null) {
			this.setLongTermWindowSize(params.longTermWindowSize.doubleValue());
		}
		if (params.windowInterval != null) {
			this.setWindowInterval(params.windowInterval.doubleValue());
		}
		if (params.waitingTime != null) {
			this.setWaitingTime(params.waitingTime);
		}
		// Gravity
		if (params.gravity != null) {
			this.gravity = params.gravity;
		}
		if (params.gravityFreshness != null) {
			this.gravityFreshness = params.gravityFreshness.doubleValue();
		}
		// Picking frequency
		if (params.desiredPicksFrequency != null) {
			desiredPickFrequency = params.desiredPicksFrequency;
		}

		// Threshold
		if (params.thresholdProb != null) {
			this.thresholdProb = params.thresholdProb.doubleValue();
		}
		if (params.updateThreshold != null) {
			this.updateThreshold = params.updateThreshold.booleanValue();
		}
		// TODO: Check end-to-end validity here.
		//this.printValues();
	}

	/**
	 * Gets the threshold probability.
	 * 
	 * @return The current threshold probability.
	 */
	public synchronized final double getThreshold() {
		return this.thresholdProb;
	}

	/**
	 * Log likelihood of last feature vector
	 * 
	 * @return
	 */
	public final double getLogLikelihood() {
		return this.llh;
	}

	/**
	 * Determines whether to declare a pick or not. PRECONDITION: pickingTime
	 * returns true. 
	 * 
	 * @return Whether to declare a pick or not.
	 */
	@Override
	final boolean pick() {
		// Update picking threshold if picking too much or too little.
		if (this.updateThreshold) {
			// TODO implement threshold updating, e.g. via online percentile
			// estimation
		}

		Matrix features;
		if (!this.longTermFeatures) {
			// Get all but the most recent measurement
			final Vector<AccelSample> inWindow = this.slide.getMeasurements();
			inWindow.remove(inWindow.size() - 1);

			// Convert to matrices
			Vector<Matrix> matrices = MathLib.measurementsToMatrices(inWindow);

			// Remove gravity.
			if (this.gravity == null) {
				this.gravity = MathLib.averageVectors(matrices);
			}
			PickerUtils.removeGravity(matrices, this.gravity,
					this.gravityFreshness);

			// Remove dimensions, if desired
			matrices = PickerUtils.cutDimensions(matrices, this.measurementDim);

			// Featurize all but the last measurement
			features = PickerUtils.featurize(matrices, this.numMoments,
					this.numFFT, this.useMaxes);
		} else {
			// Get all but the most recent measurement
			final Vector<AccelSample> shortTerm = this
					.getShortTermMeasurements();
			final Vector<AccelSample> longTerm = this.getLongTermMeasurements();
			shortTerm.remove(shortTerm.size() - 1);

			// Convert to matrices
			Vector<Matrix> shortMatrices = MathLib
					.measurementsToMatrices(shortTerm);
			Vector<Matrix> longMatrices = MathLib
					.measurementsToMatrices(longTerm);

			// Remove gravity.
			if (this.gravity == null) {
				this.gravity = MathLib.averageVectors(shortMatrices);
			}
			PickerUtils.removeGravity(shortMatrices, this.gravity,
					this.gravityFreshness);
			// Don't update gravity for the long-term measurements.
			PickerUtils.removeGravity(longMatrices, this.gravity, 0);
			// Remove dimensions, if desired
			shortMatrices = PickerUtils.cutDimensions(shortMatrices,
					this.measurementDim);
			longMatrices = PickerUtils.cutDimensions(longMatrices,
					this.measurementDim);

			// Featurize all but the last measurement
			features = PickerUtils.featurize(shortMatrices, longMatrices,
					this.numMoments, this.numFFT, this.useMaxes,
					this.numLongTermMoments, this.numLongTermFFT,
					this.longTermMaxes);
		}

		// Normalize
		if (this.onlineNormalization || this.stdDevs == null) {
			// Make sure means and m2 are the right size
			if (this.means.getRowDimension() != this.numFeatures) {
				this.means = new Matrix(this.numFeatures, 1, 0);
			}
			if (this.m2.getRowDimension() != this.numFeatures) {
				this.m2 = new Matrix(this.numFeatures, 1, 0);
				this.numPickChecks = 1;
			}
			PickerUtils.normalize(features, this.means, this.m2,
					this.numPickChecks);
		} else {
			Log.d(TAG,"Normalizing using stored means and stdDevs");
			PickerUtils.normalize(features, this.means, this.stdDevs);
		}

		// Perform PCA
		if (this.doPCA) {
			features = PickerUtils.pcaFeatures(features, this.pcaMat,
					this.pcaDim);
		}

		// Determine probability from the GaussianMixture
		final double prob = this.gm.pdf(features);
		llh = gm.logPDF(features);

		// Compare with threshold probability
		boolean pick = prob < thresholdProb;

		return pick;
	}

	/**
	 * Updates the number of features, given that the number of moments or
	 * number of FFT coefficients has changed. Doesn't update stored means or
	 * m2, though.
	 */
	private void updateNumFeatures() {
		int newFeatures = this.measurementDim * (this.numMoments + this.numFFT);
		if (this.useMaxes) {
			newFeatures += this.measurementDim;
		}
		if (this.longTermFeatures) {
			newFeatures += this.measurementDim
					* (this.numLongTermMoments + this.numLongTermFFT);
			if (this.longTermMaxes) {
				newFeatures += this.measurementDim;
			}
		}
		this.numFeatures = newFeatures;
	}

//	private void printValues() {
//		System.out.println("Measurement dim: " + this.measurementDim);
//		System.out.println("Num moments: " + this.numMoments);
//		System.out.println("Num fft: " + this.numFFT);
//		System.out.println("Maxes: " + this.useMaxes);
//		System.out.println("Number of gaussians: " + this.gm.getNumGaussians());
//		System.out.println("Gaussian dimension: " + this.gm.getDimension());
//		System.out.println("Long term: " + this.longTermFeatures);
//		System.out.println("Do PCA: " + this.doPCA);
//		System.out.println("PCA dim: " + this.pcaDim);
//		if (this.doPCA) {
//			System.out
//					.println("PCA mat Rows: " + this.pcaMat.getRowDimension());
//			System.out.println("PCA mat Cols: "
//					+ this.pcaMat.getColumnDimension());
//			System.out.println("PCA mat(0, 1): " + this.pcaMat.get(0, 1));
//		}
//		System.out.println("Mean size: " + this.means.getRowDimension());
//		System.out.println("Mean(0, 0): " + this.means.get(0, 0));
//		if (this.stdDevs != null) {
//			System.out.println("Stds size: " + this.stdDevs.getRowDimension());
//			System.out.println("Stds(0, 0): " + this.stdDevs.get(0, 0));
//		}
//		System.out.println("Online normalization: " + this.onlineNormalization);
//	}

}