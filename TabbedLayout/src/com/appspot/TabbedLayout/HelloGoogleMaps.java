package com.appspot.TabbedLayout;

/* HelloGoogleMaps
 * 
 * displays the TopBar, as TopBarActivity
 * displays the map, centered on the user
 * displays the user's location, constantly updating, as the user moves.
 * 
 * Does not update if the user has no signal.
 * There may be a bug where the Map doesn't update unless it has wireless.
 * */

import java.util.Iterator;
import java.util.List;

import com.google.android.maps.GeoPoint;
import com.google.android.maps.MapActivity;
import com.google.android.maps.MapView;
import com.google.android.maps.Overlay;
import com.google.android.maps.OverlayItem;

import android.accounts.Account;
import android.content.Context;
import android.content.Intent;
import android.graphics.drawable.Drawable;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class HelloGoogleMaps extends MapActivity implements LocationListener {

	/* This overlay item is our whereAmI icon. Currently a flag, but that's ugly 
	 * Also stores the user's location (latitude, longitude) in a GeoPoint
	 * */
	private OverlayItem myLocItem;
	
	/* The list of items being overlaid on the world map */
	private HelloItemizedOverlay itemizedoverlay;
	private Location location; // We listen to this location for updates.
	private ModifiableGeoPoint myGeoPoint; // the geopoint stored in myLocItem
	
    /** Called when the activity is first created. 
     * 
     * Start out by setting up the map and some dummy overlays.
     * 
     * */
	@Override
	public void onCreate(Bundle savedInstanceState) {
	    super.onCreate(savedInstanceState);
	    setContentView(R.layout.map);
	    
	    MapView mapView = (MapView) findViewById(R.id.mapview);
	    mapView.setBuiltInZoomControls(true);
	    
	    List<Overlay> mapOverlays = mapView.getOverlays();
	    
	    // We choose the icon to be overlaid. It's a Drawable.
	    // The Drawable icon is that of a flag.
	    Drawable drawable = this.getResources().getDrawable(R.drawable.androidmenuicon1);
	    itemizedoverlay = new HelloItemizedOverlay(drawable, this);
	    
	    // Unnecessary, but we show Japan and Mexico City as examples
		GeoPoint point = new GeoPoint(19240000,-99120000);
		OverlayItem overlayitem = new OverlayItem(point, "Hola, Mundo!", "I'm in Mexico City!");
		GeoPoint point2 = new GeoPoint(35410000, 139460000);
		OverlayItem overlayitem2 = new OverlayItem(point2, "Sekai, konichiwa!", "I'm in Japan!");
		

		// Add the geopoints to the list for display
	    itemizedoverlay.addOverlay(overlayitem);
	    itemizedoverlay.addOverlay(overlayitem2);
	    mapOverlays.add(itemizedoverlay);
	}
	
	
	/**
	 * onResume: Find the current location
	 * 
	 * set us up the locationListener
	 */
	@Override
	protected void onResume()
	{
		super.onResume();
		
		System.out.println("resuming");
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
	            LocationManager.GPS_PROVIDER, 500 /*every 500 ms*/, 1 /*in meters*/, this);
	    
	    
	    /* You also have to update your top bar status! */
		updateAccountStatus();
	}
	
	/**
	 * Guess what? We're no longer listening when we pause. Duh. Don't waste battery
	 */
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
    
    /** Remove the old icons list, make a new one. Fill it up again.
     * 
     * Note that this is all for the sake of the view refreshing. 
     */
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
    		icon.setBounds(-icon.getIntrinsicWidth()/2, -icon
    				.getIntrinsicHeight()/2, icon.getIntrinsicWidth()/2, icon
    				.getIntrinsicHeight()/2);
     
    		// create my overlay and show it
    		HelloItemizedOverlay overlay = new HelloItemizedOverlay(icon, this);
    		OverlayItem item = new OverlayItem(geopoint, "My Location", null);
    		if (MotionActivity.classification != null)
    			item = new OverlayItem(geopoint, "My Location. " + MotionActivity.classification.getText(), null);
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

    
    /* This class also extends TopBarActivity, but _some_ people think you can only extend
     * a single class. There are some justifications, but we just find it sad. */
    
	/* updateAccountStatus
	 * 
	 * Chooses how to display information on the top bar:
	 * Who's logged in and the text on the Login/Logout button
	 */
	public void updateAccountStatus()
	{
		Button v = (Button)findViewById(R.id.logoutBtn);
		v.setText(TopBarActivity.loginButtonStatus());
		
		TextView w = (TextView)findViewById(R.id.username);

		if (TabbedLayout.activeAccount != null)
		{
			String email = TabbedLayout.activeAccount.name;
			w.setText(email.substring(0, email.indexOf("@")));
		}
		else
			w.setText("Please login!");
	}
	/* Simply put... it's whether or not there is an activeAccount or not */
	public static String loginButtonStatus()
	{
		if (TabbedLayout.activeAccount != null)
			return "Logout";
		return "Login";
	}
	
	/* This would handle what happens if you press the launchSettings button, but... */
    public void launchSettings(View view) {
        
    }    
    
    /* logout: Handles both login and logout of users.
     * 
     * If logged in:
     * TabbedLayout's static activeAccount member is set to null. 
     * 
     * If logged out:
     * Start the LoginMenu activity, forcing the user to choose an account 
     */
    public void logout(View view) {
    	if (TabbedLayout.activeAccount != null)
    	{
    		// logout
    		TabbedLayout.activeAccount = null;
    		updateAccountStatus();
    	}
    	else
    	{
    		// login
    		Intent intent = new Intent(this, LoginMenu.class);
    		startActivityForResult(intent, TopBarActivity.LOGIN_CODE);
    	}
    }

    /* What we do here depends on the activities we've started.
     * 
     * LOGIN_CODE: We force someone to pick an account, and they either chose one or cancelled
     * 	This is when LoginMenu ends.
     * 	Note that picking a new account triggers the AccountInfo activity.
     * AUTHENTICATE_CODE: Just after picking an account, we then setup TabbedLayout's httpclient
     * 	This case is when AccountInfo ends.
     * 
     * Note: Currently always reauthenticates even if the chosen account is the same as the current one
     * 
     */
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data)
    {
    	switch (requestCode) {
    		case TopBarActivity.LOGIN_CODE:
    		{
    			if (resultCode == RESULT_OK)
    			{
    				Account a = (Account)data.getExtras().get("account");
    				TabbedLayout.activeAccount = a;
    				
    				// Give up old connection
    				if (TabbedLayout.http_client != null)
    					TabbedLayout.http_client.getConnectionManager().shutdown();
    				
    				
    				// And then we need to login!!!
    				Intent intent = new Intent(this, AccountInfo.class);
    				intent.putExtra("account", a);
    				startActivityForResult(intent, TopBarActivity.AUTHENTICATE_CODE);
    			}
    			else
    			{
    				// if it fails, we're storing null
    				TabbedLayout.activeAccount = null;
    			}
    			break;
    		}
    		case TopBarActivity.AUTHENTICATE_CODE:
    		{
    			if (resultCode == RESULT_OK)
    			{
    				// Yay we got an HttpClient with good cookies!
    				ParcelableHttpClient a = (ParcelableHttpClient)data.getExtras().get("client");
    				TabbedLayout.http_client = a;
    				
    				// and then we're done...
    			}
    			else
    			{
    				// if it fails, we need to store null, right?
    				TabbedLayout.http_client = null;
    			}
    			break;
    		}
    		default:
    		{
    			break;
    		}
    	}
    	// The situation might have changed, so the top bar needs to be refreshed.
    	updateAccountStatus();
    }
    
}