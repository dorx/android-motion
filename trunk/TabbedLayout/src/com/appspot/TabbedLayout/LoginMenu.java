package com.appspot.TabbedLayout;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.ListActivity;
import android.content.Intent;
//import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.ListView;

//import com.appspot.TabbedLayout.R;

public class LoginMenu extends ListActivity {
	
	protected AccountManager accountManager;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        accountManager = AccountManager.get(getApplicationContext());
        Account[] accounts = accountManager.getAccountsByType("com.google");
        String[] emails = new String[accounts.length];
        for (int i = 0; i < emails.length; i++)
        	emails[i] = accounts[i].name;
        this.setListAdapter(new ArrayAdapter<String>(this, R.layout.list_item, emails));
        
		setResult(RESULT_CANCELED);
    }
    
	@Override
	protected void onListItemClick(ListView l, View v, int position, long id) {
		Account[] accounts = accountManager.getAccountsByType("com.google");
			//(Account)getListView().getItemAtPosition(position);
		Account account = accounts[position];
		Intent intent = new Intent();
		intent.putExtra("account", account);
		
		setResult(RESULT_OK, intent);
		finish();
	}
}
