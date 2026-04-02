package com.campushive.app.activities;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import com.campushive.app.R;
import com.campushive.app.models.Note;
import com.google.android.material.textfield.TextInputEditText;

// NOTE: Firebase Storage calls will be uncommented here in the future
// import com.google.firebase.firestore.FirebaseFirestore;
// import com.google.firebase.storage.FirebaseStorage;

import java.util.Date;
import java.util.UUID;

public class UploadNoteActivity extends AppCompatActivity {

    private TextInputEditText etTitle, etSubject;
    private CardView cardSelectPdf;
    private TextView tvPdfName;
    private Button btnUpload;
    
    private Uri pdfUri = null;
    private static final int PICK_PDF_REQUEST = 101;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_upload_note);

        etTitle = findViewById(R.id.etTitle);
        etSubject = findViewById(R.id.etSubject);
        cardSelectPdf = findViewById(R.id.cardSelectPdf);
        tvPdfName = findViewById(R.id.tvPdfName);
        btnUpload = findViewById(R.id.btnUpload);

        cardSelectPdf.setOnClickListener(v -> {
            Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
            intent.setType("application/pdf");
            startActivityForResult(intent, PICK_PDF_REQUEST);
        });

        btnUpload.setOnClickListener(v -> {
            if (pdfUri != null) {
                // Placeholder for Firebase Storage Upload Logic
                // String title = etTitle.getText().toString();
                // String subject = etSubject.getText().toString();
                
                Toast.makeText(this, "Uploading Note... (Backend Sync Skipped)", Toast.LENGTH_SHORT).show();
                finish();
            } else {
                Toast.makeText(this, "Please select a PDF file first", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_PDF_REQUEST && resultCode == RESULT_OK && data != null && data.getData() != null) {
            pdfUri = data.getData();
            tvPdfName.setText("PDF Selected Successfully");
            tvPdfName.setTextColor(getResources().getColor(R.color.success));
        }
    }
}
