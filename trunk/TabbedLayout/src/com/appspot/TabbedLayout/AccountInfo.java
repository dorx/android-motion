package com.appspot.TabbedLayout;

import java.io.IOException;
import java.io.InputStream;
//import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;

import org.apache.http.HttpResponse;
import org.apache.http.client.ClientProtocolException;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.params.ClientPNames;
import org.apache.http.cookie.Cookie;
//import org.apache.http.impl.client.DefaultHttpClient;

import android.accounts.Account;
import android.accounts.AccountManager;
import android.accounts.AccountManagerCallback;
import android.accounts.AccountManagerFuture;
import android.accounts.AuthenticatorException;
import android.accounts.OperationCanceledException;
import android.app.Activity;
import android.content.Intent;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
//import android.graphics.PixelFormat;
//import android.hardware.Camera;
//import android.graphics.Bitmap;
//import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;

public class AccountInfo extends Activity /*implements SurfaceHolder.Callback*/ {
	private ParcelableHttpClient http_client = null;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);		
		setContentView(R.layout.blank);
		System.out.println("making");
		http_client = new ParcelableHttpClient();
		System.out.println("makingDone");
		
        
	}

	@Override
	protected void onResume() {
		super.onResume();
		Intent intent = getIntent();
		AccountManager accountManager = AccountManager.get(getApplicationContext());
		Account account = (Account)intent.getExtras().get("account");
		System.out.println("gettingAuthToken");
		//accountManager.getAuthToken(account, "ah", false, new GetAuthTokenTask(), null);
		new GetAuthTokenTask().execute(account);
	}
	
	@Override
	protected void onPause() {
		super.onPause();
	}
	
	
	/*private class GetAuthTokenCallback implements AccountManagerCallback<Bundle> {
		public void run(AccountManagerFuture<Bundle> result) {
			Bundle bundle;
			try {
				bundle = result.getResult();
				Intent intent = (Intent)bundle.get(AccountManager.KEY_INTENT);
				if(intent != null) {
					// User input required
					startActivity(intent);
				} else {
					onGetAuthToken(bundle);
				}
			} catch (OperationCanceledException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (AuthenticatorException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
	};*/
	private class GetAuthTokenTask extends AsyncTask<Account, Object, String> {

	    @Override
	    protected String doInBackground(Account... accounts) {
	        AccountManager manager = AccountManager.get(getApplicationContext());
	        Account account = accounts[0];
	        String token = this.buildToken(manager, account);
	        manager.invalidateAuthToken(account.type, token);
	        return this.buildToken(manager, account);
	    }

	    private String buildToken(AccountManager manager, Account account) {
	    	String TAG = "buildToken";
	        try {
	            AccountManagerFuture<Bundle> future = manager.getAuthToken (account, "ah", false, null, null);
	            Bundle bundle = future.getResult();
	            return bundle.getString(AccountManager.KEY_AUTHTOKEN);
	         } catch (OperationCanceledException e) {
	                Log.w(TAG, e.getMessage());
	         } catch (AuthenticatorException e) {
	                Log.w(TAG, e.getMessage());
	         } catch (IOException e) {
	                Log.w(TAG, e.getMessage());
	         }
	         return null;
	    }

	    protected void onPostExecute(String authToken) {
	        new GetCookieTask().execute(authToken);    
	    }
	}

	protected void onGetAuthToken(Bundle bundle) {
		String auth_token = bundle.getString(AccountManager.KEY_AUTHTOKEN);
		System.out.println("got the auth token: " + auth_token);
		new GetCookieTask().execute(auth_token);
	}

	private class GetCookieTask extends AsyncTask<String, Void, Boolean> {
		protected Boolean doInBackground(String... tokens) {
			try {
				System.out.println("now getting http client cookies");
				// Don't follow redirects
				http_client.getParams().setBooleanParameter(ClientPNames.HANDLE_REDIRECTS, false);

				HttpGet http_get = new HttpGet("http://twyttyr.appspot.com/_ah/login?continue=http://localhost/&auth=" + tokens[0]);
				HttpResponse response;
				response = http_client.execute(http_get);
				if(response.getStatusLine().getStatusCode() != 302)
				{
					// Response should be a redirect
					System.out.println("failed to get cookies" + response.getStatusLine().getStatusCode());
					return false;
				}

				System.out.println("CookieList Size: "+http_client.getCookieStore().getCookies().size());
				for(Cookie cookie : http_client.getCookieStore().getCookies()) {
					System.out.println(cookie.getName());
					if(cookie.getName().equals("ACSID"))
						return true;
				}
			} catch (ClientProtocolException e) {
				// TODO Auto-generated catch block
				System.out.print("Client ");
				e.printStackTrace();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				System.out.print("IO ");
				e.printStackTrace();
			} finally {
				http_client.getParams().setBooleanParameter(ClientPNames.HANDLE_REDIRECTS, true);
			}
			return false;
		}
		
		protected void onPostExecute(Boolean result)
		{
			System.out.println("Cookie: " + result);
			
			if (result)
			{
			Intent intent = new Intent();
			intent.putExtra("client", http_client);
			
			setResult(RESULT_OK, intent);
			}
			else
			{
				setResult(RESULT_CANCELED);
			}
			finish();
		}
	}

	/*private class AuthenticatedRequestTask extends AsyncTask<String, Void, HttpResponse> {
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
	}*/
    
    @Override
    public void onDestroy() {
    	//unregisterC2DM();
    	super.onDestroy();
		if (http_client != null)
			http_client.getConnectionManager().shutdown();
    }
       
    private InputStream OpenHttpConnection(String urlString) 
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
    }
    
    
    public Bitmap DownloadImage(String URL)
    {        
        Bitmap bitmap = null;
        InputStream in = null;        
        try {
            in = OpenHttpConnection(URL);
            bitmap = BitmapFactory.decodeStream(in);
            in.close();
        } catch (IOException e1) {
            // TODO Auto-generated catch block
            e1.printStackTrace();
        }
        return bitmap;                
    }
    
    /*private String DownloadText(String URL)
    {
        int BUFFER_SIZE = 2000;
        InputStream in = null;
        try {
            in = OpenHttpConnection(URL);
        } catch (IOException e1) {
            // TODO Auto-generated catch block
            e1.printStackTrace();
            return "";
        }
        
        InputStreamReader isr = new InputStreamReader(in);
        int charRead;
          String str = "";
          char[] inputBuffer = new char[BUFFER_SIZE];          
        try {
            while ((charRead = isr.read(inputBuffer))>0)
            {                    
                //---convert the chars to a String---
                String readString = 
                    String.copyValueOf(inputBuffer, 0, charRead);                    
                str += readString;
                inputBuffer = new char[BUFFER_SIZE];
            }
            in.close();
        } catch (IOException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return "";
        }    
        return str;        
    }
    
    private void DownloadRSS(String URL)
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
            
            String strTitle = "";
            for (int i = 0; i < itemNodes.getLength(); i++) { 
                Node itemNode = itemNodes.item(i); 
                if (itemNode.getNodeType() == Node.ELEMENT_NODE) 
                {            
                    //---convert the Node into an Element---
                    Element itemElement = (Element) itemNode;
                    
                    //---get all the <title> element under the <item> 
                    // element---
                    NodeList titleNodes = 
                        (itemElement).getElementsByTagName("title");
                    
                    //---convert a Node into an Element---
                    Element titleElement = (Element) titleNodes.item(0);
                    
                    //---get all the child nodes under the <title> element---
                    NodeList textNodes = 
                        ((Node) titleElement).getChildNodes();
                    
                    //---retrieve the text of the <title> element---
                    strTitle = ((Node) textNodes.item(0)).getNodeValue();
                   
                    //---display the title---
                    Toast.makeText(getBaseContext(),strTitle, 
                        Toast.LENGTH_SHORT).show();
                } 
            }
        } catch (IOException e1) {
            // TODO Auto-generated catch block
            e1.printStackTrace();            
        }
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
    
    //---create an anonymous class to act as a button click listener---
    /*private OnClickListener btnListener = new OnClickListener()
    {
        public void onClick(View v)
        {
        	EditText edit = (EditText) findViewById(R.id.textfield);
        	
        	String postInfo = edit.getText().toString();
        	if (postInfo.equals(""))
        		return;
        	edit.setText("");
        	try
        	{
        		postInfo = URLEncoder.encode(postInfo, "UTF-8");
        	}
        	catch(Exception e){}
        	
        	String urlToExecute = "http://twyttyr.appspot.com/?newTwyte=" + postInfo;
        	if (indexSendingTo != -1)
        	{
        		String uid = userID[indexSendingTo];
        		urlToExecute = urlToExecute + "&direct=" + uid;
        	}
        	
            System.out.println(urlToExecute);
        	
            //http_client.getConnectionManager().shutdown();
            //http_client = new DefaultHttpClient();
        	new AuthenticatedRequestTask().execute(urlToExecute);
        	
        	//try
        	//{
        		//System.out.println("posting...?");
        		
        		//Thread.sleep(2000); // Allow 2 seconds for the message to be posted

                txt = (LinearLayout) findViewById(R.id.text);
                String URL = "http://twyttyr.appspot.com/rss/";
            	TwyttyrRSS(URL, txt);
        	//}
        	//catch(InterruptedException e)
        	//{
        	//}
        }
    };
    //---create an anonymous class to act as a button click listener---
    private OnClickListener btnListener2 = new OnClickListener()
    {
        public void onClick(View v)
        {
            // refresh... and post message
            txt = (LinearLayout) findViewById(R.id.text);
            String URL = "http://twyttyr.appspot.com/rss/";
        	TwyttyrRSS(URL, txt);
        }
    };
    
    // We need to make a listener!
    private OnClickListener makePMList = new OnClickListener()
    {
    	public void onClick(View v)
    	{    		
    		// We need to make the ListMenu class
    		Intent intent = new Intent(thisRef, ListMenu.class);
    		intent.putExtra("list", userList);
    		startActivityForResult(intent, PMLIST_REQ_CODE);
    	}
    };
	public void onActivityResult(int requestCode, int resultCode, Intent data)
	{
		if (requestCode == PMLIST_REQ_CODE)
		{
			if (resultCode != -1 && resultCode != userList.length - 1) // -1 is where they just picked the back button
			{
				// resultCode is used as an index for userID and userList
		        Button button2 = (Button) findViewById(R.id.btnSendPM);
		        button2.setText("Send PM to... " + userList[resultCode]);
		        
		        indexSendingTo = resultCode;
			}
			else if (resultCode == userList.length - 1)
			{
				// resultCode is used as an index for userID and userList
		        Button button2 = (Button) findViewById(R.id.btnSendPM);
		        button2.setText("Send PM to... ");
		        
		        indexSendingTo = -1;
			}
		}
	}*/
    
    
    /*public void surfaceCreated(SurfaceHolder holder) {

    	mCamera = Camera.open();
    }
    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {

		if (mPreviewRunning) {
		mCamera.stopPreview();
		}
		Camera.Parameters p = mCamera.getParameters();
		p.setPreviewSize(w, h);
		mCamera.setParameters(p);
		try {
		mCamera.setPreviewDisplay(holder);
		} catch (IOException e) {
		e.printStackTrace();
		}
		mCamera.startPreview();
    	mPreviewRunning = true;

    }
    public void surfaceDestroyed(SurfaceHolder holder) {

    	mCamera.stopPreview();
    	mPreviewRunning = false;
    	mCamera.release();
    }
    
    Camera.PictureCallback mPictureCallback = new Camera.PictureCallback() {

    	public void onPictureTaken(byte[] imageData, Camera c) {
            //TextView postarea = (TextView) findViewById(R.id.postarea);
            //postarea.setText("\nTaking Picture...\n");
            System.out.println("snap");

    	}
    };*/

    
}