package com.appspot.TabbedLayout;

import org.apache.http.impl.client.DefaultHttpClient;

import android.accounts.Account;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class TopBarActivity extends Activity{
	
	public static final int LOGIN_CODE = 1;
	public static final int AUTHENTICATE_CODE = 2;
	
	protected void onResume()
	{
		super.onResume();

		updateAccountStatus();
	}
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
	public static String loginButtonStatus()
	{
		if (TabbedLayout.activeAccount != null)
			return "Logout";
		return "Login";
	}
	
    public void launchSettings(View view) {
        
    }    
    
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

    // Is overriding onActivityResult
    public void onActivityResult(int requestCode, int resultCode, Intent data)
    {
    	switch (requestCode) {
    		case LOGIN_CODE:
    		{
    			if (resultCode == RESULT_OK)
    			{
    				Account a = (Account)data.getExtras().get("account");
    				TabbedLayout.activeAccount = a;
    				
    				// Give up old connection
    				if (TabbedLayout.http_client != null)
    					TabbedLayout.http_client.getConnectionManager().shutdown();
    				
    				System.out.println("As we start...");
    				// And then we need to login!!!
    				Intent intent = new Intent(this, AccountInfo.class);
    				intent.putExtra("account", a);
    				startActivityForResult(intent, AUTHENTICATE_CODE);
    				System.out.println("Activity started/ing...");
    			}
    			else
    			{
    				// if it fails, we're storing null
    				TabbedLayout.activeAccount = null;
    			}
    			break;
    		}
    		case AUTHENTICATE_CODE:
    		{
    			System.out.println("We're done with the AccountInfo");
    			if (resultCode == RESULT_OK)
    			{
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
    	updateAccountStatus();
    }

}
