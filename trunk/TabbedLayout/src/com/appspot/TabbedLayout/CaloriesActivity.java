package com.appspot.TabbedLayout;

/* Displays the previously recorded motion data.
 * */

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

import android.app.Activity;
import android.os.Bundle;
import android.text.method.ScrollingMovementMethod;
import android.view.View;
import android.widget.TextView;

public class CaloriesActivity extends TopBarActivity {
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.calories);
        
        //

        /*TextView textview = new TextView(this);
        textview.setText("This is the Songs tab");
        setContentView(textview);*/
    }
    
    /* Read the recorded file on the filesystem
     * 
     * Then just display it in a Textview.
     * */
    protected void onResume()
    {
    	super.onResume();
        TextView v = (TextView) findViewById(R.id.data);
        
        try {
			FileInputStream fis = openFileInput(MotionActivity.FILENAME);
			int length = fis.available();
			if (length > 100000)
				length = 100000;
			byte[] buffer = new byte[length];
			int success = fis.read(buffer);
			String s = new String(buffer);
			v.setText(s);
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		v.setMovementMethod(new ScrollingMovementMethod()); 
        
    }
    
    
}