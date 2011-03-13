package com.appspot.TabbedLayout;

import org.apache.http.impl.client.DefaultHttpClient;

import android.os.Parcel;
import android.os.Parcelable;

public class ParcelableHttpClient extends DefaultHttpClient implements Parcelable {
    private int mData;
    
    public ParcelableHttpClient()
    {
    	super();
    }

    /* everything below here is for implementing Parcelable */

    // 99.9% of the time you can just ignore this
    public int describeContents() {
        return 0;
    }

    // write your object's data to the passed-in Parcel
    public void writeToParcel(Parcel out, int flags) {
        out.writeInt(mData);
    }

    // this is used to regenerate your object. All Parcelables must have a CREATOR that implements these two methods
    public static final Parcelable.Creator<ParcelableHttpClient> CREATOR = new Parcelable.Creator<ParcelableHttpClient>() {
        public ParcelableHttpClient createFromParcel(Parcel in) {
            return new ParcelableHttpClient(in);
        }

        public ParcelableHttpClient[] newArray(int size) {
            return new ParcelableHttpClient[size];
        }
    };

    // example constructor that takes a Parcel and gives you an object populated with it's values
    private ParcelableHttpClient(Parcel in) {
        mData = in.readInt();
    }
}
