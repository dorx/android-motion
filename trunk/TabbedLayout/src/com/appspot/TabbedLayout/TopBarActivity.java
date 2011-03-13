package com.appspot.TabbedLayout;

/***
 * A TopBarActivity describes most of the activities that will be present in our app.
 * 
 * Unfortunately, since a Java class can only extend 1 other class, the HelloGoogleMaps class
 * will have to copy most of this code as well. If you can think of a better way...
 * 
 * 
 * Logic involved:
 * Be able to handle when the top buttons, Logout/Login and Settings are pressed.
 * Logout/Login changes the state of the active Account,
 * 		as well as the HttpClient that TabbedLayout stores.
 * 
 * Settings is not setup yet.
 */

import android.accounts.Account;
import android.app.Activity;
import android.content.Intent;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class TopBarActivity extends Activity{
	
	public static final int LOGIN_CODE = 1;
	public static final int AUTHENTICATE_CODE = 2;
	
	/* Just updateAccountStatus whenever you can */
	protected void onResume()
	{
		super.onResume();

		updateAccountStatus();
	}
	
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
    		startActivityForResult(intent, LOGIN_CODE);
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
