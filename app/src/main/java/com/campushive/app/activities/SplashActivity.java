package com.campushive.app.activities;

import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import androidx.appcompat.app.AppCompatActivity;
import com.campushive.app.R;

public class SplashActivity extends AppCompatActivity {
    
    private static final int SPLASH_DELAY = 2500; // 2.5 seconds

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_splash);

        new Handler(Looper.getMainLooper()).postDelayed(() -> {
            // TODO: Route to Login or Dashboard after Firebase setup
            finish();
        }, SPLASH_DELAY);
    }
}
