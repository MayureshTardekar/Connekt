package com.campushive.app.activities;

import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import com.campushive.app.R;
import com.google.android.material.textfield.TextInputEditText;
import java.util.Calendar;
import java.util.Date;

public class AddEventActivity extends AppCompatActivity {

    private CardView cardSelectImage;
    private ImageView ivEventPreview;
    private LinearLayout llImagePlaceholder;
    private TextInputEditText etEventTitle, etEventDesc;
    private Button btnSelectDate, btnPostEvent;

    private Uri imageUri = null;
    private Date selectedDate = null;
    private static final int PICK_IMAGE_REQUEST = 102;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_add_event);

        cardSelectImage = findViewById(R.id.cardSelectImage);
        ivEventPreview = findViewById(R.id.ivEventPreview);
        llImagePlaceholder = findViewById(R.id.llImagePlaceholder);
        etEventTitle = findViewById(R.id.etEventTitle);
        etEventDesc = findViewById(R.id.etEventDesc);
        btnSelectDate = findViewById(R.id.btnSelectDate);
        btnPostEvent = findViewById(R.id.btnPostEvent);

        cardSelectImage.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
            intent.setType("image/*");
            startActivityForResult(intent, PICK_IMAGE_REQUEST);
        });

        btnSelectDate.setOnClickListener(v -> showDateTimePicker());

        btnPostEvent.setOnClickListener(v -> {
            String title = etEventTitle.getText().toString();
            String desc = etEventDesc.getText().toString();

            if (title.isEmpty() || desc.isEmpty() || selectedDate == null) {
                Toast.makeText(this, "Please fill all required fields", Toast.LENGTH_SHORT).show();
                return;
            }

            // Firebase Storage & Firestore Logic Omitted
            Toast.makeText(this, "Event Posted! (Backend Sync Skipped)", Toast.LENGTH_SHORT).show();
            finish();
        });
    }

    private void showDateTimePicker() {
        final Calendar calendar = Calendar.getInstance();
        DatePickerDialog datePickerDialog = new DatePickerDialog(this, (view, year, month, dayOfMonth) -> {
            calendar.set(Calendar.YEAR, year);
            calendar.set(Calendar.MONTH, month);
            calendar.set(Calendar.DAY_OF_MONTH, dayOfMonth);
            
            TimePickerDialog timePickerDialog = new TimePickerDialog(this, (timeView, hourOfDay, minute) -> {
                calendar.set(Calendar.HOUR_OF_DAY, hourOfDay);
                calendar.set(Calendar.MINUTE, minute);
                selectedDate = calendar.getTime();
                btnSelectDate.setText(selectedDate.toString());
            }, calendar.get(Calendar.HOUR_OF_DAY), calendar.get(Calendar.MINUTE), false);
            timePickerDialog.show();

        }, calendar.get(Calendar.YEAR), calendar.get(Calendar.MONTH), calendar.get(Calendar.DAY_OF_MONTH));
        datePickerDialog.show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            imageUri = data.getData();
            ivEventPreview.setImageURI(imageUri);
            ivEventPreview.setVisibility(View.VISIBLE);
            llImagePlaceholder.setVisibility(View.GONE);
        }
    }
}
