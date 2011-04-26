/**
 * 
 */
package edu.caltech.android.picking;

import java.util.Vector;

import Jama.Matrix;
import edu.caltech.android.gaussianMixture.MathLib;


/**
 * Utility class for functions which may be of use to Pickers in general.
 */
public final class PickerUtils {

    /**
     * Private constructor makes this a utility class.
     */
    private PickerUtils() {
    }


    /**
     * Seconds in one nanosecond.
     */
    private static final double SECONDS_PER_MILLISECOND = 1e-3;


    /**
     * Converts nanoseconds to seconds.
     * @param nano Amount of time in nanoseconds
     * @return Amount of time in seconds
     */
    public static double millisToSeconds(long ms) {
        return ms * PickerUtils.SECONDS_PER_MILLISECOND;
    }

    /**
     * Converts the given data into features.  Doesn't use the maximum absolute
     * value of each component.
     * @param matrices Vector of Measurements (as Matrices) to convert to
     * features.  Matrices should have 1 column.
     * @param numMoments Number of moments to include in the output feature
     * vector, the first moment included being the second moment.
     * @param numFFT Number of FFT coefficients to get.
     * @return Matrix (vector) consisting of the features.  Moments, then
     * FFT coefficients.
     * @deprecated
     */
    @Deprecated
	public static Matrix featurize(final Vector<Matrix> matrices,
        int numMoments, int numFFT) {
        // Get number of features
        // Dimension of each point.  This is typically either 2 (using
        // measurements with normed x- and y-values) or 3 (raw measurements).
        int pointDim = matrices.firstElement().getRowDimension();
        int numFeatures = pointDim * (numMoments + numFFT);

        Matrix features = new Matrix(pointDim * (numMoments + numFFT), 1);
        int fi = 0; // Row index into features (feature index)

        // Get the moments and add them to the features
        for (int m = 2; m < numMoments + 2; m++) {
            final Matrix moments = MathLib.momentVector(matrices, m);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0,
                moments);
            fi += pointDim;
        }

        // Get Fourier coefficients and add them to the features
        if (numFFT > 0) {
            final Matrix fftFeatures = MathLib.dfft(matrices, numFFT);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim * numFFT - 1, 0,
                fftFeatures);
            fi += pointDim * numFFT;
        }

        // Make sure that no features are NaN, Positive or Negative infinity.
        // If they are, replace them with zero.  Although this is not entirely
        // accurate, it should hopefully never occur, and when it does it is to
        // protect the mean and m2 matrices from becoming NaN, Positive or
        // Negative infinity, which would render them useless.
        for (int i = 0; i < numFeatures; i++) {
            double feature = features.get(i, 0);
            if (feature == Double.NaN || feature == Double.POSITIVE_INFINITY
                                      || feature == Double.NEGATIVE_INFINITY) {
                features.set(i, 0, 0);
                System.out.println("Found a NaN in features");
            }
        }

        return features;
    }


    /**
     * Converts the given data into features.
     * @param matrices Vector of Measurements (as Matrices) to convert to
     * features.  Matrices should have 1 column.
     * @param numMoments Number of moments to include in the output feature
     * vector, the first moment included being the second moment.
     * @param numFFT Number of FFT coefficients to get.
     * @param useMaxes Whether to use the maximum absolute value in each
     * component or not.
     * @return Matrix (vector) consisting of the features.  FFT, then moments,
     * then maxes.
     */
    public static Matrix featurize(final Vector<Matrix> matrices,
        final int numMoments, final int numFFT, final boolean useMaxes) {
        // Get number of features
        // Dimension of each point.  This is typically either 2 (using
        // measurements with normed x- and y-values) or 3 (raw measurements).
        int pointDim = matrices.firstElement().getRowDimension();
        // Contribution of using the max absolute values.
        int maxCont = useMaxes ? 1 : 0; 
        int numFeatures = pointDim * (numMoments + numFFT + maxCont);

        Matrix features = new Matrix(numFeatures, 1);
        int fi = 0; // Row index into features (feature index)

        // Get Fourier coefficients and add them to the features
        if (numFFT > 0) {
            final Matrix fftFeatures = MathLib.dfft(matrices, numFFT);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim * numFFT - 1, 0,
                fftFeatures);
            fi += pointDim * numFFT;
        }

        // Get the moments and add them to the features
        for (int m = 2; m < numMoments + 2; m++) {
            final Matrix moments = MathLib.momentVector(matrices, m);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0,
                moments);
            fi += pointDim;
        }

        // Maximum absolute values in each component
        if (useMaxes) {
            final Matrix maxes = MathLib.maxMagMatrix(matrices);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0, maxes);
            fi += pointDim;
        }

        // Make sure that no features are NaN, Positive or Negative infinity.
        // If they are, replace them with zero.  Although this is not entirely
        // accurate, it should hopefully never occur, and when it does it is to
        // protect the mean and m2 matrices from becoming NaN, Positive or
        // Negative infinity, which would render them useless.
        for (int i = 0; i < numFeatures; i++) {
            double feature = features.get(i, 0);
            if (feature == Double.NaN || feature == Double.POSITIVE_INFINITY
                                      || feature == Double.NEGATIVE_INFINITY) {
                features.set(i, 0, 0);
                System.out.println("Found a NaN in features");
            }
        }

        return features;
    }

	/**
	 * Converts the given data into features, making use of long-term features.
	 * 
	 * @param shortTermMatrices
	 *            Vector of short-term Measurements (as Matrices) to convert to
	 *            features. Matrices should have 1 column.
	 * @param longTermMatrices
	 *            Vector of long-term Measurements (as Matrices) to convert to
	 *            features. Matrices should be column vectors.
	 * @param numMoments
	 *            Number of moments to include in the output feature vector, the
	 *            first moment included being the second moment.
	 * @param numFFT
	 *            Number of FFT coefficients to get.
	 * @param useMaxes
	 *            Whether to use the maximum absolute value in each component or
	 *            not.
	 * @param longTermMoments
	 *            Number of moments to use for long-term data.
	 * @param longTermFFT
	 *            Number of FFT coefficients to use for long-term data.
	 * @param useLongTermMaxes
	 *            Whether to use long-term maximum absolute values or not.
	 * @return Matrix (vector) consisting of the features. FFT coefficients,
	 *         then moments, then maxes. Long-term features before short-term
	 *         features. Features representing the same value but over a
	 *         different dimension of the measurement are adjacent, i.e. 2nd
	 *         moment in x, 2nd moment in y, 2nd moment in z, then 3rd moment in
	 *         x, ...
	 */
    public static Matrix featurize(final Vector<Matrix> shortTermMatrices,
        final Vector<Matrix> longTermMatrices,
        final int numMoments, final int numFFT, final boolean useMaxes,
        final int longTermMoments, final int longTermFFT,
        final boolean useLongTermMaxes) {
        // Get number of features
        // Dimension of each point.  This is typically either 2 (using
        // measurements with normed x- and y-values) or 3 (raw measurements).
        int pointDim = shortTermMatrices.firstElement().getRowDimension();
        // Contribution of using the short-term max absolute values.
        int maxCont = useMaxes ? 1 : 0; 
        int longMaxCont = useLongTermMaxes ? 1 : 0; // Same, but for long-term
        int numFeatures = pointDim * (numMoments + numFFT + maxCont
            + longTermMoments + longTermFFT + longMaxCont);

        Matrix features = new Matrix(numFeatures, 1);
        int fi = 0; // Row index into features (feature index)

        // Get long-term Fourier coefficients and add them to the features
        if (longTermFFT > 0) {
            final Matrix fftFeatures = MathLib.dfft(longTermMatrices,
                longTermFFT);
            MathLib.setSubMatrix(features, fi,
                0, fi + pointDim * longTermFFT - 1, 0, fftFeatures);
            fi += pointDim * longTermFFT;
        }

        // Get the long-term moments and add them to the features
        for (int m = 2; m < longTermMoments + 2; m++) {
            final Matrix moments = MathLib.momentVector(longTermMatrices, m);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0,
                moments);
            fi += pointDim;
        }

        // Long-term Maximum absolute values in each component
        if (useLongTermMaxes) {
            final Matrix maxes = MathLib.maxMagMatrix(longTermMatrices);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0, maxes);
            fi += pointDim;
        }

        // Get short-term Fourier coefficients and add them to the features
        if (numFFT > 0) {
            final Matrix fftFeatures = MathLib.dfft(shortTermMatrices, numFFT);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim * numFFT - 1, 0,
                fftFeatures);
            fi += pointDim * numFFT;
        }

        // Get the short-term moments and add them to the features
        for (int m = 2; m < numMoments + 2; m++) {
            final Matrix moments = MathLib.momentVector(shortTermMatrices, m);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0,
                moments);
            fi += pointDim;
        }

        // Short-term Maximum absolute values in each component
        if (useMaxes) {
            final Matrix maxes = MathLib.maxMagMatrix(shortTermMatrices);
            MathLib.setSubMatrix(features, fi, 0, fi + pointDim - 1, 0, maxes);
            fi += pointDim;
        }

        // Make sure that no features are NaN, Positive or Negative infinity.
        // If they are, replace them with zero.  Although this is not entirely
        // accurate, it should hopefully never occur, and when it does it is to
        // protect the mean and m2 matrices from becoming NaN, Positive or
        // Negative infinity, which would render them useless.
        for (int i = 0; i < numFeatures; i++) {
            double feature = features.get(i, 0);
            if (feature == Double.NaN || feature == Double.POSITIVE_INFINITY
                                      || feature == Double.NEGATIVE_INFINITY) {
                features.set(i, 0, 0);
                System.out.println("Found a NaN in features");
            }
        }

        return features;
    }

    /**
     * Normalizes the given features, updating stored mean and standard
     * deviations.
     * @param features Features to normalize.  Modified.
     * @param means Matrix of stored means.  Is updated.
     * @param m2 Matrix of stored sum of squares of differences from the current
     * mean.  Is updated.
     * @param numPoints Number of points that have been subject to this
     * normalization.  This is required to update the means and determine
     * the variances.
     * @deprecated
     */
    public static void normalize(final Matrix features, final Matrix means,
        final Matrix m2, final int numPoints) {

        int numFeatures = features.getRowDimension();

        for (int i = 0; i < numFeatures; i++) {
            // Update means and sum of squares of differences from the current
            // mean
            final double x = features.get(i, 0);
            final double delta = x - means.get(i, 0);

            means.set(i, 0,
                means.get(i, 0) + delta / numPoints);
            m2.set(i, 0,
                m2.get(i, 0) + delta * (x - means.get(i, 0)));

            // Calculate variance, if possible
            double variance = 0;
            if (numPoints > 1) {
                variance = m2.get(i, 0) / (numPoints - 1);
            }

            // Now Z-transform the data
            if (variance > 0) {
                features.set(i, 0,
                    (x - means.get(i, 0)) / Math.sqrt(variance));
            } else {
                // Variance is 0, which means this measurement is the same
                // as all the previous ones, so set to 0.
                features.set(i, 0, 0);
            }
        }
    }

    /**
     * Normalizes the given features using given mean and standard deviation
     * vectors.
     * @param features Features to normalize.  Modified.
     * @param means Matrix (column vector) of stored means.
     * @param stds Matrix (column vector) of stored standard deviations.
     */
    public static void normalize(final Matrix features, final Matrix means,
        final Matrix stds) {

        int numFeatures = features.getRowDimension();

        for (int i = 0; i < numFeatures; i++) {
            // Update means and sum of squares of differences from the current
            // mean
            final double x = features.get(i, 0);
            final double std = stds.get(i, 0);
            features.set(i, 0, (x - means.get(i, 0)) / std);
        }
    }


    /**
     * Updates the gravity vector, removes gravity from the given
     * measurements (as vectors), modifying the given measurements in-place.
     * @param inMeasurements Vector of vectors (Matrices) corresponding to the
     * current measurements under consideration.
     * @param gravity Previous gravity vector, with dimensions 3x1.  Is updated.
     * @param gravityFreshness Portion of new gravity vector to get from
     * gravity determined by the given measurements.
     */
    public static void removeGravity(final Vector<Matrix> inMeasurements,
        final Matrix gravity, final double gravityFreshness) {
        // Update gravity
        if (gravityFreshness != 0) {
            // First get the average of all of the measurements.
            final Matrix average = MathLib.averageVectors(inMeasurements);

            // Copy over new gravity into current gravity vector.
            Matrix newGravity = gravity.times(1 - gravityFreshness).plus(
                average.times(gravityFreshness));
            MathLib.setSubMatrix(gravity, 0, 0, 2, 0, newGravity);
        }

        // Remove gravity from each of the Measurements, making new ones.
        // First, find the appropriate rotation matrix
        final Matrix rotationMatrix = MathLib.rotationMatrixVecVec(gravity,
            new Matrix(new double[] {0., 0., -1.}, 3));

        // Now, go through each vector, rotating it and subtracting gravity
        for (Matrix m : inMeasurements) {
            // Rotate and subtract gravity
            Matrix rotated = rotationMatrix.times(m);
            m.set(0, 0, rotated.get(0, 0));
            m.set(1, 0, rotated.get(1, 0));
            m.set(2, 0, rotated.get(2, 0) + 9.80665);
        }
    }

    /**
     * Reduces a matrix via PCA.
     * @param inFeatures Input feature column vector, normalized.
     * @param pcaMat PCA matrix to use in performing PCA.
     * @param dims Number of dimensions to keep after performing PCA.
     * @return PCA-reduced feature column vector.  Adds a feature for the
     * projection error.
     */
    public static Matrix pcaFeatures(final Matrix inFeatures,
        final Matrix pcaMat, final int dims) {
        Matrix score = inFeatures.transpose().times(pcaMat); // Row vector
        // Get norm of projection error.
        double sum = 0;
        for (int i = dims; i < score.getColumnDimension(); i++) {
            sum += Math.pow(score.get(0, i), 2);
        }
        double projectionError = Math.sqrt(sum);
        // Get new feature vector.
        Matrix newFeatures = new Matrix(dims + 1, 1);
        for (int i = 0; i < dims; i++) {
            newFeatures.set(i, 0, score.get(0, i));
        }
        newFeatures.set(dims, 0, projectionError);
        return newFeatures;
    }

    /**
     * Converts measurements to the desired dimension.
     * @param inMeasurements Vector of vectors (Matrices) corresponding to the
     * current measurements under consideration.  Dimension 3x1 for each point.
     * @param desiredDim 1 corresponds to just using z, 2 is norm(x, y) and z,
     * 3 is x, y, and z.
     * @return The measurements cut down to the desired number of dimensions.
     * Not necessarily a new vector.
     */
    public static Vector<Matrix> cutDimensions(
        final Vector<Matrix> inMeasurements, final int desiredDim) {
        switch (desiredDim) {
        case 3:
            // Nothing to do.
            return inMeasurements;

        case 2:
            // Norm of x and y, and z.
            Vector<Matrix> newMeasurements2 = new Vector<Matrix>();
            for (int i = 0; i < inMeasurements.size(); i++) {
                Matrix m = inMeasurements.get(i);
                double x = m.get(0, 0);
                double y = m.get(1, 0);
                Matrix m2 = new Matrix(new double[]
                    {Math.sqrt(x * x + y * y), m.get(2, 0)}, 2);
                newMeasurements2.add(m2);
            }
            return newMeasurements2;

        case 1:
            // Just z
            Vector<Matrix> newMeasurements1 = new Vector<Matrix>();
            for (int i = 0; i < inMeasurements.size(); i++) {
                Matrix m = inMeasurements.get(i);
                newMeasurements1.add(new Matrix(1, 1, m.get(2, 0)));
            }
            return newMeasurements1;

        default:
            // Invalid dimension, just return back what was given
            return inMeasurements;
        }
    }

    // TODO
    public static String matrixVectorToString(Matrix mat) {
        String s = "";
        for (int i = 0; i < mat.getRowDimension(); i++) {
            s += mat.get(i, 0) + " ";
        }
        return s;
    }
}
