package com.campushive.app.activities;

import android.content.Intent;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.cardview.widget.CardView;
import com.campushive.app.R;

public class DashboardActivity extends AppCompatActivity {
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dashboard);

        // Bind the Custom UI Cards
        CardView cardNotes = findViewById(R.id.cardNotes);
        CardView cardEvents = findViewById(R.id.cardEvents);
        CardView cardChat = findViewById(R.id.cardChat);
        CardView cardStudyGroups = findViewById(R.id.cardStudyGroups);
        CardView cardLostFound = findViewById(R.id.cardLostFound);
        CardView cardAnon = findViewById(R.id.cardAnon);

        // Set Click Listeners to Route to Respective Modules
        cardNotes.setOnClickListener(v -> startActivity(new Intent(this, NotesActivity.class)));
        cardEvents.setOnClickListener(v -> startActivity(new Intent(this, EventsActivity.class)));
        cardChat.setOnClickListener(v -> startActivity(new Intent(this, ChatListActivity.class)));
        cardStudyGroups.setOnClickListener(v -> startActivity(new Intent(this, StudyGroupActivity.class)));
        cardLostFound.setOnClickListener(v -> startActivity(new Intent(this, LostFoundActivity.class)));
        cardAnon.setOnClickListener(v -> startActivity(new Intent(this, AnonFeedActivity.class)));
    }
}
