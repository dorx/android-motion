package edu.caltech.android.picking;

import java.io.IOException;
import java.io.Serializable;

import Jama.Matrix;
import edu.caltech.android.gaussianMixture.GaussianMixture;

/**
 * Parameters for a GMPicker.
 * 
 * This thing seems designed to have nulls all over the place. It seems to exist
 * just to ferry new parameters during a parameter update. I really don't like
 * all these nulls. How about a map of key / value pairs? Or require that all
 * fields be assigned (and then use different parameter classes for different
 * sets of fields)?
 */
public class GMPickerParams {

	/**
	 * Version number of picking parameters
	 */
	public Double parameterVersion;

	/**
	 * Probability below which things count as a pick.
	 */
	public Double thresholdProb;

	/**
	 * Should the threshold be updated as time goes on?
	 */
	public Boolean updateThreshold;

	/**
	 * A target pick rate, i.e. fraction of runs of the picking algorithm that
	 * produce picks, on average. Maybe should be in picks per minute?
	 */
	public Double desiredPicksFrequency;


	/**
	 * Gravity is calculated as a rolling average, and this parameter tells how
	 * much of gravity is determined by the gravity vector (average) of the
	 * current set of measurements. Should be in [0,1] with 1 the most fresh.
	 */
	public Double gravityFreshness;

	/**
	 * Gravity vector. Should be a 3 by 1 Matrix.
	 */
	public Matrix gravity;

	/**
	 * Number of moments (starting at the second moment) to use for features.
	 */
	public Integer numMoments;

	/**
	 * Number of Fourier coefficients to use for features.
	 */
	public Integer numFFT;

	/**
	 * Whether to use the maximum value in each component or not for features.
	 */
	public Boolean useMaxes;

	/**
	 * Gaussian mixture that this picker uses to model its 'normal' data.
	 */
	public GaussianMixture gm;

	/**
	 * Mean of each feature, used in normalization. Column vector.
	 */
	public Matrix means;

	/**
	 * Standard deviation of each component of the feature vector.
	 */
	public Matrix stdDevs;

	/**
	 * Whether to update the normalization parameters or not.
	 */
	public Boolean onlineNormalization;

	/**
	 * Sum of squares of differences from the current mean. Used in
	 * normalization. Should have dimensions 'numFeatures' by 1.
	 */
	public Matrix m2;

	/**
	 * Whether to do PCA after converting to features or not.
	 */
	public Boolean doPCA;

	/**
	 * Matrix to multiply by for PCA.
	 */
	public Matrix pcaMat;

	/**
	 * Number of dimensions to keep in PCA.
	 */
	public Integer pcaDim;

	/**
	 * Number of dimensions of each measurement. 1 corresponds to just using z
	 * (after removing gravity), 2 uses z and the norm of x and y, and 3 uses x,
	 * y, and z.
	 */
	public Integer measurementDim;

	/**
	 * Number of long-term Fourier coefficients. Note that if the long-term
	 * window is larger than the short-term window, these don't correspond to
	 * the same Fourier coefficients
	 */
	public Integer numLongTermFFT;

	/**
	 * Number of long-term moments.
	 */
	public Integer numLongTermMoments;

	/**
	 * Whether to use max absolute values for long-term features or not.
	 */
	public Boolean longTermMaxes;

	/**
	 * Whether to use long-term features or not.
	 */
	public Boolean longTermFeatures;

	/**
	 * Short-term window size.
	 */
	public Double shortTermWindowSize;

	/**
	 * Size of long-term window (does not include short-term window size), in
	 * seconds.
	 */
	public Double longTermWindowSize;

	/**
	 * Interval between sliding windows.
	 */
	public Double windowInterval;

	/**
	 * How long to wait between picks.
	 */
	public Double waitingTime;

	/**
	 * Default constructor. Sets nothing.
	 */
	public GMPickerParams() {
	}

	/**
	 * Converts this GMPickerParams to a form recognized by the server.
	 * 
	 * @return A string of the following form:
	 *         parameter1name:value;parameter2name:value1, value2; ...
	 */
//	@Override
//	public String toString() {
//		String toReturn = "";
//		if (this.thresholdProb != null) {
//			toReturn += "threshold:" + this.thresholdProb + ";";
//		}
//		if (this.updateThreshold != null) {
//			toReturn += "updateThreshold:" + this.updateThreshold + ";";
//		}
//		if (this.desiredPicksFrequency != null) {
//			toReturn += "pickFrequency:" + this.desiredPicksFrequency
//					+ ";";
//		}
//		if (this.gravityFreshness != null) {
//			toReturn += "gravityFreshness:" + this.gravityFreshness + ";";
//		}
//		if (this.gravity != null) {
//			String str = this.encodeObject(this.gravity);
//			if (str != null) {
//				toReturn += "gravity:" + str + ";";
//			}
//		}
//		if (this.numMoments != null) {
//			toReturn += "numMoments:" + this.numMoments + ";";
//		}
//		if (this.numFFT != null) {
//			toReturn += "numFFT:" + this.numFFT + ";";
//		}
//		if (this.useMaxes != null) {
//			toReturn += "useMaxes:" + this.useMaxes + ";";
//		}
//		if (this.gm != null) {
//			String str = this.encodeObject(this.gm);
//			if (str != null) {
//				toReturn += "gaussianMixture:" + str + ";";
//			}
//		}
//		if (this.means != null) {
//			String str = this.encodeObject(this.means);
//			if (str != null) {
//				toReturn += "means:" + str + ";";
//			}
//		}
//		if (this.stdDevs != null) {
//			String str = this.encodeObject(this.stdDevs);
//			if (str != null) {
//				toReturn += "stdDevs:" + str + ";";
//			}
//		}
//		if (this.onlineNormalization != null) {
//			toReturn += "onlineNormalization:" + this.onlineNormalization + ";";
//		}
//		if (this.m2 != null) {
//			String str = this.encodeObject(this.m2);
//			if (str != null) {
//				toReturn += "meanSquared:" + str + ";";
//			}
//		}
//		if (this.doPCA != null) {
//			toReturn += "doPCA:" + this.doPCA + ";";
//		}
//		if (this.pcaMat != null) {
//			String str = this.encodeObject(this.pcaMat);
//			if (str != null) {
//				toReturn += "pcaMat:" + str + ";";
//			}
//		}
//		if (this.pcaDim != null) {
//			toReturn += "pcaDimension:" + this.pcaDim + ";";
//		}
//		if (this.measurementDim != null) {
//			toReturn += "measurementDim:" + this.measurementDim + ";";
//		}
//		if (this.numLongTermFFT != null) {
//			toReturn += "numFFTlongTerm:" + this.numLongTermFFT + ";";
//		}
//		if (this.numLongTermMoments != null) {
//			toReturn += "numMomentslongTerm:" + this.numLongTermMoments + ";";
//		}
//		if (this.longTermMaxes != null) {
//			toReturn += "useMaxesLongTerm:" + this.longTermMaxes + ";";
//		}
//		if (this.longTermFeatures != null) {
//			toReturn += "longTermFeatures:" + this.longTermFeatures + ";";
//		}
//		if (this.shortTermWindowSize != null) {
//			toReturn += "shortTermWindowSize:" + this.shortTermWindowSize + ";";
//		}
//		if (this.longTermWindowSize != null) {
//			toReturn += "longTermWindowSize:" + this.longTermWindowSize + ";";
//		}
//		if (this.windowInterval != null) {
//			toReturn += "windowInterval:" + this.windowInterval + ";";
//		}
//		if (this.waitingTime != null) {
//			toReturn += "waitingTime:" + this.waitingTime + ";";
//		}
//		return toReturn;
//	}

	/**
	 * Encodes an object using serialization and converts those bytes to base
	 * 64, returning a string.
	 * 
	 * @param obj
	 *            Object to encode.
	 * @return The object in base 64.
	 */
	public final String encodeObject(final Serializable obj) {
		String toReturn = null;
		try {
			toReturn = Base64.encodeObject(obj);
		} catch (IOException e) {
			e.printStackTrace();
		}
		return toReturn;
	}
}
