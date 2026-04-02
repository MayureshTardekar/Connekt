package com.campushive.app.activities;

import android.os.Bundle;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import com.campushive.app.R;

public class CreateGroupActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_create_group);

        Toolbar toolbar = findViewById(R.id.toolbarCreateGroup);
        setSupportActionBar(toolbar);
        if (getSupportActionBar() != null) {
            getSupportActionBar().setDisplayHomeAsUpEnabled(true);
        }
        toolbar.setNavigationOnClickListener(v -> finish());

        Button btnSubmitGroup = findViewById(R.id.btnSubmitGroup);
        btnSubmitGroup.setOnClickListener(v -> {
            Toast.makeText(this, "Study Group Created! (Mocked)", Toast.LENGTH_SHORT).show();
            finish();
        });
    }
}
