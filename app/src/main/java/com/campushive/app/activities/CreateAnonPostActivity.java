package com.campushive.app.activities;

import android.os.Bundle;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.campushive.app.R;
import com.google.android.material.textfield.TextInputEditText;

public class CreateAnonPostActivity extends AppCompatActivity {

    private TextInputEditText etAnonContent;
    private Button btnSubmitAnon;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create_anon_post);

        etAnonContent = findViewById(R.id.etAnonContent);
        btnSubmitAnon = findViewById(R.id.btnSubmitAnon);

        btnSubmitAnon.setOnClickListener(v -> {
            String content = etAnonContent.getText().toString().trim();
            if (content.isEmpty()) {
                Toast.makeText(this, "The void doesn't accept empty silence.", Toast.LENGTH_SHORT).show();
                return;
            }

            // In Phase 9, this fires off to Firestore Anonymous Collection
            Toast.makeText(this, "Message released into the void. (Backend Skipped)", Toast.LENGTH_SHORT).show();
            finish();
        });
    }
}
