package com.appspot.TabbedLayout;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.Activity;
import android.app.TabActivity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.os.Bundle;
import android.widget.TabHost;

public class TabbedLayout extends TabActivity {
    /** Called when the activity is first created. */

	public static Account activeAccount = null;
	public static final String PREFS_NAME = "AndroidMotionPrefs";
	
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);

        Resources res = getResources(); // Resource object to get Drawables
        TabHost tabHost = getTabHost();  // The activity TabHost
        TabHost.TabSpec spec;  // Resusable TabSpec for each tab
        Intent intent;  // Reusable Intent for each tab

        // Create an Intent to launch an Activity for the tab (to be reused)
        intent = new Intent().setClass(this, ArtistsActivity.class);

        // Initialize a TabSpec for each tab and add it to the TabHost
        spec = tabHost.newTabSpec("artists").setIndicator("Home",
                          res.getDrawable(R.drawable.ic_tab_home))
                      .setContent(intent);
        tabHost.addTab(spec);

        // Do the same for the other tabs
        intent = new Intent().setClass(this, HelloGoogleMaps.class);
        spec = tabHost.newTabSpec("albums").setIndicator("Map",
                          res.getDrawable(R.drawable.ic_tab_artists/*albums*/))
                      .setContent(intent);
        tabHost.addTab(spec);

        intent = new Intent().setClass(this, CaloriesActivity.class);
        spec = tabHost.newTabSpec("songs").setIndicator("Calories",
                          res.getDrawable(R.drawable.ic_tab_heart/*songs*/))
                      .setContent(intent);
        tabHost.addTab(spec);
        
        intent = new Intent().setClass(this, AlbumsActivity.class);
        spec = tabHost.newTabSpec("songs").setIndicator("Friends",
                          res.getDrawable(R.drawable.ic_tab_artists/*songs*/))
                      .setContent(intent);
        tabHost.addTab(spec);
        
        intent = new Intent().setClass(this, MotionActivity.class);
        spec = tabHost.newTabSpec("songs").setIndicator("Motion",
                          res.getDrawable(R.drawable.ic_tab_artists/*songs*/))
                      .setContent(intent);
        tabHost.addTab(spec);
        
        

        tabHost.setCurrentTab(2);
        
        restorePreferences();
    }
    public void restorePreferences()
    {
    	SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
    	String accountToString = settings.getString("accountToString", null);
    	
    	if (accountToString == null)
    		activeAccount = null;
    	else
    	{
    		// We had an old account, with a good toString value.
    		AccountManager accountManager = AccountManager.get(getApplicationContext());
            Account[] accounts = accountManager.getAccountsByType("com.google");
            for (Account account : accounts)
            {
            	if (account.toString().equals(accountToString))
            	{
            		activeAccount = account;
            		break;
            	}
            }
    	}
    }
    
    @Override
    public void onStop() {
    	SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
    	SharedPreferences.Editor editor = settings.edit();
    	String value = "";
    	if (activeAccount != null)
    		value = activeAccount.toString();
    	editor.putString("accountToString", value);
    	
    	// Save
    	editor.commit();

    	super.onStop();
    }
}
