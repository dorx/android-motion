package com.appspot.TabbedLayout;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.params.ClientPNames;
import org.apache.http.cookie.Cookie;
import org.apache.http.impl.client.DefaultHttpClient;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.app.TabActivity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.res.Resources;
import android.os.AsyncTask;
import android.os.Bundle;
import android.widget.TabHost;
import android.widget.Toast;

public class TabbedLayout extends TabActivity {
    /** Called when the activity is first created. */

	public static ParcelableHttpClient http_client = null;
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
                          res.getDrawable(R.drawable.ic_tab_runner/*songs*/))
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
    
    
    /* 
     * AUTHENTICATION DONE HERE
     * 
     * 
     * 
     * */


	private class AuthenticatedRequestTask extends AsyncTask<String, Void, HttpResponse> {
		@Override
		protected HttpResponse doInBackground(String... urls) {
			try {
				System.out.println("Hey: "+urls[0]);
				HttpGet http_get = new HttpGet(urls[0]);
				return http_client.execute(http_get);
			} catch (ClientProtocolException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			return null;
		}
		
		protected void onPostExecute(HttpResponse result) {
			processResponse(result);
		}
	}
	
	public void processResponse(HttpResponse result)
	{
		try {
			BufferedReader reader = new BufferedReader(new InputStreamReader(result.getEntity().getContent()));
			String first_line = reader.readLine();
			Toast.makeText(getApplicationContext(), first_line, Toast.LENGTH_LONG).show();
			
		} catch (IllegalStateException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public void sendSomething()
	{
    	String urlToExecute = "dummy";//http://twyttyr.appspot.com/?newTwyte=" + postInfo;
    	
        System.out.println(urlToExecute);
    	
    	new AuthenticatedRequestTask().execute(urlToExecute);
	}
	
	
	/* How to just access the internet without authentication.
	 * 
	 * Probably not needed since we need them to be logged in for database transactions.
	 * 
	 * */
    /*private InputStream OpenHttpConnection(String urlString) 
    throws IOException
    {
        InputStream in = null;
        int response = -1;
               
        URL url = new URL(urlString); 
        URLConnection conn = url.openConnection();
                 
        if (!(conn instanceof HttpURLConnection))                     
            throw new IOException("Not an HTTP connection");
        
        try{
            HttpURLConnection httpConn = (HttpURLConnection) conn;
            httpConn.setAllowUserInteraction(false);
            httpConn.setInstanceFollowRedirects(true);
            httpConn.setRequestMethod("GET");
            httpConn.connect(); 

            response = httpConn.getResponseCode();                 
            if (response == HttpURLConnection.HTTP_OK) {
                in = httpConn.getInputStream();                                 
            }                     
        }
        catch (Exception ex)
        {
            throw new IOException("Error connecting");            
        }
        return in;     
    }*/
    /*private void TwyttyrRSS(String URL, LinearLayout txt)
    {
        InputStream in = null;
        try {
            in = OpenHttpConnection(URL);
            Document doc = null;
            DocumentBuilderFactory dbf = 
                DocumentBuilderFactory.newInstance();
            DocumentBuilder db;
            
            try {
                db = dbf.newDocumentBuilder();
                doc = db.parse(in);
            } catch (ParserConfigurationException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            } catch (SAXException e) {
                // TODO Auto-generated catch block
                e.printStackTrace();
            }        
            
            doc.getDocumentElement().normalize(); 
            
            //---retrieve all the <item> nodes---
            NodeList itemNodes = doc.getElementsByTagName("item"); 
            
            //LinearLayout twyte = new LinearLayout(this);
            //txt.addView()
            //txt.setText("");
            txt.removeAllViews();
            
            for (int i = 0; i < itemNodes.getLength(); i++) { 
                Node itemNode = itemNodes.item(i); 
                if (itemNode.getNodeType() == Node.ELEMENT_NODE) 
                {            
                    //---convert the Node into an Element---
                    Element itemElement = (Element) itemNode;
                    
                    TwytePost post = new TwytePost(itemElement);
                    //post.appendView(txt);
                    LinearLayout out = post.getView(this);
                    txt.addView(out);
                    
                    txt.invalidate();
                } 
            }
            
            // Parse all the twyttyryr's into userList
            itemNodes = doc.getElementsByTagName("twyttyryr"); 
            userList = new String[itemNodes.getLength()+1];
            userID = new String[itemNodes.getLength()];
            for (int i = 0; i < itemNodes.getLength(); i++) {
                Node itemNode = itemNodes.item(i); 
                if (itemNode.getNodeType() == Node.ELEMENT_NODE) 
                {            
                    //---convert the Node into an Element---
                    Element twyttyryr = (Element) itemNode;
                    
                    userList[i] = ((Node)twyttyryr.getElementsByTagName("nickname").item(0)).getChildNodes().item(0).getNodeValue();
                    userID[i] = ((Node)twyttyryr.getElementsByTagName("user_id").item(0)).getChildNodes().item(0).getNodeValue();
                    
                    //Toast.makeText(getBaseContext(),"hi " + userList[i], Toast.LENGTH_SHORT).show();
                } 
            }
            userList[userList.length - 1] = "Everyone";
            
            
            in.close();
        } catch (IOException e1) {
            // TODO Auto-generated catch block
            e1.printStackTrace();            
        }
    }*/
    
    
    
    
}
