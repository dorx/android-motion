/**
 * 
 */
package edu.caltech.android.picking;

import android.os.Parcel;
import android.os.Parcelable;

public class Pick implements Parcelable {
	/** maximum x component acceleration */
	public final double x;

	/** maximum y component acceleration */
	public final double y;

	/** maximum z component acceleration */
	public final double z;

	/** System milliseconds */
	public final long t;

	/**
	 * Constructor.
	 * 
	 * @param inX
	 *            X value
	 * @param inY
	 *            Y value
	 * @param inZ
	 *            Z value
	 * @param inT
	 *            T (time) value
	 */
	public Pick(double inX, double inY, double inZ, long inT) {
		this.x = inX;
		this.y = inY;
		this.z = inZ;
		this.t = inT;
	}

	/**
	 * "Classes implementing the Parcelable interface must also have a static
	 * field called CREATOR, which is an object implementing the
	 * Parcelable.Creator interface" ...implementing multiple inheritance by rules
	 * defined in human readable form? :-)
	 */
	public static final Parcelable.Creator<Pick> CREATOR = new Parcelable.Creator<Pick>() {
		public Pick createFromParcel(Parcel in) {
			return new Pick(in);
		}

		public Pick[] newArray(int size) {
			return new Pick[size];
		}
	};

	/**
	 * This will be used only by the CREATOR
	 * 
	 * @param source
	 */
	public Pick(Parcel source) {
		x = source.readDouble();
		y = source.readDouble();
		z = source.readDouble();
		t = source.readLong();
	}

	@Override
	public int describeContents() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public void writeToParcel(Parcel dest, int flags) {
		dest.writeDouble(x);
		dest.writeDouble(y);
		dest.writeDouble(z);
		dest.writeLong(t);
	}
}