package com.appspot.TabbedLayout;

import com.google.android.maps.GeoPoint;

public class ModifiableGeoPoint extends GeoPoint {

	private int latitudeE6;
	private int longitudeE6;
	
	public ModifiableGeoPoint(int latitudeE6, int longitudeE6) 
	{
		super(latitudeE6, longitudeE6);
		this.latitudeE6 = latitudeE6;
		this.longitudeE6 = longitudeE6;
	}
	public void setLatitude(int lat)
	{
		latitudeE6 = lat;
	}
	public void setLongitude(int lon)
	{
		longitudeE6 = lon;
	}
	public int getLatitudeE6()
	{
		return latitudeE6;
	}
	public int getLongitudeE6()
	{
		return longitudeE6;
	}
	public String toString()
	{
		return "<Lat: " + latitudeE6 + ", Lon: "+ longitudeE6 + ">";
	}
}
