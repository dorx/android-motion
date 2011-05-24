package com.appspot.TabbedLayout;

/* Displays the previously recorded motion data.
 * */

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.view.View.OnKeyListener;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RadioGroup;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.RadioGroup.OnCheckedChangeListener;

public class CaloriesActivity extends TopBarActivity {
	
	
	// Widgets in the application
	private EditText weight;
	private EditText total_time;
	private RadioGroup rdoGroupTips;
	private Button btnCalculate;
	private Button btnReset;

	private TextView txtTipAmount;


	// For the id of radio button selected
	private int radioCheckedId = -1;
	
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.calories);
    
    	weight = (EditText) findViewById(R.id.txtAmount);
		// On app load, the cursor should be in the Amount field
		weight.requestFocus();

		total_time = (EditText) findViewById(R.id.txtTipOther);

		rdoGroupTips = (RadioGroup) findViewById(R.id.RadioGroupTips);

		btnCalculate = (Button) findViewById(R.id.btnCalculate);
		// On app load, the Calculate button is disabled
		btnCalculate.setEnabled(false);

		btnReset = (Button) findViewById(R.id.btnReset);

		txtTipAmount = (TextView) findViewById(R.id.txtTipAmount);

		/*
		 * Attach a OnCheckedChangeListener to the radio group to monitor radio
		 * buttons selected by user
		 */
		rdoGroupTips.setOnCheckedChangeListener(new OnCheckedChangeListener() {

			@Override
			public void onCheckedChanged(RadioGroup group, int checkedId) {
				// Enable/disable Other Percentage tip field
				if (checkedId == R.id.radioFifteen
						|| checkedId == R.id.radioTwenty) {
					
					/*
					 * Enable the calculate button if Total Amount and No. of
					 * People fields have valid values.
					 */
					btnCalculate.setEnabled(weight.getText().length() > 0
							&& total_time.getText().length() > 0);
				}

				
				radioCheckedId = checkedId;
			}
		});

		/*
		 * Attach a KeyListener to the Tip Amount, No. of People and Other Tip
		 * Percentage text fields
		 */
		weight.setOnKeyListener(mKeyListener);
		total_time.setOnKeyListener(mKeyListener);

		/* Attach listener to the Calculate and Reset buttons */
		btnCalculate.setOnClickListener(mClickListener);
		btnReset.setOnClickListener(mClickListener);
	}

	private OnKeyListener mKeyListener = new OnKeyListener() {
		@Override
		public boolean onKey(View v, int keyCode, KeyEvent event) {

//			switch (v.getId()) {
//			case R.id.txtAmount:
				btnCalculate.setEnabled(weight.getText().length() > 0
						&& total_time.getText().length() > 0);
//				break;

//			}
			return false;
		}

	};

	/*
	 * ClickListener for the Calculate and Reset buttons. Depending on the
	 * button clicked, the corresponding method is called.
	 */
	private OnClickListener mClickListener = new OnClickListener() {

		@Override
		public void onClick(View v) {
			if (v.getId() == R.id.btnCalculate) {
				calculate();
			} else {
				reset();
			}
		}
	};

	/**
	 * Calculate the tip as per data entered by the user.
	 */
	private void calculate() {
		
		int METSvalue = 1;
		Double kg_adjustment = 1.0;
		
		final Spinner feedbackSpinner = (Spinner) findViewById(R.id.SpinnerFeedbackType);  
		String feedbackType = feedbackSpinner.getSelectedItem().toString(); 
		
		Double weight_calc = Double.parseDouble(weight.getText().toString());
		Double activity_time = Double.parseDouble(total_time.getText().toString());

		boolean isError = false;
		if (activity_time < 1.0) {
			showErrorAlert("Please enter a valid time.", total_time.getId());
			isError = true;
		}
		
		// Get METS value for activities 
		if (feedbackType == "Walking") {
			METSvalue = 3;
		} else if (feedbackType == "Biking") {
			METSvalue = 4; 
		} else if (feedbackType == "Running") {
			METSvalue = 10;
		}

		// Adjust for metric/imperial units
		if (radioCheckedId == -1) {
			radioCheckedId = rdoGroupTips.getCheckedRadioButtonId();
		}
		if (radioCheckedId == R.id.radioFifteen) {
			kg_adjustment = 1.0;
		} else if (radioCheckedId == R.id.radioTwenty) {
			kg_adjustment = 2.2;
		} 

		if (!isError) {
			Double weight_metric = weight_calc / kg_adjustment;
			Double calories_burned = (weight_metric * METSvalue) * (activity_time / 60); 

			txtTipAmount.setText(calories_burned.toString());
		}
	}

	/**
	 * Resets the results text views at the bottom of the screen as well as
	 * resets the text fields.
	 */
	private void reset() {
		txtTipAmount.setText("");
		weight.setText("");
		total_time.setText("");

		rdoGroupTips.clearCheck();
		// set focus on the first field
		weight.requestFocus();
	}

	/**
	 * Shows the error message in an alert dialog
	 *
	 * @param errorMessage
	 *            String the error message to show
	 * @param fieldId
	 *            the Id of the field which caused the error. This is required
	 *            so that the focus can be set on that field once the dialog is
	 *            dismissed.
	 */
	private void showErrorAlert(String errorMessage, final int fieldId) {
		new AlertDialog.Builder(this).setTitle("Error")
				.setMessage(errorMessage).setNeutralButton("Close",
						new DialogInterface.OnClickListener() {
							@Override
							public void onClick(DialogInterface dialog,
									int which) {
								findViewById(fieldId).requestFocus();
							}
						}).show();
	}
}
