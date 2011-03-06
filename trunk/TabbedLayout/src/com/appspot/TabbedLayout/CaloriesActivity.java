package com.appspot.TabbedLayout;

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
    
    protected void onResume()
    {
    	super.onResume();
        TextView v = (TextView) findViewById(R.id.data);
        
        try {
			FileInputStream fis = openFileInput(MotionActivity.FILENAME);
			byte[] buffer = new byte[fis.available()];
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