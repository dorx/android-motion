package com.appspot.TabbedLayout;

/* TabbedLayout is the Main Activity. This is run first because the AndroidManifest says so!
 * We will eventually rename TabbedLayout to whatever name we pick for our App.
 * 
 * TabbedLayout holds 5 tabs
 * ArtistsActivity, which will eventually be replaced by HomeActivity.
 * HelloGoogleMaps, which will eventually be renamed.
 * CaloriesActivity, which currently displays the previously recorded motion/orientation data.
 * AlbumsActivity, which does nothing. Will be replaced with FriendsActivity
 * MotionActivity, which currently recorded the accelerometer and azimuth/pitch roll.
 * 
 * Logics done here:
 * onCreate: Create tabs, and default to CaloriesActivity tab. Will switch to HomeActivity later.
 * Reselects the last logged in person.
 * 		Slight mistake: Doesn't actually authenticate until you reselect an account
 * onStop: Saves the current Account in 'SharedPreferences'
 * 
 * One way to send and receive messages is with
 * new AuthenticatedRequestTask().execute(urlToExecute);
 * Which just visits the URL with GET.
 * 
 * In order to do something with POST
 * See private class AuthenticatedRequestTask
 * 	Instead of using an HttpGet, I suspect an HttpPost would be more appropriate.
 * 
 */

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;

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

	//the httpclient which has all our cookies and will help us with transactions with the database
	public static ParcelableHttpClient http_client = null; 
	
	// The current account we have active. Its credentials are vital for setting up the client
	// correctly.
	public static Account activeAccount = null;
	
	// Preferences name is a just the private filename we use to identify our SharedPreferences
	// The SharedPreferences stores the last logged in account, currently
	public static final String PREFS_NAME = "AndroidMotionPrefs";
	
	
    @Override
    /* onCreate makes the 5 tabs of the TabActivity
     * ArtistsActivity, which will eventually be replaced by HomeActivity.
     * HelloGoogleMaps, which will eventually be renamed.
     * CaloriesActivity, which currently displays the previously recorded motion/orientation data.
     * AlbumsActivity, which does nothing. Will be replaced with FriendsActivity
     * MotionActivity, which currently recorded the accelerometer and azimuth/pitch roll.
     * 
     * Then it selects the account of the last logged in user.
     * 	Slight mistake: doesn't authenticate that user, until you reselect one
     */
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
    
    /* restorePreferences
     * 
     * Obtain the SharedPreferences for this activity and get the account out.
     * The account string for the 'alexfandrianto@gmail.com' account is just
     * 	alexfandrianto
     * 
     * Saving this on the phone allows us to remember who was last logged in when restarting the app
     */
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
    
    /* onStop
     * 
     * Save the current account in SharedPreferences     * 
     */
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
     * AUTHENTICATED SENDING AND RECEIVING DONE HERE
     * 
     * 
     * */


    /* By calling new AuthenticatedRequestTask().execute(String url)
     * You can asyncrhonously perform an http request
     * 
     * This uses the ParcelableHttpClient http_client that TabbedLayout stores
     * 
     * Make/modify this if you want to use HTTP POST instead of HTTP GET
     */
	private class AuthenticatedRequestTask extends AsyncTask<String, Void, HttpResponse> {
		/* 
		 * The execute() function for AsyncTask really calls doInBackground
		 * 
		 * So expect this to eventually be called and run.
		 * The HttpClient will visit the url passed into the AuthenticatedRequestTask
		 */
		@Override
		protected HttpResponse doInBackground(String... urls) {
			try {
				System.out.println("Hey: "+urls[0]);
				HttpGet http_get = new HttpGet(urls[0]); // It's a Get!
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
		
		/* We want to actually obtain the information and use it in our normal thread */
		protected void onPostExecute(HttpResponse result) {
			processResponse(result);
		}
	}
	
	/* All we do here is make a Toast of the first line of the HttpResponse */
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
	
	/* An example of how to visit a URL with the AuthenticatedRequestTask */
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
