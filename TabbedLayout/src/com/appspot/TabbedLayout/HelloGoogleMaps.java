package com.appspot.TabbedLayout;

import java.util.Iterator;
import java.util.List;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapActivity;
import com.google.android.maps.MapView;
import com.google.android.maps.Overlay;
import com.google.android.maps.OverlayItem;

import android.content.Context;
import android.graphics.drawable.Drawable;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.view.View;

public class HelloGoogleMaps extends MapActivity implements LocationListener {

	private OverlayItem myLocItem;
	private HelloItemizedOverlay itemizedoverlay;
	private Location location; // We listen to this.
	private ModifiableGeoPoint myGeoPoint;
	
    /** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
	    super.onCreate(savedInstanceState);
	    setContentView(R.layout.map);
	    
	    MapView mapView = (MapView) findViewById(R.id.mapview);
	    mapView.setBuiltInZoomControls(true);
	    
	    List<Overlay> mapOverlays = mapView.getOverlays();
	    Drawable drawable = this.getResources().getDrawable(R.drawable.androidmenuicon1);
	    itemizedoverlay = new HelloItemizedOverlay(drawable, this);
	    
		GeoPoint point = new GeoPoint(19240000,-99120000);
		OverlayItem overlayitem = new OverlayItem(point, "Hola, Mundo!", "I'm in Mexico City!");
		GeoPoint point2 = new GeoPoint(35410000, 139460000);
		OverlayItem overlayitem2 = new OverlayItem(point2, "Sekai, konichiwa!", "I'm in Japan!");
		

		
	    itemizedoverlay.addOverlay(overlayitem);
	    itemizedoverlay.addOverlay(overlayitem2);
	    mapOverlays.add(itemizedoverlay);
	}
	
	@Override
	protected void onResume()
	{
		super.onResume();
		// Where am I?
		LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
		location = locationManager
				.getLastKnownLocation(LocationManager.GPS_PROVIDER);

		if (location != null) {
			myGeoPoint = new ModifiableGeoPoint((int)(location.getLatitude() * 1e6),
                    (int)(location.getLongitude() * 1e6));
		} else {
			myGeoPoint = null;
		}
	    if (myGeoPoint != null)
	    {
	    	myLocItem = new OverlayItem(myGeoPoint, "Hello, world!", "You are here!");
	    	itemizedoverlay.addOverlay(myLocItem);
	    }
	    
	    // Ask for GPS updates
	    locationManager.requestLocationUpdates(
	            LocationManager.GPS_PROVIDER, 0, 0, this);
	}
	@Override
	protected void onPause()
	{
		super.onPause();
		// Stop listening when we pause
		LocationManager locationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
		locationManager.removeUpdates(this);
	}
    
    @Override
    protected boolean isRouteDisplayed() {
        return false;
    }
    
    @Override
    public void onLocationChanged(Location loc) {
    	System.out.println("Location changed: " + loc);
        if (loc != null) {
        	/*itemizedoverlay.remove(myLocItem);
        	GeoPoint myLoc = new GeoPoint((int)(loc.getLatitude() * 1e6),
                    (int)(loc.getLongitude() * 1e6));
	    	myLocItem = new OverlayItem(myLoc, "Hello, world!", "You are here!");
	    	itemizedoverlay.addOverlay(myLocItem);*/
        	
        	/*myGeoPoint.setLatitude((int)(loc.getLatitude() * 1e6));
        	myGeoPoint.setLongitude((int)(loc.getLongitude() * 1e6));
        	itemizedoverlay.refresh();
        	
        	MapView mapView = (MapView) findViewById(R.id.mapview);
        	// move to location
        	
        	// first remove old overlay
        	List overlays = mapView.getOverlays();
    		if (overlays.size() > 0) {
    			for (Iterator iterator = overlays.iterator(); iterator.hasNext();) {
    				iterator.next();
    				iterator.remove();
    			}
    		}
    		mapView.getOverlays().add(itemizedoverlay);
        	
    		//mapView.getController().animateTo(myGeoPoint);
        	
        	mapView.postInvalidate(); // to redraw
        	
            //TextView gpsloc = (TextView) findViewById(R.id.widget28);
            //gpsloc.setText("Lat:"+loc.getLatitude()+" Lng:"+ loc.getLongitude());*/
        	
        	MapView myMap = (MapView) findViewById(R.id.mapview);
        	Location newLocation = loc;
        	
        	List overlays = myMap.getOverlays();
        	 
    		// first remove old overlay
    		if (overlays.size() > 0) {
    			for (Iterator iterator = overlays.iterator(); iterator.hasNext();) {
    				iterator.next();
    				iterator.remove();
    			}
    		}
     
    		// transform the location to a geopoint
    		GeoPoint geopoint = new GeoPoint(
    				(int) (newLocation.getLatitude() * 1E6), (int) (newLocation
    						.getLongitude() * 1E6));
     
    		// initialize icon
    		Drawable icon = getResources().getDrawable(R.drawable.androidmenuicon1);
    		icon.setBounds(0, 0, icon.getIntrinsicWidth(), icon
    				.getIntrinsicHeight());
     
    		// create my overlay and show it
    		HelloItemizedOverlay overlay = new HelloItemizedOverlay(icon, this);
    		OverlayItem item = new OverlayItem(geopoint, "My Location", null);
    		overlay.addOverlay(item);
    		myMap.getOverlays().add(overlay);
     
    		// move to location
    		myMap.getController().animateTo(geopoint);
     
    		// redraw map
    		myMap.postInvalidate();
        	
        }
    }
    @Override
    public void onProviderDisabled(String provider) {
        //TextView gpsloc = (TextView) findViewById(R.id.widget28);
        //gpsloc.setText("GPS OFFLINE.");
    }

    @Override
    public void onProviderEnabled(String provider) {
        // TODO Auto-generated method stub
    }

    @Override
    public void onStatusChanged(String provider, int status, Bundle extras) {
        // TODO Auto-generated method stub
    	System.out.println("GPS Status code:" + status);
    }

    
    public void launchSettings(View view) {
        
    }    
    
    public void logout(View view) {
    
    }
}