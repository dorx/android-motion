package com.julian.apps.Sensors141;

/**
 * @author jkrause
 * Stores data relating to one measurement.
 */
public class Measurement {

    /**
     *  x, y, and z accelerometer values.
     */
    public final float x, y, z;

    /**
     * Time in nanoseconds.
     */
    public final long t;

    /**
     * Constructor.
     * @param inX X acceleration
     * @param inY Y acceleration
     * @param inZ Z acceleration
     * @param inT Time of measurement (typically in nanoseconds)
     */
    public Measurement(final float inX, final float inY, final float inZ,
                       final long inT) {
        this.x = inX;
        this.y = inY;
        this.z = inZ;
        this.t = inT;
    }


    @Override
    public final boolean equals(final Object other) {
        if (!(other instanceof Measurement)) {
            return false;
        }

        final Measurement otherM = (Measurement) other;

        return this.x == otherM.x && this.y == otherM.y
            && this.z == otherM.z && this.t == otherM.t;
    }

    @Override
    public final int hashCode() {
        return (int) (this.t * (this.x + this.y + this.z));
    }
}
