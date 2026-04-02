package com.campushive.app.activities;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import com.campushive.app.R;
import com.google.android.material.textfield.TextInputEditText;

public class ReportItemActivity extends AppCompatActivity {

    private RadioGroup rgStatus;
    private RadioButton rbLost;
    private CardView cardReportImage;
    private ImageView ivReportPreview;
    private LinearLayout llReportPlaceholder;
    private TextInputEditText etItemName, etItemLocation, etItemDesc;
    private Button btnSubmitReport;

    private Uri imageUri = null;
    private static final int PICK_IMAGE_REQUEST = 103;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_report_item);

        rgStatus = findViewById(R.id.rgStatus);
        rbLost = findViewById(R.id.rbLost);
        cardReportImage = findViewById(R.id.cardReportImage);
        ivReportPreview = findViewById(R.id.ivReportPreview);
        llReportPlaceholder = findViewById(R.id.llReportPlaceholder);
        etItemName = findViewById(R.id.etItemName);
        etItemLocation = findViewById(R.id.etItemLocation);
        etItemDesc = findViewById(R.id.etItemDesc);
        btnSubmitReport = findViewById(R.id.btnSubmitReport);

        cardReportImage.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
            intent.setType("image/*");
            startActivityForResult(intent, PICK_IMAGE_REQUEST);
        });

        btnSubmitReport.setOnClickListener(v -> {
            String status = rbLost.isChecked() ? "LOST" : "FOUND";
            String name = etItemName.getText().toString();
            String location = etItemLocation.getText().toString();
            String desc = etItemDesc.getText().toString();

            if (name.isEmpty() || location.isEmpty()) {
                Toast.makeText(this, "Please provide Name and Location", Toast.LENGTH_SHORT).show();
                return;
            }

            // Firebase Storage & Firestore Logic Omitted
            Toast.makeText(this, "Item reported as " + status + "! (Backend Sync Skipped)", Toast.LENGTH_SHORT).show();
            finish();
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGE_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            imageUri = data.getData();
            ivReportPreview.setImageURI(imageUri);
            ivReportPreview.setVisibility(View.VISIBLE);
            llReportPlaceholder.setVisibility(View.GONE);
        }
    }
}
