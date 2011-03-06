package com.appspot.TabbedLayout;

import android.accounts.Account;
import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

public class TopBarActivity extends Activity{
	
	public static final int LOGIN_CODE = 1;
	
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
