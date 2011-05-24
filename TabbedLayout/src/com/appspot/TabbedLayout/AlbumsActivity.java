package com.appspot.TabbedLayout;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.Cursor;
import android.os.Bundle;
import android.provider.ContactsContract;
import android.provider.ContactsContract.PhoneLookup;
import android.view.View;
import android.widget.ListView;
import android.widget.TextView;

public class AlbumsActivity extends TopBarActivity {
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.temp);

        /*TextView textview = new TextView(this);
        textview.setText("This is the Albums tab");
        setContentView(textview);*/
        String total = "";
        
        Cursor cursor = getContentResolver().query(ContactsContract.Contacts.CONTENT_URI,null, null, null, null); 
        while (cursor.moveToNext()) { 
           String contactId = cursor.getString(cursor.getColumnIndex( 
           ContactsContract.Contacts._ID)); 
           String hasPhone = cursor.getString(cursor.getColumnIndex(ContactsContract.Contacts.HAS_PHONE_NUMBER)); 
           if (hasPhone.equals("1")) { 
              // You know it has a number so now query it like this
              Cursor phones = getContentResolver().query( ContactsContract.CommonDataKinds.Phone.CONTENT_URI, null, ContactsContract.CommonDataKinds.Phone.CONTACT_ID +" = "+ contactId, null, null); 
              
              int nameFieldColumnIndex = cursor.getColumnIndex(PhoneLookup.DISPLAY_NAME);
              String contact = cursor.getString(nameFieldColumnIndex);
              
              // gotta loop through the phone numbers
              while (phones.moveToNext()) { 
                 String phoneNumber = phones.getString(phones.getColumnIndex( ContactsContract.CommonDataKinds.Phone.NUMBER));                 
              
                 total = total + contact + ": " + phoneNumber + "\n";
              } 
           phones.close(); 
           }
        }

        /*Cursor emails = getContentResolver().query(ContactsContract.CommonDataKinds.Email.CONTENT_URI, null, ContactsContract.CommonDataKinds.Email.CONTACT_ID + " = " + contactId, null, null); 
        while (emails.moveToNext()) { 
           // This would allow you get several email addresses 
           String emailAddress = emails.getString( 
           emails.getColumnIndex(ContactsContract.CommonDataKinds.CommonDataColumns.DATA)); 
        } 
        emails.close(); */
        cursor.close(); 
        
        TextView tView = (TextView)findViewById(R.id.text_view);
        tView.setText(total);
    }
    
}
